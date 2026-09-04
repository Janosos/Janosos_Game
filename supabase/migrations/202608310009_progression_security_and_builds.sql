-- Janosos V6 phase 4: progression reads, mastery derivation, and build authority.

alter table public.stat_catalog enable row level security;
alter table public.stat_rank_catalog enable row level security;
alter table public.mastery_baseline_catalog enable row level security;
alter table public.skill_catalog enable row level security;
alter table public.skin_catalog enable row level security;
alter table public.content_manifests enable row level security;
alter table public.stat_upgrades enable row level security;
alter table public.skill_unlocks enable row level security;
alter table public.skin_unlocks enable row level security;
alter table public.loadouts enable row level security;
alter table public.boss_progress enable row level security;

revoke all on table public.stat_catalog,
  public.stat_rank_catalog,
  public.mastery_baseline_catalog,
  public.skill_catalog,
  public.skin_catalog,
  public.content_manifests,
  public.stat_upgrades,
  public.skill_unlocks,
  public.skin_unlocks,
  public.loadouts,
  public.boss_progress from anon, authenticated;

grant select on table public.stat_catalog,
  public.stat_rank_catalog,
  public.mastery_baseline_catalog,
  public.skill_catalog,
  public.skin_catalog,
  public.content_manifests,
  public.stat_upgrades,
  public.skill_unlocks,
  public.skin_unlocks,
  public.loadouts,
  public.boss_progress to authenticated;

create policy stat_catalog_read_authenticated
on public.stat_catalog for select to authenticated using (enabled);

create policy stat_rank_catalog_read_authenticated
on public.stat_rank_catalog for select to authenticated using (
  exists (
    select 1 from public.stat_catalog as stat
    where stat.id = stat_id and stat.enabled
  )
);

create policy mastery_baseline_read_authenticated
on public.mastery_baseline_catalog for select to authenticated using (true);

create policy skill_catalog_read_authenticated
on public.skill_catalog for select to authenticated using (enabled);

create policy skin_catalog_read_authenticated
on public.skin_catalog for select to authenticated using (available_in_v6);

create policy content_manifests_read_authenticated
on public.content_manifests for select to authenticated using (active);

create policy stat_upgrades_read_own
on public.stat_upgrades for select to authenticated using (
  (select auth.uid()) is not null and (select auth.uid()) = user_id
);

create policy skill_unlocks_read_own
on public.skill_unlocks for select to authenticated using (
  (select auth.uid()) is not null and (select auth.uid()) = user_id
);

create policy skin_unlocks_read_own
on public.skin_unlocks for select to authenticated using (
  (select auth.uid()) is not null and (select auth.uid()) = user_id
);

create policy loadouts_read_own
on public.loadouts for select to authenticated using (
  (select auth.uid()) is not null and (select auth.uid()) = user_id
);

create policy boss_progress_read_own
on public.boss_progress for select to authenticated using (
  (select auth.uid()) is not null and (select auth.uid()) = user_id
);

grant all on table public.stat_catalog,
  public.stat_rank_catalog,
  public.mastery_baseline_catalog,
  public.skill_catalog,
  public.skin_catalog,
  public.content_manifests,
  public.stat_upgrades,
  public.skill_unlocks,
  public.skin_unlocks,
  public.loadouts,
  public.boss_progress to service_role;

create or replace function private.mastery_level_for_xp(p_mastery_xp bigint)
returns smallint
language sql
immutable
security definer
set search_path = ''
as $$
  select coalesce(max(level), 0)::smallint
  from generate_series(1, 30) as level
  where greatest(p_mastery_xp, 0) >= (100 * level * (level + 1) / 2);
$$;

create or replace function private.derive_character_mastery()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.mastery_level := private.mastery_level_for_xp(new.mastery_xp);
  return new;
end;
$$;

create trigger character_progress_derive_mastery
before insert or update of mastery_xp on public.character_progress
for each row execute function private.derive_character_mastery();

create or replace function private.effective_stat_bonus(
  p_user_id uuid,
  p_character_id text,
  p_stat_id text,
  p_mastery_level smallint,
  p_mode public.game_mode
)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_mode = 'standard' then 0
    else least(
      case p_stat_id
        when 'speed' then 1000
        when 'jump' then 1000
        when 'damage' then 5000
        when 'vitality' then 1000
        when 'fortune' then 1500
        else 0
      end,
      coalesce((
        select rank.bonus_basis_points
        from public.stat_upgrades as owned
        join public.stat_rank_catalog as rank
          on rank.stat_id = owned.stat_id
          and rank.rank = owned.purchased_rank
        where owned.user_id = p_user_id
          and owned.character_id = p_character_id
          and owned.stat_id = p_stat_id
      ), 0) + coalesce((
        select sum(baseline.bonus_basis_points)::integer
        from public.mastery_baseline_catalog as baseline
        where baseline.stat_id = p_stat_id
          and baseline.mastery_level <= p_mastery_level
          and baseline.content_version = 'v6-preview-1'
      ), 0)
    )
  end;
$$;

create or replace function private.effective_bonus_lives(
  p_user_id uuid,
  p_character_id text,
  p_mode public.game_mode
)
returns smallint
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_mode = 'standard' then 0::smallint
    else coalesce((
      select rank.bonus_lives
      from public.stat_upgrades as owned
      join public.stat_rank_catalog as rank
        on rank.stat_id = owned.stat_id
        and rank.rank = owned.purchased_rank
      where owned.user_id = p_user_id
        and owned.character_id = p_character_id
        and owned.stat_id = 'vitality'
    ), 0::smallint)
  end;
$$;

create or replace function private.authorized_build(
  p_user_id uuid,
  p_character_id text,
  p_mode public.game_mode,
  p_content_version text
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with player as (
    select
      coalesce(progress.mastery_level, 0::smallint) as mastery_level,
      character.base_lives,
      loadout.active_skill_id,
      loadout.passive_skill_1_id,
      loadout.passive_skill_2_id,
      loadout.skin_id
    from public.characters as character
    left join public.character_progress as progress
      on progress.user_id = p_user_id
      and progress.character_id = character.id
    left join public.loadouts as loadout
      on loadout.user_id = p_user_id
      and loadout.character_id = character.id
    where character.id = p_character_id and character.enabled
  ), manifest as (
    select catalog_digest
    from public.content_manifests
    where content_version = p_content_version and active
  )
  select jsonb_build_object(
    'character_id', p_character_id,
    'mode', p_mode,
    'content_version', p_content_version,
    'content_digest', manifest.catalog_digest,
    'mastery_level', player.mastery_level,
    'stats', jsonb_build_object(
      'speed_basis_points', private.effective_stat_bonus(
        p_user_id, p_character_id, 'speed', player.mastery_level, p_mode
      ),
      'jump_basis_points', private.effective_stat_bonus(
        p_user_id, p_character_id, 'jump', player.mastery_level, p_mode
      ),
      'damage_basis_points', private.effective_stat_bonus(
        p_user_id, p_character_id, 'damage', player.mastery_level, p_mode
      ),
      'vitality_basis_points', private.effective_stat_bonus(
        p_user_id, p_character_id, 'vitality', player.mastery_level, p_mode
      ),
      'fortune_basis_points', private.effective_stat_bonus(
        p_user_id, p_character_id, 'fortune', player.mastery_level, p_mode
      ),
      'max_lives', player.base_lives + private.effective_bonus_lives(
        p_user_id, p_character_id, p_mode
      )
    ),
    'loadout', jsonb_build_object(
      'active_skill_id', case
        when p_mode = 'standard' then null
        else player.active_skill_id
      end,
      'default_active', case p_character_id
        when 'jano' then 'pistol_shot'
        when 'conra' then 'intangibility'
        when 'nanic' then 'electric_discharge'
        else null
      end,
      'passive_skill_ids', case
        when p_mode = 'standard' then '[]'::jsonb
        else to_jsonb(array_remove(array[
          player.passive_skill_1_id, player.passive_skill_2_id
        ], null))
      end,
      'skin_id', coalesce(player.skin_id, p_character_id || '_default')
    )
  )
  from player cross join manifest;
$$;

create or replace function private.compute_loadout_digest(
  p_user_id uuid,
  p_character_id text,
  p_mode public.game_mode,
  p_content_version text
)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select encode(
    extensions.digest(
      convert_to(coalesce(
        private.authorized_build(
          p_user_id, p_character_id, p_mode, p_content_version
        )::text,
        ''
      ), 'UTF8'),
      'sha256'
    ),
    'hex'
  );
$$;

create or replace function private.authorize_campaign_build()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  base_lives smallint;
begin
  select character.base_lives into strict base_lives
  from public.characters as character
  where character.id = new.character_id and character.enabled;

  new.loadout_digest := private.compute_loadout_digest(
    new.user_id, new.character_id, new.mode, new.content_version
  );
  if new.loadout_digest is null or new.loadout_digest !~ '^[0-9a-f]{64}$' then
    raise exception 'unsupported progression content' using errcode = '22023';
  end if;
  new.lives_remaining := base_lives + private.effective_bonus_lives(
    new.user_id, new.character_id, new.mode
  );
  return new;
end;
$$;

create trigger campaign_runs_authorize_build
before insert on public.campaign_runs
for each row execute function private.authorize_campaign_build();

create or replace function public.get_progression_snapshot(
  p_character_id text,
  p_content_version text
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with caller as (
    select auth.uid() as user_id
  ), player as (
    select
      caller.user_id,
      coalesce(progress.mastery_xp, 0::bigint) as mastery_xp,
      coalesce(progress.mastery_level, 0::smallint) as mastery_level,
      coalesce(progress.banked_currency, 0::bigint) as banked_currency,
      coalesce(progress.purchase_phase_unlocked, false) as store_unlocked
    from caller
    left join public.character_progress as progress
      on progress.user_id = caller.user_id
      and progress.character_id = p_character_id
    where caller.user_id is not null
  ), build as (
    select private.authorized_build(
      player.user_id, p_character_id, 'progression', p_content_version
    ) as value
    from player
  )
  select jsonb_build_object(
    'character_id', p_character_id,
    'content_version', p_content_version,
    'content_digest', manifest.catalog_digest,
    'mastery_xp', player.mastery_xp,
    'mastery_level', player.mastery_level,
    'next_level_xp', case
      when player.mastery_level >= 30 then player.mastery_xp
      else 100 * (player.mastery_level + 1) * (player.mastery_level + 2) / 2
    end,
    'banked_currency', player.banked_currency,
    'temporary_currency', coalesce((
      select campaign.provisional_currency
      from public.campaign_runs as campaign
      where campaign.user_id = player.user_id
        and campaign.character_id = p_character_id
        and campaign.state = 'active'
      limit 1
    ), 0),
    'store_unlocked', player.store_unlocked,
    'authorized_build', build.value,
    'stats', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', stat.id,
          'display_name', stat.display_name,
          'description', stat.description,
          'rank', coalesce(owned.purchased_rank, 0),
          'max_rank', stat.max_rank,
          'effective_basis_points', private.effective_stat_bonus(
            player.user_id, p_character_id, stat.id,
            player.mastery_level, 'progression'
          ),
          'next_cost', next_rank.cost,
          'next_unlock_level', next_rank.mastery_level_required,
          'next_bonus_basis_points', next_rank.bonus_basis_points,
          'next_bonus_lives', next_rank.bonus_lives
        ) order by stat.sort_order
      )
      from public.stat_catalog as stat
      left join public.stat_upgrades as owned
        on owned.user_id = player.user_id
        and owned.character_id = p_character_id
        and owned.stat_id = stat.id
      left join public.stat_rank_catalog as next_rank
        on next_rank.stat_id = stat.id
        and next_rank.rank = coalesce(owned.purchased_rank, 0) + 1
      where stat.content_version = p_content_version and stat.enabled
    ), '[]'::jsonb),
    'skills', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', skill.id,
          'slot', skill.slot,
          'display_name', skill.display_name,
          'description', skill.description,
          'unlock_level', skill.unlock_level,
          'cost', skill.cost,
          'effect_code', skill.effect_code,
          'effect_parameters', skill.effect_parameters,
          'ui_explanation', skill.ui_explanation,
          'compatible_modes', to_jsonb(skill.compatible_modes),
          'owned', owned.skill_id is not null
        ) order by skill.sort_order
      )
      from public.skill_catalog as skill
      left join public.skill_unlocks as owned
        on owned.user_id = player.user_id
        and owned.character_id = p_character_id
        and owned.skill_id = skill.id
      where skill.character_id = p_character_id
        and skill.content_version = p_content_version
        and skill.enabled
    ), '[]'::jsonb),
    'skins', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', skin.id,
          'display_name', skin.display_name,
          'asset_model', skin.asset_model,
          'palette_parameters', skin.palette_parameters,
          'unlock_level', skin.unlock_level,
          'cost', skin.cost,
          'owned', skin.cost = 0 or owned.skin_id is not null,
          'equipped', coalesce(loadout.skin_id, p_character_id || '_default') = skin.id
        ) order by skin.sort_order
      )
      from public.skin_catalog as skin
      left join public.skin_unlocks as owned
        on owned.user_id = player.user_id
        and owned.character_id = p_character_id
        and owned.skin_id = skin.id
      left join public.loadouts as loadout
        on loadout.user_id = player.user_id
        and loadout.character_id = p_character_id
      where skin.character_id = p_character_id
        and skin.content_version = p_content_version
        and skin.available_in_v6
    ), '[]'::jsonb)
  )
  from player
  join public.content_manifests as manifest
    on manifest.content_version = p_content_version and manifest.active
  cross join build
  where exists (
    select 1 from public.characters
    where id = p_character_id and enabled
  );
$$;

create or replace function public.get_authorized_run_configuration(
  p_user_id uuid,
  p_character_id text,
  p_mode public.game_mode,
  p_content_version text
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select private.authorized_build(
    p_user_id, p_character_id, p_mode, p_content_version
  );
$$;

revoke all on function private.mastery_level_for_xp(bigint),
  private.effective_stat_bonus(uuid, text, text, smallint, public.game_mode),
  private.effective_bonus_lives(uuid, text, public.game_mode),
  private.authorized_build(uuid, text, public.game_mode, text),
  private.compute_loadout_digest(uuid, text, public.game_mode, text),
  public.get_authorized_run_configuration(uuid, text, public.game_mode, text)
from public, anon, authenticated;

grant execute on function private.mastery_level_for_xp(bigint),
  private.effective_stat_bonus(uuid, text, text, smallint, public.game_mode),
  private.effective_bonus_lives(uuid, text, public.game_mode),
  private.authorized_build(uuid, text, public.game_mode, text),
  private.compute_loadout_digest(uuid, text, public.game_mode, text),
  public.get_authorized_run_configuration(uuid, text, public.game_mode, text)
to service_role;

revoke all on function public.get_progression_snapshot(text, text)
from public, anon;
grant execute on function public.get_progression_snapshot(text, text)
to authenticated;
