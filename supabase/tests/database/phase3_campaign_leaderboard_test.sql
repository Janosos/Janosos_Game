begin;

select plan(49);

insert into auth.users (id, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'alpha@example.com', '{"display_name":"Alpha"}'),
  ('22222222-2222-2222-2222-222222222222', 'bravo@example.com', '{"display_name":"Bravo"}');

create temporary table test_responses (
  name text primary key,
  response jsonb not null
);
grant all on table test_responses to authenticated, service_role;

select is(
  (select count(*)::integer from public.characters),
  7,
  'the stable character catalog contains seven entries'
);

select results_eq(
  $$select id from public.characters order by sort_order$$,
  $$values ('jano'), ('parker'), ('chema'), ('conra'), ('shyno'), ('nakama'), ('nanic')$$,
  'database character IDs exactly match the Flutter contract'
);

set local role anon;
select throws_ok(
  $$select * from public.characters$$,
  '42501',
  null,
  'anonymous callers cannot read the game catalog'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select is(
  (select count(*)::integer from public.characters),
  7,
  'authenticated callers can read enabled characters'
);

select throws_ok(
  $$insert into public.character_progress (user_id, character_id)
    values ('11111111-1111-1111-1111-111111111111', 'jano')$$,
  '42501',
  null,
  'clients cannot grant their own progress'
);

insert into test_responses
values (
  'campaign_one',
  public.start_campaign(
    'jano',
    'progression',
    'v6-preview-1',
    1,
    repeat('a', 64),
    3::smallint,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    repeat('1', 64)
  )
);

select is(
  (select response ->> 'status' from test_responses where name = 'campaign_one'),
  'accepted',
  'start-campaign accepts a valid request'
);

select is(
  (select count(*)::integer from public.character_progress),
  1,
  'start-campaign creates the authoritative progress root'
);

select is(
  (select count(*)::integer from public.campaign_runs where state = 'active'),
  1,
  'the player receives one active campaign lease'
);

select is(
  (select lives_remaining from public.campaign_runs where state = 'active'),
  1::smallint,
  'the server derives base lives instead of trusting the requested value'
);

select is(
  public.start_campaign(
    'jano',
    'progression',
    'v6-preview-1',
    1,
    repeat('a', 64),
    3::smallint,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    repeat('1', 64)
  ),
  (select response from test_responses where name = 'campaign_one'),
  'an exact start-campaign retry returns its canonical response'
);

select throws_ok(
  $$select public.start_campaign(
      'jano', 'progression', 'v6-preview-1', 1, repeat('a', 64), 3::smallint,
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', repeat('2', 64)
    )$$,
  '22023',
  null,
  'an idempotency key cannot be reused with another request digest'
);

insert into test_responses
values (
  'campaign_two',
  public.start_campaign(
    'jano',
    'progression',
    'v6-preview-1',
    1,
    repeat('a', 64),
    3::smallint,
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    repeat('3', 64)
  )
);

select is(
  (select response ->> 'status' from test_responses where name = 'campaign_two'),
  'accepted',
  'starting a replacement campaign succeeds explicitly'
);

select is(
  (select count(*)::integer from public.campaign_runs where state = 'active'),
  1,
  'replacement preserves the one-active-campaign invariant'
);

select is(
  (select count(*)::integer from public.campaign_runs where state = 'abandoned'),
  1,
  'the previous lease is marked abandoned'
);

insert into test_responses
values (
  'stage_two',
  public.start_stage(
    ((select response ->> 'campaign_id' from test_responses where name = 'campaign_two'))::uuid,
    repeat('b', 64),
    repeat('c', 64),
    ((select response ->> 'lease_expires_at' from test_responses where name = 'campaign_two'))::timestamptz - interval '5 hours 59 minutes 59 seconds',
    ((select response ->> 'lease_expires_at' from test_responses where name = 'campaign_two'))::timestamptz,
    1::smallint,
    1::smallint,
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    repeat('4', 64)
  )
);

select is(
  (select response ->> 'status' from test_responses where name = 'stage_two'),
  'accepted',
  'start-stage issues metadata for the expected sequence'
);

select throws_ok(
  $$select * from private.campaign_stages$$,
  '42501',
  null,
  'clients cannot read private token digests'
);

select is(
  public.start_stage(
    ((select response ->> 'campaign_id' from test_responses where name = 'campaign_two'))::uuid,
    repeat('b', 64),
    repeat('c', 64),
    ((select response ->> 'lease_expires_at' from test_responses where name = 'campaign_two'))::timestamptz - interval '5 hours 59 minutes 59 seconds',
    ((select response ->> 'lease_expires_at' from test_responses where name = 'campaign_two'))::timestamptz,
    1::smallint,
    1::smallint,
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    repeat('4', 64)
  ),
  (select response from test_responses where name = 'stage_two'),
  'an exact start-stage retry returns its canonical response'
);

select throws_ok(
  $$insert into public.run_results (
      campaign_id, user_id, character_id, mode, outcome, completed,
      level_reached, total_score, duration_ms, validation,
      content_version, protocol_version, ended_at
    ) values (
      gen_random_uuid(), '11111111-1111-1111-1111-111111111111',
      'jano', 'progression', 'defeat', false, 1, 1, 1000,
      'verified', 'v6-preview-1', 1, now()
    )$$,
  '42501',
  null,
  'clients cannot insert personal results directly'
);

select throws_ok(
  $$insert into public.leaderboard_entries (
      result_id, user_id, display_name, character_id, mode,
      content_version, completed, level_reached, total_score,
      duration_ms, ended_at
    ) values (
      gen_random_uuid(), '11111111-1111-1111-1111-111111111111',
      'Cheater', 'jano', 'progression', 'v6-preview-1', false, 1, 999999,
      1, now()
    )$$,
  '42501',
  null,
  'clients cannot publish leaderboard entries directly'
);

select throws_ok(
  $$select public.apply_finish_stage(
      '11111111-1111-1111-1111-111111111111',
      ((select response ->> 'campaign_id' from test_responses where name = 'campaign_two'))::uuid,
      repeat('b', 64), 'defeat', 1000, 5000, 'lives_depleted', 50, 100,
      'dddddddd-dddd-4ddd-8ddd-dddddddddddd', repeat('5', 64)
    )$$,
  '42501',
  null,
  'authenticated clients cannot call the privileged finish transaction'
);

reset role;
set local role service_role;

insert into test_responses
values (
  'finish_two',
  public.apply_finish_stage(
    '11111111-1111-1111-1111-111111111111',
    ((select response ->> 'campaign_id' from test_responses where name = 'campaign_two'))::uuid,
    repeat('b', 64),
    'defeat',
    1000,
    5000,
    'lives_depleted',
    50,
    100,
    'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    repeat('5', 64)
  )
);

select is(
  (select response ->> 'status' from test_responses where name = 'finish_two'),
  'accepted',
  'the privileged finish transaction accepts a plausible terminal result'
);

select is(
  (select (response ->> 'ranked')::boolean from test_responses where name = 'finish_two'),
  true,
  'an accepted gameplay defeat is globally ranked'
);

select is(
  (select count(*)::integer from public.run_results
    where user_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'finish-stage records exactly one personal result'
);

select is(
  (select count(*)::integer from public.leaderboard_entries
    where user_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'finish-stage publishes exactly one verified best row'
);

select is(
  (select mastery_xp from public.character_progress
    where user_id = '11111111-1111-1111-1111-111111111111'
      and character_id = 'jano'),
  100::bigint,
  'accepted defeat grants the bounded mastery amount once'
);

select is(
  (select state::text from public.campaign_runs
    where id = ((select response ->> 'campaign_id' from test_responses where name = 'campaign_two'))::uuid),
  'failed',
  'gameplay defeat seals the campaign as failed'
);

select is(
  public.apply_finish_stage(
    '11111111-1111-1111-1111-111111111111',
    ((select response ->> 'campaign_id' from test_responses where name = 'campaign_two'))::uuid,
    repeat('b', 64), 'defeat', 1000, 5000, 'lives_depleted', 50, 100,
    'dddddddd-dddd-4ddd-8ddd-dddddddddddd', repeat('5', 64)
  ),
  (select response from test_responses where name = 'finish_two'),
  'a duplicate finish returns the exact canonical response'
);

select is(
  (select count(*)::integer from private.command_receipts
    where user_id = '11111111-1111-1111-1111-111111111111'
      and command_type = 'finish-stage'),
  1,
  'duplicate finishes create one durable command receipt'
);

select throws_ok(
  $$select public.apply_finish_stage(
      '11111111-1111-1111-1111-111111111111',
      ((select response ->> 'campaign_id' from test_responses where name = 'campaign_two'))::uuid,
      repeat('b', 64), 'defeat', 1001, 5000, 'lives_depleted', 50, 100,
      'dddddddd-dddd-4ddd-8ddd-dddddddddddd', repeat('6', 64)
    )$$,
  '22023',
  null,
  'a changed finish payload cannot reuse the receipt key'
);

reset role;

insert into public.character_progress (user_id, character_id)
values ('22222222-2222-2222-2222-222222222222', 'jano');

insert into public.campaign_runs (
  id, user_id, character_id, mode, state, current_level,
  expected_sequence, content_version, protocol_version, loadout_digest,
  lease_expires_at, provisional_currency, total_score, total_duration_ms,
  lives_remaining
) values (
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
  '22222222-2222-2222-2222-222222222222',
  'jano', 'progression', 'active', 10, 11, 'v6-preview-1', 1,
  repeat('e', 64), now() + interval '1 hour', 500, 900, 4500, 1
);

set local role service_role;
insert into test_responses
values (
  'complete_bravo',
  public.apply_complete_campaign(
    '22222222-2222-2222-2222-222222222222',
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    repeat('7', 64)
  )
);

select is(
  (select response ->> 'status' from test_responses where name = 'complete_bravo'),
  'accepted',
  'complete-campaign accepts a campaign with ten verified stages'
);

select is(
  (select banked_currency from public.character_progress
    where user_id = '22222222-2222-2222-2222-222222222222'
      and character_id = 'jano'),
  500::bigint,
  'completion atomically banks temporary currency'
);

select is(
  (select purchase_phase_unlocked from public.character_progress
    where user_id = '22222222-2222-2222-2222-222222222222'
      and character_id = 'jano'),
  true,
  'completion permanently unlocks the character purchase phase'
);

select is(
  public.apply_complete_campaign(
    '22222222-2222-2222-2222-222222222222',
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    repeat('7', 64)
  ),
  (select response from test_responses where name = 'complete_bravo'),
  'a duplicate completion returns the same receipt response'
);

reset role;

select lives_ok($test$
with inserted_campaigns as (
  insert into public.campaign_runs (
    user_id, character_id, mode, state, current_level, expected_sequence,
    content_version, protocol_version, loadout_digest, lease_expires_at,
    total_score, total_duration_ms, provisional_currency, lives_remaining,
    ended_at
  )
  select
    '22222222-2222-2222-2222-222222222222'::uuid,
    character.id,
    'progression'::public.game_mode,
    'failed'::public.campaign_state,
    2,
    2,
    'v6-preview-1',
    1,
    repeat('f', 64),
    now(),
    200 + character.sort_order,
    6000,
    0,
    0,
    now() + make_interval(secs => character.sort_order)
  from public.characters as character
  where character.id <> 'jano'
  returning id, user_id, character_id, mode, content_version,
    protocol_version, total_score, total_duration_ms, ended_at
), inserted_results as (
  insert into public.run_results (
    campaign_id, user_id, character_id, mode, outcome, completed,
    level_reached, total_score, duration_ms, defeat_reason, validation,
    content_version, protocol_version, ended_at
  )
  select
    id, user_id, character_id, mode, 'defeat', false, 2,
    total_score, total_duration_ms, 'lives_depleted', 'verified',
    content_version, protocol_version, ended_at
  from inserted_campaigns
  returning id
)
select count(*) from inserted_results;
$test$, 'representative verified results can be created for six more characters');

do $$
declare
  candidate record;
begin
  for candidate in
    select id from public.run_results
    where user_id = '22222222-2222-2222-2222-222222222222'
  loop
    perform private.publish_best_result(candidate.id);
  end loop;
end;
$$;

select is(
  (select count(distinct character_id)::integer
    from public.leaderboard_entries),
  7,
  'verified leaderboard data covers all seven character filters'
);

select is(
  (select user_id from public.leaderboard_entries
    where character_id = 'jano'
      and mode = 'progression'
      and content_version = 'v6-preview-1'
    order by completed desc, level_reached desc, total_score desc,
      duration_ms asc, ended_at asc, id asc
    limit 1),
  '22222222-2222-2222-2222-222222222222'::uuid,
  'a completed run ranks ahead of a failed run regardless of raw score'
);

select has_index(
  'public',
  'leaderboard_entries',
  'leaderboard_entries_verified_keyset',
  'the canonical verified keyset index exists'
);

select has_index(
  'public',
  'run_results',
  'run_results_personal_history',
  'the personal-history keyset index exists'
);

select is(
  (select count(*)::integer from private.premium_wallets),
  0,
  'future premium wallets contain no seeded balances'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select throws_ok(
  $$select * from public.run_results$$,
  '42501',
  null,
  'personal history cannot bypass the bounded RPC'
);
select is(
  (select count(*)::integer from public.get_personal_history(
    'jano', 'progression', 'v6-preview-1', 100
  )),
  1,
  'bounded personal history exposes only Alpha results'
);

select is(
  (select count(*)::integer from public.character_progress),
  1,
  'character progress RLS exposes only Alpha progress'
);

select throws_ok(
  $$select * from public.leaderboard_entries$$,
  '42501',
  null,
  'clients cannot read internal leaderboard identifiers directly'
);

select throws_ok(
  $$select * from private.premium_wallets$$,
  '42501',
  null,
  'premium-wallet data has no client read access'
);

select is(
  (select sum(page.entry_count)::integer
   from public.characters as character
   cross join lateral (
     select count(*) as entry_count
     from public.get_leaderboard_page(
       character.id, 'progression', 'v6-preview-1', 25
     )
   ) as page),
  8,
  'the sanitized global RPC exposes verified rows across all characters'
);

select is(
  (select count(*)::integer
    from public.get_leaderboard_page(
      'jano', 'progression', 'v6-preview-1', 25
    )),
  2,
  'the leaderboard RPC returns the filtered top page'
);

select is(
  (select count(*)::integer
   from public.get_leaderboard_page(
     'jano', 'progression', 'v6-preview-1', 25
   )
   where validation <> 'verified'),
  0,
  'no pending, limited, or rejected result appears in the global RPC'
);

select is(
  (select "position" from public.get_leaderboard_page(
    'jano', 'progression', 'v6-preview-1', 1
  )),
  1::bigint,
  'the first keyset page preserves absolute rank'
);

select is(
  (select next_page."position"
   from public.get_leaderboard_page(
     'jano', 'progression', 'v6-preview-1', 1
   ) as first_entry
   cross join lateral public.get_leaderboard_page(
     'jano',
     'progression',
     'v6-preview-1',
     1,
     first_entry.completed,
     first_entry.level_reached,
     first_entry.total_score,
     first_entry.duration_ms,
     first_entry.ended_at,
     first_entry.id
   ) as next_page),
  2::bigint,
  'the keyset cursor returns the next absolute rank without overlap'
);

select * from finish();
rollback;
