# Roth Minimap

Edit-Mode-compatible minimap presentation for World of Warcraft Retail 12.1.

Roth Minimap applies a square mask, additive Diablo-style art, an opaque-safe ping notification, and bounded mouse-wheel zoom. Blizzard remains the owner of MinimapCluster geometry and every clock, calendar, tracking, difficulty, mail, addon-compartment, and third-party minimap button.

## Compatibility

- Game: World of Warcraft Retail / Midnight 12.1.0
- Interface: `120100`
- Version: `0.4.0`
- Verified Blizzard source baseline: `12.1.0.69497`
- SavedVariables: `RothMinimapDB`
- External dependencies: none
- GitHub Actions: none

## Geometry and Blizzard widgets

Use Blizzard **Edit Mode** to position and size the Minimap. Roth Minimap does not save or overwrite MinimapCluster points, parent, size, scale, clamping, mouse scripts, click handlers, or state drivers.

The addon does not move or hide functional widgets. These remain Blizzard-owned:

- `TimeManagerClockButton`;
- `GameTimeFrame` / calendar;
- `MiniMapTracking`;
- difficulty and challenge badges;
- mail and queue/status indicators;
- `AddonCompartmentFrame`;
- native and third-party minimap buttons.

`Hide decorative Blizzard border art` changes alpha only on a short allowlist of known decorative border/background regions. Original alpha is captured and restored. It does not reparent or reanchor widgets.

## Removed ButtonBag

The old ButtonBag and AddonCompartment diagnostic modules are removed. They scanned global/minimap frame trees, reparented real foreign buttons, changed their alpha/parent/points, and temporarily replaced `SetPoint`/`ClearAllPoints` methods. There is no generic safe contract for taking ownership of every Blizzard and third-party minimap button on Retail 12.1.

All buttons remain in their native ownership/lifecycle. The Blizzard Addon Compartment remains available as the supported central launcher.

## Additive skin

All border, rune, fire, glow, and vignette textures are addon-owned:

- square mask on `Minimap`;
- border/runes/fire frame anchored to `Minimap` without changing Minimap geometry;
- optional vignette texture created on Minimap;
- 4×4 fire atlas ticker that exists only while the visible skin has fire enabled;
- combat changes only fire alpha/speed state;
- ping can trigger an addon-owned pulse.

Edit Mode exit and UI-scale/world events update only the addon-owned skin geometry.

## Ping

`MINIMAP_PING` is treated as an opaque notification. The addon never calls `UnitName` or formats the event unit payload. It shows fixed ordinary text: `Map ping received`.

## Zoom

Mouse-wheel zoom uses only `Minimap:GetZoom` and `Minimap:SetZoom`. Optional reset uses one cancellable `C_Timer.NewTimer`; there is no recursive timer or smooth polling loop. Zoom input and reset are skipped in combat.

## Commands

```text
/rmmap
/rmmap config
/rmmap toggle
/rmmap reset
/rmmap status
```

`/rmmap status` reports that geometry is owned by Blizzard Edit Mode and ButtonBag is removed.

## Validation status

`tests/test_ownership_12_1.lua` is a local static regression that enforces:

- Interface `120100`;
- no ButtonBag/AddonCompartment module in the TOC;
- no frame-tree scan, foreign SetParent/reanchor/method override, or `UnitName` ping path;
- Edit Mode callback presence;
- bounded one-timer zoom reset.

Live Retail testing remains required for Edit Mode layouts, square mask, decorative-art restore, skin atlas, combat fire, ping, zoom, UI scale, Settings, reload migration, taint, errors, and performance.

## Developer documentation

- [Architecture](ARCHITECTURE.md)
- [Agent guide](AGENT_GUIDE.md)
- [Code index](CODE_INDEX.md)
- [Code graph](CODE_GRAPH.md)
- [WoW addon engineering knowledge base](https://github.com/UnknownAlienHuman/wow-addon-engineering-kb)

## License

Licensed under the [MIT License](LICENSE).
