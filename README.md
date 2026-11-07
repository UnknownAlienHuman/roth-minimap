# Roth Minimap

A restrained Diablo-style minimap presentation for World of Warcraft Retail 12.1.5. Blizzard Edit Mode remains the sole owner of native position, size, input, widgets, Hybrid Minimap, housing overlays, and third-party buttons.

## Compatibility

- Retail / Midnight 12.1.5
- Interface `120105`
- Addon version `0.5.0`
- SavedVariables schema `9`
- Reviewed Blizzard live build `12.1.5.70783`
- Source pin `Gethe/wow-ui-source@297d7aaaa736f346b3e036f38ee088eaf7f8c07f`
- External dependencies: none
- In-client runtime matrix: **NOT-RUN**

## Visual direction

Version 0.5.0 replaces the flat stack of full-strength textures with one coherent composition:

```text
soft outer shadow
  -> low ember halo
  -> charred rim
  -> thin animated embers
  -> dark bronze frame + restrained highlight
  -> optional runes
  -> subtle inner vignette
```

The frame is deliberately quieter out of combat. The default `Obsidian Ember` preset uses thin flames, 5% idle ember alpha, 26% combat alpha, a smaller 28-pixel expansion, and no runes.

### Presets

- **Obsidian Ember** — dark bronze, low idle motion, controlled combat warmth; default.
- **Inferno** — stronger orange frame and fire without turning the minimap into a permanent alert.
- **Runebound** — visible amber runes with reduced fire so the layers do not compete.
- **Clean** — frame, charred depth, shadow, and light vignette; no animated fire or runes.
- **Custom** — selected automatically after any detailed appearance control is changed.

Selecting a named preset updates the detailed controls. Manual edits preserve their exact values and mark the result as `Custom`.

## Ownership

Use Blizzard **Edit Mode** to position and size the minimap. Roth Minimap does not store or replace native points, parent, scale, scripts, state drivers, or child layout.

`Hide decorative Blizzard border art` changes alpha only on:

- `MinimapCompassTexture`;
- `MinimapCluster.BorderTop`.

`MinimapBackdrop` is untouched because it owns housing and expansion UI descendants. Original accessible alpha values are retained until restoration resolves safely.

## Mask policy

Roth Minimap writes the square mask only while that feature is selected. Starting disabled or with `Square minimap mask` off leaves an existing third-party mask untouched.

After Roth Minimap has applied its square mask, disabling it restores the selected-build native default. Exact restoration of an arbitrary foreign mask is not claimed because the selected public Minimap API exposes `SetMaskTexture`, but no exact `GetMaskTexture` contract.

## Native fallback

While Blizzard Hybrid Minimap or indoor housing presentation is active, the addon:

- applies the known native minimap mask only when Roth square mode owns the transition;
- restores exact decorative alpha values hidden by Roth Minimap;
- hides only addon-owned frame regions;
- leaves the fixed ping notification and bounded zoom reset available.

## Performance

The layered design adds static textures, not extra polling:

- one thin 4×4 fire-atlas ticker;
- idle default 2 FPS, configurable 1–8;
- combat default 8 FPS, configurable 1–20;
- no ticker when fire alpha is zero, the skin is hidden, or native fallback is active;
- no `OnUpdate`, frame-tree scanning, retry loops, or recurring object creation.

## Ping

`MINIMAP_PING` is registered through `Frame:RegisterEventCallback`. All secret payload arguments are ignored. A compact, clamped toast displays only fixed ordinary text:

```text
Map ping received
```

Blizzard retains native ping-sound ownership.

## Zoom

Blizzard performs the only wheel zoom step. Roth Minimap observes the completed native input and owns at most one cancellable timer that resets zoom to level `0`.

## Commands

```text
/rmmap
/rmmap config
/rmmap toggle
/rmmap reset
/rmmap status
```

`/rmmap status` includes the current visual preset and native-presentation reason.

## Validation

```text
texlua tests/test_syntax.lua
texlua tests/test_contracts_12_1_5.lua
texlua tests/test_runtime_stubs.lua
python3 tests/test_media.py
```

Run these gates locally before publishing. Offline coverage includes schema-9 preset migration, Settings identity, layered texture selection, zero-alpha ticker suppression, secret ping opacity, mask ownership, native fallback, combat deferral, native wheel behavior, and exact TGA manifest/frame validation.

Live testing is still required for actual client rendering, Edit Mode profiles, Hybrid Minimap/housing presentation, atlas alignment, taint capture, logout persistence, and `C_AddOnProfiler` measurements.

## Developer documentation

- [Architecture](ARCHITECTURE.md)
- [Agent guide](AGENT_GUIDE.md)
- [Code index](CODE_INDEX.md)
- [Code graph](CODE_GRAPH.md)
- [Changelog](docs/CHANGELOG.md)
- [WoW addon engineering knowledge base](https://github.com/UnknownAlienHuman/wow-addon-engineering-kb)

## License

MIT.
