local E = dofile("tests/runtime_stubs_env.lua")
local event = E.event
local timers = E.timers
local tickers = E.tickers
local errors = E.errors
local settings = E.settings
local native = E.native
local addonName = "roth-minimap-main"

local legacy = {
  version = 18,
  enabled = true,
  square = false,
  hideBlizzardArt = true,
  skinEnabled = false,
  visual = {
    border = { alpha = 0.75, color = { 0.2, 0.3, 0.4 } },
    runes = { enabled = true, outAlpha = 0.25, color = { 0.9, 0.5, 0.1 } },
    vignette = { enabled = false, alpha = 0.15 },
  },
  fire = { enabled = true, outAlpha = 0.11, combatAlpha = 0.55, outFPS = 2, combatFPS = 9 },
  ping = { enabled = true, where = "chat", duration = 4, sound = true },
  zoom = { mousewheel = true, autoReset = true, delay = 4, mode = "smooth" },
}

RothMinimapDB = legacy
local ns = {}
assert(loadfile("RothMinimap.lua"))(addonName, ns)
assert(ns.media == "Interface\\AddOns\\" .. addonName .. "\\media\\")
assert(ns.db == legacy and ns.db.version == 9)
assert(ns.db.skin.preset == "custom")
assert(ns.db.squareMask == false and ns.db.skin.enabled == false)
assert(ns.db.skin.borderColor[1] == 0.2 and ns.db.skin.borderColor[4] == 0.75)
assert(ns.db.skin.runesColor[4] == 0.25)
assert(ns.db.skin.vignette == false and ns.db.skin.vignetteAlpha == 0.15)
assert(ns.db.skin.fireIdleFPS == 2 and ns.db.skin.fireCombatFPS == 9 and ns.db.skin.fireFPS == nil)
assert(ns.db.ping.where == "chat" and ns.db.ping.duration == 4 and ns.db.ping.sound == nil)
assert(ns.db.visual == nil and ns.db.fire == nil and ns.db.skinEnabled == nil)
assert(_G.RothMinimap == nil)

for _, path in ipairs({
  "modules/Skin.lua",
  "modules/Ping.lua",
  "modules/Zoom.lua",
  "Options.lua",
}) do
  assert(loadfile(path))(addonName, ns)
end

assert(settings.ROTH_MINIMAP_PRESET and #settings.ROTH_MINIMAP_PRESET.options == 5)
assert(settings.ROTH_MINIMAP_PING_WHERE and #settings.ROTH_MINIMAP_PING_WHERE.options == 2)

ns.db.enabled = true
ns.db.squareMask = true
ns.db.skin.enabled = true
ns.db.skin.border = true
ns.db.skin.runes = true
ns.db.skin.vignette = true
ns.db.skin.fire = true
ns.db.ping.enabled = true
ns.db.ping.where = "toast"
ns.db.zoom.autoReset = true

assert(ns.ApplyAll())
assert(Minimap.mask:find("mask_square.tga", 1, true))
assert(Minimap.mask:find(addonName, 1, true))
assert(MinimapCompassTexture.alpha == 0)
assert(MinimapCluster.BorderTop.alpha == 0)
assert(MinimapBackdrop.alpha == 0.7)
assert(ns.skin.frame:GetFrameStrata() == "LOW")
assert(ns.skin.frame:GetFrameLevel() == 10)
assert(ns.skin.frame:GetFrameLevel() < native:GetFrameLevel())
assert(ns.skin.frame:GetWidth() == 254 and ns.skin.frame:GetHeight() == 254)
assert(ns.skin.geometryScale == 1 and ns.skin.scaledOutset == 28 and ns.skin.shadowPadding == 8)

local layers = ns.skin.frame.textures
assert(#layers == 8)
assert(layers[1].texture:find("RM_DIABLO_FIRE_GLOW_512.tga", 1, true))
assert(layers[2].texture:find("RM_DIABLO_FIRE_GLOW_512.tga", 1, true))
assert(layers[3].texture:find("RM_DIABLO_CHAR_512.tga", 1, true))
assert(layers[4].texture:find("RM_DIABLO_FIRE_ATLAS_512_HOLE_THIN.tga", 1, true))
assert(layers[5].texture:find("RM_DIABLO_BORDER_512.tga", 1, true))
assert(layers[6].texture:find("RM_DIABLO_BORDER_512.tga", 1, true))
assert(layers[7].texture:find("RM_DIABLO_RUNES_512.tga", 1, true))
assert(layers[8].texture:find("RM_DIABLO_FIRE_GLOW_512.tga", 1, true))
assert(layers[1].blendMode == "BLEND" and layers[2].blendMode == "ADD")
assert(layers[3]:IsShown() and layers[5]:IsShown() and layers[7]:IsShown())
assert(layers[1].alpha < 0.40 and layers[3].alpha < 0.40)
assert(layers[4].vertexColor[1] > 0.9 and layers[4].vertexColor[2] > 0.6)

assert(#ns.skin.frame.maskTextures == 1)
assert(ns.skin.fireMask == ns.skin.frame.maskTextures[1])
assert(ns.skin.fireMask.texture:find("RM_DIABLO_CHAR_512.tga", 1, true))
assert(#layers[1].masks == 0)
assert(layers[2].masks[1] == ns.skin.fireMask)
assert(layers[4].masks[1] == ns.skin.fireMask)
assert(layers[8].masks[1] == ns.skin.fireMask)

-- Idle motion is a static atlas frame with a looping C-level alpha breath, not a Lua ticker.
assert(#tickers == 0)
assert(ns.skin.fireBreathGroup and ns.skin.fireBreathGroup.playing)
assert(ns.skin.fireBreathGroup.looping == "REPEAT")
assert(#ns.skin.fireBreathGroup.animations == 2)
local breathDuration = ns.skin.fireBreathGroup.animations[1].values.SetDuration
assert(type(breathDuration) == "number" and breathDuration > 2 and breathDuration < 3)

E.setCombat(true)
event("PLAYER_REGEN_DISABLED")
assert(not ns.skin.fireBreathGroup.playing)
assert(#tickers == 1 and not tickers[1].cancelled)
assert(math.abs(tickers[1].interval - (1 / 9)) < 0.000001)
local combatTicker = tickers[1]

E.setCombat(false)
event("PLAYER_REGEN_ENABLED")
assert(combatTicker.cancelled)
assert(ns.skin.fireBreathGroup.playing)
assert(#tickers == 1)

-- The authored frame ratio remains stable across Blizzard Edit Mode sizes.
Minimap:SetSize(99, 99)
assert(ns.skin:UpdateGeometry())
assert(ns.skin.geometryScale == 0.5 and ns.skin.scaledOutset == 14)
assert(ns.skin.frame:GetWidth() == 127 and ns.skin.shadowPadding == 4)
Minimap:SetSize(297, 297)
assert(ns.skin:UpdateGeometry())
assert(ns.skin.geometryScale == 1.5 and ns.skin.scaledOutset == 42)
assert(ns.skin.frame:GetWidth() == 381 and ns.skin.shadowPadding == 12)
Minimap:SetSize(198, 198)
assert(ns.skin:UpdateGeometry())
assert(ns.skin.frame:GetWidth() == 254 and ns.skin.scaledOutset == 28)

assert(E.hasCallbackEvent("MINIMAP_PING"))
assert(not E.hasRawEvent("MINIMAP_PING"))
local secret = setmetatable({ __bad = true }, {
  __tostring = function() error("secret") end,
  __eq = function() error("secret") end,
  __index = function() error("secret") end,
})
event("MINIMAP_PING", secret, secret, secret)
assert(ns.ping.toast and ns.ping.toast:IsShown())
assert(ns.ping.toast:GetWidth() == 168 and ns.ping.toast:GetHeight() == 30)
assert(ns.ping.toast.clamped == true)
assert(ns.ping.toast:GetFrameStrata() == "LOW" and ns.ping.toast:GetFrameLevel() == 12)
assert(ns.ping.toast.textures[1].width == 2)

ns.db.ping.enabled = false
assert(ns.ApplyAll())
assert(not E.hasCallbackEvent("MINIMAP_PING"))
ns.db.ping.enabled = true
assert(ns.ApplyAll())
assert(E.hasCallbackEvent("MINIMAP_PING"))

-- A temporarily inaccessible alpha read must not discard the original snapshot.
ns.db.hideBlizzardArt = false
MinimapCompassTexture.alphaReadable = false
assert(ns.ApplyAll() == false)
assert(MinimapCompassTexture.alpha == 0)
MinimapCompassTexture.alphaReadable = true
assert(ns.ApplyAll())
assert(MinimapCompassTexture.alpha == 0.8)
assert(MinimapCluster.BorderTop.alpha == 0.6)

-- If another owner changes ordinary alpha, preserve its latest value before rehiding.
ns.db.hideBlizzardArt = true
assert(ns.ApplyAll())
MinimapCompassTexture.alpha = 0.35
assert(ns.ApplyAll())
assert(MinimapCompassTexture.alpha == 0)
ns.db.hideBlizzardArt = false
assert(ns.ApplyAll())
assert(MinimapCompassTexture.alpha == 0.35)
ns.db.hideBlizzardArt = true

E.setHybrid(true)
assert(ns.ApplyAll())
assert(Minimap.mask == "Interface\\Minimap\\UI-Minimap-Background")
assert(MinimapCompassTexture.alpha == 0.35)
assert(MinimapCluster.BorderTop.alpha == 0.6)
assert(not ns.skin.frame:IsShown())
assert(not ns.skin.fireBreathGroup.playing)
assert(ns.GetStatus().nativePresentation == "hybrid")

E.setHybrid(false)
E.setHousing(true)
assert(ns.ApplyAll())
assert(Minimap.mask == "Interface\\Minimap\\UI-Minimap-Background")
assert(not ns.skin.frame:IsShown())
assert(ns.GetStatus().nativePresentation == "housing")

E.setHousing(false)
assert(ns.ApplyAll())
assert(Minimap.mask:find("mask_square.tga", 1, true))
assert(MinimapCompassTexture.alpha == 0)
assert(MinimapCluster.BorderTop.alpha == 0)
assert(ns.skin.frame:IsShown())
assert(ns.skin.fireBreathGroup.playing)
assert(ns.GetStatus().nativePresentation == nil)

-- One wheel notch is one native step, followed by one bounded reset timer.
Minimap.zoom = 1
Minimap:RunScript("OnMouseWheel", 1)
assert(Minimap.zoom == 2)
local zoomTimer = timers[#timers]
assert(zoomTimer.delay == 4 and not zoomTimer.cancelled)
assert(ns.ApplyAll() and not zoomTimer.cancelled)
zoomTimer.callback()
assert(Minimap.zoom == 0)

ns.skin:Pulse()
ns.skin.pulseGroup:Stop()
assert(not ns.skin.pulseGroup.owner:IsShown())
assert(ns.skin.pulseGroup.owner:GetAlpha() == 0)

ns.skin.frame:Hide()
assert(not ns.skin.fireBreathGroup.playing)
ns.skin.frame:Show()
assert(ns.skin.fireBreathGroup.playing)

-- Direct full apply supersedes and cancels a queued lifecycle refresh, even in combat.
local queuedTimerCount = #timers
ns.QueueRefresh(true)
assert(#timers == queuedTimerCount + 1)
local supersededRefresh = timers[#timers]
assert(not supersededRefresh.cancelled)
E.setCombat(true)
assert(ns.ApplyAll() == false)
assert(supersededRefresh.cancelled)
assert(ns.GetStatus().pendingApply)
E.setCombat(false)
event("PLAYER_REGEN_ENABLED")
assert(not ns.GetStatus().pendingApply)

ns.skin.frame:Show()
ns.db.skin.fire = false
E.setCombat(true)
assert(ns.ApplyAll() == false)
assert(not layers[4]:IsShown() and not layers[2]:IsShown())
assert(not ns.skin.fireBreathGroup.playing)
assert(ns.GetStatus().pendingApply)
E.setCombat(false)
event("PLAYER_REGEN_ENABLED")
assert(not ns.GetStatus().pendingApply)

local timerCount = #timers
ns.QueueRefresh(false)
ns.QueueRefresh(false)
ns.QueueRefresh(true)
assert(#timers == timerCount + 1)
timers[#timers].callback()

-- Module statuses are ordinary-only; inaccessible returns are rejected without formatting them.
local realSkinApply = ns.skin.Apply
ns.skin.Apply = function() return secret end
assert(ns.ApplyAll() == false)
assert(#errors == 1 and errors[1]:find("returned inaccessible status", 1, true))
ns.skin.Apply = realSkinApply
errors[1] = nil
assert(ns.ApplyAll())

-- Curated presets update all dependent settings; a detailed edit becomes Custom.
settings.ROTH_MINIMAP_PRESET:SetValue("runic")
assert(ns.db.skin.preset == "runic")
assert(ns.db.skin.runes == true and ns.db.skin.fire == true)
assert(ns.db.skin.outset == 30 and ns.db.skin.fireCombatAlpha == 0.18)
assert(ns.skin.frame:GetWidth() == 258)
assert(layers[7]:IsShown())
assert(ns.skin.fireBreathGroup.playing)
settings.ROTH_MINIMAP_FIRE_COMBAT:SetValue(0.33)
assert(ns.db.skin.preset == "custom" and ns.db.skin.fireCombatAlpha == 0.33)
settings.ROTH_MINIMAP_PRESET:SetValue("minimal")
assert(ns.db.skin.preset == "minimal")
assert(ns.db.skin.fire == false and ns.db.skin.runes == false and ns.db.skin.outset == 20)
assert(not layers[4]:IsShown() and not layers[2]:IsShown())
assert(not ns.skin.fireBreathGroup.playing)

local rootRef = ns.db
local skinRef = ns.db.skin
local pingRef = ns.db.ping
local zoomRef = ns.db.zoom
local realApply = ns.ApplyAll
local applyCount = 0
ns.ApplyAll = function(...)
  applyCount = applyCount + 1
  return realApply(...)
end
assert(ns.ResetDB() and applyCount == 1)
assert(ns.db == rootRef)
assert(ns.db.skin == skinRef)
assert(ns.db.ping == pingRef)
assert(ns.db.zoom == zoomRef)
assert(ns.db.version == 9 and ns.db.skin.preset == "obsidian")
assert(ns.db.skin.borderColor[1] == 0.23)
assert(ns.db.skin.vignetteAlpha == 0.16)
assert(ns.db.skin.fireIdleAlpha == 0.05 and ns.db.skin.fireCombatAlpha == 0.26)
assert(ns.db.skin.fireIdleFPS == 2 and ns.db.skin.fireCombatFPS == 8)
assert(ns.db.skin.outset == 28)

-- Schema 8 exact defaults are upgraded to the coherent default preset.
RothMinimapDB = {
  version = 8,
  enabled = true,
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
  ping = {},
  zoom = {},
}
local ns2 = {}
assert(loadfile("RothMinimap.lua"))("RothMinimap", ns2)
assert(ns2.db.version == 9 and ns2.db.skin.preset == "obsidian")
assert(ns2.db.skin.borderColor[1] == 0.23 and ns2.db.skin.vignetteAlpha == 0.16)
assert(ns2.db.skin.fireIdleAlpha == 0.05 and ns2.db.skin.fireCombatAlpha == 0.26)
assert(ns2.db.skin.outset == 28)

-- Schema 8 custom appearance is preserved and marked Custom.
RothMinimapDB = {
  version = 8,
  enabled = true,
  skin = {
    enabled = true,
    border = true,
    runes = true,
    vignette = true,
    fire = true,
    borderColor = { 0.4, 0.2, 0.1, 1 },
    runesColor = { 0.8, 0.3, 0.1, 0.4 },
    vignetteAlpha = 0.30,
    fireIdleAlpha = 0.08,
    fireCombatAlpha = 0.50,
    fireIdleFPS = 3,
    fireCombatFPS = 11,
    outset = 40,
  },
  ping = {},
  zoom = {},
}
local ns3 = {}
assert(loadfile("RothMinimap.lua"))("RothMinimap", ns3)
assert(ns3.db.version == 9 and ns3.db.skin.preset == "custom")
assert(ns3.db.skin.borderColor[1] == 0.4 and ns3.db.skin.runes == true)
assert(ns3.db.skin.fireCombatFPS == 11 and ns3.db.skin.outset == 40)

-- Schema 6 unified fire cadence still migrates without overwriting custom values.
RothMinimapDB = {
  version = 6,
  enabled = true,
  skin = {
    enabled = true,
    borderColor = { 1, 1, 1, 1 },
    vignetteAlpha = 0.40,
    fireFPS = 12,
  },
  ping = {},
  zoom = {},
}
local ns4 = {}
assert(loadfile("RothMinimap.lua"))("RothMinimap", ns4)
assert(ns4.db.version == 9 and ns4.db.skin.preset == "custom")
assert(ns4.db.skin.borderColor[1] == 1)
assert(ns4.db.skin.vignetteAlpha == 0.40)
assert(ns4.db.skin.fireIdleFPS == 2 and ns4.db.skin.fireCombatFPS == 12 and ns4.db.skin.fireFPS == nil)

RothMinimapDB = "corrupt"
local ns5 = {}
assert(loadfile("RothMinimap.lua"))("RothMinimap", ns5)
assert(type(ns5.db) == "table" and ns5.db.version == 9)
assert(ns5.db.skin.preset == "obsidian" and ns5.db.skin.outset == 28)

-- Starting disabled or with squareMask off must not overwrite a foreign mask.
Minimap.mask = "ThirdPartyMask"
Minimap.maskWrites = 0
RothMinimapDB = {
  version = 9,
  enabled = false,
  squareMask = false,
  skin = { preset = "minimal", enabled = false },
  ping = { enabled = false },
  zoom = { autoReset = false },
}
local ns6 = {}
assert(loadfile("RothMinimap.lua"))("RothMinimap", ns6)
assert(ns6.ApplyAll())
assert(Minimap.mask == "ThirdPartyMask" and Minimap.maskWrites == 0)

assert(#errors == 0)
print("PASS: masked embers, smooth idle breath, combat atlas, proportional geometry, presets and ownership")
