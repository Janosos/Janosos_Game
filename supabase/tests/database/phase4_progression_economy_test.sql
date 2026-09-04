begin;

select plan(51);

insert into auth.users (id, email, raw_user_meta_data)
values
  ('33333333-3333-4333-8333-333333333333', 'economy-alpha@example.com', '{"display_name":"Economy Alpha"}'),
  ('44444444-4444-4444-8444-444444444444', 'economy-bravo@example.com', '{"display_name":"Economy Bravo"}');

create temporary table economy_responses (
  name text primary key,
  response jsonb not null
);
grant all on table economy_responses to authenticated, service_role;

select is((select count(*)::integer from public.stat_catalog), 5, 'five stat paths are canonical');
select is((select count(*)::integer from public.stat_rank_catalog), 25, 'every stat path has five ranks');
select is((select count(*)::integer from public.skill_catalog), 28, 'the catalog contains exactly 28 exclusive skills');
select results_eq(
  $$select count(*)::integer from public.skill_catalog group by character_id order by character_id$$,
  $$values (4), (4), (4), (4), (4), (4), (4)$$,
  'every character owns four catalog skills'
);
select results_eq(
  $$select count(*)::integer from public.skill_catalog where slot = 'active' group by character_id order by character_id$$,
  $$values (2), (2), (2), (2), (2), (2), (2)$$,
  'every character owns two active skills'
);
select results_eq(
  $$select count(*)::integer from public.skill_catalog where slot = 'passive' group by character_id order by character_id$$,
  $$values (2), (2), (2), (2), (2), (2), (2)$$,
  'every character owns two passive skills'
);
select is(
  (select count(*)::integer from public.skill_catalog where 'standard' = any(compatible_modes)),
  0,
  'purchased skills never declare Standard compatibility'
);
select is((select count(*)::integer from public.skin_catalog), 21, 'three palette records exist per character');
select is(
  (select count(*)::integer from public.skin_catalog where available_in_v6 and future_premium_sku is not null),
  0,
  'no V6-visible skin exposes a premium SKU'
);
select throws_ok(
  $$insert into public.skin_catalog (
      id, character_id, display_name, palette_parameters,
      unlock_level, cost, sort_order
    ) values (
      'jano_invalid_palette', 'jano', 'Invalid',
      '{"hue_shift":999,"saturation_basis_points":10000,"value_basis_points":10000}',
      0, 0, 20
    )$$,
  '23514', null, 'unsafe palette transforms are rejected by the catalog'
);
select ok(
  (select catalog_digest ~ '^[0-9a-f]{64}$' from public.content_manifests where content_version = 'v6-preview-1'),
  'the canonical catalog has a SHA-256 digest'
);
select is(
  (select catalog_digest from public.content_manifests where content_version = 'v6-preview-1'),
  private.compute_progression_catalog_digest('v6-preview-1'),
  'the stored manifest matches the generated catalog'
);
select is(private.mastery_level_for_xp(46500), 30::smallint, '46500 XP reaches mastery 30');
select is(private.mastery_level_for_xp(46499), 29::smallint, 'mastery 30 cannot unlock one XP early');

set local role anon;
select throws_ok(
  $$select * from public.skill_catalog$$,
  '42501', null, 'anonymous callers cannot browse progression content'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated"}',
  true
);
select is((select count(*)::integer from public.skill_catalog), 28, 'authenticated players can browse the catalog');
select is(
  public.get_progression_snapshot('jano', 'v6-preview-1') ->> 'character_id',
  'jano',
  'a new account receives a zeroed, browsable snapshot'
);
select throws_ok(
  $$insert into public.stat_upgrades (user_id, character_id, stat_id, purchased_rank)
    values ('33333333-3333-4333-8333-333333333333', 'jano', 'speed', 5)$$,
  '42501', null, 'clients cannot grant stat ranks directly'
);
select throws_ok(
  $$select public.apply_purchase_upgrade(
    '33333333-3333-4333-8333-333333333333', 'jano', 'speed', 0::smallint,
    'v6-preview-1', repeat('a', 64),
    '30000000-0000-4000-8000-000000000001', repeat('1', 64)
  )$$,
  '42501', null, 'authenticated clients cannot bypass the purchase Edge Function'
);

reset role;
insert into public.character_progress (
  user_id, character_id, mastery_xp, banked_currency, purchase_phase_unlocked
) values (
  '33333333-3333-4333-8333-333333333333', 'jano', 46500, 100000, false
);

set local role service_role;
insert into economy_responses values (
  'locked_upgrade',
  public.apply_purchase_upgrade(
    '33333333-3333-4333-8333-333333333333', 'jano', 'speed', 0::smallint,
    'v6-preview-1', (select catalog_digest from public.content_manifests where content_version = 'v6-preview-1'),
    '30000000-0000-4000-8000-000000000002', repeat('2', 64)
  )
);
select is(
  (select response ->> 'code' from economy_responses where name = 'locked_upgrade'),
  'store_locked',
  'purchases are impossible before the character clear entitlement'
);

reset role;
update public.character_progress
set purchase_phase_unlocked = true
where user_id = '33333333-3333-4333-8333-333333333333' and character_id = 'jano';

set local role service_role;
insert into economy_responses values (
  'speed_one',
  public.apply_purchase_upgrade(
    '33333333-3333-4333-8333-333333333333', 'jano', 'speed', 0::smallint,
    'v6-preview-1', (select catalog_digest from public.content_manifests where content_version = 'v6-preview-1'),
    '30000000-0000-4000-8000-000000000003', repeat('3', 64)
  )
);
select is((select response ->> 'status' from economy_responses where name = 'speed_one'), 'accepted', 'an eligible stat purchase succeeds');
select is(
  (select banked_currency from public.character_progress where user_id = '33333333-3333-4333-8333-333333333333' and character_id = 'jano'),
  99800::bigint,
  'the stat cost is deducted atomically'
);
select is(
  (select purchased_rank from public.stat_upgrades where user_id = '33333333-3333-4333-8333-333333333333' and character_id = 'jano' and stat_id = 'speed'),
  1::smallint,
  'the purchased rank advances exactly once'
);
select is(
  public.apply_purchase_upgrade(
    '33333333-3333-4333-8333-333333333333', 'jano', 'speed', 0::smallint,
    'v6-preview-1', (select catalog_digest from public.content_manifests where content_version = 'v6-preview-1'),
    '30000000-0000-4000-8000-000000000003', repeat('3', 64)
  ),
  (select response from economy_responses where name = 'speed_one'),
  'an exact purchase retry returns the first canonical response'
);
select throws_ok(
  $$select public.apply_purchase_upgrade(
    '33333333-3333-4333-8333-333333333333', 'jano', 'speed', 0::smallint,
    'v6-preview-1', (select catalog_digest from public.content_manifests where content_version = 'v6-preview-1'),
    '30000000-0000-4000-8000-000000000003', repeat('4', 64)
  )$$,
  '22023', null, 'a changed purchase cannot reuse an idempotency key'
);
insert into economy_responses values (
  'stale_rank',
  public.apply_purchase_upgrade(
    '33333333-3333-4333-8333-333333333333', 'jano', 'speed', 0::smallint,
    'v6-preview-1', (select catalog_digest from public.content_manifests where content_version = 'v6-preview-1'),
    '30000000-0000-4000-8000-000000000004', repeat('5', 64)
  )
);
select is((select response ->> 'code' from economy_responses where name = 'stale_rank'), 'stale_rank', 'stale rank previews fail safely');
select is(
  (select banked_currency from public.character_progress where user_id = '33333333-3333-4333-8333-333333333333' and character_id = 'jano'),
  99800::bigint,
  'a rejected stale purchase spends nothing'
);

insert into economy_responses values (
  'ricochet',
  public.apply_purchase_skill(
    '33333333-3333-4333-8333-333333333333', 'jano', 'jano_ricochet_round',
    'v6-preview-1', (select catalog_digest from public.content_manifests where content_version = 'v6-preview-1'),
    '30000000-0000-4000-8000-000000000005', repeat('6', 64)
  )
);
select is((select response ->> 'status' from economy_responses where name = 'ricochet'), 'accepted', 'an exclusive skill can be purchased by its owner character');
select is(
  (select count(*)::integer from public.skill_unlocks where user_id = '33333333-3333-4333-8333-333333333333' and character_id = 'jano'),
  1,
  'the exclusive skill is permanently owned once'
);
insert into economy_responses values (
  'wrong_character',
  public.apply_purchase_skill(
    '33333333-3333-4333-8333-333333333333', 'jano', 'parker_guard_dash',
    'v6-preview-1', (select catalog_digest from public.content_manifests where content_version = 'v6-preview-1'),
    '30000000-0000-4000-8000-000000000006', repeat('7', 64)
  )
);
select is((select response ->> 'code' from economy_responses where name = 'wrong_character'), 'invalid_skill', 'skills cannot cross character ownership boundaries');

insert into economy_responses values (
  'aurora',
  public.apply_purchase_skin(
    '33333333-3333-4333-8333-333333333333', 'jano', 'jano_aurora',
    'v6-preview-1', (select catalog_digest from public.content_manifests where content_version = 'v6-preview-1'),
    '30000000-0000-4000-8000-000000000007', repeat('8', 64)
  )
);
select is((select response ->> 'status' from economy_responses where name = 'aurora'), 'accepted', 'an earned palette can be purchased');
select is(
  (select count(*)::integer from public.skin_unlocks where user_id = '33333333-3333-4333-8333-333333333333' and character_id = 'jano'),
  1,
  'the palette unlock is permanent'
);

insert into economy_responses values (
  'quickdraw',
  public.apply_purchase_skill(
    '33333333-3333-4333-8333-333333333333', 'jano', 'jano_quickdraw',
    'v6-preview-1', (select catalog_digest from public.content_manifests where content_version = 'v6-preview-1'),
    '30000000-0000-4000-8000-000000000008', repeat('9', 64)
  )
);
select is((select response ->> 'status' from economy_responses where name = 'quickdraw'), 'accepted', 'the first passive can be purchased');
insert into economy_responses values (
  'scavenger',
  public.apply_purchase_skill(
    '33333333-3333-4333-8333-333333333333', 'jano', 'jano_scavenger_sight',
    'v6-preview-1', (select catalog_digest from public.content_manifests where content_version = 'v6-preview-1'),
    '30000000-0000-4000-8000-000000000009', repeat('a', 64)
  )
);
select is((select response ->> 'status' from economy_responses where name = 'scavenger'), 'accepted', 'the second passive can be purchased');

insert into economy_responses values (
  'equip',
  public.apply_equip_loadout(
    '33333333-3333-4333-8333-333333333333', 'jano',
    'jano_ricochet_round', 'jano_quickdraw', 'jano_scavenger_sight', 'jano_aurora',
    'v6-preview-1', (select catalog_digest from public.content_manifests where content_version = 'v6-preview-1'),
    '30000000-0000-4000-8000-000000000010', repeat('b', 64)
  )
);
select is((select response ->> 'status' from economy_responses where name = 'equip'), 'accepted', 'an owned compatible loadout can be equipped');
select is(
  (select active_skill_id from public.loadouts where user_id = '33333333-3333-4333-8333-333333333333' and character_id = 'jano'),
  'jano_ricochet_round',
  'the selected active is stored'
);
select is(
  (select num_nonnulls(passive_skill_1_id, passive_skill_2_id) from public.loadouts where user_id = '33333333-3333-4333-8333-333333333333' and character_id = 'jano'),
  2,
  'at most two distinct owned passives are stored'
);
insert into economy_responses values (
  'cross_equip',
  public.apply_equip_loadout(
    '33333333-3333-4333-8333-333333333333', 'jano',
    'jano_ricochet_round', 'parker_reinforced_vest', null, 'jano_aurora',
    'v6-preview-1', (select catalog_digest from public.content_manifests where content_version = 'v6-preview-1'),
    '30000000-0000-4000-8000-000000000011', repeat('c', 64)
  )
);
select is((select response ->> 'code' from economy_responses where name = 'cross_equip'), 'passive_not_owned', 'loadouts reject cross-character passives');

select is(
  (public.get_authorized_run_configuration(
    '33333333-3333-4333-8333-333333333333', 'jano', 'standard', 'v6-preview-1'
  ) #>> '{stats,speed_basis_points}')::integer,
  0,
  'Standard removes purchased and baseline speed'
);
select is(
  (public.get_authorized_run_configuration(
    '33333333-3333-4333-8333-333333333333', 'jano', 'standard', 'v6-preview-1'
  ) #>> '{stats,damage_basis_points}')::integer,
  0,
  'Standard removes every damage bonus'
);
select is(
  jsonb_array_length(public.get_authorized_run_configuration(
    '33333333-3333-4333-8333-333333333333', 'jano', 'standard', 'v6-preview-1'
  ) #> '{loadout,passive_skill_ids}'),
  0,
  'Standard removes all purchased passives'
);
select is(
  public.get_authorized_run_configuration(
    '33333333-3333-4333-8333-333333333333', 'jano', 'progression', 'v6-preview-1'
  ) #>> '{loadout,active_skill_id}',
  'jano_ricochet_round',
  'Progression applies the selected active'
);
select is(
  jsonb_array_length(public.get_authorized_run_configuration(
    '33333333-3333-4333-8333-333333333333', 'jano', 'progression', 'v6-preview-1'
  ) #> '{loadout,passive_skill_ids}'),
  2,
  'Progression applies both selected passives'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated"}',
  true
);
select is(
  (select count(*)::integer
   from jsonb_array_elements(public.get_progression_snapshot('jano', 'v6-preview-1') -> 'skills') as item
   where (item ->> 'owned')::boolean),
  3,
  'the snapshot reports the three purchased skills'
);
select ok(
  not (public.get_progression_snapshot('jano', 'v6-preview-1') ? 'premium_wallet'),
  'the public snapshot contains no premium balance or affordance'
);

select is((select count(*)::integer from public.skill_unlocks), 3, 'inventory RLS exposes only the current account');
select set_config(
  'request.jwt.claims',
  '{"sub":"44444444-4444-4444-8444-444444444444","role":"authenticated"}',
  true
);
select is((select count(*)::integer from public.skill_unlocks), 0, 'another account cannot see purchased skills');

reset role;
insert into public.stat_upgrades (user_id, character_id, stat_id, purchased_rank)
values ('33333333-3333-4333-8333-333333333333', 'jano', 'vitality', 5);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated"}',
  true
);
insert into economy_responses values (
  'progression_campaign',
  public.start_campaign(
    'jano', 'progression', 'v6-preview-1', 1, repeat('f', 64), 1::smallint,
    '30000000-0000-4000-8000-000000000012', repeat('d', 64)
  )
);
select is(
  (select lives_remaining from public.campaign_runs where id = ((select response ->> 'campaign_id' from economy_responses where name = 'progression_campaign'))::uuid),
  2::smallint,
  'Progression authorizes at most one purchased extra life for Jano'
);
select isnt(
  (select loadout_digest from public.campaign_runs where id = ((select response ->> 'campaign_id' from economy_responses where name = 'progression_campaign'))::uuid),
  repeat('f', 64),
  'the campaign trigger replaces the client-provided loadout digest'
);
insert into economy_responses values (
  'standard_campaign',
  public.start_campaign(
    'jano', 'standard', 'v6-preview-1', 1, repeat('e', 64), 3::smallint,
    '30000000-0000-4000-8000-000000000013', repeat('e', 64)
  )
);
select is(
  (select lives_remaining from public.campaign_runs where id = ((select response ->> 'campaign_id' from economy_responses where name = 'standard_campaign'))::uuid),
  1::smallint,
  'Standard restores the base life count despite purchases and client input'
);
select throws_ok(
  $$select * from private.premium_wallets$$,
  '42501', null, 'premium wallets remain completely inaccessible'
);

select * from finish();
rollback;
