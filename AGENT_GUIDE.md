# Roth Minimap agent guide

## Target

Addon `0.4.2` · Retail 12.1.5 · Interface `120105` · selected Blizzard source `12.1.5.70688`. Source review and offline stubs do not imply a live-client PASS.

## Ownership

Blizzard/Edit Mode owns `MinimapCluster` geometry, native input, child widgets, and third-party buttons. Roth Minimap owns only:

- schema-6 SavedVariables;
- the deterministic square/default mask policy;
- alpha of the exact decorative allowlist;
- addon-created skin, ping, and zoom-reset objects.

Never restore ButtonBag, frame-tree discovery, foreign reparent/reanchor/method replacement, native geometry ownership, `MinimapBackdrop` mutation, secret ping inspection, a second wheel step, or `EnableMouseWheel` ownership.

## Files

- `RothMinimap.lua`: migration, access gates, exact art/mask application, coalesced lifecycle refresh, in-place reset, slash commands.
- `modules/Skin.lua`: additive art and bounded visible-only animation.
- `modules/Ping.lua`: direct `MINIMAP_PING` owner; tuple discarded at the event boundary.
- `modules/Zoom.lua`: native-wheel observer and one reset timer.
- `Options.lua`: one session-lifetime Settings category.
- `tests/test_contracts_12_1_5.lua`: static ownership regression.
- `tests/runtime_stubs_env.lua`: compact WoW/Settings/timer test environment.
- `tests/test_runtime_stubs.lua`: offline behavior regression.

There is no generic addon-local event bus. Each feature owns its native event frame so raw or secret-capable tuples never pass through a shared dispatcher.

## Persistence

The TOC uses `## LoadSavedVariablesFirst: 1`. Migration runs once before Settings registration.

Schema 6 must preserve supported pre-0.4 preferences from:

```text
square / hideBlizzardArt / skinEnabled
visual.border / visual.runes / visual.vignette
fire
ping
zoom
```

Do not replace `ns.db`, `ns.db.skin`, `ns.db.ping`, or `ns.db.zoom` after Settings registration. Reset them recursively in place. Suppress Settings callbacks while broadcasting `Settings.NotifyUpdate`, because `NotifyUpdate` triggers value-changed callbacks.

## Geometry and draw order

Never store/apply native minimap position or size. Edit Mode refreshes addon-owned dimensions; world-entry and UI-scale signals coalesce a full mask/art/module revalidation.

If width/height/strata/level are inaccessible, skip the update or retain the last ordinary geometry. Do not guess.

The skin frame follows the native Minimap strata and frame level. Never force `HIGH`/large frame levels that can cover native child controls. Addon-owned regions are noninteractive.

## Decorative art

Allowlist only:

```text
MinimapCompassTexture
MinimapCluster.BorderTop
```

Snapshot an accessible ordinary alpha before mutation. On later apply, preserve the latest ordinary alpha before hiding again. Restore only while the current alpha still matches the addon-applied hidden value. Never mutate `MinimapBackdrop`.

## Ping

The direct event callback must ignore every `MINIMAP_PING` argument. It may emit fixed ordinary text or trigger addon-owned animation only. No name lookup, coordinate access, keying, logging, persistence, closure capture, or timer handoff.

## Zoom

Blizzard performs the native wheel step. The addon hook observes the completed state and schedules/cancels one reset timer. Validate `GetZoomLevels() - 1`; never hard-code the ceiling or mutate native wheel enablement.

Cancel reset work on disable, native hide, combat entry, and world transition. An unrelated settings apply must not cancel a valid pending reset.

## Performance

Allowed repeating work: one fire ticker, 1–20 FPS, only while effectively visible. Geometry invalidations coalesce into one zero-delay timer. Zoom owns at most one timer. No `OnUpdate`, polling, recursive retry, child-tree scan, or per-event snapshot allocation.

## Verification

```text
texlua --luaconly RothMinimap.lua Options.lua modules/Skin.lua modules/Ping.lua modules/Zoom.lua tests/test_contracts_12_1_5.lua tests/runtime_stubs_env.lua tests/test_runtime_stubs.lua
texlua tests/test_contracts_12_1_5.lua
texlua tests/test_runtime_stubs.lua
```

Live gates remain NOT-RUN until recorded with client build, addon commit/configuration, steps, output, and taint/error capture.
