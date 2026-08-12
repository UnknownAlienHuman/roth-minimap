# Dev notes

## Minimap widgets
When `hideBlizzardArt` is enabled, Blizzard anchors for `ZoneTextButton` and `MiniMapInstanceDifficulty` may drift because some anchor frames are hidden.
RothMinimap snapshots their original points and re-anchors them to `Minimap`.

## Button bag
We avoid embedding other button collectors (HidingBar/MBB/etc) to prevent nested bags.
Instead we scan for their contained buttons and collect them directly.

