-- Janosos V6 phase 5: persisted, idempotent boss-drop resolution.

alter table private.campaign_stages
  add column unique_reward_id text,
  add column drop_roll_basis_points integer,
  add column unique_drop_granted boolean;

alter table private.campaign_stages
  add constraint campaign_stage_drop_roll_complete check (
    (drop_roll_basis_points is null and unique_drop_granted is null)
    or (
      outcome = 'victory'
      and unique_reward_id is not null
      and drop_roll_basis_points between 0 and 9999
      and unique_drop_granted is not null
    )
  );

create or replace function private.reward_id_for_level(p_level smallint)
returns text
language sql
immutable
security definer
set search_path = ''
as $$
  select case p_level
    when 1 then 'headless_horseman.spectral_trail'
    when 2 then 'queen_of_hearts.card_aura'
    when 3 then 'mister_hyde.hyde_serum'
    when 4 then 'phantom.phantom_mask'
    when 5 then 'snow_queen.frost_heart'
    when 6 then 'dracula.crimson_cape'
    when 7 then 'wicked_witch.silver_shoes'
    when 8 then 'frankenstein_creature.galvanic_core'
    when 9 then 'davy_jones.abyssal_compass'
    when 10 then 'moriarty.strategist_crown'
  end;
$$;

create or replace function public.apply_finish_stage_with_drop(
  p_user_id uuid,
  p_campaign_id uuid,
  p_token_digest text,
  p_outcome public.run_outcome,
  p_score bigint,
  p_duration_ms bigint,
  p_defeat_reason text,
  p_currency_earned bigint,
  p_mastery_xp bigint,
  p_unique_reward_id text,
  p_drop_roll_basis_points integer,
  p_idempotency_key uuid,
  p_request_digest text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  command_response jsonb;
  campaign public.campaign_runs%rowtype;
  stage private.campaign_stages%rowtype;
  progress public.boss_progress%rowtype;
  expected_reward_id text;
  granted boolean := false;
  already_owned boolean := false;
begin
  if p_drop_roll_basis_points not between 0 and 9999 then
    raise exception 'invalid boss drop roll' using errcode = '22023';
  end if;

  command_response := public.apply_finish_stage(
    p_user_id,
    p_campaign_id,
    p_token_digest,
    p_outcome,
    p_score,
    p_duration_ms,
    p_defeat_reason,
    p_currency_earned,
    p_mastery_xp,
    p_idempotency_key,
    p_request_digest
  );

  if command_response ->> 'status' <> 'accepted' or p_outcome <> 'victory' then
    return command_response;
  end if;

  select * into campaign
  from public.campaign_runs
  where id = p_campaign_id and user_id = p_user_id
  for update;

  select * into stage
  from private.campaign_stages
  where campaign_id = p_campaign_id
    and token_digest = p_token_digest
  for update;

  if not found or stage.status <> 'accepted' then
    raise exception 'accepted stage missing' using errcode = '55000';
  end if;

  if stage.drop_roll_basis_points is not null then
    return command_response;
  end if;

  expected_reward_id := private.reward_id_for_level(stage.sequence);
  if expected_reward_id is null or p_unique_reward_id <> expected_reward_id then
    raise exception 'invalid unique reward' using errcode = '22023';
  end if;

  select * into progress
  from public.boss_progress
  where user_id = p_user_id
    and character_id = campaign.character_id
    and boss_level = stage.sequence
  for update;

  if found then
    already_owned := progress.unique_reward_owned;
    granted := campaign.mode = 'progression'
      and p_drop_roll_basis_points < 100
      and not already_owned;
    update public.boss_progress
    set
      victories = victories + 1,
      unique_reward_id = case
        when granted then expected_reward_id
        else unique_reward_id
      end,
      unique_reward_owned = unique_reward_owned or granted
    where user_id = p_user_id
      and character_id = campaign.character_id
      and boss_level = stage.sequence;
  else
    granted := campaign.mode = 'progression'
      and p_drop_roll_basis_points < 100;
    insert into public.boss_progress (
      user_id,
      character_id,
      boss_level,
      victories,
      unique_reward_id,
      unique_reward_owned
    ) values (
      p_user_id,
      campaign.character_id,
      stage.sequence,
      1,
      case when granted then expected_reward_id else null end,
      granted
    );
  end if;

  update private.campaign_stages
  set
    unique_reward_id = expected_reward_id,
    drop_roll_basis_points = p_drop_roll_basis_points,
    unique_drop_granted = granted
  where id = stage.id;

  command_response := command_response || jsonb_build_object(
    'unique_reward_id', expected_reward_id,
    'unique_drop_granted', granted,
    'unique_drop_already_owned', already_owned
  );

  update private.command_receipts
  set response = command_response
  where user_id = p_user_id
    and command_type = 'finish-stage'
    and idempotency_key = p_idempotency_key;

  return command_response;
end;
$$;

revoke all on function private.reward_id_for_level(smallint),
  public.apply_finish_stage_with_drop(
    uuid, uuid, text, public.run_outcome, bigint, bigint, text,
    bigint, bigint, text, integer, uuid, text
  )
from public, anon, authenticated;

grant execute on function public.apply_finish_stage_with_drop(
  uuid, uuid, text, public.run_outcome, bigint, bigint, text,
  bigint, bigint, text, integer, uuid, text
)
to service_role;
