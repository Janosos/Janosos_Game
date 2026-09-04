-- Janosos V6 phase 4: atomic, idempotent purchases and loadout mutations.

create or replace function private.begin_economic_command(
  p_user_id uuid,
  p_command_type text,
  p_idempotency_key uuid,
  p_request_digest text
)
returns table (receipt_id uuid, replay_response jsonb)
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing_receipt private.command_receipts%rowtype;
begin
  if p_user_id is null or p_request_digest !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid economic command envelope' using errcode = '22023';
  end if;

  insert into private.command_receipts (
    user_id, command_type, idempotency_key, request_digest
  ) values (
    p_user_id, p_command_type, p_idempotency_key, p_request_digest
  )
  on conflict (user_id, command_type, idempotency_key) do nothing
  returning id into receipt_id;

  if receipt_id is not null then
    replay_response := null;
    return next;
    return;
  end if;

  select * into existing_receipt
  from private.command_receipts
  where user_id = p_user_id
    and command_type = p_command_type
    and idempotency_key = p_idempotency_key
  for update;

  if existing_receipt.request_digest <> p_request_digest then
    raise exception 'idempotency key reused with different request'
      using errcode = '22023';
  end if;
  if existing_receipt.status = 'processing' then
    raise exception 'command is still processing' using errcode = '55000';
  end if;

  receipt_id := null;
  replay_response := existing_receipt.response;
  return next;
end;
$$;

create or replace function private.catalog_digest_matches(
  p_content_version text,
  p_catalog_digest text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.content_manifests as manifest
    where manifest.content_version = p_content_version
      and manifest.catalog_digest = p_catalog_digest
      and manifest.active
  );
$$;

create or replace function public.apply_purchase_upgrade(
  p_user_id uuid,
  p_character_id text,
  p_stat_id text,
  p_expected_rank smallint,
  p_content_version text,
  p_catalog_digest text,
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
  progress public.character_progress%rowtype;
  current_rank smallint := 0;
  next_rank public.stat_rank_catalog%rowtype;
  previous_balance bigint;
  response jsonb;
begin
  select * into command from private.begin_economic_command(
    p_user_id, 'purchase-upgrade', p_idempotency_key, p_request_digest
  );
  if command.replay_response is not null then
    return command.replay_response;
  end if;

  if not private.catalog_digest_matches(p_content_version, p_catalog_digest) then
    response := jsonb_build_object('status', 'rejected', 'code', 'stale_catalog');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'stale_catalog'
    );
  end if;

  select * into progress
  from public.character_progress
  where user_id = p_user_id and character_id = p_character_id
  for update;

  if not found or not progress.purchase_phase_unlocked then
    response := jsonb_build_object('status', 'rejected', 'code', 'store_locked');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'store_locked'
    );
  end if;
  if exists (
    select 1 from public.campaign_runs
    where user_id = p_user_id and state = 'active'
  ) then
    response := jsonb_build_object('status', 'rejected', 'code', 'campaign_active');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'campaign_active'
    );
  end if;

  select purchased_rank into current_rank
  from public.stat_upgrades
  where user_id = p_user_id
    and character_id = p_character_id
    and stat_id = p_stat_id
  for update;
  current_rank := coalesce(current_rank, 0);

  if current_rank <> p_expected_rank then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'stale_rank', 'current_rank', current_rank
    );
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'stale_rank'
    );
  end if;

  select * into next_rank
  from public.stat_rank_catalog
  where stat_id = p_stat_id and rank = current_rank + 1;

  if not found then
    response := jsonb_build_object('status', 'rejected', 'code', 'rank_capped');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'rank_capped'
    );
  end if;
  if progress.mastery_level < next_rank.mastery_level_required then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'mastery_required',
      'required_level', next_rank.mastery_level_required
    );
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'mastery_required'
    );
  end if;
  if progress.banked_currency < next_rank.cost then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'insufficient_currency',
      'required_currency', next_rank.cost,
      'current_balance', progress.banked_currency
    );
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'insufficient_currency'
    );
  end if;

  previous_balance := progress.banked_currency;
  update public.character_progress
  set banked_currency = banked_currency - next_rank.cost
  where user_id = p_user_id and character_id = p_character_id;

  insert into public.stat_upgrades (
    user_id, character_id, stat_id, purchased_rank
  ) values (
    p_user_id, p_character_id, p_stat_id, next_rank.rank
  )
  on conflict (user_id, character_id, stat_id) do update
  set purchased_rank = excluded.purchased_rank;

  response := jsonb_build_object(
    'status', 'accepted',
    'character_id', p_character_id,
    'stat_id', p_stat_id,
    'previous_rank', current_rank,
    'new_rank', next_rank.rank,
    'new_bonus_basis_points', next_rank.bonus_basis_points,
    'new_bonus_lives', next_rank.bonus_lives,
    'balance_before', previous_balance,
    'balance_after', previous_balance - next_rank.cost,
    'normalized_in_standard', true
  );
  return private.finish_command_receipt(command.receipt_id, 'accepted', response);
end;
$$;

create or replace function public.apply_purchase_skill(
  p_user_id uuid,
  p_character_id text,
  p_skill_id text,
  p_content_version text,
  p_catalog_digest text,
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
  progress public.character_progress%rowtype;
  skill public.skill_catalog%rowtype;
  previous_balance bigint;
  response jsonb;
begin
  select * into command from private.begin_economic_command(
    p_user_id, 'purchase-skill', p_idempotency_key, p_request_digest
  );
  if command.replay_response is not null then
    return command.replay_response;
  end if;

  if not private.catalog_digest_matches(p_content_version, p_catalog_digest) then
    response := jsonb_build_object('status', 'rejected', 'code', 'stale_catalog');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'stale_catalog'
    );
  end if;

  select * into progress
  from public.character_progress
  where user_id = p_user_id and character_id = p_character_id
  for update;

  if not found or not progress.purchase_phase_unlocked then
    response := jsonb_build_object('status', 'rejected', 'code', 'store_locked');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'store_locked'
    );
  end if;
  if exists (
    select 1 from public.campaign_runs
    where user_id = p_user_id and state = 'active'
  ) then
    response := jsonb_build_object('status', 'rejected', 'code', 'campaign_active');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'campaign_active'
    );
  end if;

  select * into skill
  from public.skill_catalog
  where id = p_skill_id
    and character_id = p_character_id
    and content_version = p_content_version
    and enabled;

  if not found then
    response := jsonb_build_object('status', 'rejected', 'code', 'invalid_skill');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'invalid_skill'
    );
  end if;
  if exists (
    select 1 from public.skill_unlocks
    where user_id = p_user_id
      and character_id = p_character_id
      and skill_id = p_skill_id
  ) then
    response := jsonb_build_object('status', 'rejected', 'code', 'already_owned');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'already_owned'
    );
  end if;
  if progress.mastery_level < skill.unlock_level then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'mastery_required',
      'required_level', skill.unlock_level
    );
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'mastery_required'
    );
  end if;
  if progress.banked_currency < skill.cost then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'insufficient_currency',
      'required_currency', skill.cost,
      'current_balance', progress.banked_currency
    );
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'insufficient_currency'
    );
  end if;

  previous_balance := progress.banked_currency;
  update public.character_progress
  set banked_currency = banked_currency - skill.cost
  where user_id = p_user_id and character_id = p_character_id;

  insert into public.skill_unlocks (
    user_id, character_id, skill_id, source
  ) values (
    p_user_id, p_character_id, p_skill_id, 'purchase'
  );

  response := jsonb_build_object(
    'status', 'accepted',
    'character_id', p_character_id,
    'skill_id', p_skill_id,
    'slot', skill.slot,
    'balance_before', previous_balance,
    'balance_after', previous_balance - skill.cost,
    'normalized_in_standard', true
  );
  return private.finish_command_receipt(command.receipt_id, 'accepted', response);
end;
$$;

create or replace function public.apply_purchase_skin(
  p_user_id uuid,
  p_character_id text,
  p_skin_id text,
  p_content_version text,
  p_catalog_digest text,
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
  progress public.character_progress%rowtype;
  skin public.skin_catalog%rowtype;
  previous_balance bigint;
  response jsonb;
begin
  select * into command from private.begin_economic_command(
    p_user_id, 'purchase-skin', p_idempotency_key, p_request_digest
  );
  if command.replay_response is not null then
    return command.replay_response;
  end if;

  if not private.catalog_digest_matches(p_content_version, p_catalog_digest) then
    response := jsonb_build_object('status', 'rejected', 'code', 'stale_catalog');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'stale_catalog'
    );
  end if;

  select * into progress
  from public.character_progress
  where user_id = p_user_id and character_id = p_character_id
  for update;

  if not found or not progress.purchase_phase_unlocked then
    response := jsonb_build_object('status', 'rejected', 'code', 'store_locked');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'store_locked'
    );
  end if;
  if exists (
    select 1 from public.campaign_runs
    where user_id = p_user_id and state = 'active'
  ) then
    response := jsonb_build_object('status', 'rejected', 'code', 'campaign_active');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'campaign_active'
    );
  end if;

  select * into skin
  from public.skin_catalog
  where id = p_skin_id
    and character_id = p_character_id
    and content_version = p_content_version
    and available_in_v6
    and future_premium_sku is null;

  if not found or skin.cost = 0 then
    response := jsonb_build_object('status', 'rejected', 'code', 'invalid_skin');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'invalid_skin'
    );
  end if;
  if exists (
    select 1 from public.skin_unlocks
    where user_id = p_user_id
      and character_id = p_character_id
      and skin_id = p_skin_id
  ) then
    response := jsonb_build_object('status', 'rejected', 'code', 'already_owned');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'already_owned'
    );
  end if;
  if progress.mastery_level < skin.unlock_level then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'mastery_required',
      'required_level', skin.unlock_level
    );
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'mastery_required'
    );
  end if;
  if progress.banked_currency < skin.cost then
    response := jsonb_build_object(
      'status', 'rejected', 'code', 'insufficient_currency',
      'required_currency', skin.cost,
      'current_balance', progress.banked_currency
    );
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'insufficient_currency'
    );
  end if;

  previous_balance := progress.banked_currency;
  update public.character_progress
  set banked_currency = banked_currency - skin.cost
  where user_id = p_user_id and character_id = p_character_id;

  insert into public.skin_unlocks (
    user_id, character_id, skin_id, source
  ) values (
    p_user_id, p_character_id, p_skin_id, 'purchase'
  );

  response := jsonb_build_object(
    'status', 'accepted',
    'character_id', p_character_id,
    'skin_id', p_skin_id,
    'asset_model', skin.asset_model,
    'balance_before', previous_balance,
    'balance_after', previous_balance - skin.cost,
    'cosmetic_only', true
  );
  return private.finish_command_receipt(command.receipt_id, 'accepted', response);
end;
$$;

create or replace function public.apply_equip_loadout(
  p_user_id uuid,
  p_character_id text,
  p_active_skill_id text,
  p_passive_skill_1_id text,
  p_passive_skill_2_id text,
  p_skin_id text,
  p_content_version text,
  p_catalog_digest text,
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
  response jsonb;
  build jsonb;
begin
  select * into command from private.begin_economic_command(
    p_user_id, 'equip-loadout', p_idempotency_key, p_request_digest
  );
  if command.replay_response is not null then
    return command.replay_response;
  end if;

  if not private.catalog_digest_matches(p_content_version, p_catalog_digest) then
    response := jsonb_build_object('status', 'rejected', 'code', 'stale_catalog');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'stale_catalog'
    );
  end if;

  perform 1
  from public.character_progress
  where user_id = p_user_id and character_id = p_character_id
  for update;
  if not found then
    response := jsonb_build_object('status', 'rejected', 'code', 'progress_not_found');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'progress_not_found'
    );
  end if;
  if exists (
    select 1 from public.campaign_runs
    where user_id = p_user_id and state = 'active'
  ) then
    response := jsonb_build_object('status', 'rejected', 'code', 'campaign_active');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'campaign_active'
    );
  end if;

  if p_passive_skill_1_id is not null
    and p_passive_skill_1_id = p_passive_skill_2_id then
    response := jsonb_build_object('status', 'rejected', 'code', 'duplicate_passive');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'duplicate_passive'
    );
  end if;

  if p_active_skill_id is not null and not exists (
    select 1
    from public.skill_unlocks as owned
    join public.skill_catalog as skill
      on skill.id = owned.skill_id and skill.character_id = owned.character_id
    where owned.user_id = p_user_id
      and owned.character_id = p_character_id
      and owned.skill_id = p_active_skill_id
      and skill.slot = 'active'
      and skill.enabled
  ) then
    response := jsonb_build_object('status', 'rejected', 'code', 'active_not_owned');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'active_not_owned'
    );
  end if;

  if exists (
    select 1
    from unnest(array[p_passive_skill_1_id, p_passive_skill_2_id]) as selected(skill_id)
    where selected.skill_id is not null
      and not exists (
        select 1
        from public.skill_unlocks as owned
        join public.skill_catalog as skill
          on skill.id = owned.skill_id and skill.character_id = owned.character_id
        where owned.user_id = p_user_id
          and owned.character_id = p_character_id
          and owned.skill_id = selected.skill_id
          and skill.slot = 'passive'
          and skill.enabled
      )
  ) then
    response := jsonb_build_object('status', 'rejected', 'code', 'passive_not_owned');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'passive_not_owned'
    );
  end if;

  if p_skin_id is not null
    and p_skin_id <> (p_character_id || '_default')
    and not exists (
      select 1
      from public.skin_unlocks as owned
      join public.skin_catalog as skin
        on skin.id = owned.skin_id and skin.character_id = owned.character_id
      where owned.user_id = p_user_id
        and owned.character_id = p_character_id
        and owned.skin_id = p_skin_id
        and skin.available_in_v6
    ) then
    response := jsonb_build_object('status', 'rejected', 'code', 'skin_not_owned');
    return private.finish_command_receipt(
      command.receipt_id, 'rejected', response, 'skin_not_owned'
    );
  end if;

  insert into public.loadouts (
    user_id, character_id, active_skill_id,
    passive_skill_1_id, passive_skill_2_id, skin_id
  ) values (
    p_user_id, p_character_id, p_active_skill_id,
    p_passive_skill_1_id, p_passive_skill_2_id,
    nullif(p_skin_id, p_character_id || '_default')
  )
  on conflict (user_id, character_id) do update set
    active_skill_id = excluded.active_skill_id,
    passive_skill_1_id = excluded.passive_skill_1_id,
    passive_skill_2_id = excluded.passive_skill_2_id,
    skin_id = excluded.skin_id;

  build := private.authorized_build(
    p_user_id, p_character_id, 'progression', p_content_version
  );
  response := jsonb_build_object(
    'status', 'accepted',
    'character_id', p_character_id,
    'authorized_build', build,
    'loadout_digest', private.compute_loadout_digest(
      p_user_id, p_character_id, 'progression', p_content_version
    ),
    'normalized_in_standard', true
  );
  return private.finish_command_receipt(command.receipt_id, 'accepted', response);
end;
$$;

revoke all on function private.begin_economic_command(uuid, text, uuid, text),
  private.catalog_digest_matches(text, text),
  public.apply_purchase_upgrade(uuid, text, text, smallint, text, text, uuid, text),
  public.apply_purchase_skill(uuid, text, text, text, text, uuid, text),
  public.apply_purchase_skin(uuid, text, text, text, text, uuid, text),
  public.apply_equip_loadout(uuid, text, text, text, text, text, text, text, uuid, text)
from public, anon, authenticated;

grant execute on function private.begin_economic_command(uuid, text, uuid, text),
  private.catalog_digest_matches(text, text),
  public.apply_purchase_upgrade(uuid, text, text, smallint, text, text, uuid, text),
  public.apply_purchase_skill(uuid, text, text, text, text, uuid, text),
  public.apply_purchase_skin(uuid, text, text, text, text, uuid, text),
  public.apply_equip_loadout(uuid, text, text, text, text, text, text, text, uuid, text)
to service_role;
