# Roth Minimap

Edit-Mode-compatible minimap presentation for World of Warcraft Retail 12.1.5.

Roth Minimap owns a square mask, additive Diablo-style art, a fixed opaque-safe ping notification, and an optional reset after Blizzard's native mouse-wheel zoom. Blizzard remains the sole owner of `MinimapCluster` geometry, native widgets, input, and third-party minimap buttons.

## Compatibility

- Game: World of Warcraft Retail / Midnight 12.1.5
- Interface: `120105`
- Addon version: `0.4.1`
- SavedVariables schema: `5`
- Source-reviewed Blizzard baseline: `12.1.5.70688`
- In-client runtime matrix: **NOT-RUN**
- External dependencies: none
- GitHub Actions: none

## Ownership

Use Blizzard **Edit Mode** to position and size the minimap. Roth Minimap does not persist or replace Minimap/MinimapCluster points, parent, size, scale, scripts, state drivers, or child-widget layout.

The addon never scans frame trees, collects minimap buttons, reparents foreign controls, or overrides their methods. Clock, calendar, tracking, difficulty, mail, alerts, Addon Compartment, and third-party buttons remain native.

`Hide decorative Blizzard border art` changes alpha only on the selected-source decorative owners:

- `MinimapCompassTexture`;
- `MinimapCluster.BorderTop`.

`MinimapBackdrop` is deliberately excluded because it owns the housing overlay and expansion landing-page controls.

## Skin and visibility

All border, rune, fire, pulse, and vignette regions are addon-owned. The outer skin is parented to `Minimap`, follows its effective visibility, and retains the last accessible ordinary geometry instead of inventing fallback dimensions.

The 4×4 fire-atlas ticker:

- is bounded to 1–20 FPS;
- exists only while the skin and native minimap are effectively visible;
- is cancelled on hide/disable;
- is not recreated when the configured interval did not change.

## Ping

`MINIMAP_PING` arguments are ignored in full. The addon never reads, compares, formats, logs, persists, or defers the secret payload. It may show only fixed ordinary text: `Map ping received`.

The toast is created outside combat when the feature is applied. Roth Minimap does not play a second ping sound because Blizzard already owns native ping audio.

## Zoom

Blizzard's `MinimapMixin:OnMouseWheel` performs the zoom step. Roth Minimap post-hooks it only to observe the resulting ordinary zoom and schedule one cancellable reset to level `0`.

The addon does not call `EnableMouseWheel`, does not perform a second zoom step, does not hard-code a maximum zoom level, and cancels pending reset work on disable, hide, combat entry, and re-apply.

## Persistence and reset

`## LoadSavedVariablesFirst: 1` makes file-scope schema migration explicit for the current client family. Schema 5 removes the obsolete duplicate ping-sound and wheel-owner fields.

`/rmmap reset` resets the root and nested SavedVariables tables **in place**. This preserves the table identities already registered with Blizzard Settings, then notifies every registered setting.

## Commands

```text
/rmmap
/rmmap config
/rmmap toggle
/rmmap reset
/rmmap status
```

## Validation

```text
texlua --luaconly RothMinimap.lua Options.lua modules/Skin.lua modules/Ping.lua modules/Zoom.lua tests/test_contracts_12_1_5.lua tests/test_runtime_stubs.lua
texlua tests/test_contracts_12_1_5.lua
texlua tests/test_runtime_stubs.lua
```

The local checks cover syntax, schema migration, in-place reset, exact decorative ownership, opaque ping policy, effective skin visibility, one native wheel step, and one cancellable reset timer.

Live Retail validation remains required for actual build/Interface capture, Edit Mode layouts, masks, atlas rendering, housing/landing-page coexistence, combat transitions, Settings, reload/logout persistence, taint/forbidden errors, and profiler measurements.

## Developer documentation

- [Architecture](ARCHITECTURE.md)
- [Agent guide](AGENT_GUIDE.md)
- [Code index](CODE_INDEX.md)
- [Code graph](CODE_GRAPH.md)
- [WoW addon engineering knowledge base](https://github.com/UnknownAlienHuman/wow-addon-engineering-kb)

## License

Licensed under the [MIT License](LICENSE).
