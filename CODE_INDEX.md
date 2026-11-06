# Roth Minimap code index

| Path | Responsibility |
|---|---|
| `RothMinimap.toc` | Retail 12.1.5 metadata, Interface `120105`, early SavedVariables readiness, definitive load order |
| `RothMinimap.lua` | Schema-v5 migration/sanitize, access/object gates, event routing, mask, exact decorative alpha restore, coalesced Edit Mode refresh, isolated apply, in-place reset, slash/status |
| `modules/Skin.lua` | Addon-owned border/runes/fire/pulse/vignette, accessible geometry, effective-visibility ticker lifecycle |
| `modules/Ping.lua` | Fully opaque `MINIMAP_PING`, pre-created fixed-text toast/chat notice, no duplicate native sound |
| `modules/Zoom.lua` | Post-hook observation of Blizzard's native wheel step and one cancellable reset timer |
| `Options.lua` | One vertical Blizzard Settings category and `NotifyUpdate` reset refresh |
| `tests/test_contracts_12_1_5.lua` | Static Retail 12.1.5 ownership/lifecycle regression |
| `tests/test_runtime_stubs.lua` | Offline schema migration, exact art ownership, one native wheel step, reset timer, and in-place DB reset regression |

Removed and prohibited: ButtonBag, AddonCompartment diagnostics, generic frame scans, foreign reparent/reanchor/method overrides, `MinimapBackdrop` hiding, ping-payload inspection, and addon-owned wheel steps.
