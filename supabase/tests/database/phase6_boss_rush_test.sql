begin;

select plan(23);

insert into auth.users (id, email, raw_user_meta_data)
values (
  '66666666-6666-4666-8666-666666666666',
  'phase6@example.com',
  '{"display_name":"Phase Six"}'
);

create temporary table phase6_responses (
  name text primary key,
  response jsonb not null
);
grant all on table phase6_responses to authenticated, service_role;

select function_privs_are(
  'public', 'start_boss_rush',
  array['text', 'text', 'integer', 'text', 'uuid', 'text'],
  'authenticated', array['EXECUTE'],
  'authenticated players can request a Boss Rush lease'
);
select function_privs_are(
  'public', 'apply_finish_boss_rush',
  array[
    'uuid', 'uuid', 'text', 'run_outcome', 'smallint', 'bigint', 'bigint',
    'jsonb', 'uuid', 'text'
  ],
  'service_role', array['EXECUTE'],
  'only the service role can commit a Boss Rush result'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"66666666-6666-4666-8666-666666666666","role":"authenticated"}',
  true
);

insert into phase6_responses values (
  'locked',
  public.start_boss_rush(
    'jano', 'v6-preview-1', 1, repeat('a', 64),
    '61000000-0000-4000-8000-000000000001', repeat('1', 64)
  )
);
select is(
  (select response ->> 'code' from phase6_responses where name = 'locked'),
  'boss_rush_locked',
  'Boss Rush is locked before a full campaign clear'
);

reset role;
set local role service_role;
insert into public.character_progress (
  user_id, character_id, purchase_phase_unlocked
) values (
  '66666666-6666-4666-8666-666666666666', 'jano', true
)
on conflict (user_id, character_id) do update
set purchase_phase_unlocked = excluded.purchase_phase_unlocked;
update public.character_progress
set purchase_phase_unlocked = true
where user_id = '66666666-6666-4666-8666-666666666666'
  and character_id = 'jano';

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"66666666-6666-4666-8666-666666666666","role":"authenticated"}',
  true
);
insert into phase6_responses values (
  'start',
  public.start_boss_rush(
    'jano', 'v6-preview-1', 1, repeat('a', 64),
    '61000000-0000-4000-8000-000000000002', repeat('2', 64)
  )
);
select is(
  (select response ->> 'status' from phase6_responses where name = 'start'),
  'accepted',
  'an entitled character starts Boss Rush'
);
select is(
  (select mode from public.campaign_runs where state = 'active'),
  'boss_rush'::public.game_mode,
  'the attempt is isolated under the Boss Rush mode'
);

insert into phase6_responses values (
  'stage',
  public.start_stage(
    ((select response ->> 'campaign_id' from phase6_responses where name = 'start'))::uuid,
    repeat('b', 64), repeat('c', 64),
    ((select response ->> 'lease_expires_at' from phase6_responses where name = 'start'))::timestamptz - interval '5 hours 59 minutes 59 seconds',
    ((select response ->> 'lease_expires_at' from phase6_responses where name = 'start'))::timestamptz,
    1::smallint, 1::smallint,
    '61000000-0000-4000-8000-000000000003', repeat('3', 64)
  )
);
select is(
  (select response ->> 'status' from phase6_responses where name = 'stage'),
  'accepted',
  'the server issues one token for the complete boss chain'
);

select throws_ok(
  $$select public.apply_finish_boss_rush(
    '66666666-6666-4666-8666-666666666666',
    ((select response ->> 'campaign_id' from phase6_responses where name = 'start'))::uuid,
    repeat('b', 64), 'defeat', 2::smallint, 5000, 300000,
    '[{"level":1,"reward_id":"headless_horseman.spectral_trail","roll_basis_points":0},{"level":2,"reward_id":"queen_of_hearts.card_aura","roll_basis_points":9999}]'::jsonb,
    '61000000-0000-4000-8000-000000000004', repeat('4', 64)
  )$$,
  '42501', null,
  'the client cannot choose drop rolls or commit its own score'
);

reset role;
set local role service_role;
insert into phase6_responses values (
  'finish',
  public.apply_finish_boss_rush(
    '66666666-6666-4666-8666-666666666666',
    ((select response ->> 'campaign_id' from phase6_responses where name = 'start'))::uuid,
    repeat('b', 64), 'defeat', 2::smallint, 5000, 300000,
    '[{"level":1,"reward_id":"headless_horseman.spectral_trail","roll_basis_points":0},{"level":2,"reward_id":"queen_of_hearts.card_aura","roll_basis_points":9999}]'::jsonb,
    '61000000-0000-4000-8000-000000000004', repeat('4', 64)
  )
);

select is(
  (select response ->> 'status' from phase6_responses where name = 'finish'),
  'accepted',
  'a valid partial Boss Rush result is accepted'
);
select is(
  (select response ->> 'bosses_defeated' from phase6_responses where name = 'finish'),
  '2',
  'the canonical response keeps the defeated-boss count'
);
select is(
  (select response ->> 'mastery_xp_granted' from phase6_responses where name = 'finish'),
  '40',
  'Boss Rush grants reduced mastery'
);
select is(
  (select response ->> 'currency_granted' from phase6_responses where name = 'finish'),
  '0',
  'Boss Rush never grants campaign currency'
);
select is(
  (select response -> 'unique_rewards_granted' ->> 0 from phase6_responses where name = 'finish'),
  'headless_horseman.spectral_trail',
  'an eligible one-percent roll grants the defeated boss reward'
);
select is(
  (select count(*)::integer from public.boss_progress
   where user_id = '66666666-6666-4666-8666-666666666666'
     and character_id = 'jano'),
  2,
  'only defeated bosses receive progress'
);
select is(
  (select mastery_xp from public.character_progress
   where user_id = '66666666-6666-4666-8666-666666666666'
     and character_id = 'jano'),
  40::bigint,
  'reduced mastery is persisted once'
);
select is(
  (select mode from public.run_results
   where user_id = '66666666-6666-4666-8666-666666666666'),
  'boss_rush'::public.game_mode,
  'history stores Boss Rush separately from campaign results'
);
select is(
  (select mode from public.leaderboard_entries
   where user_id = '66666666-6666-4666-8666-666666666666'),
  'boss_rush'::public.game_mode,
  'the best score is published only in the Boss Rush partition'
);
select is(
  public.apply_finish_boss_rush(
    '66666666-6666-4666-8666-666666666666',
    ((select response ->> 'campaign_id' from phase6_responses where name = 'start'))::uuid,
    repeat('b', 64), 'defeat', 2::smallint, 5000, 300000,
    '[{"level":1,"reward_id":"headless_horseman.spectral_trail","roll_basis_points":0},{"level":2,"reward_id":"queen_of_hearts.card_aura","roll_basis_points":9999}]'::jsonb,
    '61000000-0000-4000-8000-000000000004', repeat('4', 64)
  ),
  (select response from phase6_responses where name = 'finish'),
  'an exact result retry returns the canonical response'
);
select is(
  (select victories from public.boss_progress
   where user_id = '66666666-6666-4666-8666-666666666666'
     and character_id = 'jano' and boss_level = 1),
  1,
  'retrying cannot duplicate a boss victory'
);
select is(
  (select mastery_xp from public.character_progress
   where user_id = '66666666-6666-4666-8666-666666666666'
     and character_id = 'jano'),
  40::bigint,
  'retrying cannot duplicate mastery'
);
select throws_ok(
  $$select public.apply_finish_boss_rush(
    '66666666-6666-4666-8666-666666666666',
    ((select response ->> 'campaign_id' from phase6_responses where name = 'start'))::uuid,
    repeat('b', 64), 'victory', 2::smallint, 5000, 300000,
    '[{"level":1,"reward_id":"headless_horseman.spectral_trail","roll_basis_points":0},{"level":2,"reward_id":"queen_of_hearts.card_aura","roll_basis_points":9999}]'::jsonb,
    '61000000-0000-4000-8000-000000000005', repeat('5', 64)
  )$$,
  '22023', null,
  'victory is impossible before defeating all ten bosses'
);
select is(
  (select provisional_currency from public.campaign_runs
   where id = ((select response ->> 'campaign_id' from phase6_responses where name = 'start'))::uuid),
  0::bigint,
  'Boss Rush leaves no provisional economy balance'
);
select is(
  (select state from public.campaign_runs
   where id = ((select response ->> 'campaign_id' from phase6_responses where name = 'start'))::uuid),
  'failed'::public.campaign_state,
  'death terminates the Boss Rush chain'
);
select is(
  (select count(*)::integer from public.leaderboard_entries
   where user_id = '66666666-6666-4666-8666-666666666666'
     and mode <> 'boss_rush'),
  0,
  'Boss Rush cannot enter Standard or Progression leaderboard partitions'
);

reset role;
select * from finish();
rollback;
