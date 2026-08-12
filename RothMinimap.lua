-- Roth Minimap - Core
-- Lightweight minimap customization: square mask, skins, ping toast, zoom, HUD overlay, minimap button bag.
--
-- Goals:
--   * Midnight-ready (Interface 12.0)
--   * Low CPU: no always-on OnUpdate loops; prefer events + C_Timer tickers
--   * Low taint risk: never move secure/protected frames in combat
--   * Modular: each feature is isolated

local ADDON, ns = ...

-- Public namespace
ns.ADDON = ADDON
ns.VERSION = "0.3.11.29"

-- -----------------------------------------------------------------------------
-- Utilities (minimal, intentionally)
-- -----------------------------------------------------------------------------

local function deepcopy(src, dst)
  if type(src) ~= "table" then return src end
  dst = dst or {}
  for k, v in pairs(src) do
    if type(v) == "table" then
      dst[k] = deepcopy(v, type(dst[k]) == "table" and dst[k] or {})
    else
      dst[k] = v
    end
  end
  return dst
end

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function round(v)
  return math.floor((v or 0) + 0.5)
end

ns.util = ns.util or {}
ns.util.deepcopy = deepcopy
ns.util.clamp = clamp
ns.util.round = round


-- Safe call wrappers: never let one module crash the whole addon.
local function _rm_errhandler(err)
  return tostring(err)
end

function ns.util.safeCall(func, ...)
  if type(func) ~= "function" then return end
  local ok, res = xpcall(func, _rm_errhandler, ...)
  if not ok then
    local msg = "RothMinimap: error: " .. tostring(res)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff5555" .. msg .. "|r")
    end
  end
  return res
end

function ns.util.safeMethod(obj, method, ...)
  if not obj then return end
  local fn = obj[method]
  if type(fn) ~= "function" then return end
  return ns.util.safeCall(fn, obj, ...)
end

-- -----------------------------------------------------------------------------
-- Defaults / SavedVariables
-- -----------------------------------------------------------------------------

local DEFAULTS = {
  version = 18,
  debug = false,

  -- Layout
  enabled = true,
  size = 205,        -- Minimap size (square)
  scale = 1.00,      -- MinimapCluster scale
  point = { "TOPRIGHT", "UIParent", "TOPRIGHT", -20, -20 },

  -- Blizzard art
  hideBlizzardArt = true,
  hideZoomButtons = true,
  hideNorthTag = true,
  hideAddonCompartment = true,

  -- Shape / Skin
  square = true,
  skinEnabled = true,
  skin = "Diablo",
  skinPadding = 6, -- extra pixels around Minimap for skin frame

  shadow = {
    enabled = true,
    -- "MATERIAL" = corner-safe 2-layer drop shadow (recommended)
    -- "EDGE"     = legacy gradient rim (edge-only; corners are flat by design)
    style = "MATERIAL",
    alpha = 0.22,
    thickness = 3,
    inset = 0,
  },

  -- Visual layers for the skin (tweakable without swapping textures)
  visual = {
    border = {
      alpha = 1.00,
      -- Default border is intentionally dark (the shipped texture is a white silhouette).
      color = { 0.25, 0.22, 0.20 },
      -- Convenience UI preset. "Custom" means: keep the current color value.
      preset = "Dark",
    },

    runes = {
      enabled = true,
      outAlpha = 0.20,
      combatAlpha = 0.35,
      blendMode = "ADD",
      color = { 1, 1, 1 },
    },

    glow = {
      enabled = true,
      outAlpha = 0.12,
      combatAlpha = 0.28,
      scale = 1.08,
      blendMode = "ADD",
      color = { 1, 0.45, 0.20 },
    },

    vignette = {
      enabled = true,
      alpha = 0.22,
    },

    char = {
      enabled = true,
      alpha = 0.65,
      blendMode = "BLEND",
    },

    fx = {
      enabled = true,
      combatFlash = true,
      lootFlash = true,
      achievementFlash = true,
      flashAlpha = 0.75,
      flashScale = 1.12,
      durationIn = 0.08,
      durationOut = 0.22,
    },
  },


  quickMap = {
    enabled = true,
    modifier = "SHIFT", -- SHIFT | CTRL | ALT
    button = "LeftButton",
  },

  zoneText = {
    font = "Friz Quadrata TT",
  },

  -- Diablo fire overlay behavior
  fire = {
    enabled = true,

    -- Texture preset (non-destructive). Atlas is selected by filename, originals stay intact in media.
    -- Only 512 atlases are shipped (performance + package size).
    atlasSize = "512",
    atlasPreset = "HOLE_THIN", -- "ORIGINAL" | "HOLE_THIN" | "HOLE_NORMAL" | "HOLE_THICK"
    -- Base animation
    -- Keep it subtle: "smolder" out of combat, controlled intensity in combat.
    outAlpha = 0.12,
    combatAlpha = 0.45,
    outFPS = 1,
    combatFPS = 8,

    -- Combat transition
    combatFlare = true,       -- flare when entering combat
    flareDuration = 0.18,     -- sec
    fadeOutDuration = 1.20,   -- sec

    -- Breathing overlay (looping alpha on a separate fire layer)
    breath = {
      enabled = true,
      outMin = 0.03,
      outMax = 0.10,
      outPeriod = 4.6,
      combatMin = 0.06,
      combatMax = 0.18,
      combatPeriod = 1.8,
    },

    -- Reactive behavior (visual feedback)
    reactive = {
      enabled = true,

      -- Ping: short burst
      pingPulse = true,
      pingStrength = 0.30,    -- +alpha
      pingDuration = 0.55,    -- sec

      -- Damage taken: very short hot flicker
      damagePulse = true,
      damageStrength = 0.22,  -- +alpha
      damageDuration = 0.25,  -- sec
      damageThrottle = 0.10,  -- sec (ignore extra hits inside this window)

      -- Low health: steady stronger glow + faster fire
      lowHealth = true,
      lowHealthThreshold = 0.35, -- % (0-1)
      lowHealthAlphaBoost = 0.22,
      lowHealthFpsBoost = 6,

      -- Mounted/resting dim (keep it subtle)
      dimWhileMounted = true,
      dimWhileResting = true,
      dimFactor = 0.80,       -- multiplier (0-1)

      -- "Joy" pulse: loot/achievements
      joyPulse = true,
      joyStrength = 0.30,
      joyDuration = 0.55,
      joyThrottle = 0.35,
      lootPulse = true,
      achievementPulse = true,
    },
  },

  -- Ping toast
  ping = {
    enabled = true,
    where = "toast", -- "toast" | "chat"
    duration = 3.0,
    sound = false,
  },

  -- Zoom
  zoom = {
    mousewheel = true,
    autoReset = true,
    delay = 3.0,
    mode = "smooth", -- "smooth" | "snap"
    interval = 0.20,  -- smooth tick interval
  },

  -- Minimap buttons
  buttons = {
    bag = true,
    showToggle = true,
    buttonSize = 28,
    columns = 6,
    stashWhenClosed = true,
    openOnHover = true,
    hoverCloseDelay = 0.20,
    openAtCursor = true,
    pinOnClick = true,
    -- Strict: only collect addon buttons created via LibDBIcon-1.0.
    -- Default is OFF to avoid an "empty bag" for addons that implement their own minimap buttons.
    onlyLibDBIcon = false,
    -- Exclusions (case-insensitive)
    --   * excludeExact: exact frame names (recommended)
    --   * excludeSubstrings: substring tokens matched against frame name or tostring(btn)
    -- Legacy field "exclude" is kept for migration.
    excludeExact = "",
    excludeSubstrings = "",
    exclude = "", -- legacy (comma/space separated)
  },

  -- Mover
  mover = {
    enabled = false,
    requireAlt = true,
  },
}

-- Keep a reference to the original shape helper so we can restore it.
local _origGetMinimapShape = _G.GetMinimapShape

local function dprint(...)
  if ns.db and ns.db.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffRothMinimap:|r " .. table.concat({ tostringall(...) }, " "))
  end
end

local function initDB()
  if type(_G.RothMinimapDB) ~= "table" then
    _G.RothMinimapDB = deepcopy(DEFAULTS)
  else
    _G.RothMinimapDB = deepcopy(DEFAULTS, _G.RothMinimapDB)
  end
  ns.db = _G.RothMinimapDB


  -- Versioned migrations (keep behavior sane across rapid iterations).
  local db = ns.db
  local prev = db.version or 0
  if prev < 3 then
    db.version = 3

    -- v0.3.4 defaulted to hiding buttons when the bag is closed; that is too surprising.
    if db.buttons then
      db.buttons.stashWhenClosed = false
    end

    -- The HUD ring overlay was visually noisy on a square minimap.
  end

  if prev < 4 then
    db.version = 4

    if db.ping then
      db.ping.sound = false
    end

    if db.buttons then
      db.buttons.stashWhenClosed = true
      if db.buttons.openOnHover == nil then db.buttons.openOnHover = true end
      if db.buttons.hoverCloseDelay == nil then db.buttons.hoverCloseDelay = 0.20 end
      if db.buttons.openAtCursor == nil then db.buttons.openAtCursor = true end
      if db.buttons.pinOnClick == nil then db.buttons.pinOnClick = true end
      if db.buttons.onlyLibDBIcon == nil then db.buttons.onlyLibDBIcon = false end
    end

    if type(db.shadow) ~= "table" then
      db.shadow = { enabled = true, alpha = 0.55, thickness = 18, inset = 0 }
    else
      if db.shadow.enabled == nil then db.shadow.enabled = true end
      if db.shadow.alpha == nil then db.shadow.alpha = 0.55 end
      if db.shadow.thickness == nil then db.shadow.thickness = 18 end
      if db.shadow.inset == nil then db.shadow.inset = 0 end
    end
  end

	if prev < 5 then
		db.version = 5

		-- New visual layer controls (glow / vignette / flash)
		if type(db.visual) ~= "table" then
			db.visual = deepcopy(DEFAULTS.visual)
		end

		-- Fire breathing + joy pulses
		if type(db.fire) == "table" then
			if type(db.fire.breath) ~= "table" then
				db.fire.breath = deepcopy(DEFAULTS.fire.breath)
			end
			if type(db.fire.reactive) == "table" then
				local r = db.fire.reactive
				if r.joyPulse == nil then r.joyPulse = true end
				if r.joyStrength == nil then r.joyStrength = 0.30 end
				if r.joyDuration == nil then r.joyDuration = 0.55 end
				if r.joyThrottle == nil then r.joyThrottle = 0.35 end
				if r.lootPulse == nil then r.lootPulse = true end
				if r.achievementPulse == nil then r.achievementPulse = true end
			end
		end
	end

	if prev < 6 then
		db.version = 6

		-- New "charred edge" visual layer (burnt parchment rim).
		if type(db.visual) ~= "table" then
			db.visual = deepcopy(DEFAULTS.visual)
		end
		if type(db.visual.char) ~= "table" then
			db.visual.char = deepcopy(DEFAULTS.visual.char)
		end
	end

	if prev < 7 then
		db.version = 7

		-- v0.3.11.6: make shadow more visible by default.
		if type(db.shadow) ~= "table" then
			db.shadow = { enabled = true, alpha = 0.75, thickness = 24, inset = 0 }
		else
			if db.shadow.alpha ~= nil and math.abs((tonumber(db.shadow.alpha) or 0) - 0.55) < 1e-6 then
				db.shadow.alpha = 0.75
			end
			if db.shadow.thickness ~= nil and (tonumber(db.shadow.thickness) or 0) == 18 then
				db.shadow.thickness = 24
			end
		end
	end

	if prev < 8 then
		db.version = 8

		-- v0.3.11.7: border silhouette is white; default recolor is now much darker.
		if type(db.visual) ~= "table" then
			db.visual = deepcopy(DEFAULTS.visual)
		end
		if type(db.visual.border) ~= "table" then
			db.visual.border = deepcopy(DEFAULTS.visual.border)
		end
		local c = db.visual.border.color
		local function setDark()
			db.visual.border.color = { 0.25, 0.22, 0.20 }
		end
		if type(c) ~= "table" then
			setDark()
		else
			local r, g, b = tonumber(c[1]) or 0, tonumber(c[2]) or 0, tonumber(c[3]) or 0
			local function close(a, x) return math.abs(a - x) < 1e-4 end
			-- Upgrade the known old defaults (pure white / parchment tone) to the new dark tone.
			if (close(r, 1) and close(g, 1) and close(b, 1)) or (close(r, 0.65) and close(g, 0.58) and close(b, 0.50)) then
				setDark()
			end
		end
	end

	if prev < 9 then
		db.version = 9

		-- v0.3.11.8: split exclusions into exact names and substring tokens.
		if type(db.buttons) ~= "table" then
			db.buttons = deepcopy(DEFAULTS.buttons)
		else
			if db.buttons.excludeExact == nil then db.buttons.excludeExact = "" end
			if db.buttons.excludeSubstrings == nil then
				-- Migrate legacy field.
				db.buttons.excludeSubstrings = tostring(db.buttons.exclude or "")
			end
			-- Keep legacy field but clear to reduce confusion.
			if type(db.buttons.exclude) == "string" and db.buttons.exclude ~= "" then
				db.buttons.exclude = ""
			end
		end

		-- v0.3.11.8: border color preset helper.

		-- v0.3.11.9: ButtonBag now avoids adopting Minimap POIs/map content; shadow edge gradient orientation fixed.
		if type(db.visual) ~= "table" then
			db.visual = deepcopy(DEFAULTS.visual)
		end
		if type(db.visual.border) ~= "table" then
			db.visual.border = deepcopy(DEFAULTS.visual.border)
		end
		if db.visual.border.preset == nil then
			local c = db.visual.border.color
			local r, g, b = 0, 0, 0
			if type(c) == "table" then
				r, g, b = tonumber(c[1]) or 0, tonumber(c[2]) or 0, tonumber(c[3]) or 0
			end
			local function close(a, x) return math.abs((tonumber(a) or 0) - x) < 1e-4 end
			if close(r, 1) and close(g, 1) and close(b, 1) then
				db.visual.border.preset = "White"
			elseif close(r, 0.65) and close(g, 0.58) and close(b, 0.50) then
				db.visual.border.preset = "Parchment"
			elseif close(r, 0.25) and close(g, 0.22) and close(b, 0.20) then
				db.visual.border.preset = "Dark"
			else
				db.visual.border.preset = "Custom"
			end
		end
		end

		if prev < 10 then
		db.version = 10

		-- Force LibDBIcon-only button bag. This is the only reliable public signal for addon minimap buttons.
		if type(db.buttons) ~= "table" then
			db.buttons = deepcopy(DEFAULTS.buttons)
		end
		db.buttons.onlyLibDBIcon = true

		-- Shadow defaults: switch from the earlier heavy vignette to a thinner Material-like rim.
		if type(db.shadow) ~= "table" then
			db.shadow = deepcopy(DEFAULTS.shadow)
		else
			local a = tonumber(db.shadow.alpha)
			local th = tonumber(db.shadow.thickness)
			local function close(x, y)
				return x ~= nil and math.abs((tonumber(x) or 0) - y) < 1e-4
			end
			-- Only auto-upgrade known old defaults.
			if close(a, 0.75) or close(a, 0.55) then
				db.shadow.alpha = DEFAULTS.shadow.alpha
			end
			if th == 24 or th == 18 then
				db.shadow.thickness = DEFAULTS.shadow.thickness
			end
		end

		-- Hide the Blizzard AddonCompartment button by default (it inflates MinimapCluster bounds and is incomplete).
		  if db.hideAddonCompartment and AddonCompartmentFrame then
    AddonCompartmentFrame:Hide()
  end

  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM and db.zoneText and db.zoneText.font and ZoneTextString then
    local fontPath = LSM:Fetch("font", db.zoneText.font)
    if fontPath then
      local oldPath, height, flags = ZoneTextString:GetFont()
      ZoneTextString:SetFont(fontPath, height, flags)
    end
  end
end

	if prev < 11 then
		db.version = 11
		-- Stage 9: visual seam/rim fixes + align code fallbacks with shipped defaults.
	end


		if prev < 12 then
			db.version = 12

			-- v0.3.11.15: soften + narrow the default shadow; fix ButtonBag interaction edge-cases.
			-- Only auto-adjust known old defaults to avoid overriding user customization.
			if type(db.shadow) ~= "table" then
				db.shadow = deepcopy(DEFAULTS.shadow)
			else
				local a = tonumber(db.shadow.alpha)
				local th = tonumber(db.shadow.thickness)
				local function close(x, y)
					return x ~= nil and math.abs((tonumber(x) or 0) - y) < 1e-4
				end
				if close(a, 0.35) then
					db.shadow.alpha = DEFAULTS.shadow.alpha
				end
				if th == 10 then
					db.shadow.thickness = DEFAULTS.shadow.thickness
				end
			end
		end

		if prev < 13 then
			db.version = 13
			-- v0.3.11.16: make the default shadow narrower + smoother.
			-- Only auto-adjust if the user is still on the known stage-12 defaults.
			if type(db.shadow) ~= "table" then
				db.shadow = deepcopy(DEFAULTS.shadow)
			else
				local a = tonumber(db.shadow.alpha)
				local th = tonumber(db.shadow.thickness)
				local function close(x, y)
					return x ~= nil and math.abs((tonumber(x) or 0) - y) < 1e-4
				end
				if close(a, 0.30) and (th == 7 or th == 6) then
					db.shadow.alpha = DEFAULTS.shadow.alpha
					db.shadow.thickness = DEFAULTS.shadow.thickness
				end
			end
		end

		if prev < 14 then
			db.version = 14
			-- v0.3.11.20: narrower + smoother shadow defaults.
			-- Only auto-adjust if the user is still on known stage defaults.
			if type(db.shadow) ~= "table" then
				db.shadow = deepcopy(DEFAULTS.shadow)
			else
				local a = tonumber(db.shadow.alpha)
				local th = tonumber(db.shadow.thickness)
				local function close(x, y)
					return x ~= nil and math.abs((tonumber(x) or 0) - y) < 1e-4
				end
				-- Known stage defaults
				if (close(a, 0.26) and (th == 5)) or (close(a, 0.24) and (th == 3)) then
					db.shadow.alpha = DEFAULTS.shadow.alpha
					db.shadow.thickness = DEFAULTS.shadow.thickness
				end
			end
		end

		if prev < 15 then
			db.version = 15
			-- v0.3.11.21: ButtonBag no longer forces LibDBIcon-only mode.
			-- This avoids an "empty bag" for addons that implement custom minimap buttons.
			if type(db.buttons) ~= "table" then
				db.buttons = deepcopy(DEFAULTS.buttons)
			end
			if db.buttons.onlyLibDBIcon == true then
				db.buttons.onlyLibDBIcon = false
			end
		end

    if prev < 16 then
      db.version = 16
      -- v0.3.11.22-24: shadow style selector ("MATERIAL"/"EDGE") + safer Material drop shadow.
      if type(db.shadow) ~= "table" then
        db.shadow = deepcopy(DEFAULTS.shadow)
      else
        if db.shadow.style == nil then
          db.shadow.style = DEFAULTS.shadow.style or "MATERIAL"
        end
      end
    end

    if prev < 17 then
      db.version = 17
      -- v0.3.11.25: shrink default skin padding so the minimap content takes more area.
      -- Only auto-adjust if the user is still on the old default.
      if db.skinPadding == 10 then
        db.skinPadding = DEFAULTS.skinPadding
      end
    end

    if prev < 18 then
      db.version = 18
      -- v0.3.11.30: these Blizzard visuals are always hidden in RothMinimap.
      db.hideBlizzardArt = true
      db.hideZoomButtons = true
      db.hideNorthTag = true
    end

    -- Keep policy strict even if old SavedVariables manually override it.
    db.hideBlizzardArt = true
    db.hideZoomButtons = true
    db.hideNorthTag = true
	end
function ns:ResetDB(reload)
  -- Hard reset saved variables to addon defaults.
  -- If reload==true, ReloadUI() is called (recommended to guarantee a clean state).
  _G.RothMinimapDB = nil
  initDB()
  self.db = _G.RothMinimapDB
  self:ApplyAll("reset")
  if reload then
    ReloadUI()
  end
end

-- -----------------------------------------------------------------------------
-- Media paths
-- -----------------------------------------------------------------------------

ns.media = "Interface\\AddOns\\RothMinimap\\media\\"

-- -----------------------------------------------------------------------------
-- Event bus (modules can register handlers without clobbering each other)
-- -----------------------------------------------------------------------------

do
  local bus = CreateFrame("Frame")
  local handlers = {}

  bus:SetScript("OnEvent", function(_, event, ...)
    local t = handlers[event]
    if not t then return end
    for fn in pairs(t) do
      local ok, err = pcall(fn, event, ...)
      if not ok and ns.db and ns.db.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555RothMinimap error:|r " .. tostring(err))
      end
    end
  end)

  function ns.RegisterEvent(event, fn)
    if type(event) ~= "string" or type(fn) ~= "function" then return end
    if not handlers[event] then
      handlers[event] = {}
      local ok = pcall(bus.RegisterEvent, bus, event)
      if not ok then
        handlers[event] = nil
        if ns.db and ns.db.debug then
          DEFAULT_CHAT_FRAME:AddMessage("|cffff5555RothMinimap:|r skipped unknown event " .. tostring(event))
        end
        return
      end
    end
    handlers[event][fn] = true
  end

  function ns.UnregisterEvent(event, fn)
    if type(event) ~= "string" or type(fn) ~= "function" then return end
    local t = handlers[event]
    if not t then return end
    t[fn] = nil
    if not next(t) then
      handlers[event] = nil
      pcall(bus.UnregisterEvent, bus, event)
    end
  end

  ns._bus = bus
end

-- -----------------------------------------------------------------------------
-- Snapshot / Restore (so toggling 'Enabled' is reversible without reload)
-- -----------------------------------------------------------------------------

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local original = {
  done = false,
  minimapMask = nil,
  minimapW = nil,
  minimapH = nil,
  clusterScale = nil,
  clusterPoint = nil,
  hiddenFrames = {}, -- [frame] = { parent, points, shown }
}


-- Snapshot + restore points for frames we reposition (zone text, instance difficulty, etc.)
local function snapshotFramePoints(key, frame)
  if not key or original[key] or not frame or not frame.GetNumPoints then return end
  local meta = {
    parent = frame.GetParent and frame:GetParent() or UIParent,
    shown = frame.IsShown and frame:IsShown() or true,
    points = {},
  }
  local n = frame.GetNumPoints and frame:GetNumPoints() or 0
  for i = 1, n do
    local p, rel, rp, x, y = frame:GetPoint(i)
    meta.points[i] = { p, rel, rp, x, y }
  end
  original[key] = meta
end

local function restoreFramePoints(key, frame)
  local meta = key and original[key]
  if not meta or not frame then return end
  pcall(frame.SetParent, frame, meta.parent or UIParent)
  pcall(frame.ClearAllPoints, frame)
  if meta.points and #meta.points > 0 then
    for i = 1, #meta.points do
      local p = meta.points[i]
      if p and p[1] then
        pcall(frame.SetPoint, frame, p[1], p[2], p[3], p[4], p[5])
      end
    end
  end
  if meta.shown then
    pcall(frame.Show, frame)
  else
    pcall(frame.Hide, frame)
  end
end

local function restoreFramePlacement(key, frame)
  local meta = key and original[key]
  if not meta or not frame then return end

  pcall(frame.SetParent, frame, meta.parent or UIParent)
  pcall(frame.ClearAllPoints, frame)
  if meta.points and #meta.points > 0 then
    for i = 1, #meta.points do
      local p = meta.points[i]
      if p and p[1] then
        pcall(frame.SetPoint, frame, p[1], p[2], p[3], p[4], p[5])
      end
    end
  end
end
local DEFAULT_MINIMAP_MASK = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"

local function safeGetMinimapMask()
  if not Minimap then return DEFAULT_MINIMAP_MASK end
  if type(Minimap.GetMaskTexture) == "function" then
    local ok, res = pcall(Minimap.GetMaskTexture, Minimap)
    if ok and type(res) == "string" and res ~= "" then
      return res
    end
  end
  -- Retail builds where Minimap:GetMaskTexture() is unavailable: fallback to default.
  return DEFAULT_MINIMAP_MASK
end

local function snapshotOriginal()
  if original.done then return end
  if not Minimap or not MinimapCluster then return end

  original.minimapMask = safeGetMinimapMask()
  original.minimapW, original.minimapH = Minimap:GetSize()
  original.clusterScale = MinimapCluster:GetScale()
  local p, rel, rp, x, y = MinimapCluster:GetPoint(1)
  original.clusterPoint = { p, rel and rel:GetName() or "UIParent", rp, x, y }

  -- Size bounds of MinimapCluster vary across UI modes; snapshot so we can restore.
  original.clusterW, original.clusterH = MinimapCluster:GetSize()

  -- Minimap itself can be re-anchored to remove extra padding in MinimapCluster.
  snapshotFramePoints("minimap", Minimap)

  -- Snapshot default positions for key minimap widgets (we may re-anchor when Blizzard art is hidden).
  local zoneBtn = (MinimapCluster and MinimapCluster.ZoneTextButton) or _G.MinimapZoneTextButton
  snapshotFramePoints("zoneText", zoneBtn)

  -- The "header" container often holds zone text, time and other indicators.
  -- When Blizzard art is hidden, this frame can drift (anchors reference hidden art).
  local header = zoneBtn and zoneBtn.GetParent and zoneBtn:GetParent()
  snapshotFramePoints("headerFrame", header)

  local inst = _G.MiniMapInstanceDifficulty or (MinimapCluster and MinimapCluster.InstanceDifficulty)
  snapshotFramePoints("instanceDifficulty", inst)

  local guild = _G.GuildInstanceDifficulty or _G.MiniMapGuildInstanceDifficulty
  snapshotFramePoints("guildDifficulty", guild)

  local chall = _G.MiniMapChallengeMode
  snapshotFramePoints("challengeMode", chall)

  -- Clock / calendar (optional depending on UI settings).
  snapshotFramePoints("clockButton", _G.TimeManagerClockButton)
  snapshotFramePoints("gameTime", _G.GameTimeFrame)

  -- AddonCompartment can be re-anchored when Blizzard art is hidden.
  local comp = _G.AddonCompartmentFrame
  snapshotFramePoints("addonCompartment", comp)
  snapshotFramePoints("addonCompartmentText", comp and comp.Text)

  original.done = true
end

local function hideFrame(frame, detach)
  if not frame or not frame.GetParent then return end
  if original.hiddenFrames[frame] then
    local meta = original.hiddenFrames[frame]
    if (detach and not meta.detached) or (meta.detached and frame:GetParent() ~= hiddenParent) then
      frame:SetParent(hiddenParent)
      meta.detached = true
    end
    frame:Hide()
    return
  end

  local meta = {
    parent = frame:GetParent(),
    shown = frame:IsShown(),
    detached = detach and true or false,
    points = {},
  }
  for i = 1, frame:GetNumPoints() do
    local p, rel, rp, x, y = frame:GetPoint(i)
    meta.points[i] = { p, rel, rp, x, y }
  end
  original.hiddenFrames[frame] = meta

  if meta.detached then
    frame:SetParent(hiddenParent)
  end
  frame:Hide()
end

local function restoreHiddenFrames()
  for frame, meta in pairs(original.hiddenFrames) do
    if frame and meta then
      frame:SetParent(meta.parent or UIParent)
      frame:ClearAllPoints()
      if meta.points and #meta.points > 0 then
        for i = 1, #meta.points do
          local p = meta.points[i]
          frame:SetPoint(p[1], p[2], p[3], p[4], p[5])
        end
      end
      if meta.shown then frame:Show() else frame:Hide() end
    end
  end
  wipe(original.hiddenFrames)
end

local function restoreHiddenFrame(frame)
  local meta = frame and original.hiddenFrames[frame]
  if not meta or not frame then return end

  frame:SetParent(meta.parent or UIParent)
  frame:ClearAllPoints()
  if meta.points and #meta.points > 0 then
    for i = 1, #meta.points do
      local p = meta.points[i]
      frame:SetPoint(p[1], p[2], p[3], p[4], p[5])
    end
  end
  if meta.shown then frame:Show() else frame:Hide() end
  original.hiddenFrames[frame] = nil
end

-- -----------------------------------------------------------------------------
-- Core apply / disable
-- -----------------------------------------------------------------------------

local pendingApply = false
local pendingCombatLock = false
local lastWidgetsHideArtState = nil
local lastClusterSize = nil
local lastClusterScale = nil
local lastClusterPointSig = nil
local lastClusterHideArtState = nil
local lastClusterBoundW = nil
local lastClusterBoundH = nil

function ns:QueueApply(reason)
  if pendingApply then return end
  pendingApply = true
  C_Timer.After(0.05, function()
    pendingApply = false
    dprint("apply:", reason or "(no reason)")
    ns:ApplyAll()
  end)
end

local function applyClusterLayout()
  local db = ns.db
  if not db or not Minimap or not MinimapCluster then return end

  if InCombatLockdown() then
    pendingCombatLock = true
    return
  end

  local size = clamp(db.size, 120, 420)
  if lastClusterSize ~= size then
    Minimap:SetSize(size, size)
    lastClusterSize = size
  end

  local scale = clamp(db.scale, 0.5, 4.0)
  if lastClusterScale ~= scale then
    MinimapCluster:SetScale(scale)
    lastClusterScale = scale
  end

  local pointSig = table.concat({
    tostring(db.point[1]),
    tostring(db.point[2]),
    tostring(db.point[3]),
    tostring(db.point[4]),
    tostring(db.point[5]),
  }, "|")

  if lastClusterPointSig ~= pointSig then
    MinimapCluster:ClearAllPoints()
    MinimapCluster:SetPoint(db.point[1], _G[db.point[2]] or UIParent, db.point[3], db.point[4], db.point[5])
    lastClusterPointSig = pointSig
  end


  -- Tighten MinimapCluster bounds when Blizzard art is hidden.
  -- This removes the empty top padding visible in frame movers and keeps the minimap
  -- aligned to the cluster's top edge.
  if db.hideBlizzardArt then
    local wantW, wantH = Minimap:GetWidth(), Minimap:GetHeight()
    if lastClusterHideArtState ~= true or lastClusterBoundW ~= wantW or lastClusterBoundH ~= wantH then
      pcall(MinimapCluster.SetSize, MinimapCluster, wantW, wantH)
      Minimap:ClearAllPoints()
      Minimap:SetPoint("CENTER", MinimapCluster, "CENTER", 0, 0)
      lastClusterBoundW, lastClusterBoundH = wantW, wantH
    end
  else
    -- Restore default anchoring when Blizzard art is used.
    if lastClusterHideArtState ~= false then
      restoreFramePoints("minimap", Minimap)
      if original.clusterW and original.clusterH then
        pcall(MinimapCluster.SetSize, MinimapCluster, original.clusterW, original.clusterH)
      end
    end
  end

  lastClusterHideArtState = db.hideBlizzardArt and true or false

end

local function applyShape()
  local db = ns.db
  if not db or not Minimap then return end

  if db.square then
    Minimap:SetMaskTexture(ns.media .. "mask_square.tga")
    -- Helper for addons that consult GetMinimapShape().
    if _G.GetMinimapShape ~= nil then
      _G.GetMinimapShape = function()
        return "SQUARE"
      end
    end
  else
    if original.minimapMask then
      Minimap:SetMaskTexture(original.minimapMask or DEFAULT_MINIMAP_MASK)
    end
    if _origGetMinimapShape then
      _G.GetMinimapShape = _origGetMinimapShape
    end
  end
end

local function applyHideArt()
  local db = ns.db
  if not db then return end

  if not db.hideBlizzardArt then
    restoreHiddenFrames()
    return
  end

  hideFrame(_G.MinimapBorder)
  hideFrame(_G.MinimapBorderTop)

  -- On modern builds there is also a backdrop ring/frame that can remain visible.
  hideFrame(_G.MinimapBackdrop)
  hideFrame(_G.MinimapBackdrop and _G.MinimapBackdrop.Background)
  hideFrame(_G.MinimapBackdrop and _G.MinimapBackdrop.NineSlice)
  hideFrame(_G.MinimapBackdrop and _G.MinimapBackdrop.Blackout)

  -- Some builds show an additional compass/border ring. Hide it when Blizzard art is disabled.
  hideFrame(_G.MinimapCompassTexture)
  hideFrame(_G.MinimapCompassFrame)
  if MinimapCluster then
    hideFrame(MinimapCluster.BorderTop)
    hideFrame(MinimapCluster.CompassFrame)
  end

  if db.hideZoomButtons then
    hideFrame(_G.MinimapZoomIn)
    hideFrame(_G.MinimapZoomOut)
  end

  if db.hideNorthTag then
    hideFrame(_G.MinimapNorthTag)
  end
end




local function applyAddonCompartment()
  local db = ns.db
  if not db then return end
  local f = _G.AddonCompartmentFrame
  if not f then return end

  if db.hideAddonCompartment then
    -- Detach when hidden so it cannot affect MinimapCluster bounds in EditMode.
    hideFrame(f, true)
    if f.Text then hideFrame(f.Text, true) end
  else
    -- If it was detached previously, bring it back before re-anchoring.
    restoreHiddenFrame(f)
    if f.Text then restoreHiddenFrame(f.Text) end

    -- If Blizzard art is hidden, keep it anchored to the actual Minimap so it does not bloat MinimapCluster bounds.
    if db.hideBlizzardArt and not InCombatLockdown() then
      pcall(f.SetParent, f, Minimap)
      pcall(f.ClearAllPoints, f)
      pcall(f.SetPoint, f, "TOPRIGHT", Minimap, "TOPRIGHT", -2, -2)
    elseif not InCombatLockdown() then
      -- Restore original placement when Blizzard art is visible.
      restoreFramePlacement("addonCompartment", f)
      if f.Text then
        restoreFramePlacement("addonCompartmentText", f.Text)
      end
    end
  end
end
local function applyMinimapWidgetsLayout()
  local db = ns.db
  if not db or not Minimap then return end

  if InCombatLockdown() then
    -- Avoid point changes during combat just in case some widgets are protected on certain builds.
    pendingCombatLock = true
    return
  end

  local hideArt = db.hideBlizzardArt and true or false
  if lastWidgetsHideArtState == hideArt then
    return
  end
  lastWidgetsHideArtState = hideArt

  -- Keep Blizzard's own minimap anchor graph intact.
  -- Repeated re-parent/re-anchor here causes visible "jumping" when MinimapCluster updates.
  local zoneBtn = (MinimapCluster and MinimapCluster.ZoneTextButton) or _G.MinimapZoneTextButton
  local clock = _G.TimeManagerClockButton
  if not clock and MinimapCluster and MinimapCluster.IndicatorFrame then
    clock = MinimapCluster.IndicatorFrame.TimeManagerClockButton
  end
  local gameTime = _G.GameTimeFrame
  if not gameTime and MinimapCluster and MinimapCluster.IndicatorFrame then
    gameTime = MinimapCluster.IndicatorFrame.GameTimeFrame
  end
  local inst = _G.MiniMapInstanceDifficulty or (MinimapCluster and MinimapCluster.InstanceDifficulty)
  local guild = _G.GuildInstanceDifficulty or _G.MiniMapGuildInstanceDifficulty
  local chall = _G.MiniMapChallengeMode

  local function normalize(frame, key)
    if not frame or not frame.ClearAllPoints then return end
    snapshotFramePoints(key, frame)
    
    if key == "zoneText" and hideArt then
      frame:ClearAllPoints()
      frame:SetPoint("BOTTOM", Minimap, "TOP", 0, 10)
    else
      restoreFramePlacement(key, frame)
    end
    
    if frame.SetClampedToScreen then
      pcall(frame.SetClampedToScreen, frame, true)
    end
  end

  normalize(zoneBtn, "zoneText")
  normalize(clock, "clockButton")
  normalize(gameTime, "gameTime")
  normalize(inst, "instanceDifficulty")
  normalize(guild, "guildDifficulty")
  normalize(chall, "challengeMode")
end
function ns:DisableAll()
  lastWidgetsHideArtState = nil
  lastClusterSize = nil
  lastClusterScale = nil
  lastClusterPointSig = nil
  lastClusterHideArtState = nil
  lastClusterBoundW = nil
  lastClusterBoundH = nil

  -- Restore original Blizzard minimap state.
  restoreHiddenFrames()

  -- Restore widget anchors that we might have re-positioned.
  restoreFramePoints("zoneText", (MinimapCluster and MinimapCluster.ZoneTextButton) or _G.MinimapZoneTextButton)
  restoreFramePoints("instanceDifficulty", _G.MiniMapInstanceDifficulty or (MinimapCluster and MinimapCluster.InstanceDifficulty))
  restoreFramePoints("guildDifficulty", _G.GuildInstanceDifficulty or _G.MiniMapGuildInstanceDifficulty)
  restoreFramePoints("challengeMode", _G.MiniMapChallengeMode)
  local _c = _G.TimeManagerClockButton
  if not _c and MinimapCluster and MinimapCluster.IndicatorFrame then _c = MinimapCluster.IndicatorFrame.TimeManagerClockButton end
  restoreFramePoints("clockButton", _c)

  local _gt = _G.GameTimeFrame
  if not _gt and MinimapCluster and MinimapCluster.IndicatorFrame then _gt = MinimapCluster.IndicatorFrame.GameTimeFrame end
  restoreFramePoints("gameTime", _gt)

  local _ac = _G.AddonCompartmentFrame
  restoreFramePlacement("addonCompartment", _ac)
  if _ac and _ac.Text then
    restoreFramePlacement("addonCompartmentText", _ac.Text)
  end

  if original.minimapMask and Minimap then
    Minimap:SetMaskTexture(original.minimapMask or DEFAULT_MINIMAP_MASK)
  end
  if _origGetMinimapShape then
    _G.GetMinimapShape = _origGetMinimapShape
  end
  if original.minimapW and original.minimapH and Minimap then
    Minimap:SetSize(original.minimapW, original.minimapH)
    -- Restore MinimapCluster bounds and original Minimap anchors (EditMode highlight + layout sanity).
    if original.clusterW and original.clusterH then
      MinimapCluster:SetSize(original.clusterW, original.clusterH)
    end
    restoreFramePoints("minimap", Minimap)
  end
  if original.clusterScale and MinimapCluster then
    MinimapCluster:SetScale(original.clusterScale)
  end
  if original.clusterPoint and MinimapCluster then
    MinimapCluster:ClearAllPoints()
    MinimapCluster:SetPoint(original.clusterPoint[1], _G[original.clusterPoint[2]] or UIParent, original.clusterPoint[3], original.clusterPoint[4], original.clusterPoint[5])
  end


  -- Tell modules to stop / hide (isolated).
  ns.util.safeMethod(ns.skin, 'Disable')
  ns.util.safeMethod(ns.ping, 'Disable')
  ns.util.safeMethod(ns.zoom, 'Disable')
  ns.util.safeMethod(ns.buttons, 'Disable')
end

function ns:ApplyAll()
  if not ns.db then return end
  if not ns.db.enabled then
    ns:DisableAll()
    return
  end

  ns.util.safeCall(applyHideArt)
  ns.util.safeCall(applyAddonCompartment)
  ns.util.safeCall(applyClusterLayout)
  ns.util.safeCall(applyShape)
  ns.util.safeCall(applyMinimapWidgetsLayout)


  ns.util.safeMethod(ns.skin, 'Apply')
  ns.util.safeMethod(ns.ping, 'Apply')
  ns.util.safeMethod(ns.zoom, 'Apply')
  ns.util.safeMethod(ns.buttons, 'Apply')
  ns.util.safeMethod(ns.compartment, 'Apply')
end

-- -----------------------------------------------------------------------------
-- Mover (Alt-drag)
-- -----------------------------------------------------------------------------

local mover

local function ensureMover()
  if mover then return mover end

  mover = CreateFrame("Frame", "RothMinimapMover", Minimap)
  mover:SetAllPoints(Minimap)
  mover:SetFrameStrata("HIGH")
  mover:EnableMouse(true)
  mover:RegisterForDrag("LeftButton")
  mover:SetClampedToScreen(true)
  mover:Hide()

  local label = mover:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("TOP", mover, "TOP", 0, -6)
  label:SetText("Roth Minimap: drag (Alt)")

  mover:SetScript("OnDragStart", function()
    if InCombatLockdown() then return end
    if ns.db.mover.requireAlt and not IsAltKeyDown() then return end
    MinimapCluster:SetMovable(true)
    MinimapCluster:SetClampedToScreen(true)
    MinimapCluster:StartMoving()
  end)

  mover:SetScript("OnDragStop", function()
    MinimapCluster:StopMovingOrSizing()
    local p, rel, rp, x, y = MinimapCluster:GetPoint(1)
    if p and rp then
      ns.db.point = { p, rel and rel:GetName() or "UIParent", rp, x, y }
    end
  end)

  return mover
end

function ns:SetMoverEnabled(enabled)
  ns.db.mover.enabled = not not enabled
  local m = ensureMover()
  if ns.db.mover.enabled and ns.db.enabled then
    m:Show()
  else
    m:Hide()
  end
end

-- -----------------------------------------------------------------------------
-- QuickMap (shift-click minimap to open zone map)
-- -----------------------------------------------------------------------------

local _quickMapHooked = false

local function _isModDown(mod)
  if mod == "SHIFT" then return IsShiftKeyDown() end
  if mod == "CTRL" then return IsControlKeyDown() end
  if mod == "ALT" then return IsAltKeyDown() end
  return false
end

local function setupQuickMap()
  if _quickMapHooked or not Minimap then return end
  _quickMapHooked = true

  Minimap:HookScript("OnMouseDown", function(_, button)
    local q = ns.db and ns.db.quickMap
    if not (q and q.enabled) then return end
    if q.button and button ~= q.button then return end
    local mod = q.modifier or "SHIFT"
    if not _isModDown(mod) then return end

    -- WoW minimap cannot be panned like a free camera. Best lightweight substitute:
    -- open the World Map quickly for zone overview (dragging works there).
    if type(ToggleWorldMap) == "function" then
      ToggleWorldMap()
    elseif _G.WorldMapFrame then
      _G.WorldMapFrame:Show()
    end
  end)
end

-- -----------------------------------------------------------------------------
-- Slash commands / Addon compartment
-- -----------------------------------------------------------------------------

local function openOptions()
  if ns.options and ns.options.Open then
    ns.options:Open()
    return
  end

  -- Fallback: open the general Settings window.
  if Settings and Settings.OpenToCategory then
    Settings.OpenToCategory("AddOns")
  elseif InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(ADDON)
  end
end

function _G.RothMinimap_OpenConfig()
  openOptions()
end

SLASH_ROTHMINIMAP1 = "/rmmap"
SLASH_ROTHMINIMAP2 = "/rothminimap"
SLASH_ROTHMINIMAP3 = "/rm"
SlashCmdList.ROTHMINIMAP = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "unlock" then
    ns:SetMoverEnabled(true)
    print("Roth Minimap: mover enabled (Alt-drag).")
  elseif msg == "lock" then
    ns:SetMoverEnabled(false)
    print("Roth Minimap: mover disabled.")
  elseif msg == "scan" then
    if ns.buttons and ns.buttons.Rescan then ns.buttons:Rescan(true) end
  elseif msg == "compartment" or msg == "comp" then
    if ns.compartment and ns.compartment.Dump then ns.compartment:Dump("slash") end
  elseif msg == "reset" then
    ns:ResetDB(true)
  else
    openOptions()
  end
end

-- -----------------------------------------------------------------------------
-- Boot
-- -----------------------------------------------------------------------------

local ev = CreateFrame("Frame")

ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")

ev:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    initDB()
    snapshotOriginal()
    setupQuickMap()

    -- Register Settings panel (deferred one frame inside :Init).
    if ns.options and ns.options.Init then ns.options:Init() end

    -- Apply once after the UI has finished assembling.
    C_Timer.After(0, function()
      ns:ApplyAll()
      if ns.db.mover.enabled then ns:SetMoverEnabled(true) end
    end)

  elseif event == "PLAYER_ENTERING_WORLD" then
    snapshotOriginal()
    setupQuickMap()
    -- Some minimap pieces spawn after login; apply again.
    ns:QueueApply("enter_world")

  elseif event == "PLAYER_REGEN_DISABLED" then
    if ns.skin and ns.skin.SetCombat then ns.skin:SetCombat(true) end
    if ns.buttons and ns.buttons.OnCombatChanged then ns.buttons:OnCombatChanged(true) end

  elseif event == "PLAYER_REGEN_ENABLED" then
    if ns.skin and ns.skin.SetCombat then ns.skin:SetCombat(false) end
    if ns.buttons and ns.buttons.OnCombatChanged then ns.buttons:OnCombatChanged(false) end

    if pendingCombatLock then
      pendingCombatLock = false
      ns:QueueApply("combat_end")
    end
  end
end)
