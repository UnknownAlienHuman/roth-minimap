# Roth Minimap code index — 0.4.5

| Path | Owner |
|---|---|
| `RothMinimap.toc` | Retail metadata, source pin, and load order |
| `RothMinimap.lua` | Schema 7, dynamic media root, access gates, hybrid/housing fallback, mask/art ownership, lifecycle, reset, and commands |
| `modules/Skin.lua` | Addon-owned Diablo presentation and adaptive idle/combat fire ticker |
| `modules/Ping.lua` | `MINIMAP_PING` CallbackEvent and fixed ordinary notification |
| `modules/Zoom.lua` | Native wheel observation and one reset timer |
| `Options.lua` | Blizzard vertical Settings controls |
| `tests/test_syntax.lua` | Per-file Lua compilation gate |
| `tests/test_contracts_12_1_5.lua` | Static ownership, access, documentation, and forbidden-pattern regression |
| `tests/runtime_stubs_env.lua` | Offline WoW API, Settings, access, timer, and error stubs |
| `tests/test_runtime_stubs.lua` | Migration, media-root, cadence, callback, alpha restore, fallback, timer, combat, and reset behavior |
| `tests/test_media.py` | TGA dimensions/format/alpha, mask-shape, and fire-atlas validation |
| `.github/workflows/validate.yml` | Runs all local validation gates on `main` and pull requests |

Retired and forbidden: ButtonBag, AddonCompartment diagnostics, foreign reparenting, native geometry ownership, raw ping payload routing, recursive zoom, and hard-coded addon-folder media paths.
