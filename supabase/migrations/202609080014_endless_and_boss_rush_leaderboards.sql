-- Janosos V6: Online leaderboards for Endless and Boss Rush with unique records per player.

-- 1. Endless leaderboard: 1 record per user (best score)
create table if not exists public.leaderboard_endless (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (
    char_length(display_name) between 1 and 32
    and display_name = btrim(display_name)
  ),
  character_id text not null,
  score bigint not null check (score >= 0),
  duration_ms bigint not null check (duration_ms >= 0),
  content_version text not null default 'v6-preview-1',
  updated_at timestamptz not null default now()
);

comment on table public.leaderboard_endless is
  'Unique highest-score record per user in Endless mode.';

create index if not exists leaderboard_endless_ranking_idx
on public.leaderboard_endless (score desc, duration_ms desc, updated_at asc);

-- 2. Boss Rush leaderboard: 1 record per user (total clears count)
create table if not exists public.leaderboard_boss_rush (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (
    char_length(display_name) between 1 and 32
    and display_name = btrim(display_name)
  ),
  completions_count integer not null default 1 check (completions_count >= 1),
  content_version text not null default 'v6-preview-1',
  updated_at timestamptz not null default now()
);

comment on table public.leaderboard_boss_rush is
  'Unique completion-count record per user in Boss Rush mode.';

create index if not exists leaderboard_boss_rush_ranking_idx
on public.leaderboard_boss_rush (completions_count desc, updated_at asc);

-- 3. Enable RLS
alter table public.leaderboard_endless enable row level security;
alter table public.leaderboard_boss_rush enable row level security;

-- 4. RLS policies (idempotent): anyone can read, owner can insert/update
drop policy if exists leaderboard_endless_select_all on public.leaderboard_endless;
create policy leaderboard_endless_select_all
on public.leaderboard_endless for select
using (true);

drop policy if exists leaderboard_endless_insert_owner on public.leaderboard_endless;
create policy leaderboard_endless_insert_owner
on public.leaderboard_endless for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists leaderboard_endless_update_owner on public.leaderboard_endless;
create policy leaderboard_endless_update_owner
on public.leaderboard_endless for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists leaderboard_boss_rush_select_all on public.leaderboard_boss_rush;
create policy leaderboard_boss_rush_select_all
on public.leaderboard_boss_rush for select
using (true);

drop policy if exists leaderboard_boss_rush_insert_owner on public.leaderboard_boss_rush;
create policy leaderboard_boss_rush_insert_owner
on public.leaderboard_boss_rush for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists leaderboard_boss_rush_update_owner on public.leaderboard_boss_rush;
create policy leaderboard_boss_rush_update_owner
on public.leaderboard_boss_rush for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- 5. Grants
grant select on public.leaderboard_endless to anon, authenticated;
grant insert, update on public.leaderboard_endless to authenticated;
grant all on public.leaderboard_endless to service_role;

grant select on public.leaderboard_boss_rush to anon, authenticated;
grant insert, update on public.leaderboard_boss_rush to authenticated;
grant all on public.leaderboard_boss_rush to service_role;

-- 6. Helper RPC for Endless: records run and updates only if higher score
create or replace function public.record_endless_score(
  p_character_id text,
  p_score bigint,
  p_duration_ms bigint
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  player_name text;
begin
  -- Try to get display_name from public.profiles
  begin
    select display_name into player_name
    from public.profiles
    where user_id = auth.uid();
  exception when others then
    player_name := null;
  end;

  -- Fallback to auth.users raw_user_meta_data
  if player_name is null or btrim(player_name) = '' then
    select coalesce(
      raw_user_meta_data->>'display_name',
      raw_user_meta_data->>'full_name',
      raw_user_meta_data->>'name',
      'Jugador'
    )
    into player_name
    from auth.users
    where id = auth.uid();
  end if;

  if player_name is null or btrim(player_name) = '' then
    player_name := 'Jugador';
  end if;

  insert into public.leaderboard_endless (
    user_id,
    display_name,
    character_id,
    score,
    duration_ms,
    updated_at
  ) values (
    auth.uid(),
    player_name,
    p_character_id,
    p_score,
    p_duration_ms,
    now()
  )
  on conflict (user_id)
  do update set
    display_name = excluded.display_name,
    character_id = case when excluded.score > public.leaderboard_endless.score then excluded.character_id else public.leaderboard_endless.character_id end,
    duration_ms = case when excluded.score > public.leaderboard_endless.score then excluded.duration_ms else public.leaderboard_endless.duration_ms end,
    updated_at = case when excluded.score > public.leaderboard_endless.score then now() else public.leaderboard_endless.updated_at end,
    score = greatest(public.leaderboard_endless.score, excluded.score);
end;
$$;

grant execute on function public.record_endless_score(text, bigint, bigint) to authenticated;

-- 7. Helper RPC for Boss Rush: increments clears count
create or replace function public.record_boss_rush_clear()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  player_name text;
begin
  -- Try to get display_name from public.profiles
  begin
    select display_name into player_name
    from public.profiles
    where user_id = auth.uid();
  exception when others then
    player_name := null;
  end;

  -- Fallback to auth.users raw_user_meta_data
  if player_name is null or btrim(player_name) = '' then
    select coalesce(
      raw_user_meta_data->>'display_name',
      raw_user_meta_data->>'full_name',
      raw_user_meta_data->>'name',
      'Jugador'
    )
    into player_name
    from auth.users
    where id = auth.uid();
  end if;

  if player_name is null or btrim(player_name) = '' then
    player_name := 'Jugador';
  end if;

  insert into public.leaderboard_boss_rush (
    user_id,
    display_name,
    completions_count,
    updated_at
  ) values (
    auth.uid(),
    player_name,
    1,
    now()
  )
  on conflict (user_id)
  do update set
    display_name = excluded.display_name,
    completions_count = public.leaderboard_boss_rush.completions_count + 1,
    updated_at = now();
end;
$$;

grant execute on function public.record_boss_rush_clear() to authenticated;
