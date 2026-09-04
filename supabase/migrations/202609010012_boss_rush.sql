-- Janosos V6 phase 6: authoritative post-campaign Boss Rush.

alter table public.run_results
  drop constraint run_results_level_reached_check,
  add constraint run_results_level_reached_check check (
    (mode = 'boss_rush' and level_reached between 0 and 10)
    or (mode <> 'boss_rush' and level_reached between 1 and 10)
  );

alter table public.leaderboard_entries
  drop constraint leaderboard_entries_level_reached_check,
  add constraint leaderboard_entries_level_reached_check check (
    (mode = 'boss_rush' and level_reached between 0 and 10)
    or (mode <> 'boss_rush' and level_reached between 1 and 10)
  );

create or replace function public.start_boss_rush(
  p_character_id text,
  p_content_version text,
  p_protocol_version integer,
  p_loadout_digest text,
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
  command record;
  active_campaign public.campaign_runs%rowtype;
  new_campaign public.campaign_runs%rowtype;
  response jsonb;
begin
  select * into command from private.begin_economic_command(
    caller_id, 'start-boss-rush', p_idempotency_key, p_request_digest
  );
  if command.replay_response is not null then
    return command.replay_response;
  end if;

  if p_loadout_digest !~ '^[0-9a-f]{64}$'
    or p_protocol_version not between 1 and 100000 then
    raise exception 'invalid boss rush envelope' using errcode = '22023';
  end if;

  if not exists (
    select 1 from private.supported_client_versions
    where content_version = btrim(p_content_version)
      and protocol_version = p_protocol_version
      and supported_from <= now()
      and supported_until > now()
  ) then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'unsupported_client_version'
    );
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'unsupported_client_version'
    );
  end if;

  if not exists (
    select 1 from public.character_progress
    where user_id = caller_id
      and character_id = p_character_id
      and purchase_phase_unlocked
  ) then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'boss_rush_locked'
    );
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'boss_rush_locked'
    );
  end if;

  select * into active_campaign
  from public.campaign_runs
  where user_id = caller_id and state = 'active'
  for update;
  if found then
    if active_campaign.lease_expires_at <= now() then
      update private.campaign_stages
      set
        status = 'rejected', consumed_at = now(), outcome = 'defeat',
        score = 0, duration_ms = 0, verification = 'rejected',
        rejection_code = 'campaign_expired'
      where campaign_id = active_campaign.id
        and status in ('token_issued', 'playing', 'finished_pending');
      update public.campaign_runs
      set state = 'expired', provisional_currency = 0, ended_at = now()
      where id = active_campaign.id;
    else
      response := jsonb_build_object(
        'status', 'rejected', 'code', 'campaign_active'
      );
      return private.finish_command_receipt(
        command.receipt_id, 'rejected', response, 'campaign_active'
      );
    end if;
  end if;

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
    'boss_rush',
    btrim(p_content_version),
    p_protocol_version,
    p_loadout_digest,
    now() + interval '6 hours',
    1
  ) returning * into new_campaign;

  response := jsonb_build_object(
    'status', 'accepted',
    'campaign_id', new_campaign.id,
    'state', new_campaign.state,
    'lease_expires_at', new_campaign.lease_expires_at
  );
  return private.finish_command_receipt(
    command.receipt_id, 'accepted', response
  );
end;
$$;

create or replace function public.apply_finish_boss_rush(
  p_user_id uuid,
  p_campaign_id uuid,
  p_token_digest text,
  p_outcome public.run_outcome,
  p_bosses_defeated smallint,
  p_score bigint,
  p_duration_ms bigint,
  p_drop_rolls jsonb,
  p_idempotency_key uuid,
  p_request_digest text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  command record;
  campaign public.campaign_runs%rowtype;
  stage private.campaign_stages%rowtype;
  progress public.boss_progress%rowtype;
  response jsonb;
  result_id uuid;
  mastery_granted bigint;
  expected_reward text;
  supplied_reward text;
  roll integer;
  granted boolean;
  granted_rewards jsonb := '[]'::jsonb;
begin
  select * into command from private.begin_economic_command(
    p_user_id, 'finish-boss-rush', p_idempotency_key, p_request_digest
  );
  if command.replay_response is not null then
    return command.replay_response;
  end if;

  if p_token_digest !~ '^[0-9a-f]{64}$'
    or p_bosses_defeated not between 0 and 10
    or p_score not between 0 and 5000000
    or p_duration_ms not between 1000 and 21600000
    or jsonb_typeof(p_drop_rolls) <> 'array'
    or jsonb_array_length(p_drop_rolls) <> p_bosses_defeated then
    raise exception 'invalid boss rush result' using errcode = '22023';
  end if;
  if (p_outcome = 'victory') <> (p_bosses_defeated = 10) then
    raise exception 'boss rush outcome mismatch' using errcode = '22023';
  end if;

  select * into campaign
  from public.campaign_runs
  where id = p_campaign_id and user_id = p_user_id
  for update;

  select * into stage
  from private.campaign_stages
  where campaign_id = p_campaign_id and token_digest = p_token_digest
  for update;

  if campaign.id is null or campaign.mode <> 'boss_rush'
    or campaign.state <> 'active'
    or stage.id is null
    or stage.status not in ('token_issued', 'playing')
    or stage.expires_at <= now() then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'boss_rush_not_active'
    );
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'boss_rush_not_active'
    );
  end if;

  if not exists (
    select 1 from public.character_progress
    where user_id = p_user_id
      and character_id = campaign.character_id
      and purchase_phase_unlocked
  ) then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'boss_rush_locked'
    );
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'boss_rush_locked'
    );
  end if;

  for current_boss_level in 1..p_bosses_defeated loop
    expected_reward := private.reward_id_for_level(current_boss_level::smallint);
    supplied_reward := p_drop_rolls -> (current_boss_level - 1) ->> 'reward_id';
    roll := (p_drop_rolls -> (current_boss_level - 1) ->> 'roll_basis_points')::integer;
    if (p_drop_rolls -> (current_boss_level - 1) ->> 'level')::smallint <> current_boss_level
      or supplied_reward <> expected_reward
      or roll not between 0 and 9999 then
      raise exception 'invalid boss rush drop material' using errcode = '22023';
    end if;

    select * into progress
    from public.boss_progress
    where user_id = p_user_id
      and character_id = campaign.character_id
      and boss_level = current_boss_level
    for update;

    granted := roll < 100 and (not found or not progress.unique_reward_owned);
    if found then
      update public.boss_progress
      set
        victories = victories + 1,
        unique_reward_id = case when granted then expected_reward else unique_reward_id end,
        unique_reward_owned = unique_reward_owned or granted
      where user_id = p_user_id
        and character_id = campaign.character_id
        and boss_level = current_boss_level;
    else
      insert into public.boss_progress (
        user_id, character_id, boss_level, victories,
        unique_reward_id, unique_reward_owned
      ) values (
        p_user_id, campaign.character_id, current_boss_level, 1,
        case when granted then expected_reward else null end, granted
      );
    end if;
    if granted then
      granted_rewards := granted_rewards || to_jsonb(expected_reward);
    end if;
  end loop;

  mastery_granted := p_bosses_defeated * 20
    + case when p_bosses_defeated = 10 then 50 else 0 end;
  update public.character_progress
  set mastery_xp = mastery_xp + mastery_granted
  where user_id = p_user_id and character_id = campaign.character_id;

  update private.campaign_stages
  set
    status = 'accepted',
    consumed_at = now(),
    outcome = p_outcome,
    score = p_score,
    duration_ms = p_duration_ms,
    verification = 'verified'
  where id = stage.id;

  update public.campaign_runs
  set
    state = case when p_outcome = 'victory'
      then 'completed'::public.campaign_state
      else 'failed'::public.campaign_state
    end,
    current_level = greatest(1, p_bosses_defeated),
    expected_sequence = case when p_outcome = 'victory' then 11 else 1 end,
    total_score = p_score,
    total_duration_ms = p_duration_ms,
    provisional_currency = 0,
    ended_at = now()
  where id = campaign.id
  returning * into campaign;

  insert into public.run_results (
    campaign_id, user_id, character_id, mode, outcome, completed,
    level_reached, total_score, duration_ms, validation,
    content_version, protocol_version, ended_at
  ) values (
    campaign.id, p_user_id, campaign.character_id, 'boss_rush', p_outcome,
    p_outcome = 'victory', p_bosses_defeated, p_score,
    p_duration_ms, 'verified', campaign.content_version,
    campaign.protocol_version, campaign.ended_at
  ) returning id into result_id;

  perform private.publish_best_result(result_id);
  response := jsonb_build_object(
    'status', 'accepted',
    'campaign_id', campaign.id,
    'result_id', result_id,
    'ranked', true,
    'bosses_defeated', p_bosses_defeated,
    'mastery_xp_granted', mastery_granted,
    'currency_granted', 0,
    'purchase_phase_unlocked', false,
    'unique_rewards_granted', granted_rewards
  );
  return private.finish_command_receipt(
    command.receipt_id, 'accepted', response
  );
end;
$$;

revoke all on function public.start_boss_rush(
  text, text, integer, text, uuid, text
) from public, anon;
grant execute on function public.start_boss_rush(
  text, text, integer, text, uuid, text
) to authenticated;

revoke all on function public.apply_finish_boss_rush(
  uuid, uuid, text, public.run_outcome, smallint, bigint, bigint,
  jsonb, uuid, text
) from public, anon, authenticated;
grant execute on function public.apply_finish_boss_rush(
  uuid, uuid, text, public.run_outcome, smallint, bigint, bigint,
  jsonb, uuid, text
) to service_role;
