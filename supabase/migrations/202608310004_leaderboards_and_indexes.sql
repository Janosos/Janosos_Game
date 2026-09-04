-- Janosos V6 phase 3: verified global best results with canonical keyset order.

create table public.leaderboard_entries (
  id uuid primary key default gen_random_uuid(),
  result_id uuid not null unique references public.run_results(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null check (
    char_length(display_name) between 1 and 32
    and display_name = btrim(display_name)
  ),
  character_id text not null references public.characters(id),
  mode public.game_mode not null,
  content_version text not null check (
    char_length(content_version) between 1 and 48
  ),
  completed boolean not null,
  level_reached smallint not null check (level_reached between 1 and 10),
  total_score bigint not null check (total_score >= 0),
  duration_ms bigint not null check (duration_ms >= 0),
  ended_at timestamptz not null,
  validation public.validation_status not null default 'verified'
    check (validation = 'verified'),
  updated_at timestamptz not null default now(),
  unique (user_id, character_id, mode, content_version)
);

comment on table public.leaderboard_entries is
  'One verified best result per user, character, mode, and content version.';

create index leaderboard_entries_verified_keyset
on public.leaderboard_entries (
  character_id,
  mode,
  content_version,
  completed desc,
  level_reached desc,
  total_score desc,
  duration_ms asc,
  ended_at asc,
  id asc
)
where validation = 'verified';

create trigger leaderboard_entries_touch_updated_at
before update on public.leaderboard_entries
for each row execute function private.touch_updated_at();

