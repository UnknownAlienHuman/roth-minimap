# Roth Minimap agent guide

## Contract

Target Retail 12.1.5 / Interface `120105`. Selected Blizzard source baseline: `12.1.5.70688`; named-client runtime validation is not implied.

Blizzard Edit Mode owns `MinimapCluster` position, size, settings, native input, and child widgets. Roth Minimap may change only its own schema-v5 DB, the Minimap mask, alpha of the exact decorative allowlist, and addon-created skin/ping/reset objects.

## Never restore

```text
ButtonBag or generic minimap-button collector
foreign SetParent / SetPoint / ClearAllPoints
foreign method replacement or SetPoint blockers
GetChildren / GetNumChildren / EnumerateFrames discovery
clock/calendar/tracking/difficulty/compartment reanchor
MinimapCluster or Minimap geometry ownership
MinimapBackdrop alpha/visibility mutation
MINIMAP_PING payload inspection or UnitName lookup
second wheel zoom step
EnableMouseWheel ownership
recursive or uncancellable zoom timers
```

Use the Blizzard Addon Compartment metadata entry already declared in the TOC.

## Files

- `RothMinimap.lua`: schema v5, access/object gates, event routing, deterministic mask policy, exact decorative alpha restore, coalesced Edit Mode refresh, isolated module apply, in-place reset, slash commands.
- `modules/Skin.lua`: addon-owned border/runes/fire/pulse/vignette; effective-visibility ticker lifecycle.
- `modules/Ping.lua`: pre-created fixed-text notification; full payload opacity.
- `modules/Zoom.lua`: observes Blizzard's completed wheel step and owns one cancellable reset timer only.
- `Options.lua`: one session-lifetime vertical Settings category and reset notifications.
- `tests/test_contracts_12_1_5.lua`: static ownership/lifecycle regression.
- `tests/test_runtime_stubs.lua`: offline migration/reset/art/zoom behavior regression.

## Persistence

The TOC uses `## LoadSavedVariablesFirst: 1`; file-scope migration is therefore deliberate. Migrate and sanitize exactly once before Settings registration.

Do not replace `ns.db`, `ns.db.skin`, `ns.db.ping`, or `ns.db.zoom` after Settings registration. Reset recursively in place, preserving those identities, then call `Settings.NotifyUpdate` for registered variables.

## Geometry and visibility

Do not store or apply native minimap position/size. Addon art is parented/anchored to `Minimap` and refreshes only its own dimensions after coalesced Edit Mode callbacks, world entry, or UI-scale changes.

If width/height are inaccessible or invalid, retain the last valid ordinary geometry or keep the skin hidden. Do not invent a fallback size.

## Decorative art

The allowlist is intentionally limited to:

```text
MinimapCompassTexture
MinimapCluster.BorderTop
```

Snapshot accessible ordinary alpha before first mutation and restore that exact value when the option/addon is disabled. Never include `MinimapBackdrop`: selected source places housing and expansion controls inside it.

## Combat

Core apply and first structural creation defer in combat. A pending apply is attempted once on `PLAYER_REGEN_ENABLED`. Zoom reset is cancelled on combat entry and is not retried. Addon-owned fire alpha may update from cached ordinary settings; no protected/foreign mutation is attempted.

## Ping

Treat every `MINIMAP_PING` argument as secret and borrowed. Ignore the tuple completely. Do not name the sender, inspect coordinates, compare/key/log/persist values, or pass them into timers. Do not duplicate Blizzard's native ping sound.

## Zoom

Selected native `MinimapMixin:OnMouseWheel` already calls zoom in/out. The addon hook runs after that native operation and may only schedule/cancel the reset. One wheel notch must remain exactly one native step.

Never enable/disable native wheel input, hard-code maximum zoom, or implement the step again. Validate the accessible native range through `GetZoomLevels()` before reset mutation.

## Performance

The only repeating work is the fire ticker, bounded 1–20 FPS and absent while effectively hidden. Geometry bursts coalesce into one zero-delay cancellable timer. Zoom owns at most one cancellable timer. No `OnUpdate`, frame-tree scan, recursive retry, permanent profiler wrapper, or button collection.

## Verification

```text
texlua --luaconly RothMinimap.lua Options.lua modules/Skin.lua modules/Ping.lua modules/Zoom.lua tests/test_contracts_12_1_5.lua tests/test_runtime_stubs.lua
texlua tests/test_contracts_12_1_5.lua
texlua tests/test_runtime_stubs.lua
```

Live gates remain: actual build/Interface, Edit Mode movement/resize/profile changes, native hide/show and game-rule transitions, housing and expansion alerts, mask policy, atlas rendering, ping, zoom, combat, Settings/reset, reload/logout migration, taint/errors, and measured CPU/allocation behavior.
