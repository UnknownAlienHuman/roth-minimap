# Roth Minimap agent guide

## Contract

Target Retail 12.1.5 / Interface `120105`. Addon version `0.4.6`, schema `8`, reviewed Blizzard live source `12.1.5.70783` at `Gethe/wow-ui-source@297d7aaaa736f346b3e036f38ee088eaf7f8c07f`.

Blizzard/Edit Mode owns `MinimapCluster`, native input, native widget topology, Hybrid Minimap, housing overlays, and third-party buttons. Roth Minimap owns only its DB, transition-scoped Minimap mask policy, exact decorative-alpha mutations, and addon-created skin/ping/reset objects.

## Never restore

```text
ButtonBag or generic minimap-button collector
frame-tree discovery
foreign SetParent / SetPoint / ClearAllPoints
foreign method replacement
native Minimap/MinimapCluster geometry ownership
MinimapBackdrop alpha/visibility mutation
raw RegisterEvent for CallbackEvent MINIMAP_PING
MINIMAP_PING payload inspection
second wheel zoom step
EnableMouseWheel ownership
recursive or uncancellable timers
foreign HybridMinimap mask mutation
foreign housing overlay mutation
hard-coded addon-folder media paths
```

## Media root

Build bundled texture paths from the `ADDON_NAME` supplied through `...`. Do not assume the installation folder is exactly `RothMinimap`.

## Mask ownership

The selected Minimap API documents `SetMaskTexture`, not an exact `GetMaskTexture` restoration contract.

- If Roth starts disabled or square-mask is off, do not write a default mask.
- Applying the square mask establishes one runtime ownership transition.
- Leaving square mode restores the selected-build native default.
- Native Hybrid/housing fallback applies the known default only when Roth's square feature is selected.
- Revalidate once on `PLAYER_ENTERING_WORLD`; do not rewrite on unrelated Settings applies.
- Never claim restoration of an arbitrary foreign mask.

## Native fallback

`C_Minimap.ShouldUseHybridMinimap()` and `C_Housing.IsInsideHouse()` are read-only mode gates. When either is true, restore addon-owned decoration, hide addon-created skin regions, and leave foreign MapCanvas masks/housing descendants untouched.

## Decorative alpha

Retain an alpha snapshot until restoration succeeds or another owner has already replaced the hidden value. If `GetAlpha()` is temporarily inaccessible, return failure and keep the snapshot for a later full apply.

## Ping

`MINIMAP_PING` is `CallbackEvent = true`, `SecretPayloads = true`. Register it with `Frame:RegisterEventCallback`; unregister with `Frame:UnregisterEventCallback`. Ignore every payload argument.

Module return values, core errors, and Settings refresh errors are ordinary-only. Gate a returned value before comparison, and never `tostring` an inaccessible error object.

## Persistence

`## LoadSavedVariablesFirst: 1` allows one file-scope migration before Settings registration. Preserve root and nested Settings tables on reset.

Schema 8 retains valid schema-7 values and repairs disabled border/rune layers whose migrated color alpha was `0`, so later checkbox enablement is visible. Pre-0.4 alpha `0` maps to a disabled layer plus a usable default alpha.

## Lifecycle and performance

One visible-only fire ticker with point-of-use idle/combat cadence, one zoom timer, and one coalesced refresh timer maximum. Combat lifecycle bursts update pending flags directly and create no zero-delay timers. A direct full apply supersedes queued refresh work. No `OnUpdate`, polling, tree scans, per-event timer fan-out, or retry loops.

## Verification

```text
texlua tests/test_syntax.lua
texlua tests/test_contracts_12_1_5.lua
texlua tests/test_runtime_stubs.lua
python3 tests/test_media.py
```

`test_syntax.lua` discovers Lua files recursively. GitHub Actions uses a commit-pinned checkout action with persisted credentials disabled.

Do not label source/offline checks as live runtime PASS.
