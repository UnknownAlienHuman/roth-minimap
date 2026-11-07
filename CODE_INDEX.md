# Roth Minimap code index — 0.4.6

| Path | Owner |
|---|---|
| `RothMinimap.toc` | Retail metadata, source pin, SavedVariables-first load, and runtime order |
| `RothMinimap.lua` | Schema 8, dynamic media root, access gates, transition-owned mask policy, hybrid/housing fallback, exact art restoration, lifecycle, reset, and commands |
| `modules/Skin.lua` | Addon-owned Diablo presentation and adaptive idle/combat fire ticker |
| `modules/Ping.lua` | `MINIMAP_PING` CallbackEvent and fixed ordinary notification |
| `modules/Zoom.lua` | Native wheel observation and one reset timer |
| `Options.lua` | Blizzard vertical Settings controls |
| `tests/test_syntax.lua` | Recursive per-file Lua compilation gate for Windows/POSIX |
| `tests/test_contracts_12_1_5.lua` | Static ownership, access, TOC, workflow, documentation, and forbidden-pattern regression |
| `tests/runtime_stubs_env.lua` | Offline WoW API, native wheel, Settings, access, mask, timer, and error stubs |
| `tests/test_runtime_stubs.lua` | Migration, mask transitions, cadence, callback, alpha restore, fallback, native wheel, combat, and reset behavior |
| `tests/test_media.py` | Exact TGA manifest, dimensions/format/alpha, mask shape, and per-atlas-frame validation |
| `.github/workflows/validate.yml` | Runs all validation gates with pinned checkout code and no persisted credentials |

Retired and forbidden: ButtonBag, AddonCompartment diagnostics, foreign reparenting, native geometry ownership, raw ping payload routing, recursive zoom, unconditional default-mask writes, and hard-coded addon-folder media paths.
