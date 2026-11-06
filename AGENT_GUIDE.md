# Roth Minimap agent guide

## Contract

Target Retail 12.1.5 / Interface `120105`. Addon version `0.4.3`, schema `6`, selected Blizzard source `12.1.5.70688`.

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
```

## Native fallback

`C_Minimap.ShouldUseHybridMinimap()` and `C_Housing.IsInsideHouse()` are read-only mode gates. When either is true:

- use the known native default mask;
- restore addon-owned decorative-alpha changes;
- hide only addon-created skin regions;
- do not inspect or mutate HybridMinimap/MapCanvas masks or housing descendants.

The cached mode is refreshed by full applies, including `PLAYER_ENTERING_WORLD` and `UI_SCALE_CHANGED`.

## Ping

`MINIMAP_PING` is `CallbackEvent = true`, `SecretPayloads = true`. Register it with `Frame:RegisterEventCallback`; unregister with `Frame:UnregisterEventCallback`. Callback code must accept no payload use and call only fixed ordinary presentation.

## Persistence

`## LoadSavedVariablesFirst: 1` allows one file-scope migration before Settings registration. Preserve the root and nested Settings tables on reset. Existing valid user colors/alpha values remain unchanged; tuned defaults affect new/reset databases only.

## Performance

One visible-only fire ticker, one zoom timer, and one coalesced refresh timer maximum. No `OnUpdate`, polling, tree scans, per-event timer fan-out, or retry loops.

## Verification

```text
texlua --luaconly RothMinimap.lua Options.lua modules/Skin.lua modules/Ping.lua modules/Zoom.lua tests/test_contracts_12_1_5.lua tests/runtime_stubs_env.lua tests/test_runtime_stubs.lua
texlua tests/test_contracts_12_1_5.lua
texlua tests/test_runtime_stubs.lua
```

Do not label source/offline checks as live runtime PASS.
