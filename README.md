# Roth Minimap

Lightweight, event-driven minimap addon for WoW Midnight. It provides a square minimap, Diablo-inspired skin, ping notifications, mouse-wheel zoom with optional auto zoom-out, HUD overlay and a minimap button bag.

## Compatibility

- Interface: `120001`, `120005`
- Version: `0.3.11.29`
- Author: Neomorph (Roth UI Project)
- SavedVariables: `RothMinimapDB`

## Installation and usage

Copy `RothMinimap` into `World of Warcraft/_retail_/Interface/AddOns/`, enable it and reload the UI. Open settings through the AddOns settings panel or `/rmmap`. The documented commands include `/rmmap unlock`, `/rmmap lock`, `/rmmap scan` and `/rmmap reset`.

The older [`README.txt`](README.txt) is preserved. It describes the original v0.3.5 feature wording; the current version is taken from `RothMinimap.toc`.

## Development status

ButtonBag code and performance work is largely marked complete in [`todo.md`](todo.md). Current open validation is in [`docs/TODO.md`](docs/TODO.md): bag existence/coverage/one-window behavior, combat deferral, Blizzard widget bounds, settings scroll/persistence and visual polish. The repository intentionally includes replaceable TGA art; keep the documented texture-size contract in mind.

## License

No license declaration was inferred from the current tree.
