# Janosos Game V6 — implementation plan

Date: 2026-08-31  
Status: READY FOR IMPLEMENTATION  
Source design: `docs/designs/2026-08-31-rpg-progression-campaign-supabase.md`

## 1. Outcome

Deliver V6 as a sequence of playable vertical slices, preserving the current V5.1 runner while adding:

- Supabase email/password, Google, and Apple authentication.
- Cloud-backed per-character progress and inventory.
- Standard and Progression leaderboards split by character, plus personal history.
- Per-character mastery, currency, stats, exclusive skills, loadouts, and palette skins.
- A ten-level all-or-nothing campaign, ten bosses, 1% unique rewards, and Boss Rush.
- Offline practice plus one-token eligible offline stages with a bounded encrypted outbox.
- Schema-only preparation for later premium skins, with no payment behavior in V6.

The approved design is the product and security contract. This plan determines build order and file ownership; it does not relax any design invariant.

## 2. Verified baseline

Graphify reports 690 nodes and 735 edges. The implementation-sensitive hubs are `DinoRunGame`, `DinoComponent`, the HUD/overlay group, and `ScoreSystem`.

Current constraints:

- `lib/main.dart` directly creates `DinoRunGame` and owns three overlays.
- `lib/game/dino_run_game.dart` owns game lifecycle, input, audio, score, speed, spawning, and overlay transitions.
- `lib/game/components/dino.dart` owns all seven existing character behaviors and imports `CharacterType` from a presentation file.
- `lib/game/hud/score.dart` both calculates score and persists one device-wide `high_score`.
- `test/widget_test.dart` is stale and references nonexistent `MyApp`.
- There is no `supabase/` directory or Supabase project configuration.
- Flutter is not currently resolvable from this session's `PATH`; `flutter analyze` and `flutter test` have not been certified.
- The repository is on `main`, with `docs/` and `graphify-out/` currently untracked.

No implementation phase may report green tests until the Flutter toolchain is located/configured and the commands actually run.

## 3. Fixed technical choices

### Application composition

- `flutter_riverpod`, without generator annotations initially, for dependency injection, controllers, async state, and test overrides.
- `go_router` for the authenticated shell, redirects, OAuth callbacks, and six-platform deep links.
- Manual immutable domain models; avoid adding Freezed until repetition proves it valuable.
- Repository interfaces belong to domain/application code. Supabase and Drift implementations remain in data modules.

### Remote backend

- `supabase_flutter` stable 2.x, locked by `pubspec.lock`; do not adopt the 3.x prerelease.
- Supabase CLI migrations, PostgreSQL RLS, transactional SQL RPCs, and Deno Edge Functions.
- Publishable/anon key only in Flutter. Service-role and signing/drop secrets only in Supabase secret storage.
- Credentials arrive through `--dart-define` or CI secrets. No real `.env`, project URL, provider secret, or service key is committed.

### Local persistence

- Drift for cache metadata, local history projections, and outbox records on all six platforms.
- `NativeDatabase.createInBackground` on Android, iOS, Windows, macOS, and Linux.
- `WasmDatabase` plus worker on web. GitHub Pages uses Drift's compatible fallback because the preferred COOP/COEP headers can conflict with OAuth popups and are not guaranteed by Pages.
- `flutter_secure_storage` for Android Keystore, Apple Keychain, Windows protection, and Linux Secret Service.
- A custom `WebProtectedStore` uses Web Crypto with an origin-bound non-extractable key. Do not treat the standard package's web `LocalStorage` wrapping as satisfying the approved design.
- Sensitive outbox payloads use authenticated encryption; searchable status/age fields remain non-sensitive Drift columns.

### Canonical content

App and server must not maintain hand-copied balance catalogs. Canonical versioned JSON lives under `content/v6/`:

- `characters.json`
- `stats.json`
- `skills.json`
- `skins.json`
- `levels.json`
- `bosses.json`
- `rewards.json`

`tool/generate_catalogs.dart` validates IDs, ownership, caps, slot types, asset references, and compatibility, then generates:

- `lib/generated/content_catalog_v6.g.dart`
- `supabase/functions/_shared/generated/content_catalog_v6.ts`
- `supabase/seed/content_catalog_v6.sql`

Generated files are committed so CI and Edge Functions consume exactly the same content digest.

## 4. Target code structure

```text
lib/
  main.dart
  bootstrap.dart
  app/
    janosos_app.dart
    app_router.dart
    app_providers.dart
    app_theme.dart
  core/
    config/app_environment.dart
    errors/app_failure.dart
    persistence/app_database.dart
    persistence/database_connection_native.dart
    persistence/database_connection_web.dart
    security/protected_store.dart
    security/native_protected_store.dart
    security/web_protected_store.dart
    sync/outbox.dart
    sync/sync_coordinator.dart
    version/content_version.dart
  features/
    auth/{domain,data,application,presentation}/
    campaign/{domain,data,application,presentation}/
    leaderboard/{domain,data,application,presentation}/
    progression/{domain,data,application,presentation}/
    store/{domain,data,application,presentation}/
    profile/{domain,data,application,presentation}/
  game/
    domain/
      character_id.dart
      character_definition.dart
      run_configuration.dart
      gameplay_event.dart
      run_result.dart
      control_layout.dart
    runtime/
      gameplay_event_sink.dart
      ability_runtime.dart
      damage_runtime.dart
      level_runtime.dart
      boss_runtime.dart
    components/
    hud/
    dino_run_game.dart
content/v6/
supabase/
  migrations/
  functions/
  seed/
  tests/database/
test/
  core/
  features/
  game/
integration_test/
tool/
```

Existing component paths remain in place during the first refactor and move only when imports and characterization tests are green.

## 5. Execution phases

### Phase 0 — Toolchain, baseline, and safety rails

Goal: establish a truthful green baseline before architecture changes.

Tasks:

1. Locate or install a stable Flutter SDK compatible with Dart `^3.10.4`; record `flutter --version` and `flutter doctor -v`.
2. Run `flutter pub get`, `flutter analyze`, and `flutter test`; preserve the stale-test failure as baseline evidence.
3. Replace `test/widget_test.dart` with a real V5 shell smoke test and add a minimal `DinoRunGame` load/reset test.
4. Add `.github/workflows/quality.yml` for formatting verification, analysis, and tests on pull requests.
5. Centralize V6 display/build version; update `pubspec.yaml` only when the first V6 slice is runnable.
6. Document required Linux `libsecret` packages and the Flutter/Supabase CLI prerequisites.
7. Decide explicitly whether generated `graphify-out/` artifacts are committed or ignored; never mix that decision into feature diffs silently.

Exit gate:

- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test`
- CI performs the same checks.

### Phase 1 — Gameplay boundary with V5 behavior parity

Goal: make Flame consume immutable configuration and emit events without knowing persistence or Supabase.

Files created:

- `lib/game/domain/character_id.dart`
- `lib/game/domain/character_definition.dart`
- `lib/game/domain/run_configuration.dart`
- `lib/game/domain/gameplay_event.dart`
- `lib/game/domain/run_result.dart`
- `lib/game/runtime/gameplay_event_sink.dart`
- `test/game/character_behavior_test.dart`
- `test/game/run_configuration_test.dart`
- `test/game/scoring_test.dart`

Files changed:

- `lib/game/dino_run_game.dart`
- `lib/game/components/dino.dart`
- `lib/game/components/obstacle.dart`
- `lib/game/components/obstacle_manager.dart`
- `lib/game/components/projectile.dart`
- `lib/game/components/orb.dart`
- `lib/game/hud/score.dart`
- `lib/game/hud/character_selection_overlay.dart`
- `lib/game/hud/ability_button.dart`
- `lib/game/hud/hud_indicators.dart`

Tasks:

1. Move `CharacterType` out of `character_selection_overlay.dart`; use stable IDs (`jano`, `parker`, `chema`, `conra`, `shyno`, `nakama`, `nanic`) independent of localized labels.
2. Characterize the seven current abilities before changing them: projectile, extra life, regenerating shield/score penalty, intangibility, double jump, glide, and Nanic charge/discharge.
3. Introduce `RunConfiguration` with character, mode, base/normalized stats, core traits, loadout, level, content/protocol version, and deterministic seed.
4. Construct `DinoRunGame` with a configuration and `GameplayEventSink`.
5. Emit score, damage, life depletion, boss phase, victory, defeat, pause, and terminal result events.
6. Make `ScoreSystem` a pure runtime counter. Move `SharedPreferences` access into a later `LegacyScoreMigrator`.
7. Replace direct `gameOver()` persistence with a terminal gameplay event; the Flutter/application layer owns navigation and saving.
8. Replace hard-coded ability-button eligibility with `ControlLayout` from configuration.
9. Keep every existing V5 behavior and asset mapping unchanged in this phase.

Exit gate:

- Existing runner remains playable with all seven characters.
- No Supabase, Drift, JSON parsing, or repository import exists under `lib/game/` runtime code.
- Characterization and Flame tests pass.

### Phase 2 — App shell, local database, and authentication

Goal: add account lifecycle and safe local infrastructure without changing gameplay rewards.

Dependencies added with latest compatible stable releases and locked:

- `supabase_flutter`
- `flutter_riverpod`
- `go_router`
- `flutter_secure_storage`
- `drift`, `drift_dev`, and `build_runner`
- `path_provider`, `cryptography`, and `uuid`
- Flutter SDK `integration_test`

Tasks:

1. Add `bootstrap.dart`, `ProviderScope`, typed environment validation, and a fake/local composition root for tests.
2. Add `JanososApp` and `go_router` routes for `/auth`, `/auth/callback`, `/home`, `/characters`, `/leaderboard`, `/campaign`, `/store`, `/settings`, and `/game`.
3. Create `AuthRepository`, `AuthController`, `AuthGate`, login, registration, verification, reset, provider-linking, reauthentication, logout, and deletion screens.
4. Use PKCE redirect OAuth on web/Windows/Linux and native ID-token flows where supported on Android/iOS/macOS. Store only Supabase session tokens, never Google/Apple provider tokens.
5. Implement native protected storage plus fail-closed web protected storage; disable eligible offline progress when protection is unavailable.
6. Create Drift schema v1 for user namespaces, cached profile, outbox, result projections, and legacy-score state.
7. Implement `LegacyScoreMigrator`: preserve `high_score` as private “Récord local heredado,” never upload or assign it to a character.
8. Add initial Supabase migrations for profiles, identity metadata, deletion tombstones, grants, and RLS.
9. Add `delete-account` Edge Function with recent-auth enforcement and idempotent deletion receipt.
10. Configure Android/iOS/macOS/web/Windows/Linux deep-link manifests and documented redirect URLs; keep all provider IDs as placeholders.

Exit gate:

- Email registration/login/reset works against local Supabase.
- Google/Apple flows are integration-tested where credentials exist and degrade to an actionable configuration message where they do not.
- Account switching isolates caches; logout/delete wipes protected local data according to the confirmation flow.
- RLS tests prove users cannot read or mutate another profile.

### Phase 3 — Server-authorized campaign primitives and leaderboards first

Goal: deliver the first user-visible cloud feature requested: per-character leaderboards and personal history.

Migrations:

```text
supabase/migrations/
  202608310001_extensions_and_types.sql
  202608310002_profiles_and_characters.sql
  202608310003_campaigns_stages_results.sql
  202608310004_leaderboards_and_indexes.sql
  202608310005_command_receipts.sql
  202608310006_rls_and_grants.sql
  202608310007_transactional_rpcs.sql
```

Edge Functions/RPCs:

- `start-campaign`
- `start-stage`
- `finish-stage`
- `fail-campaign`
- `complete-campaign`
- SQL `apply_finish_stage` and `apply_complete_campaign`

Tasks:

1. Implement campaign/stage enums, one-account lease, sequence constraint, token digest, version claims, and six-hour expiry.
2. Implement request digest plus `(user, command_type, idempotency_key)` receipts returning the canonical first response.
3. Lock campaign/progress rows with `SELECT ... FOR UPDATE` inside each economic transaction.
4. Implement accepted defeat aggregation/publication in `finish-stage` and completion publication in `complete-campaign`.
5. Create the exact verified keyset index using character, mode, content version, completion, level, `total_score`, duration, `ended_at`, and ID.
6. Build `LeaderboardRepository`, controller, global top-100 pages of 25, character/mode filters, and last-100 personal history.
7. Show completed/failed, validation status, content version, level, score, duration, timestamp, and pending/limited/rejected explanations.
8. Build the encrypted bounded outbox with the approved 100-item/10-MB/30-day and retry policy.
9. Integrate current runtime terminal events with a level-one campaign attempt; unfinished content uses a clearly marked developer fixture, never a production leaderboard shortcut.
10. Add pgTAP tests for RLS, unique constraints, idempotency, races, ordering/ties, keyset pages, direct-write denial, and rejected versions.

Exit gate:

- Two users and all seven character filters are isolated correctly.
- Concurrent duplicate finishes produce one transaction and the same receipt.
- Failed and completed ordering matches the approved canonical index.
- Offline pending rows never appear globally before acceptance.

### Phase 4 — Mastery, economy, store, loadouts, and palette skins

Goal: complete permanent per-character progression while preserving Standard fairness.

Migrations/functions:

- Character mastery and banked currency.
- Stat ranks, skill unlocks, loadouts, skin unlocks, boss progress.
- Inert `premium_wallets` table with no client policy or grant/spend function.
- `purchase-upgrade`, `purchase-skill`, `purchase-skin`, and `equip-loadout`.

Tasks:

1. Implement the canonical content generator and digest checks.
2. Add five capped stat paths and the fixed mastery baseline track.
3. Define 28 exclusive skill catalog records: two active and two passive per character. Each record requires owner, slot, unlock level, character-currency cost, modes, caps, compatibility, UI explanation, and deterministic runtime effect.
4. Preserve current abilities as `core_traits` or `default_active`; never sell an existing identity back to the player.
5. Add `ProgressionRepository`, `EconomyService`, `LoadoutService`, and Riverpod controllers.
6. Build character progression, skill tree, stat detail, loadout, palette selection, catalog preview, and post-clear purchase screens.
7. Show temporary versus banked currency and preview current/new value plus post-purchase balance.
8. Normalize all power in Standard; add unit tests proving every stat, passive, active, and power drop is excluded.
9. Add palette generation/validation without duplicating animation logic or changing hitboxes.
10. Build the deterministic economy simulator and tune prices/XP toward the approved 20–30 hour median target.

Exit gate:

- Purchases are atomic, idempotent, per character, and impossible before that character's clear entitlement.
- All 28 skills have unit tests and compatibility tests.
- Standard results are identical for base and fully upgraded accounts given the same seed/input fixture.
- No premium balance or purchase affordance is visible or callable.

### Phase 5 — Level-one vertical slice

Goal: prove the complete campaign loop before multiplying content.

Content:

- Runner section and Headless Horseman boss.
- Original temporary pixel-art placeholder until source/name clearance is recorded.
- Spectral Trail 1% unique reward.

Tasks:

1. Add `LevelRuntime`, phase transitions, deterministic spawn script, boss arena, projectile pools, damage/resistance, and encounter-specific boss action.
2. Add lives, short invulnerability, runner defeat, boss defeat/victory, pause budget, sealed terminal result, and campaign reset.
3. Add preflight eligibility and current/offline/practice state.
4. Add skippable/reopenable controls tutorial and `ControlLayout` across touch, keyboard, and controller.
5. Add redundant shape/text/audio cues, high contrast, reduced motion, flash limits, subtitles, screen-shake control, and semantic pause/help UI.
6. Execute the server-side 1% HMAC roll, key versioning, persisted outcome, unique ownership, and normal “no drop” result.
7. Measure the exact worst-case pool/frame/memory fixture on the first available target hardware.

Exit gate:

- One level works online, eligible offline, and practice-only.
- Victory, life depletion, quit, force termination, token expiry, retry, rejection, and later synchronization each reach the documented state.
- No character requires a purchased skill or rare drop to defeat the boss.
- Accessibility checks pass without relying only on sound, color, animation, or haptics.

### Phase 6 — Levels 2–10 and Boss Rush

Goal: expand only the proven level-one pattern.

Build in two batches to limit balance regressions:

- Batch A: Queen of Hearts, Mr. Hyde, The Phantom, Snow Queen.
- Batch B: Dracula, Wicked Witch of the West, Frankenstein's Creature, Davy Jones, Professor Moriarty.

For each boss:

1. Complete documented source/name clearance before final naming or art generation.
2. Implement one signature mechanic, encounter-specific damage action, redundant cues, reduced-motion alternative, tutorial/help copy, and deterministic tests.
3. Generate original pixel-art assets from public-domain source descriptions only; do not imitate movie costumes, dialogue, music, logos, or later derivative designs.
4. Add and test its 1% reward, power cap, ownership, mode eligibility, and non-mandatory-clear assertion.
5. Run a three-character smoke set after each boss, then all seven characters before batch completion.

After level ten:

- Bank temporary character currency.
- Grant permanent per-character store entitlement.
- Publish the completed attempt.
- Unlock Boss Rush.

Boss Rush grants reduced mastery and eligible unique-drop rolls, but no campaign currency or store entitlement.

Exit gate:

- A deterministic automated fixture completes all ten levels with each character.
- Any terminal life depletion resets to level one and loses only provisional currency.
- Boss Rush is isolated from campaign leaderboards and economy.
- Balance simulator and human playtest show no rare reward is mandatory.

### Phase 7 — Hardening and six-platform release

Goal: satisfy every approved operational, privacy, accessibility, and performance gate.

Tasks:

1. Finish current/previous content and protocol compatibility tests for the 90-day window.
2. Add retention jobs, 24-hour deletion SLA audit, tombstone replay, sanitized 14-day logs, and technical SLO alerts.
3. Load-test 25 requests/second for ten minutes and 100 requests/second for one minute.
4. Configure daily backups, document RPO 24h/RTO 8h, and complete a staging restore drill.
5. Execute full release journeys on web, Android, iOS, Windows, macOS, and Linux.
6. Run the exact frame/memory matrix and all accessibility variants.
7. Update GitHub Pages deployment with publishable Supabase defines, WASM/worker assets, CSP compatible with OAuth, and no secret exposure.
8. Update README, setup guide, migration guide, privacy/data-retention explanation, account-deletion guide, and Apple six-month secret-rotation runbook.
9. Regenerate Graphify and compare affected hubs/import cycles after the final architecture settles.

Exit gate:

- All tests, builds, database checks, function checks, E2E journeys, load tests, restore drill, and performance/accessibility gates pass.
- Monthly infrastructure forecast remains below the approved threshold.
- No unresolved source/name clearance item or secret placeholder reaches production.

## 6. Test layout and commands

```text
test/game/                         pure gameplay/domain and Flame component tests
test/features/auth/                repository/controller/widget recovery states
test/features/leaderboard/         ordering, filters, pagination, status explanations
test/features/progression/         caps, prices, loadouts, normalization, palettes
test/core/persistence/             Drift migrations, encryption envelope, outbox limits
supabase/tests/database/           pgTAP RLS, constraints, transactions, receipts
supabase/functions/**/_test.ts     token/auth/request validation and error mapping
integration_test/                  platform journeys with fake/local Supabase
```

Required commands after the toolchain is available:

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
supabase db reset
supabase test db
deno fmt --check supabase/functions
deno lint supabase/functions
deno test supabase/functions
flutter test integration_test
```

Release builds are produced on native host runners: web/Android/Linux on Linux, Windows on Windows, and iOS/macOS on macOS.

## 7. Commit and review strategy

Use small commits that leave the app runnable. Suggested branches/PRs:

1. `codex/v6-foundation`
2. `codex/v6-auth`
3. `codex/v6-leaderboards`
4. `codex/v6-progression`
5. `codex/v6-level-1`
6. `codex/v6-campaign-content`
7. `codex/v6-hardening`

Every code batch receives language/framework review after tests. Security review is mandatory for auth, SQL/RLS, Edge Functions, protected storage, token logic, purchases, and deletion. Accessibility review is mandatory for every new UI and boss control/cue.

Do not combine generated content, database migrations, gameplay refactors, and large binary asset additions in one opaque commit.

## 8. External prerequisites and honest blockers

Local development can begin without production secrets, but these external items are required at their gates:

- Flutter SDK and Dart toolchain visible to the workspace.
- Supabase CLI and Deno.
- A user-created Supabase project for remote integration; local Supabase may be used first.
- Google OAuth client IDs/secrets and redirect allowlist.
- Apple Developer App ID, Services ID, key, and a six-month secret-rotation owner.
- HTTPS production origin and final deep-link domains.
- Access to each native platform runner for release testing.
- Documented public-domain/name clearance before final boss art.

If these are absent, tests must remain marked skipped/blocked with the exact missing prerequisite; they must never be reported as passing.

## 9. First implementation batch

The next execution should be limited to Phase 0 plus Phase 1:

1. Restore a working Flutter command.
2. Capture the real baseline failures.
3. Replace the stale widget test.
4. Add quality CI.
5. Extract `CharacterId` and immutable character definitions.
6. Add `RunConfiguration`, `GameplayEvent`, and the event sink.
7. Refactor `ScoreSystem` to pure runtime state.
8. Refactor `DinoRunGame` to receive configuration and emit a terminal result.
9. Preserve all seven existing character behaviors with characterization tests.
10. Run format, analysis, tests, and a framework-specific code review.
11. Stop and verify the playable V5 parity gate before adding Supabase dependencies.

This creates the stable seam required by every later feature and avoids coupling the network migration to the most fragile gameplay refactor.

## 10. Documentation references

- Approved local design: `docs/designs/2026-08-31-rpg-progression-campaign-supabase.md`
- Generated project map: `graphify-out/GRAPH_REPORT.md` and `graphify-out/graph.html`
- Supabase Flutter quickstart: <https://supabase.com/docs/guides/getting-started/quickstarts/flutter>
- Supabase Google login: <https://supabase.com/docs/guides/auth/social-login/auth-google>
- Supabase Apple login: <https://supabase.com/docs/guides/auth/social-login/auth-apple>
- Flutter deep links: <https://docs.flutter.dev/ui/navigation/deep-linking>
- Drift supported platforms: <https://drift.simonbinder.eu/platforms/>
- Drift web setup and fallback constraints: <https://drift.simonbinder.eu/platforms/web/>
- Flutter secure storage: <https://pub.dev/packages/flutter_secure_storage>
