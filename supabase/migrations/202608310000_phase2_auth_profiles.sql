-- Janosos V6 phase 2: account profile, linked-identity metadata, and
-- privacy-preserving account-deletion receipts.

create extension if not exists pgcrypto with schema extensions;
create schema if not exists private;

revoke all on schema private from public, anon, authenticated;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (
    char_length(display_name) between 1 and 32
    and display_name = btrim(display_name)
  ),
  avatar_key text,
  content_version text not null default 'v6-preview-1',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profile_identities (
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null check (provider in ('email', 'google', 'apple')),
  linked_at timestamptz not null,
  last_seen_at timestamptz not null,
  primary key (user_id, provider)
);

comment on table public.profile_identities is
  'Non-secret provider metadata. Provider access and refresh tokens are never stored.';

create table private.account_deletion_receipts (
  receipt_id uuid primary key default gen_random_uuid(),
  user_hash text not null check (user_hash ~ '^[0-9a-f]{64}$'),
  idempotency_key uuid not null,
  status text not null default 'processing'
    check (status in ('processing', 'completed', 'failed')),
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  failure_code text check (failure_code is null or failure_code ~ '^[a-z0-9_]{1,48}$'),
  constraint account_deletion_receipts_idempotency_unique
    unique (user_hash, idempotency_key)
);

create table private.account_deletion_tombstones (
  user_hash text primary key check (user_hash ~ '^[0-9a-f]{64}$'),
  receipt_id uuid not null unique
    references private.account_deletion_receipts(receipt_id),
  deleted_at timestamptz not null default now()
);

create or replace function private.touch_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function private.touch_updated_at();

create or replace function private.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_name text;
begin
  requested_name := btrim(coalesce(new.raw_user_meta_data ->> 'display_name', ''));
  if char_length(requested_name) < 1 then
    requested_name := split_part(coalesce(new.email, 'jugador'), '@', 1);
  end if;

  insert into public.profiles (user_id, display_name)
  values (new.id, left(requested_name, 32))
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger auth_user_created_profile
after insert on auth.users
for each row execute function private.create_profile_for_new_user();

create or replace function private.sync_profile_identities()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected_user uuid;
begin
  affected_user := case when tg_op = 'DELETE' then old.user_id else new.user_id end;

  delete from public.profile_identities
  where user_id = affected_user;

  insert into public.profile_identities (
    user_id,
    provider,
    linked_at,
    last_seen_at
  )
  select
    identity.user_id,
    identity.provider,
    min(identity.created_at),
    max(identity.updated_at)
  from auth.identities as identity
  where identity.user_id = affected_user
    and identity.provider in ('email', 'google', 'apple')
  group by identity.user_id, identity.provider;

  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

create trigger auth_identity_metadata_changed
after insert or update or delete on auth.identities
for each row execute function private.sync_profile_identities();

create or replace function public.begin_account_deletion(p_idempotency_key uuid)
returns table (receipt_id uuid, status text, user_hash text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  caller_hash text;
begin
  if caller_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  caller_hash := encode(extensions.digest(caller_id::text, 'sha256'), 'hex');

  return query
  insert into private.account_deletion_receipts as receipt (
    user_hash,
    idempotency_key
  )
  values (caller_hash, p_idempotency_key)
  on conflict on constraint account_deletion_receipts_idempotency_unique
  do update
    set idempotency_key = excluded.idempotency_key
  returning receipt.receipt_id, receipt.status, receipt.user_hash;
end;
$$;

create or replace function public.complete_account_deletion(
  p_receipt_id uuid,
  p_succeeded boolean,
  p_failure_code text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  receipt private.account_deletion_receipts%rowtype;
begin
  select * into receipt
  from private.account_deletion_receipts
  where receipt_id = p_receipt_id
  for update;

  if not found then
    raise exception 'deletion receipt not found' using errcode = 'P0002';
  end if;

  if receipt.status = 'completed' then
    return;
  end if;

  update private.account_deletion_receipts
  set
    status = case when p_succeeded then 'completed' else 'failed' end,
    completed_at = now(),
    failure_code = case
      when p_succeeded then null
      else left(coalesce(p_failure_code, 'unknown'), 48)
    end
  where receipt_id = p_receipt_id;

  if p_succeeded then
    insert into private.account_deletion_tombstones (user_hash, receipt_id)
    values (receipt.user_hash, p_receipt_id)
    on conflict (user_hash) do nothing;
  end if;
end;
$$;

alter table public.profiles enable row level security;
alter table public.profile_identities enable row level security;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.profile_identities from anon, authenticated;
grant select, update on table public.profiles to authenticated;
grant select on table public.profile_identities to authenticated;

create policy profiles_select_own
on public.profiles for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy profiles_update_own
on public.profiles for update
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id)
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy profile_identities_select_own
on public.profile_identities for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

revoke all on function public.begin_account_deletion(uuid) from public, anon;
grant execute on function public.begin_account_deletion(uuid) to authenticated;

revoke all on function public.complete_account_deletion(uuid, boolean, text)
from public, anon, authenticated;
grant execute on function public.complete_account_deletion(uuid, boolean, text)
to service_role;

grant all on table public.profiles, public.profile_identities to service_role;
grant all on table private.account_deletion_receipts,
  private.account_deletion_tombstones to service_role;
