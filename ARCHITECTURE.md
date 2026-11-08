# Roth Minimap architecture — 0.5.0

## Owners

- `RothMinimap.lua`: schema 9, visual presets, migration, access gates, native-mode detection, mask/art ownership, lifecycle coalescing, reset, and commands.
- `modules/Skin.lua`: addon-owned responsive shadow, ember halo, charred rim, fire, frame, highlight, runes, pulse, and vignette.
- `modules/Ping.lua`: secret-payload-safe callback registration and compact fixed-text toast/chat presentation.
- `modules/Zoom.lua`: native wheel observation and one cancellable reset timer.
- `Options.lua`: Blizzard Settings registration, preset application, motion controls, and `Custom` transition after detailed edits.

## Visual composition

```text
BACKGROUND
  soft black shadow
  low ember halo

ARTWORK
  charred material rim
  thin ember atlas
  dark frame
  restrained additive frame highlight
  optional runes
  event pulse

MINIMAP OVERLAY
  inner vignette
```

All regions are addon-created and noninteractive. The frame follows accessible Minimap strata and level; native child widgets remain above it.

## Atlas evidence boundary

The 512×512 fire file is a 4×4 atlas. Whole-file coordinates are not runtime frame coordinates. Validation therefore slices all 16 actual 128×128 frames and checks each one independently.

```text
whole atlas center alpha != displayed-frame center alpha
```

All displayed-frame centers are transparent in the selected thin atlas. No extra runtime effect mask is created: it would add an object and potentially clip the authored flame silhouette without addressing an observed defect.

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

Only addon-owned frame and shadow geometry change. Blizzard Edit Mode remains the sole authority for the native Minimap size and position. Inaccessible or invalid geometry skips the update rather than inventing a size.

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
- no extra effect mask;
- no `OnUpdate`, polling, recursive timers, or repeated frame/texture creation;
- proportional geometry is recalculated only on settings changes and confirmed lifecycle signals.

## Verification boundary

`tests/test_syntax.lua` discovers every Lua file. Static tests enforce ownership, responsive geometry, and motion contracts. Runtime stubs exercise presets, schema migration, idle/combat transitions, three Edit Mode sizes, ping, native mask ownership, zoom, and reset behavior. `tests/test_media.py` enforces the exact TGA manifest and reports per-frame alpha metrics rather than reasoning from whole-atlas coordinates.

Live rendering, taint, native ordering, SavedVariables serialization, and profiler measurements remain `NOT-RUN` until captured on a named client build.
