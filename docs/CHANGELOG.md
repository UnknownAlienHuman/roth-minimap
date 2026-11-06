# Changelog

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
- Expanded offline stubs and regressions for callback-event ownership, secret payload opacity, hybrid/housing transitions, native-art restoration and fallback recovery.

## 0.4.2 — second ownership and lifecycle audit

- Removed the generic raw-payload event bus.
- Added complete pre-0.4 migration and in-place reset.
- Added ping-destination dropdown.
- Hardened combat deferral, draw order, pulse cleanup and documentation parity.

## 0.4.1 — Retail 12.1.5 contract update

- Updated Interface to `120105`.
- Fixed module clamp semantics, exact decorative ownership, hidden ticker cleanup and duplicate wheel zoom.
- Removed stale ButtonBag-era documentation and unused media.

## 0.4.0 — ownership rewrite

- Removed ButtonBag and AddonCompartment diagnostics.
- Returned native geometry/widgets/buttons to Blizzard/Edit Mode.
- Kept only additive mask, skin, opaque ping and bounded zoom behavior.
