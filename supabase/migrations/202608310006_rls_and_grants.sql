-- Janosos V6 phase 3: least-privilege reads and authoritative server writes.

alter table public.characters enable row level security;
alter table public.character_progress enable row level security;
alter table public.campaign_runs enable row level security;
alter table public.run_results enable row level security;
alter table public.leaderboard_entries enable row level security;

revoke all on table public.characters from anon, authenticated;
revoke all on table public.character_progress from anon, authenticated;
revoke all on table public.campaign_runs from anon, authenticated;
revoke all on table public.run_results from anon, authenticated;
revoke all on table public.leaderboard_entries from anon, authenticated;

grant select on table public.characters to authenticated;
grant select on table public.character_progress to authenticated;
grant select on table public.campaign_runs to authenticated;
grant select on table public.run_results to authenticated;

create policy characters_read_authenticated
on public.characters for select
to authenticated
using (enabled);

create policy character_progress_read_own
on public.character_progress for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy campaign_runs_read_own
on public.campaign_runs for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy run_results_read_own
on public.run_results for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

grant all on table public.characters,
  public.character_progress,
  public.campaign_runs,
  public.run_results,
  public.leaderboard_entries to service_role;

revoke all on table private.campaign_stages,
  private.command_receipts,
  private.premium_wallets,
  private.supported_client_versions from public, anon, authenticated;

grant all on table private.campaign_stages,
  private.command_receipts,
  private.premium_wallets,
  private.supported_client_versions to service_role;

grant usage on schema private to service_role;
