# RothMinimap - TODO + Specs (living document)

This file is the **single source of truth** for what remains, why it matters, and how to replace placeholder art with final Diablo-quality graphics without breaking performance or turning textures into multi‑MB monsters.

---

## P0 - Must fix (user-visible breakage)

### Minimap Button Bag
- [ ] Verify the bag **always exists** at the minimap bottom-left when `Buttons -> Enable button bag` is on.
- [ ] Verify the bag actually collects buttons from:
  - LibDBIcon (`LibDBIcon10_*`) addons
  - buttons parented to `Minimap` and `MinimapCluster`
  - Leatrix combined frame (if present)
  - buttons moved by other collectors (best effort via throttled global scan when the bag is open)
- [ ] Verify **ONE window only**: no nested bag(s) and no “bag inside bag” edge cases.
- [ ] Combat behavior:
  - Do not reparent/hide protected/forbidden frames; do not move anything in combat.
  - If buttons appear during combat, mark `pendingStash` and stash them **after combat**.

### Blizzard widgets when Blizzard art is hidden
- [ ] When `General -> Hide Blizzard minimap art` is ON, confirm the following stay inside the minimap bounds and do not drift off-screen:
  - ZoneTextButton
  - Clock (TimeManagerClockButton)
  - Difficulty badges (Instance/Guild/Challenge)

---

## P1 - Visual quality / immersion

### Diablo “burning parchment” composition
Target look: **square map** that feels embedded in UI, with **thin, controlled flame** (not filling the screen).

Layers (bottom -> top), how they should feel:
1) **Inner vignette** (dark gradient on the inside edge) → makes the map look deep/embedded.
2) **Charred rim** (burnt paper edge) → subtle, adds realism.
3) **Border** (thin frame) → defines the silhouette, supports recolor.
4) **Runes** (ornamental) → optional, faint when idle, stronger in combat.
5) **Glow** (soft halo) → very faint idle, stronger in combat/joy.
6) **Fire atlas** (animated edge flame) → idle: smolder; combat: ignite; events: quick pulses.

---

## P2 - UX / features

- [ ] Minimap panning inside frame (drag-to-pan):
  - Goal: hold a modifier (e.g. ALT) and drag inside the minimap to pan within the zone view.
  - Constraints: avoid taint; clamp so you cannot pan outside the rendered minimap area.
  - Note: this may not be feasible if the engine does not expose a safe pan transform for Minimap; if blocked, implement as a “camera offset” illusion on overlay layers only.

- [ ] Settings UX: keep Blizzard Settings layout clean and aligned; if new groups are added, split into more subcategories.

---

## Texture contract (IMPORTANT)

### No GIF support in WoW
WoW UI does **not** support GIF playback for textures. Animated skins must be implemented as:
- **Sprite sheet / atlas** (one texture containing multiple frames), animated by changing **TexCoord** to show a different frame.
- Optional additional breathing via **AnimationGroup** that modulates alpha/scale.

### Size / format rules
**Hard rule for shipping:**
- Max texture size: **512×512** for all shipped placeholders.
- File format: **TGA (32-bit)** with alpha (or BLP if we later build a pipeline; for now keep TGA).
- Power-of-two sizes only: 64/128/256/512.
- Avoid HD sets. A single 2048 TGA can hit ~16MB; that is unacceptable for a lightweight minimap addon.

Expected rough file sizes (order of magnitude):
- 512×512 RGBA TGA ≈ ~1.0–1.1 MB (acceptable)
- 1024×1024 RGBA TGA ≈ ~4 MB (borderline)
- 2048×2048 RGBA TGA ≈ ~16 MB (do not ship)

### “Replaceable art” principles
To make recoloring and layer mixing work:
- Draw most overlays in **white** (or neutral) and use **alpha** to define shapes.
- Use `SetVertexColor` in code to recolor (border/runes/glow).
- Keep consistent transparent margins (padding) so layers align across skins.

---

## Current placeholder textures (what they do)

These are **schematic placeholders**. They are meant to validate the pipeline, performance and animation logic.

### Minimap mask
- `media/mask_square.tga`
  - Used by `Minimap:SetMaskTexture()` when square mode is enabled.

### Inner vignette (shadow inside)
- `media/RM_VIGNETTE_SQUARE_512.tga`
  - Applied to Minimap itself (not the skin frame).
  - Color is forced to black; alpha controlled by Settings.

### Border
- `media/RM_DIABLO_BORDER_512.tga`
  - Static frame. Recolored via vertex color.
  - Replace later with painted border, but keep **same 512 canvas** and alignment.

### Runes
- `media/RM_DIABLO_RUNES_512.tga`
  - Optional ornament layer. Intended to be subtle idle, stronger in combat.
  - Recolored and blended (ADD/BLEND) by Settings.

### Glow halo
- `media/RM_DIABLO_FIRE_GLOW_512.tga`
  - Soft halo behind border. ADD blend.
  - Acts as “heat haze” / ambient energy.

### Charred edge (burnt parchment rim)
- `media/RM_DIABLO_CHAR_512.tga`
  - Dark rim under the fire; alpha controlled by Settings.
  - Should remain mostly subtle.

### Fire atlas (animated)
- `media/RM_DIABLO_FIRE_ATLAS_512_*.tga` (16 frames, 4×4 grid)
  - Used by both `fireTex` and `breathTex`.
  - Code assumes:
    - square atlas
    - **4×4 grid** (16 frames)
    - frames are indexed left-to-right, top-to-bottom
    - center is mostly transparent (hole), flame lives on the edges

Presets:
- `..._ORIGINAL.tga` → raw (for debugging: verify art is not destroyed)
- `..._HOLE_THIN.tga` → thin edge flame
- `..._HOLE_NORMAL.tga` → default
- `..._HOLE_THICK.tga` → thicker edge flame

### Shadow edge helper
- `media/shadow_edge.tga`
  - Used by the shadow module to build a gradient “drop shadow” around the minimap.

---

## “Final art” requirements for the real Diablo fire

When we replace placeholders with real art, the fire should feel like:
- **Idle:** smolder / breathing ember, low alpha, slow frame rate.
- **Combat:** ignite quickly (fast ramp), higher alpha, higher frame rate.
- **Events:** short pulses:
  - Ping: brief bright pulse (optional)
  - Loot/Achievement: warm “joy” flash (golden)

Art requirements for the fire atlas:
- 512×512 only.
- 16 frames (4×4).
- Flame tongues must be **very small** (close to the edge), so it does not invade nearby frames.
- Center must stay transparent (hole), only a thin border of flame.
- Prefer higher detail in alpha silhouette rather than huge bright blobs.

---

## Notes for debugging

- Button bag debug command: `/rmb scan` forces deep rescan.
- If bag is empty: check whether a competing addon is moving buttons during combat (we defer stashing until out of combat).
