# Roth Minimap agent guide

## Contract

Target Retail 12.1.5 / Interface `120105`. Addon version `0.4.5`, schema `7`, reviewed Blizzard live source `12.1.5.70783` at `Gethe/wow-ui-source@297d7aaaa736f346b3e036f38ee088eaf7f8c07f`.

Blizzard/Edit Mode owns `MinimapCluster`, native input, native widget topology, Hybrid Minimap, housing overlays, and third-party buttons. Roth Minimap owns only its DB, deterministic Minimap mask policy, exact decorative-alpha mutations, and addon-created skin/ping/reset objects.

## Never restore

```text
ButtonBag or generic minimap-button collector
frame-tree discovery
foreign SetParent / SetPoint / ClearAllPoints
foreign method replacement
native Minimap/MinimapCluster geometry ownership
MinimapBackdrop alpha/visibility mutation
raw RegisterEvent for CallbackEvent MINIMAP_PING
MINIMAP_PING payload inspection
second wheel zoom step
EnableMouseWheel ownership
recursive or uncancellable timers
foreign HybridMinimap mask mutation
foreign housing overlay mutation
hard-coded addon-folder media paths
```

## Media root

Build bundled texture paths from the `ADDON_NAME` supplied through `...`. Do not assume the installation folder is exactly `RothMinimap`; GitHub archives and manual installs may rename it.

## Native fallback

`C_Minimap.ShouldUseHybridMinimap()` and `C_Housing.IsInsideHouse()` are read-only mode gates. When either is true:

- use the known native default mask;
- restore addon-owned decorative-alpha changes;
- hide only addon-created skin regions;
- do not inspect or mutate HybridMinimap/MapCanvas masks or housing descendants.

The cached mode is refreshed by full applies, including `PLAYER_ENTERING_WORLD` and `UI_SCALE_CHANGED`.

## Decorative alpha

Retain an alpha snapshot until restoration succeeds or another owner has already replaced the hidden value. If `GetAlpha()` is temporarily inaccessible, return failure and keep the snapshot for a later full apply. Never guess an alpha or clear state merely because a read failed.

## Ping

`MINIMAP_PING` is `CallbackEvent = true`, `SecretPayloads = true`. Register it with `Frame:RegisterEventCallback`; unregister with `Frame:UnregisterEventCallback`. Callback code must ignore every payload argument and call only fixed ordinary presentation.

Module return values and errors are ordinary-only. Gate a returned value before comparison, and never `tostring` an inaccessible error object.

## Persistence

`## LoadSavedVariablesFirst: 1` allows one file-scope migration before Settings registration. Preserve the root and nested Settings tables on reset. Existing valid user colors/alpha/cadence values remain unchanged. Schema 7 maps the old unified `fireFPS` to a 2-FPS-capped idle cadence and preserves it as the combat cadence.

## Lifecycle and performance

One visible-only fire ticker with separate idle/combat cadence, one zoom timer, and one coalesced refresh timer maximum. A direct full apply supersedes and cancels queued refresh work, including combat-deferred transitions. No `OnUpdate`, polling, tree scans, per-event timer fan-out, or retry loops.

## Verification

```text
texlua tests/test_syntax.lua
texlua tests/test_contracts_12_1_5.lua
texlua tests/test_runtime_stubs.lua
python3 tests/test_media.py
```

Do not use one `texlua --luaconly` invocation with several paths: Lua compilers treat later paths as script arguments rather than compiling every file. `test_syntax.lua` calls `loadfile` for each Lua file explicitly. GitHub Actions runs all four gates.

Do not label source/offline checks as live runtime PASS.
