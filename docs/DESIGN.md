# Design Notes

## No third-party code copying

This addon re-implements features inspired by common minimap addons, but does not copy code from them.

## Combat safety

- Rescanning minimap buttons and re-parenting frames is deferred in combat (`InCombatLockdown`).
- The bag still shows already-stashed buttons in combat.

## Ping

The addon listens to `MINIMAP_PING` and can show a toast and optional sound. The sound uses a soft UI kit and avoids raid-warning alarms.

## Shadow vignette

The shadow effect uses a small texture (`media/shadow_edge.tga`) with alpha gradient, rotated via `SetTexCoord` for each edge.
