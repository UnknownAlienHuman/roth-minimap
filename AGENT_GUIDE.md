# Roth Minimap agent guide

## Start here

Read [`RothMinimap.toc`](RothMinimap.toc), then `RothMinimap.lua`. The TOC loads the core file first, followed by `modules/Skin.lua`, `Ping.lua`, `Zoom.lua`, `ButtonBag.lua`, `AddonCompartment.lua`, and root `Options.lua`. The namespace is `local ADDON, ns = ...`; modules attach to `ns.skin`, `ns.ping`, `ns.zoom`, `ns.buttons`, and `ns.compartment`.

## Runtime and data flow

`RothMinimap.lua` owns `DEFAULTS`, `RothMinimapDB` initialization/migrations (currently schema version 18), the event bus, snapshot/restore state, minimap cluster geometry, mover, slash commands, and `ApplyAll`/`DisableAll`. `ADDON_LOADED` initializes DB, snapshots Blizzard frame points, prepares quick-map, initializes Options, and queues apply; `PLAYER_ENTERING_WORLD` repeats discovery/apply; regen events toggle combat state in Skin and ButtonBag and drain pending work.

`Skin.lua` builds the square mask, border, rune/glow/vignette/char/fire/shadow layers and a single fire ticker; it subscribes to health, mount/rest, combat, loot, and achievement events for reactive effects. `Ping.lua` subscribes to `MINIMAP_PING`. `Zoom.lua` handles mouse-wheel zoom and delayed auto reset. `ButtonBag.lua` scans LibDBIcon/manual minimap buttons, snapshots original parent/points, moves eligible buttons into `RothMinimapBagFrame`, and restores them at combat boundaries. `AddonCompartment.lua` diagnoses the launcher. `Options.lua` builds Settings subcategories for layout/skin/modules/button bag.

## State, surfaces, dependencies

`RothMinimapDB` contains layout, visibility, square/skin/fire/visual/shadow settings, quick-map, zone font, zoom, ping, mover, and button-bag state. `_G.RothMinimap_OpenConfig` is the TOC `AddonCompartmentFunc`. Core slash aliases are `/rmmap`, `/rothminimap`, `/rm` with `unlock|lock|scan|compartment|reset`; ButtonBag adds `/rmb scan|reset`. `LibSharedMedia-3.0` and `LibDBIcon-1.0` are probed dynamically through LibStub; neither is a TOC dependency, so features must degrade safely when absent.

## Invariants and risks

- ButtonBag may hide/reparent protected or forbidden frames. Preserve `canModifyFrame`, `InCombatLockdown`, snapshots, hook suppression, delayed rescans, and `OnCombatChanged` restore logic.
- `hideBlizzardArt`, `hideZoomButtons`, and `hideNorthTag` are forced true by migrations/current policy; do not treat them as freely reversible without updating migration semantics.
- Skin fire/reactive tickers and ButtonBag scans are the main hot paths. Keep one ticker per feature and stop it when disabled/out of scope.
- Minimap/cluster `SetPoint`, scale, parent, and widget hiding can be combat-sensitive; queue through `QueueApply` and retain pending-combat state.
- Button discovery is heuristic when `buttons.onlyLibDBIcon` is false; do not promise complete/zero-false-positive collection without runtime testing.

## Change routing

- DB/defaults/migrations, minimap geometry, apply/restore, core slash/events: `RothMinimap.lua`.
- Visual layers/reactive effects: `modules/Skin.lua`.
- Ping toast: `modules/Ping.lua`.
- Zoom policy: `modules/Zoom.lua`.
- Button discovery/reparent/restore/bag UI: `modules/ButtonBag.lua`.
- Addon compartment diagnostics: `modules/AddonCompartment.lua`.
- Settings controls: `Options.lua`.

## Verification

Static: validate all TOC paths, parse the seven loaded Lua files (root `RothMinimap.lua`, five `modules/*.lua` files, and `Options.lua`), and run `git diff --check`. In game, exercise `/rm unlock|lock|scan|compartment|reset` and `/rmb scan|reset`, open Settings and the compartment entry, toggle skin/fire/ping/zoom/button-bag features, zone and enter/leave combat, and verify every collected button can be restored. Watch CPU/FPS and forbidden/protected errors during scans. Current audit does not claim live client behavior.
