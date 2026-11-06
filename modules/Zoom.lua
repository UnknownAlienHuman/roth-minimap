-- Roth Minimap native-wheel zoom reset for Retail 12.1.5.
-- Blizzard owns the wheel input and performs the only zoom step.

local _, ns = ...
ns.zoom = ns.zoom or {}
local M = ns.zoom
local U = ns.util

local hooked = false
local enabled = false
local resetTimer

local function IsCombatLocked()
  return type(InCombatLockdown) == "function" and InCombatLockdown()
end

local function IsEnabledNow()
  local db = ns.db and ns.db.zoom
  return enabled and ns.db and ns.db.enabled and db and db.autoReset
end

local function CancelReset()
  if resetTimer and type(resetTimer.Cancel) == "function" then resetTimer:Cancel() end
  resetTimer = nil
end

local function ResetZoom()
  if not IsEnabledNow() or IsCombatLocked() or not U.CanUseObject(_G.Minimap) then return end

  local levels = U.SafeNumber(U.SafeGet(Minimap, "GetZoomLevels"))
  local zoom = U.SafeNumber(U.SafeGet(Minimap, "GetZoom"))
  if not levels or levels < 1 or not zoom then return end

  local maximum = levels - 1
  if zoom <= 0 or zoom > maximum then return end
  U.SafeCall(Minimap, "SetZoom", 0)
end

local function ScheduleReset()
  CancelReset()
  local db = ns.db and ns.db.zoom
  if not (IsEnabledNow() and db and C_Timer and type(C_Timer.NewTimer) == "function") then return end

  local delay = U.clamp(U.SafeNumber(db.delay) or 3, 1, 10)
  resetTimer = C_Timer.NewTimer(delay, function()
    resetTimer = nil
    ResetZoom()
  end)
end

local function OnWheel(_, delta)
  if not IsEnabledNow() or IsCombatLocked() then return end
  delta = U.SafeNumber(delta)
  if not delta or delta == 0 then return end

  -- HookScript runs after MinimapMixin:OnMouseWheel. Observe only.
  local zoom = U.SafeNumber(U.SafeGet(Minimap, "GetZoom"))
  if zoom and zoom > 0 then
    ScheduleReset()
  else
    CancelReset()
  end
end

local function AttachHooks()
  if hooked then return true end
  if not U.CanUseObject(_G.Minimap) or type(Minimap.HookScript) ~= "function" then return false end

  Minimap:HookScript("OnMouseWheel", OnWheel)
  Minimap:HookScript("OnHide", CancelReset)
  hooked = true
  return true
end

function M:Apply()
  enabled = ns.db and ns.db.enabled and ns.db.zoom and ns.db.zoom.autoReset or false
  if not enabled then
    CancelReset()
    return true
  end
  return AttachHooks()
end

function M:ApplySafeState()
  if not (ns.db and ns.db.enabled and ns.db.zoom and ns.db.zoom.autoReset) then
    enabled = false
    CancelReset()
  end
  return true
end

function M:Disable()
  enabled = false
  CancelReset()
end

local lifecycleEvents = CreateFrame("Frame")
lifecycleEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
lifecycleEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
lifecycleEvents:SetScript("OnEvent", CancelReset)
