local function read(path)
  local file = assert(io.open(path, "rb"))
  local text = assert(file:read("*a"))
  file:close()
  return text
end

local function assertAbsent(text, token, message)
  if text:find(token, 1, true) then
    error((message or "forbidden token") .. ": " .. token, 2)
  end
end

local function assertPresent(text, token, message)
  if not text:find(token, 1, true) then
    error((message or "required token missing") .. ": " .. token, 2)
  end
end

local toc = read("RothMinimap.toc")
local core = read("RothMinimap.lua")
local skin = read("modules/Skin.lua")
local ping = read("modules/Ping.lua")
local zoom = read("modules/Zoom.lua")
local options = read("Options.lua")
local runtime = table.concat({ core, skin, ping, zoom, options }, "\n")

assertPresent(toc, "## Interface: 120105", "Retail 12.1.5 interface")
assertPresent(toc, "## LoadSavedVariablesFirst: 1", "file-scope DB readiness")
assertPresent(toc, "## Version: 0.4.1", "release version")
assertPresent(toc, "modules\\Skin.lua", "skin load")
assertPresent(toc, "modules\\Ping.lua", "ping load")
assertPresent(toc, "modules\\Zoom.lua", "zoom load")
assertAbsent(toc, "ButtonBag", "button collector must not load")
assertAbsent(toc, "AddonCompartment.lua", "compartment diagnostics must not load")

for _, token in ipairs({
  "GetChildren(",
  "GetNumChildren(",
  "EnumerateFrames",
  "UnitName(",
  "TimeManagerClockButton:SetPoint",
  "GameTimeFrame:SetPoint",
  "MiniMapTracking:SetPoint",
  "AddonCompartmentFrame:SetPoint",
  "MinimapCluster:SetPoint",
  "Minimap:SetParent",
  ".SetPoint =",
  ".ClearAllPoints =",
}) do
  assertAbsent(runtime, token, "foreign-widget ownership regression")
end

assertPresent(core, "ns.DB_VERSION = 5", "schema migration")
assertPresent(core, "clamp = ClampValue", "three-argument module clamp contract")
assertPresent(core, "ReplaceContents(ns.db, fresh)", "Settings table identity preservation")
assertPresent(core, "EditMode.Exit", "Edit Mode geometry refresh")
assertPresent(core, "C_Timer.NewTimer(0", "coalesced geometry refresh")
assertPresent(core, "_G.MinimapCompassTexture", "exact compass decoration")
assertPresent(core, "cluster and cluster.BorderTop", "exact top-border decoration")
assertAbsent(core, "_G.MinimapBackdrop", "functional MinimapBackdrop must remain untouched")
assertAbsent(core, "GetMaskTexture", "unconfirmed exact mask getter must not drive restoration")

assertPresent(skin, "CreateFrame(\"Frame\", \"RothMinimapSkinFrame\", Minimap)", "native visibility parent")
assertPresent(skin, "IsEffectivelyVisible", "effective visibility gate")
assertPresent(skin, "frame:SetScript(\"OnHide\", StopFireTicker)", "hidden ticker cleanup")
assertAbsent(skin, "or 140", "guessed geometry fallback")

assertPresent(ping, "Map ping received", "opaque ping message")
assertPresent(ping, "enabled and db.where == \"toast\"", "toast precreation")
assertAbsent(ping, "PlaySound", "do not duplicate Blizzard native ping sound")
assertAbsent(ping, "local unit", "ping payload must remain opaque")

assertPresent(zoom, "HookScript(\"OnMouseWheel\"", "native wheel observation")
assertPresent(zoom, "GetZoomLevels", "dynamic zoom range validation")
assertPresent(zoom, "C_Timer.NewTimer", "bounded zoom reset")
assertPresent(zoom, "SafeCall(Minimap, \"SetZoom\", 0)", "single reset mutation")
assertAbsent(zoom, "EnableMouseWheel", "native input state must remain Blizzard-owned")
assertAbsent(zoom, "zoom = zoom + 1", "no duplicate native zoom-in step")
assertAbsent(zoom, "zoom = zoom - 1", "no duplicate native zoom-out step")
assertAbsent(zoom, "C_Timer.After", "uncancellable zoom timer must remain absent")

assertPresent(options, "Settings.NotifyUpdate", "reset refreshes registered settings")
assertAbsent(options, "ROTH_MINIMAP_PING_SOUND", "duplicate ping sound setting retired")
assertAbsent(options, "ROTH_MINIMAP_WHEEL", "redundant wheel-owner setting retired")

print("PASS: Retail 12.1.5 ownership, lifecycle, visibility, ping and native-wheel reset contracts")
