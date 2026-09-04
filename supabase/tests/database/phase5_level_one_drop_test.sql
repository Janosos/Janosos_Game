begin;

select plan(19);

insert into auth.users (id, email, raw_user_meta_data)
values (
  '55555555-5555-4555-8555-555555555555',
  'phase5@example.com',
  '{"display_name":"Phase Five"}'
);

create temporary table phase5_responses (
  name text primary key,
  response jsonb not null
);
grant all on table phase5_responses to authenticated, service_role;

select has_column(
  'private', 'campaign_stages', 'drop_roll_basis_points',
  'campaign stages persist the secret-derived roll outcome'
);
select has_column(
  'private', 'campaign_stages', 'unique_drop_granted',
  'campaign stages persist whether the unique reward was granted'
);
select function_privs_are(
  'public',
  'apply_finish_stage_with_drop',
  array[
    'uuid', 'uuid', 'text', 'run_outcome', 'bigint', 'bigint', 'text',
    'bigint', 'bigint', 'text', 'integer', 'uuid', 'text'
  ],
  'service_role',
  array['EXECUTE'],
  'only service role can execute the drop-aware finish transaction'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated"}',
  true
);

insert into phase5_responses values (
  'campaign_one',
  public.start_campaign(
    'jano', 'progression', 'v6-preview-1', 1, repeat('a', 64), 1::smallint,
    '51000000-0000-4000-8000-000000000001', repeat('1', 64)
  )
);
select is(
  (select response ->> 'status' from phase5_responses where name = 'campaign_one'),
  'accepted',
  'level-one progression campaign starts'
);

insert into phase5_responses values (
  'stage_one',
  public.start_stage(
    ((select response ->> 'campaign_id' from phase5_responses where name = 'campaign_one'))::uuid,
    repeat('b', 64), repeat('c', 64),
    ((select response ->> 'lease_expires_at' from phase5_responses where name = 'campaign_one'))::timestamptz - interval '5 hours 59 minutes 59 seconds',
    ((select response ->> 'lease_expires_at' from phase5_responses where name = 'campaign_one'))::timestamptz,
    1::smallint, 1::smallint,
    '51000000-0000-4000-8000-000000000002', repeat('2', 64)
  )
);
select is(
  (select response ->> 'sequence' from phase5_responses where name = 'stage_one'),
  '1',
  'the issued stage is boss level one'
);

select throws_ok(
  $$select public.apply_finish_stage_with_drop(
    '55555555-5555-4555-8555-555555555555',
    ((select response ->> 'campaign_id' from phase5_responses where name = 'campaign_one'))::uuid,
    repeat('b', 64), 'victory', 1800, 240000, null, 180, 110,
    'headless_horseman.spectral_trail', 0,
    '51000000-0000-4000-8000-000000000003', repeat('3', 64)
  )$$,
  '42501', null,
  'authenticated clients cannot choose their own boss-drop roll'
);

reset role;
set local role service_role;

insert into phase5_responses values (
  'finish_one',
  public.apply_finish_stage_with_drop(
    '55555555-5555-4555-8555-555555555555',
    ((select response ->> 'campaign_id' from phase5_responses where name = 'campaign_one'))::uuid,
    repeat('b', 64), 'victory', 1800, 240000, null, 180, 110,
    'headless_horseman.spectral_trail', 0,
    '51000000-0000-4000-8000-000000000003', repeat('3', 64)
  )
);

select is(
  (select (response ->> 'unique_drop_granted')::boolean
   from phase5_responses where name = 'finish_one'),
  true,
  'a server roll below one percent grants the reward'
);
select is(
  (select response ->> 'unique_reward_id'
   from phase5_responses where name = 'finish_one'),
  'headless_horseman.spectral_trail',
  'the response identifies the level-one reward'
);
select is(
  (select victories from public.boss_progress
   where user_id = '55555555-5555-4555-8555-555555555555'
     and character_id = 'jano' and boss_level = 1),
  1,
  'the first accepted victory increments boss progress once'
);
select ok(
  (select unique_reward_owned from public.boss_progress
   where user_id = '55555555-5555-4555-8555-555555555555'
     and character_id = 'jano' and boss_level = 1),
  'the unique reward is permanent immediately after acceptance'
);
select is(
  (select drop_roll_basis_points from private.campaign_stages
   where token_digest = repeat('b', 64)),
  0,
  'the exact roll is persisted in private stage state'
);

select is(
  public.apply_finish_stage_with_drop(
    '55555555-5555-4555-8555-555555555555',
    ((select response ->> 'campaign_id' from phase5_responses where name = 'campaign_one'))::uuid,
    repeat('b', 64), 'victory', 1800, 240000, null, 180, 110,
    'headless_horseman.spectral_trail', 0,
    '51000000-0000-4000-8000-000000000003', repeat('3', 64)
  ),
  (select response from phase5_responses where name = 'finish_one'),
  'an exact retry returns the persisted drop outcome'
);
select is(
  (select victories from public.boss_progress
   where user_id = '55555555-5555-4555-8555-555555555555'
     and character_id = 'jano' and boss_level = 1),
  1,
  'retrying cannot increment victories or reroll'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated"}',
  true
);
insert into phase5_responses values (
  'campaign_two',
  public.start_campaign(
    'jano', 'progression', 'v6-preview-1', 1, repeat('d', 64), 1::smallint,
    '52000000-0000-4000-8000-000000000001', repeat('4', 64)
  )
);
insert into phase5_responses values (
  'stage_two',
  public.start_stage(
    ((select response ->> 'campaign_id' from phase5_responses where name = 'campaign_two'))::uuid,
    repeat('e', 64), repeat('f', 64),
    ((select response ->> 'lease_expires_at' from phase5_responses where name = 'campaign_two'))::timestamptz - interval '5 hours 59 minutes 59 seconds',
    ((select response ->> 'lease_expires_at' from phase5_responses where name = 'campaign_two'))::timestamptz,
    1::smallint, 1::smallint,
    '52000000-0000-4000-8000-000000000002', repeat('5', 64)
  )
);

reset role;
set local role service_role;
insert into phase5_responses values (
  'finish_two',
  public.apply_finish_stage_with_drop(
    '55555555-5555-4555-8555-555555555555',
    ((select response ->> 'campaign_id' from phase5_responses where name = 'campaign_two'))::uuid,
    repeat('e', 64), 'victory', 1900, 241000, null, 190, 110,
    'headless_horseman.spectral_trail', 0,
    '52000000-0000-4000-8000-000000000003', repeat('6', 64)
  )
);

select is(
  (select (response ->> 'unique_drop_granted')::boolean
   from phase5_responses where name = 'finish_two'),
  false,
  'an already-owned reward is never granted twice'
);
select is(
  (select (response ->> 'unique_drop_already_owned')::boolean
   from phase5_responses where name = 'finish_two'),
  true,
  'the canonical response distinguishes already-owned from a normal miss'
);
select is(
  (select victories from public.boss_progress
   where user_id = '55555555-5555-4555-8555-555555555555'
     and character_id = 'jano' and boss_level = 1),
  2,
  'a distinct accepted campaign records the next victory'
);
select is(
  (select count(*)::integer from public.boss_progress
   where user_id = '55555555-5555-4555-8555-555555555555'
     and character_id = 'jano' and boss_level = 1),
  1,
  'boss ownership remains one row per user, character and boss'
);
reset role;
select is(
  private.reward_id_for_level(10::smallint),
  'moriarty.strategist_crown',
  'the server has a fixed reward mapping through level ten'
);
select is(
  private.reward_id_for_level(11::smallint),
  null,
  'the server rejects reward mappings beyond the campaign'
);

select * from finish();
rollback;
