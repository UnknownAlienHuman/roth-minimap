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
  "ROTH_MINIMAP_PRESET",
  "ROTH_MINIMAP_BORDER",
  "ROTH_MINIMAP_RUNES",
  "ROTH_MINIMAP_VIGNETTE",
  "ROTH_MINIMAP_FIRE",
  "ROTH_MINIMAP_VIGNETTE_ALPHA",
  "ROTH_MINIMAP_FIRE_IDLE",
  "ROTH_MINIMAP_FIRE_COMBAT",
  "ROTH_MINIMAP_FIRE_IDLE_FPS",
  "ROTH_MINIMAP_FIRE_COMBAT_FPS",
  "ROTH_MINIMAP_OUTSET",
  "ROTH_MINIMAP_PING",
  "ROTH_MINIMAP_PING_WHERE",
  "ROTH_MINIMAP_PING_DURATION",
  "ROTH_MINIMAP_AUTO_RESET",
  "ROTH_MINIMAP_ZOOM_DELAY",
}

local function ReportSettingsError(errorText)
  local handler = type(geterrorhandler) == "function" and geterrorhandler() or nil
  if type(handler) ~= "function" then return end
  local detail = ns.util and ns.util.SafeString and ns.util.SafeString(errorText) or "<unavailable>"
  pcall(handler, "Roth Minimap Settings: " .. detail)
end

local function Apply()
  if refreshing then return end
  if type(ns.ApplyAll) == "function" then ns.ApplyAll() end
end

local function NotifyOne(variable)
  if not Settings or type(Settings.NotifyUpdate) ~= "function" then return end
  refreshing = true
  local ok, errorText = pcall(Settings.NotifyUpdate, variable)
  refreshing = false
  if not ok then ReportSettingsError(errorText) end
end

local function MarkCustomAndApply()
  if refreshing then return end
  if ns.db and ns.db.skin and ns.db.skin.preset ~= "custom" then
    ns.db.skin.preset = "custom"
    NotifyOne("ROTH_MINIMAP_PRESET")
  end
  Apply()
end

local function ApplyPreset(setting, value)
  if refreshing then return end
  if value == nil and setting and type(setting.GetValue) == "function" then
    value = setting:GetValue()
  end
  if type(ns.ApplySkinPreset) ~= "function" or not ns.ApplySkinPreset(value) then return end
  if type(ns.RefreshSettings) == "function" then ns.RefreshSettings() end
  Apply()
end

local function Bind(setting, callback)
  setting:SetValueChangedCallback(callback or Apply)
  return setting
end

local function Checkbox(category, tableRef, variable, key, label, defaultValue, tooltip, callback)
  local setting = Bind(Settings.RegisterAddOnSetting(
    category,
    variable,
    key,
    tableRef,
    Settings.VarType.Boolean,
    label,
    defaultValue
  ), callback)
  Settings.CreateCheckbox(category, setting, tooltip)
  return setting
end

local function Slider(category, tableRef, variable, key, label, defaultValue, minimum, maximum, step, tooltip, callback)
  local setting = Bind(Settings.RegisterAddOnSetting(
    category,
    variable,
    key,
    tableRef,
    Settings.VarType.Number,
    label,
    defaultValue
  ), callback)
  Settings.CreateSlider(category, setting, Settings.CreateSliderOptions(minimum, maximum, step), tooltip)
  return setting
end

local function Dropdown(category, tableRef, variable, key, label, defaultValue, values, tooltip, callback)
  local setting = Bind(Settings.RegisterAddOnSetting(
    category,
    variable,
    key,
    tableRef,
    Settings.VarType.String,
    label,
    defaultValue
  ), callback)

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
    "Change only the native Minimap mask. Hybrid Minimap and indoor housing keep Blizzard's native presentation.")
  Checkbox(category, ns.db, "ROTH_MINIMAP_HIDE_ART", "hideBlizzardArt", "Hide decorative Blizzard border art", true,
    "Hide only the selected-source compass texture and top-border decoration. Functional MinimapBackdrop descendants remain untouched.")

  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_SKIN", "enabled", "Layered Diablo frame", true,
    "A noninteractive shadow, charred rim, frame, embers, optional runes, and inner vignette. Native widgets stay above it.")
  Dropdown(category, ns.db.skin, "ROTH_MINIMAP_PRESET", "preset", "Appearance preset", "obsidian", {
    { value = "obsidian", label = "Obsidian Ember" },
    { value = "inferno", label = "Inferno" },
    { value = "runic", label = "Runebound" },
    { value = "minimal", label = "Clean" },
    { value = "custom", label = "Custom" },
  }, "Apply a coherent visual composition. Changing any detailed appearance control marks the result as Custom.", ApplyPreset)

  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_BORDER", "border", "Obsidian frame", true, nil, MarkCustomAndApply)
  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_RUNES", "runes", "Runic overlay", false, nil, MarkCustomAndApply)
  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_VIGNETTE", "vignette", "Inner vignette", true, nil, MarkCustomAndApply)
  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_FIRE", "fire", "Reactive embers", true,
    "Out of combat, a static ember frame breathes through a C-level AnimationGroup. In combat, one bounded atlas ticker becomes active.", MarkCustomAndApply)
  Slider(category, ns.db.skin, "ROTH_MINIMAP_VIGNETTE_ALPHA", "vignetteAlpha", "Vignette strength", 0.16, 0, 1, 0.05, nil, MarkCustomAndApply)
  Slider(category, ns.db.skin, "ROTH_MINIMAP_FIRE_IDLE", "fireIdleAlpha", "Idle ember strength", 0.05, 0, 1, 0.025, nil, MarkCustomAndApply)
  Slider(category, ns.db.skin, "ROTH_MINIMAP_FIRE_COMBAT", "fireCombatAlpha", "Combat ember strength", 0.26, 0, 1, 0.025, nil, MarkCustomAndApply)
  Slider(category, ns.db.skin, "ROTH_MINIMAP_FIRE_IDLE_FPS", "fireIdleFPS", "Idle ember motion speed", 2, 1, 8, 1,
    "Controls the slow alpha-breathing cycle. Idle presentation does not run a Lua atlas ticker.", MarkCustomAndApply)
  Slider(category, ns.db.skin, "ROTH_MINIMAP_FIRE_COMBAT_FPS", "fireCombatFPS", "Combat ember frames per second", 8, 1, 20, 1, nil, MarkCustomAndApply)
  Slider(category, ns.db.skin, "ROTH_MINIMAP_OUTSET", "outset", "Frame expansion", 28, 0, 96, 1,
    "Reference expansion at the default 198-pixel minimap size. It scales proportionally with Blizzard Edit Mode sizing.", MarkCustomAndApply)

  Checkbox(category, ns.db.ping, "ROTH_MINIMAP_PING", "enabled", "Ping notification", true,
    "Show fixed ordinary text without reading the secret MINIMAP_PING payload.")
  Dropdown(category, ns.db.ping, "ROTH_MINIMAP_PING_WHERE", "where", "Ping destination", "toast", {
    { value = "toast", label = "Compact toast below minimap" },
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

  if firstError ~= nil then ReportSettingsError(firstError) end
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
