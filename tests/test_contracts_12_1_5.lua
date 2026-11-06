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
local readme = read("README.md")
local agentGuide = read("AGENT_GUIDE.md")
local architecture = read("ARCHITECTURE.md")
local codeIndex = read("CODE_INDEX.md")
local changelog = read("docs/CHANGELOG.md")
local runtime = table.concat({ core, skin, ping, zoom, options }, "\n")

assertPresent(toc, "## Interface: 120105", "Retail 12.1.5 interface")
assertPresent(toc, "## LoadSavedVariablesFirst: 1", "file-scope DB readiness")
assertPresent(toc, "## Version: 0.4.2", "release version")
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

assertPresent(core, "ns.DB_VERSION = 6", "schema migration")
assertPresent(core, "MigrateLegacyDB", "pre-0.4 migration")
assertPresent(core, "old.skinEnabled", "legacy skin enablement migration")
assertPresent(core, "SafeTable(old.visual)", "legacy visual migration")
assertPresent(core, "ReplaceContents(old, migrated)", "root identity preservation")
assertPresent(core, "ReplaceContents(ns.db, fresh)", "Settings table identity preservation")
assertPresent(core, "EditMode.Exit", "Edit Mode geometry refresh")
assertPresent(core, "C_Timer.NewTimer(0", "coalesced refresh")
assertPresent(core, "_G.MinimapCompassTexture", "exact compass decoration")
assertPresent(core, "cluster and cluster.BorderTop", "exact top-border decoration")
assertAbsent(core, "_G.MinimapBackdrop", "functional MinimapBackdrop must remain untouched")
assertAbsent(core, "GetMaskTexture", "unconfirmed mask getter must not drive restoration")
assertAbsent(core, "function ns.RegisterEvent", "generic raw-payload event bus")
assertAbsent(core, "_G.RothMinimap = ns", "mutable implementation namespace exposure")

assertPresent(skin, "GetFrameStrata", "native draw-order synchronization")
assertPresent(skin, "GetFrameLevel", "native frame-level synchronization")
assertPresent(skin, "pulseGroup:SetScript(\"OnStop\", ResetPulse)", "pulse stop cleanup")
assertPresent(skin, "frame:SetScript(\"OnHide\", OnSkinHidden)", "hidden ticker cleanup")
assertAbsent(skin, "SetFrameStrata(\"HIGH\")", "skin must not cover native widgets")
assertAbsent(skin, "SetFrameLevel(300)", "hard-coded top frame level")
assertAbsent(skin, "or 140", "guessed geometry fallback")

assertPresent(ping, "eventFrame:RegisterEvent(\"MINIMAP_PING\")", "direct ping event ownership")
assertPresent(ping, "if event == \"MINIMAP_PING\" then OnPing() end", "payload dropped at native boundary")
assertPresent(ping, "Map ping received", "opaque ping message")
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

assertPresent(options, "ROTH_MINIMAP_PING_WHERE", "ping destination setting")
assertPresent(options, "Settings.CreateDropdown", "ping destination control")
assertPresent(options, "if refreshing then return end", "reset callback suppression")
assertPresent(options, "Settings.NotifyUpdate", "reset refreshes registered settings")

for name, document in pairs({
  README = readme,
  AGENT_GUIDE = agentGuide,
  ARCHITECTURE = architecture,
  CODE_INDEX = codeIndex,
  CHANGELOG = changelog,
}) do
  assertPresent(document, "0.4.2", name .. " release version")
end
assertPresent(readme, "SavedVariables schema `6`", "README schema")
assertPresent(agentGuide, "schema-6", "agent schema contract")
assertPresent(architecture, "No generic event bus", "architecture signal ownership")

print("PASS: Retail 12.1.5 static ownership, migration, lifecycle, Settings and documentation contracts")
