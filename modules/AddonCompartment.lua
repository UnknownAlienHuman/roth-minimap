-- Roth Minimap - AddonCompartment investigation helpers
--
-- Purpose:
--   Blizzard's AddonCompartmentFrame (12.0+) can inflate MinimapCluster bounds and
--   shows incomplete state ("not owned") for some addons depending on how they register.
--   This module provides a safe dumper to understand what data Blizzard stores and how
--   the frame is populated on the current client build, without copying other addons' code.
--
-- Design:
--   * No OnUpdate loops.
--   * No secure/protected calls.
--   * SecretValue-safe: never uses # or string operations on unknown values.

local ADDON, ns = ...

ns.compartment = ns.compartment or {}
local M = ns.compartment

local function dbg(...)
  if ns.db and ns.db.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffRothMinimap:|r " .. table.concat({ tostringall(...) }, " "))
  end
end

local function safeToString(v)
  local ok, s = pcall(tostring, v)
  if ok then return s end
  return "<tostring-error>"
end

local function safeType(v)
  local ok, t = pcall(type, v)
  if ok then return t end
  return "<type-error>"
end

local function countTable(t, maxN)
  if type(t) ~= "table" then return 0 end
  local n = 0
  for _ in pairs(t) do
    n = n + 1
    if maxN and n >= maxN then break end
  end
  return n
end

local function dumpKeys(t, maxN)
  if type(t) ~= "table" then
    return "<not-a-table>"
  end
  maxN = maxN or 24
  local out, n = {}, 0
  for k, v in pairs(t) do
    n = n + 1
    out[#out+1] = safeToString(k) .. ":" .. safeType(v)
    if n >= maxN then break end
  end
  return table.concat(out, ", ")
end

local function getChildrenList(f)
  if not f or not f.GetChildren then return {} end
  local ok, a, b, c, d, e, r = pcall(function() return { f:GetChildren() } end)
  if ok and type(a) == "table" then return a end
  return {}
end

function M:Dump(reason)
  local f = _G.AddonCompartmentFrame
  if not f then
    dbg("compartment:", "AddonCompartmentFrame=nil")
    return
  end

  dbg("compartment: dump begin", reason or "(no reason)")
  dbg("frame:", safeToString(f), "shown=" .. safeToString(f:IsShown()), "parent=" .. safeToString(f:GetParent() and f:GetParent():GetName()))
  dbg("size:", safeToString(f:GetWidth()), safeToString(f:GetHeight()), "scale=" .. safeToString(f:GetScale()))
  if f.GetPoint then
    local ok, p, rel, rp, x, y = pcall(f.GetPoint, f, 1)
    if ok then
      dbg("point:", safeToString(p), safeToString(rel and rel:GetName()), safeToString(rp), safeToString(x), safeToString(y))
    end
  end

  -- Probe common candidate fields used by Blizzard widgets.
  local candidates = {
    "registeredAddons",
    "registeredAddonsByName",
    "addons",
    "entries",
    "buttons",
    "AddonButtons",
    "addonButtons",
    "buttonPool",
    "addonButtonPool",
    "pool",
    "dataProvider",
    "scrollView",
  }

  for _, key in ipairs(candidates) do
    local v = rawget(f, key)
    if v ~= nil then
      dbg("field:", key, "type=" .. safeType(v), "count=" .. safeToString(countTable(v, 9999)))
      if type(v) == "table" then
        dbg("  keys:", dumpKeys(v, 18))
      end
    end
  end

  -- Probe children.
  local children = getChildrenList(f)
  dbg("children:", #children)
  local shownButtons = 0
  for i = 1, math.min(#children, 40) do
    local c = children[i]
    local okType, ot = pcall(c.GetObjectType, c)
    local okName, nm = pcall(c.GetName, c)
    local okShown, sh = pcall(c.IsShown, c)
    local typeStr = okType and ot or "<no-type>"
    local nameStr = okName and (nm or "<nil>") or "<no-name>"
    local shownStr = okShown and safeToString(sh) or "<no-shown>"

    if typeStr == "Button" and okShown and sh then
      shownButtons = shownButtons + 1
    end

    -- Avoid touching potentially secret fields; only rawget + safe tostring.
    local addonName = rawget(c, "addonName") or rawget(c, "AddonName") or rawget(c, "name")
    local icon = rawget(c, "icon") or rawget(c, "Icon") or rawget(c, "texture")
    dbg(("child[%d]:"):format(i), typeStr, nameStr, "shown=" .. shownStr, "addon=" .. safeToString(addonName), "icon=" .. safeToString(icon))
  end
  dbg("children: shown buttons:", shownButtons)

  dbg("compartment: dump end")
end

-- Optional: auto-dump once on login when debug is enabled.
local ev
function M:Apply()
  if not (ns.db and ns.db.debug) then
    if ev then ev:UnregisterAllEvents() end
    return
  end
  if not ev then
    ev = CreateFrame("Frame")
    ev:SetScript("OnEvent", function(_, event)
      if event == "PLAYER_LOGIN" then
        C_Timer.After(1, function()
          if ns.compartment and ns.compartment.Dump then
            ns.compartment:Dump("PLAYER_LOGIN")
          end
        end)
      end
    end)
    ev:RegisterEvent("PLAYER_LOGIN")
  end
end
