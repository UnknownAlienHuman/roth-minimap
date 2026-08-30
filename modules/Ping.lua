-- RothMinimap ping notification for Retail 12.1.
-- The MINIMAP_PING unit payload is intentionally not inspected or named.

local ADDON_NAME, ns = ...
ns.ping = ns.ping or {}
local M = ns.ping
local U = ns.util

local toast
local text
local animation
local hold
local registered = false

local function EnsureToast()
  if toast then return true end
  if InCombatLockdown and InCombatLockdown() then return false end
  toast = CreateFrame("Frame", "RothMinimapPingToast", UIParent, "BackdropTemplate")
  toast:SetSize(190, 36)
  toast:SetFrameStrata("HIGH")
  toast:SetPoint("TOP", Minimap, "BOTTOM", 0, -8)
  toast:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  toast:SetBackdropColor(0, 0, 0, 0.65)
  toast:SetBackdropBorderColor(1, 1, 1, 0.15)
  toast:Hide()

  text = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("CENTER")
  text:SetText("Map ping received")

  animation = toast:CreateAnimationGroup()
  local fadeIn = animation:CreateAnimation("Alpha")
  fadeIn:SetOrder(1)
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(0.10)
  hold = animation:CreateAnimation("Alpha")
  hold:SetOrder(2)
  hold:SetFromAlpha(1)
  hold:SetToAlpha(1)
  hold:SetDuration(3)
  local fadeOut = animation:CreateAnimation("Alpha")
  fadeOut:SetOrder(3)
  fadeOut:SetFromAlpha(1)
  fadeOut:SetToAlpha(0)
  fadeOut:SetDuration(0.30)
  animation:SetScript("OnFinished", function() toast:Hide() end)
  return true
end

local function PlaySoundSafe()
  if not (PlaySound and SOUNDKIT) then return end
  local sound = SOUNDKIT.MAP_PING or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
  if sound then pcall(PlaySound, sound, "Master") end
end

local function OnPing()
  local db = ns.db and ns.db.ping
  if not (ns.db and ns.db.enabled and db and db.enabled) then return end

  if db.where == "chat" then
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffRothMinimap:|r map ping received") end
  elseif EnsureToast() then
    hold:SetDuration(U.clamp(U.SafeNumber(db.duration) or 3, 1, 10))
    animation:Stop()
    toast:Show()
    animation:Play()
  end

  if ns.skin and type(ns.skin.Pulse) == "function" then ns.skin:Pulse("ping") end
  if db.sound then PlaySoundSafe() end
end

function M:Apply()
  local enabled = ns.db and ns.db.enabled and ns.db.ping and ns.db.ping.enabled
  if enabled and not registered then
    ns.RegisterEvent("MINIMAP_PING", OnPing)
    registered = true
  elseif not enabled and registered then
    ns.UnregisterEvent("MINIMAP_PING", OnPing)
    registered = false
  end
  if not enabled and toast then toast:Hide() end
end

function M:Disable()
  if registered then ns.UnregisterEvent("MINIMAP_PING", OnPing) end
  registered = false
  if toast then toast:Hide() end
end
