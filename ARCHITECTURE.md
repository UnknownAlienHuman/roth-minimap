# Roth Minimap architecture

## Ownership

`RothMinimap.lua` owns schema-v5 SavedVariables, access/object gates, event routing, deterministic square/default mask selection, exact decorative-alpha snapshots, isolated module application, coalesced Edit Mode geometry refresh, combat-deferred apply, in-place reset, and slash commands.

`modules/Skin.lua` owns only addon-created border, runes, fire, pulse, and vignette regions. `modules/Ping.lua` owns one addon-created fixed-text toast. `modules/Zoom.lua` owns a post-hook observer and one cancellable reset timer; Blizzard owns the actual wheel zoom step. `Options.lua` owns one session-lifetime Blizzard Settings category.

Blizzard/Edit Mode owns `MinimapCluster` geometry, native Minimap input, every functional child widget, and third-party minimap buttons.

## Load order

```text
RothMinimap.toc
  -> LoadSavedVariablesFirst
  -> RothMinimap.lua: migrate/sanitize schema 5
  -> modules/Skin.lua
  -> modules/Ping.lua
  -> modules/Zoom.lua
  -> Options.lua: register Settings after addon load
```

## Geometry and visibility

The runtime never changes native parent, point, size, scale, clamping, click scripts, or state drivers. The skin frame is a noninteractive child of `Minimap`, anchored once, and resizes only after an accessible positive width/height read.

`EditMode.Exit` and `EditMode.SavedLayouts` coalesce into one addon-owned geometry refresh. World entry and UI-scale changes run one full apply. Inaccessible geometry preserves the last valid dimensions; there is no guessed fallback.

Effective native visibility controls addon art and ticker lifetime. Hiding `Minimap` hides the child skin and cancels repeating fire work.

## Blizzard-art boundary

Only `MinimapCompassTexture` and `MinimapCluster.BorderTop` may have alpha changed. Their first accessible ordinary alpha is weakly snapshotted and restored.

`MinimapBackdrop` is excluded because selected source places the housing static overlay and expansion landing-page button/alerts inside it.

## Module behavior

- Skin: one 4×4 atlas ticker, bounded 1–20 FPS; start only while effectively visible; cancel on hide/disable; do not restart at the same interval.
- Ping: ignore the complete event tuple; pre-create the toast outside combat; fixed ordinary text only; no duplicate sound.
- Zoom: observe Blizzard's completed wheel step; one cancellable reset to level 0; no input-state mutation and no duplicate zoom step.
- Settings: current vertical Settings API; schema tables retain identity across reset.

Module `Apply` calls are isolated so one visual feature error does not prevent mask, art, ping, or reset application; errors remain visible through the normal error handler.

## Persistent state

Schema 5 persists only enablement, mask/art toggles, skin values, ping notification values, and zoom-reset values. It retires legacy mover, ButtonBag, widget-position, compartment, HUD, clock/calendar/tracking/difficulty, generic hide, duplicate ping-sound, and wheel-owner fields.

Reset recursively replaces values inside the existing root/nested tables. Blizzard Settings therefore never retains stale table references.

## Evidence boundary

The local tests prove syntax and selected offline/static invariants. They do not prove live rendering, callback delivery, taint, protected execution, client build, or performance. Those remain explicit named-client validation work.
