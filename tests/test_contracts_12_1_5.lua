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
local syntaxTest = read("tests/test_syntax.lua")
local mediaTest = read("tests/test_media.py")
local readme = read("README.md")
local agentGuide = read("AGENT_GUIDE.md")
local architecture = read("ARCHITECTURE.md")
local codeIndex = read("CODE_INDEX.md")
local codeGraph = read("CODE_GRAPH.md")
local changelog = read("docs/CHANGELOG.md")
local runtime = table.concat({ core, skin, ping, zoom, options }, "\n")

assertPresent(toc, "## Interface: 120105", "Retail 12.1.5 interface")
assertPresent(toc, "## LoadSavedVariablesFirst: 1", "file-scope DB readiness")
assertPresent(toc, "## Version: 0.5.0", "release version")
assertPresent(toc, "## X-Source-Reviewed-Build: 12.1.5.70783", "reviewed live source")
assertPresent(toc, "## X-Source-Reviewed-Commit: 297d7aaaa736f346b3e036f38ee088eaf7f8c07f", "reviewed source pin")
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

assertPresent(core, "ns.VERSION = \"0.5.0\"", "runtime version")
assertPresent(core, "ns.DB_VERSION = 9", "schema contract")
assertPresent(core, "preset = \"obsidian\"", "new-install visual preset")
assertPresent(core, "inferno = {", "inferno preset")
assertPresent(core, "runic = {", "runic preset")
assertPresent(core, "minimal = {", "minimal preset")
assertPresent(core, "function ns.ApplySkinPreset", "preset application boundary")
assertPresent(core, "upgradeLegacyDefaults", "default-only visual upgrade")
assertPresent(core, "db.skin.preset = \"custom\"", "custom migration preservation")
assertPresent(core, "outset = 28", "refined default frame expansion")
assertPresent(core, "fireIdleAlpha = 0.05", "restrained idle embers")
assertPresent(core, "fireCombatAlpha = 0.26", "controlled combat embers")
assertPresent(core, "ns.media = \"Interface\\\\AddOns\\\\\" .. ADDON_NAME", "dynamic addon media root")
assertAbsent(core, "Interface\\\\AddOns\\\\RothMinimap\\\\media", "hard-coded addon folder")
assertPresent(core, "local detail = SafeString(errorText) or \"<unavailable>\"", "safe error reporting")
assertPresent(core, "if not CanAccess(result) then", "module return access gate")
assertPresent(core, "MigrateLegacyDB", "pre-0.4 migration")
assertPresent(core, "ReplaceContents(ns.db, fresh)", "Settings table identity preservation")
assertPresent(core, "ShouldUseHybridMinimap", "hybrid native fallback")
assertPresent(core, "IsInsideHouse", "housing native fallback")
assertPresent(core, "if desiredMode == nil and maskMode ~= \"square\"", "foreign mask no-op")
assertPresent(core, "InvalidateMask", "world-entry mask revalidation")
assertAbsent(core, "_G.MinimapBackdrop", "functional MinimapBackdrop must remain untouched")
assertAbsent(core, "GetMaskTexture", "unconfirmed mask getter must not drive restoration")
assertAbsent(core, "function ns.RegisterEvent", "generic raw-payload event bus")
assertAbsent(core, "_G.RothMinimap = ns", "mutable implementation namespace exposure")
assertAbsent(core, "tostring(errorText)", "inaccessible errors must not be formatted")

assertPresent(skin, "Obsidian Ember", "visual design contract")
assertPresent(skin, "RM_DIABLO_CHAR_512.tga", "charred rim layer")
assertPresent(skin, "RM_DIABLO_FIRE_ATLAS_512_HOLE_THIN.tga", "thin ember atlas")
assertAbsent(skin, "RM_DIABLO_FIRE_ATLAS_512_HOLE_NORMAL.tga", "heavy fire atlas retired")
assertPresent(skin, "local shadow", "outer shadow layer")
assertPresent(skin, "local ambientGlow", "ambient halo layer")
assertPresent(skin, "local borderHighlight", "frame highlight layer")
assertPresent(skin, "local REFERENCE_MINIMAP_SIZE = 198", "reference-size geometry")
assertPresent(skin, "local IDLE_FIRE_FRAME = 5", "stable idle atlas frame")
assertPresent(skin, "fireBreathGroup:SetLooping(\"REPEAT\")", "C-level idle breath")
assertPresent(skin, "3.4 / math.sqrt(speed)", "bounded idle motion speed")
assertPresent(skin, "if not inCombat or not (FireEnabled()", "combat-only Lua ticker")
assertPresent(skin, "local scaledOutset = math.floor(baseOutset * geometryScale + 0.5)", "proportional frame expansion")
assertPresent(skin, "shadow:ClearAllPoints()", "owned shadow geometry refresh")
assertPresent(skin, "SetEmberColor", "palette-derived ember tint")
assertPresent(skin, "math.min(0.46, base + response)", "bounded charred material response")
assertPresent(skin, "fireMask = frame:CreateMaskTexture()", "addon-owned ember mask")
assertPresent(skin, "fireTexture:AddMaskTexture(fireMask)", "atlas center exclusion")
assertPresent(skin, "ambientGlow:AddMaskTexture(fireMask)", "halo center exclusion")
assertPresent(skin, "pulseTexture:AddMaskTexture(fireMask)", "pulse center exclusion")
assertPresent(skin, "GetFrameStrata", "native draw-order synchronization")
assertPresent(skin, "GetFrameLevel", "native frame-level synchronization")
assertPresent(skin, "pulseGroup:SetScript(\"OnStop\", ResetPulse)", "pulse stop cleanup")
assertPresent(skin, "frame:SetScript(\"OnHide\", OnSkinHidden)", "hidden motion cleanup")
assertAbsent(skin, "SetFrameStrata(\"HIGH\")", "skin must not cover native widgets")
assertAbsent(skin, "SetFrameLevel(300)", "hard-coded top frame level")
assertAbsent(skin, "OnUpdate", "skin polling remains forbidden")

assertPresent(ping, "RegisterEventCallback(\"MINIMAP_PING\"", "CallbackEvent registration")
assertPresent(ping, "UnregisterEventCallback(\"MINIMAP_PING\"", "CallbackEvent cleanup")
assertPresent(ping, "toast:SetSize(168, 30)", "compact toast geometry")
assertPresent(ping, "SetClampedToScreen", "toast screen safety")
assertPresent(ping, "Map ping received", "opaque ping message")
assertPresent(ping, "CreateAnimation(\"Translation\")", "subtle toast motion")
assertAbsent(ping, "RegisterEvent(\"MINIMAP_PING\"", "CallbackEvent must not use raw frame event registration")
assertAbsent(ping, "SetScript(\"OnEvent\"", "secret callback payload must not enter generic OnEvent")
assertAbsent(ping, "PlaySound", "do not duplicate Blizzard native ping sound")
assertAbsent(ping, "SetFrameStrata(\"HIGH\")", "toast must follow native draw order")

assertPresent(zoom, "HookScript(\"OnMouseWheel\"", "native wheel observation")
assertPresent(zoom, "GetZoomLevels", "dynamic zoom range validation")
assertPresent(zoom, "C_Timer.NewTimer", "bounded zoom reset")
assertPresent(zoom, "SafeCall(Minimap, \"SetZoom\", 0)", "single reset mutation")
assertAbsent(zoom, "EnableMouseWheel", "native input state must remain Blizzard-owned")
assertAbsent(zoom, "zoom = zoom + 1", "no duplicate native zoom-in step")
assertAbsent(zoom, "C_Timer.After", "uncancellable zoom timer must remain absent")

assertPresent(options, "ROTH_MINIMAP_PRESET", "appearance preset setting")
assertPresent(options, "Obsidian Ember", "default preset label")
assertPresent(options, "Inferno", "inferno preset label")
assertPresent(options, "Runebound", "runic preset label")
assertPresent(options, "Clean", "minimal preset label")
assertPresent(options, "MarkCustomAndApply", "manual edit custom-state transition")
assertPresent(options, "Layered Diablo frame", "coherent skin label")
assertPresent(options, "Reactive embers", "semantic motion label")
assertPresent(options, "Idle ember motion speed", "idle motion control")
assertPresent(options, "Idle presentation does not run a Lua atlas ticker", "idle performance explanation")
assertPresent(options, "scales proportionally with Blizzard Edit Mode sizing", "responsive frame explanation")
assertPresent(options, "ROTH_MINIMAP_PING_WHERE", "ping destination setting")
assertPresent(options, "if refreshing then return end", "Settings refresh callback suppression")
assertPresent(options, "Settings.NotifyUpdate", "preset refreshes registered settings")

assertPresent(syntaxTest, "find . -type f -name '*.lua'", "recursive POSIX Lua discovery")
assertPresent(syntaxTest, "dir /b /s *.lua", "recursive Windows Lua discovery")
assertPresent(mediaTest, "RM_DIABLO_CHAR_512.tga", "char texture validation")
assertPresent(mediaTest, "RM_DIABLO_FIRE_ATLAS_512_HOLE_THIN.tga", "thin atlas validation")
assertAbsent(mediaTest, "RM_DIABLO_FIRE_ATLAS_512_HOLE_NORMAL.tga", "retired atlas absent from manifest")
assertPresent(mediaTest, "unexpected TGA manifest", "exact media manifest")
assertPresent(mediaTest, "frame {frame_index} has no visible alpha", "per-frame fire validation")
assertPresent(mediaTest, "center_alpha", "visual center-coverage report")

for name, document in pairs({
  README = readme,
  AGENT_GUIDE = agentGuide,
  ARCHITECTURE = architecture,
  CODE_INDEX = codeIndex,
  CODE_GRAPH = codeGraph,
  CHANGELOG = changelog,
}) do
  assertPresent(document, "0.5.0", name .. " release version")
end
assertPresent(readme, "Obsidian Ember", "documented visual direction")
assertPresent(readme, "Inferno", "documented visual presets")
assertPresent(readme, "Runebound", "documented visual presets")
assertPresent(readme, "Clean", "documented visual presets")

print("PASS: Retail 12.1.5 masked embers, smooth idle motion, proportional geometry and ownership contracts")
