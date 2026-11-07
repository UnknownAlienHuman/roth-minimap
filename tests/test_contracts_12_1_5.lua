local function read(path)
  local file = assert(io.open(path, "rb"))
  local text = assert(file:read("*a"))
  file:close()
  return text
end

local function exists(path)
  local file = io.open(path, "rb")
  if not file then return false end
  file:close()
  return true
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
local syntaxTest = read("tests/test_syntax.lua")
local mediaTest = read("tests/test_media.py")
local workflow = read(".github/workflows/validate.yml")
local readme = read("README.md")
local agentGuide = read("AGENT_GUIDE.md")
local architecture = read("ARCHITECTURE.md")
local codeIndex = read("CODE_INDEX.md")
local codeGraph = read("CODE_GRAPH.md")
local changelog = read("docs/CHANGELOG.md")
local runtime = table.concat({ core, skin, ping, zoom, options }, "\n")

assertPresent(toc, "## Interface: 120105", "Retail 12.1.5 interface")
assertPresent(toc, "## LoadSavedVariablesFirst: 1", "file-scope DB readiness")
assertPresent(toc, "## Version: 0.4.6", "release version")
assertPresent(toc, "## X-Source-Reviewed-Build: 12.1.5.70783", "reviewed live source")
assertPresent(toc, "## X-Source-Reviewed-Commit: 297d7aaaa736f346b3e036f38ee088eaf7f8c07f", "reviewed source pin")
assertAbsent(toc, "ButtonBag", "button collector must not load")
assertAbsent(toc, "AddonCompartment.lua", "compartment diagnostics must not load")

for line in toc:gmatch("[^\r\n]+") do
  if line ~= "" and not line:match("^##") then
    local path = line:gsub("\\", "/")
    assert(exists(path), "TOC entry does not exist: " .. path)
  end
end

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

assertPresent(core, "ns.VERSION = \"0.4.6\"", "runtime version")
assertPresent(core, "ns.DB_VERSION = 8", "schema contract")
assertPresent(core, "ns.media = \"Interface\\\\AddOns\\\\\" .. ADDON_NAME", "dynamic addon media root")
assertAbsent(core, "Interface\\\\AddOns\\\\RothMinimap\\\\media", "hard-coded addon folder")
assertPresent(core, "not CanAccess(current)", "default merge access gate")
assertPresent(core, "local detail = SafeString(errorText) or \"<unavailable>\"", "safe error reporting")
assertPresent(core, "SafeString = SafeString", "safe string helper export")
assertPresent(core, "if not CanAccess(result) then", "module return access gate")
assertPresent(core, "returned non-boolean status", "module return type contract")
assertPresent(core, "if currentAlpha == nil then return false end", "alpha restore retry gate")
assertPresent(core, "artState[object] = nil", "alpha snapshot cleanup")
assertPresent(core, "local previousVersion = SafeNumber(db.version)", "schema upgrade source version")
assertPresent(core, "Schema 8 repairs", "zero-alpha migration repair")
assertPresent(core, "local function PositiveAlpha", "legacy visible-alpha migration")
assertPresent(core, "local maskMode", "mask transition ownership")
assertPresent(core, "local maskNeedsValidation = true", "world-entry mask revalidation")
assertPresent(core, "desiredMode == nil and maskMode ~= \"square\"", "disabled mask no-op")
assertPresent(core, "InvalidateMask()", "world-entry mask invalidation")
assertPresent(core, "refreshNeedsFullApply = false\n  CancelRefreshTimer()", "full apply supersedes queued refresh")
assertPresent(core, "return CallModule(\"skin\", \"ApplySafeState\")", "safe-state failure propagation")
assertPresent(core, "MigrateLegacyDB", "pre-0.4 migration")
assertPresent(core, "ReplaceContents(old, migrated)", "root identity preservation")
assertPresent(core, "ReplaceContents(ns.db, fresh)", "Settings table identity preservation")
assertPresent(core, "ShouldUseHybridMinimap", "hybrid native fallback")
assertPresent(core, "IsInsideHouse", "housing native fallback")
assertPresent(core, "fireIdleFPS = 2", "low idle fire cadence")
assertPresent(core, "fireCombatFPS = 8", "combat fire cadence")
assertPresent(core, "db.skin.fireFPS = nil", "unified cadence retirement")
assertPresent(core, "EditMode.Exit", "Edit Mode geometry refresh")
assertPresent(core, "C_Timer.NewTimer(0", "coalesced refresh")
assertPresent(core, "if IsCombatLocked() then", "combat queue collapse")
assertPresent(core, "elseif not pendingFullApply then", "geometry/full pending arbitration")
assertPresent(core, "_G.MinimapCompassTexture", "exact compass decoration")
assertPresent(core, "cluster and cluster.BorderTop", "exact top-border decoration")
assertAbsent(core, "_G.MinimapBackdrop", "functional MinimapBackdrop must remain untouched")
assertAbsent(core, "GetMaskTexture", "unconfirmed mask getter must not drive restoration")
assertAbsent(core, "function ns.RegisterEvent", "generic raw-payload event bus")
assertAbsent(core, "_G.RothMinimap = ns", "mutable implementation namespace exposure")
assertAbsent(core, "tostring(errorText)", "inaccessible errors must not be formatted")

assertPresent(skin, "PresentationEnabled", "native presentation skin gate")
assertPresent(skin, "SyncCombatState", "point-of-use combat-state synchronization")
assertPresent(skin, "ns.UsesNativePresentation()", "hybrid/housing skin suppression")
assertPresent(skin, "GetFrameStrata", "native draw-order synchronization")
assertPresent(skin, "GetFrameLevel", "native frame-level synchronization")
assertPresent(skin, "pulseGroup:SetScript(\"OnStop\", ResetPulse)", "pulse stop cleanup")
assertPresent(skin, "frame:SetScript(\"OnHide\", OnSkinHidden)", "hidden ticker cleanup")
assertAbsent(skin, "SetFrameStrata(\"HIGH\")", "skin must not cover native widgets")
assertAbsent(skin, "SetFrameLevel(300)", "hard-coded top frame level")
assertAbsent(skin, "or 140", "guessed geometry fallback")

assertPresent(ping, "RegisterEventCallback(\"MINIMAP_PING\"", "CallbackEvent registration")
assertPresent(ping, "UnregisterEventCallback(\"MINIMAP_PING\"", "CallbackEvent cleanup")
assertPresent(ping, "Map ping received", "opaque ping message")
assertAbsent(ping, "RegisterEvent(\"MINIMAP_PING\"", "CallbackEvent must not use raw frame event registration")
assertAbsent(ping, "SetScript(\"OnEvent\"", "secret callback payload must not enter generic OnEvent")
assertAbsent(ping, "PlaySound", "do not duplicate Blizzard native ping sound")
assertAbsent(ping, "local unit", "ping payload must remain opaque")

assertPresent(zoom, "HookScript(\"OnMouseWheel\"", "native wheel observation")
assertPresent(zoom, "GetZoomLevels", "dynamic zoom range validation")
assertPresent(zoom, "C_Timer.NewTimer", "bounded zoom reset")
assertPresent(zoom, "scheduledDelay", "pending delay ownership")
assertPresent(zoom, "scheduledDelay ~= delay", "delay-change reschedule")
assertPresent(zoom, "SafeCall(Minimap, \"SetZoom\", 0)", "single reset mutation")
assertAbsent(zoom, "EnableMouseWheel", "native input state must remain Blizzard-owned")
assertAbsent(zoom, "zoom = zoom + 1", "no duplicate native zoom-in step")
assertAbsent(zoom, "zoom = zoom - 1", "no duplicate native zoom-out step")
assertAbsent(zoom, "C_Timer.After", "uncancellable zoom timer must remain absent")

assertPresent(options, "ROTH_MINIMAP_PING_WHERE", "ping destination setting")
assertPresent(options, "Settings.CreateDropdown", "ping destination control")
assertPresent(options, "ROTH_MINIMAP_FIRE_IDLE_FPS", "idle fire cadence setting")
assertPresent(options, "ROTH_MINIMAP_FIRE_COMBAT_FPS", "combat fire cadence setting")
assertAbsent(options, "ROTH_MINIMAP_FIRE_FPS\"", "unified fire cadence setting retired")
assertPresent(options, "Hybrid Minimap", "native fallback explanation")
assertPresent(options, "if refreshing then return end", "reset callback suppression")
assertPresent(options, "Settings.NotifyUpdate", "reset refreshes registered settings")
assertPresent(options, "ns.util.SafeString(firstError)", "Settings error access gate")
assertAbsent(options, "tostring(firstError)", "Settings errors must not be formatted before gating")

assertPresent(syntaxTest, "io.popen", "recursive Lua discovery")
assertPresent(syntaxTest, "find . -type f -name '*.lua'", "POSIX Lua discovery")
assertPresent(syntaxTest, "dir /b /s *.lua", "Windows Lua discovery")
assertPresent(syntaxTest, "loadfile(path)", "per-file syntax validation")
assertPresent(mediaTest, "media manifest mismatch", "exact media manifest")
assertPresent(mediaTest, "frame_alpha", "per-frame atlas alpha validation")
assertPresent(mediaTest, "expected uncompressed true-color TGA", "TGA header validation")
assertPresent(mediaTest, "all 16 frames are byte-identical", "fire atlas frame validation")
assertPresent(mediaTest, "transparent center", "mask center validation")

assertPresent(workflow, "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1", "pinned checkout action")
assertPresent(workflow, "persist-credentials: false", "workflow token cleanup")
assertPresent(workflow, "runs-on: ubuntu-24.04", "pinned runner image")
assertPresent(workflow, "lua5.1 tests/test_syntax.lua", "syntax gate")
assertPresent(workflow, "python3 tests/test_media.py", "media gate")

for name, document in pairs({
  README = readme,
  AGENT_GUIDE = agentGuide,
  ARCHITECTURE = architecture,
  CODE_INDEX = codeIndex,
  CODE_GRAPH = codeGraph,
  CHANGELOG = changelog,
}) do
  assertPresent(document, "0.4.6", name .. " release version")
end
assertPresent(readme, "schema `8`", "README schema")
assertPresent(readme, "texlua tests/test_syntax.lua", "recursive syntax command")
assertPresent(readme, "python3 tests/test_media.py", "media validation command")
assertAbsent(readme, "texlua --luaconly RothMinimap.lua Options.lua", "misleading multi-file compiler command")
assertPresent(agentGuide, "texlua tests/test_syntax.lua", "agent syntax command")
assertAbsent(agentGuide, "texlua --luaconly RothMinimap.lua Options.lua", "agent misleading compiler command")

print("PASS: Retail 12.1.5 mask, migration, access, callback, media, ownership and lifecycle contracts")
