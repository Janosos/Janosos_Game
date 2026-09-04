-- Janosos V6 phase 3: campaign lease, private stage tokens, and personal history.

create table public.campaign_runs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  character_id text not null references public.characters(id),
  mode public.game_mode not null,
  state public.campaign_state not null default 'active',
  current_level smallint not null default 1
    check (current_level between 1 and 10),
  expected_sequence smallint not null default 1
    check (expected_sequence between 1 and 11),
  content_version text not null check (
    char_length(content_version) between 1 and 48
    and content_version = btrim(content_version)
  ),
  protocol_version integer not null check (protocol_version between 1 and 100000),
  loadout_digest text not null check (loadout_digest ~ '^[0-9a-f]{64}$'),
  lease_id uuid not null default gen_random_uuid(),
  lease_expires_at timestamptz not null,
  total_score bigint not null default 0 check (total_score >= 0),
  total_duration_ms bigint not null default 0 check (total_duration_ms >= 0),
  provisional_currency bigint not null default 0
    check (provisional_currency >= 0),
  lives_remaining smallint not null check (lives_remaining between 0 and 99),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  updated_at timestamptz not null default now(),
  constraint campaign_terminal_timestamp check (
    (state = 'active' and ended_at is null)
    or (state <> 'active' and ended_at is not null)
  ),
  constraint campaign_expected_sequence_matches_state check (
    state <> 'completed' or expected_sequence = 11
  )
);

comment on table public.campaign_runs is
  'Server-owned campaign summary. Exactly one active lease is permitted per account.';

create unique index campaign_runs_one_active_per_user
on public.campaign_runs (user_id)
where state = 'active';

create index campaign_runs_user_recent
on public.campaign_runs (user_id, started_at desc, id desc);

create trigger campaign_runs_touch_updated_at
before update on public.campaign_runs
for each row execute function private.touch_updated_at();

create table private.campaign_stages (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaign_runs(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  sequence smallint not null check (sequence between 1 and 10),
  status public.stage_status not null default 'token_issued',
  token_digest text not null unique check (token_digest ~ '^[0-9a-f]{64}$'),
  configuration_digest text not null
    check (configuration_digest ~ '^[0-9a-f]{64}$'),
  signing_key_version smallint not null check (signing_key_version > 0),
  drop_key_version smallint not null check (drop_key_version > 0),
  issued_at timestamptz not null default now(),
  expires_at timestamptz not null,
  consumed_at timestamptz,
  outcome public.run_outcome,
  score bigint check (score is null or score >= 0),
  duration_ms bigint check (duration_ms is null or duration_ms >= 0),
  verification public.validation_status not null default 'pending',
  defeat_reason text check (
    defeat_reason is null or defeat_reason ~ '^[a-z0-9_]{1,48}$'
  ),
  rejection_code text check (
    rejection_code is null or rejection_code ~ '^[a-z0-9_]{1,48}$'
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (campaign_id, sequence),
  constraint campaign_stage_token_lifetime check (
    expires_at > issued_at
    and expires_at <= issued_at + interval '6 hours'
  ),
  constraint campaign_stage_terminal_fields check (
    (status in ('token_issued', 'playing', 'finished_pending')
      and consumed_at is null and outcome is null and score is null
      and duration_ms is null and verification = 'pending')
    or (status in ('accepted', 'rejected')
      and consumed_at is not null and outcome is not null
      and score is not null and duration_ms is not null
      and verification <> 'pending')
  )
);

comment on table private.campaign_stages is
  'Private one-use stage-token state. Raw signed tokens are never persisted here.';

create index campaign_stages_user_campaign
on private.campaign_stages (user_id, campaign_id, sequence);

create trigger campaign_stages_touch_updated_at
before update on private.campaign_stages
for each row execute function private.touch_updated_at();

create table public.run_results (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null unique
    references public.campaign_runs(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  character_id text not null references public.characters(id),
  mode public.game_mode not null,
  outcome public.run_outcome not null,
  completed boolean not null,
  level_reached smallint not null check (level_reached between 1 and 10),
  total_score bigint not null check (total_score >= 0),
  duration_ms bigint not null check (duration_ms >= 0),
  defeat_reason text check (
    defeat_reason is null or defeat_reason ~ '^[a-z0-9_]{1,48}$'
  ),
  validation public.validation_status not null,
  rejection_code text check (
    rejection_code is null or rejection_code ~ '^[a-z0-9_]{1,48}$'
  ),
  content_version text not null check (
    char_length(content_version) between 1 and 48
  ),
  protocol_version integer not null check (protocol_version between 1 and 100000),
  ended_at timestamptz not null,
  accepted_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint run_result_outcome_matches_completion check (
    (completed and outcome = 'victory')
    or (not completed and outcome = 'defeat')
  ),
  constraint progression_completion_reaches_ten check (
    mode <> 'progression' or not completed or level_reached = 10
  )
);

comment on table public.run_results is
  'Authoritative personal run history. A client can read only its own rows.';

create index run_results_personal_history
on public.run_results (user_id, accepted_at desc, id desc);

