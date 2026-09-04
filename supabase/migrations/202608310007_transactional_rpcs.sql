-- Janosos V6 phase 3: transactional campaign commands and publication.

create or replace function private.finish_command_receipt(
  p_receipt_id uuid,
  p_status public.command_status,
  p_response jsonb,
  p_rejection_code text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_status = 'processing' or p_response is null then
    raise exception 'terminal receipt required' using errcode = '22023';
  end if;

  update private.command_receipts
  set
    status = p_status,
    response = p_response,
    rejection_code = p_rejection_code,
    completed_at = now()
  where id = p_receipt_id;

  if not found then
    raise exception 'command receipt not found' using errcode = 'P0002';
  end if;
  return p_response;
end;
$$;

create or replace function private.publish_best_result(p_result_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  result_row public.run_results%rowtype;
  player_name text;
begin
  select * into result_row
  from public.run_results
  where id = p_result_id;

  if not found or result_row.validation <> 'verified' then
    return;
  end if;

  select display_name into player_name
  from public.profiles
  where user_id = result_row.user_id;

  insert into public.leaderboard_entries as board (
    result_id,
    user_id,
    display_name,
    character_id,
    mode,
    content_version,
    completed,
    level_reached,
    total_score,
    duration_ms,
    ended_at,
    validation
  ) values (
    result_row.id,
    result_row.user_id,
    coalesce(player_name, 'Jugador'),
    result_row.character_id,
    result_row.mode,
    result_row.content_version,
    result_row.completed,
    result_row.level_reached,
    result_row.total_score,
    result_row.duration_ms,
    result_row.ended_at,
    'verified'
  )
  on conflict (user_id, character_id, mode, content_version)
  do update set
    result_id = excluded.result_id,
    display_name = excluded.display_name,
    completed = excluded.completed,
    level_reached = excluded.level_reached,
    total_score = excluded.total_score,
    duration_ms = excluded.duration_ms,
    ended_at = excluded.ended_at,
    validation = excluded.validation
  where
    excluded.completed > board.completed
    or (
      excluded.completed = board.completed
      and excluded.level_reached > board.level_reached
    )
    or (
      excluded.completed = board.completed
      and excluded.level_reached = board.level_reached
      and excluded.total_score > board.total_score
    )
    or (
      excluded.completed = board.completed
      and excluded.level_reached = board.level_reached
      and excluded.total_score = board.total_score
      and excluded.duration_ms < board.duration_ms
    )
    or (
      excluded.completed = board.completed
      and excluded.level_reached = board.level_reached
      and excluded.total_score = board.total_score
      and excluded.duration_ms = board.duration_ms
      and excluded.ended_at < board.ended_at
    );
end;
$$;

create or replace function public.start_campaign(
  p_character_id text,
  p_mode public.game_mode,
  p_content_version text,
  p_protocol_version integer,
  p_loadout_digest text,
  p_lives smallint,
  p_idempotency_key uuid,
  p_request_digest text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  receipt_id uuid;
  existing_receipt private.command_receipts%rowtype;
  old_campaign public.campaign_runs%rowtype;
  new_campaign public.campaign_runs%rowtype;
  response jsonb;
  authorized_lives smallint;
begin
  if caller_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;
  if p_request_digest !~ '^[0-9a-f]{64}$'
    or p_loadout_digest !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid digest' using errcode = '22023';
  end if;
  if p_lives is null or p_lives not between 1 and 3 then
    raise exception 'invalid legacy lives hint' using errcode = '22023';
  end if;
  if p_mode = 'boss_rush' then
    raise exception 'boss rush is not enabled in phase 3' using errcode = '22023';
  end if;

  insert into private.command_receipts (
    user_id, command_type, idempotency_key, request_digest
  ) values (
    caller_id, 'start-campaign', p_idempotency_key, p_request_digest
  )
  on conflict (user_id, command_type, idempotency_key) do nothing
  returning id into receipt_id;

  if receipt_id is null then
    select * into existing_receipt
    from private.command_receipts
    where user_id = caller_id
      and command_type = 'start-campaign'
      and idempotency_key = p_idempotency_key;
    if existing_receipt.request_digest <> p_request_digest then
      raise exception 'idempotency key reused with different request'
        using errcode = '22023';
    end if;
    if existing_receipt.status = 'processing' then
      raise exception 'command is still processing' using errcode = '55000';
    end if;
    return existing_receipt.response;
  end if;

  select base_lives into authorized_lives
  from public.characters
  where id = p_character_id and enabled;

  if not found then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'unknown_character'
    );
    return private.finish_command_receipt(
      receipt_id, 'rejected', response, 'unknown_character'
    );
  end if;

  if not exists (
    select 1
    from private.supported_client_versions
    where content_version = btrim(p_content_version)
      and protocol_version = p_protocol_version
      and supported_from <= now()
      and supported_until > now()
  ) then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'unsupported_client_version'
    );
    return private.finish_command_receipt(
      receipt_id, 'rejected', response, 'unsupported_client_version'
    );
  end if;

  select * into old_campaign
  from public.campaign_runs
  where user_id = caller_id and state = 'active'
  for update;

  if found then
    update private.campaign_stages
    set
      status = 'rejected',
      consumed_at = now(),
      outcome = 'defeat',
      score = 0,
      duration_ms = 0,
      verification = 'rejected',
      rejection_code = 'campaign_replaced'
    where campaign_id = old_campaign.id
      and status in ('token_issued', 'playing', 'finished_pending');

    update public.campaign_runs
    set
      state = 'abandoned',
      provisional_currency = 0,
      ended_at = now()
    where id = old_campaign.id;
  end if;

  insert into public.character_progress (user_id, character_id)
  values (caller_id, p_character_id)
  on conflict (user_id, character_id) do nothing;

  insert into public.campaign_runs (
    user_id,
    character_id,
    mode,
    content_version,
    protocol_version,
    loadout_digest,
    lease_expires_at,
    lives_remaining
  ) values (
    caller_id,
    p_character_id,
    p_mode,
    btrim(p_content_version),
    p_protocol_version,
    p_loadout_digest,
    now() + interval '6 hours',
    authorized_lives
  ) returning * into new_campaign;

  response := jsonb_build_object(
    'status', 'accepted',
    'campaign_id', new_campaign.id,
    'lease_id', new_campaign.lease_id,
    'state', new_campaign.state,
    'level', new_campaign.current_level,
    'expected_sequence', new_campaign.expected_sequence,
    'lease_expires_at', new_campaign.lease_expires_at
  );
  return private.finish_command_receipt(receipt_id, 'accepted', response);
end;
$$;

create or replace function public.start_stage(
  p_campaign_id uuid,
  p_token_digest text,
  p_configuration_digest text,
  p_issued_at timestamptz,
  p_expires_at timestamptz,
  p_signing_key_version smallint,
  p_drop_key_version smallint,
  p_idempotency_key uuid,
  p_request_digest text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  receipt_id uuid;
  existing_receipt private.command_receipts%rowtype;
  campaign public.campaign_runs%rowtype;
  stage private.campaign_stages%rowtype;
  response jsonb;
begin
  if caller_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;
  if p_request_digest !~ '^[0-9a-f]{64}$'
    or p_token_digest !~ '^[0-9a-f]{64}$'
    or p_configuration_digest !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid digest' using errcode = '22023';
  end if;

  insert into private.command_receipts (
    user_id, command_type, idempotency_key, request_digest
  ) values (
    caller_id, 'start-stage', p_idempotency_key, p_request_digest
  )
  on conflict (user_id, command_type, idempotency_key) do nothing
  returning id into receipt_id;

  if receipt_id is null then
    select * into existing_receipt
    from private.command_receipts
    where user_id = caller_id
      and command_type = 'start-stage'
      and idempotency_key = p_idempotency_key;
    if existing_receipt.request_digest <> p_request_digest then
      raise exception 'idempotency key reused with different request'
        using errcode = '22023';
    end if;
    if existing_receipt.status = 'processing' then
      raise exception 'command is still processing' using errcode = '55000';
    end if;
    return existing_receipt.response;
  end if;

  select * into campaign
  from public.campaign_runs
  where id = p_campaign_id and user_id = caller_id
  for update;

  if not found or campaign.state <> 'active' then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'campaign_not_active'
    );
    return private.finish_command_receipt(
      receipt_id, 'rejected', response, 'campaign_not_active'
    );
  end if;

  if campaign.lease_expires_at <= now() then
    update public.campaign_runs
    set state = 'expired', provisional_currency = 0, ended_at = now()
    where id = campaign.id;
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'campaign_expired'
    );
    return private.finish_command_receipt(
      receipt_id, 'rejected', response, 'campaign_expired'
    );
  end if;

  if campaign.expected_sequence > 10 then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'campaign_ready_to_complete'
    );
    return private.finish_command_receipt(
      receipt_id, 'rejected', response, 'campaign_ready_to_complete'
    );
  end if;

  if p_expires_at <> campaign.lease_expires_at
    or p_issued_at > now() + interval '30 seconds'
    or p_expires_at <= now()
    or p_expires_at > p_issued_at + interval '6 hours' then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'invalid_stage_window'
    );
    return private.finish_command_receipt(
      receipt_id, 'rejected', response, 'invalid_stage_window'
    );
  end if;

  if exists (
    select 1 from private.campaign_stages
    where campaign_id = campaign.id
      and sequence = campaign.expected_sequence
  ) then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'stage_already_issued'
    );
    return private.finish_command_receipt(
      receipt_id, 'rejected', response, 'stage_already_issued'
    );
  end if;

  insert into private.campaign_stages (
    campaign_id,
    user_id,
    sequence,
    token_digest,
    configuration_digest,
    signing_key_version,
    drop_key_version,
    issued_at,
    expires_at
  ) values (
    campaign.id,
    caller_id,
    campaign.expected_sequence,
    p_token_digest,
    p_configuration_digest,
    p_signing_key_version,
    p_drop_key_version,
    p_issued_at,
    p_expires_at
  ) returning * into stage;

  response := jsonb_build_object(
    'status', 'accepted',
    'campaign_id', campaign.id,
    'stage_id', stage.id,
    'sequence', stage.sequence,
    'expires_at', stage.expires_at
  );
  return private.finish_command_receipt(receipt_id, 'accepted', response);
end;
$$;

create or replace function public.fail_campaign(
  p_campaign_id uuid,
  p_idempotency_key uuid,
  p_request_digest text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  receipt_id uuid;
  existing_receipt private.command_receipts%rowtype;
  campaign public.campaign_runs%rowtype;
  response jsonb;
begin
  if caller_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;
  if p_request_digest !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid digest' using errcode = '22023';
  end if;

  insert into private.command_receipts (
    user_id, command_type, idempotency_key, request_digest
  ) values (
    caller_id, 'fail-campaign', p_idempotency_key, p_request_digest
  )
  on conflict (user_id, command_type, idempotency_key) do nothing
  returning id into receipt_id;

  if receipt_id is null then
    select * into existing_receipt
    from private.command_receipts
    where user_id = caller_id
      and command_type = 'fail-campaign'
      and idempotency_key = p_idempotency_key;
    if existing_receipt.request_digest <> p_request_digest then
      raise exception 'idempotency key reused with different request'
        using errcode = '22023';
    end if;
    if existing_receipt.status = 'processing' then
      raise exception 'command is still processing' using errcode = '55000';
    end if;
    return existing_receipt.response;
  end if;

  select * into campaign
  from public.campaign_runs
  where id = p_campaign_id and user_id = caller_id
  for update;

  if not found or campaign.state <> 'active' then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'campaign_not_active'
    );
    return private.finish_command_receipt(
      receipt_id, 'rejected', response, 'campaign_not_active'
    );
  end if;

  update private.campaign_stages
  set
    status = 'rejected',
    consumed_at = now(),
    outcome = 'defeat',
    score = 0,
    duration_ms = 0,
    verification = 'rejected',
    rejection_code = 'player_abandoned'
  where campaign_id = campaign.id
    and status in ('token_issued', 'playing', 'finished_pending');

  update public.campaign_runs
  set state = 'abandoned', provisional_currency = 0, ended_at = now()
  where id = campaign.id;

  response := jsonb_build_object(
    'status', 'accepted',
    'campaign_id', campaign.id,
    'state', 'abandoned',
    'ranked', false
  );
  return private.finish_command_receipt(receipt_id, 'accepted', response);
end;
$$;

create or replace function public.apply_finish_stage(
  p_user_id uuid,
  p_campaign_id uuid,
  p_token_digest text,
  p_outcome public.run_outcome,
  p_score bigint,
  p_duration_ms bigint,
  p_defeat_reason text,
  p_currency_earned bigint,
  p_mastery_xp bigint,
  p_idempotency_key uuid,
  p_request_digest text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  receipt_id uuid;
  existing_receipt private.command_receipts%rowtype;
  campaign public.campaign_runs%rowtype;
  stage private.campaign_stages%rowtype;
  result_id uuid;
  response jsonb;
  rejection text;
  lost_currency bigint;
begin
  if p_request_digest !~ '^[0-9a-f]{64}$'
    or p_token_digest !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid digest' using errcode = '22023';
  end if;

  insert into private.command_receipts (
    user_id, command_type, idempotency_key, request_digest
  ) values (
    p_user_id, 'finish-stage', p_idempotency_key, p_request_digest
  )
  on conflict (user_id, command_type, idempotency_key) do nothing
  returning id into receipt_id;

  if receipt_id is null then
    select * into existing_receipt
    from private.command_receipts
    where user_id = p_user_id
      and command_type = 'finish-stage'
      and idempotency_key = p_idempotency_key;
    if existing_receipt.request_digest <> p_request_digest then
      raise exception 'idempotency key reused with different request'
        using errcode = '22023';
    end if;
    if existing_receipt.status = 'processing' then
      raise exception 'command is still processing' using errcode = '55000';
    end if;
    return existing_receipt.response;
  end if;

  select * into campaign
  from public.campaign_runs
  where id = p_campaign_id and user_id = p_user_id
  for update;

  if not found or campaign.state <> 'active' then
    rejection := 'campaign_not_active';
  elsif campaign.lease_expires_at <= now() then
    rejection := 'campaign_expired';
  elsif p_score < 0 or p_score > 5000000
    or p_duration_ms < 1000 or p_duration_ms > 21600000
    or p_currency_earned < 0 or p_currency_earned > 100000
    or p_mastery_xp < 0 or p_mastery_xp > 10000 then
    rejection := 'implausible_result';
  end if;

  if rejection is null then
    select * into stage
    from private.campaign_stages
    where campaign_id = campaign.id
      and user_id = p_user_id
      and sequence = campaign.expected_sequence
      and token_digest = p_token_digest
    for update;

    if not found then
      rejection := 'stage_token_not_found';
    elsif stage.status <> 'token_issued' then
      rejection := 'stage_already_finished';
    elsif stage.expires_at <= now() then
      rejection := 'stage_token_expired';
    end if;
  end if;

  if rejection is not null then
    if campaign.id is not null and campaign.state = 'active' then
      update public.campaign_runs
      set
        state = case when rejection in ('campaign_expired', 'stage_token_expired')
          then 'expired'::public.campaign_state
          else 'failed'::public.campaign_state
        end,
        provisional_currency = 0,
        ended_at = now()
      where id = campaign.id;
    end if;
    if stage.id is not null and stage.status = 'token_issued' then
      update private.campaign_stages
      set
        status = 'rejected',
        consumed_at = now(),
        outcome = p_outcome,
        score = greatest(p_score, 0),
        duration_ms = greatest(p_duration_ms, 0),
        verification = 'rejected',
        defeat_reason = case when p_outcome = 'defeat' then p_defeat_reason else null end,
        rejection_code = rejection
      where id = stage.id;
    end if;
    response := jsonb_build_object(
      'status', 'rejected',
      'code', rejection,
      'campaign_id', p_campaign_id,
      'ranked', false
    );
    return private.finish_command_receipt(
      receipt_id, 'rejected', response, rejection
    );
  end if;

  insert into public.character_progress (user_id, character_id)
  values (p_user_id, campaign.character_id)
  on conflict (user_id, character_id) do nothing;

  perform 1
  from public.character_progress
  where user_id = p_user_id and character_id = campaign.character_id
  for update;

  update public.character_progress
  set
    mastery_xp = mastery_xp + p_mastery_xp,
    mastery_level = least(30, ((mastery_xp + p_mastery_xp) / 1000)::smallint)
  where user_id = p_user_id and character_id = campaign.character_id;

  update private.campaign_stages
  set
    status = 'accepted',
    consumed_at = now(),
    outcome = p_outcome,
    score = p_score,
    duration_ms = p_duration_ms,
    verification = 'verified',
    defeat_reason = case when p_outcome = 'defeat' then p_defeat_reason else null end
  where id = stage.id;

  if p_outcome = 'defeat' then
    lost_currency := campaign.provisional_currency;
    update public.campaign_runs
    set
      state = 'failed',
      total_score = total_score + p_score,
      total_duration_ms = total_duration_ms + p_duration_ms,
      lives_remaining = 0,
      provisional_currency = 0,
      ended_at = now()
    where id = campaign.id
    returning * into campaign;

    insert into public.run_results (
      campaign_id,
      user_id,
      character_id,
      mode,
      outcome,
      completed,
      level_reached,
      total_score,
      duration_ms,
      defeat_reason,
      validation,
      content_version,
      protocol_version,
      ended_at
    ) values (
      campaign.id,
      p_user_id,
      campaign.character_id,
      campaign.mode,
      'defeat',
      false,
      stage.sequence,
      campaign.total_score,
      campaign.total_duration_ms,
      coalesce(p_defeat_reason, 'lives_depleted'),
      'verified',
      campaign.content_version,
      campaign.protocol_version,
      campaign.ended_at
    ) returning id into result_id;

    perform private.publish_best_result(result_id);
    response := jsonb_build_object(
      'status', 'accepted',
      'campaign_id', campaign.id,
      'state', campaign.state,
      'result_id', result_id,
      'ranked', true,
      'level_reached', stage.sequence,
      'mastery_xp_granted', p_mastery_xp,
      'currency_lost', lost_currency,
      'unique_drop_granted', false
    );
    return private.finish_command_receipt(receipt_id, 'accepted', response);
  end if;

  update public.campaign_runs
  set
    total_score = total_score + p_score,
    total_duration_ms = total_duration_ms + p_duration_ms,
    provisional_currency = provisional_currency + p_currency_earned,
    expected_sequence = expected_sequence + 1,
    current_level = least(10, current_level + 1),
    lease_expires_at = now() + interval '6 hours'
  where id = campaign.id
  returning * into campaign;

  response := jsonb_build_object(
    'status', 'accepted',
    'campaign_id', campaign.id,
    'state', campaign.state,
    'level_completed', stage.sequence,
    'next_sequence', campaign.expected_sequence,
    'ready_to_complete', campaign.expected_sequence = 11,
    'temporary_currency', campaign.provisional_currency,
    'mastery_xp_granted', p_mastery_xp,
    'unique_drop_granted', false
  );
  return private.finish_command_receipt(receipt_id, 'accepted', response);
end;
$$;

create or replace function public.apply_complete_campaign(
  p_user_id uuid,
  p_campaign_id uuid,
  p_idempotency_key uuid,
  p_request_digest text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  receipt_id uuid;
  existing_receipt private.command_receipts%rowtype;
  campaign public.campaign_runs%rowtype;
  result_id uuid;
  banked bigint;
  response jsonb;
begin
  if p_request_digest !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid digest' using errcode = '22023';
  end if;

  insert into private.command_receipts (
    user_id, command_type, idempotency_key, request_digest
  ) values (
    p_user_id, 'complete-campaign', p_idempotency_key, p_request_digest
  )
  on conflict (user_id, command_type, idempotency_key) do nothing
  returning id into receipt_id;

  if receipt_id is null then
    select * into existing_receipt
    from private.command_receipts
    where user_id = p_user_id
      and command_type = 'complete-campaign'
      and idempotency_key = p_idempotency_key;
    if existing_receipt.request_digest <> p_request_digest then
      raise exception 'idempotency key reused with different request'
        using errcode = '22023';
    end if;
    if existing_receipt.status = 'processing' then
      raise exception 'command is still processing' using errcode = '55000';
    end if;
    return existing_receipt.response;
  end if;

  select * into campaign
  from public.campaign_runs
  where id = p_campaign_id and user_id = p_user_id
  for update;

  if not found or campaign.state <> 'active' or campaign.expected_sequence <> 11 then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'campaign_not_ready'
    );
    return private.finish_command_receipt(
      receipt_id, 'rejected', response, 'campaign_not_ready'
    );
  end if;

  perform 1
  from public.character_progress
  where user_id = p_user_id and character_id = campaign.character_id
  for update;

  banked := campaign.provisional_currency;
  update public.character_progress
  set
    banked_currency = banked_currency + banked,
    purchase_phase_unlocked = true
  where user_id = p_user_id and character_id = campaign.character_id;

  update public.campaign_runs
  set
    state = 'completed',
    provisional_currency = 0,
    ended_at = now()
  where id = campaign.id
  returning * into campaign;

  insert into public.run_results (
    campaign_id,
    user_id,
    character_id,
    mode,
    outcome,
    completed,
    level_reached,
    total_score,
    duration_ms,
    validation,
    content_version,
    protocol_version,
    ended_at
  ) values (
    campaign.id,
    p_user_id,
    campaign.character_id,
    campaign.mode,
    'victory',
    true,
    10,
    campaign.total_score,
    campaign.total_duration_ms,
    'verified',
    campaign.content_version,
    campaign.protocol_version,
    campaign.ended_at
  ) returning id into result_id;

  perform private.publish_best_result(result_id);
  response := jsonb_build_object(
    'status', 'accepted',
    'campaign_id', campaign.id,
    'state', campaign.state,
    'result_id', result_id,
    'ranked', true,
    'banked_currency', banked,
    'purchase_phase_unlocked', true
  );
  return private.finish_command_receipt(receipt_id, 'accepted', response);
end;
$$;

create or replace function public.get_leaderboard_page(
  p_character_id text,
  p_mode public.game_mode,
  p_content_version text,
  p_limit integer default 25,
  p_after_completed boolean default null,
  p_after_level smallint default null,
  p_after_score bigint default null,
  p_after_duration_ms bigint default null,
  p_after_ended_at timestamptz default null,
  p_after_id uuid default null
)
returns table (
  "position" bigint,
  id uuid,
  display_name text,
  character_id text,
  mode public.game_mode,
  content_version text,
  completed boolean,
  level_reached smallint,
  total_score bigint,
  duration_ms bigint,
  ended_at timestamptz,
  validation public.validation_status
)
language sql
stable
security definer
set search_path = ''
as $$
  with ranked as (
    select
      row_number() over (
        order by
          entry.completed desc,
          entry.level_reached desc,
          entry.total_score desc,
          entry.duration_ms asc,
          entry.ended_at asc,
          entry.id asc
      ) as rank_position,
      entry.id,
      entry.display_name,
      entry.character_id,
      entry.mode,
      entry.content_version,
      entry.completed,
      entry.level_reached,
      entry.total_score,
      entry.duration_ms,
      entry.ended_at,
      entry.validation
    from public.leaderboard_entries as entry
    where entry.character_id = p_character_id
      and entry.mode = p_mode
      and entry.content_version = p_content_version
      and entry.validation = 'verified'
      and (select auth.uid()) is not null
  )
  select
    ranked.rank_position,
    ranked.id,
    ranked.display_name,
    ranked.character_id,
    ranked.mode,
    ranked.content_version,
    ranked.completed,
    ranked.level_reached,
    ranked.total_score,
    ranked.duration_ms,
    ranked.ended_at,
    ranked.validation
  from ranked
  where ranked.rank_position <= 100
    and (
      p_after_id is null
      or ranked.completed < p_after_completed
      or (ranked.completed = p_after_completed
        and ranked.level_reached < p_after_level)
      or (ranked.completed = p_after_completed
        and ranked.level_reached = p_after_level
        and ranked.total_score < p_after_score)
      or (ranked.completed = p_after_completed
        and ranked.level_reached = p_after_level
        and ranked.total_score = p_after_score
        and ranked.duration_ms > p_after_duration_ms)
      or (ranked.completed = p_after_completed
        and ranked.level_reached = p_after_level
        and ranked.total_score = p_after_score
        and ranked.duration_ms = p_after_duration_ms
        and ranked.ended_at > p_after_ended_at)
      or (ranked.completed = p_after_completed
        and ranked.level_reached = p_after_level
        and ranked.total_score = p_after_score
        and ranked.duration_ms = p_after_duration_ms
        and ranked.ended_at = p_after_ended_at
        and ranked.id > p_after_id)
    )
  order by
    ranked.completed desc,
    ranked.level_reached desc,
    ranked.total_score desc,
    ranked.duration_ms asc,
    ranked.ended_at asc,
    ranked.id asc
  limit least(greatest(p_limit, 1), 25);
$$;

revoke all on function private.finish_command_receipt(
  uuid, public.command_status, jsonb, text
) from public, anon, authenticated;
revoke all on function private.publish_best_result(uuid)
from public, anon, authenticated;

revoke all on function public.start_campaign(
  text, public.game_mode, text, integer, text, smallint, uuid, text
) from public, anon;
grant execute on function public.start_campaign(
  text, public.game_mode, text, integer, text, smallint, uuid, text
) to authenticated;

revoke all on function public.start_stage(
  uuid, text, text, timestamptz, timestamptz, smallint, smallint, uuid, text
) from public, anon;
grant execute on function public.start_stage(
  uuid, text, text, timestamptz, timestamptz, smallint, smallint, uuid, text
) to authenticated;

revoke all on function public.fail_campaign(uuid, uuid, text)
from public, anon;
grant execute on function public.fail_campaign(uuid, uuid, text)
to authenticated;

revoke all on function public.apply_finish_stage(
  uuid, uuid, text, public.run_outcome, bigint, bigint, text,
  bigint, bigint, uuid, text
) from public, anon, authenticated;
grant execute on function public.apply_finish_stage(
  uuid, uuid, text, public.run_outcome, bigint, bigint, text,
  bigint, bigint, uuid, text
) to service_role;

revoke all on function public.apply_complete_campaign(
  uuid, uuid, uuid, text
) from public, anon, authenticated;
grant execute on function public.apply_complete_campaign(
  uuid, uuid, uuid, text
) to service_role;

revoke all on function public.get_leaderboard_page(
  text, public.game_mode, text, integer, boolean, smallint, bigint,
  bigint, timestamptz, uuid
) from public, anon;
grant execute on function public.get_leaderboard_page(
  text, public.game_mode, text, integer, boolean, smallint, bigint,
  bigint, timestamptz, uuid
) to authenticated;
