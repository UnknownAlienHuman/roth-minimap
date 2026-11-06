-- Roth Minimap core for Retail 12.1.5.
-- Blizzard/Edit Mode owns native minimap geometry, input and child widgets.

local ADDON_NAME, ns = ...
ns = ns or {}

ns.VERSION = "0.4.4"
ns.DB_VERSION = 7
ns.media = "Interface\\AddOns\\RothMinimap\\media\\"

local DEFAULT_MASK = "Interface\\Minimap\\UI-Minimap-Background"
local SQUARE_MASK = ns.media .. "mask_square.tga"

local DEFAULTS = {
  version = ns.DB_VERSION,
  enabled = true,
  squareMask = true,
  hideBlizzardArt = true,

  skin = {
    enabled = true,
    border = true,
    runes = false,
    vignette = true,
    fire = true,
    borderColor = { 0.25, 0.22, 0.20, 1 },
    runesColor = { 1, 0.35, 0.12, 0.20 },
    vignetteAlpha = 0.22,
    fireIdleAlpha = 0.14,
    fireCombatAlpha = 0.42,
    fireIdleFPS = 2,
    fireCombatFPS = 8,
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

local function CopyColor(value, fallback, alpha)
  local source = SafeTable(value) or fallback
  return {
    Clamp(source[1], fallback[1], 0, 1),
    Clamp(source[2], fallback[2], 0, 1),
    Clamp(source[3], fallback[3], 0, 1),
    Clamp(alpha ~= nil and alpha or source[4], fallback[4], 0, 1),
  }
end

local function SanitizeDB(db)
  local rawSkin = SafeTable(db.skin)
  local unifiedFireFPS = rawSkin and SafeNumber(rawSkin.fireFPS)
  local existingIdleFPS = rawSkin and SafeNumber(rawSkin.fireIdleFPS)
  local existingCombatFPS = rawSkin and SafeNumber(rawSkin.fireCombatFPS)

  MergeDefaults(db, DEFAULTS)
  db.version = ns.DB_VERSION
  db.enabled = SafeBoolean(db.enabled) ~= false
  db.squareMask = SafeBoolean(db.squareMask) ~= false
  db.hideBlizzardArt = SafeBoolean(db.hideBlizzardArt) ~= false

  db.skin = SafeTable(db.skin) or {}
  MergeDefaults(db.skin, DEFAULTS.skin)
  if unifiedFireFPS then
    if existingIdleFPS == nil then
      db.skin.fireIdleFPS = math.min(unifiedFireFPS, DEFAULTS.skin.fireIdleFPS)
    end
    if existingCombatFPS == nil then
      db.skin.fireCombatFPS = unifiedFireFPS
    end
  end
  db.skin.enabled = SafeBoolean(db.skin.enabled) ~= false
  db.skin.border = SafeBoolean(db.skin.border) ~= false
  db.skin.runes = SafeBoolean(db.skin.runes) == true
  db.skin.vignette = SafeBoolean(db.skin.vignette) ~= false
  db.skin.fire = SafeBoolean(db.skin.fire) ~= false
  db.skin.borderColor = CopyColor(db.skin.borderColor, DEFAULTS.skin.borderColor)
  db.skin.runesColor = CopyColor(db.skin.runesColor, DEFAULTS.skin.runesColor)
  db.skin.vignetteAlpha = Clamp(db.skin.vignetteAlpha, DEFAULTS.skin.vignetteAlpha, 0, 1)
  db.skin.fireIdleAlpha = Clamp(db.skin.fireIdleAlpha, DEFAULTS.skin.fireIdleAlpha, 0, 1)
  db.skin.fireCombatAlpha = Clamp(db.skin.fireCombatAlpha, DEFAULTS.skin.fireCombatAlpha, 0, 1)
  db.skin.fireIdleFPS = math.floor(Clamp(db.skin.fireIdleFPS, DEFAULTS.skin.fireIdleFPS, 1, 8) + 0.5)
  db.skin.fireCombatFPS = math.floor(Clamp(db.skin.fireCombatFPS, DEFAULTS.skin.fireCombatFPS, 1, 20) + 0.5)
  db.skin.outset = math.floor(Clamp(db.skin.outset, DEFAULTS.skin.outset, 0, 96) + 0.5)

  db.ping = SafeTable(db.ping) or {}
  MergeDefaults(db.ping, DEFAULTS.ping)
  db.ping.enabled = SafeBoolean(db.ping.enabled) ~= false
  db.ping.where = SafeString(db.ping.where) == "chat" and "chat" or "toast"
  db.ping.duration = Clamp(db.ping.duration, DEFAULTS.ping.duration, 1, 10)

  db.zoom = SafeTable(db.zoom) or {}
  MergeDefaults(db.zoom, DEFAULTS.zoom)
  db.zoom.autoReset = SafeBoolean(db.zoom.autoReset) ~= false
  db.zoom.delay = Clamp(db.zoom.delay, DEFAULTS.zoom.delay, 1, 10)

  -- Retired pre-0.4 ownership and duplicated settings.
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
  db.square = nil
  db.skinEnabled = nil
  db.skinPadding = nil
  db.skin.fireFPS = nil
  db.visual = nil
  db.fire = nil
  db.quickMap = nil
  db.zoneText = nil
  db.shadow = nil
  db.debug = nil
  db.ping.sound = nil
  db.zoom.mousewheel = nil
  db.zoom.mode = nil
  db.zoom.interval = nil
end

local function NewDB()
  local db = {}
  MergeDefaults(db, DEFAULTS)
  SanitizeDB(db)
  return db
end

local function FirstBoolean(...)
  for index = 1, select("#", ...) do
    local value = SafeBoolean(select(index, ...))
    if value ~= nil then return value end
  end
  return nil
end

local function FirstNumber(...)
  for index = 1, select("#", ...) do
    local value = SafeNumber(select(index, ...))
    if value ~= nil then return value end
  end
  return nil
end

local function MigrateLegacyDB(old)
  local migrated = NewDB()
  local general = SafeTable(old.general)
  local visual = SafeTable(old.visual)
  local legacyFire = SafeTable(old.fire)
  local legacyPing = SafeTable(old.ping)
  local legacyZoom = SafeTable(old.zoom)

  local enabled = FirstBoolean(old.enabled, general and general.enabled)
  if enabled ~= nil then migrated.enabled = enabled end

  local square = FirstBoolean(old.squareMask, old.square, general and general.square)
  if square ~= nil then migrated.squareMask = square end

  local hideArt = FirstBoolean(old.hideBlizzardArt, general and general.hideBlizzardArt)
  if hideArt ~= nil then migrated.hideBlizzardArt = hideArt end

  local skinEnabled = SafeBoolean(old.skinEnabled)
  if skinEnabled ~= nil then migrated.skin.enabled = skinEnabled end

  if visual then
    local border = SafeTable(visual.border)
    if border then
      local alpha = SafeNumber(border.alpha)
      migrated.skin.border = alpha == nil or alpha > 0
      migrated.skin.borderColor = CopyColor(border.color, migrated.skin.borderColor, alpha)
    end

    local runes = SafeTable(visual.runes)
    if runes then
      local runesEnabled = SafeBoolean(runes.enabled)
      if runesEnabled ~= nil then migrated.skin.runes = runesEnabled end
      migrated.skin.runesColor = CopyColor(
        runes.color,
        migrated.skin.runesColor,
        FirstNumber(runes.outAlpha, runes.alpha)
      )
    end

    local vignette = SafeTable(visual.vignette)
    if vignette then
      local vignetteEnabled = SafeBoolean(vignette.enabled)
      if vignetteEnabled ~= nil then migrated.skin.vignette = vignetteEnabled end
      migrated.skin.vignetteAlpha = FirstNumber(vignette.alpha) or migrated.skin.vignetteAlpha
    end
  end

  if legacyFire then
    local fireEnabled = SafeBoolean(legacyFire.enabled)
    if fireEnabled ~= nil then migrated.skin.fire = fireEnabled end
    migrated.skin.fireIdleAlpha = FirstNumber(legacyFire.outAlpha) or migrated.skin.fireIdleAlpha
    migrated.skin.fireCombatAlpha = FirstNumber(legacyFire.combatAlpha) or migrated.skin.fireCombatAlpha
    migrated.skin.fireIdleFPS = FirstNumber(legacyFire.outFPS) or migrated.skin.fireIdleFPS
    migrated.skin.fireCombatFPS = FirstNumber(legacyFire.combatFPS, legacyFire.outFPS) or migrated.skin.fireCombatFPS
  end

  if legacyPing then
    local pingEnabled = SafeBoolean(legacyPing.enabled)
    if pingEnabled ~= nil then migrated.ping.enabled = pingEnabled end
    migrated.ping.where = SafeString(legacyPing.where) or migrated.ping.where
    migrated.ping.duration = SafeNumber(legacyPing.duration) or migrated.ping.duration
  end

  if legacyZoom then
    local autoReset = SafeBoolean(legacyZoom.autoReset)
    local mousewheel = SafeBoolean(legacyZoom.mousewheel)
    if autoReset ~= nil then migrated.zoom.autoReset = autoReset end
    if mousewheel == false then migrated.zoom.autoReset = false end
    migrated.zoom.delay = SafeNumber(legacyZoom.delay) or migrated.zoom.delay
  end

  SanitizeDB(migrated)
  return migrated
end

local function MigrateDB(raw)
  local old = SafeTable(raw)
  if not old then return NewDB() end

  local migrated
  if SafeTable(old.skin) then
    SanitizeDB(old)
    migrated = old
  else
    migrated = MigrateLegacyDB(old)
  end

  if migrated ~= old then ReplaceContents(old, migrated) end
  return old
end

RothMinimapDB = MigrateDB(RothMinimapDB)
ns.db = RothMinimapDB

ns.util = {
  SafeNumber = SafeNumber,
  SafeTable = SafeTable,
  CanUseObject = CanUseObject,
  SafeCall = SafeCall,
  SafeGet = SafeGet,
  clamp = ClampValue,
}

local function ReportError(scope, errorText)
  local message = "Roth Minimap " .. scope .. ": " .. tostring(errorText)
  local handler = type(geterrorhandler) == "function" and geterrorhandler() or nil
  if type(handler) == "function" then
    pcall(handler, message)
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

local function ReadNamespaceBoolean(namespace, methodName)
  if type(namespace) ~= "table" then return false end
  local method = namespace[methodName]
  if type(method) ~= "function" then return false end
  local ok, value = pcall(method)
  return ok and SafeBoolean(value) == true
end

local nativePresentationReason

local function DetectNativePresentation()
  if ReadNamespaceBoolean(_G.C_Minimap, "ShouldUseHybridMinimap") then
    return "hybrid"
  end
  if ReadNamespaceBoolean(_G.C_Housing, "IsInsideHouse") then
    return "housing"
  end
  return nil
end

function ns.UsesNativePresentation()
  return nativePresentationReason ~= nil
end

local artState = setmetatable({}, { __mode = "k" })

local function SetDecorativeHidden(object, hidden)
  if not object then return true end
  if not CanUseObject(object) then return false end

  local state = artState[object]
  if not state then
    state = {}
    artState[object] = state
  end

  local currentAlpha = SafeNumber(SafeGet(object, "GetAlpha"))
  if hidden then
    if currentAlpha == nil then return false end
    if not state.applied or currentAlpha ~= 0 then state.originalAlpha = currentAlpha end
    if currentAlpha ~= 0 and not SafeCall(object, "SetAlpha", 0) then return false end
    state.applied = true
    return true
  end

  if state.applied and currentAlpha == 0 and state.originalAlpha ~= nil then
    if not SafeCall(object, "SetAlpha", state.originalAlpha) then return false end
  end
  state.applied = false
  state.originalAlpha = nil
  return true
end

local function ApplyBlizzardArt()
  local hidden = ns.db.enabled and ns.db.hideBlizzardArt and not ns.UsesNativePresentation()
  local okCompass = SetDecorativeHidden(_G.MinimapCompassTexture, hidden)
  local cluster = _G.MinimapCluster
  local okTop = SetDecorativeHidden(cluster and cluster.BorderTop, hidden)
  return okCompass and okTop
end

local function ApplyMask()
  if not CanUseObject(_G.Minimap) then return false end
  local useSquare = ns.db.enabled and ns.db.squareMask and not ns.UsesNativePresentation()
  return SafeCall(Minimap, "SetMaskTexture", useSquare and SQUARE_MASK or DEFAULT_MASK)
end

local function ApplyModules()
  local skinOK = CallModule("skin", "Apply")
  local pingOK = CallModule("ping", "Apply")
  local zoomOK = CallModule("zoom", "Apply")
  return skinOK and pingOK and zoomOK
end

local function ApplyOwnedSafeState()
  CallModule("skin", "ApplySafeState")
  CallModule("ping", "ApplySafeState")
  CallModule("zoom", "ApplySafeState")
end

local refreshTimer
local refreshNeedsFullApply = false
local pendingFullApply = false
local pendingGeometryRefresh = false

local function IsCombatLocked()
  return type(InCombatLockdown) == "function" and InCombatLockdown()
end

local function CancelRefreshTimer()
  if refreshTimer and type(refreshTimer.Cancel) == "function" then refreshTimer:Cancel() end
  refreshTimer = nil
end

local function RefreshOwnedGeometry()
  if ns.UsesNativePresentation() or not (ns.db.enabled and ns.db.skin and ns.db.skin.enabled) then
    pendingGeometryRefresh = false
    CallModule("skin", "ApplySafeState")
    return true
  end
  if IsCombatLocked() then
    pendingGeometryRefresh = true
    return false
  end
  pendingGeometryRefresh = false
  return CallModule("skin", "UpdateGeometry")
end

function ns.ApplyAll()
  nativePresentationReason = DetectNativePresentation()

  if IsCombatLocked() then
    pendingFullApply = true
    ApplyOwnedSafeState()
    return false
  end

  pendingFullApply = false
  pendingGeometryRefresh = false
  refreshNeedsFullApply = false
  CancelRefreshTimer()

  local maskOK = ApplyMask()
  local artOK = ApplyBlizzardArt()
  local modulesOK = ApplyModules()
  return maskOK and artOK and modulesOK
end

local function RunQueuedRefresh()
  refreshTimer = nil
  local fullApply = refreshNeedsFullApply
  refreshNeedsFullApply = false
  if fullApply then
    ns.ApplyAll()
  else
    RefreshOwnedGeometry()
  end
end

function ns.QueueRefresh(fullApply)
  if fullApply then refreshNeedsFullApply = true end
  if refreshTimer then return end

  if C_Timer and type(C_Timer.NewTimer) == "function" then
    refreshTimer = C_Timer.NewTimer(0, RunQueuedRefresh)
  else
    RunQueuedRefresh()
  end
end

function ns.ResetDB()
  local fresh = NewDB()
  ReplaceContents(ns.db, fresh)
  RothMinimapDB = ns.db
  local applied = ns.ApplyAll()
  if type(ns.RefreshSettings) == "function" then ns.RefreshSettings() end
  return applied
end

function ns.GetStatus()
  return {
    version = ns.VERSION,
    enabled = ns.db.enabled,
    squareMask = ns.db.squareMask,
    hideBlizzardArt = ns.db.hideBlizzardArt,
    zoomReset = ns.db.zoom.autoReset,
    nativePresentation = nativePresentationReason,
    pendingApply = pendingFullApply or pendingGeometryRefresh,
  }
end

local editModeCallbacksRegistered = false

local function RegisterEditModeCallbacks()
  if editModeCallbacksRegistered then return end
  if not EventRegistry or type(EventRegistry.RegisterCallback) ~= "function" then return end
  editModeCallbacksRegistered = true
  EventRegistry:RegisterCallback("EditMode.Exit", function() ns.QueueRefresh(false) end, ns)
  EventRegistry:RegisterCallback("EditMode.SavedLayouts", function() ns.QueueRefresh(false) end, ns)
end

local coreEvents = CreateFrame("Frame")
coreEvents:RegisterEvent("PLAYER_LOGIN")
coreEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
coreEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
coreEvents:RegisterEvent("UI_SCALE_CHANGED")
coreEvents:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    RegisterEditModeCallbacks()
  elseif event == "PLAYER_ENTERING_WORLD" or event == "UI_SCALE_CHANGED" then
    ns.QueueRefresh(true)
  elseif event == "PLAYER_REGEN_ENABLED" then
    if pendingFullApply then
      ns.ApplyAll()
    elseif pendingGeometryRefresh then
      RefreshOwnedGeometry()
    end
  end
end)

function _G.RothMinimap_OpenConfig()
  if type(ns.OpenOptions) == "function" then ns.OpenOptions() end
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
      "Roth Minimap %s: enabled=%s square=%s hideArt=%s native=%s zoomReset=%s pending=%s",
      status.version,
      tostring(status.enabled),
      tostring(status.squareMask),
      tostring(status.hideBlizzardArt),
      status.nativePresentation or "no",
      tostring(status.zoomReset),
      tostring(status.pendingApply)
    ))
  elseif message == "config" or message == "options" or message == "" then
    _G.RothMinimap_OpenConfig()
  else
    print("Roth Minimap: /rmmap config|toggle|reset|status")
    print("Position and size are controlled by Blizzard Edit Mode.")
  end
end
