-- Roth Minimap - Skin system (Diablo)
--
-- Goals:
--   * Lightweight: no always-on OnUpdate loops.
--   * Reactive: combat flare, ping/damage pulses, low-HP rage, "joy" on loot/achievements.
--   * Skinnable: layered textures (border/runes/glow/vignette/fire) + animated FX.
--
-- Implementation notes:
--   * Fire uses a single C_Timer.NewTicker that advances frames only while at least
--     one fire layer is visible.
--   * Breathing is handled by an AnimationGroup on a separate overlay layer,
--     so it does not fight combat fades.
--   * All player-state reads that may be Secret in 12.0+ are guarded.
--
-- No third-party addon code is copied.

local ADDON, ns = ...

ns.skin = ns.skin or {}
local M = ns.skin

local SKINS = {}

-- Primary skin frame (anchors to Minimap)
local skinFrame
local borderTex
local runesTex
local glowTex
local charTex
local fireTex
local breathTex
local fxTex

-- Inner vignette (anchors directly to Minimap so it clips with the minimap mask)
local vignetteTex
local materialBlendTex


-- Shadow vignette (external edge fade)
local shadowFrame
local shadowEdgeTex = {}

-- Corner-safe drop shadow (Material-style)
local shadowDropFrame
local shadowDropTex = {}

local fire = {
  atlas = nil,
  grid = 4,
  frameCount = 16,
  step = 0.25, -- 1/4
  idx = 1,
  targetAlpha = 0,

  ticker = nil,
  interval = nil,

  fadeGroup = nil,
  fadeAnim = nil,

  breathGroup = nil,
  breathA1 = nil,
  breathA2 = nil,

  fxGroup = nil,
  fxAIn = nil,
  fxAOut = nil,
  fxSIn = nil,
  fxSOut = nil,

  -- reactive state
  inCombat = false,
  lowHealth = false,
  mounted = false,
  resting = false,

  pulse = {
    pingUntil = 0,
    pingStart = 0,
    dmgUntil  = 0,
    dmgStart  = 0,
    joyUntil  = 0,
    joyStart  = 0,
    joyColor  = nil,

    lastDamage = 0,
    lastJoy = 0,
  },

  queued = false,
}

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function clamp(v, lo, hi)
  return ns.util.clamp(tonumber(v) or 0, lo, hi)
end

local function isSecret(v)
  return type(_G.issecretvalue) == "function" and _G.issecretvalue(v)
end

local function numOrNil(v)
  if v == nil or isSecret(v) then return nil end
  return tonumber(v)
end

local function now()
  return GetTime()
end

local function tget(tbl, key, fallback)
  if type(tbl) ~= "table" then return fallback end
  local v = tbl[key]
  if v == nil then return fallback end
  return v
end

local function unpackColor(c, dr, dg, db)
  if type(c) ~= "table" then return dr, dg, db end
  local r, g, b = c[1], c[2], c[3]
  return tonumber(r) or dr, tonumber(g) or dg, tonumber(b) or db
end

-- -----------------------------------------------------------------------------
-- Frame construction
-- -----------------------------------------------------------------------------

local function ensureVignette()
  if vignetteTex then return end

  vignetteTex = Minimap:CreateTexture(nil, "BORDER")
  vignetteTex:SetAllPoints(Minimap)
  vignetteTex:SetTexture(ns.media .. "RM_VIGNETTE_SQUARE_512.tga")
  vignetteTex:SetBlendMode("BLEND")
  vignetteTex:SetVertexColor(0, 0, 0, 1)
  vignetteTex:SetAlpha(0)
  vignetteTex:Hide()
end

local function ensureMaterialBlend()
  if materialBlendTex then return end

  -- Material inner fade: soft gradient where the frame meets the minimap content.
  -- Anchored to Minimap so it is clipped by the minimap mask (no visible corners outside the map).
  materialBlendTex = Minimap:CreateTexture(nil, "OVERLAY")
  materialBlendTex:SetAllPoints(Minimap)
  materialBlendTex:SetTexture(ns.media .. "RM_VIGNETTE_SQUARE_512.tga")
  materialBlendTex:SetBlendMode("BLEND")
  materialBlendTex:SetVertexColor(0, 0, 0, 1)
  materialBlendTex:SetAlpha(0)
  materialBlendTex:Hide()
end

local function hideMaterialBlend()
  if not materialBlendTex then return end
  materialBlendTex:SetAlpha(0)
  materialBlendTex:Hide()
end


local function ensureSkinFrame()
  if skinFrame then return end

  -- The Minimap frame can be configured to clip children on some builds; ensure external FX can render.
  pcall(Minimap.SetClipsChildren, Minimap, false)

  skinFrame = CreateFrame("Frame", "RothMinimapSkinFrame", (MinimapCluster or UIParent))
  skinFrame:SetFrameStrata("HIGH")
  skinFrame:SetFrameLevel(Minimap:GetFrameLevel() + 20)
  skinFrame:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
  skinFrame:SetSize(Minimap:GetWidth(), Minimap:GetHeight())
  skinFrame:Hide()

  -- Expose for other modules (anchoring Blizzard widgets, etc.)
  M.frame = skinFrame

  -- Glow (soft halo behind border)
  glowTex = skinFrame:CreateTexture(nil, "BACKGROUND")
  glowTex:SetTexture(ns.media .. "RM_DIABLO_FIRE_GLOW_512.tga")
  glowTex:SetBlendMode("ADD")
  glowTex:SetAlpha(0)
  glowTex:Hide()

  -- Border (static)
  borderTex = skinFrame:CreateTexture(nil, "OVERLAY")
  borderTex:SetAllPoints(skinFrame)
  borderTex:SetAlpha(1)

  -- Runes (static)
  runesTex = skinFrame:CreateTexture(nil, "OVERLAY")
  runesTex:SetAllPoints(skinFrame)
  runesTex:SetBlendMode("ADD")
  runesTex:SetAlpha(0)
  runesTex:Hide()

  -- Charred edge (burnt parchment rim under fire)
  charTex = skinFrame:CreateTexture(nil, "ARTWORK")
  charTex:SetAllPoints(skinFrame)
  charTex:SetTexture(ns.media .. "RM_DIABLO_CHAR_512.tga")
  charTex:SetBlendMode("BLEND")
  charTex:SetAlpha(0)
  charTex:Hide()

  -- Breathing fire layer (alpha animated by AnimationGroup)
  breathTex = skinFrame:CreateTexture(nil, "ARTWORK")
  breathTex:SetAllPoints(skinFrame)
  breathTex:SetBlendMode("ADD")
  -- Default to the 512 atlas; higher resolutions are intentionally not shipped.
  breathTex:SetTexture(ns.media .. "RM_DIABLO_FIRE_ATLAS_512_HOLE_NORMAL.tga")
  breathTex:SetAlpha(0)
  breathTex:Hide()

  fire.breathGroup = breathTex:CreateAnimationGroup()
  fire.breathGroup:SetLooping("REPEAT")

  fire.breathA1 = fire.breathGroup:CreateAnimation("Alpha")
  fire.breathA1:SetOrder(1)
  fire.breathA1:SetSmoothing("IN_OUT")

  fire.breathA2 = fire.breathGroup:CreateAnimation("Alpha")
  fire.breathA2:SetOrder(2)
  fire.breathA2:SetSmoothing("IN_OUT")

  -- Main fire layer (fades via AnimationGroup, frames via ticker)
  fireTex = skinFrame:CreateTexture(nil, "ARTWORK")
  fireTex:SetAllPoints(skinFrame)
  fireTex:SetBlendMode("ADD")
  fireTex:SetTexture(ns.media .. "RM_DIABLO_FIRE_ATLAS_512_HOLE_NORMAL.tga")
  fireTex:SetAlpha(0)
  fireTex:Hide()

  fire.fadeGroup = fireTex:CreateAnimationGroup()
  fire.fadeAnim = fire.fadeGroup:CreateAnimation("Alpha")
  fire.fadeAnim:SetOrder(1)
  fire.fadeGroup:SetScript("OnFinished", function()
    if fireTex and (fireTex:GetAlpha() or 0) <= 0.001 then
      fireTex:Hide()
    end
    -- stop frame ticker if both fire layers are hidden
    if (not fireTex or not fireTex:IsShown()) and (not breathTex or not breathTex:IsShown()) then
      if fire.ticker then
        fire.ticker:Cancel()
        fire.ticker = nil
        fire.interval = nil
      end
    end
  end)

  -- FX flash layer (one-shot pulse animations for combat/loot/achievements)
  fxTex = skinFrame:CreateTexture(nil, "OVERLAY")
  fxTex:SetTexture(ns.media .. "RM_DIABLO_FIRE_GLOW_512.tga")
  fxTex:SetBlendMode("ADD")
  fxTex:SetAlpha(0)
  fxTex:Hide()

  fire.fxGroup = fxTex:CreateAnimationGroup()

  fire.fxAIn = fire.fxGroup:CreateAnimation("Alpha")
  fire.fxAIn:SetOrder(1)
  fire.fxAIn:SetFromAlpha(0)
  fire.fxAIn:SetToAlpha(1)
  fire.fxAIn:SetDuration(0.08)

  fire.fxSIn = fire.fxGroup:CreateAnimation("Scale")
  fire.fxSIn:SetOrder(1)
  fire.fxSIn:SetScale(1.08, 1.08)
  fire.fxSIn:SetDuration(0.08)

  fire.fxAOut = fire.fxGroup:CreateAnimation("Alpha")
  fire.fxAOut:SetOrder(2)
  fire.fxAOut:SetFromAlpha(1)
  fire.fxAOut:SetToAlpha(0)
  fire.fxAOut:SetDuration(0.22)

  fire.fxSOut = fire.fxGroup:CreateAnimation("Scale")
  fire.fxSOut:SetOrder(2)
  fire.fxSOut:SetScale(0.92, 0.92)
  fire.fxSOut:SetDuration(0.22)

  fire.fxGroup:SetScript("OnPlay", function() if fxTex then fxTex:Show() end end)
  fire.fxGroup:SetScript("OnFinished", function() if fxTex then fxTex:Hide() end end)
end

-- -----------------------------------------------------------------------------
-- Shadow vignette (external edge fade)
-- -----------------------------------------------------------------------------

-- Two shadow styles:
--   * MATERIAL: corner-safe, 2-layer drop shadow (looks like real elevation)
--   * EDGE: legacy edge-only rim built from a 64x64 gradient strip (corners are flat)

local SHADOW_EDGE_TEX = (ns.media or "Interface\\AddOns\\RothMinimap\\media\\") .. "shadow_edge.tga"
local SHADOW_DROP_TEX = (ns.media or "Interface\\AddOns\\RothMinimap\\media\\") .. "RM_VIGNETTE_SQUARE_512.tga"

local function hideShadowEdge()
  if shadowFrame then shadowFrame:Hide() end
end

local function hideShadowDrop()
  if shadowDropFrame then shadowDropFrame:Hide() end
end

local function ensureShadowEdge()
  if shadowFrame then return end

  -- Shadow extends outside the minimap bounds; ensure the minimap does not clip children.
  pcall(Minimap.SetClipsChildren, Minimap, false)

  shadowFrame = CreateFrame("Frame", "RothMinimapShadowFrame", (MinimapCluster or UIParent))
  shadowFrame:SetFrameStrata("HIGH")
  shadowFrame:SetFrameLevel(Minimap:GetFrameLevel() + 10)
  shadowFrame:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
  shadowFrame:SetSize(Minimap:GetWidth(), Minimap:GetHeight())
  shadowFrame:Hide()

  local function edge(layer)
    local t = shadowFrame:CreateTexture(nil, layer or "BACKGROUND")
    t:SetTexture(SHADOW_EDGE_TEX)
    t:SetBlendMode("BLEND")
    t:SetVertexColor(0, 0, 0, 1)
    t:SetAlpha(0)
    t:Hide()
    return t
  end

  -- Outer gradient (softer)
  shadowEdgeTex.top = edge("BACKGROUND")
  shadowEdgeTex.bottom = edge("BACKGROUND")
  shadowEdgeTex.left = edge("BACKGROUND")
  shadowEdgeTex.right = edge("BACKGROUND")

  -- Inner gradient (darker, narrower)
  shadowEdgeTex.top2 = edge("BORDER")
  shadowEdgeTex.bottom2 = edge("BORDER")
  shadowEdgeTex.left2 = edge("BORDER")
  shadowEdgeTex.right2 = edge("BORDER")

  -- A thin inner border to eliminate bright seams at the map edge.
  local function line()
    local t = shadowFrame:CreateTexture(nil, "OVERLAY")
    t:SetColorTexture(0, 0, 0, 1)
    t:SetBlendMode("BLEND")
    t:Hide()
    return t
  end

  shadowEdgeTex.innerTop = line()
  shadowEdgeTex.innerBottom = line()
  shadowEdgeTex.innerLeft = line()
  shadowEdgeTex.innerRight = line()
end

local function applyShadowEdge(sdb)
  ensureShadowEdge()
  hideShadowDrop()

  local alpha = clamp(sdb.alpha or 0.22, 0, 1)
  local thickness = clamp(sdb.thickness or 3, 0, 64)
  local inset = clamp(sdb.inset or 0, 0, 64)

  if alpha <= 0 or thickness <= 0 then
    hideShadowEdge()
    return
  end

  shadowFrame:ClearAllPoints()
  shadowFrame:SetPoint("CENTER", Minimap, "CENTER", 0, 0)

  -- Two-layer falloff without increasing total width:
  --  * outer: full thickness, low alpha (soft shoulder)
  --  * inner: narrower, higher alpha (density near the edge)
  local tOuter = thickness
  local aOuter = alpha * 0.30
  local tInner = clamp(math.floor(thickness * 0.55 + 0.5), 1, thickness)
  local aInner = alpha * 0.58

  shadowFrame:SetSize(Minimap:GetWidth() + tOuter * 2, Minimap:GetHeight() + tOuter * 2)

  local function placeEdge(tex, side, t, a)
    if not tex then return end

    tex:ClearAllPoints()
    tex:SetTexture(SHADOW_EDGE_TEX)

    if side == "TOP" then
      tex:SetPoint("TOPLEFT", shadowFrame, "TOPLEFT", inset, -inset)
      tex:SetPoint("TOPRIGHT", shadowFrame, "TOPRIGHT", -inset, -inset)
      tex:SetHeight(t)
      -- transparent outside (top) -> opaque inside (bottom)
      tex:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
    elseif side == "BOTTOM" then
      tex:SetPoint("BOTTOMLEFT", shadowFrame, "BOTTOMLEFT", inset, inset)
      tex:SetPoint("BOTTOMRIGHT", shadowFrame, "BOTTOMRIGHT", -inset, inset)
      tex:SetHeight(t)
      -- opaque inside (top) -> transparent outside (bottom)
      tex:SetTexCoord(0, 0, 1, 0, 0, 1, 1, 1)
    elseif side == "LEFT" then
      tex:SetPoint("TOPLEFT", shadowFrame, "TOPLEFT", inset, -inset)
      tex:SetPoint("BOTTOMLEFT", shadowFrame, "BOTTOMLEFT", inset, inset)
      tex:SetWidth(t)
      -- transparent outside (left) -> opaque inside (right)
      tex:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1)
    elseif side == "RIGHT" then
      tex:SetPoint("TOPRIGHT", shadowFrame, "TOPRIGHT", -inset, -inset)
      tex:SetPoint("BOTTOMRIGHT", shadowFrame, "BOTTOMRIGHT", -inset, inset)
      tex:SetWidth(t)
      -- opaque inside (left) -> transparent outside (right)
      tex:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
    end

    tex:SetAlpha(clamp(a, 0, 1))
    tex:Show()
  end

  placeEdge(shadowEdgeTex.top, "TOP", tOuter, aOuter)
  placeEdge(shadowEdgeTex.bottom, "BOTTOM", tOuter, aOuter)
  placeEdge(shadowEdgeTex.left, "LEFT", tOuter, aOuter)
  placeEdge(shadowEdgeTex.right, "RIGHT", tOuter, aOuter)

  placeEdge(shadowEdgeTex.top2, "TOP", tInner, aInner)
  placeEdge(shadowEdgeTex.bottom2, "BOTTOM", tInner, aInner)
  placeEdge(shadowEdgeTex.left2, "LEFT", tInner, aInner)
  placeEdge(shadowEdgeTex.right2, "RIGHT", tInner, aInner)

  -- Thin inner seam killer lines aligned to the minimap edge.
  local inner = 1
  local iAlpha = clamp(alpha * 1.05, 0, 0.45)
  local ox = tOuter + inset
  local oy = tOuter + inset

  local it = shadowEdgeTex.innerTop
  local ib = shadowEdgeTex.innerBottom
  local il = shadowEdgeTex.innerLeft
  local ir = shadowEdgeTex.innerRight

  it:ClearAllPoints()
  it:SetPoint("TOPLEFT", shadowFrame, "TOPLEFT", ox, -oy)
  it:SetPoint("TOPRIGHT", shadowFrame, "TOPRIGHT", -ox, -oy)
  it:SetHeight(inner)
  it:SetVertexColor(0, 0, 0, iAlpha)
  it:Show()

  ib:ClearAllPoints()
  ib:SetPoint("BOTTOMLEFT", shadowFrame, "BOTTOMLEFT", ox, oy)
  ib:SetPoint("BOTTOMRIGHT", shadowFrame, "BOTTOMRIGHT", -ox, oy)
  ib:SetHeight(inner)
  ib:SetVertexColor(0, 0, 0, iAlpha)
  ib:Show()

  il:ClearAllPoints()
  il:SetPoint("TOPLEFT", shadowFrame, "TOPLEFT", ox, -oy)
  il:SetPoint("BOTTOMLEFT", shadowFrame, "BOTTOMLEFT", ox, oy)
  il:SetWidth(inner)
  il:SetVertexColor(0, 0, 0, iAlpha)
  il:Show()

  ir:ClearAllPoints()
  ir:SetPoint("TOPRIGHT", shadowFrame, "TOPRIGHT", -ox, -oy)
  ir:SetPoint("BOTTOMRIGHT", shadowFrame, "BOTTOMRIGHT", -ox, oy)
  ir:SetWidth(inner)
  ir:SetVertexColor(0, 0, 0, iAlpha)
  ir:Show()

  shadowFrame:Show()
end

local function ensureShadowDrop()
  if shadowDropFrame then return end

  pcall(Minimap.SetClipsChildren, Minimap, false)

  shadowDropFrame = CreateFrame("Frame", "RothMinimapShadowDropFrame", (MinimapCluster or UIParent))
  local strata = (Minimap and Minimap.GetFrameStrata and Minimap:GetFrameStrata()) or "LOW"
  shadowDropFrame:SetFrameStrata(strata)
  local lvl = (Minimap and Minimap.GetFrameLevel and Minimap:GetFrameLevel()) or 0
  shadowDropFrame:SetFrameLevel(math.max(0, lvl - 5))
  shadowDropFrame:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
  shadowDropFrame:SetSize(Minimap:GetWidth(), Minimap:GetHeight())
  shadowDropFrame:Hide()

  local function make(layer)
    local t = shadowDropFrame:CreateTexture(nil, layer)
    t:SetTexture(SHADOW_DROP_TEX)
    t:SetBlendMode("BLEND")
    t:SetVertexColor(0, 0, 0, 1)
    t:SetAlpha(0)
    t:Hide()
    return t
  end

  shadowDropTex.ambient = make("BACKGROUND")
  shadowDropTex.key = make("BORDER")
end

local function applyShadowMaterial(sdb)
  ensureShadowDrop()
  ensureMaterialBlend()
  hideShadowEdge()

  local alpha = clamp(sdb.alpha or 0.22, 0, 1)
  -- Re-use the existing slider name/field: thickness == perceived elevation.
  local elev = clamp(sdb.thickness or 3, 0, 64)

  if alpha <= 0 or elev <= 0 then
    hideShadowDrop()
    hideMaterialBlend()
    return
  end

  local w = (Minimap and Minimap.GetWidth and Minimap:GetWidth()) or 0
  local h = (Minimap and Minimap.GetHeight and Minimap:GetHeight()) or 0
  if w <= 0 or h <= 0 then
    hideShadowDrop()
    hideMaterialBlend()
    return
  end

  -- Mapping: keep defaults subtle; allow stronger shadows without extreme widths.
  -- (This is drawn **behind** the minimap. The inner blend texture provides the soft seam.)
  local spreadAmbient = math.max(10, elev * 6)
  local spreadKey = math.max(8, elev * 5)

  local ox = ns.util.round(elev * 0.60)
  local oy = -ns.util.round(elev * 1.20)

  local ambient = shadowDropTex.ambient
  local key = shadowDropTex.key

  ambient:ClearAllPoints()
  ambient:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
  ambient:SetSize(w + spreadAmbient * 2, h + spreadAmbient * 2)
  ambient:SetAlpha(clamp(alpha * 0.38, 0, 1))
  ambient:Show()

  key:ClearAllPoints()
  key:SetPoint("CENTER", Minimap, "CENTER", ox, oy)
  key:SetSize(w + spreadKey * 2, h + spreadKey * 2)
  key:SetAlpha(clamp(alpha * 0.62, 0, 1))
  key:Show()

  shadowDropFrame:Show()

  -- Inner seam blend: a very subtle edge vignette clipped to the minimap mask.
  local innerA = clamp((alpha * 0.25) + (elev * 0.003), 0, 0.22)
  local vdb = ns.db and ns.db.visual and ns.db.visual.vignette
  if vdb and vdb.enabled then
    -- Avoid stacking a strong vignette twice (user vignette + material seam).
    innerA = clamp(innerA - (clamp(vdb.alpha or 0.22, 0, 1) * 0.65), 0, 0.22)
  end
  if innerA <= 0 then
    hideMaterialBlend()
  else
    materialBlendTex:SetAlpha(innerA)
    materialBlendTex:Show()
  end
end

local function applyShadow()
  local db = ns.db
  local sdb = db and db.shadow

  if not (db and db.enabled and sdb and sdb.enabled) then
    hideShadowEdge()
    hideShadowDrop()
    hideMaterialBlend()
    return
  end

  local style = tostring(sdb.style or "MATERIAL")
  style = string.upper(style)

  if style == "EDGE" then
    hideMaterialBlend()
    applyShadowEdge(sdb)
  else
    applyShadowMaterial(sdb)
  end
end


-- -----------------------------------------------------------------------------
-- Fire atlas helpers
local function setFireAtlasFrame(i)
  if type(i) ~= "number" then i = 1 end
  if i < 1 then i = 1 elseif i > (fire.frameCount or 16) then i = fire.frameCount or 16 end
  local idx = i - 1
  local grid = fire.grid or 4
  local step = fire.step or (1 / grid)
  local col = idx % grid
  local row = math.floor(idx / grid)
  local left = col * step
  local right = (col + 1) * step
  local top = row * step
  local bottom = (row + 1) * step
  if fireTex then pcall(fireTex.SetTexCoord, fireTex, left, right, top, bottom) end
  if breathTex then pcall(breathTex.SetTexCoord, breathTex, left, right, top, bottom) end
end

-- Fire frames ticker
-- -----------------------------------------------------------------------------

local function tickerNeeded()
  return (fireTex and fireTex:IsShown()) or (breathTex and breathTex:IsShown())
end

local function stepFrame()
  if not tickerNeeded() then return end

  local n = fire.frameCount or 16
  if n <= 0 then return end

  fire.idx = fire.idx + 1
  if fire.idx > n then fire.idx = 1 end

  setFireAtlasFrame(fire.idx)

  -- Micro-flicker (do not fight fade animations)
  if fireTex and fireTex:IsShown() and fire.fadeGroup and fire.fadeGroup.IsPlaying and fire.fadeGroup:IsPlaying() then
    return
  end

  if fireTex and fireTex:IsShown() then
    local base = fire.targetAlpha or (fireTex:GetAlpha() or 0)
    local mul = 0.97 + math.random() * 0.06 -- 0.97..1.03
    fireTex:SetAlpha(clamp(base * mul, 0, 1))
  end
end

local function ensureTicker(fps)
  fps = tonumber(fps) or 0
  if fps <= 0 then fps = 8 end
  fps = clamp(fps, 1, 40)

  local interval = 1 / fps
  if fire.ticker and fire.interval and math.abs(fire.interval - interval) < 0.0005 then
    return
  end

  if fire.ticker then
    fire.ticker:Cancel()
    fire.ticker = nil
    fire.interval = nil
  end

  fire.interval = interval
  fire.ticker = C_Timer.NewTicker(interval, stepFrame)
end

local function fadeTo(alpha, duration)
  alpha = clamp(alpha, 0, 1)
  duration = tonumber(duration) or 0

  fire.targetAlpha = alpha

  fire.fadeGroup:Stop()
  fire.fadeAnim:SetFromAlpha(fireTex:GetAlpha() or 0)
  fire.fadeAnim:SetToAlpha(alpha)
  fire.fadeAnim:SetDuration(math.max(0, duration))
  fireTex:Show()
  fire.fadeGroup:Play()
end

-- -----------------------------------------------------------------------------
-- Visual composition
-- -----------------------------------------------------------------------------

local function applyInnerVignette()
  ensureVignette()

  local v = ns.db and ns.db.visual
  local vdb = v and v.vignette

  if not (ns.db and ns.db.enabled and vdb and vdb.enabled) then
    vignetteTex:SetAlpha(0)
    vignetteTex:Hide()
    return
  end

  vignetteTex:SetAlpha(clamp(vdb.alpha or 0.22, 0, 1))
  vignetteTex:Show()
end


local function resolveFireAtlas(fdb)
  fdb = fdb or {}
  local preset = tostring(fdb.atlasPreset or "HOLE_NORMAL"):upper()

  -- Only ship a 512 atlas (performance and download size).
  local base = "RM_DIABLO_FIRE_ATLAS_512_"
  local path

  if preset == "ORIGINAL" then
    path = ns.media .. base .. "ORIGINAL.tga"
  elseif preset == "HOLE_THIN" then
    path = ns.media .. base .. "HOLE_THIN.tga"
  elseif preset == "HOLE_THICK" then
    path = ns.media .. base .. "HOLE_THICK.tga"
  else
    path = ns.media .. base .. "HOLE_NORMAL.tga"
  end

  return path
end

local function applyDecor()
  ensureSkinFrame()

  local db = ns.db
  local v = db and db.visual

  local pad = tonumber(db and db.skinPadding) or 10
  local w, h = Minimap:GetWidth(), Minimap:GetHeight()

  skinFrame:SetSize(w + pad * 2, h + pad * 2)

  -- Border
  -- Current texture is a **schematic placeholder** drawn in white (alpha defines silhouette).
  -- The final Diablo border art should keep the same 512×512 canvas + alignment; we recolor via vertex color.
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  local bdb = v and v.border
  local bTexPath = (LSM and bdb and bdb.texture and LSM:Fetch("background", bdb.texture)) or (ns.media .. "RM_DIABLO_BORDER_512.tga")
  borderTex:SetTexture(bTexPath)
  local br, bg, bb = unpackColor(bdb and bdb.color, 1, 1, 1)
  borderTex:SetVertexColor(br, bg, bb)
  borderTex:SetAlpha(clamp(tget(bdb, "alpha", 1), 0, 1))

  -- Runes
  -- Current texture is a **schematic placeholder**. Final runes should also be mostly white with meaningful alpha.
  local rdb = v and v.runes
  local rTexPath = (LSM and rdb and rdb.texture and LSM:Fetch("background", rdb.texture)) or (ns.media .. "RM_DIABLO_RUNES_512.tga")
  runesTex:SetTexture(rTexPath)
  local rr, rg, rb = unpackColor(rdb and rdb.color, 1, 1, 1)
  runesTex:SetVertexColor(rr, rg, rb)
  runesTex:SetBlendMode(tget(rdb, "blendMode", "ADD"))

  -- Glow
  local gdb = v and v.glow
  if gdb and gdb.enabled then
    glowTex:SetBlendMode(tget(gdb, "blendMode", "ADD"))
    local gr, gg, gb = unpackColor(gdb.color, 1, 0.45, 0.20)
    glowTex:SetVertexColor(gr, gg, gb)

    local scale = clamp(tget(gdb, "scale", 1.08), 0.80, 1.40)
    glowTex:ClearAllPoints()
    glowTex:SetPoint("CENTER", skinFrame, "CENTER", 0, 0)
    glowTex:SetSize(skinFrame:GetWidth() * scale, skinFrame:GetHeight() * scale)
  else
    glowTex:SetAlpha(0)
    glowTex:Hide()
  end

  -- Fire atlas (single texture, frames via texcoord)
  fire.atlas = resolveFireAtlas(db and db.fire)

  if fireTex then fireTex:SetTexture(fire.atlas) end
  if breathTex then breathTex:SetTexture(fire.atlas) end

  fire.frameCount = 16
  fire.grid = 4
  fire.step = 0.25

  fire.idx = math.random(1, fire.frameCount)
  -- fireTex/breathTex textures are set once in ensureSkinFrame; here we only set initial frame.
  setFireAtlasFrame(fire.idx)

  applyInnerVignette()
end

-- -----------------------------------------------------------------------------
-- Reactive intensity computation
-- -----------------------------------------------------------------------------

local function pulseFactor(untilTime, startTime)
  local t = now()
  if not untilTime or untilTime <= t then return 0 end
  startTime = startTime or (untilTime - 0.001)
  local dur = math.max(0.001, untilTime - startTime)
  local left = untilTime - t
  return clamp(left / dur, 0, 1)
end

local function computeIntensity()
  local db = ns.db
  local fdb = db and db.fire
  local rdb = fdb and fdb.reactive
  local v = db and db.visual

  if not (db and db.enabled and db.skinEnabled and fdb and fdb.enabled) then
    return nil
  end

  local baseAlpha = fire.inCombat and (fdb.combatAlpha or 0.85) or (fdb.outAlpha or 0.30)
  local fps = fire.inCombat and (fdb.combatFPS or 16) or (fdb.outFPS or 5)

  local alpha = baseAlpha

  -- Visual layer alphas
  local runesA
  local glowA

  local rvis = v and v.runes
  if rvis and rvis.enabled == false then
    runesA = 0
  else
    local outA = tonumber(rvis and rvis.outAlpha) or 0.20
    local cbtA = tonumber(rvis and rvis.combatAlpha) or 0.35
    runesA = fire.inCombat and cbtA or outA
  end

  local gvis = v and v.glow
  if not (gvis and gvis.enabled) then
    glowA = 0
  else
    local outA = tonumber(gvis.outAlpha) or 0.12
    local cbtA = tonumber(gvis.combatAlpha) or 0.28
    glowA = fire.inCombat and cbtA or outA
  end

  -- Base heat color
  local r, g, b = 1.00, 0.35, 0.10

  if rdb and rdb.enabled then
    -- Ping pulse
    if rdb.pingPulse then
      local p = pulseFactor(fire.pulse.pingUntil, fire.pulse.pingStart)
      if p > 0 then
        alpha = alpha + (tonumber(rdb.pingStrength) or 0.30) * (p ^ 0.6)
        runesA = runesA + 0.12 * (p ^ 0.5)
        glowA  = glowA  + 0.16 * (p ^ 0.5)
      end
    end

    -- Damage pulse
    if rdb.damagePulse then
      local p = pulseFactor(fire.pulse.dmgUntil, fire.pulse.dmgStart)
      if p > 0 then
        alpha = alpha + (tonumber(rdb.damageStrength) or 0.22) * (p ^ 0.7)
        fps = fps + 5 * p
        runesA = runesA + 0.10 * p
        glowA  = glowA  + 0.10 * p
      end
    end

    -- Joy pulse (loot/achievement)
    if rdb.joyPulse then
      local p = pulseFactor(fire.pulse.joyUntil, fire.pulse.joyStart)
      if p > 0 then
        local strength = tonumber(rdb.joyStrength) or 0.30
        alpha = alpha + strength * (p ^ 0.55)
        runesA = runesA + 0.16 * p
        glowA  = glowA  + 0.22 * p

        local jr, jg, jb = unpackColor(fire.pulse.joyColor, 1.00, 0.78, 0.20)
        r = clamp(r * (1 - p) + jr * p, 0, 1)
        g = clamp(g * (1 - p) + jg * p, 0, 1)
        b = clamp(b * (1 - p) + jb * p, 0, 1)
      end
    end

    -- Low health
    if rdb.lowHealth and fire.lowHealth then
      alpha = alpha + (tonumber(rdb.lowHealthAlphaBoost) or 0.22)
      fps = fps + (tonumber(rdb.lowHealthFpsBoost) or 6)
      runesA = runesA + 0.35
      glowA  = glowA  + 0.30
      r, g, b = 1.00, 0.08, 0.05
    end

    -- Mounted/resting dim
    local dim = tonumber(rdb.dimFactor) or 0.80
    if rdb.dimWhileMounted and fire.mounted then
      alpha = alpha * dim
      runesA = runesA * dim
      glowA  = glowA  * dim
    end
    if rdb.dimWhileResting and fire.resting then
      alpha = alpha * dim
      runesA = runesA * dim
      glowA  = glowA  * dim
    end
  end

  return {
    alpha = clamp(alpha, 0, 1),
    fps = clamp(fps, 1, 40),
    runesAlpha = clamp(runesA, 0, 1),
    glowAlpha = clamp(glowA, 0, 1),
    color = { r, g, b },
  }
end

local function stopBreath()
  if fire.breathGroup and fire.breathGroup.IsPlaying and fire.breathGroup:IsPlaying() then
    fire.breathGroup:Stop()
  end
  if breathTex then
    breathTex:SetAlpha(0)
    breathTex:Hide()
  end
end

local function updateBreath()
  local db = ns.db
  local fdb = db and db.fire
  local bdb = fdb and fdb.breath
  if not (db and db.enabled and db.skinEnabled and fdb and fdb.enabled and bdb and bdb.enabled) then
    stopBreath()
    return
  end

  local inCombat = fire.inCombat

  local minA = clamp(inCombat and (bdb.combatMin or 0.10) or (bdb.outMin or 0.05), 0, 1)
  local maxA = clamp(inCombat and (bdb.combatMax or 0.34) or (bdb.outMax or 0.18), 0, 1)
  local period = clamp(inCombat and (bdb.combatPeriod or 1.4) or (bdb.outPeriod or 3.8), 0.4, 20)

  local half = period / 2

  fire.breathGroup:Stop()
  fire.breathA1:SetFromAlpha(minA)
  fire.breathA1:SetToAlpha(maxA)
  fire.breathA1:SetDuration(half)

  fire.breathA2:SetFromAlpha(maxA)
  fire.breathA2:SetToAlpha(minA)
  fire.breathA2:SetDuration(half)

  breathTex:Show()
  fire.breathGroup:Play()
end

local function clearVisual()
  if fire.fadeGroup then fire.fadeGroup:Stop() end
  stopBreath()

  if fire.ticker then
    fire.ticker:Cancel()
    fire.ticker = nil
    fire.interval = nil
  end

  if fireTex then
    fire.targetAlpha = 0
    fireTex:SetAlpha(0)
    fireTex:Hide()
  end

  if runesTex then
    runesTex:SetAlpha(0)
    runesTex:Hide()
  end

  if glowTex then
    glowTex:SetAlpha(0)
    glowTex:Hide()
  end

  if fxTex then
    fxTex:SetAlpha(0)
    fxTex:Hide()
  end

  if vignetteTex then
    vignetteTex:SetAlpha(0)
    vignetteTex:Hide()
  end
end

local function applyFireVisual(forceSnap, flareOnEnterCombat)
  local db = ns.db
  local fdb = db and db.fire
  local r = computeIntensity()

  if not r then
    clearVisual()
    return
  end

  -- Ensure we animate frames only while needed.
  ensureTicker(r.fps)

  -- Apply colors
  local cr, cg, cb = unpack(r.color)
  if fireTex then fireTex:SetVertexColor(cr, cg, cb) end
  if breathTex then breathTex:SetVertexColor(cr, cg, cb) end

  -- Static layers
  local v = db and db.visual

  if runesTex then
    local rvis = v and v.runes
    if rvis and rvis.enabled == false then
      runesTex:SetAlpha(0)
      runesTex:Hide()
    else
      local rr, rg, rb = unpackColor(rvis and rvis.color, 1, 1, 1)
      runesTex:SetVertexColor(rr, rg, rb)
      runesTex:SetBlendMode(tget(rvis, "blendMode", "ADD"))
      runesTex:SetAlpha(r.runesAlpha)
      runesTex:Show()
    end
  end

  if glowTex then
    local gvis = v and v.glow
    if gvis and gvis.enabled then
      local gr, gg, gb = unpackColor(gvis.color, 1, 0.45, 0.20)
      glowTex:SetVertexColor(gr, gg, gb)
      glowTex:SetBlendMode(tget(gvis, "blendMode", "ADD"))
      glowTex:SetAlpha(r.glowAlpha)
      glowTex:Show()
    else
      glowTex:SetAlpha(0)
      glowTex:Hide()
    end
  end

  -- Keep breath running (state dependent)
  updateBreath()

  if forceSnap then
    fire.targetAlpha = r.alpha
    if fire.fadeGroup then fire.fadeGroup:Stop() end
    fireTex:SetAlpha(r.alpha)
    if r.alpha > 0.001 then
      fireTex:Show()
    else
      fireTex:Hide()
    end
    return
  end

  if flareOnEnterCombat and fire.inCombat and fdb and fdb.combatFlare then
    local flareDur = tonumber(fdb.flareDuration) or 0.18
    fire.targetAlpha = r.alpha

    if fire.fadeGroup then fire.fadeGroup:Stop() end
    fireTex:SetAlpha(1)
    fireTex:Show()

    C_Timer.After(flareDur, function()
      if fire.inCombat then
        fadeTo(r.alpha, 0.10)
      else
        fadeTo(r.alpha, 0.10)
      end
    end)
    return
  end

  local dur
  if fire.inCombat then
    dur = 0.10
  else
    dur = tonumber(fdb and fdb.fadeOutDuration) or 1.20
  end
  fadeTo(r.alpha, dur)
end

local function queueApply()
  if fire.queued then return end
  fire.queued = true
  C_Timer.After(0, function()
    fire.queued = false
    applyFireVisual(true)
  end)
end

-- -----------------------------------------------------------------------------
-- Diablo skin
-- -----------------------------------------------------------------------------

SKINS["Diablo"] = function()
  ensureSkinFrame()
  applyDecor()
  skinFrame:Show()
end

-- -----------------------------------------------------------------------------
-- FX / pulses
-- -----------------------------------------------------------------------------

local function playFlash(kind)
  local db = ns.db
  local vfx = db and db.visual and db.visual.fx
  if not (db and db.enabled and db.skinEnabled and vfx and vfx.enabled) then return end

  local enabled = false
  if kind == "combat" then enabled = vfx.combatFlash ~= false
  elseif kind == "loot" then enabled = vfx.lootFlash ~= false
  elseif kind == "achievement" then enabled = vfx.achievementFlash ~= false
  end
  if not enabled then return end

  local alpha = clamp(tget(vfx, "flashAlpha", 0.75), 0, 1)
  local scale = clamp(tget(vfx, "flashScale", 1.12), 1.00, 1.40)
  local din = clamp(tget(vfx, "durationIn", 0.08), 0.02, 1.0)
  local dout = clamp(tget(vfx, "durationOut", 0.22), 0.02, 2.0)

  local r, g, b
  if kind == "loot" then
    r, g, b = 0.30, 1.00, 0.45
  elseif kind == "achievement" then
    r, g, b = 1.00, 0.82, 0.20
  else
    r, g, b = 1.00, 0.45, 0.20
  end

  fxTex:SetVertexColor(r, g, b)

  fire.fxGroup:Stop()

  fire.fxAIn:SetFromAlpha(0)
  fire.fxAIn:SetToAlpha(alpha)
  fire.fxAIn:SetDuration(din)

  fire.fxSIn:SetScale(scale, scale)
  fire.fxSIn:SetDuration(din)

  fire.fxAOut:SetFromAlpha(alpha)
  fire.fxAOut:SetToAlpha(0)
  fire.fxAOut:SetDuration(dout)

  fire.fxSOut:SetScale(2 - scale, 2 - scale)
  fire.fxSOut:SetDuration(dout)

  fxTex:Show()
  fire.fxGroup:Play()
end

function M:Pulse(kind)
  local db = ns.db and ns.db.fire and ns.db.fire.reactive
  if not (db and db.enabled) then return end

  local t = now()

  if kind == "ping" and db.pingPulse then
    local dur = tonumber(db.pingDuration) or 0.55
    fire.pulse.pingStart = t
    fire.pulse.pingUntil = t + dur
    queueApply()

  elseif kind == "damage" and db.damagePulse then
    local dur = tonumber(db.damageDuration) or 0.25
    fire.pulse.dmgStart = t
    fire.pulse.dmgUntil = t + dur
    queueApply()

  elseif kind == "joy" and db.joyPulse then
    local dur = tonumber(db.joyDuration) or 0.55
    fire.pulse.joyStart = t
    fire.pulse.joyUntil = t + dur
    queueApply()
  end
end

-- -----------------------------------------------------------------------------
-- Reactive event handlers
-- -----------------------------------------------------------------------------

local function updateMountState()
  fire.mounted = IsMounted() and true or false
end

local function updateRestState()
  fire.resting = IsResting() and true or false
end

local function onHealth(_, unit)
  if unit ~= "player" then return end
  local db = ns.db and ns.db.fire and ns.db.fire.reactive
  if not (db and db.enabled and db.lowHealth) then return end

  local maxH = numOrNil(UnitHealthMax("player"))
  local curH = numOrNil(UnitHealth("player"))
  if not maxH or maxH <= 0 or curH == nil then return end

  local frac = curH / maxH
  local enterAt = tonumber(db.lowHealthThreshold) or 0.35
  local exitAt = math.min(0.95, enterAt + 0.05)
  -- Hysteresis avoids rapid low-health toggling around the threshold.
  local low = fire.lowHealth and (frac <= exitAt) or (frac <= enterAt)

  if low ~= fire.lowHealth then
    fire.lowHealth = low
    queueApply()
  end
end

local function onMount()
  local old = fire.mounted
  updateMountState()
  if old ~= fire.mounted then
    queueApply()
  end
end

local function onRest()
  local old = fire.resting
  updateRestState()
  if old ~= fire.resting then
    queueApply()
  end
end

local function onUnitCombat(_, unit, action)
  if unit ~= "player" then return end
  local db = ns.db and ns.db.fire and ns.db.fire.reactive
  if not (db and db.enabled and db.damagePulse) then return end

  if action == "HEAL" or action == "ENERGIZE" then return end

  local t = now()
  local throttle = tonumber(db.damageThrottle) or 0.10
  if fire.pulse.lastDamage and (t - fire.pulse.lastDamage) < throttle then
    return
  end

  fire.pulse.lastDamage = t
  M:Pulse("damage")
end

local function onLoot()
  local db = ns.db and ns.db.fire and ns.db.fire.reactive
  if not (db and db.enabled and db.joyPulse and db.lootPulse) then return end

  local t = now()
  local throttle = tonumber(db.joyThrottle) or 0.35
  if fire.pulse.lastJoy and (t - fire.pulse.lastJoy) < throttle then
    return
  end
  fire.pulse.lastJoy = t

  fire.pulse.joyColor = { 0.30, 1.00, 0.45 }
  M:Pulse("joy")
  playFlash("loot")
end

local function onAchievement()
  local db = ns.db and ns.db.fire and ns.db.fire.reactive
  if not (db and db.enabled and db.joyPulse and db.achievementPulse) then return end

  local t = now()
  local throttle = tonumber(db.joyThrottle) or 0.35
  if fire.pulse.lastJoy and (t - fire.pulse.lastJoy) < throttle then
    return
  end
  fire.pulse.lastJoy = t

  fire.pulse.joyColor = { 1.00, 0.82, 0.20 }
  M:Pulse("joy")
  playFlash("achievement")
end

local function registerReactiveEvents()
  if M._reactiveRegistered then return end

  ns.RegisterEvent("UNIT_HEALTH", onHealth)
  ns.RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED", onMount)
  ns.RegisterEvent("PLAYER_UPDATE_RESTING", onRest)
  ns.RegisterEvent("UNIT_COMBAT", onUnitCombat)

  -- Joy triggers
  ns.RegisterEvent("CHAT_MSG_LOOT", onLoot)
  ns.RegisterEvent("CHAT_MSG_MONEY", onLoot)
  ns.RegisterEvent("CHAT_MSG_CURRENCY", onLoot)
  ns.RegisterEvent("ACHIEVEMENT_EARNED", onAchievement)

  M._reactiveRegistered = true
end

local function unregisterReactiveEvents()
  if not M._reactiveRegistered then return end

  ns.UnregisterEvent("UNIT_HEALTH", onHealth)
  ns.UnregisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED", onMount)
  ns.UnregisterEvent("PLAYER_UPDATE_RESTING", onRest)
  ns.UnregisterEvent("UNIT_COMBAT", onUnitCombat)

  ns.UnregisterEvent("CHAT_MSG_LOOT", onLoot)
  ns.UnregisterEvent("CHAT_MSG_MONEY", onLoot)
  ns.UnregisterEvent("CHAT_MSG_CURRENCY", onLoot)
  ns.UnregisterEvent("ACHIEVEMENT_EARNED", onAchievement)

  M._reactiveRegistered = false
end

-- -----------------------------------------------------------------------------
-- Public API
-- -----------------------------------------------------------------------------

function M:Apply()
  applyShadow()
  ensureVignette()
  ensureSkinFrame()

  local db = ns.db
  if not (db and db.enabled and db.skinEnabled) then
    unregisterReactiveEvents()
    clearVisual()
    if skinFrame then skinFrame:Hide() end
    return
  end

  local skinName = db.skin or "Diablo"
  local fn = SKINS[skinName]
  if fn then
    fn()
  else
    skinFrame:Hide()
    return
  end

  -- Initialize reactive states
  updateMountState()
  updateRestState()
  onHealth(nil, "player")

  local rdb = db.fire and db.fire.reactive
  if rdb and rdb.enabled then
    registerReactiveEvents()
  else
    unregisterReactiveEvents()
  end

  applyFireVisual(false)
end

function M:SetCombat(inCombat)
  local prev = fire.inCombat
  fire.inCombat = not not inCombat
  local entering = fire.inCombat and not prev

  if entering then
    playFlash("combat")
  end

  updateBreath()
  applyFireVisual(false, entering)
end

function M:Disable()
  unregisterReactiveEvents()
  clearVisual()
  if skinFrame then skinFrame:Hide() end
  if shadowFrame then shadowFrame:Hide() end
  if shadowDropFrame then shadowDropFrame:Hide() end
end
