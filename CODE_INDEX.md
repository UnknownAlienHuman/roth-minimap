# Roth Minimap code index — 0.5.0

| Path | Responsibility |
|---|---|
| `RothMinimap.toc` | Retail metadata, release version, source pin, and load order |
| `RothMinimap.lua` | Schema 9, four named visual presets, migration, access gates, native mask/art ownership, lifecycle, reset, and commands |
| `modules/Skin.lua` | Responsive Obsidian Ember composition, owned center mask, idle AnimationGroup breath, and one combat-only atlas ticker |
| `modules/Ping.lua` | Opaque `MINIMAP_PING` callback and compact themed notification |
| `modules/Zoom.lua` | Native wheel observation and one reset timer |
| `Options.lua` | Blizzard Settings, preset selection, semantic motion controls, responsive expansion, and automatic `Custom` state |
| `tests/test_syntax.lua` | Recursive Lua compilation gate |
| `tests/test_contracts_12_1_5.lua` | Static design, ownership, masking, access, documentation, and forbidden-pattern regression |
| `tests/runtime_stubs_env.lua` | Offline WoW API, Settings, mask, animation, access, timer, and error stubs |
| `tests/test_runtime_stubs.lua` | Schema-9 presets, owned masks, idle/combat motion, proportional geometry, callbacks, combat, and reset behavior |
| `tests/test_media.py` | Exact seven-file TGA manifest, dimensions, alpha, center/bounds report, map mask, and thin-atlas validation |

Retired: idle Lua atlas ticker, unmasked center fire bleed, fixed-pixel frame ratio, heavy default fire atlas, flat full-strength composition, ButtonBag, native geometry ownership, raw ping routing, recursive zoom, and hard-coded media roots.
