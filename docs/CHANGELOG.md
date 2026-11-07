# Changelog

## 0.4.6 — mask ownership and migration verification

- Stopped unconditional default-mask writes when the addon starts disabled or the square-mask feature is unselected.
- Added transition-owned mask state: square application, selected native fallback, disable restore, and one world-entry revalidation.
- Added schema 8 to repair disabled border/rune layers whose previous migration also stored color alpha `0`.
- Legacy alpha `0` now maps to a disabled layer with a usable positive alpha, so the current checkbox can show it again.
- Propagated failures from geometry safe-state cleanup instead of silently returning success.
- Gated Settings refresh errors before formatting, matching the core ordinary-only error boundary.
- Synchronized fire combat state at point of use to avoid event-order-dependent transient combat cadence.
- Collapsed lifecycle refreshes received in combat directly into one pending state without zero-delay timer churn.
- Rescheduled a pending zoom reset only when its configured delay actually changes.
- Reworked the syntax gate to discover every Lua file recursively on Windows and POSIX hosts.
- Strengthened TGA validation with an exact media manifest and visible-alpha checks for every fire-atlas frame.
- Replaced the synthetic zoom test with an actual native-wheel-before-hook stub, proving one wheel step remains one native step.
- Added TOC path existence checks and mask-write-count regression coverage.
- Pinned the GitHub Actions runner image and checkout action; disabled persisted checkout credentials.

## 0.4.5 — media paths, alpha restoration and executable validation

- Derived bundled media paths from the actual addon folder name.
- Retained decorative alpha snapshots across temporarily inaccessible reads.
- Gated module return values and error formatting through ordinary-value checks.
- Made direct full apply cancel stale queued refresh work.
- Added per-file Lua syntax, static, runtime, and binary TGA validation in GitHub Actions.

## 0.4.4 — adaptive fire cadence and source continuity

- Split the old unified fire FPS into idle and combat cadences.
- New/reset defaults use 2 FPS idle smolder and 8 FPS combat fire.
- Schema 7 migrated pre-0.4 `outFPS`/`combatFPS` and schema-6 `fireFPS`.
- Updated source-review metadata to build `12.1.5.70783`.

## 0.4.3 — callback-event and native-mode hardening

- Registered secret `MINIMAP_PING` through `RegisterEventCallback`/`UnregisterEventCallback`.
- Added automatic native-presentation fallback for Blizzard Hybrid Minimap and indoor housing.
- Tuned new/reset defaults to a dark Diablo border and subtler vignette.

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
