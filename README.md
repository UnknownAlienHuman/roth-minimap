# Roth Minimap

Additive minimap presentation for World of Warcraft Retail 12.1.5.

Roth Minimap provides a square mask, Diablo-themed addon-owned art, a fixed opaque ping notification, and an optional reset after Blizzard's native wheel zoom. Blizzard remains the sole owner of `MinimapCluster` geometry, native widgets, input, and third-party minimap buttons.

## Compatibility

- Retail / Midnight 12.1.5
- Interface `120105`
- Addon version `0.4.2`
- SavedVariables schema `6`
- Source-reviewed Blizzard baseline `12.1.5.70688`
- In-client runtime matrix: **NOT-RUN**
- External dependencies: none

## Ownership boundary

Use Blizzard **Edit Mode** to position and size the minimap. The addon does not persist or replace Minimap/MinimapCluster points, parent, size, scale, scripts, state drivers, or child-widget layout.

It does not scan frame trees, collect minimap buttons, reparent foreign controls, or replace their methods. Clock, calendar, tracking, difficulty, mail, alerts, Addon Compartment, and third-party buttons remain native.

The optional Blizzard-art toggle changes alpha only on two selected-source decorative regions:

- `MinimapCompassTexture`;
- `MinimapCluster.BorderTop`.

`MinimapBackdrop` is deliberately untouched because it contains the housing overlay and expansion landing-page controls. Alpha restoration uses an ordinary snapshot and does not overwrite a newer foreign value.

## Skin and animation

The border, runes, fire, pulse, and vignette are addon-owned and noninteractive. The outer skin follows the native minimap's frame strata/level instead of forcing itself above Blizzard widgets.

The fire atlas ticker:

- is bounded to 1–20 FPS;
- exists only while the skin and minimap are effectively visible;
- is cancelled on hide or disable;
- is not recreated when the interval is unchanged.

If native geometry is inaccessible, the addon retains the last valid ordinary geometry or keeps the skin hidden. It never invents fallback dimensions.

## Ping

`MINIMAP_PING` is registered directly by the ping module. Its event tuple is discarded at the native event boundary; no unit token or coordinate is read, compared, formatted, logged, persisted, or deferred.

The notification contains only fixed ordinary text: `Map ping received`. Destination is configurable as a toast or chat message. Blizzard keeps native ping-sound ownership.

## Zoom

Blizzard's `MinimapMixin:OnMouseWheel` performs the only zoom step. Roth Minimap post-hooks it only to schedule one cancellable reset to level `0`.

The addon does not call `EnableMouseWheel`, does not perform a second step, and derives the valid range from `GetZoomLevels()`. Pending reset work is cancelled on disable, combat entry, native hide, and world transition.

## Persistence

`## LoadSavedVariablesFirst: 1` makes file-scope migration explicit. Schema 6 includes a real migration from the pre-0.4 schema (`square`, `skinEnabled`, `visual`, `fire`, legacy ping/zoom fields) instead of silently replacing those preferences with new defaults.

`/rmmap reset` rewrites the root and registered nested tables in place, performs one runtime apply, then refreshes Settings without recursively reapplying the addon for every control.

## Commands

```text
/rmmap
/rmmap config
/rmmap toggle
/rmmap reset
/rmmap status
```

## Verification

```text
texlua --luaconly RothMinimap.lua Options.lua modules/Skin.lua modules/Ping.lua modules/Zoom.lua tests/test_contracts_12_1_5.lua tests/runtime_stubs_env.lua tests/test_runtime_stubs.lua
texlua tests/test_contracts_12_1_5.lua
texlua tests/test_runtime_stubs.lua
```

The offline suite covers legacy/current-schema migration, root/nested identity preservation, exact decorative ownership, direct opaque ping handling, native-widget draw order, fire/pulse cleanup, one native zoom step, world/combat cancellation, refresh coalescing, and single-apply Settings reset.

Live Retail validation remains required for actual build/Interface capture, Edit Mode profiles, hybrid minimap/game-rule transitions, housing and landing-page coexistence, mask rendering, texture alignment, combat/taint behavior, logout persistence, and profiler measurements.

## Developer documentation

- [Architecture](ARCHITECTURE.md)
- [Agent guide](AGENT_GUIDE.md)
- [Code index](CODE_INDEX.md)
- [Code graph](CODE_GRAPH.md)
- [Changelog](docs/CHANGELOG.md)
- [WoW addon engineering knowledge base](https://github.com/UnknownAlienHuman/wow-addon-engineering-kb)

## License

Licensed under the [MIT License](LICENSE).
