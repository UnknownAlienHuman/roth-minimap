# Roth Minimap

Edit-Mode-compatible minimap presentation for World of Warcraft Retail 12.1.5.

Roth Minimap adds a square mask, restrained Diablo-style art, an opaque ping notification, and an optional reset after Blizzard's native mouse-wheel zoom. Blizzard remains the sole owner of `MinimapCluster` geometry, native input, native widgets, Hybrid Minimap, housing overlays, and third-party minimap buttons.

## Compatibility

- Retail / Midnight 12.1.5
- Interface `120105`
- Addon version `0.4.6`
- SavedVariables schema `8`
- Source-reviewed Blizzard live build `12.1.5.70783`
- Source pin `Gethe/wow-ui-source@297d7aaaa736f346b3e036f38ee088eaf7f8c07f`
- External dependencies: none
- In-client runtime matrix: **NOT-RUN**

## Installation

Place the addon folder under `World of Warcraft/_retail_/Interface/AddOns/`. Runtime media paths use the actual addon folder name, so a renamed GitHub archive folder still resolves bundled textures.

## Ownership

Use Blizzard **Edit Mode** to position and size the minimap. Roth Minimap never stores or replaces native points, parent, size, scale, scripts, state drivers, or child-widget layout.

The addon does not scan frame trees, collect minimap buttons, reparent foreign controls, or replace their methods. Addon Compartment is the supported launcher.

`Hide decorative Blizzard border art` changes alpha only on:

- `MinimapCompassTexture`;
- `MinimapCluster.BorderTop`.

The original accessible alpha is retained until a safe restore succeeds. A temporarily inaccessible read does not discard the snapshot. `MinimapBackdrop` is deliberately untouched because it owns housing and expansion UI descendants.

## Mask policy

Roth Minimap writes the square mask only while that feature is selected. If the addon starts disabled or with `Square minimap mask` off, it leaves an existing third-party mask untouched.

After Roth Minimap has applied its square mask, disabling the feature restores the selected-build native default. `PLAYER_ENTERING_WORLD` revalidates the active mask once. Exact restoration of an arbitrary foreign mask is not claimed because the selected public Minimap API exposes `SetMaskTexture`, but no exact `GetMaskTexture` contract.

## Native-presentation fallback

Blizzard Hybrid Minimap uses a separate `MapCanvas` and its own circular mask. Indoor housing adds a native static overlay. Roth Minimap does not reshape either foreign surface.

When the Roth square-mask feature is selected and either native mode becomes active, the addon:

- applies the known native minimap mask;
- restores exact decorative alpha values previously hidden by Roth Minimap;
- hides only addon-owned border, runes, fire, pulse, and vignette;
- leaves the fixed ping notification and bounded zoom reset available.

Normal square presentation returns on the next full lifecycle refresh after the native mode ends.

## Skin and performance

All skin regions are addon-owned and noninteractive. The default border tint is dark brown and the default inner vignette is `0.22`.

The 4×4 fire-atlas ticker uses separate cadence limits:

- idle default: 2 FPS, configurable from 1–8;
- combat default: 8 FPS, configurable from 1–20;
- exists only while the skin and native minimap are effectively visible;
- stops on hide, disable, native fallback, or fire disable;
- is not recreated when the interval is unchanged;
- reads combat lockdown at update time, so event-frame ordering cannot select the wrong cadence.

Schema 8 repairs old migrated border/rune layers that were disabled with alpha `0`: the layer remains disabled, but enabling its checkbox now makes it visible again.

## Ping

`MINIMAP_PING` is registered through the callback-event API. Its secret payload is ignored completely. The addon displays only fixed ordinary text:

```text
Map ping received
```

Blizzard retains native ping-sound ownership.

## Zoom

Blizzard performs the only wheel zoom step. Roth Minimap post-hooks the completed input and owns at most one cancellable timer that resets zoom to level `0`.

It does not call `EnableMouseWheel`, duplicate the wheel step, hard-code the maximum level, or recursively retry. A pending reset is preserved across unrelated settings applies and rescheduled only when its delay changes.

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
texlua tests/test_syntax.lua
texlua tests/test_contracts_12_1_5.lua
texlua tests/test_runtime_stubs.lua
python3 tests/test_media.py
```

`tests/test_syntax.lua` discovers and compiles every Lua file recursively on Windows and POSIX hosts. `tests/test_media.py` enforces the exact TGA manifest, dimensions, format, alpha channels, square-mask shape, and visible alpha in every fire-atlas frame. GitHub Actions runs the same four gates on `main` and pull requests with a pinned checkout action and read-only permissions.

Offline checks cover schema migration, dynamic media paths, adaptive fire cadence, Settings identity, callback-event ping registration, secret payload opacity, ordinary-only core/Settings errors, exact alpha restoration, transition-owned mask writes, native fallback, draw order, native wheel behavior, combat deferral, timer-free combat queue collapse, refresh coalescing, zoom-delay rescheduling, and reset.

Live testing is still required for actual client build capture, Edit Mode profiles, hybrid/housing rendering, atlas alignment, taint/forbidden errors, logout persistence, and profiler measurements.

## Developer documentation

- [Architecture](ARCHITECTURE.md)
- [Agent guide](AGENT_GUIDE.md)
- [Code index](CODE_INDEX.md)
- [Code graph](CODE_GRAPH.md)
- [Changelog](docs/CHANGELOG.md)
- [WoW addon engineering knowledge base](https://github.com/UnknownAlienHuman/wow-addon-engineering-kb)

## License

MIT.
