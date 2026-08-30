# Roth Minimap agent guide

## Contract

Retail 12.1 / Interface `120100`. Blizzard Edit Mode owns MinimapCluster position and size. RothMinimap may change only its own DB, Minimap mask, alpha of an explicit decorative-art allowlist, and addon-created skin/ping/zoom objects.

## Never restore

```text
ButtonBag
foreign button SetParent / SetPoint / ClearAllPoints
method replacement or SetPoint blockers
GetChildren / GetNumChildren / EnumerateFrames button discovery
clock/calendar/tracking/difficulty/compartment reanchor
MinimapCluster or Minimap position/parent/size ownership
UnitName(MINIMAP_PING payload)
recursive zoom timers
```

There is no generic safe contract for collecting every Blizzard/third-party minimap button. Leave them native and use Blizzard Addon Compartment.

## Files

- `RothMinimap.lua`: schema v4, access/object gates, event bus, mask, decorative alpha snapshot/restore, Edit Mode callbacks, apply/reset/slash.
- `modules/Skin.lua`: addon-owned border/runes/fire/pulse/vignette only.
- `modules/Ping.lua`: opaque fixed-text ping notification.
- `modules/Zoom.lua`: public wheel zoom plus one cancellable timer.
- `Options.lua`: current vertical Settings category.
- `tests/test_ownership_12_1.lua`: static ownership regression.

## Geometry

Do not store or apply minimap position/size. Addon art anchors to Minimap. Refresh addon geometry after Edit Mode exit/saved layouts, world entry, and UI-scale changes. Do not inspect protected widget topology to infer geometry.

## Decorative art

Only the core allowlist may have alpha changed. Snapshot original alpha before the first change and restore it when disabled. Never include functional widgets in the allowlist.

## Combat

`ns.ApplyAll` and skin geometry creation defer in combat. Zoom input/reset is skipped. The visible addon fire animation may continue using cached ordinary settings; it must not touch Blizzard state.

## Ping

Treat every MINIMAP_PING argument as opaque. Do not name the sender, query UnitName, log the unit token, or persist the payload.

## Performance

The only repeating work is the fire ticker, bounded 1–20 FPS and cancelled when skin/fire/frame is disabled or hidden. Zoom uses one cancellable timer. No frame-tree scan, OnUpdate, polling, or button collection.

## Verification

```text
texlua --luaconly RothMinimap.lua Options.lua modules/Skin.lua modules/Ping.lua modules/Zoom.lua tests/test_ownership_12_1.lua
texlua tests/test_ownership_12_1.lua
```

Live gates: Edit Mode movement/resize, widget preservation, art restore, square mask, skin/fire/ping/zoom, combat changes, Settings, reload migration, taint/errors, and hidden/visible performance.
