begin;

select plan(12);

insert into auth.users (id, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'owner@example.com', '{"display_name":"Owner"}'),
  ('22222222-2222-2222-2222-222222222222', 'other@example.com', '{"display_name":"Other"}');

insert into public.profile_identities (user_id, provider, linked_at, last_seen_at)
values
  ('11111111-1111-1111-1111-111111111111', 'email', now(), now()),
  ('22222222-2222-2222-2222-222222222222', 'email', now(), now());

set local role anon;
select throws_ok(
  $$select * from public.profiles$$,
  '42501',
  null,
  'anon cannot read profiles'
);
select throws_ok(
  $$update public.profiles set display_name = 'Intruder'$$,
  '42501',
  null,
  'anon cannot update profiles'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select is(
  (select count(*)::integer from public.profiles),
  1,
  'an authenticated user sees exactly their own profile'
);
select is(
  (select display_name from public.profiles),
  'Owner',
  'the visible profile belongs to the caller'
);
select lives_ok(
  $$update public.profiles set display_name = 'Owner Updated'
    where user_id = '11111111-1111-1111-1111-111111111111'$$,
  'the owner can update their profile'
);
select is(
  (select display_name from public.profiles),
  'Owner Updated',
  'the owner update is visible'
);
select is_empty(
  $$update public.profiles set display_name = 'Stolen'
    where user_id = '22222222-2222-2222-2222-222222222222'
    returning user_id$$,
  'a user cannot update another profile'
);
select is(
  (select count(*)::integer from public.profile_identities),
  1,
  'identity metadata exposes only the caller provider row'
);
select throws_ok(
  $$insert into public.profile_identities
    (user_id, provider, linked_at, last_seen_at)
    values (
      '11111111-1111-1111-1111-111111111111',
      'google',
      now(),
      now()
    )$$,
  '42501',
  null,
  'clients cannot forge identity metadata'
);
select lives_ok(
  $$select * from public.begin_account_deletion(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  )$$,
  'an authenticated user can begin account deletion'
);
select is(
  (select count(*)::integer
   from public.begin_account_deletion('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')),
  1,
  'repeating the idempotency key returns one canonical receipt'
);
select throws_ok(
  $$select public.complete_account_deletion(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true, null
  )$$,
  '42501',
  null,
  'clients cannot complete server deletion receipts'
);

select * from finish();
rollback;
