-- Roth Minimap layered "Obsidian Ember" skin for Retail 12.1.5.
-- Every region in this file is addon-owned and noninteractive.

local _, ns = ...
ns.skin = ns.skin or {}
local M = ns.skin
local U = ns.util

local frame
local shadow
local ambientGlow
local charEdge
local border
local borderHighlight
local runes
local fireTexture
local fireBreathGroup
local fireBreathUp
local fireBreathDown
local pulseTexture
local pulseGroup
local vignette
local fireTicker
local fireInterval
local fireIndex = 0
local fireBreathing = false
local breathLow
local breathHigh
local breathDuration
local inCombat = type(InCombatLockdown) == "function" and InCombatLockdown() or false
local geometryReady = false

local REFERENCE_MINIMAP_SIZE = 198
local IDLE_FIRE_FRAME = 5
local FIRE_ATLAS = ns.media .. "RM_DIABLO_FIRE_ATLAS_512_HOLE_THIN.tga"
local BORDER_TEXTURE = ns.media .. "RM_DIABLO_BORDER_512.tga"
local CHAR_TEXTURE = ns.media .. "RM_DIABLO_CHAR_512.tga"
local RUNES_TEXTURE = ns.media .. "RM_DIABLO_RUNES_512.tga"
local VIGNETTE_TEXTURE = ns.media .. "RM_VIGNETTE_SQUARE_512.tga"
local GLOW_TEXTURE = ns.media .. "RM_DIABLO_FIRE_GLOW_512.tga"

local function ReadColor(color, fallbackR, fallbackG, fallbackB, fallbackA)
  local source = U.SafeTable(color)
  if not source then return fallbackR, fallbackG, fallbackB, fallbackA end
  return U.SafeNumber(source[1]) or fallbackR,
    U.SafeNumber(source[2]) or fallbackG,
    U.SafeNumber(source[3]) or fallbackB,
    U.SafeNumber(source[4]) or fallbackA
end

local function SetColor(texture, color, alphaOverride)
  if not texture then return end
  local r, g, b, a = ReadColor(color, 1, 1, 1, 1)
  texture:SetVertexColor(r, g, b, alphaOverride ~= nil and alphaOverride or a)
end

local function SetAccentColor(texture, color)
  if not texture then return end
  local r, g, b = ReadColor(color, 1, 0.34, 0.10, 1)
  texture:SetVertexColor(r, g, b, 1)
end

local function SetEmberColor(texture, color)
  if not texture then return end
  local r, g, b = ReadColor(color, 1, 0.34, 0.10, 1)
  texture:SetVertexColor(
    math.min(1, 0.45 + r * 0.55),
    math.min(1, 0.28 + g * 0.72),
    math.min(1, 0.16 + b * 0.84),
    1
  )
end

local function SetCharColor(texture, borderColor, accentColor)
  if not texture then return end
  local br, bg, bb = ReadColor(borderColor, 0.23, 0.18, 0.14, 1)
  local ar, ag, ab = ReadColor(accentColor, 1, 0.34, 0.10, 1)
  texture:SetVertexColor(
    math.min(1, 0.38 + br * 0.55 + ar * 0.07),
    math.min(1, 0.30 + bg * 0.55 + ag * 0.05),
    math.min(1, 0.24 + bb * 0.55 + ab * 0.03),
    1
  )
end

local function PresentationEnabled()
  local db = ns.db and ns.db.skin
  return db
    and ns.db.enabled
    and db.enabled
    and not (type(ns.UsesNativePresentation) == "function" and ns.UsesNativePresentation())
end

local function IsEffectivelyVisible()
  return frame
    and U.SafeGet(frame, "IsVisible") == true
    and U.SafeGet(Minimap, "IsVisible") == true
end

local function SyncCombatState()
  if type(InCombatLockdown) ~= "function" then return end
  local current = InCombatLockdown()
  if type(current) == "boolean" then inCombat = current end
end

local function StopFireTicker()
  if fireTicker and type(fireTicker.Cancel) == "function" then fireTicker:Cancel() end
  fireTicker = nil
  fireInterval = nil
end

local function StopIdleBreath()
  if fireBreathGroup and fireBreathing then fireBreathGroup:Stop() end
  fireBreathing = false
end

local function ResetPulse()
  if not pulseTexture then return end
  pulseTexture:SetAlpha(0)
  pulseTexture:Hide()
end

local function StopPulse()
  if pulseGroup then pulseGroup:Stop() end
  ResetPulse()
end

local function SetFireFrame(index)
  if not fireTexture then return end
  index = index % 16
  local column = index % 4
  local row = math.floor(index / 4)
  local step = 0.25
  fireTexture:SetTexCoord(column * step, (column + 1) * step, row * step, (row + 1) * step)
end

local function CurrentFireAlpha()
  SyncCombatState()
  local db = ns.db and ns.db.skin
  if not db then return 0 end
  local alpha = inCombat and db.fireCombatAlpha or db.fireIdleAlpha
  return U.clamp(U.SafeNumber(alpha) or 0, 0, 1)
end

local function FireEnabled()
  local db = ns.db and ns.db.skin
  return PresentationEnabled() and db.fire == true
end

local function StartIdleBreath(alpha)
  local db = ns.db and ns.db.skin
  if not (fireBreathGroup and fireBreathUp and fireBreathDown and db) then return end

  local speed = U.clamp(U.SafeNumber(db.fireIdleFPS) or 2, 1, 8)
  local low = alpha * 0.72
  local high = alpha
  local duration = 3.4 / math.sqrt(speed)

  if breathLow ~= low or breathHigh ~= high or breathDuration ~= duration then
    breathLow = low
    breathHigh = high
    breathDuration = duration
    fireBreathUp:SetFromAlpha(low)
    fireBreathUp:SetToAlpha(high)
    fireBreathUp:SetDuration(duration)
    fireBreathDown:SetFromAlpha(high)
    fireBreathDown:SetToAlpha(low)
    fireBreathDown:SetDuration(duration)
  end

  fireTexture:SetAlpha(low)
  if not fireBreathing then
    fireBreathGroup:Play()
    fireBreathing = true
  end
end

local function StartFireTicker()
  local db = ns.db and ns.db.skin
  local alpha = CurrentFireAlpha()
  if not inCombat or not (FireEnabled() and alpha > 0.001 and IsEffectivelyVisible()) then
    StopFireTicker()
    return
  end
  if not C_Timer or type(C_Timer.NewTicker) ~= "function" then return end

  local fps = U.clamp(U.SafeNumber(db.fireCombatFPS) or 8, 1, 20)
  local interval = 1 / fps
  if fireTicker and fireInterval == interval then return end

  StopFireTicker()
  fireInterval = interval
  fireTicker = C_Timer.NewTicker(interval, function()
    SyncCombatState()
    if not inCombat or not (FireEnabled() and CurrentFireAlpha() > 0.001 and IsEffectivelyVisible()) then
      StopFireTicker()
      return
    end
    fireIndex = (fireIndex + 1) % 16
    SetFireFrame(fireIndex)
  end)
end

local function UpdateFire()
  if not fireTexture then return end
  local db = ns.db and ns.db.skin
  local alpha = CurrentFireAlpha()

  if not FireEnabled() or alpha <= 0.001 then
    StopFireTicker()
    StopIdleBreath()
    fireTexture:Hide()
    if ambientGlow then ambientGlow:Hide() end
    if charEdge then
      charEdge:SetShown(db and db.border == true)
      charEdge:SetAlpha(db and db.border and 0.28 or 0)
    end
    return
  end

  fireTexture:Show()
  if inCombat then
    StopIdleBreath()
    fireTexture:SetAlpha(alpha)
    StartFireTicker()
  else
    StopFireTicker()
    SetFireFrame(IDLE_FIRE_FRAME)
    StartIdleBreath(alpha)
  end

  if ambientGlow then
    local glowAlpha
    if inCombat then
      glowAlpha = math.min(0.15, 0.010 + alpha * 0.38)
    else
      glowAlpha = math.min(0.08, 0.006 + alpha * 0.22)
    end
    ambientGlow:SetAlpha(glowAlpha)
    ambientGlow:Show()
  end

  if charEdge then
    local base = db and db.border and 0.28 or 0.22
    local response = inCombat and alpha * 0.34 or alpha * 0.16
    charEdge:SetAlpha(math.min(0.46, base + response))
    charEdge:Show()
  end
end

local function SyncDrawOrder()
  if not frame then return false end
  local strata = U.SafeGet(Minimap, "GetFrameStrata")
  local level = U.SafeNumber(U.SafeGet(Minimap, "GetFrameLevel"))
  if type(strata) ~= "string" or not level or level < 0 then return false end

  frame:SetFrameStrata(strata)
  frame:SetFrameLevel(level)
  return true
end

local function UpdateStaticLayers()
  if not frame then return end
  local db = ns.db and ns.db.skin
  if not db then return end

  local hasOuterArt = db.border or db.runes or db.fire
  local shadowAlpha = 0
  if hasOuterArt then
    shadowAlpha = db.fire and 0.34 or 0.26
    if db.runes then shadowAlpha = shadowAlpha + 0.02 end
  end
  shadow:SetShown(hasOuterArt == true)
  shadow:SetAlpha(shadowAlpha)

  charEdge:SetShown(db.border == true or db.fire == true)
  charEdge:SetAlpha((db.border or db.fire) and 0.28 or 0)
  SetCharColor(charEdge, db.borderColor, db.runesColor)

  border:SetShown(db.border == true)
  SetColor(border, db.borderColor)

  borderHighlight:SetShown(db.border == true)
  SetAccentColor(borderHighlight, db.runesColor)
  local _, _, _, runeAlpha = ReadColor(db.runesColor, 1, 0.34, 0.10, 0.16)
  borderHighlight:SetAlpha(db.border and math.min(0.11, 0.035 + runeAlpha * 0.20) or 0)

  runes:SetShown(db.runes == true)
  SetColor(runes, db.runesColor)

  SetEmberColor(fireTexture, db.runesColor)
  SetEmberColor(ambientGlow, db.runesColor)
  SetEmberColor(pulseTexture, db.runesColor)

  vignette:SetShown(db.vignette == true)
  vignette:SetAlpha(db.vignette and U.clamp(U.SafeNumber(db.vignetteAlpha) or 0, 0, 1) or 0)
end

local function OnSkinHidden()
  StopFireTicker()
  StopIdleBreath()
  StopPulse()
end

local function Ensure()
  if frame then return true end
  if type(InCombatLockdown) == "function" and InCombatLockdown() then return false end
  if not U.CanUseObject(_G.Minimap) then return false end

  frame = CreateFrame("Frame", nil, Minimap)
  frame:EnableMouse(false)
  frame:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
  frame:Hide()
  frame:SetScript("OnShow", UpdateFire)
  frame:SetScript("OnHide", OnSkinHidden)

  shadow = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
  shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", -8, 8)
  shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 8, -8)
  shadow:SetTexture(GLOW_TEXTURE)
  shadow:SetBlendMode("BLEND")
  shadow:SetVertexColor(0, 0, 0, 1)
  shadow:SetAlpha(0.34)

  ambientGlow = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
  ambientGlow:SetAllPoints(frame)
  ambientGlow:SetTexture(GLOW_TEXTURE)
  ambientGlow:SetBlendMode("ADD")
  ambientGlow:SetAlpha(0)
  ambientGlow:Hide()

  charEdge = frame:CreateTexture(nil, "ARTWORK", nil, 0)
  charEdge:SetAllPoints(frame)
  charEdge:SetTexture(CHAR_TEXTURE)
  charEdge:SetBlendMode("BLEND")
  charEdge:SetAlpha(0.28)

  fireTexture = frame:CreateTexture(nil, "ARTWORK", nil, 1)
  fireTexture:SetAllPoints(frame)
  fireTexture:SetTexture(FIRE_ATLAS)
  fireTexture:SetBlendMode("ADD")
  SetFireFrame(IDLE_FIRE_FRAME)

  fireBreathGroup = fireTexture:CreateAnimationGroup()
  fireBreathGroup:SetLooping("REPEAT")
  fireBreathUp = fireBreathGroup:CreateAnimation("Alpha")
  fireBreathUp:SetOrder(1)
  fireBreathUp:SetSmoothing("IN_OUT")
  fireBreathDown = fireBreathGroup:CreateAnimation("Alpha")
  fireBreathDown:SetOrder(2)
  fireBreathDown:SetSmoothing("IN_OUT")

  border = frame:CreateTexture(nil, "ARTWORK", nil, 2)
  border:SetAllPoints(frame)
  border:SetTexture(BORDER_TEXTURE)
  border:SetBlendMode("BLEND")

  borderHighlight = frame:CreateTexture(nil, "ARTWORK", nil, 3)
  borderHighlight:SetAllPoints(frame)
  borderHighlight:SetTexture(BORDER_TEXTURE)
  borderHighlight:SetBlendMode("ADD")
  borderHighlight:SetAlpha(0.07)

  runes = frame:CreateTexture(nil, "ARTWORK", nil, 4)
  runes:SetAllPoints(frame)
  runes:SetTexture(RUNES_TEXTURE)
  runes:SetBlendMode("ADD")

  pulseTexture = frame:CreateTexture(nil, "ARTWORK", nil, 5)
  pulseTexture:SetAllPoints(frame)
  pulseTexture:SetTexture(GLOW_TEXTURE)
  pulseTexture:SetBlendMode("ADD")
  ResetPulse()

  pulseGroup = pulseTexture:CreateAnimationGroup()
  local fadeIn = pulseGroup:CreateAnimation("Alpha")
  fadeIn:SetOrder(1)
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(0.42)
  fadeIn:SetDuration(0.10)
  local fadeOut = pulseGroup:CreateAnimation("Alpha")
  fadeOut:SetOrder(2)
  fadeOut:SetFromAlpha(0.42)
  fadeOut:SetToAlpha(0)
  fadeOut:SetDuration(0.34)
  pulseGroup:SetScript("OnPlay", function() pulseTexture:Show() end)
  pulseGroup:SetScript("OnStop", ResetPulse)
  pulseGroup:SetScript("OnFinished", ResetPulse)

  vignette = Minimap:CreateTexture(nil, "OVERLAY", nil, 7)
  vignette:SetAllPoints(Minimap)
  vignette:SetTexture(VIGNETTE_TEXTURE)
  vignette:SetVertexColor(0, 0, 0, 1)
  vignette:Hide()

  M.frame = frame
  M.fireBreathGroup = fireBreathGroup
  M.pulseGroup = pulseGroup
  return SyncDrawOrder()
end

function M:UpdateGeometry()
  if not PresentationEnabled() then
    self:Disable()
    return true
  end
  if not Ensure() then return false end
  if type(InCombatLockdown) == "function" and InCombatLockdown() then return false end
  if not SyncDrawOrder() then return false end

  local width = U.SafeNumber(U.SafeGet(Minimap, "GetWidth"))
  local height = U.SafeNumber(U.SafeGet(Minimap, "GetHeight"))
  if not width or not height or width <= 0 or height <= 0 then return false end

  local geometryScale = U.clamp(math.min(width, height) / REFERENCE_MINIMAP_SIZE, 0.5, 2.5)
  local baseOutset = U.clamp(U.SafeNumber(ns.db.skin.outset) or 28, 0, 96)
  local scaledOutset = math.floor(baseOutset * geometryScale + 0.5)
  local shadowPadding = math.max(4, math.floor(8 * geometryScale + 0.5))
  local targetWidth = width + scaledOutset * 2
  local targetHeight = height + scaledOutset * 2
  local currentWidth = U.SafeNumber(U.SafeGet(frame, "GetWidth"))
  local currentHeight = U.SafeNumber(U.SafeGet(frame, "GetHeight"))
  if currentWidth ~= targetWidth or currentHeight ~= targetHeight then
    frame:SetSize(targetWidth, targetHeight)
  end

  if M.shadowPadding ~= shadowPadding then
    shadow:ClearAllPoints()
    shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", -shadowPadding, shadowPadding)
    shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", shadowPadding, -shadowPadding)
    M.shadowPadding = shadowPadding
  end

  M.geometryScale = geometryScale
  M.scaledOutset = scaledOutset
  geometryReady = true
  return true
end

function M:Apply()
  if not PresentationEnabled() then
    self:Disable()
    return true
  end
  if not Ensure() then return false end

  local updated = self:UpdateGeometry()
  if not updated and not geometryReady then
    self:Disable()
    return false
  end

  UpdateStaticLayers()
  frame:Show()
  UpdateFire()
  return true
end

function M:ApplySafeState()
  if not frame then return true end
  if not PresentationEnabled() then
    self:Disable()
    return true
  end

  UpdateStaticLayers()
  UpdateFire()
  return true
end

function M:Pulse()
  if not IsEffectivelyVisible() or not pulseGroup then return end
  StopPulse()
  pulseGroup:Play()
end

function M:Disable()
  StopFireTicker()
  StopIdleBreath()
  StopPulse()
  if frame then frame:Hide() end
  if vignette then vignette:Hide() end
end

local combatEvents = CreateFrame("Frame")
combatEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
combatEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
combatEvents:SetScript("OnEvent", function()
  SyncCombatState()
  UpdateFire()
end)
