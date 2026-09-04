# Janosos V6 Research

## Overview

Janosos V6 expands the existing Flutter/Flame runner with accounts, verified leaderboards, per-character RPG progression, a ten-level campaign, bosses, rare rewards, offline handling, and future monetization preparation.

## Canonical research and design

The complete user-validated and peer-approved research/design is maintained at:

- `docs/designs/2026-08-31-rpg-progression-campaign-supabase.md`
- `graphify-out/GRAPH_REPORT.md`
- `graphify-out/graph.html`

Those documents define the selected architecture, product decisions, rejected alternatives, data/security model, accessibility contract, review resolutions, and primary references. They are canonical; this file exists to connect the `build` workflow without duplicating decisions.

## Current implementation focus

Phase 0 and Phase 1 only:

- establish a truthful Flutter baseline;
- replace the stale test;
- extract character/game domain contracts;
- make Flame consume immutable run configuration and emit gameplay events;
- preserve all seven existing character behaviors;
- keep persistence and networking out of the Flame update path.

