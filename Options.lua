-- Roth Minimap Settings owner for Retail 12.1.5.

local ADDON_NAME, ns = ...
local registered = false
local refreshing = false
local categoryID

local SETTING_VARIABLES = {
  "ROTH_MINIMAP_ENABLED",
  "ROTH_MINIMAP_SQUARE",
  "ROTH_MINIMAP_HIDE_ART",
  "ROTH_MINIMAP_SKIN",
  "ROTH_MINIMAP_BORDER",
  "ROTH_MINIMAP_RUNES",
  "ROTH_MINIMAP_VIGNETTE",
  "ROTH_MINIMAP_FIRE",
  "ROTH_MINIMAP_VIGNETTE_ALPHA",
  "ROTH_MINIMAP_FIRE_IDLE",
  "ROTH_MINIMAP_FIRE_COMBAT",
  "ROTH_MINIMAP_FIRE_FPS",
  "ROTH_MINIMAP_OUTSET",
  "ROTH_MINIMAP_PING",
  "ROTH_MINIMAP_PING_WHERE",
  "ROTH_MINIMAP_PING_DURATION",
  "ROTH_MINIMAP_AUTO_RESET",
  "ROTH_MINIMAP_ZOOM_DELAY",
}

local function Apply()
  if refreshing then return end
  if type(ns.ApplyAll) == "function" then ns.ApplyAll() end
end

local function BindApply(setting)
  setting:SetValueChangedCallback(Apply)
  return setting
end

local function Checkbox(category, tableRef, variable, key, label, defaultValue, tooltip)
  local setting = BindApply(Settings.RegisterAddOnSetting(
    category,
    variable,
    key,
    tableRef,
    Settings.VarType.Boolean,
    label,
    defaultValue
  ))
  Settings.CreateCheckbox(category, setting, tooltip)
  return setting
end

local function Slider(category, tableRef, variable, key, label, defaultValue, minimum, maximum, step, tooltip)
  local setting = BindApply(Settings.RegisterAddOnSetting(
    category,
    variable,
    key,
    tableRef,
    Settings.VarType.Number,
    label,
    defaultValue
  ))
  Settings.CreateSlider(category, setting, Settings.CreateSliderOptions(minimum, maximum, step), tooltip)
  return setting
end

local function Dropdown(category, tableRef, variable, key, label, defaultValue, values, tooltip)
  local setting = BindApply(Settings.RegisterAddOnSetting(
    category,
    variable,
    key,
    tableRef,
    Settings.VarType.String,
    label,
    defaultValue
  ))

  local function GetOptions()
    local container = Settings.CreateControlTextContainer()
    for _, option in ipairs(values) do container:Add(option.value, option.label) end
    return container:GetData()
  end

  Settings.CreateDropdown(category, setting, GetOptions, tooltip)
  return setting
end

local function RegisterSettings()
  if registered then return true end
  if not Settings or not Settings.RegisterVerticalLayoutCategory then return false end

  local category = Settings.RegisterVerticalLayoutCategory("Roth Minimap")
  categoryID = category:GetID()

  Checkbox(category, ns.db, "ROTH_MINIMAP_ENABLED", "enabled", "Enabled", true,
    "Enable the square mask, additive art, ping notification, and optional zoom reset.")
  Checkbox(category, ns.db, "ROTH_MINIMAP_SQUARE", "squareMask", "Square minimap mask", true,
    "Change only the Minimap mask. Blizzard Edit Mode remains the position and size owner.")
  Checkbox(category, ns.db, "ROTH_MINIMAP_HIDE_ART", "hideBlizzardArt", "Hide decorative Blizzard border art", true,
    "Hide only the selected-source compass texture and top-border decoration. Functional MinimapBackdrop descendants remain untouched.")

  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_SKIN", "enabled", "Diablo skin", true)
  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_BORDER", "border", "Border", true)
  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_RUNES", "runes", "Runes", false)
  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_VIGNETTE", "vignette", "Inner vignette", true)
  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_FIRE", "fire", "Animated fire", true,
    "The bounded fire ticker runs only while the native minimap and addon skin are visible.")
  Slider(category, ns.db.skin, "ROTH_MINIMAP_VIGNETTE_ALPHA", "vignetteAlpha", "Vignette alpha", 0.40, 0, 1, 0.05)
  Slider(category, ns.db.skin, "ROTH_MINIMAP_FIRE_IDLE", "fireIdleAlpha", "Idle fire alpha", 0.14, 0, 1, 0.05)
  Slider(category, ns.db.skin, "ROTH_MINIMAP_FIRE_COMBAT", "fireCombatAlpha", "Combat fire alpha", 0.42, 0, 1, 0.05)
  Slider(category, ns.db.skin, "ROTH_MINIMAP_FIRE_FPS", "fireFPS", "Fire frames per second", 8, 1, 20, 1)
  Slider(category, ns.db.skin, "ROTH_MINIMAP_OUTSET", "outset", "Skin outset", 34, 0, 96, 1)

  Checkbox(category, ns.db.ping, "ROTH_MINIMAP_PING", "enabled", "Ping notification", true,
    "Show fixed ordinary text without reading the secret MINIMAP_PING payload.")
  Dropdown(category, ns.db.ping, "ROTH_MINIMAP_PING_WHERE", "where", "Ping destination", "toast", {
    { value = "toast", label = "Toast below minimap" },
    { value = "chat", label = "Chat message" },
  }, "Choose where the fixed ping notification appears.")
  Slider(category, ns.db.ping, "ROTH_MINIMAP_PING_DURATION", "duration", "Ping toast duration", 3, 1, 10, 0.5)

  Checkbox(category, ns.db.zoom, "ROTH_MINIMAP_AUTO_RESET", "autoReset", "Reset wheel zoom automatically", true,
    "Blizzard performs the native wheel step. Roth Minimap only schedules one cancellable reset to minimum zoom.")
  Slider(category, ns.db.zoom, "ROTH_MINIMAP_ZOOM_DELAY", "delay", "Zoom reset delay", 3, 1, 10, 0.5)

  Settings.RegisterAddOnCategory(category)
  registered = true
  return true
end

function ns.RefreshSettings()
  if not registered or not Settings or type(Settings.NotifyUpdate) ~= "function" then return end

  refreshing = true
  local firstError
  for _, variable in ipairs(SETTING_VARIABLES) do
    local ok, errorText = pcall(Settings.NotifyUpdate, variable)
    if not ok and firstError == nil then firstError = errorText end
  end
  refreshing = false

  if firstError ~= nil then
    local handler = type(geterrorhandler) == "function" and geterrorhandler() or nil
    if type(handler) == "function" then
      pcall(handler, "Roth Minimap Settings.NotifyUpdate: " .. tostring(firstError))
    end
  end
end

function ns.OpenOptions()
  if not registered then RegisterSettings() end
  if Settings and categoryID then Settings.OpenToCategory(categoryID) end
end

if EventUtil and type(EventUtil.ContinueOnAddOnLoaded) == "function" then
  EventUtil.ContinueOnAddOnLoaded(ADDON_NAME, RegisterSettings)
else
  local readiness = CreateFrame("Frame")
  readiness:RegisterEvent("PLAYER_LOGIN")
  readiness:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    RegisterSettings()
  end)
end
