-- RothMinimap additive skin for Retail 12.1.5.
-- All regions are addon-owned. Blizzard minimap widgets remain untouched.

local _, ns = ...
ns.skin = ns.skin or {}
local M = ns.skin
local U = ns.util

local frame
local border
local runes
local fireTexture
local pulseTexture
local vignette
local fireTicker
local fireInterval
local fireIndex = 0
local inCombat = false
local geometryReady = false

local FIRE_ATLAS = ns.media .. "RM_DIABLO_FIRE_ATLAS_512_HOLE_NORMAL.tga"
local BORDER_TEXTURE = ns.media .. "RM_DIABLO_BORDER_512.tga"
local RUNES_TEXTURE = ns.media .. "RM_DIABLO_RUNES_512.tga"
local VIGNETTE_TEXTURE = ns.media .. "RM_VIGNETTE_SQUARE_512.tga"
local GLOW_TEXTURE = ns.media .. "RM_DIABLO_FIRE_GLOW_512.tga"

local function SetColor(texture, color)
  local source = U.SafeTable(color)
  if not texture or not source then return end
  texture:SetVertexColor(
    U.SafeNumber(source[1]) or 1,
    U.SafeNumber(source[2]) or 1,
    U.SafeNumber(source[3]) or 1,
    U.SafeNumber(source[4]) or 1
  )
end

local function IsEffectivelyVisible()
  return frame and U.SafeGet(frame, "IsVisible") == true and U.SafeGet(Minimap, "IsVisible") == true
end

local function StopFireTicker()
  if fireTicker and type(fireTicker.Cancel) == "function" then fireTicker:Cancel() end
  fireTicker = nil
  fireInterval = nil
end

local function SetFireFrame(index)
  if not fireTexture then return end
  index = index % 16
  local column = index % 4
  local row = math.floor(index / 4)
  local step = 0.25
  fireTexture:SetTexCoord(column * step, (column + 1) * step, row * step, (row + 1) * step)
end

local function StartFireTicker()
  local db = ns.db and ns.db.skin
  if not (db and ns.db.enabled and db.enabled and db.fire and IsEffectivelyVisible()) then
    StopFireTicker()
    return
  end
  if not C_Timer or type(C_Timer.NewTicker) ~= "function" then return end

  local fps = U.clamp(U.SafeNumber(db.fireFPS) or 8, 1, 20)
  local interval = 1 / fps
  if fireTicker and fireInterval == interval then return end

  StopFireTicker()
  fireInterval = interval
  fireTicker = C_Timer.NewTicker(interval, function()
    local current = ns.db and ns.db.skin
    if not (current and ns.db.enabled and current.enabled and current.fire and IsEffectivelyVisible()) then
      StopFireTicker()
      return
    end
    fireIndex = (fireIndex + 1) % 16
    SetFireFrame(fireIndex)
  end)
end

local function UpdateFireAlpha()
  if not fireTexture then return end
  local db = ns.db and ns.db.skin
  if not (db and ns.db.enabled and db.enabled and db.fire) then
    fireTexture:Hide()
    StopFireTicker()
    return
  end

  local alpha = inCombat and db.fireCombatAlpha or db.fireIdleAlpha
  fireTexture:SetAlpha(U.clamp(U.SafeNumber(alpha) or 0, 0, 1))
  fireTexture:Show()
  StartFireTicker()
end

local function Ensure()
  if frame then return true end
  if InCombatLockdown and InCombatLockdown() then return false end
  if not U.CanUseObject(_G.Minimap) then return false end

  frame = CreateFrame("Frame", "RothMinimapSkinFrame", Minimap)
  frame:SetFrameStrata("HIGH")
  frame:SetFrameLevel(300)
  frame:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
  frame:Hide()
  frame:SetScript("OnShow", UpdateFireAlpha)
  frame:SetScript("OnHide", StopFireTicker)

  border = frame:CreateTexture(nil, "OVERLAY", nil, 1)
  border:SetAllPoints(frame)
  border:SetTexture(BORDER_TEXTURE)

  runes = frame:CreateTexture(nil, "OVERLAY", nil, 2)
  runes:SetAllPoints(frame)
  runes:SetTexture(RUNES_TEXTURE)
  runes:SetBlendMode("ADD")

  fireTexture = frame:CreateTexture(nil, "ARTWORK", nil, 1)
  fireTexture:SetAllPoints(frame)
  fireTexture:SetTexture(FIRE_ATLAS)
  fireTexture:SetBlendMode("ADD")
  SetFireFrame(0)

  pulseTexture = frame:CreateTexture(nil, "OVERLAY", nil, 3)
  pulseTexture:SetAllPoints(frame)
  pulseTexture:SetTexture(GLOW_TEXTURE)
  pulseTexture:SetBlendMode("ADD")
  pulseTexture:SetAlpha(0)
  pulseTexture:Hide()

  local pulseGroup = pulseTexture:CreateAnimationGroup()
  local fadeIn = pulseGroup:CreateAnimation("Alpha")
  fadeIn:SetOrder(1)
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(0.9)
  fadeIn:SetDuration(0.08)
  local fadeOut = pulseGroup:CreateAnimation("Alpha")
  fadeOut:SetOrder(2)
  fadeOut:SetFromAlpha(0.9)
  fadeOut:SetToAlpha(0)
  fadeOut:SetDuration(0.28)
  pulseGroup:SetScript("OnPlay", function() pulseTexture:Show() end)
  pulseGroup:SetScript("OnFinished", function() pulseTexture:Hide() end)
  frame.pulseGroup = pulseGroup

  vignette = Minimap:CreateTexture("RothMinimapVignette", "OVERLAY", nil, 7)
  vignette:SetAllPoints(Minimap)
  vignette:SetTexture(VIGNETTE_TEXTURE)
  vignette:SetVertexColor(0, 0, 0, 1)
  vignette:Hide()

  M.frame = frame
  return true
end

function M:UpdateGeometry()
  if not Ensure() then return false end
  if InCombatLockdown and InCombatLockdown() then return false end

  local width = U.SafeNumber(U.SafeGet(Minimap, "GetWidth"))
  local height = U.SafeNumber(U.SafeGet(Minimap, "GetHeight"))
  if not width or not height or width <= 0 or height <= 0 then return false end

  local outset = U.clamp(U.SafeNumber(ns.db.skin.outset) or 34, 0, 96)
  local targetWidth = width + outset * 2
  local targetHeight = height + outset * 2
  if frame:GetWidth() ~= targetWidth or frame:GetHeight() ~= targetHeight then
    frame:SetSize(targetWidth, targetHeight)
  end
  geometryReady = true
  return true
end

function M:Apply()
  if not Ensure() then return false end
  local db = ns.db and ns.db.skin
  local enabled = ns.db and ns.db.enabled and db and db.enabled

  if not enabled then
    if frame.pulseGroup then frame.pulseGroup:Stop() end
    frame:Hide()
    if vignette then vignette:Hide() end
    StopFireTicker()
    return true
  end

  local updated = self:UpdateGeometry()
  if not updated and not geometryReady then
    frame:Hide()
    StopFireTicker()
    return false
  end

  border:SetShown(db.border == true)
  SetColor(border, db.borderColor)
  runes:SetShown(db.runes == true)
  SetColor(runes, db.runesColor)
  vignette:SetShown(db.vignette == true)
  vignette:SetAlpha(db.vignette and U.clamp(U.SafeNumber(db.vignetteAlpha) or 0, 0, 1) or 0)
  frame:Show()
  UpdateFireAlpha()
  return true
end

function M:Pulse()
  if not IsEffectivelyVisible() or not frame.pulseGroup then return end
  frame.pulseGroup:Stop()
  frame.pulseGroup:Play()
end

function M:Disable()
  StopFireTicker()
  if frame and frame.pulseGroup then frame.pulseGroup:Stop() end
  if frame then frame:Hide() end
  if vignette then vignette:Hide() end
end

local function OnCombat(_, event)
  inCombat = event == "PLAYER_REGEN_DISABLED"
  UpdateFireAlpha()
end

ns.RegisterEvent("PLAYER_REGEN_DISABLED", OnCombat)
ns.RegisterEvent("PLAYER_REGEN_ENABLED", OnCombat)
