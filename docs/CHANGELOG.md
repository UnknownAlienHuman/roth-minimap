# Changelog

## 0.5.0 — Obsidian Ember visual redesign

- Replaced the flat visual stack with a deliberate depth hierarchy: soft shadow, bounded ember halo, charred rim, thin fire, dark frame/highlight, optional runes, and inner vignette.
- Added four coherent presets: `Obsidian Ember`, `Inferno`, `Runebound`, and `Clean`; detailed edits automatically become `Custom`.
- Added schema 9. Exact 0.4.6 defaults upgrade to the new default preset; detected custom appearances are preserved unchanged.
- Replaced the normal fire atlas with the thinner atlas and restored the charred-rim texture as an intentional runtime asset.
- Reduced new/reset idle fire alpha from `0.14` to `0.05`, combat alpha from `0.42` to `0.26`, vignette from `0.22` to `0.16`, and frame expansion from `34` to `28`.
- Suppressed the fire ticker when the selected fire alpha is zero.
- Reworked the ping toast into a compact, clamped, palette-aware notification that follows native Minimap draw order.
- Expanded offline tests for preset application, automatic custom-state transitions, layered texture order, schema-9 migration, and compact toast behavior.

## 0.4.6 — ownership and migration closure

- Prevented disabled/unselected square-mask mode from overwriting a third-party mask.
- Added transition-owned mask writes and world-entry revalidation.
- Added schema 8 repair for zero-alpha disabled border/rune migrations.
- Removed combat-time lifecycle timer creation and synchronized fire cadence with actual combat lockdown.
- Hardened syntax discovery, exact media manifests, native-wheel tests, and pinned read-only CI.

## 0.4.5 — media and validation hardening

- Derived media paths from the actual addon name.
- Retained decorative-alpha snapshots across temporarily inaccessible reads.
- Added executable Lua, runtime, static, and binary TGA validation in GitHub Actions.

## 0.4.4 — adaptive fire cadence

- Split idle and combat fire FPS.
- Updated selected Blizzard source to `12.1.5.70783`.

## 0.4.3 — callback event and native fallback

- Moved secret `MINIMAP_PING` to the callback-event API.
- Added Hybrid Minimap and indoor-housing fallback.

## 0.4.2 — ownership and lifecycle audit

- Removed the generic event bus.
- Added complete pre-0.4 migration, in-place reset, and Settings callback suppression.

## 0.4.1 — Retail 12.1.5 update

- Updated Interface metadata and fixed clamp, ticker, art ownership, and duplicate-wheel defects.

## 0.4.0 — ownership rewrite

- Removed ButtonBag and native widget/layout ownership.
- Kept only additive mask, skin, opaque ping, and bounded zoom behavior.
