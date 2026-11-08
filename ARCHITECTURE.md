# Roth Minimap architecture — 0.5.0

## Owners

- `RothMinimap.lua`: schema 9, visual presets, migration, access gates, native-mode detection, mask/art ownership, lifecycle coalescing, reset, and commands.
- `modules/Skin.lua`: addon-owned responsive shadow, masked ember halo, charred rim, fire, frame, highlight, runes, pulse, and vignette.
- `modules/Ping.lua`: secret-payload-safe callback registration and compact fixed-text toast/chat presentation.
- `modules/Zoom.lua`: native wheel observation and one cancellable reset timer.
- `Options.lua`: Blizzard Settings registration, preset application, motion controls, and `Custom` transition after detailed edits.

## Visual composition

```text
BACKGROUND
  soft black shadow (unmasked)
  masked ember halo

ARTWORK
  charred material rim
  masked thin ember atlas
  dark frame
  restrained additive frame highlight
  optional runes
  masked event pulse

MINIMAP OVERLAY
  inner vignette
```

All regions and the ember mask are addon-created, noninteractive objects. The frame follows accessible Minimap strata and level; native child widgets remain above it. No native or third-party texture receives an addon mask.

## Masked effect boundary

The thin fire atlas has nonzero alpha at its texture center. Rendering it unmasked can tint map content even at low global alpha. The skin therefore creates one owned `MaskTexture` from the charred-rim asset and attaches it only to:

- ambient glow;
- fire atlas;
- event pulse.

The outer black shadow is deliberately unmasked. The material frame and runes already carry authored alpha and do not need a runtime mask.

```text
owned CHAR alpha
  -> owned MaskTexture
  -> owned halo / fire / pulse only
  -> map content and foreign regions untouched
```

## Motion state machine

```text
idle + visible + fire alpha > 0
  -> fixed representative atlas frame
  -> repeating AnimationGroup alpha breath
  -> no Lua ticker

combat + visible + fire alpha > 0
  -> stop idle breath
  -> one atlas ticker at combat FPS

hidden / disabled / native fallback / zero alpha
  -> stop ticker
  -> stop breath
  -> hide fire/halo as required
```

`fireIdleFPS` is retained as a SavedVariables key for compatibility, but semantically controls idle breathing speed. `fireCombatFPS` remains the atlas frame cadence.

## Responsive geometry

Preset `outset` values are authored against the selected-build 198-pixel native minimap. Runtime derives:

```text
geometryScale = clamp(min(width, height) / 198, 0.5, 2.5)
scaledOutset  = round(authoredOutset * geometryScale)
shadowPadding = round(8 * geometryScale)
```

Only addon-owned frame and shadow geometry change. Blizzard Edit Mode remains the sole authority for the native Minimap size and position. Inaccessible or invalid geometry still skips the update rather than inventing a size.

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
  -> addon square map mask
  -> exact decorative art hidden
  -> responsive layered frame visible

Hybrid Minimap or indoor housing
  -> selected-build native map mask when Roth owns square transition
  -> decorative art restored
  -> addon frame and animation hidden
  -> foreign MapCanvas/masks/overlays untouched
```

## Lifecycle

```text
file load
  -> schema migration
  -> module load
  -> Settings registration

PLAYER_ENTERING_WORLD
  -> invalidate owned native-mask decision
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

- zero idle Lua tickers;
- one combat-only fire ticker;
- one C-level repeating idle AnimationGroup;
- one zoom timer;
- one coalesced lifecycle timer;
- no `OnUpdate`, polling, recursive timers, or repeated frame/texture/mask creation;
- proportional geometry is recalculated only on settings changes and confirmed lifecycle signals.

## Verification boundary

`tests/test_syntax.lua` discovers every Lua file. Static tests enforce ownership, masking, responsive geometry, and motion contracts. Runtime stubs exercise presets, schema migration, owned mask attachment, idle/combat transitions, three Edit Mode sizes, ping, native mask ownership, zoom, and reset behavior. `tests/test_media.py` enforces the exact TGA manifest and reports alpha center/bounds for design review.

Live rendering, taint, native ordering, SavedVariables serialization, and profiler measurements remain `NOT-RUN` until captured on a named client build.
