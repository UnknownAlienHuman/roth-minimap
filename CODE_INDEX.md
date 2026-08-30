# Roth Minimap code index

| Path | Responsibility |
|---|---|
| `RothMinimap.toc` | Retail 12.1 metadata and definitive safe load order |
| `RothMinimap.lua` | Schema v4 migration/sanitize, accessibility/object gates, event routing, mask, decorative alpha restore, Edit Mode callbacks, combat-deferred apply, slash/reset/status |
| `modules/Skin.lua` | Addon-owned border, runes, visible-only fire ticker, pulse and vignette |
| `modules/Ping.lua` | Opaque MINIMAP_PING fixed-text toast/chat notice and optional sound |
| `modules/Zoom.lua` | Public wheel zoom and one cancellable reset timer |
| `Options.lua` | Current vertical Blizzard Settings category |
| `tests/test_ownership_12_1.lua` | Static regression for no foreign-widget collection/reparent/reanchor/method override or ping-unit lookup |

Removed: `modules/ButtonBag.lua` and `modules/AddonCompartment.lua`. Blizzard/Edit Mode owns geometry and functional minimap widgets.
