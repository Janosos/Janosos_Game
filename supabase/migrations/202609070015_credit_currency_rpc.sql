create or replace function public.credit_character_currency(
  p_character_id text,
  p_amount bigint
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null or p_amount <= 0 then
    return;
  end if;

  insert into public.character_progress (user_id, character_id, banked_currency, store_unlocked)
  values (v_user_id, p_character_id, p_amount, true)
  on conflict (user_id, character_id) do update
  set banked_currency = public.character_progress.banked_currency + p_amount,
      store_unlocked = true,
      updated_at = now();
end;
$$;

grant execute on function public.credit_character_currency(text, bigint) to authenticated;
