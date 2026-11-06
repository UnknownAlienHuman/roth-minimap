# Changelog

## 0.4.1 — Retail 12.1.5 contract update

- Updated Interface to `120105`; source-reviewed against Blizzard UI `12.1.5.70688`.
- Added `LoadSavedVariablesFirst` and schema 5 migration before Settings registration.
- Fixed `/rmmap reset` to preserve root and nested Settings table identities and notify registered controls.
- Fixed the exported clamp helper: module calls now use the intended `(value, minimum, maximum)` contract instead of forcing FPS/alpha/outset/durations to their maxima.
- Restricted Blizzard-art mutation to `MinimapCompassTexture` and `MinimapCluster.BorderTop`; removed the unsafe whole-`MinimapBackdrop` mutation.
- Removed unconfirmed mask-getter restoration and adopted a deterministic square/default mask policy.
- Parent addon skin/toast to `Minimap`; stop repeating/temporary work when the native surface is hidden.
- Removed guessed `140×140` geometry fallback; retain last accessible ordinary geometry instead.
- Coalesced Edit Mode geometry callbacks and removed the duplicate geometry update during full apply.
- Pre-create the ping toast outside combat, ignore the complete secret payload, and remove duplicate native ping sound playback/settings.
- Fixed wheel zoom: Blizzard now performs the only zoom step; Roth Minimap only observes it and owns one cancellable reset timer.
- Removed native mouse-wheel enablement ownership and hard-coded zoom ceiling.
- Isolated module apply failures while preserving visible error reporting.
- Added static Retail 12.1.5 contract tests and offline runtime stubs for migration, art ownership, one-step zoom, reset timing, and in-place DB reset.
- Removed stale ButtonBag-era README/TODO/animation/design notes.
- Removed about 5 MiB of unreferenced legacy char, alternate-fire, HUD-overlay, and shadow textures.

## 0.4.0 — ownership rewrite

- Removed ButtonBag and AddonCompartment diagnostics.
- Returned MinimapCluster geometry and every functional/native/third-party widget to Blizzard/Edit Mode ownership.
- Kept only additive mask, skin, opaque ping, and bounded zoom behavior.

## Historical versions

Pre-0.4 ButtonBag and experimental skin history remains available in Git history. It is intentionally omitted here because those subsystems are no longer loaded, supported, or valid implementation guidance.
