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

assertPresent(toc, "## Interface: 120100", "Retail interface")
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

assertPresent(core, "EditMode.Exit", "Edit Mode geometry refresh")
assertPresent(core, "buttonBag = \"removed\"", "retired button bag status")
assertPresent(core, "SetDecorativeAlpha", "decorative alpha owner")
assertPresent(ping, "Map ping received", "opaque ping message")
assertAbsent(ping, "local unit", "ping unit payload must remain opaque")
assertPresent(zoom, "C_Timer.NewTimer", "bounded zoom reset")
assertAbsent(zoom, "C_Timer.After", "recursive zoom timer must remain absent")

print("PASS: Blizzard/Edit Mode owns minimap geometry and widgets; RothMinimap owns only additive art, opaque ping and bounded zoom")
