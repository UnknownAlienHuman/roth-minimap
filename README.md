# Roth Minimap

Edit-Mode-compatible minimap presentation for World of Warcraft Retail 12.1.5.

Roth Minimap adds a square mask, restrained Diablo-style art, an opaque ping notification, and an optional reset after Blizzard's native mouse-wheel zoom. Blizzard remains the sole owner of `MinimapCluster` geometry, native input, native widgets, and third-party minimap buttons.

## Compatibility

- Retail / Midnight 12.1.5
- Interface `120105`
- Addon version `0.4.4`
- SavedVariables schema `7`
- Source-reviewed Blizzard live build `12.1.5.70783`
- External dependencies: none
- In-client runtime matrix: **NOT-RUN**

## Ownership

Use Blizzard **Edit Mode** to position and size the minimap. Roth Minimap never stores or replaces native points, parent, size, scale, scripts, state drivers, or child-widget layout.

The addon does not scan frame trees, collect minimap buttons, reparent foreign controls, or replace their methods. Addon Compartment is the supported launcher.

`Hide decorative Blizzard border art` changes alpha only on:

- `MinimapCompassTexture`;
- `MinimapCluster.BorderTop`.

`MinimapBackdrop` is deliberately untouched because it owns housing and expansion UI descendants.

## Native-presentation fallback

Blizzard Hybrid Minimap uses a separate `MapCanvas` and its own circular mask. Indoor housing also adds a native static overlay. Roth Minimap cannot safely reshape either foreign surface.

While either mode is active, version 0.4.4 automatically:

- restores the default native minimap mask;
- restores the exact decorative alpha values previously hidden by the addon;
- hides only the addon-owned border, runes, fire, pulse, and vignette;
- leaves ping and bounded zoom reset available.

Normal square presentation returns on the next full lifecycle refresh after the native mode ends.

## Skin and performance

All skin regions are addon-owned and noninteractive. The default border tint is dark brown and the default inner vignette is `0.22`.

The 4×4 fire-atlas ticker uses separate cadence limits:

- idle default: 2 FPS, configurable from 1–8;
- combat default: 8 FPS, configurable from 1–20;
- exists only while the skin and native minimap are effectively visible;
- stops on hide, disable, native fallback, or fire disable;
- is not recreated when the interval is unchanged.

## Ping

`MINIMAP_PING` is registered through the current callback-event API. Its secret payload is ignored completely. The addon displays only fixed ordinary text:

```text
Map ping received
```

Blizzard retains native ping-sound ownership.

## Zoom

Blizzard performs the only wheel zoom step. Roth Minimap post-hooks the completed input and owns at most one cancellable timer that resets zoom to level `0`.

It does not call `EnableMouseWheel`, duplicate the wheel step, hard-code the maximum level, or recursively retry.

## Commands

```text
/rmmap
/rmmap config
/rmmap toggle
/rmmap reset
/rmmap status
```

`/rmmap status` includes the active native-presentation reason (`hybrid`, `housing`, or `no`).

## Validation

```text
texlua --luaconly RothMinimap.lua Options.lua modules/Skin.lua modules/Ping.lua modules/Zoom.lua tests/test_contracts_12_1_5.lua tests/runtime_stubs_env.lua tests/test_runtime_stubs.lua
texlua tests/test_contracts_12_1_5.lua
texlua tests/test_runtime_stubs.lua
```

Offline checks cover schema migration, adaptive idle/combat fire cadence, Settings identity, callback-event ping registration, secret payload opacity, native fallback, draw order, visibility, zoom, combat deferral, coalescing, and reset.

Live testing is still required for actual client build capture, Edit Mode profiles, hybrid/housing rendering, atlas alignment, taint/forbidden errors, logout persistence, and profiler metrics.

## Developer documentation

- [Architecture](ARCHITECTURE.md)
- [Agent guide](AGENT_GUIDE.md)
- [Code index](CODE_INDEX.md)
- [Code graph](CODE_GRAPH.md)
- [Changelog](docs/CHANGELOG.md)
- [WoW addon engineering knowledge base](https://github.com/UnknownAlienHuman/wow-addon-engineering-kb)

## License

MIT.
