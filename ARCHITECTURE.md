# Roth Minimap architecture

## Ownership

`RothMinimap.lua` owns schema-v4 SavedVariables, accessibility/object gates, event routing, square-mask selection, decorative Blizzard-art alpha snapshots, module application, Edit Mode callbacks, slash commands, reset, and combat-deferred apply.

`modules/Skin.lua` owns only addon-created border, runes, fire, pulse, and vignette textures. `modules/Ping.lua` owns an addon-created fixed-text toast. `modules/Zoom.lua` owns the mouse-wheel hook and one cancellable zoom-reset timer. `Options.lua` owns the Blizzard Settings category and writes current DB fields.

Blizzard/Edit Mode owns MinimapCluster position/size, Minimap child widgets, and third-party minimap buttons.

## Load order

```text
RothMinimap.toc
  -> RothMinimap.lua
  -> modules/Skin.lua
  -> modules/Ping.lua
  -> modules/Zoom.lua
  -> Options.lua
```

ButtonBag and AddonCompartment diagnostic modules are absent.

## Geometry boundary

The runtime never changes MinimapCluster/Minimap parent, point, size, scale, clamping, click scripts, or state drivers. Addon art is anchored to Minimap and follows Blizzard geometry. `EditMode.Exit`, `EditMode.SavedLayouts`, world entry, and UI-scale events refresh addon-owned skin dimensions only.

## Blizzard-art boundary

`hideBlizzardArt` applies alpha only to an allowlist of decorative border/background objects. Original alpha is weakly snapshotted and restored. Clock, calendar, tracking, difficulty, mail, queue, compartment, and minimap buttons are not included.

## Module behavior

- Skin: visible-only 4×4 atlas ticker, bounded 1–20 FPS; no hidden ticker.
- Ping: fixed ordinary text; MINIMAP_PING payload is opaque.
- Zoom: public GetZoom/SetZoom and one cancellable timer; no recursive animation.
- Settings: current vertical Settings API; no mover/button-bag controls.

## Combat

Core apply, skin geometry, and creation defer in combat. Zoom input/reset is skipped in combat. Existing addon-owned animation may continue with ordinary cached settings; no Blizzard secure geometry/state is mutated.

## Persistent state

Only enablement, mask/art toggles, skin visual values, ping values, and zoom values remain. Legacy mover, ButtonBag, widget-position, compartment, HUD, clock/calendar/tracking/difficulty, and hide tables are discarded.

## Evidence boundary

The local ownership regression proves the static code/load boundary. It does not prove live Edit Mode callbacks, frame accessibility, decorative-art allowlist, visual alignment, taint, or performance.
