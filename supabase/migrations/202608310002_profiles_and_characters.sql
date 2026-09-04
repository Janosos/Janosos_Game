-- Janosos V6 phase 3: stable character catalog and permanent progress roots.

create table public.characters (
  id text primary key check (id ~ '^[a-z][a-z0-9_]{1,31}$'),
  display_name text not null unique check (
    char_length(display_name) between 2 and 32
    and display_name = btrim(display_name)
  ),
  sort_order smallint not null unique check (sort_order between 1 and 100),
  base_lives smallint not null default 1 check (base_lives between 1 and 3),
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.characters (id, display_name, sort_order, base_lives)
values
  ('jano', 'Jano', 1, 1),
  ('parker', 'Parker', 2, 2),
  ('chema', 'Chema', 3, 1),
  ('conra', 'Conra', 4, 1),
  ('shyno', 'Shyno', 5, 1),
  ('nakama', 'Nakama', 6, 1),
  ('nanic', 'Nanic', 7, 1);

create table public.character_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  character_id text not null references public.characters(id),
  mastery_xp bigint not null default 0 check (mastery_xp >= 0),
  mastery_level smallint not null default 0
    check (mastery_level between 0 and 30),
  banked_currency bigint not null default 0 check (banked_currency >= 0),
  purchase_phase_unlocked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, character_id)
);

comment on table public.character_progress is
  'Authoritative per-character progression. Clients have read-only access to their own rows.';

create table private.premium_wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  balance bigint not null default 0 check (balance >= 0),
  currency_code text not null default 'PREMIUM'
    check (currency_code = 'PREMIUM'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table private.supported_client_versions (
  content_version text not null,
  protocol_version integer not null check (protocol_version between 1 and 100000),
  supported_from timestamptz not null default now(),
  supported_until timestamptz not null,
  rank_eligible boolean not null default true,
  primary key (content_version, protocol_version),
  check (supported_until > supported_from)
);

insert into private.supported_client_versions (
  content_version, protocol_version, supported_until, rank_eligible
) values
  ('v6-preview-1', 1, '2100-01-01 00:00:00+00', true),
  ('v5-legacy', 1, now() + interval '90 days', false);

comment on table private.premium_wallets is
  'Schema-only future monetization root. V6 exposes no read, grant, spend, purchase, or payment API.';

create trigger characters_touch_updated_at
before update on public.characters
for each row execute function private.touch_updated_at();

create trigger character_progress_touch_updated_at
before update on public.character_progress
for each row execute function private.touch_updated_at();

create trigger premium_wallets_touch_updated_at
before update on private.premium_wallets
for each row execute function private.touch_updated_at();
