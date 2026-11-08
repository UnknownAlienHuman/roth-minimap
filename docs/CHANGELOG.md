# Changelog

## 0.5.0 — Obsidian Ember visual redesign

- Replaced the flat visual stack with a deliberate depth hierarchy: soft shadow, bounded ember halo, charred rim, thin fire, dark frame/highlight, optional runes, and inner vignette.
- Added four coherent presets: `Obsidian Ember`, `Inferno`, `Runebound`, and `Clean`; detailed edits automatically become `Custom`.
- Added schema 9. Exact 0.4.6 defaults upgrade to the new default preset; detected custom appearances are preserved unchanged.
- Replaced the normal fire atlas with the thinner atlas and restored the charred-rim texture as an intentional runtime asset.
- Reduced new/reset idle fire alpha from `0.14` to `0.05`, combat alpha from `0.42` to `0.26`, vignette from `0.22` to `0.16`, and frame expansion from `34` to `28`.
- Reworked the ping toast into a compact, clamped, palette-aware notification that follows native Minimap draw order.

### Second-pass design refinement

- Replaced the permanently running 2 FPS idle atlas with one fixed representative frame and a slow repeating C-level alpha breath. The Lua atlas ticker now exists only in combat.
- Made authored frame expansion and shadow padding proportional to the accessible Edit Mode minimap size, using the selected-build 198-pixel minimap as the reference.
- Reduced shadow, charred material, frame-highlight, and event-pulse strength so the map remains visually dominant.
- Derived ember, halo, pulse, and char tones from the active accent/frame palette instead of using one hard-coded pale-orange tint.
- Added per-frame atlas diagnostics. They proved all 16 displayed frame centers are transparent; a proposed runtime effect mask was removed rather than shipping unnecessary clipping logic.
- Added runtime coverage for idle/combat motion transitions and proportional geometry at 99, 198, and 297 pixels.
- Extended media diagnostics with whole-asset alpha bounds plus per-frame visible/strong/mean/center metrics.

## 0.4.6 — ownership and migration closure

- Prevented disabled/unselected square-mask mode from overwriting a third-party mask.
- Added transition-owned mask writes and world-entry revalidation.
- Added schema 8 repair for zero-alpha disabled border/rune migrations.
- Removed combat-time lifecycle timer creation and synchronized fire cadence with actual combat lockdown.
- Hardened syntax discovery, exact media manifests, native-wheel tests, and local validation.

## 0.4.5 — media and validation hardening

- Derived media paths from the actual addon name.
- Retained decorative-alpha snapshots across temporarily inaccessible reads.
- Added executable Lua, runtime, static, and binary TGA validation scripts.

## 0.4.4 — adaptive fire cadence

- Split idle and combat fire settings.
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
