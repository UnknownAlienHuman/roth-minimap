# Changelog

## 0.4.2 — second-pass Retail 12.1.5 audit

- Replaced the shared raw-payload event bus with direct feature-owned native event frames.
- Added a complete schema-6 migration for pre-0.4 `square`, `skinEnabled`, `visual`, `fire`, ping, and zoom preferences.
- Preserved SavedVariables root/nested identities for both migration and reset.
- Prevented Settings reset from triggering one full addon apply per notified control.
- Restored the missing ping destination control (`toast` / `chat`).
- Synchronized the skin to native Minimap strata/level instead of forcing `HIGH` / frame level `300` above Blizzard widgets.
- Added deterministic pulse cleanup on animation stop, finish, hide, and disable.
- Stopped/hid fire immediately when the owned feature is disabled during a deferred combat apply.
- Coalesced world/Edit Mode/UI-scale refreshes and skipped geometry creation while the addon/skin is disabled.
- Improved decorative alpha ownership: require an ordinary snapshot, preserve a newer ordinary alpha, and restore only the addon-applied hidden state.
- Kept a pending zoom reset across unrelated settings applies; cancel it on world transition, combat, native hide, or disable.
- Expanded offline tests to cover legacy/current migration, secret ping tuples, native draw order, ticker/pulse cleanup, combat deferral, refresh coalescing, and single-apply reset.

## 0.4.1 — initial Retail 12.1.5 update

- Updated Interface to `120105` and selected source baseline to `12.1.5.70688`.
- Removed whole-`MinimapBackdrop` mutation, duplicate wheel zoom, duplicate ping sound, hard-coded zoom ceiling, guessed geometry fallback, and stale ButtonBag-era files/assets.
- Added deterministic mask policy, exact decorative allowlist, native-wheel reset, and initial static/offline tests.

## 0.4.0 — ownership rewrite

- Removed ButtonBag and AddonCompartment diagnostics.
- Returned MinimapCluster geometry and every functional/native/third-party widget to Blizzard/Edit Mode ownership.
- Kept only additive mask, skin, opaque ping, and bounded zoom-reset behavior.

Pre-0.4 experimental history remains available in Git history and is not valid current implementation guidance.
