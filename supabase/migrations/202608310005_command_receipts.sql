-- Janosos V6 phase 3: durable canonical responses for idempotent commands.

create table private.command_receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  command_type text not null check (command_type ~ '^[a-z][a-z0-9_-]{1,47}$'),
  idempotency_key uuid not null,
  request_digest text not null check (request_digest ~ '^[0-9a-f]{64}$'),
  status public.command_status not null default 'processing',
  response jsonb,
  rejection_code text check (
    rejection_code is null or rejection_code ~ '^[a-z0-9_]{1,48}$'
  ),
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (user_id, command_type, idempotency_key),
  constraint command_receipt_terminal_response check (
    (status = 'processing' and response is null and completed_at is null)
    or (status <> 'processing' and response is not null and completed_at is not null)
  )
);

create index command_receipts_retention
on private.command_receipts (completed_at, id)
where status <> 'processing';

comment on table private.command_receipts is
  'Exact retries return response; reuse of a key with a changed digest is rejected.';

