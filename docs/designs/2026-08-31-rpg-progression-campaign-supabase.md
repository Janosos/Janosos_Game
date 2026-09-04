# Janosos Game — RPG progression, cloud accounts, leaderboards, and world campaign

Date: 2026-08-31  
Status: APPROVED — user-validated and structured peer-reviewed  
Target release: V6

## 1. Understanding summary

- Expand the existing Flutter/Flame endless runner into an RPG/roguelite progression system for all seven characters.
- Add Supabase-backed accounts, cloud progress, inventory, purchases, and global leaderboards.
- Preserve each character's unique identity while adding character-specific stats, palette skins, and four exclusive skills.
- Add a ten-level campaign with one boss per level; exhausting all lives resets the campaign to level one.
- Preserve permanent purchases, boss drops, and mastery across failed campaigns while losing the current campaign's unbanked currency.
- Support web, Android, iOS, Windows, macOS, and Linux for a small initial community under 1,000 active players.

## 2. Existing baseline

- `DinoRunGame` owns the Flame loop, overlays, global speed, score, and game-over transition.
- `DinoComponent` contains seven hard-coded character abilities and collision behavior.
- `ScoreSystem` stores one device-wide high score through `shared_preferences`.
- The current game has no account, backend, economy, inventory, campaign, boss, or leaderboard domains.
- The existing widget test references a removed `MyApp` type and must be replaced.

## 3. Goals

- Reward continued play through mastery even when a campaign fails.
- Provide meaningful, bounded RPG customization without compromising the standard leaderboard.
- Keep the Flame update loop independent of network availability and latency.
- Make economy mutations and leaderboard publication server-authorized, with an explicit plausibility-based trust model.
- Deliver a complete ten-level campaign and a post-campaign Boss Rush.
- Prepare the schema for future premium skins without enabling real-money purchases in V6.

## 4. Explicit non-goals

- No real-money purchases or visible premium currency in V6.
- No custom administration or moderation panel.
- No detailed telemetry or event replay system.
- No ranked mid-run resume across application restarts.
- No direct use of protected movie designs, costumes, music, branding, or later derivative depictions.
- No live remote content editor in the first release.

## 5. Assumptions and non-functional requirements

### Product assumptions

- A run always starts from the beginning; the account restores progression, not an interrupted run.
- Currency earned in the active campaign is at risk. Previously banked currency and completed purchases are permanent.
- Mastery XP and unique boss drops persist immediately, including after a later campaign defeat.
- "Immediately" means after server acceptance. Offline rewards remain provisional and unusable until synchronization.
- Store purchases are enabled only after completing all ten campaign levels; the catalog may be browsed earlier.
- The purchase phase and store entitlement are per character. A successful campaign opens that character's purchase phase; a later failure does not erase already banked funds or purchases.
- Standard mode normalizes all power and ignores purchased skills, power drops, and stat upgrades.
- Progression mode applies the complete character build.
- Losing one life is not campaign death. Campaign death occurs only when remaining lives reach zero.
- Mastery levels unlock a small fixed baseline progression track, so repeated failed campaigns can eventually make the first clear more achievable without spending currency.

### Performance

- Target 60 FPS with a 16.7 ms frame budget.
- No network, database, JSON serialization, or OAuth work runs in Flame's `update()` path.
- Boss assets are preloaded before the encounter and use atlases plus bounded projectile/particle pools.

### Scale and availability

- Initial scale is fewer than 1,000 active players.
- Global leaderboards expose the top 100 with pagination; personal history retains the latest 100 runs.
- Previously authenticated users can play cached content while offline. Ranked/economic offline play requires one already-issued stage token; otherwise play is practice-only.
- Network failures queue eligible mutations with exponential retry and idempotency keys.
- An account may have only one active campaign lease across devices. Starting a new online campaign explicitly abandons the previous lease.

### Security and privacy

- Supabase Auth supports email/password, Google, and Apple.
- PostgreSQL grants and RLS enforce least privilege on every exposed table.
- Service-role or secret keys exist only in trusted backend functions.
- Edge Functions validate run starts, finishes, rewards, drops, and purchases.
- Stored personal data is limited to email, public display name, provider identity, progression, inventory, and run results.
- Account deletion is available in-app and cascades through player-owned data.
- No analytics or third-party behavioral telemetry is collected.
- Functional run records used for progression, ranking, fraud checks, and support are not analytics telemetry and have explicit retention limits.
- Local caches are namespaced by user and wiped on logout/deletion. Credentials and economic tokens use the mandatory protected-store policy in Section 16; eligible offline progression fails closed when that protection is unavailable.

### Maintenance

- Schema changes are migration-driven and reviewable in the repository.
- Game catalogs are versioned with the application and identified by `content_version`.
- Supabase Dashboard may be used for infrastructure setup, but gameplay moderation is automatic.

## 6. Selected architecture

Use a modular monolith inside the Flutter application:

```text
UI and overlays
    -> application services
        -> pure domain models and policies
            -> local and remote repository interfaces
                -> local cache / Supabase Auth, Postgres, Edge Functions
```

### Presentation

- `AuthGate`
- account and deletion screens
- start and character-selection menus
- campaign map and boss tutorial overlays
- progression, loadout, skins, and store screens
- standard/progression leaderboards and personal history
- results, offline state, sync rejection, and campaign-complete screens

### Application services

- `AuthService`
- `CampaignService`
- `EconomyService`
- `ProgressionService`
- `LoadoutService`
- `LeaderboardService`
- `SyncCoordinator`

### Domain

- `PlayerProfile`
- `CharacterProgress`
- `CharacterStats`
- `SkillDefinition`
- `Loadout`
- `SkinDefinition`
- `CampaignRun`
- `LevelDefinition`
- `BossDefinition`
- `RewardDefinition`
- `RunResult`
- `LeaderboardEntry`

### Gameplay boundary

`DinoRunGame` receives one immutable `RunConfiguration` containing character, mode, normalized or upgraded stats, loadout, level, and content version. Gameplay emits domain events such as score changes, damage, boss phase changes, victory, and defeat. It does not import Supabase or perform persistence directly.

## 7. Server-authorized data flow and lifecycle

One campaign contains ten sequential stage attempts. A stage is one runner section plus its boss. The trust boundary is explicit:

1. Authenticate, synchronize, and acquire one account-wide campaign lease.
2. Create a `campaign_run` with character, mode, loadout, and `content_version`.
3. Before every level, request `start-stage`; receive a one-use stage token with sequence number and signed constraints.
4. Run the local deterministic stage and save a result with an idempotency key.
5. Submit `finish-stage` with terminal outcome `victory` or `defeat`. The server validates timing, score bounds, sequence, version, ownership, and rate limits.
6. An accepted victory atomically adds mastery XP, advances the campaign, records provisional run currency, and performs the boss-drop roll.
7. An accepted gameplay defeat atomically records the stage and cumulative failed-attempt result, grants its eligible mastery, clears provisional currency, marks the campaign failed, and publishes/updates the failed leaderboard row. Explicit quit, abandoned/expired lease, or rejected/tampered result also fails the campaign and clears provisional currency but is not globally ranked.
8. After ten accepted victories, `complete-campaign` banks provisional currency, opens the character's purchase phase, records completion, and writes the leaderboard result.

The server authorizes permanent mutations but does not claim to replay or prove gameplay. Plausibility checks mitigate ordinary tampering; they cannot eliminate a modified client. This limitation is accepted for the selected small-community threat model.

When online, the client may cache at most one six-hour, one-use token for the campaign's current expected stage. The next stage token is never issued until the preceding result is accepted. A stage begun offline without that token is practice-only. Results from cached tokens remain provisional until synchronization. Offline results never reveal or allow equipping a boss drop before server acceptance. Invalid/tampered submissions grant nothing; valid but unranked submissions may grant capped mastery only.

For concurrent devices, the server accepts only the first valid result for the campaign's expected stage sequence. A later result for the same sequence, an obsolete lease, or an abandoned campaign is rejected without rewards. Starting a new online campaign explicitly invalidates the previous lease and all of its unused tokens.

### Campaign and stage state machine

`campaign_runs` uses `active`, `completed`, `failed`, `abandoned`, and `expired`. Its current stage uses `token_issued`, `playing`, `finished_pending`, `accepted`, or `rejected`:

- `token_issued` may become `playing` locally without a server write.
- The client atomically seals a terminal result into its durable outbox before showing the result screen; that local state is `finished_pending` and is never resumable as gameplay.
- Suspending or terminating the process before a result is sealed cannot be distinguished reliably. The stage remains untrusted and the server moves the lease to `expired` after its deadline; the client sends a best-effort abandonment when it reconnects.
- Suspending or terminating after the result is sealed preserves the outbox item. Synchronization may still accept it before token/lease expiry; closure alone does not overwrite it as abandoned.
- A rejected, abandoned, or expired stage invalidates the campaign and any dependent local items. Because future-stage tokens are not pre-issued, there is no ambiguous rejection cascade.
- An accepted result advances the expected sequence. Only then may the client request the next stage token.

## 8. Supabase model

### Core tables

- `profiles`: user ID, public display name, timestamps.
- `character_progress`: user, character, mastery XP/level, banked character currency.
- `stat_upgrades`: user, character, stat ID, purchased rank.
- `skill_unlocks`: user, character, skill ID, source, acquired timestamp.
- `loadouts`: user, character, active skill and two passive skill IDs.
- `skin_unlocks`: user, character, skin ID, source, equipped state.
- `campaign_runs`: user, character, mode, state, current level, content version, signed timing data.
- `campaign_stages`: campaign, sequence, one-use token digest, outcome, idempotency key, verification class.
- `command_receipts`: user, command type, idempotency key, request digest, terminal status, and canonical response JSON.
- `run_results`: score, duration, level reached, defeat reason, verification state.
- `leaderboard_entries`: verified best score by user, character, and mode.
- `boss_progress`: victories and unique reward ownership.
- `premium_wallets`: schema-only future account-level premium balance, with no V6 product access.

### Server functions

- `start-campaign`
- `start-stage`
- `finish-stage`
- `fail-campaign`
- `complete-campaign`
- `purchase-upgrade`
- `purchase-skill`
- `purchase-skin`
- `equip-loadout`
- `delete-account`

The client cannot directly insert scores or update currency, purchases, drops, mastery, or entitlement rows.

`finish-stage` owns stage advancement, additive mastery XP, provisional currency, the boss roll, and accepted gameplay-defeat publication. `complete-campaign` only banks the accumulated provisional currency, grants the completion entitlement, and publishes the completed result. Each mutation has a unique idempotency constraint.

Edge Functions authenticate and validate the request envelope, then delegate every economic command to one PostgreSQL transaction/RPC. `apply_finish_stage`, `apply_complete_campaign`, and each purchase RPC lock the relevant `campaign_runs` and `character_progress` rows with `SELECT ... FOR UPDATE`, verify the expected state/version, apply all writes, and commit one `command_receipts` row. The receipt key is unique by user, command type, and idempotency key. An exact retry returns its stored canonical response; reuse with a different request digest is rejected. No Edge Function performs a chain of independent economic writes.

Every privileged endpoint validates the Supabase JWT and derives the user ID only from its verified `sub`, never from the request body. SQL functions use `SECURITY DEFINER` only where required, pin an empty or explicitly qualified safe `search_path`, qualify all objects, and revoke execution from `public`/`anon`. Account deletion and identity linking require authentication within the preceding five minutes. Service-role credentials remain only in backend secret storage and are never logged.

Stage tokens include issuer, `janosos-stage` audience, user ID, campaign ID, stage sequence, character, mode, loadout/config digest, `content_version`, `protocol_version`, nonce, issued/not-before/expiry times, and signing-key version. The server stores the one-use token digest. Tokens expire after six hours, are bound to one account and campaign, and cannot be transferred or replayed. Rotation retains verification material for the current and previous key until every issued token has expired.

Important invariants include one active campaign lease per account, one stage result per campaign sequence, one completion per campaign, one unique boss reward per user/character/reward, one best leaderboard row per user/character/mode/version, one equipped skin, one active skill, and at most two passive skills.

Required indexes include a partial unique active-campaign index per user; unique receipt/idempotency and stage-sequence indexes; a partial verified leaderboard index on `(character_id, mode, content_version, completed DESC, level_reached DESC, total_score DESC, duration_ms ASC, ended_at ASC, id ASC)`; and personal history on `(user_id, accepted_at DESC, id DESC)`. Migration tests use representative data and `EXPLAIN` to prove keyset queries use these indexes.

`premium_wallets` is a user-requested forward-compatibility exception. In V6 it permits no client read or write, has no grant, spend, purchase, or payment function, contains no seeded balances, and cannot affect gameplay. Activating it later requires a separate reviewed migration, payment-provider design, regional/privacy review, and store-compliance release. The table still participates in account-deletion cascades.

## 9. Progression and economy

Each character has 30 mastery levels, targeted at approximately 20–30 hours to complete. This is a balance target, not a guaranteed duration.

Mastery provides a small fixed baseline track at predetermined levels. The total automatic baseline is capped below the purchased progression ceiling and exists specifically to prevent a first-clear deadlock. Store tiers still require mastery, while currency purchases provide most build customization.

Five stat paths contain five ranks each:

- Speed: up to +10% attack cadence, boss movement, and recovery; it never accelerates the campaign world.
- Jump: up to +10% jump impulse.
- Damage: up to +50% against enemies and bosses.
- Vitality: at most one extra life; Parker may reach three total lives because of the innate ability.
- Fortune: up to +15% character currency earned.

The active campaign accumulates temporary character currency from score, duration, records, and bounded bonuses. Any defeat destroys that temporary currency. Completing level ten banks it and unlocks the purchase phase.

Accepted mastery always persists and unlocks store tiers. It also grants only the capped baseline track described above; it does not automatically purchase or equip store upgrades. Premium currency is modeled but hidden and unavailable.

Standard mode grants reduced mastery XP and personal/global Standard scores. It grants no temporary currency, boss drops, store purchase phase, or power progression. Progression mode owns the economy, campaign completion banking, and unique drops.

## 10. Skills, loadouts, and skins

- Each of the seven characters receives four exclusive purchasable skills: two active and two passive.
- Every character defines always-on `core_traits` and an optional `default_active`.
- Jano, Conra, and Nanic have a default active. Parker and Chema have innate defensive core traits. Shyno's double jump and Nakama's glide are traversal core traits.
- The active slot selects either `default_active` or one purchased active. Characters without a default active begin with an empty active slot until one is unlocked.
- Two passive slots accept purchased passive skills.
- Innate character identity remains active and does not consume a slot.
- Compatibility and ownership are validated on client and server.
- Initial skins are palette variants of existing sprite sheets.
- The asset model supports future paid sprite sheets without enabling payment code.

Standard mode replaces the complete build with the base character definition. Progression mode and Boss Rush use the equipped build.

With two purchased passive skills and two passive slots, V6 intentionally has no passive exclusion choice once both are owned; the meaningful initial loadout choice is between active skills. The UI must not claim otherwise.

## 11. Damage and lives

- Common obstacles have one to three resistance points where appropriate.
- Ranged or offensive abilities deal explicit damage rather than unconditional deletion.
- Characters without attack abilities can continue to evade common obstacles.
- Boss combat gives every character a boss-specific way to inflict damage.
- Bosses use phases and mechanics rather than excessive health inflation.
- Lives and damage are clamped by the selected progression limits.
- A hit consumes one life and applies a brief invulnerability window. Only depletion to zero emits campaign defeat and triggers reset.
- Every boss provides a basic encounter-specific damage action independent of purchased skills, so all base characters remain viable.

## 12. Campaign structure

- Ten sequential levels, approximately three minutes of runner gameplay each.
- One 45–90 second boss encounter follows each runner section.
- Full successful campaign target: 35–45 minutes.
- Any death during runner or boss gameplay resets campaign progress to level one.
- Permanent mastery, purchases, banked currency, and acquired unique drops remain.
- Completing the campaign unlocks Boss Rush.
- Boss Rush chains all bosses, offers partial healing between encounters, and uses a separate score that does not enter the primary campaign leaderboard.
- Closing or force-terminating the application before a terminal result is sealed, logging out with explicit discard, token/lease expiry, or starting another campaign abandons the active campaign and applies the same reset/loss rule. A sealed pending result may synchronize after restart, but gameplay itself never resumes mid-stage.
- Boss Rush grants reduced mastery and eligible 1% unique-drop rolls for defeated bosses, but no campaign currency or store purchase phase. Death ends the Boss Rush attempt.

## 13. Initial levels and bosses

| Level | Scenario | Boss | Signature mechanic | Unique drop (1%) |
|---|---|---|---|---|
| 1 | Sleepy Hollow | Headless Horseman | Side charges and spectral hazards | Spectral Trail |
| 2 | Court of Chaos | Queen of Hearts | Cards, moving platforms, size shifts | Card Aura |
| 3 | Chemical London | Mr. Hyde | Strength/speed shifts and shockwaves | Hyde Serum |
| 4 | Underground Opera | The Phantom | Darkness, echoes, sound-guided attacks | Phantom Mask |
| 5 | Winter Palace | Snow Queen | Slippery floor and ice projectiles | Frost Heart |
| 6 | Transylvanian Castle | Dracula | Bats, mist, teleportation, healing | Crimson Cape |
| 7 | Emerald Realm | Wicked Witch of the West | Flight, cyclones, toxic zones | Silver Shoes |
| 8 | Storm Laboratory | Frankenstein's Creature | Lightning, breakable armor, charges | Galvanic Core |
| 9 | Abyssal Harbor | Davy Jones | Tides, chains, tilting deck | Abyssal Compass |
| 10 | Clockwork London | Professor Moriarty | Traps, decoys, prior-mechanic combinations | Strategist Crown |

Every boss starts with a brief skippable control tutorial. Unique drops use pure 1% independent chance without pity. The roll happens only on the server in `finish-stage`, using an idempotent server-secret HMAC of campaign ID, stage sequence, user ID, and reward ID. Retrying the same stage cannot reroll. After ownership, that reward no longer rolls and duplicates grant nothing. Drops may be cosmetic or power-bearing; power drops work only in Progression and Boss Rush. An accepted drop survives later campaign defeat.

The campaign stores `drop_key_version` when the stage token is issued. The first accepted transaction persists the computed roll and grant in the stage plus command receipt; all retries return that outcome even during key rotation. Previous drop keys remain available only for the maximum token lifetime plus a bounded synchronization grace period. Secrets and raw HMAC material are redacted from logs.

No power-bearing drop may be required to clear the base campaign. Its effect is capped at the approximate value of one ordinary stat rank, cannot exceed global stat caps, and remains excluded from Standard mode. The long campaign, post-clear store, and pure 1% chance are deliberate product constraints; the simulator and playtest gates in Section 18 must reject balance that makes their combined grind coercive or a rare reward functionally mandatory.

All visuals are original pixel art derived only from old literary or folkloric source descriptions. Later film designs, trademark presentation, music, dialogue, and branding are excluded. IP/source clearance is a pre-production gate before names are frozen or boss art is generated, not a release-time afterthought. Any uncleared name is replaced before content production.

## 14. Leaderboards

- Global and personal views.
- Separate filter for each character.
- Separate Standard and Progression modes.
- Top 100 global entries with pagination.
- Last 100 personal runs.
- Boss Rush has a separate postgame score view and does not affect the main campaign leaderboard.
- Only server-verified results may be globally visible.
- Public rows expose display name, character, mode, score, duration, and timestamp only.
- A ranked row represents one accepted campaign attempt. Completed attempts are published by `complete-campaign`; failed attempts are published by the same transactional `finish-stage` call that accepts a terminal life-depletion defeat in either runner or boss gameplay. Quit, abandonment, expiry, and rejected/tampered submissions never enter the global board.
- The server maintains the attempt aggregate from accepted stage rows. `total_score` is their score sum, `duration_ms` is their signed active-play duration sum excluding allowed pauses, `level_reached` is the terminal sequence, and `ended_at` is the server acceptance time of defeat or completion.
- Stable ordering is: completion first, level reached descending, total score descending, duration ascending, `ended_at` ascending, entry ID ascending.
- Global results use keyset pagination in pages of 25 over the top 100.
- Personal history keeps the latest 100 accepted results; older functional run rows are deleted by a scheduled retention job after verification/audit retention expires.

## 15. Authentication and account lifecycle

- Email/password registration, verification, reset, and sign-in.
- Google and Apple sign-in.
- OAuth cancellation safely returns to `AuthGate`.
- Deep-link and redirect configuration is platform-specific.
- Previously authenticated sessions may open offline from cache.
- First-time registration requires connectivity.
- In-app account deletion calls a server function, revokes the account, and cascades all player-owned data.
- Provider accounts are never merged solely by matching email. A signed-in user explicitly links Google or Apple to the existing account. Hidden Apple relay emails remain valid identities. Collisions prompt sign-in with the existing provider before linking.
- Logout wipes that user's local tokens, cache, and pending mutations. Account switching uses a separate user namespace. A revoked session prevents synchronization and disables offline progression after a 24-hour cached-session grace period or sooner when revocation is observed.
- Public display names use a restricted length/character policy plus automatic profanity screening. Rejected names receive a neutral generated fallback and may be changed to another compliant name; no punitive account state depends on the filter.
- Names are re-screened when the moderation policy changes. A name later flagged is replaced by a neutral generated fallback automatically; the account and progression remain usable without manual intervention.

## 16. Offline and conflict handling

UI exposes five explicit result/sync states: practice/offline-ineligible, pending, synchronized, synchronized-with-limits, and rejected. `synchronized-with-limits` enumerates every accepted grant and every excluded grant/ranking with a plain-language reason; it is never presented as complete success.

- Local writes use stable idempotency keys.
- Server economic state is authoritative.
- Confirmed purchases are never rolled back by stale local data.
- Mastery XP is additive through unique accepted stage-result IDs; clients never submit a replacement mastery total.
- A content-version mismatch preserves eligible mastery but excludes the result from global ranking.
- Retries use exponential backoff and survive app restart.
- Network failures never interrupt gameplay.

The outbox is capped at 100 items or 10 MB and 30 days, whichever is reached first. Retry delay begins at two seconds, doubles to one hour, uses full jitter, and stops automatic retry after 20 failed attempts pending explicit user retry. Permanent rejections remain visible until acknowledged, then are deleted locally. Expired items become rejected and cannot silently award progress; the UI offers practice play while synchronization is blocked.

### Local security policy

- Android: Keystore-backed encrypted storage.
- iOS and macOS: Keychain with device-only accessibility.
- Windows: DPAPI scoped to the current OS user.
- Linux: Secret Service/libsecret for persisted credentials and economic outbox data.
- Web: IndexedDB encrypted with an origin-bound, non-extractable Web Crypto key, strict CSP, no dynamically loaded third-party scripts, and documented exposure to same-origin XSS.

Only session material, the current stage token, and sealed outbox items enter protected storage; catalogs and non-sensitive UI cache remain separate. If the required protected store is unavailable or locked, the session is memory-only and eligible offline progression is disabled. Practice play remains available. No platform falls back to plaintext credentials or economic tokens.

`content_version` identifies balance/assets/catalogs; `protocol_version` identifies the request and database contract. For each dimension, the server supports the current and immediately previous version for at least 90 days after its successor's release. Database changes use expand/migrate/contract: additive changes deploy first, both protocol handlers remain tested, and destructive contraction occurs only after the 90-day minimum plus a client-adoption gate.

The server never issues a stage token for an unsupported content/protocol pair. A token issued while both versions are supported retains its stated eligibility until its own six-hour expiry even if a 90-day window closes meanwhile. A sealed pending result gains no extra version grace: submission before token expiry may receive normal economy and writes only to its own content-version leaderboard; submission after expiry or with an unsupported pair may receive capped mastery only when plausibility checks pass, with no currency, drops, advancement, completion, or global publication. The outbox may retain that limited/rejected result for its normal 30-day UI and retry lifecycle.

Functional service data includes scores, durations, timestamps, verification state, and rejection codes. This is required game/account data, not analytics telemetry. Detailed rejection records expire after 30 days; retained leaderboard and personal-history rows follow their stated product limits.

Accepted non-best run results are retained for 180 days, with only the latest 100 exposed in personal history; verification detail and rejected results are retained 30 days; sanitized function logs are retained 14 days. Account deletion immediately revokes active sessions and queues deletion of Auth identities plus application rows, with a 24-hour live-system SLA. Encrypted backups age out within 30 days and are never used to selectively restore a deleted account; after disaster restore, deletion tombstones are reapplied before service reopens. A scheduled audit alerts if retention or deletion work is more than 24 hours late.

## 17. Player experience and accessibility contract

### Eligibility, interruption, and loss communication

Before every stage, a preflight card states one of: verified online, eligible offline for this stage only, or practice. It shows the current level, token expiry where applicable, rewards that may be earned, and whether results will remain pending. A valid in-progress stage does not silently become practice because connectivity disappears. The client refuses eligible offline start when the token lacks enough remaining lifetime for the maximum stage duration; later server restriction or rejection is shown explicitly in the result.

Minimizing, locking the screen, or receiving a call pauses locally while the process survives, subject to the signed pause budget and token lifetime. Resuming after the budget expires ends the stage as abandoned. Forced OS termination before a sealed result is not recoverable; a sealed `finished_pending` result remains synchronizable. Where the platform permits, back, window-close, quit, logout, delete-account, and start-another-campaign actions show a confirmation with level `X/10`, remaining lives, temporary currency, and pending results at risk. Logout offers synchronize now, cancel, or knowingly discard pending items. The app never claims it can intercept a force-kill.

All player-facing text uses “agotar todas las vidas” for campaign defeat. The map, pause screen, and stage result always show level `X/10`, lives, temporary currency “en riesgo,” and banked currency “guardada.” Defeat results have separate “Perdiste” and “Conservaste” groups for currency/progress lost versus accepted mastery, purchases, banked currency, skins, and drops retained.

### Economy, progression, and drop presentation

- Store and confirmation cards show the owning character, current/new value, rank cap, banked balance before/after, and modes where the item works.
- Starting Standard shows a concise confirmation that upgrades, purchased skills, and power drops are normalized for fairness; cosmetics remain visual only where allowed.
- Menus initially show the selected character's next available improvements. Advanced trees and the other characters are disclosed on demand; V6 never shows the inactive premium wallet or purchase affordances.
- Boss reward panels state the 1% chance, owning character, eligible modes, and already-owned status. “No drop” is a normal accepted outcome, visually separate from pending/rejected synchronization.

### Controls and encounter help

Every encounter publishes a `ControlLayout`: movement/jump, equipped active when present, and a visually distinct boss-action control. A character with no active skill has no inert gameplay button; the loadout screen labels the slot “Sin habilidad activa.” Boss actions never masquerade as equipped skills. Their touch, keyboard, and controller bindings appear before the fight and in pause/help. The skippable tutorial can always be reopened, and pausing exposes the current boss mechanic without abandoning the stage.

### Accessibility

- Critical warnings and boss attacks use at least two independent cues among shape/icon, position/motion, text, sound, and optional haptics; no mechanic depends only on sound or color. The Phantom's audio theme therefore includes a directional visual pulse and text/icon warning.
- Menus and overlays meet WCAG 2.2 AA contrast, preserve content at 200% text scaling, expose semantic names/roles/state/focus order, and support keyboard, controller, and touch without pointer-only actions.
- Settings include reduced motion, zero screen shake, high-contrast hazard cues, subtitles/captions, independent music/effects levels, and remappable gameplay controls. Essential information remains visible when haptics, audio, animation, or color differentiation is unavailable.
- Flashes stay below three per second. Reduced-motion mode replaces parallax, zoom, rapid size changes, and intense particles with static or opacity-safe cues without changing timing or difficulty.

### Existing-player migration and leaderboard clarity

The old device-wide `high_score` has no trustworthy character or verification metadata. On first upgrade it is preserved as “Récord local heredado,” never uploaded, never used for rewards, and never assigned to a character. Its explanation is shown once and remains available in local records until the player clears local data.

Global rows label completed/failed, level reached, character, Standard/Progression, competitive content version, score, duration, and validation timestamp. Personal history additionally shows pending, synchronized-with-limits, rejected, or globally ranked, with an actionable plain-language explanation. Pending local results stay in the personal activity view and never appear as missing without status.

### Account recovery matrix

| State | Player message and action |
|---|---|
| Email unverified | Explain that connectivity is required; resend with cooldown, change address, or sign out. |
| Password rejected | Retry, reveal/hide password, or open password reset without erasing the entered email. |
| OAuth cancelled/unavailable | Return safely to `AuthGate`; retry the provider or use another configured sign-in method. |
| Provider collision | Ask the player to authenticate with the existing provider, then link the new provider from account settings. |
| Recent authentication required | Preserve the safe UI context, reauthenticate, then retry the sensitive action; never interrupt active gameplay. |
| Session revoked/storage unavailable | Explain why eligible offline progress is disabled; offer sign-in retry or practice mode. |
| Account deletion | Show the destructive scope and 24-hour live-system SLA, require explicit confirmation, then show completion/pending/error state. |

Backend codes map to localized, actionable messages. Unknown errors show a retry path and a non-identifying correlation reference; raw SQL, provider, stack, or internal rejection text is never exposed.

Automatic display-name replacement triggers a neutral notification explaining the policy category and immediately offers the existing rename flow. It never implies misconduct or blocks progression.

## 18. Testing strategy

### Unit

- reward and currency loss rules
- mastery progression
- stat caps and prices
- loadout ownership and compatibility
- standard-mode normalization
- deterministic testing of 1% drops through injected RNG
- idempotency and conflict reconciliation

### Flame/component

- collision, damage, resistance, lives, and character abilities
- boss phases, tutorials, controls, victory, and defeat
- campaign reset and Boss Rush transitions
- equivalent control mappings, redundant boss cues, reduced-motion substitutions, flash limits, and boss-help reopening

### Widget

- authentication and cancellation
- character progression and loadouts
- store lock/unlock behavior
- leaderboard filters and pagination
- practice, pending, synchronized, synchronized-with-limits, and rejected states
- preflight eligibility, voluntary-loss confirmations, legacy-score labeling, account recovery, semantic focus, 200% text scaling, and contrast

### Supabase

- migrations and constraints
- RLS isolation and least privileges
- direct economy/score writes denied
- duplicate run completion denied
- implausible and rate-limited results rejected
- atomic purchases and campaign completion

### Platform matrix

- Full E2E: web, Android, Windows.
- Full release-gate journeys on all six platforms: authentication/deep links, one complete stage, persistence, offline queue, synchronization, leaderboard, deletion, keyboard/touch/controller equivalence where supported, screen-reader menu navigation, text scaling, and reduced-motion/non-audio boss cues. Web, Android, and Windows are automated first; iOS, macOS, and Linux may use documented manual E2E until automation is available, but smoke-only validation is insufficient for release.

### Balance and performance acceptance

- A deterministic economy simulator estimates median character completion between 20 and 30 hours and reports the 10th/90th percentile range.
- An internal playtest gate measures first-clear feasibility, abandonment, and whether any power drop becomes mandatory. Balance must be adjusted before release if the base campaign cannot be cleared without rare drops.
- The minimum performance matrix is: Pixel 4a for Android; iPhone SE 2nd generation for iOS; Intel i5-8250U/UHD 620/8 GB for Windows and Chrome web; the same x86 class with Ubuntu 24.04 LTS for Linux; and a 2018 Intel Mac mini/8 GB for macOS. A later equivalent device may replace one only if its measured CPU/GPU performance is no higher.
- Tests use profile builds, native mobile resolution, 1920x1080 desktop, and 1366x768 web. After a five-minute warm-up, each target runs three ten-minute level-ten scenes with the boss's maximum phase, full HUD, 128 projectiles, 512 particles, 96 hazards, and 256 visual effects available in fixed pools.
- Every repetition must keep at least 99% of frames at or below 16.7 ms, produce no frame over 50 ms after warm-up, and remain below 350 MB working set on mobile, 500 MB in the browser tab, and 600 MB on desktop. Pool overflow drops nonessential effects instead of allocating during the frame.

## 19. Operational readiness

Technical observability is permitted; behavioral analytics is not. Aggregated metrics contain no email, display name, raw user ID, score trail, or gameplay event stream. They include endpoint request/error counts, latency histograms, rejection-code counts, queue age, database/storage utilization, scheduled-job freshness, auth failures, and quota consumption. Sanitized logs use random correlation IDs, redact tokens/secrets/request bodies, and expire after 14 days.

Internal monthly SLOs are 99.5% availability for authentication and synchronization, 99.5% successful processing of valid economic commands, p95 server latency below two seconds, 95% of queued mutations resolved within five minutes after stable connectivity, and zero partial economic commits. Alerts fire on SLO burn, anomalous rejection rate, oldest outbox age, retention/deletion lateness, database saturation, and 50/75/90% quota thresholds.

The launch capacity envelope is 1,000 daily active users, three campaign attempts per user/day, and at most ten stages per attempt: approximately 66,000 start/finish/completion commands per day, 900,000 stage rows per month before retention, and at most 540,000 retained 180-day run summaries. Load acceptance is 25 requests/second for ten minutes and 100 requests/second for one minute without invariant failure or p95 latency above two seconds. Tables with time-based retention are partitioned monthly once their query plan or size crosses the measured threshold.

The initial infrastructure ceiling is USD 100/month. A pre-launch cost model must include Supabase compute/database/storage, Edge invocations, Auth email, backups, and scheduled jobs. Forecast above 80% of that ceiling triggers a plan/capacity review; launch cannot rely on an unverified free-tier quota. The display-name filter is a versioned server-side ruleset and bundled denylist, not an external moderation provider, so it adds no third-party data disclosure or runtime dependency.

Production requires daily encrypted backups with RPO at most 24 hours and RTO at most eight hours. A staging restore drill runs quarterly and before the first release. Migrations use expand/migrate/contract, create a verified backup before destructive steps, run inside a transaction where PostgreSQL permits, and include an explicit forward fix/rollback procedure. The selected Supabase plan must meet these requirements before production data is accepted.

## 20. Delivery sequence

1. Domain boundaries, local persistence, migrations, Supabase client, and authentication.
2. Run validation, Standard/Progression leaderboards, and personal history.
3. Mastery, economy, store, stat upgrades, loadouts, and palette skins.
4. Level-one vertical slice with the Headless Horseman.
5. Levels two through ten, all exclusive skills, unique drops, and Boss Rush.
6. Offline hardening, security tests, balance passes, and six-platform release validation.

Each phase must be playable and tested before the next content multiplier begins.

## 21. Decision log

| Decision | Alternatives considered | Rationale | Objections / resolution |
|---|---|---|---|
| Supabase cloud backend | Firebase; local profiles | Relational rankings/economy and integrated Auth/RLS/Functions | Retained; guarded by RLS and server functions |
| Email, Google, Apple auth | Email only; Google only | User selected broad cross-platform access | Retained; explicit linking and cache lifecycle added |
| Modular monolith | Remote-config-first; event replay | Small scale, offline needs, maintainability | Retained; gameplay/network boundary specified |
| Performance-based run currency | Collectibles; time only | Rewards skill and play duration | Retained; only Progression grants currency |
| Per-character currency/progression | Global; mixed | Strong individual character investment | Retained; campaign/store entitlement is per character |
| Hidden future premium wallet | Monetize now; omit schema | User explicitly requested future monetization preparation | Retained as an inert, inaccessible schema exception |
| Standard and Progression boards | One board; normalized only | Separates fairness from RPG investment | Retained; Standard economy exclusions specified |
| Global plus personal history | Global only; seasons | Supports competition and personal review | Retained; ordering, pagination, and retention specified |
| No mid-run restore | Unranked restore; ranked cloud restore | Simpler, safer validation | Retained; closure is explicit abandonment |
| Offline cached play | Practice only; online required | Reliability across target platforms | Retained with bounded signed stage tokens and provisional rewards |
| Plausibility validation | Trust client; event replay | Balanced security and complexity | Retained; security limitation and accepted threat model made explicit |
| All skills exclusive | Shared; hybrid | User prioritizes character uniqueness | Retained; existing abilities classified as core/default |
| Four new skills per character | Three; six | Enough active choice at manageable scope | Retained; V6 passive-choice limitation disclosed |
| One active and two passive slots | One extra; unlimited | Limits combinations and control load | Retained; only the active slot offers exclusion choice in V6 |
| Palette skins first | New sheets; mixed | Low asset weight and animation risk | Retained; paid sprite support is a future asset seam only |
| 20–30 hour character completion | 3–5; 8–12 | Long-term progression chosen by user | Retained as a measured target with simulator/playtest gates |
| Ten-level all-or-nothing campaign | Current-level retry; lives | High-stakes roguelite loop chosen by user | Retained; life depletion and abandonment semantics specified |
| Mastery persists on failure | Milestone bonuses; no progress | Prevents new-player progression deadlock | Retained with capped automatic baseline progression |
| Store after full completion | Between levels; after bosses | Maximum campaign tension chosen by user | Retained as permanent per-character entitlement after a clear |
| Pure 1% boss drops | Pity; increasing chance | High rarity chosen by user | Retained; server HMAC roll, idempotency, and duplicate behavior specified |
| Mixed cosmetic/power drops | Cosmetic only; power only | Variety; power isolated from Standard mode | Retained with power cap and non-required-clear gate |
| Boss Rush after clear | Level select; full campaign repeat | Dedicated farming/postgame loop | Retained; reward and failure behavior specified |
| Original pixel-art bosses | Placeholders; supplied art | Visual cohesion and IP control | Retained; source clearance moved before content production |
| Minimal personal data | Anonymous analytics; telemetry | Privacy choice from user | Retained; functional records distinguished and bounded by retention |
| Automated moderation | Dashboard workflows; custom panel | Small scale and no manual operations | Retained; neutral fallback avoids punitive false positives |
| Six-platform first release | Web/mobile; web first | User-selected reach | Retained; full release journeys required on every platform |

## 22. Skeptic review resolution log

The Skeptic returned `REVISE`. Every objection was addressed before requesting the next reviewer.

| ID | Severity | Resolution | Disposition |
|---|---|---|---|
| S1 | Blocking | Added a capped mastery baseline that advances after accepted failures and prevents a first-clear power deadlock. | Accepted |
| S2 | Blocking | Replaced the undefined offline run flow with bounded, signed, one-use cached stage tokens; tokenless play is practice-only. | Accepted |
| S3 | Blocking | Renamed the guarantee to server-authorized and documented that plausibility checks do not prove gameplay against a modified client. | Accepted risk |
| S4 | Blocking | Defined campaign, stage, runner/boss boundary, stage sequence, lease, abandonment, and completion lifecycle. | Accepted |
| S5 | Major | Assigned stage rewards to `finish-stage` and banking/publication to `complete-campaign`. | Accepted |
| S6 | Major | Made offline rewards provisional and unavailable until server acceptance. | Accepted |
| S7 | Major | Defined a deterministic, server-secret, idempotent HMAC drop roll in `finish-stage`. | Accepted |
| S8 | Major | Defined campaign death as depletion of all lives, not loss of one life. | Accepted |
| S9 | Major | Limited persistence promises to accepted results; rejected/tampered results grant nothing. | Accepted |
| S10 | Major | Added one account-wide lease, expected-sequence arbitration, and explicit invalidation of obsolete device tokens. | Accepted |
| S11 | Major | Replaced snapshot reconciliation with additive XP keyed by unique accepted stage-result IDs. | Accepted |
| S12 | Major | Defined permanent store entitlement as per character after that character's full clear. | Accepted |
| S13 | Major | Defined Standard as reduced mastery plus scores only, with no currency, drops, store, or power progression. | Accepted |
| S14 | Major | Defined completed versus accepted gameplay-defeat publishers, excluded non-gameplay failures, server aggregation, `ended_at`, and stable comparison order. | Accepted after arbiter revision |
| S15 | Major | Set current/previous content and protocol support to at least 90 days and defined token issuance, six-hour grandfathering, sealed-result expiry, economy, and ranking effects. | Accepted after arbiter revision |
| S16 | Major | Added protected, per-user cache namespaces and cleanup/revocation rules. | Accepted |
| S17 | Major | Added explicit provider linking and collision handling; email matching never auto-merges accounts. | Accepted |
| S18 | Major | Added restricted names, automatic screening, neutral fallback, and non-punitive re-screening. | Accepted |
| S19 | Major | Distinguished necessary functional records from prohibited analytics telemetry and added retention limits. | Accepted |
| S20 | Major | Required complete release-gate journeys on all six platforms; manual E2E is allowed where automation is unavailable. | Accepted |
| S21 | Major | Recast 20–30 hours as a measurable target and added simulator percentile plus playtest gates. | Accepted |
| S22 | Major | Added combined-grind rejection gates and bounded power drops that cannot be required to clear. | Accepted risk |
| S23 | Major | Defined Boss Rush mastery, drop, currency, store, death, and score behavior. | Accepted |
| S24 | Major | Mapped existing abilities into core traits/default active and guaranteed a boss damage action for all characters. | Accepted |
| S25 | Major | Moved source/name/IP clearance to a pre-production gate before names or art are frozen. | Accepted |
| S26 | Minor | Explicitly disclosed that V6 offers active choice but no passive exclusion once both passives are owned. | Accepted limitation |
| S27 | Minor | Defined owned unique drops as ineligible for future rolls, with no duplicate compensation. | Accepted |
| S28 | Minor | Added keyset pagination, page size, stable order, and deterministic tie-breakers. | Accepted |
| S29 | Minor | Defined the last-100 personal history view and scheduled deletion of older rows after audit retention. | Accepted |
| S30 | Minor | Listed uniqueness and cardinality invariants for campaigns, results, drops, boards, skins, and slots. | Accepted |
| S31 | Minor | Added exact hardware/resolution/build/scene repetitions, 99th-percentile frame acceptance, long-frame limits, memory ceilings, and pool bounds. | Accepted |
| S32 | Minor | Retained the premium table because future monetization preparation is user-locked; isolated it with no V6 access or behavior and a mandatory future review. | Rejected removal; constrained exception |

## 23. Constraint Guardian review resolution log

The Constraint Guardian returned `REVISE`. Every constraint objection was incorporated before requesting user-experience review.

| ID | Severity | Resolution | Disposition |
|---|---|---|---|
| CG-B1 | Blocking | Routed each economic command through one locking PostgreSQL transaction with request digests and persistent canonical receipts. | Accepted |
| CG-B2 | Blocking | Defined observable campaign/stage states, sealed pending results, lease expiry, and issuance of only the current stage token. | Accepted |
| CG-M1 | Major | Added JWT-derived identity, recent-auth requirements, safe `SECURITY DEFINER` policy, grants, and secret handling. | Accepted |
| CG-M2 | Major | Specified every token claim, six-hour expiry, digest, account/campaign binding, one-use semantics, and rotation window. | Accepted |
| CG-M3 | Major | Defined protected storage and fail-closed behavior separately for all six platforms, including the web threat limitation. | Accepted |
| CG-M4 | Major | Added exact live-data/log/backup retention, deletion SLA, tombstones, and overdue-job alerts. | Accepted |
| CG-M5 | Major | Separated content/protocol versions; both keep current/previous for at least 90 days, with exact token, sealed-result, expiry, and deployment behavior. | Accepted after arbiter revision |
| CG-M6 | Major | Added privacy-preserving technical metrics, SLOs, redacted logs, and operational alerts without behavioral analytics. | Accepted |
| CG-M7 | Major | Added an exact hardware/resolution/scene/build matrix, three repetitions, p99 frame threshold, long-frame bound, memory ceilings, and pool limits. | Accepted |
| CG-M8 | Major | Added workload envelope, load test, USD 100 monthly ceiling, quota alarms, RPO/RTO, restore drills, migration recovery, and a local-only name filter. | Accepted |
| CG-m1 | Minor | Added concrete partial/compound indexes and migration query-plan tests. | Accepted |
| CG-m2 | Minor | Bounded outbox size, age, attempts, delay, jitter, expiry, rejection visibility, and user retry. | Accepted |
| CG-m3 | Minor | Versioned the drop key, persisted the first outcome transactionally, retained old keys for the bounded grace period, and redacted HMAC material. | Accepted |

## 24. User Advocate review resolution log

The User Advocate returned `REVISE`. Every player-facing objection was incorporated before arbitration.

| ID | Severity | Resolution | Disposition |
|---|---|---|---|
| UA-B1 | Blocking | Added redundant critical cues, WCAG 2.2 AA menu/overlay rules, 200% text, semantic focus, flash/motion controls, equivalent inputs, and six-platform accessibility journeys. | Accepted |
| UA-M1 | Major | Added `synchronized-with-limits` with an itemized accepted/excluded result rather than a false complete-success state. | Accepted |
| UA-M2 | Major | Added mandatory preflight eligibility and prohibited silent downgrade after a valid stage starts. | Accepted |
| UA-M3 | Major | Defined suspension, pause budget, force termination, sealed pending results, voluntary-loss confirmations, and logout choices. | Accepted |
| UA-M4 | Major | Defined at-risk/banked currency presentation, purchase preview, ownership, mode applicability, and Standard normalization notice. | Accepted |
| UA-M5 | Major | Preserved the old score as private, unattributed, unverified “Récord local heredado” without upload or rewards. | Accepted |
| UA-M6 | Major | Added explicit completed/verified-defeat publication, excluded failure types, aggregate fields/timestamp, row semantics, and visible pending/limited/rejected explanations. | Accepted after arbiter revision |
| UA-M7 | Major | Added an actionable account-state recovery matrix and localized/redacted error contract. | Accepted |
| UA-M8 | Major | Added per-encounter control layouts, no inert active button, a distinct boss action, and replayable help. | Accepted |
| UA-M9 | Major | Standardized “agotar todas las vidas” and added persistent `X/10`, lives, risk, lost, and retained summaries. | Accepted |
| UA-m1 | Minor | Added visible 1% chance, ownership/mode/owned status, and normal “no drop” presentation. | Accepted |
| UA-m2 | Minor | Added progressive disclosure around the selected character and hid premium affordances in V6. | Accepted |
| UA-m3 | Minor | Added neutral notification and immediate rename action after automatic name replacement. | Accepted |

## 25. Arbitration log

Round 1 disposition: `REVISE`.

- Accepted: S1–S13, S16–S32; CG-B1, CG-B2, CG-M1–M4, CG-M6–M8, CG-m1–m3; UA-B1, UA-M1–M5, UA-M7–M9, UA-m1–m3.
- Rejected pending correction: S14/UA-M6 because failed leaderboard publication was not owned by a function; S15/CG-M5 because `content_version` lacked an exact support window.
- Primary Designer response: `finish-stage` now owns accepted gameplay-defeat aggregation/publication with precise eligibility, aggregate fields, and `ended_at`; content and protocol versions now both support current/previous for at least 90 days with exact token and pending-result expiry behavior.

Round 2 disposition: `REVISE`.

- Accepted: S15 and CG-M5.
- Rejected pending correction: S14 and UA-M6 because the required leaderboard index still named legacy `score`/`completed_at` fields instead of the canonical `total_score`/`ended_at` keyset fields.
- Primary Designer response: the compound verified-leaderboard index now exactly matches the canonical filter, ordering, and tie-break fields.

Round 3 disposition: `APPROVED`.

- Accepted: S14 and UA-M6. Failed-attempt ownership, aggregation, canonical ordering, and the compound keyset index now use the same fields.
- Final arbiter disposition: all registered Skeptic, Constraint Guardian, and User Advocate objections are resolved or explicitly accepted as constrained product risks.

## 26. Remaining accepted risks

- Twenty-eight exclusive skills and ten bespoke bosses create a large content and balance surface.
- Pure 1% power drops may create severe grind and progression inequality.
- A 35–45 minute all-or-nothing run may increase abandonment.
- Offline economy validation without event replay cannot eliminate sophisticated cheating.
- Google/Apple OAuth behavior differs across six platforms.
- Exact public-domain source eligibility varies by market and still requires documented pre-production clearance.
- Automated moderation without an operational override can create unrecoverable false positives.

## 27. Primary references

- Supabase Flutter quickstart: <https://supabase.com/docs/guides/getting-started/quickstarts/flutter>
- Supabase Row Level Security: <https://supabase.com/docs/guides/database/postgres/row-level-security>
- Supabase data security: <https://supabase.com/docs/guides/database/secure-data>
- Supabase Edge Function authentication: <https://supabase.com/docs/guides/functions/auth>
- Supabase Google login: <https://supabase.com/docs/guides/auth/social-login/auth-google>
- Supabase native Google/Apple ID tokens: <https://supabase.com/docs/reference/dart/auth-signinwithidtoken>
- U.S. Copyright Office, derivative works: <https://www.copyright.gov/circs/circ14.pdf>
- U.S. Copyright Office, copyright lifecycle: <https://copyright.gov/history/copyright-exhibit/lifecycle/>
