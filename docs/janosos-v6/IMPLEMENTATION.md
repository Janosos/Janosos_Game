# Janosos V6 Implementation Plan

## Overview

The canonical detailed implementation plan is:

- `docs/plans/2026-08-31-v6-implementation-plan.md`

This tracker mirrors its phase boundaries for the `build` workflow.

## Prerequisites

- Flutter/Dart toolchain
- Clean baseline analysis and tests
- Approved V6 design
- Generated Graphify project map

## Phase summary

0. Toolchain, baseline, and safety rails.
1. Gameplay boundary with V5 behavior parity.
3. App shell, local database, and authentication.
4. Server-authorized campaign primitives and leaderboards.
5. Mastery, economy, store, loadouts, and palette skins.
6. Level-one vertical slice.
7. Levels 2–10 and Boss Rush.
8. Hardening and six-platform release.

## Current execution: phase 8 hardening and release

### Objective

Harden privacy/operations, prove distributable local builds, and leave every
external release prerequisite explicit and reproducible.

### Tasks

- [x] Enforce current/previous client compatibility and rank eligibility.
- [x] Bound personal history to a server-owned last-100 RPC.
- [x] Add 14/30/180-day retention, deletion SLA audit, sanitized logs, cron,
  and tombstone replay.
- [x] Add authenticated load tooling and pass the full local 25/100-rps gates.
- [x] Add CSP, Supabase production defines, Pages deployment, SQL/Deno CI, and
  secret-free native signing seams.
- [x] Add persistent audio/reduced-motion controls and system motion fallback.
- [x] Add account-scoped local campaign/economy/store/Boss Rush parity and a
  real Windows application journey for the credential-free release.
- [x] Build a Windows release after installing the documented ATL dependency.
- [x] Add setup, migration, privacy, deletion, backup, SLO, Apple rotation, and
  release runbooks.
- [ ] Run the full-duration load and managed backup restore drill in staging.
- [ ] Complete signed-device journeys on all six target platforms.
- [ ] Configure production Supabase/OAuth/signing/legal prerequisites.

### Success criteria

- Local automated gates and Windows/Web release builds pass.
- Retention, bounded history, deletion replay, and compatibility are pgTAP
  enforced.
- No release is labeled production-ready without external staging, signing,
  hardware, OAuth, backup, and legal evidence.

## Phase 6 — Ten-level campaign and Boss Rush

**Status:** Automated gate complete; signed-device playtesting pending

### Delivered

- Ten deterministic three-minute runner stages with distinct public-domain
  bosses, warning profiles, health curves, mechanics, and fixed 1% rewards.
- Server-authorized continuation from `expected_sequence` 1 through 10,
  automatic banking and store entitlement after the final victory, and reset
  semantics that preserve only permanent progress.
- Runtime contracts for every equipped active/passive exclusive skill without
  making purchases or rare drops necessary to clear a boss.
- Post-campaign Boss Rush chaining all ten bosses, healing one life between
  encounters, granting reduced mastery and eligible unique drops, granting no
  campaign currency, and publishing only to the `boss_rush` ranking partition.
- AES-GCM outbox sealing for campaign completion, Boss Rush results, and
  abandonment; retries use stable idempotency keys and canonical responses.

### Automated evidence

- Flutter analysis: zero issues.
- Flutter tests: 101 passing, plus the Windows local application journey.
- Release web build: passing, including the WASM dry run.
- PostgreSQL reset: all 14 migrations apply from an empty database.
- pgTAP: 178 passing tests across auth, RLS, campaign, economy, drops, and
  Boss Rush.
- Authenticated HTTP E2E: all ten campaign stages complete, 1,550 mastery XP
  persists, 1,000 temporary currency banks, and Boss Rush unlocks.
- Authenticated Boss Rush E2E: three defeated bosses grant 60 mastery XP,
  zero currency, one isolated ranking result, and a canonical retry.
- Local parity: all seven characters clear levels 1–10 independently; defeat,
  purchases, account isolation, active-run freezes, Boss Rush, deletion, and
  crash-safe one-time banking are covered.

### Remaining release verification

- Complete signed-device playthroughs and control/accessibility checks on all
  six target platforms.
- Configure production Supabase secrets/provider credentials and repeat E2E in
  a non-local project before release.
