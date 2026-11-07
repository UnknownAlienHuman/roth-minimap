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
assert(ns.db == legacy and ns.db.version == 7)
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
assert(#tickers > 0 and not tickers[#tickers].cancelled)

local idleTicker = tickers[#tickers]
assert(idleTicker.interval == 0.5)
event("PLAYER_REGEN_DISABLED")
local combatTicker = tickers[#tickers]
assert(idleTicker.cancelled and combatTicker ~= idleTicker)
assert(math.abs(combatTicker.interval - (1 / 9)) < 0.000001)
event("PLAYER_REGEN_ENABLED")
local resumedIdleTicker = tickers[#tickers]
assert(combatTicker.cancelled and resumedIdleTicker ~= combatTicker and resumedIdleTicker.interval == 0.5)

assert(E.hasCallbackEvent("MINIMAP_PING"))
assert(not E.hasRawEvent("MINIMAP_PING"))
local secret = setmetatable({ __bad = true }, {
  __tostring = function() error("secret") end,
  __eq = function() error("secret") end,
  __index = function() error("secret") end,
})
event("MINIMAP_PING", secret, secret, secret)
assert(ns.ping.toast and ns.ping.toast:IsShown())

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

local preHybridTicker = tickers[#tickers]
E.setHybrid(true)
assert(ns.ApplyAll())
assert(Minimap.mask == "Interface\\Minimap\\UI-Minimap-Background")
assert(MinimapCompassTexture.alpha == 0.35)
assert(MinimapCluster.BorderTop.alpha == 0.6)
assert(not ns.skin.frame:IsShown())
assert(preHybridTicker.cancelled)
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
assert(ns.GetStatus().nativePresentation == nil)

Minimap.zoom = 1
Minimap:RunScript("OnMouseWheel", 1)
assert(Minimap.zoom == 1)
local zoomTimer = timers[#timers]
assert(zoomTimer.delay == 4 and not zoomTimer.cancelled)
assert(ns.ApplyAll() and not zoomTimer.cancelled)
zoomTimer.callback()
assert(Minimap.zoom == 0)

ns.skin:Pulse()
ns.skin.pulseGroup:Stop()
assert(not ns.skin.pulseGroup.owner:IsShown())
assert(ns.skin.pulseGroup.owner:GetAlpha() == 0)

local ticker = tickers[#tickers]
ns.skin.frame:Hide()
assert(ticker.cancelled)

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
assert(not ns.skin.frame.textures[3]:IsShown())
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
assert(ns.db.version == 7)
assert(ns.db.skin.borderColor[1] == 0.25)
assert(ns.db.skin.vignetteAlpha == 0.22)
assert(ns.db.skin.fireIdleFPS == 2 and ns.db.skin.fireCombatFPS == 8)

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
local ns2 = {}
assert(loadfile("RothMinimap.lua"))("RothMinimap", ns2)
assert(ns2.db.version == 7)
assert(ns2.db.skin.borderColor[1] == 1)
assert(ns2.db.skin.vignetteAlpha == 0.40)
assert(ns2.db.skin.fireIdleFPS == 2 and ns2.db.skin.fireCombatFPS == 12 and ns2.db.skin.fireFPS == nil)

RothMinimapDB = {
  version = 5,
  enabled = "bad",
  skin = { fireFPS = 99, outset = -4, borderColor = { 2, -1, 0.5, 0.2 } },
  ping = { where = "bad", duration = 0 },
  zoom = { autoReset = false, delay = 99 },
}
local ns3 = {}
assert(loadfile("RothMinimap.lua"))("RothMinimap", ns3)
assert(ns3.db.version == 7 and ns3.db.enabled == true)
assert(ns3.db.skin.fireIdleFPS == 2 and ns3.db.skin.fireCombatFPS == 20 and ns3.db.skin.fireFPS == nil and ns3.db.skin.outset == 0)
assert(ns3.db.ping.where == "toast" and ns3.db.ping.duration == 1)
assert(ns3.db.zoom.delay == 10)

RothMinimapDB = "corrupt"
local ns4 = {}
assert(loadfile("RothMinimap.lua"))("RothMinimap", ns4)
assert(type(ns4.db) == "table" and ns4.db.version == 7)
assert(ns4.db.skin.borderColor[1] == 0.25)
assert(ns4.db.skin.vignetteAlpha == 0.22)
assert(ns4.db.skin.fireIdleFPS == 2 and ns4.db.skin.fireCombatFPS == 8)

RothMinimapDB = {
  version = 7,
  enabled = true,
  skin = { fireIdleFPS = 5, fireCombatFPS = 13 },
  ping = {},
  zoom = {},
}
local ns5 = {}
assert(loadfile("RothMinimap.lua"))("RothMinimap", ns5)
assert(ns5.db.skin.fireIdleFPS == 5 and ns5.db.skin.fireCombatFPS == 13)
assert(#errors == 0)

print("PASS: migration, dynamic media, adaptive cadence, CallbackEvent ping, alpha restore, fallback, combat and reset")