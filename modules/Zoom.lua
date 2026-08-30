-- RothMinimap wheel zoom for Retail 12.1.
-- Uses only Minimap's public zoom methods and one cancellable reset timer.

local ADDON_NAME, ns = ...
ns.zoom = ns.zoom or {}
local M = ns.zoom
local U = ns.util

local hooked = false
local enabled = false
local resetTimer

local function CancelReset()
  if resetTimer and type(resetTimer.Cancel) == "function" then resetTimer:Cancel() end
  resetTimer = nil
end

local function SetZoom(value)
  if not U.CanUseObject(_G.Minimap) then return false end
  value = U.SafeNumber(value)
  if not value then return false end
  if value < 0 then value = 0 elseif value > 5 then value = 5 end
  return U.SafeCall(Minimap, "SetZoom", value)
end

local function ScheduleReset()
  CancelReset()
  local db = ns.db and ns.db.zoom
  if not (db and db.autoReset and C_Timer and type(C_Timer.NewTimer) == "function") then return end
  local delay = U.clamp(U.SafeNumber(db.delay) or 3, 1, 10)
  resetTimer = C_Timer.NewTimer(delay, function()
    resetTimer = nil
    if enabled and not InCombatLockdown() then SetZoom(0) end
  end)
end

local function OnWheel(_, delta)
  if not enabled or InCombatLockdown() then return end
  delta = U.SafeNumber(delta)
  if not delta then return end
  local zoom = U.SafeNumber(U.SafeGet(Minimap, "GetZoom")) or 0
  if delta > 0 then zoom = zoom + 1 else zoom = zoom - 1 end
  SetZoom(zoom)
  ScheduleReset()
end

function M:Apply()
  enabled = ns.db and ns.db.enabled and ns.db.zoom and ns.db.zoom.mousewheel or false
  if enabled then
    U.SafeCall(Minimap, "EnableMouseWheel", true)
    if not hooked and U.CanUseObject(Minimap) and type(Minimap.HookScript) == "function" then
      Minimap:HookScript("OnMouseWheel", OnWheel)
      hooked = true
    end
  else
    CancelReset()
  end
end

function M:Disable()
  enabled = false
  CancelReset()
end
