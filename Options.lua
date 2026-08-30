-- RothMinimap Settings owner for Retail 12.1.

local ADDON_NAME, ns = ...
local registered = false
local categoryID

local function Apply()
  if type(ns.ApplyAll) == "function" then ns.ApplyAll() end
end

local function Checkbox(category, tableRef, variable, key, label, defaultValue, tooltip)
  local setting = Settings.RegisterAddOnSetting(
    category,
    variable,
    key,
    tableRef,
    Settings.VarType.Boolean,
    label,
    defaultValue
  )
  setting:SetValueChangedCallback(Apply)
  Settings.CreateCheckbox(category, setting, tooltip)
  return setting
end

local function Slider(category, tableRef, variable, key, label, defaultValue, minimum, maximum, step, tooltip)
  local setting = Settings.RegisterAddOnSetting(
    category,
    variable,
    key,
    tableRef,
    Settings.VarType.Number,
    label,
    defaultValue
  )
  setting:SetValueChangedCallback(Apply)
  Settings.CreateSlider(category, setting, Settings.CreateSliderOptions(minimum, maximum, step), tooltip)
  return setting
end

local function RegisterSettings()
  if registered or not Settings or not Settings.RegisterVerticalLayoutCategory then return false end
  registered = true

  local category = Settings.RegisterVerticalLayoutCategory("Roth Minimap")
  categoryID = category:GetID()

  Checkbox(category, ns.db, "ROTH_MINIMAP_ENABLED", "enabled", "Enabled", true,
    "Enable RothMinimap's mask, additive art, ping and zoom modules.")
  Checkbox(category, ns.db, "ROTH_MINIMAP_SQUARE", "squareMask", "Square minimap mask", true,
    "Change only the Minimap mask. Position and size remain controlled by Blizzard Edit Mode.")
  Checkbox(category, ns.db, "ROTH_MINIMAP_HIDE_ART", "hideBlizzardArt", "Hide decorative Blizzard border art", true,
    "Changes alpha only on known decorative border textures. Clock, calendar, tracking, difficulty and addon-compartment widgets remain Blizzard-owned.")

  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_SKIN", "enabled", "Diablo skin", true)
  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_BORDER", "border", "Border", true)
  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_RUNES", "runes", "Runes", false)
  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_VIGNETTE", "vignette", "Inner vignette", true)
  Checkbox(category, ns.db.skin, "ROTH_MINIMAP_FIRE", "fire", "Animated fire", true,
    "The fire ticker exists only while the skin is visible and fire is enabled.")
  Slider(category, ns.db.skin, "ROTH_MINIMAP_VIGNETTE_ALPHA", "vignetteAlpha", "Vignette alpha", 0.40, 0, 1, 0.05)
  Slider(category, ns.db.skin, "ROTH_MINIMAP_FIRE_IDLE", "fireIdleAlpha", "Idle fire alpha", 0.14, 0, 1, 0.05)
  Slider(category, ns.db.skin, "ROTH_MINIMAP_FIRE_COMBAT", "fireCombatAlpha", "Combat fire alpha", 0.42, 0, 1, 0.05)
  Slider(category, ns.db.skin, "ROTH_MINIMAP_FIRE_FPS", "fireFPS", "Fire frames per second", 8, 1, 20, 1)
  Slider(category, ns.db.skin, "ROTH_MINIMAP_OUTSET", "outset", "Skin outset", 34, 0, 96, 1)

  Checkbox(category, ns.db.ping, "ROTH_MINIMAP_PING", "enabled", "Ping notification", true,
    "Shows a fixed ordinary notification. The MINIMAP_PING unit payload is not inspected.")
  Checkbox(category, ns.db.ping, "ROTH_MINIMAP_PING_SOUND", "sound", "Ping sound", false)
  Slider(category, ns.db.ping, "ROTH_MINIMAP_PING_DURATION", "duration", "Ping toast duration", 3, 1, 10, 0.5)

  Checkbox(category, ns.db.zoom, "ROTH_MINIMAP_WHEEL", "mousewheel", "Mouse-wheel zoom", true)
  Checkbox(category, ns.db.zoom, "ROTH_MINIMAP_AUTO_RESET", "autoReset", "Reset zoom automatically", true)
  Slider(category, ns.db.zoom, "ROTH_MINIMAP_ZOOM_DELAY", "delay", "Zoom reset delay", 3, 1, 10, 0.5)

  Settings.RegisterAddOnCategory(category)
  return true
end

function ns.OpenOptions()
  if not registered then RegisterSettings() end
  if Settings and categoryID then Settings.OpenToCategory(categoryID) end
end

if EventUtil and EventUtil.ContinueOnAddOnLoaded then
  EventUtil.ContinueOnAddOnLoaded(ADDON_NAME, RegisterSettings)
else
  ns.RegisterEvent("PLAYER_LOGIN", function()
    RegisterSettings()
  end)
end
