-- Roth Minimap - Zoom module
--
-- Features:
--   * Mousewheel zoom (no taint; uses HookScript)
--   * Optional auto zoom-out after delay
--   * Two reset modes: smooth (step) or snap (to 0)
--
-- Performance:
--   * Only schedules a single C_Timer.After per wheel action.

local ADDON, ns = ...

ns.zoom = ns.zoom or {}
local M = ns.zoom

local resetTimer = nil
local hooked = false
local enabled = false

local function cancelReset()
  if resetTimer and resetTimer.Cancel then
    resetTimer:Cancel()
  end
  resetTimer = nil
end

local function resetZoom(mode)
  cancelReset()
  if not enabled then return end
  if InCombatLockdown() then return end

  if mode == "snap" then
    Minimap:SetZoom(0)
    return
  end

  -- Smooth: step down over a few ticks
  local z = Minimap:GetZoom() or 0
  if z <= 0 then return end
  local step = 1
  local function tick()
    if not enabled then return end
    if InCombatLockdown() then return end
    z = (Minimap:GetZoom() or 0) - step
    if z <= 0 then
      Minimap:SetZoom(0)
      return
    end
    Minimap:SetZoom(z)
    C_Timer.After(0.08, tick)
  end
  tick()
end

local function scheduleReset()
  cancelReset()
  local db = ns.db and ns.db.zoom
  if not (db and db.autoReset) then return end
  local delay = ns.util.clamp(tonumber(db.delay) or 3, 1, 10)

  resetTimer = C_Timer.NewTimer(delay, function()
    local mode = (db.mode == "snap") and "snap" or "smooth"
    resetZoom(mode)
  end)
end

local function onWheel(_, delta)
  if not enabled then return end
  if InCombatLockdown() then return end

  if delta > 0 then
    Minimap_ZoomIn()
  else
    Minimap_ZoomOut()
  end

  scheduleReset()
end

function M:Apply()
  local db = ns.db and ns.db.zoom
  enabled = (ns.db and ns.db.enabled and db and db.mousewheel) and true or false

  if enabled then
    Minimap:EnableMouseWheel(true)
    if not hooked then
      hooked = true
      Minimap:HookScript("OnMouseWheel", onWheel)
    end
  else
    cancelReset()
  end
end

function M:Disable()
  enabled = false
  cancelReset()
end
