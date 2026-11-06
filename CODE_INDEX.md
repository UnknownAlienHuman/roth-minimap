# Roth Minimap code index

Release `0.4.2` · Retail Interface `120105`.

| Path | Responsibility |
|---|---|
| `RothMinimap.toc` | Retail 12.1.5 metadata and load order |
| `RothMinimap.lua` | Schema 6 migration, access gates, exact mask/art ownership, lifecycle queue, module apply, in-place reset, slash commands |
| `modules/Skin.lua` | Addon-owned art, native draw-order sync, visible-only fire ticker, deterministic pulse cleanup |
| `modules/Ping.lua` | Direct opaque `MINIMAP_PING` owner and fixed toast/chat notification |
| `modules/Zoom.lua` | Native wheel observation and one cancellable reset timer |
| `Options.lua` | Vertical Settings category, ping destination dropdown, callback-suppressed refresh |
| `tests/test_contracts_12_1_5.lua` | Static ownership and forbidden-pattern regression |
| `tests/runtime_stubs_env.lua` | Compact offline WoW/Settings/timer environment used only by runtime tests |
| `tests/test_runtime_stubs.lua` | Legacy/current migration, lifecycle, draw-order, ping, timer, combat, and reset behavior |

Removed subsystems remain removed: ButtonBag, AddonCompartment diagnostics, native geometry ownership, and foreign-widget mutation.
