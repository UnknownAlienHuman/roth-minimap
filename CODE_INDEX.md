# Roth Minimap code index

| File | Responsibility |
|---|---|
| `RothMinimap.toc` | Metadata, SavedVariables and load order |
| `RothMinimap.lua` | Namespace, DB, minimap geometry, lifecycle and common helpers |
| `modules/Skin.lua` | Square mask, border, runes, glow and fire layers |
| `modules/Ping.lua` | Ping toast, sound and skin pulse |
| `modules/Zoom.lua` | Mouse-wheel zoom and auto reset |
| `modules/ButtonBag.lua` | Button discovery, stash/restore and bag UI |
| `modules/AddonCompartment.lua` | Addon compartment integration |
| `Options.lua` | Settings and slash-command entrypoints |

Detailed load/event/state routing is in [`AGENT_GUIDE.md`](AGENT_GUIDE.md).
