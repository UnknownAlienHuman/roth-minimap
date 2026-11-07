-- Roth Minimap ping notification for Retail 12.1.5.
-- MINIMAP_PING is a CallbackEvent with secret payloads; arguments are ignored.

local _, ns = ...
ns.ping = ns.ping or {}
local M = ns.ping
local U = ns.util

local toast
local accent
local text
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

local function ReadAccent()
  local color = ns.db and ns.db.skin and U.SafeTable(ns.db.skin.runesColor)
  if not color then return 1, 0.34, 0.10 end
  return U.SafeNumber(color[1]) or 1,
    U.SafeNumber(color[2]) or 0.34,
    U.SafeNumber(color[3]) or 0.10
end

local function SyncToastStyle()
  if not toast then return end

  local r, g, b = ReadAccent()
  toast:SetBackdropColor(0.018, 0.014, 0.012, 0.88)
  toast:SetBackdropBorderColor(r, g, b, 0.34)
  if accent then accent:SetVertexColor(r, g, b, 0.92) end
  if text then text:SetTextColor(0.95, 0.91, 0.84, 1) end

  local strata = U.SafeGet(Minimap, "GetFrameStrata")
  local level = U.SafeNumber(U.SafeGet(Minimap, "GetFrameLevel"))
  if type(strata) == "string" then toast:SetFrameStrata(strata) end
  if level and level >= 0 then toast:SetFrameLevel(level + 2) end
end

local function EnsureToast()
  if toast then
    SyncToastStyle()
    return true
  end
  if type(InCombatLockdown) == "function" and InCombatLockdown() then return false end
  if not U.CanUseObject(_G.Minimap) then return false end

  toast = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
  toast:EnableMouse(false)
  toast:SetSize(168, 30)
  toast:SetPoint("TOP", Minimap, "BOTTOM", 0, -10)
  toast:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  U.SafeCall(toast, "SetClampedToScreen", true)
  toast:Hide()

  accent = toast:CreateTexture(nil, "ARTWORK")
  accent:SetTexture("Interface\\Buttons\\WHITE8x8")
  accent:SetPoint("TOPLEFT", toast, "TOPLEFT", 0, -1)
  accent:SetPoint("BOTTOMLEFT", toast, "BOTTOMLEFT", 0, 1)
  accent:SetWidth(2)

  text = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("LEFT", toast, "LEFT", 11, 0)
  text:SetText("Map ping received")

  animation = toast:CreateAnimationGroup()
  local fadeIn = animation:CreateAnimation("Alpha")
  fadeIn:SetOrder(1)
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(0.08)
  local slideIn = animation:CreateAnimation("Translation")
  slideIn:SetOrder(1)
  slideIn:SetOffset(0, 4)
  slideIn:SetDuration(0.08)
  hold = animation:CreateAnimation("Alpha")
  hold:SetOrder(2)
  hold:SetFromAlpha(1)
  hold:SetToAlpha(1)
  hold:SetDuration(3)
  local fadeOut = animation:CreateAnimation("Alpha")
  fadeOut:SetOrder(3)
  fadeOut:SetFromAlpha(1)
  fadeOut:SetToAlpha(0)
  fadeOut:SetDuration(0.22)
  animation:SetScript("OnPlay", function() toast:Show() end)
  animation:SetScript("OnStop", ResetToast)
  animation:SetScript("OnFinished", ResetToast)

  Minimap:HookScript("OnHide", StopToast)
  M.toast = toast
  SyncToastStyle()
  return true
end

local function OnPing()
  local db = ns.db and ns.db.ping
  if not (ns.db and ns.db.enabled and db and db.enabled) then return end

  if db.where == "chat" then
    StopToast()
    if DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage("|cffd68a42Roth Minimap:|r map ping received")
    end
  elseif U.SafeGet(Minimap, "IsVisible") == true and EnsureToast() then
    hold:SetDuration(U.clamp(U.SafeNumber(db.duration) or 3, 1, 10))
    animation:Stop()
    SyncToastStyle()
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

  if toast then SyncToastStyle() end
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
