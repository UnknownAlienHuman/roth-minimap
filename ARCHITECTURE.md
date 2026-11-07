# Roth Minimap architecture — 0.5.0

## Owners

- `RothMinimap.lua`: schema 9, visual presets, migration, access gates, native-mode detection, mask/art ownership, lifecycle coalescing, reset, and commands.
- `modules/Skin.lua`: addon-owned shadow, ember halo, charred rim, fire, frame, highlight, runes, pulse, and vignette.
- `modules/Ping.lua`: secret-payload-safe callback registration and compact fixed-text toast/chat presentation.
- `modules/Zoom.lua`: native wheel observation and one cancellable reset timer.
- `Options.lua`: Blizzard Settings registration, preset application, and `Custom` transition after detailed edits.

## Visual composition

```text
BACKGROUND
  shadow (black BLEND, extended 8 px)
  ambient ember halo (ADD, bounded by visible fire alpha)

ARTWORK
  charred rim
  thin 4x4 ember atlas
  dark frame
  low-alpha additive frame highlight
  optional runes
  event pulse

MINIMAP OVERLAY
  clipped inner vignette
```

All regions are noninteractive. The frame follows accessible Minimap strata and level; native child widgets remain above it.

## Preset model

Named presets write explicit ordinary values into `ns.db.skin`. Runtime rendering reads only those values; there is no second hidden style authority.

```text
select named preset
  -> update frame/rune/fire/vignette values in place
  -> notify existing Settings objects
  -> apply once

change detailed appearance control
  -> preserve edited value
  -> set preset = custom
  -> apply once
```

Schema 9 upgrades schema-8 installations only when every old visual value still matches the previous defaults. Any detected customization is preserved and marked `custom`.

## Presentation state

```text
normal native minimap + Roth square mode
  -> addon square mask
  -> exact decorative art hidden
  -> layered frame visible

Hybrid Minimap or indoor housing
  -> selected-build native mask when Roth owns square transition
  -> decorative art restored
  -> addon frame hidden
  -> foreign MapCanvas/masks/overlays untouched
```

## Lifecycle

```text
file load
  -> schema migration
  -> module load
  -> Settings registration

PLAYER_ENTERING_WORLD
  -> invalidate owned mask decision
  -> one coalesced full apply

UI_SCALE_CHANGED
  -> one coalesced full apply

EditMode.Exit / EditMode.SavedLayouts
  -> one coalesced addon-geometry refresh

combat
  -> no structural geometry work
  -> collapse requests into one pending state
  -> update only addon-owned safe presentation
  -> drain once after PLAYER_REGEN_ENABLED
```

## Security and ownership boundary

`MINIMAP_PING` uses `RegisterEventCallback`; every payload argument is ignored at the callback boundary. No raw payload enters a generic bus, cache, timer, logger, or serializer.

No code scans frame trees, reparents foreign objects, replaces native methods, mutates `MinimapBackdrop`, owns native wheel enablement, or persists Blizzard geometry.

## Performance boundary

- one fire ticker, absent at zero alpha or while hidden;
- one zoom timer;
- one coalesced lifecycle timer;
- no `OnUpdate`, polling, recursive timers, or repeated frame/texture creation;
- additional 0.5.0 depth layers are static textures and do not add periodic work.

## Verification boundary

`tests/test_syntax.lua` discovers every Lua file. Static tests enforce ownership and design contracts. Runtime stubs exercise presets, schema migration, layer assets, combat, ping, mask, zoom, and reset behavior. `tests/test_media.py` enforces the exact TGA manifest and visible alpha in every thin-atlas frame.

Live rendering, taint, native ordering, SavedVariables serialization, and profiler measurements remain `NOT-RUN` until captured on a named client build.
