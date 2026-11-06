-- RothMinimap core for Retail 12.1.5.
--
-- Ownership boundary:
--   * Blizzard/Edit Mode owns MinimapCluster position, size and child widgets.
--   * RothMinimap owns only its SavedVariables, mask, exact decorative alpha,
--     and addon-created skin/ping/zoom-reset objects.
--   * No Blizzard clock/calendar/tracking/difficulty/compartment frame is
--     reparented, reanchored, resized, method-overridden or collected.

local ADDON_NAME, ns = ...
ns = ns or {}

ns.VERSION = "0.4.1"
ns.DB_VERSION = 5
ns.media = "Interface\\AddOns\\RothMinimap\\media\\"

local DEFAULT_MASK = "Interface\\Minimap\\UI-Minimap-Background"
local SQUARE_MASK = ns.media .. "mask_square.tga"

local DEFAULTS = {
  version = ns.DB_VERSION,
  enabled = true,
  squareMask = true,
  hideBlizzardArt = true,
  debug = false,

  skin = {
    enabled = true,
    border = true,
    runes = false,
    vignette = true,
    fire = true,
    borderColor = { 1, 1, 1, 1 },
    runesColor = { 1, 0.35, 0.12, 0.20 },
    vignetteAlpha = 0.40,
    fireIdleAlpha = 0.14,
    fireCombatAlpha = 0.42,
    fireFPS = 8,
    outset = 34,
  },

  ping = {
    enabled = true,
    where = "toast",
    duration = 3,
  },

  zoom = {
    autoReset = true,
    delay = 3,
  },
}

local function CanAccess(value)
  if type(canaccessvalue) == "function" then
    local ok, accessible = pcall(canaccessvalue, value)
    return ok and accessible == true
  end
  if type(issecretvalue) == "function" then
    local ok, secret = pcall(issecretvalue, value)
    return ok and secret ~= true
  end
  return true
end

local function SafeBoolean(value)
  if not CanAccess(value) or type(value) ~= "boolean" then return nil end
  return value
end

local function SafeNumber(value)
  if not CanAccess(value) or type(value) ~= "number" or value ~= value then return nil end
  return value
end

local function SafeString(value)
  if not CanAccess(value) or type(value) ~= "string" then return nil end
  return value
end

local function SafeTable(value)
  if not CanAccess(value) or type(value) ~= "table" then return nil end
  if type(canaccesstable) == "function" then
    local ok, accessible = pcall(canaccesstable, value)
    if not ok or accessible ~= true then return nil end
  elseif type(issecrettable) == "function" then
    local ok, secret = pcall(issecrettable, value)
    if not ok or secret == true then return nil end
  end
  return value
end

local function CanUseObject(object)
  if not object then return false end
  if type(object.CanBeAccessedInContext) == "function" then
    local ok, accessible = pcall(object.CanBeAccessedInContext, object)
    if not ok or SafeBoolean(accessible) ~= true then return false end
  end
  if type(object.IsForbidden) == "function" then
    local ok, forbidden = pcall(object.IsForbidden, object)
    if not ok or SafeBoolean(forbidden) ~= false then return false end
  end
  return true
end

local function SafeCall(object, methodName, ...)
  if not CanUseObject(object) then return false end
  local method = object[methodName]
  if type(method) ~= "function" then return false end
  return pcall(method, object, ...)
end

local function SafeGet(object, methodName, ...)
  if not CanUseObject(object) then return nil end
  local method = object[methodName]
  if type(method) ~= "function" then return nil end
  local ok, value = pcall(method, object, ...)
  if ok and CanAccess(value) then return value end
  return nil
end

local function Clamp(value, fallback, minimum, maximum)
  value = SafeNumber(value)
  if not value then return fallback end
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

local function ClampValue(value, minimum, maximum)
  value = SafeNumber(value)
  if not value then return minimum end
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

local function MergeDefaults(destination, source)
  destination = SafeTable(destination) or {}
  for key, value in pairs(source) do
    if type(value) == "table" then
      destination[key] = MergeDefaults(destination[key], value)
    elseif type(destination[key]) ~= type(value) then
      destination[key] = value
    end
  end
  return destination
end

local function ReplaceContents(destination, source)
  for key in pairs(destination) do
    if source[key] == nil then destination[key] = nil end
  end
  for key, value in pairs(source) do
    if type(value) == "table" then
      local child = SafeTable(destination[key])
      if not child then
        child = {}
        destination[key] = child
      end
      ReplaceContents(child, value)
    else
      destination[key] = value
    end
  end
end

local function CopyColor(value, fallback)
  local source = SafeTable(value) or fallback
  return {
    Clamp(source[1], fallback[1], 0, 1),
    Clamp(source[2], fallback[2], 0, 1),
    Clamp(source[3], fallback[3], 0, 1),
    Clamp(source[4], fallback[4], 0, 1),
  }
end

local function SanitizeDB(db)
  MergeDefaults(db, DEFAULTS)
  db.version = ns.DB_VERSION
  db.enabled = SafeBoolean(db.enabled) ~= false
  db.squareMask = SafeBoolean(db.squareMask) ~= false
  db.hideBlizzardArt = SafeBoolean(db.hideBlizzardArt) ~= false
  db.debug = SafeBoolean(db.debug) == true

  db.skin = SafeTable(db.skin) or {}
  MergeDefaults(db.skin, DEFAULTS.skin)
  db.skin.enabled = SafeBoolean(db.skin.enabled) ~= false
  db.skin.border = SafeBoolean(db.skin.border) ~= false
  db.skin.runes = SafeBoolean(db.skin.runes) == true
  db.skin.vignette = SafeBoolean(db.skin.vignette) ~= false
  db.skin.fire = SafeBoolean(db.skin.fire) ~= false
  db.skin.borderColor = CopyColor(db.skin.borderColor, DEFAULTS.skin.borderColor)
  db.skin.runesColor = CopyColor(db.skin.runesColor, DEFAULTS.skin.runesColor)
  db.skin.vignetteAlpha = Clamp(db.skin.vignetteAlpha, 0.40, 0, 1)
  db.skin.fireIdleAlpha = Clamp(db.skin.fireIdleAlpha, 0.14, 0, 1)
  db.skin.fireCombatAlpha = Clamp(db.skin.fireCombatAlpha, 0.42, 0, 1)
  db.skin.fireFPS = math.floor(Clamp(db.skin.fireFPS, 8, 1, 20) + 0.5)
  db.skin.outset = math.floor(Clamp(db.skin.outset, 34, 0, 96) + 0.5)

  db.ping = SafeTable(db.ping) or {}
  MergeDefaults(db.ping, DEFAULTS.ping)
  db.ping.enabled = SafeBoolean(db.ping.enabled) ~= false
  db.ping.where = SafeString(db.ping.where) == "chat" and "chat" or "toast"
  db.ping.duration = Clamp(db.ping.duration, 3, 1, 10)
  db.ping.sound = nil

  db.zoom = SafeTable(db.zoom) or {}
  MergeDefaults(db.zoom, DEFAULTS.zoom)
  db.zoom.autoReset = SafeBoolean(db.zoom.autoReset) ~= false
  db.zoom.delay = Clamp(db.zoom.delay, 3, 1, 10)
  db.zoom.mousewheel = nil

  -- Retire ownership that cannot be made generic and safe on Retail 12.1.5.
  db.buttons = nil
  db.position = nil
  db.mover = nil
  db.clock = nil
  db.calendar = nil
  db.tracking = nil
  db.difficulty = nil
  db.compartment = nil
  db.hud = nil
  db.hide = nil
end

local function NewDB()
  local db = {}
  MergeDefaults(db, DEFAULTS)
  SanitizeDB(db)
  return db
end

local function MigrateDB(raw)
  local old = SafeTable(raw)
  if not old then return NewDB() end
  local migrated = NewDB()

  local oldGeneral = SafeTable(old.general)
  local oldSkin = SafeTable(old.skin)
  local oldPing = SafeTable(old.ping)
  local oldZoom = SafeTable(old.zoom)

  migrated.enabled = SafeBoolean(old.enabled)
  if migrated.enabled == nil then migrated.enabled = true end
  migrated.squareMask = SafeBoolean(old.squareMask)
  if migrated.squareMask == nil and oldGeneral then migrated.squareMask = SafeBoolean(oldGeneral.square) end
  if migrated.squareMask == nil then migrated.squareMask = true end
  migrated.hideBlizzardArt = SafeBoolean(old.hideBlizzardArt)
  if migrated.hideBlizzardArt == nil and oldGeneral then
    migrated.hideBlizzardArt = SafeBoolean(oldGeneral.hideBlizzardArt)
  end
  if migrated.hideBlizzardArt == nil then migrated.hideBlizzardArt = true end
  migrated.debug = SafeBoolean(old.debug) == true

  if oldSkin then
    migrated.skin.enabled = SafeBoolean(oldSkin.enabled) ~= false
    migrated.skin.border = SafeBoolean(oldSkin.border) ~= false
    migrated.skin.runes = SafeBoolean(oldSkin.runes) == true
    migrated.skin.vignette = SafeBoolean(oldSkin.vignette) ~= false
    migrated.skin.fire = SafeBoolean(oldSkin.fire) ~= false
    migrated.skin.vignetteAlpha = SafeNumber(oldSkin.vignetteAlpha) or migrated.skin.vignetteAlpha
    migrated.skin.fireIdleAlpha = SafeNumber(oldSkin.fireIdleAlpha) or migrated.skin.fireIdleAlpha
    migrated.skin.fireCombatAlpha = SafeNumber(oldSkin.fireCombatAlpha) or migrated.skin.fireCombatAlpha
    migrated.skin.fireFPS = SafeNumber(oldSkin.fireFPS) or migrated.skin.fireFPS
    migrated.skin.outset = SafeNumber(oldSkin.outset) or migrated.skin.outset
    migrated.skin.borderColor = CopyColor(oldSkin.borderColor, migrated.skin.borderColor)
    migrated.skin.runesColor = CopyColor(oldSkin.runesColor, migrated.skin.runesColor)
  end

  if oldPing then
    migrated.ping.enabled = SafeBoolean(oldPing.enabled) ~= false
    migrated.ping.where = SafeString(oldPing.where) or migrated.ping.where
    migrated.ping.duration = SafeNumber(oldPing.duration) or migrated.ping.duration
  end

  if oldZoom then
    local oldAutoReset = SafeBoolean(oldZoom.autoReset)
    local oldMousewheel = SafeBoolean(oldZoom.mousewheel)
    if oldAutoReset ~= nil then migrated.zoom.autoReset = oldAutoReset end
    if oldMousewheel == false then migrated.zoom.autoReset = false end
    migrated.zoom.delay = SafeNumber(oldZoom.delay) or migrated.zoom.delay
  end

  SanitizeDB(migrated)
  return migrated
end

RothMinimapDB = MigrateDB(RothMinimapDB)
ns.db = RothMinimapDB

ns.util = {
  CanAccess = CanAccess,
  SafeBoolean = SafeBoolean,
  SafeNumber = SafeNumber,
  SafeString = SafeString,
  SafeTable = SafeTable,
  CanUseObject = CanUseObject,
  SafeCall = SafeCall,
  SafeGet = SafeGet,
  clamp = ClampValue,
}

local eventFrame = CreateFrame("Frame")
local eventHandlers = {}

function ns.RegisterEvent(event, callback)
  if type(event) ~= "string" or type(callback) ~= "function" then return false end
  local handlers = eventHandlers[event]
  if not handlers then
    handlers = {}
    eventHandlers[event] = handlers
    eventFrame:RegisterEvent(event)
  end
  handlers[callback] = true
  return true
end

function ns.UnregisterEvent(event, callback)
  local handlers = eventHandlers[event]
  if not handlers then return end
  handlers[callback] = nil
  if not next(handlers) then
    eventHandlers[event] = nil
    eventFrame:UnregisterEvent(event)
  end
end

local pendingApply = false
local geometryRefreshTimer
local artState = setmetatable({}, { __mode = "k" })

local function Debug(message)
  if not ns.db.debug then return end
  local text = SafeString(message) or "<unavailable>"
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffRothMinimap:|r " .. text)
  end
end

local function ReportError(scope, errorText)
  local message = "RothMinimap " .. scope .. ": " .. tostring(errorText)
  local handler = type(geterrorhandler) == "function" and geterrorhandler() or nil
  if type(handler) == "function" then
    handler(message)
  elseif DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff5555" .. message .. "|r")
  end
end

local function CallModule(moduleName, methodName)
  local module = ns[moduleName]
  local method = module and module[methodName]
  if type(method) ~= "function" then return true end
  local ok, result = pcall(method, module)
  if not ok then
    ReportError(moduleName .. "." .. methodName, result)
    return false
  end
  return result ~= false
end

local function SnapshotAlpha(object)
  if not CanUseObject(object) or artState[object] then return end
  local alpha = SafeGet(object, "GetAlpha")
  artState[object] = { alpha = SafeNumber(alpha) or 1 }
end

local function SetDecorativeAlpha(object, hidden)
  if not CanUseObject(object) then return end
  SnapshotAlpha(object)
  local state = artState[object]
  SafeCall(object, "SetAlpha", hidden and 0 or (state and state.alpha or 1))
end

local function ApplyBlizzardArt()
  local hidden = ns.db.enabled and ns.db.hideBlizzardArt

  -- Exact selected-source decorative owners only. MinimapBackdrop is excluded:
  -- it owns the housing static overlay and expansion landing-page controls.
  SetDecorativeAlpha(_G.MinimapCompassTexture, hidden)
  local cluster = _G.MinimapCluster
  SetDecorativeAlpha(cluster and cluster.BorderTop, hidden)
end

local function ApplyMask()
  if not CanUseObject(_G.Minimap) then return end
  local texture = ns.db.enabled and ns.db.squareMask and SQUARE_MASK or DEFAULT_MASK
  SafeCall(Minimap, "SetMaskTexture", texture)
end

local function ApplyModules()
  CallModule("skin", "Apply")
  CallModule("ping", "Apply")
  CallModule("zoom", "Apply")
end

local function CancelGeometryRefresh()
  if geometryRefreshTimer and type(geometryRefreshTimer.Cancel) == "function" then
    geometryRefreshTimer:Cancel()
  end
  geometryRefreshTimer = nil
end

local function RefreshOwnedGeometry()
  if type(InCombatLockdown) == "function" and InCombatLockdown() then
    pendingApply = true
    return false
  end
  return CallModule("skin", "UpdateGeometry")
end

function ns.QueueGeometryRefresh()
  if geometryRefreshTimer then return end
  if C_Timer and type(C_Timer.NewTimer) == "function" then
    geometryRefreshTimer = C_Timer.NewTimer(0, function()
      geometryRefreshTimer = nil
      RefreshOwnedGeometry()
    end)
  else
    RefreshOwnedGeometry()
  end
end

function ns.ApplyAll()
  SanitizeDB(ns.db)
  if type(InCombatLockdown) == "function" and InCombatLockdown() then
    pendingApply = true
    return false
  end

  pendingApply = false
  CancelGeometryRefresh()
  ApplyMask()
  ApplyBlizzardArt()
  ApplyModules()
  return true
end

function ns.ResetDB()
  local fresh = NewDB()
  ReplaceContents(ns.db, fresh)
  RothMinimapDB = ns.db
  ns.ApplyAll()
  if type(ns.RefreshSettings) == "function" then ns.RefreshSettings() end
end

function ns.GetStatus()
  return {
    enabled = ns.db.enabled,
    squareMask = ns.db.squareMask,
    hideBlizzardArt = ns.db.hideBlizzardArt,
    editModeOwnsGeometry = true,
    buttonBag = "removed",
    zoomReset = ns.db.zoom.autoReset,
    pendingApply = pendingApply,
  }
end

local function RegisterEditModeCallbacks()
  if ns._editModeRegistered or not EventRegistry or type(EventRegistry.RegisterCallback) ~= "function" then return end
  ns._editModeRegistered = true
  EventRegistry:RegisterCallback("EditMode.Exit", ns.QueueGeometryRefresh, ns)
  EventRegistry:RegisterCallback("EditMode.SavedLayouts", ns.QueueGeometryRefresh, ns)
end

local function OnCoreEvent(_, event, ...)
  if event == "ADDON_LOADED" then
    local loaded = ...
    if SafeString(loaded) ~= ADDON_NAME then return end
    ns.UnregisterEvent("ADDON_LOADED", OnCoreEvent)
    Debug("loaded v" .. ns.VERSION)
  elseif event == "PLAYER_LOGIN" then
    RegisterEditModeCallbacks()
    ns.ApplyAll()
  elseif event == "PLAYER_ENTERING_WORLD" or event == "UI_SCALE_CHANGED" then
    ns.ApplyAll()
  elseif event == "PLAYER_REGEN_ENABLED" and pendingApply then
    ns.ApplyAll()
  end
end

for _, event in ipairs({
  "ADDON_LOADED",
  "PLAYER_LOGIN",
  "PLAYER_ENTERING_WORLD",
  "PLAYER_REGEN_ENABLED",
  "UI_SCALE_CHANGED",
}) do
  ns.RegisterEvent(event, OnCoreEvent)
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
  local handlers = eventHandlers[event]
  if not handlers then return end
  local snapshot = {}
  for callback in pairs(handlers) do snapshot[#snapshot + 1] = callback end
  for _, callback in ipairs(snapshot) do
    local ok, errorText = pcall(callback, self, event, ...)
    if not ok then ReportError("event " .. event, errorText) end
  end
end)

function _G.RothMinimap_OpenConfig()
  if ns.OpenOptions then ns.OpenOptions() end
end

SLASH_ROTHMINIMAP1 = "/rmmap"
SlashCmdList.ROTHMINIMAP = function(message)
  message = SafeString(message) or ""
  message = message:lower():gsub("^%s+", ""):gsub("%s+$", "")
  if message == "toggle" then
    ns.db.enabled = not ns.db.enabled
    ns.ApplyAll()
  elseif message == "reset" then
    ns.ResetDB()
  elseif message == "status" then
    local status = ns.GetStatus()
    print(string.format(
      "RothMinimap: enabled=%s square=%s hideArt=%s geometry=Blizzard Edit Mode buttonBag=%s zoomReset=%s pending=%s",
      tostring(status.enabled),
      tostring(status.squareMask),
      tostring(status.hideBlizzardArt),
      status.buttonBag,
      tostring(status.zoomReset),
      tostring(status.pendingApply)
    ))
  elseif message == "config" or message == "options" or message == "" then
    _G.RothMinimap_OpenConfig()
  else
    print("RothMinimap: /rmmap config|toggle|reset|status")
    print("Position and size are controlled by Blizzard Edit Mode.")
  end
end

_G.RothMinimap = ns
