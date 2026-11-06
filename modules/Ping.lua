-- Roth Minimap ping notification for Retail 12.1.5.
-- MINIMAP_PING is a CallbackEvent with secret payloads; arguments are ignored.

local _, ns = ...
ns.ping = ns.ping or {}
local M = ns.ping
local U = ns.util

local toast
local animation
local hold
local registered = false
local callbackFrame = CreateFrame("Frame")

local function ResetToast()
  if toast then
    toast:SetAlpha(0)
    toast:Hide()
  end
end

local function StopToast()
  if animation then animation:Stop() end
  ResetToast()
end

local function EnsureToast()
  if toast then return true end
  if type(InCombatLockdown) == "function" and InCombatLockdown() then return false end
  if not U.CanUseObject(_G.Minimap) then return false end

  toast = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
  toast:EnableMouse(false)
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

  local text = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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
  animation:SetScript("OnStop", ResetToast)
  animation:SetScript("OnFinished", ResetToast)

  Minimap:HookScript("OnHide", StopToast)
  M.toast = toast
  return true
end

local function OnPing()
  local db = ns.db and ns.db.ping
  if not (ns.db and ns.db.enabled and db and db.enabled) then return end

  if db.where == "chat" then
    StopToast()
    if DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffRoth Minimap:|r map ping received")
    end
  elseif U.SafeGet(Minimap, "IsVisible") == true and EnsureToast() then
    hold:SetDuration(U.clamp(U.SafeNumber(db.duration) or 3, 1, 10))
    animation:Stop()
    toast:SetAlpha(1)
    toast:Show()
    animation:Play()
  end

  if ns.skin and type(ns.skin.Pulse) == "function" then ns.skin:Pulse() end
end

local function RegisterPing()
  if registered then return true end
  if type(callbackFrame.RegisterEventCallback) ~= "function" then return false end
  callbackFrame:RegisterEventCallback("MINIMAP_PING", OnPing)
  registered = true
  return true
end

local function UnregisterPing()
  if not registered then return true end
  if type(callbackFrame.UnregisterEventCallback) ~= "function" then return false end
  callbackFrame:UnregisterEventCallback("MINIMAP_PING")
  registered = false
  return true
end

function M:Apply()
  local db = ns.db and ns.db.ping
  local enabled = ns.db and ns.db.enabled and db and db.enabled

  if enabled and db.where == "toast" and not EnsureToast() then return false end
  if enabled then
    if not RegisterPing() then return false end
  elseif not UnregisterPing() then
    return false
  end

  if not enabled or db.where ~= "toast" then StopToast() end
  return true
end

function M:ApplySafeState()
  local db = ns.db and ns.db.ping
  if not (ns.db and ns.db.enabled and db and db.enabled and db.where == "toast") then
    StopToast()
  end
  return true
end

function M:Disable()
  UnregisterPing()
  StopToast()
end
