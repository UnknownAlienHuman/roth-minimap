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

Obsidian Ember is one composition, not a pile of equally strong effects:

```text
soft outer shadow
  -> masked ember halo
  -> charred material rim
  -> masked thin embers
  -> dark bronze frame + restrained highlight
  -> optional runes
  -> subtle inner vignette
```

The default preset uses thin flames, 5% idle ember alpha, 26% combat alpha, a 28-pixel reference expansion, and no runes. Shadow, char, highlight, and pulse strengths are deliberately bounded so the map remains the focal surface.

### Motion hierarchy

Motion now communicates state instead of running continuously at a choppy low frame rate:

- **out of combat:** one selected atlas frame uses a slow repeating alpha breath in an `AnimationGroup`; no Lua atlas ticker runs;
- **in combat:** the breath stops and one bounded 4×4 atlas ticker starts at the selected combat FPS;
- **ping:** one short, masked pulse; no gameplay payload is read;
- **hidden, disabled, or native fallback:** all owned motion stops.

The ember atlas contains nonzero center alpha, so fire, halo, and pulse are clipped by one addon-owned mask derived from the charred-rim asset. The map center is not tinted by the decorative effects.

### Responsive geometry

`Frame expansion` is authored against Blizzard's 198-pixel reference minimap. Runtime scales that expansion and shadow padding proportionally with the accessible Edit Mode minimap size. A small minimap does not acquire an oversized frame, and a large minimap does not get a thin, undersized rim.

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

All masks used by the visual frame are addon-created and apply only to addon-created textures. No native or third-party region is adopted or masked.

## Mask policy

Roth Minimap writes the native square map mask only while that feature is selected. Starting disabled or with `Square minimap mask` off leaves an existing third-party mask untouched.

After Roth Minimap has applied its square mask, disabling it restores the selected-build native default. Exact restoration of an arbitrary foreign mask is not claimed because the selected public Minimap API exposes `SetMaskTexture`, but no exact `GetMaskTexture` contract.

## Native fallback

While Blizzard Hybrid Minimap or indoor housing presentation is active, the addon:

- applies the known native minimap mask only when Roth square mode owns the transition;
- restores exact decorative alpha values hidden by Roth Minimap;
- hides only addon-owned frame regions;
- stops addon-owned animation;
- leaves the fixed ping notification and bounded zoom reset available.

## Performance

- no idle Lua atlas ticker;
- one combat-only ticker, configurable from 1–20 FPS;
- one C-level idle alpha animation, controlled by `Idle ember motion speed`;
- no ticker or breath when ember alpha is zero, the frame is hidden, or native fallback is active;
- no `OnUpdate`, frame-tree scanning, retry loops, or recurring region creation;
- geometry is recalculated only on explicit settings or confirmed lifecycle signals.

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

Offline coverage includes schema-9 preset migration, Settings identity, texture order, owned mask attachment, idle/combat motion transitions, proportional geometry at multiple Edit Mode sizes, secret ping opacity, native mask ownership, native fallback, combat deferral, native wheel behavior, and exact TGA geometry reports.

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
