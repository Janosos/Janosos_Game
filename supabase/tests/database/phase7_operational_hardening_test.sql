begin;

select plan(24);

select is(
  (select count(*)::integer from private.supported_client_versions
   where content_version = 'v6-preview-1' and protocol_version = 1
     and supported_from <= now() and supported_until > now()
     and rank_eligible),
  1,
  'the current client remains supported and rank eligible'
);
select is(
  (select count(*)::integer from private.supported_client_versions
   where content_version = 'v5-legacy' and protocol_version = 1
     and supported_from <= now() and supported_until > now()
     and not rank_eligible
     and supported_until <= supported_from + interval '90 days 1 minute'),
  1,
  'the previous client has a bounded compatibility window without ranking'
);

select function_privs_are(
  'public', 'get_personal_history',
  array['text', 'game_mode', 'text', 'integer'],
  'authenticated', array['EXECUTE'],
  'authenticated players receive history only through the bounded RPC'
);
select function_privs_are(
  'private', 'run_retention_maintenance', array['timestamp with time zone'],
  'service_role', array['EXECUTE'],
  'only the service role can invoke retention maintenance'
);
select is(
  (select count(*)::integer from cron.job
   where jobname = 'janosos-retention-daily'
     and schedule = '17 4 * * *'),
  1,
  'daily retention maintenance is scheduled once'
);

insert into auth.users (id, email, raw_user_meta_data)
values
  ('77777777-7777-4777-8777-777777777771', 'phase7@example.com',
   '{"display_name":"Phase Seven"}'),
  ('77777777-7777-4777-8777-777777777772', 'restored@example.com',
   '{"display_name":"Restored User"}');

insert into private.account_deletion_receipts (
  receipt_id, user_hash, idempotency_key, status, requested_at
) values (
  '77000000-0000-4000-8000-000000000001',
  encode(extensions.digest(
    '77777777-7777-4777-8777-777777777772', 'sha256'
  ), 'hex'),
  '77000000-0000-4000-8000-000000000002',
  'completed', now() - interval '2 days'
);
update private.account_deletion_receipts
set completed_at = now() - interval '2 days'
where receipt_id = '77000000-0000-4000-8000-000000000001';
insert into private.account_deletion_tombstones (user_hash, receipt_id)
select user_hash, receipt_id from private.account_deletion_receipts
where receipt_id = '77000000-0000-4000-8000-000000000001';

insert into private.account_deletion_receipts (
  user_hash, idempotency_key, status, requested_at
) values (
  repeat('7', 64), '77000000-0000-4000-8000-000000000003',
  'processing', now() - interval '25 hours'
);

insert into private.operational_events (
  correlation_id, category, code, measurement, occurred_at
) values
  ('77000000-0000-4000-8000-000000000004', 'function', 'old_sample', 1,
   now() - interval '15 days'),
  ('77000000-0000-4000-8000-000000000005', 'function', 'fresh_sample', 1,
   now());

insert into private.command_receipts (
  user_id, command_type, idempotency_key, request_digest, status,
  response, created_at, completed_at
) values (
  '77777777-7777-4777-8777-777777777771', 'old-command',
  '77000000-0000-4000-8000-000000000006', repeat('7', 64), 'accepted',
  '{"status":"accepted"}', now() - interval '31 days',
  now() - interval '31 days'
);

create temporary table phase7_result (response jsonb not null);
insert into phase7_result
select private.run_retention_maintenance(now());

select is(
  (select (response ->> 'reapplied_tombstones')::integer from phase7_result),
  1,
  'maintenance reapplies deletion tombstones before reopening service'
);
select is(
  (select count(*)::integer from auth.users
   where id = '77777777-7777-4777-8777-777777777772'),
  0,
  'a restored deleted account is removed again'
);
select is(
  (select (response ->> 'overdue_deletions')::integer from phase7_result),
  1,
  'the 24-hour deletion SLA audit detects overdue work'
);
select is(
  (select count(*)::integer from private.operational_events
   where code = 'account_deletion_sla_breach' and measurement = 1),
  1,
  'an overdue deletion emits one aggregate technical alert'
);
select is(
  (select count(*)::integer from private.operational_events
   where code = 'old_sample'),
  0,
  'sanitized operational events expire after 14 days'
);
select is(
  (select count(*)::integer from private.operational_events
   where code = 'fresh_sample'),
  1,
  'fresh sanitized operational events are retained'
);
select is(
  (select count(*)::integer from private.command_receipts
   where command_type = 'old-command'),
  0,
  'terminal command receipts expire after 30 days'
);
select is(
  (select status from private.retention_runs order by completed_at desc limit 1),
  'attention_required',
  'the retention audit records when operator attention is required'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"77777777-7777-4777-8777-777777777771","role":"authenticated"}',
  true
);
select throws_ok(
  $$select * from public.run_results$$,
  '42501', null,
  'clients cannot bypass the bounded personal-history RPC'
);
select is(
  (select count(*)::integer from public.get_personal_history(
    'jano', 'standard', 'v6-preview-1', 500
  )),
  0,
  'the bounded personal-history RPC accepts at most 100 requested rows'
);
select is(
  public.start_campaign(
    'jano', 'standard'::public.game_mode, 'v5-legacy', 1,
    repeat('7', 64), 1::smallint,
    '77000000-0000-4000-8000-000000000007', repeat('8', 64)
  ) ->> 'status',
  'accepted',
  'the previous client can finish its bounded compatibility window'
);
select is(
  public.start_campaign(
    'jano', 'standard'::public.game_mode, 'v4-expired', 1,
    repeat('7', 64), 1::smallint,
    '77000000-0000-4000-8000-000000000008', repeat('9', 64)
  ) ->> 'code',
  'unsupported_client_version',
  'clients older than the previous compatibility window are rejected'
);
select throws_ok(
  $$select private.run_retention_maintenance(now())$$,
  '42501', null,
  'players cannot run retention maintenance'
);
select throws_ok(
  $$select private.record_operational_event(
    'function', 'client_forged', 1, null, gen_random_uuid()
  )$$,
  '42501', null,
  'players cannot forge operational signals'
);

reset role;
update public.campaign_runs
set state = 'failed', ended_at = now()
where user_id = '77777777-7777-4777-8777-777777777771'
  and content_version = 'v5-legacy';
with inserted as (
  insert into public.run_results (
    campaign_id, user_id, character_id, mode, outcome, completed,
    level_reached, total_score, duration_ms, validation,
    content_version, protocol_version, ended_at
  )
  select
    id, user_id, character_id, mode, 'defeat', false, 1, 100, 1000,
    'verified', content_version, protocol_version, ended_at
  from public.campaign_runs
  where user_id = '77777777-7777-4777-8777-777777777771'
    and content_version = 'v5-legacy'
  returning id
)
select private.publish_best_result(id) from inserted;
select is(
  (select count(*)::integer from public.leaderboard_entries
   where user_id = '77777777-7777-4777-8777-777777777771'
     and content_version = 'v5-legacy'),
  0,
  'the compatible previous client cannot publish a ranked result'
);
select is(
  (select count(*)::integer from public.run_results
   where user_id = '77777777-7777-4777-8777-777777777771'
     and content_version = 'v5-legacy'),
  1,
  'the previous client result remains available as personal history'
);
select throws_ok(
  $$select private.record_operational_event(
    'Bad Category', 'invalid', 1, null, gen_random_uuid()
  )$$,
  '22023', null,
  'operational event identifiers are strictly sanitized'
);
select is(
  (select count(*)::integer from information_schema.columns
   where table_schema = 'private' and table_name = 'operational_events'
     and column_name in (
       'user_id', 'email', 'display_name', 'token', 'request', 'response',
       'payload', 'score'
     )),
  0,
  'the technical event schema has no player or gameplay payload columns'
);
select is(
  (select count(*)::integer from private.account_deletion_tombstones
   where user_hash = encode(extensions.digest(
     '77777777-7777-4777-8777-777777777772', 'sha256'
   ), 'hex')),
  1,
  'deletion tombstones remain durable after replay'
);

select * from finish();
rollback;
