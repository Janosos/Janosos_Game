-- Janosos V6 phase 7: compatibility, bounded history, and private operations.

create extension if not exists pg_cron with schema extensions;

create table private.operational_events (
  id bigint generated always as identity primary key,
  correlation_id uuid not null default gen_random_uuid(),
  category text not null check (category ~ '^[a-z][a-z0-9_]{1,31}$'),
  code text not null check (code ~ '^[a-z][a-z0-9_]{1,47}$'),
  measurement bigint not null default 1 check (measurement >= 0),
  duration_ms integer check (duration_ms is null or duration_ms >= 0),
  occurred_at timestamptz not null default now()
);

comment on table private.operational_events is
  'Sanitized technical signals only: no account IDs, names, email, tokens, request bodies, or gameplay payloads.';

create index operational_events_retention
on private.operational_events (occurred_at, id);

create table private.retention_runs (
  id uuid primary key default gen_random_uuid(),
  started_at timestamptz not null,
  completed_at timestamptz not null,
  expired_campaigns integer not null check (expired_campaigns >= 0),
  deleted_short_lived_campaigns integer not null
    check (deleted_short_lived_campaigns >= 0),
  deleted_verified_campaigns integer not null
    check (deleted_verified_campaigns >= 0),
  deleted_command_receipts integer not null
    check (deleted_command_receipts >= 0),
  deleted_operational_events integer not null
    check (deleted_operational_events >= 0),
  overdue_deletions integer not null check (overdue_deletions >= 0),
  reapplied_tombstones integer not null check (reapplied_tombstones >= 0),
  status text not null check (status in ('completed', 'attention_required'))
);

comment on table private.retention_runs is
  'Aggregate maintenance evidence without player identifiers or gameplay data.';

create index retention_runs_retention
on private.retention_runs (completed_at, id);

create or replace function private.record_operational_event(
  p_category text,
  p_code text,
  p_measurement bigint default 1,
  p_duration_ms integer default null,
  p_correlation_id uuid default gen_random_uuid()
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_category !~ '^[a-z][a-z0-9_]{1,31}$'
    or p_code !~ '^[a-z][a-z0-9_]{1,47}$'
    or p_measurement < 0
    or coalesce(p_duration_ms, 0) < 0 then
    raise exception 'invalid sanitized operational event' using errcode = '22023';
  end if;

  insert into private.operational_events (
    correlation_id, category, code, measurement, duration_ms
  ) values (
    p_correlation_id, p_category, p_code, p_measurement, p_duration_ms
  );
  return p_correlation_id;
end;
$$;

create or replace function private.reapply_deletion_tombstones()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  deleted_count integer;
begin
  delete from auth.users as restored_user
  using private.account_deletion_tombstones as tombstone
  where encode(
    extensions.digest(restored_user.id::text, 'sha256'), 'hex'
  ) = tombstone.user_hash;
  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

create or replace function private.audit_account_deletion_sla(
  p_now timestamptz default now()
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  overdue_count integer;
begin
  select count(*)::integer into overdue_count
  from private.account_deletion_receipts
  where status = 'processing'
    and requested_at <= p_now - interval '24 hours';

  if overdue_count > 0 then
    perform private.record_operational_event(
      'alert', 'account_deletion_sla_breach', overdue_count
    );
  end if;
  return overdue_count;
end;
$$;

create or replace function private.run_retention_maintenance(
  p_now timestamptz default now()
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  run_id uuid := gen_random_uuid();
  started timestamptz := clock_timestamp();
  expired_count integer := 0;
  short_campaign_count integer := 0;
  verified_campaign_count integer := 0;
  receipt_count integer := 0;
  event_count integer := 0;
  overdue_count integer := 0;
  tombstone_count integer := 0;
  response jsonb;
begin
  update private.campaign_stages as stage
  set
    status = 'rejected',
    consumed_at = p_now,
    outcome = 'defeat',
    score = 0,
    duration_ms = 0,
    verification = 'rejected',
    rejection_code = 'campaign_expired'
  from public.campaign_runs as campaign
  where stage.campaign_id = campaign.id
    and campaign.state = 'active'
    and campaign.lease_expires_at <= p_now
    and stage.status in ('token_issued', 'playing', 'finished_pending');

  update public.campaign_runs
  set state = 'expired', provisional_currency = 0, ended_at = p_now
  where state = 'active' and lease_expires_at <= p_now;
  get diagnostics expired_count = row_count;

  delete from private.command_receipts
  where status <> 'processing'
    and completed_at < p_now - interval '30 days';
  get diagnostics receipt_count = row_count;

  delete from public.campaign_runs as campaign
  where campaign.state <> 'active'
    and campaign.ended_at < p_now - interval '30 days'
    and not exists (
      select 1 from public.run_results as result
      where result.campaign_id = campaign.id
        and result.validation in ('verified', 'limited')
    );
  get diagnostics short_campaign_count = row_count;

  delete from public.campaign_runs
  where state <> 'active'
    and ended_at < p_now - interval '180 days';
  get diagnostics verified_campaign_count = row_count;

  delete from private.operational_events
  where occurred_at < p_now - interval '14 days';
  get diagnostics event_count = row_count;

  delete from private.retention_runs
  where completed_at < p_now - interval '180 days';

  tombstone_count := private.reapply_deletion_tombstones();
  overdue_count := private.audit_account_deletion_sla(p_now);

  insert into private.retention_runs (
    id, started_at, completed_at, expired_campaigns,
    deleted_short_lived_campaigns, deleted_verified_campaigns,
    deleted_command_receipts, deleted_operational_events,
    overdue_deletions, reapplied_tombstones, status
  ) values (
    run_id, started, clock_timestamp(), expired_count,
    short_campaign_count, verified_campaign_count,
    receipt_count, event_count, overdue_count, tombstone_count,
    case when overdue_count > 0 then 'attention_required' else 'completed' end
  );

  perform private.record_operational_event(
    'maintenance', 'retention_completed',
    expired_count + short_campaign_count + verified_campaign_count
      + receipt_count + event_count + tombstone_count,
    greatest(
      0,
      (extract(epoch from clock_timestamp() - started) * 1000)::integer
    ),
    run_id
  );

  response := jsonb_build_object(
    'run_id', run_id,
    'status', case when overdue_count > 0
      then 'attention_required' else 'completed' end,
    'expired_campaigns', expired_count,
    'deleted_short_lived_campaigns', short_campaign_count,
    'deleted_verified_campaigns', verified_campaign_count,
    'deleted_command_receipts', receipt_count,
    'deleted_operational_events', event_count,
    'overdue_deletions', overdue_count,
    'reapplied_tombstones', tombstone_count
  );
  return response;
end;
$$;

create or replace function public.get_personal_history(
  p_character_id text,
  p_mode public.game_mode,
  p_content_version text,
  p_limit integer default 100
)
returns table (
  id uuid,
  character_id text,
  mode public.game_mode,
  outcome public.run_outcome,
  validation public.validation_status,
  completed boolean,
  level_reached smallint,
  total_score bigint,
  duration_ms bigint,
  ended_at timestamptz,
  content_version text,
  rejection_code text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    result.id, result.character_id, result.mode, result.outcome,
    result.validation, result.completed, result.level_reached,
    result.total_score, result.duration_ms, result.ended_at,
    result.content_version, result.rejection_code
  from public.run_results as result
  where result.user_id = auth.uid()
    and result.character_id = p_character_id
    and result.mode = p_mode
    and result.content_version = btrim(p_content_version)
  order by result.accepted_at desc, result.id desc
  limit least(greatest(p_limit, 1), 100)
$$;

-- Legacy clients may finish a valid in-flight attempt during the 90-day
-- compatibility window, but only explicitly eligible content can be ranked.
create or replace function private.publish_best_result(p_result_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  result_row public.run_results%rowtype;
  player_name text;
begin
  select * into result_row
  from public.run_results
  where id = p_result_id;

  if not found or result_row.validation <> 'verified'
    or not exists (
      select 1 from private.supported_client_versions as version
      where version.content_version = result_row.content_version
        and version.protocol_version = result_row.protocol_version
        and version.supported_from <= now()
        and version.supported_until > now()
        and version.rank_eligible
    ) then
    return;
  end if;

  select display_name into player_name
  from public.profiles
  where user_id = result_row.user_id;

  insert into public.leaderboard_entries as board (
    result_id, user_id, display_name, character_id, mode, content_version,
    completed, level_reached, total_score, duration_ms, ended_at, validation
  ) values (
    result_row.id, result_row.user_id, coalesce(player_name, 'Jugador'),
    result_row.character_id, result_row.mode, result_row.content_version,
    result_row.completed, result_row.level_reached, result_row.total_score,
    result_row.duration_ms, result_row.ended_at, 'verified'
  )
  on conflict (user_id, character_id, mode, content_version)
  do update set
    result_id = excluded.result_id,
    display_name = excluded.display_name,
    completed = excluded.completed,
    level_reached = excluded.level_reached,
    total_score = excluded.total_score,
    duration_ms = excluded.duration_ms,
    ended_at = excluded.ended_at,
    validation = excluded.validation
  where
    excluded.completed > board.completed
    or (excluded.completed = board.completed
      and excluded.level_reached > board.level_reached)
    or (excluded.completed = board.completed
      and excluded.level_reached = board.level_reached
      and excluded.total_score > board.total_score)
    or (excluded.completed = board.completed
      and excluded.level_reached = board.level_reached
      and excluded.total_score = board.total_score
      and excluded.duration_ms < board.duration_ms)
    or (excluded.completed = board.completed
      and excluded.level_reached = board.level_reached
      and excluded.total_score = board.total_score
      and excluded.duration_ms = board.duration_ms
      and excluded.ended_at < board.ended_at);
end;
$$;

create or replace function private.finish_command_receipt(
  p_receipt_id uuid,
  p_status public.command_status,
  p_response jsonb,
  p_rejection_code text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  canonical_response jsonb := p_response;
begin
  if canonical_response ? 'ranked'
    and canonical_response ? 'campaign_id'
    and not exists (
      select 1
      from public.campaign_runs as campaign
      join private.supported_client_versions as version
        on version.content_version = campaign.content_version
        and version.protocol_version = campaign.protocol_version
      where campaign.id::text = canonical_response ->> 'campaign_id'
        and version.supported_from <= now()
        and version.supported_until > now()
        and version.rank_eligible
    ) then
    canonical_response := jsonb_set(
      canonical_response, '{ranked}', 'false'::jsonb
    );
  end if;

  update private.command_receipts
  set
    status = p_status,
    response = canonical_response,
    rejection_code = p_rejection_code,
    completed_at = now()
  where id = p_receipt_id;

  if not found then
    raise exception 'command receipt not found' using errcode = 'P0002';
  end if;
  return canonical_response;
end;
$$;

update private.command_receipts as receipt
set response = jsonb_set(receipt.response, '{ranked}', 'false'::jsonb)
from public.campaign_runs as campaign
join private.supported_client_versions as version
  on version.content_version = campaign.content_version
  and version.protocol_version = campaign.protocol_version
where receipt.response ? 'ranked'
  and receipt.response ->> 'campaign_id' = campaign.id::text
  and not version.rank_eligible;

revoke select on table public.run_results from authenticated;
revoke all on function public.get_personal_history(
  text, public.game_mode, text, integer
) from public, anon;
grant execute on function public.get_personal_history(
  text, public.game_mode, text, integer
) to authenticated;

revoke all on table private.operational_events,
  private.retention_runs from public, anon, authenticated;
grant all on table private.operational_events,
  private.retention_runs to service_role;
grant usage, select on sequence private.operational_events_id_seq to service_role;

revoke all on function private.record_operational_event(
  text, text, bigint, integer, uuid
) from public, anon, authenticated;
revoke all on function private.reapply_deletion_tombstones()
from public, anon, authenticated;
revoke all on function private.audit_account_deletion_sla(timestamptz)
from public, anon, authenticated;
revoke all on function private.run_retention_maintenance(timestamptz)
from public, anon, authenticated;
grant execute on function private.record_operational_event(
  text, text, bigint, integer, uuid
) to service_role;
grant execute on function private.reapply_deletion_tombstones() to service_role;
grant execute on function private.audit_account_deletion_sla(timestamptz)
to service_role;
grant execute on function private.run_retention_maintenance(timestamptz)
to service_role;

do $$
declare
  existing_job bigint;
begin
  select jobid into existing_job
  from cron.job
  where jobname = 'janosos-retention-daily';
  if existing_job is not null then
    perform cron.unschedule(existing_job);
  end if;
  perform cron.schedule(
    'janosos-retention-daily',
    '17 4 * * *',
    'select private.run_retention_maintenance();'
  );
end;
$$;
