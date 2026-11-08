# Roth Minimap agent guide

## Contract

Target Retail 12.1.5 / Interface `120105`. Addon version `0.5.0`, schema `9`, reviewed source `12.1.5.70783` at `Gethe/wow-ui-source@297d7aaaa736f346b3e036f38ee088eaf7f8c07f`.

Blizzard/Edit Mode owns native geometry, input, widget topology, Hybrid Minimap, housing overlays, and third-party buttons. Roth Minimap owns only its ordinary DB, transition-scoped map-mask policy, exact decorative-alpha snapshots, and addon-created presentation/timers.

## Visual contract

The default design is `Obsidian Ember`:

```text
shadow -> ember halo -> charred rim -> thin fire -> frame/highlight -> optional runes -> vignette
```

Keep the hierarchy restrained. The map remains dominant; shadow, char, highlight, fire, and pulse are supporting layers.

Motion has one semantic split:

```text
idle   -> fixed atlas frame + slow repeating alpha AnimationGroup
combat -> one bounded atlas ticker
```

Do not reintroduce an idle Lua ticker or make decorative effects react to secret gameplay state. Stop all owned motion when hidden, disabled, at zero alpha, or in native fallback.

`outset` is authored at the selected-build 198-pixel Minimap size and scales proportionally with accessible Edit Mode geometry. Never return to a fixed-pixel frame ratio across all sizes.

Named presets write explicit values. Detailed appearance edits must mark the preset `custom`; they must not be silently overwritten on reload.

## Evidence before mechanisms

The fire file is a 4×4 atlas. Inspect each displayed tile, not whole-file coordinates. Current per-frame validation proves every frame center is transparent, so no additional effect mask is justified. Do not add masks, clipping layers, or compensating geometry without a demonstrated rendering defect.

## Never restore

```text
ButtonBag or generic minimap-button collection
frame-tree discovery
foreign SetParent / SetPoint / ClearAllPoints
foreign method replacement
native Minimap/MinimapCluster geometry ownership
MinimapBackdrop alpha/visibility mutation
raw RegisterEvent for MINIMAP_PING
MINIMAP_PING payload inspection
second wheel zoom step
EnableMouseWheel ownership
recursive or uncancellable timers
foreign HybridMinimap/housing mutation
hard-coded addon-folder media paths
idle Lua atlas ticker
unproven runtime effect mask
extra polling for visual effects
```

## Persistence

`LoadSavedVariablesFirst` permits migration before Settings registration. Preserve root and nested table identities. Schema 9 upgrades the exact 0.4.6 default appearance to `Obsidian Ember`; any differing values become `custom` and remain unchanged.

## Media

Runtime uses:

- `RM_DIABLO_BORDER_512.tga`;
- `RM_DIABLO_CHAR_512.tga`;
- `RM_DIABLO_RUNES_512.tga`;
- `RM_DIABLO_FIRE_GLOW_512.tga`;
- `RM_DIABLO_FIRE_ATLAS_512_HOLE_THIN.tga`;
- `RM_VIGNETTE_SQUARE_512.tga`;
- `mask_square.tga`.

Do not add unused variants. Update the exact media-manifest test with every intentional asset change.

## Verification

```text
texlua tests/test_syntax.lua
texlua tests/test_contracts_12_1_5.lua
texlua tests/test_runtime_stubs.lua
python3 tests/test_media.py
```

Do not label source/offline checks as live-client PASS.
