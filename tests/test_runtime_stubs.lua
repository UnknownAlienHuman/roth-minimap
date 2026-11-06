local function object(methods)
  methods = methods or {}
  function methods:CanBeAccessedInContext() return true end
  function methods:IsForbidden() return false end
  return methods
end

canaccessvalue = function() return true end
canaccesstable = function() return true end
InCombatLockdown = function() return false end
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}

local eventFrame
CreateFrame = function()
  local frame = object({ events = {}, scripts = {} })
  function frame:RegisterEvent(event) self.events[event] = true end
  function frame:UnregisterEvent(event) self.events[event] = nil end
  function frame:SetScript(script, callback) self.scripts[script] = callback end
  eventFrame = eventFrame or frame
  return frame
end

local callbacks = {}
EventRegistry = {
  RegisterCallback = function(_, event, callback, owner)
    callbacks[event] = { callback = callback, owner = owner }
  end,
}

local timers = {}
C_Timer = {
  NewTimer = function(delay, callback)
    local timer = { delay = delay, callback = callback, cancelled = false }
    function timer:Cancel() self.cancelled = true end
    timers[#timers + 1] = timer
    return timer
  end,
}

local function alphaObject(alpha)
  return object({
    alpha = alpha,
    GetAlpha = function(self) return self.alpha end,
    SetAlpha = function(self, value) self.alpha = value end,
  })
end

MinimapCompassTexture = alphaObject(0.8)
MinimapBackdrop = alphaObject(0.7)
MinimapCluster = { BorderTop = alphaObject(0.6) }

local wheelHook
local hideHook
Minimap = object({ zoom = 0, levels = 6, visible = true })
function Minimap:SetMaskTexture(texture) self.mask = texture end
function Minimap:GetZoom() return self.zoom end
function Minimap:GetZoomLevels() return self.levels end
function Minimap:SetZoom(value) self.zoom = value end
function Minimap:IsVisible() return self.visible end
function Minimap:HookScript(script, callback)
  if script == "OnMouseWheel" then wheelHook = callback end
  if script == "OnHide" then hideHook = callback end
end

geterrorhandler = function()
  return function(message) error(message, 0) end
end

RothMinimapDB = {
  version = 4,
  enabled = true,
  squareMask = true,
  hideBlizzardArt = true,
  debug = true,
  skin = { enabled = true },
  ping = { enabled = true, sound = true },
  zoom = { mousewheel = false, autoReset = true, delay = 4 },
}

local ns = {}
assert(loadfile("RothMinimap.lua"))("RothMinimap", ns)
assert(ns.db.version == 5)
assert(ns.db.debug == true)
assert(ns.db.ping.sound == nil)
assert(ns.db.zoom.mousewheel == nil)
assert(ns.db.zoom.autoReset == false)

local rootRef = ns.db
local skinRef = ns.db.skin
local pingRef = ns.db.ping
local zoomRef = ns.db.zoom

assert(loadfile("modules/Zoom.lua"))("RothMinimap", ns)
ns.db.zoom.autoReset = true
assert(ns.ApplyAll())

assert(MinimapCompassTexture.alpha == 0)
assert(MinimapCluster.BorderTop.alpha == 0)
assert(MinimapBackdrop.alpha == 0.7)
assert(type(wheelHook) == "function")

-- Blizzard has already applied one native wheel step before HookScript runs.
Minimap.zoom = 1
wheelHook(Minimap, 1)
assert(Minimap.zoom == 1, "addon performed a duplicate wheel zoom step")
local resetTimer = timers[#timers]
assert(resetTimer and resetTimer.delay == 4)
resetTimer.callback()
assert(Minimap.zoom == 0)

ns.db.hideBlizzardArt = false
ns.ApplyAll()
assert(MinimapCompassTexture.alpha == 0.8)
assert(MinimapCluster.BorderTop.alpha == 0.6)
assert(MinimapBackdrop.alpha == 0.7)

ns.ResetDB()
assert(ns.db == rootRef, "reset replaced the registered root table")
assert(ns.db.skin == skinRef, "reset replaced the registered skin table")
assert(ns.db.ping == pingRef, "reset replaced the registered ping table")
assert(ns.db.zoom == zoomRef, "reset replaced the registered zoom table")
assert(RothMinimapDB == rootRef)

print("PASS: schema migration, exact art ownership, native wheel observation and in-place reset")
