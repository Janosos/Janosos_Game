# Janosos V6 Progress

## Status: Phase 0 complete; Phase 1 automated gate complete; Phase 2 automated gate complete; Phase 3 automated gate complete; Phase 4 economy/store gate complete

## Quick reference

- Research: `docs/janosos-v6/RESEARCH.md`
- Implementation: `docs/janosos-v6/IMPLEMENTATION.md`
- Approved design: `docs/designs/2026-08-31-rpg-progression-campaign-supabase.md`
- Detailed plan: `docs/plans/2026-08-31-v6-implementation-plan.md`

## Phase progress

### Phase 0: Toolchain, baseline, and safety rails

**Status:** Complete

#### Tasks completed

- Installed official Flutter 3.47.2 stable with Dart 3.13.2.
- Verified the official archive SHA-256 before extraction.
- Added `C:\Users\junio\develop\flutter\bin` to the user PATH.
- Enabled Windows Developer Mode for Flutter plugin symlinks.
- Captured the baseline: 39 analyzer findings and a stale widget test that
  referenced the nonexistent `MyApp` widget.
- Replaced the stale test and added `.github/workflows/quality.yml`.
- Verified formatting, analysis, tests, and a release web build.

#### Decisions made

- Use the current stable Flutter release; the project's Dart constraint accepts Dart 3.13.2.
- Execute only foundation/gameplay-boundary work before Supabase dependencies.

#### Verification

- `dart format --output=none --set-exit-if-changed lib test`: pass.
- `flutter analyze`: pass, 0 issues.
- `flutter test`: pass, 10 tests.
- `flutter build web --release --base-href "/Janosos_Game/"`: pass.

### Phase 1: Gameplay boundary with V5 behavior parity

**Status:** Automated gate complete; manual seven-character playthrough pending

#### Tasks completed

- Added stable IDs and centralized definitions for all seven V5 characters.
- Added immutable run stats, loadouts, configuration, control layout, results,
  and gameplay events.
- Changed `DinoRunGame` to consume `RunConfiguration` and emit terminal events.
- Removed storage access from `ScoreSystem`; `main.dart` now owns the temporary
  legacy high-score adapter.
- Updated Flame APIs without changing existing character mappings or abilities.
- Added character, configuration, score, widget, and architecture tests.

#### Remaining verification

- Complete a manual run with each of the seven characters on a live device.
- Review and decide separately whether `graphify-out/` should be committed.
- Install Android SDK command-line tools before the first Android release;
  this does not block the verified web/Windows development baseline.

### Phase 2: App shell, local database, and authentication

**Status:** Automated gate complete; signed-provider/device checks pending

#### Tasks completed

- Added Riverpod composition root, typed environment, guarded `go_router`
  routes, responsive app shell, auth UI, account settings, and local developer
  backend.
- Added email registration/login/reset contracts, Google/Apple provider flows,
  provider linking, password update, logout, and typed account deletion.
- Added native protected session storage and fail-closed web behavior.
- Added Drift schema v1 for account namespaces, profile cache, encrypted outbox
  records, result projections, and the private legacy score.
- Added legacy score migration that never uploads or attributes the old score.
- Added the initial Supabase profile/identity migration, least-privilege grants,
  RLS policies, pgTAP tests, deletion receipts, and the recent-authenticated
  `delete-account` Edge Function.
- Added Android/iOS/macOS deep-link manifests, Windows/Linux activation hooks,
  packaging metadata, and the matching Drift 2.34.3 web runtime assets.

#### Verification

- `dart format lib test`: pass.
- `flutter analyze`: pass, 0 issues.
- `flutter test`: pass, 21 tests.
- Drift code generation: pass.
- `flutter build web --release --base-href "/Janosos_Game/"`: pass,
  including the WASM dry run.
- Supabase migration applied on PostgreSQL 17 local: pass.
- pgTAP RLS suite: pass, 12 tests.
- Deno check/lint/format: pass.
- Account-deletion E2E: HTTP 200, deleted account login rejected with HTTP
  400, and profile cascade left zero rows.

#### Remaining manual verification

- Test native Google/Apple on signed devices after final provider credentials
  are available.
- Test packaged Windows and Linux protocol activation.

### Phase 3: Server-authorized campaigns, leaderboard, and result synchronization

**Status:** Automated gate complete; production deployment pending

#### Tasks completed

- Added server-owned campaign runs, stage leases, token digests, accepted run
  results, command receipts, and canonical leaderboard entries.
- Added current/previous client-version support and deterministic, rotating
  six-hour stage JWTs without storing raw tokens in PostgreSQL.
- Added idempotent start, finish, fail, and complete campaign transactions with
  row locks, canonical first responses, server-derived lives, rewards, and
  leaderboard publication.
- Added a sanitized keyset leaderboard RPC: authenticated clients can read the
  public ranking projection but cannot select the source table or user IDs.
- Added global top-100 and private last-100 history screens split by character,
  mode, and content version with explicit pending/limited/rejected states.
- Added an AES-256-GCM per-account outbox with authenticated metadata, bounded
  storage, expiry, exponential jitter, pause/retry behavior, and fail-closed key
  handling.
- Added the ten-world campaign catalog and an explicit level-one developer
  fixture that cannot grant rewards or publish rankings.

#### Verification

- `dart format lib test`: pass, 79 files unchanged.
- `flutter analyze`: pass, 0 issues.
- `flutter test`: pass, 33 tests.
- `flutter build web --release --base-href "/Janosos_Game/"`: pass,
  including the WASM dry run.
- Supabase pgTAP suites: pass, 60 tests.
- Deno check/format/lint: pass across all six campaign functions and the local
  E2E fixture.
- Authenticated HTTP E2E: deterministic stage retry, canonical finish retry,
  one sanitized leaderboard row, and one private history result.

#### Remaining deployment verification

- Configure production stage-signing keys and deploy migrations/functions to a
  non-local Supabase project.
- Exercise concurrent multi-device leases against the deployed environment.

### Phase 4: Mastery, economy, loadouts, and palette skins

**Status:** Economy/store automated gate complete; encounter integration pending

#### Tasks completed

- Added a canonical, versioned catalog digest with five stat paths and five
  ranks each, a fixed eight-step mastery baseline, 28 exclusive skills, and 21
  palette records.
- Added permanent stat, skill, palette, loadout, and boss-progress inventory
  tables with own-account read policies and no direct client mutation grants.
- Added atomic/idempotent upgrade, skill, palette, and loadout transactions;
  each validates character ownership, mastery, balance, catalog version,
  expected rank, compatibility, and active-campaign build freezing.
- Added four authenticated Edge Functions that derive the account from the JWT
  and delegate each economic mutation to one locking PostgreSQL transaction.
- Added server-authorized build resolution: Standard removes all bought power,
  Progresión applies capped stats/loadout, and campaign creation replaces the
  client lives/loadout hints with server-derived values.
- Added the Flutter progression repository/controller and replaced the store
  placeholder with responsive mastery, currency, stat, skill/loadout, and
  palette screens for all seven characters.
- Added bounded palette color matrices used by the existing sprite animations;
  palettes do not duplicate sheets, modify hitboxes, or expose paid skins.
- Added deterministic contracts for all 28 skill effects and kept every V5
  ability as an innate trait or default active rather than a purchase.
- Added a deterministic economy simulator using the canonical 38,400 character
  currency catalog and 46,500-XP mastery cap.

#### Verification

- `dart format --output=none --set-exit-if-changed lib test tool`: pass,
  95 files unchanged.
- `flutter analyze`: pass, 0 issues.
- `flutter test`: pass, 73 tests, including one deterministic/compatibility test
  for every exclusive skill.
- `flutter build web --release --base-href "/Janosos_Game/"`: pass,
  including the WASM dry run.
- Supabase pgTAP suites: pass, 111 tests.
- `supabase db lint --local --level warning`: pass, no schema errors or warnings.
- Deno check/format/lint: pass across 10 Edge Functions and two E2E fixtures.
- Economy HTTP E2E: entitlement enforced, canonical purchase retry, three owned
  exclusive skills, owned/equipped palette and loadout, Standard normalization,
  and active-campaign build freezing.
- Simulator (2,001 deterministic players): P10 22.28 h, median 25.10 h, and P90
  28.45 h, within the approved 20–30-hour median target.

#### Remaining encounter integration

- Consume the resolved active/passive effect contracts inside the level-one
  boss vertical slice and add Flame component tests for each trigger family.
- Feed the selected authorized build and palette into the real campaign route
  when it replaces the explicit no-reward developer fixture.
- Deploy the new migrations/functions to a non-local Supabase project and run
  signed-device plus accessibility journeys.

## Session log

### 2026-08-31

- Began implementation after user authorization.
- Installed and verified the Flutter toolchain.
- Initialized `build` workflow progress tracking.
- Recorded the failing baseline before changing production code.
- Completed the Phase 0 and Phase 1 automated gates.
- Implemented the Phase 2 app shell, authentication, persistence, RLS, account
  deletion, native social-provider adapters, and deep-link configuration.

### 2026-09-01

- Completed the Phase 3 transactional campaign, validation, leaderboard,
  history, encrypted outbox, and local authenticated HTTP gate.
- Hardened leaderboard privacy, server-derived base lives, stage-key rotation,
  and missing-key outbox behavior after implementation review.
- Began Phase 4 permanent per-character progression and economy work.
- Completed the Phase 4 economic/store vertical: authoritative purchases,
  loadouts, palette rendering, 28 skill contracts, UI, and balance simulator.
- Completed the level-one vertical slice with lives, pause/expiry rules,
  accessible boss cues, real campaign preflight, all exclusive runtime effects,
  durable result synchronization, and an idempotent server-only 1% drop.
- Expanded the proven slice to ten level definitions and ten original
  programmatic boss presentations with distinct attack patterns.
- Connected client progression to the server-owned campaign sequence, including
  level-ten completion, currency banking, permanent store entitlement, and
  explicit practice-only fallback.
- Added Boss Rush as a direct ten-boss chain with partial healing, reduced
  mastery, no campaign currency, eligible unique drops, encrypted retries, and
  an isolated leaderboard mode.
- Passed the Phase 6 gate: Flutter analysis, 90 Flutter tests, release web build,
  13 clean migrations, 153 pgTAP tests, and authenticated campaign/Boss Rush
  HTTP E2E fixtures.

### 2026-09-02

- Added a fourteenth operational migration with current/previous client
  compatibility, rank eligibility, a bounded personal-history RPC, daily
  retention, sanitized technical events, 24-hour deletion auditing, and
  tombstone replay after restore.
- Expanded the database gate to 178 passing pgTAP tests and a warning-free lint
  of the `private` and `public` application schemas.
- Added an authenticated load harness; full local runs passed with zero errors:
  15,000 requests at 25 rps/600 s and 6,000 at 100 rps/60 s, both at 5 ms p95.
- Hardened GitHub Pages deployment with production Supabase defines, official
  Pages artifacts, CSP, and a SQL/Deno CI job.
- Replaced placeholder settings with persistent audio and reduced-motion
  behavior, including the host accessibility preference.
- Removed template application identifiers, added external Android signing,
  installed the Windows ATL dependency, and built `janosos_game.exe` release.
- Added setup, V5 migration, privacy, deletion, backup/restore, SLO/load, Apple
  rotation, and release checklist documentation.
- Rebuilt and smoke-tested the Windows and local-web release bundles, recorded
  SHA-256 hashes, and added a local release handoff.
- Android SDK installation was declined at the Windows elevation prompt, so APK
  compilation remains an explicit local toolchain gate rather than claimed.
- Replaced the catalog-only local fallback with account-scoped persistent
  campaign, currency, mastery, store, palettes, exclusive skills, unique drops,
  and Boss Rush behavior so the credential-free Windows/Web delivery is a full
  local game rather than a practice shell.
- Added crash-safe one-time campaign banking, cross-mode active-run exclusion,
  store freezing during campaign/Boss Rush, and deletion of the matching local
  gameplay namespace with the account.
- Expanded the Flutter gate to 101 passing tests and added a passing Windows
  application journey covering registration, protected navigation, settings,
  session restoration, and account deletion.
- Rebuilt and smoke-tested the Windows/Web local packages after the parity
  changes; release hashes are recorded in `docs/releases/6.0.0-dev.1.md`.

## Files changed

- Added `lib/game/domain/` contracts and `lib/game/runtime/` event boundary.
- Refactored the current Flame game, character component, HUD, and overlays.
- Replaced the stale widget test and added focused game/architecture tests.
- Added the pull-request quality workflow.
- Added `lib/app/`, `lib/core/`, and `lib/features/auth/` application layers.
- Added `supabase/` migrations, RLS tests, and the account-deletion function.
- Added provider/deep-link configuration documentation and web database assets.
- Added campaign/result migrations, six campaign Edge Functions, leaderboard
  and campaign screens, encrypted synchronization, and their SQL/Dart/E2E tests.
- Added Phase 4 catalog/inventory migrations, four economy Edge Functions,
  progression UI/domain/data layers, palette rendering, and balance tooling.
- Added generic campaign boss/hazard components, the ten-level runtime,
  campaign/Boss Rush coordinators, two Boss Rush Edge Functions, the Phase 6
  transaction migration, and Phase 5/6 database and HTTP test suites.

## Architectural decisions

- The Flame runtime receives immutable configuration and emits events.
- Networking and persistence remain outside Flame's `update()` path.
- Stable character IDs are independent of display names and assets.
- The application layer is the only owner of legacy high-score persistence.
- Public clients receive only least-privilege profile grants; deletion authority
  remains in the Edge Function.
- Provider tokens are exchanged in memory and are not persisted by the game.
- Raw stage tokens and leaderboard user IDs are never exposed through database
  projections; economic commands are idempotent server transactions.
- Standard runs remain normalized and cannot grant currency, drops, or power.
- Store mutations freeze while a campaign is active so a signed stage cannot
  change its build mid-run.
- V6 palettes are bounded render transforms over existing sheets; future paid
  sprite sheets remain an inert schema seam with no wallet or purchase API.
- Boss Rush reuses the equipped progression build but has one signed attempt,
  no currency path, reduced mastery, and a separate `boss_rush` score partition.

## Lessons learned

- Flutter was absent from the active PATH and required an explicit SDK installation.
- The existing project had 39 analyzer findings, but only the stale `MyApp`
  reference blocked test compilation.
