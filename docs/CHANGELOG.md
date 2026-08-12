## 0.3.11.29

- ButtonBag: filtered Blizzard minimap widget subtrees (tracking/indicator/mail/crafting internals) to prevent accidental adoption of system buttons.
- ButtonBag: removed repeated forced warmup rescans from every `Apply()`; warmup scans now run once per enable-cycle and global fallback stays disabled while bag is closed.
- ButtonBag: combat flush now respects `stashWhenClosed=false` (no delayed re-stashing of closed bag buttons).
- Minimap core: hide-art path now preserves anchor-family for structural frames; widget layout is idempotent and no longer re-parents zone/clock/difficulty every apply.
- Minimap core: AddonCompartment placement/restore logic hardened when toggling `hideBlizzardArt` and `hideAddonCompartment`.
- Options: fixed Skin/FX fire section anchor chain (controls after atlas preset no longer overlap) and hardened panel rebuild retries.
- Skin FX: added low-health hysteresis to reduce flicker near threshold.

## 0.3.11.27

- Settings: harden Settings UI panel build (template fallbacks, late-register on Blizzard_Settings load, and retry on SettingsPanel show). This fixes "empty" settings categories on some clients.

## 0.3.11.26
- Fix: ButtonBag: proxy button skinning no longer calls `SetNormalTexture(nil)` (can error on WoW 12.x). Clears state textures via existing texture objects instead.

## 0.3.11.25

- Shadow (Material): drop shadow now renders **behind** the minimap (no longer overlays/darkens map content); added a subtle mask-clipped inner seam fade to blend the rim into the map.
- Skin: reduced default skin padding (10 → 6) with a migration for users still on the old default.

## 0.3.11.20

- ButtonBag: fixed proxy icons showing as identical bag/backpack art by **dropping the Blizzard zoom/backpack normal textures** on proxies and rendering a neutral round border + background.
- ButtonBag: snapshot addon icon textures **before parking originals**; proxies now render from the snapshot to avoid LibDBIcon skin mutations when buttons are hidden/off-parent.
- ButtonBag: parked originals are now kept shown at normal alpha/scale offscreen (mouse-disabled) to reduce addon heuristics that treat the button as disabled/hidden.
- Shadow: narrowed + smoothed default “material” rim (`alpha=0.22`, `thickness=3`) with a targeted migration from known prior defaults.

## 0.3.11.19

- ButtonBag: fixed proxy icons still appearing as blank squares by **stopping draw-layer rewrites** (they could push the icon behind the button's normal texture) and by rendering the proxy icon on the **OVERLAY** layer.
- ButtonBag: proxy buttons now use the Blizzard minimap button ring style to avoid square placeholders from addon-provided normal textures.

## 0.3.11.18

- ButtonBag: fixed proxy icons rendering as empty squares by removing `rawget()` access on frame userdata and by supporting both `GetTexture()` and `GetAtlas()` sources.
- ButtonBag: proxies now refresh their icon texture on every bag layout pass (handles addons that set the icon late).
- Shadow: tuned "material" falloff to appear narrower and smoother at the same thickness (lower shoulder alpha + narrower inner density); adjusted fallback defaults (`alpha=0.24`, `thickness=3`).

## 0.3.11.15

- ButtonBag: fixed stashed LibDBIcon buttons appearing **dim / non-interactive** by forcing enabled visuals (und-desaturate + reset texture alpha) and raising strata/levels inside the bag.
- ButtonBag: improved bag window screen clamping (multi-pass after show) to avoid partial off-screen opens.
- Shadow: narrower + smoother “Material” rim by default; corrected gradient orientation on all sides and implemented a two-layer falloff (outer soft + inner dense).
- Options: reduced the Shadow thickness slider max to 24px (discourages overly wide rims).

## 0.3.11.13

- AddonCompartment: added a safe investigation/dump module (debug-only auto dump on login + `/rm comp` manual dump) to identify Blizzard data structures without taint or secret-value crashes.

## 0.3.11.12

- Shadow: fallbacks now match shipped defaults (`alpha=0.35`, `thickness=10`) to prevent “old rim” visuals when DB fields are missing/partial.
- Shadow: stronger inner seam lines at the minimap edge (2px, higher alpha) to reduce residual bright/white rims.
- Skin: padding fallback aligned with shipped default (`skinPadding=10`) to avoid subtle alignment drift.

## 0.3.11.11

- Settings: responsive layout (no hardcoded widths) for subtitles, notes, sliders, edit boxes and helper buttons.
- Settings: added “Hide addon compartment button” toggle to the General category.

## 0.3.11.10

- ButtonBag: enforced **LibDBIcon-only** collection (only `LibDBIcon10_*` frames).
- Settings: “Collect only LibDBIcon buttons” is now forced ON (disabled control).
- MinimapCluster: added `hideAddonCompartment` (default ON) + `applyAddonCompartment()` to prevent bounds bloating.
- Defaults: shadow tuned to a thinner rim (`alpha=0.35`, `thickness=10`) with targeted migration from older defaults.

## 0.3.11.9

- ButtonBag: avoid adopting minimap POI/content markers (filter ScrollContainer + unnamed minimap children).
- Shadow: flipped edge gradient (black toward minimap, fade outward).

## 0.3.11.8
- ButtonBag: combat safety: `SetParent/ClearAllPoints/SetPoint` are now avoided entirely in combat; changes are queued and flushed after combat.
- ButtonBag: rescan performance: global fallback scan is backoff-throttled (max once per 5 seconds) while the bag is open.
- ButtonBag: layout performance: sorted list is cached by signature to reduce repeated `table.sort` calls.
- ButtonBag: UX: exclusions are split into exact-name list + substring list; Settings adds “Add hovered button” helper.
- Settings: scroll panels now auto-size scroll child height based on actual content.
- Skin: border color preset dropdown (Dark / Parchment / White / Custom).

## 0.3.11.6
- Fix: ButtonBag: removed invalid Lua syntax (`local ok, ... =`) in `safeGetRegions()` that prevented the addon from loading.
- Fix: Skin: shadow frame now expands by `thickness*2`, so the edge shadow is actually visible outside the minimap border.
- Tuning: Defaults/migration: border color is no longer pure white by default; shadow alpha/thickness increased for a clearer drop-shadow.

## 0.3.11.5
- Fix: ButtonBag: global fallback scan now uses safe method wrappers (prevents "bad self" errors from mixins/tables in `_G`).
- Fix: ButtonBag: texture detection now reads **all** regions via a protected vararg call to `GetRegions()` (previously only first return value was checked), significantly improving candidate detection.
- Tuning: ButtonBag: force rescan uses deeper tree scan depth (4) to catch buttons nested in containers.

## 0.3.11.4
- Fix: Button bag global fallback scan no longer errors on non-UI globals (e.g. functions), preventing aborted scans.
- Fix: Button bag candidate detection now accepts UIObjects that are `userdata` on some builds.
- Fix: Settings panels: anchor scroll child content to prevent widgets drifting left outside the panel.

## 0.3.11.3
- Button bag: full clean-room rewrite of scanning + layout to avoid "empty bag" issues; deeper tree scan (Minimap/Cluster/collectors) and optional global fallback when the bag is open.
- Button bag: bag button now copies Blizzard minimap zoom button art when available (round style), anchored bottom-left of the minimap.
- Media: replaced legacy `diablo_border.tga` / `diablo_runes.tga` with new schematic placeholders `RM_DIABLO_BORDER_512.tga` / `RM_DIABLO_RUNES_512.tga`.

## 0.3.11.23
- Fix: ButtonBag: candidate detection now accepts minimap icon Frames (not only Buttons) when they have click-ish handlers (prevents empty bag on some addons).
- Fix: ButtonBag: proxy click forwarding prefers :Click() and falls back to OnClick/OnMouseUp/OnMouseDown scripts for non-Button icons.
- Debug: ButtonBag rescan summary now prints seen/candidates/adopted counts + top reject reasons (debug mode).
- Filter: exclude AddonCompartmentFrame from adoption to avoid duplicates.

## 0.3.11.24
- Shadow: added MATERIAL (corner-safe) drop shadow using `RM_VIGNETTE_SQUARE_512.tga` (2-layer ambient+key with subtle Y offset).
- Shadow: added style selector (MATERIAL vs EDGE) and renamed thickness slider to Shadow elevation.
- Shadow: elevation 0 disables shadow output.

## 0.3.11.21
- ButtonBag: default collection mode now includes non-LibDBIcon minimap buttons (strict LibDBIcon-only remains optional).
- ButtonBag: rescan covers Minimap/MinimapCluster children in addition to LibDBIcon registry; added /rmb dump debug helper.
- Migration: disable forced LibDBIcon-only mode introduced in earlier stages (prevents silent "empty bag" regressions).

## 0.3.11.0
- Replaced all media with schematic sprite placeholders (512-only) for testing.
- Fixed shadow edge SetTexCoord mapping.
- Default fire preset set to HOLE_THIN (delicate).

## 0.3.10.3
- Fire textures: keep **ORIGINAL** atlases intact and add non-destructive **HOLE** presets (thin/normal/thick) at 512/1024/2048.
- Options: added Fire atlas size + hole preset selectors (Blizzard Settings).
- Fix: zone text anchor when hiding Blizzard minimap art (kept inside minimap bounds).
- Fix: ButtonBag bag button now parents to MinimapCluster (not masked/clipped), uses in-game bag icon.
- Fix: Options slider value formatting handles string format patterns.


## 0.3.10.2
- Fire atlas repack: added RAW 2048 TGA and new 1024 atlas; fixed prior over-masked atlas.
- Added docs/TODO.md.
# RothMinimap 0.3.10.1

- Fix: Skin module initialization order (charred edge no longer referenced before creation).
- Fix: Hide Blizzard MinimapBackdrop ring when `hideBlizzardArt` is enabled (removes stray circular ring).
- Fix: Button bag now scans Leatrix Plus combined frame buttons directly to avoid nested-bag behavior.
- Tuning: Diablo fire defaults adjusted to a more subtle "smolder" (lower alpha/FPS) with controlled combat intensity.

# RothMinimap 0.3.10.0

- Diablo Fire: switched to a single 2048 atlas (16 frames) and animates via TexCoord (no per-frame SetTexture calls).
- Diablo Fire: added optional “Charred edge” layer under the fire (RM_DIABLO_CHAR_512).
- Diablo Glow/Vignette: updated Diablo glow + inner vignette textures (RM_DIABLO_FIRE_GLOW_512 / RM_VIGNETTE_SQUARE_512).
- Settings: added “Layers” section (border/runes/glow/char/vignette alpha toggles) under Skin & FX.

# RothMinimap 0.3.9.3

- Fix: Re-anchor zone text and difficulty badges when hiding Blizzard minimap art.
- Fix: Button bag scanning now accepts attribute-driven buttons (no OnClick script) and scans common naming patterns.
- UX: Settings split into Blizzard Settings subcategories (General / Skin & FX / Buttons / Ping & Zoom).
