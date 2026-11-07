# Changelog

## 0.4.5 — validation and access hardening

- Derive bundled media paths from the actual `ADDON_NAME` instead of assuming the installation folder is exactly `RothMinimap`.
- Preserve decorative-alpha snapshots when `GetAlpha()` is temporarily inaccessible; retry restoration on a later full apply instead of silently forgetting the original value.
- Gate SavedVariables default replacement before inspecting inaccessible values.
- Require module return statuses to be accessible booleans or `nil`; reject inaccessible/non-boolean results.
- Stop formatting inaccessible error objects; error reporting now uses an accessible string or a fixed placeholder.
- Make an explicit full apply cancel and supersede queued lifecycle refresh work, including combat-deferred transitions.
- Replace the misleading multi-file `texlua --luaconly` command with `tests/test_syntax.lua`, which compiles each Lua file separately.
- Add TGA validation for dimensions, true-color/alpha format, square-mask shape, and 4×4 fire-atlas structure.
- Add GitHub Actions validation for syntax, static contracts, offline runtime behavior, and media structure.
- Expand runtime stubs for inaccessible alpha, error capture, renamed addon folders, refresh supersession, and inaccessible module returns.

## 0.4.4 — adaptive fire cadence and source continuity

- Split the old unified fire FPS into idle and combat cadences.
- New/reset defaults use 2 FPS idle smolder and 8 FPS combat fire.
- Schema 7 migrates pre-0.4 `outFPS`/`combatFPS` and schema-6 `fireFPS`; existing explicit schema-7 values remain unchanged.
- The ticker restarts only when combat state selects a different configured interval.
- Verified the complete `12.1.5.70688 → 12.1.5.70783` live-source delta; it contains no Minimap, Settings, Frame callback, XML, or TOC contract changes.
- Updated source-review metadata to build `12.1.5.70783`.

## 0.4.3 — callback-event and native-mode hardening

- Registered secret `MINIMAP_PING` through `RegisterEventCallback`/`UnregisterEventCallback` instead of raw frame-event registration.
- Added automatic native-presentation fallback for Blizzard Hybrid Minimap and indoor housing.
- Native fallback restores the default mask and exact decorative alpha, hides only addon-owned skin regions, and never mutates foreign MapCanvas masks or housing overlays.
- Added the active native mode to `/rmmap status`.
- Tuned new/reset defaults to a dark Diablo border and subtler `0.22` vignette; existing valid user values are preserved.
- Expanded offline stubs and regressions for callback-event ownership, secret payload opacity, hybrid/housing transitions, native-art restoration, and fallback recovery.

## 0.4.2 — second ownership and lifecycle audit

- Removed the generic raw-payload event bus.
- Added complete pre-0.4 migration and in-place reset.
- Added ping-destination dropdown.
- Hardened combat deferral, draw order, pulse cleanup, and documentation parity.

## 0.4.1 — Retail 12.1.5 contract update

- Updated Interface to `120105`.
- Fixed module clamp semantics, exact decorative ownership, hidden ticker cleanup, and duplicate wheel zoom.
- Removed stale ButtonBag-era documentation and unused media.

## 0.4.0 — ownership rewrite

- Removed ButtonBag and AddonCompartment diagnostics.
- Returned native geometry/widgets/buttons to Blizzard/Edit Mode.
- Kept only additive mask, skin, opaque ping, and bounded zoom behavior.
