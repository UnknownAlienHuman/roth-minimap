-- RothMinimap - Minimap Button Bag
--
-- Design goals:
--   * MBB-style behavior: show real addon buttons inside the bag panel.
--   * Keep guarded access to foreign frames (forbidden/protected-safe).
--   * Preserve original parent/anchors and restore cleanly on close/disable.

local ADDON, ns = ...

ns.buttons = ns.buttons or {}
local M = ns.buttons

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

local BUTTON_SIZE = 28
local GRID_COLS = 6
local GRID_PAD = 3
local HEADER_H = 22
local FRAME_PAD = 8

local SCAN_THROTTLE = 1.0
local ROOT_SCAN_MAX_DEPTH = 6
local OPEN_SCAN_INTERVAL = 2.0

local BAG_TOGGLE_ICON = "Interface\\Icons\\INV_Misc_Bag_10"

---------------------------------------------------------------------------
-- Ignore list
---------------------------------------------------------------------------

local IGNORE_NAMES = {
  Minimap = true,
  MinimapCluster = true,
  MinimapBackdrop = true,
  MinimapBorder = true,
  MinimapBorderTop = true,
  MinimapNorthTag = true,
  MinimapZoomIn = true,
  MinimapZoomOut = true,
  MinimapZoneTextButton = true,
  TimeManagerClockButton = true,
  GameTimeFrame = true,
  MiniMapTracking = true,
  MiniMapTrackingButton = true,
  MiniMapTrackingFrame = true,
  MiniMapMailFrame = true,
  QueueStatusMinimapButton = true,
  QueueStatusButton = true,
  MiniMapLFGFrame = true,
  MiniMapWorldMapButton = true,
  MiniMapBattlefieldFrame = true,
  MiniMapInstanceDifficulty = true,
  GuildInstanceDifficulty = true,
  MiniMapChallengeMode = true,
  ExpansionLandingPageMinimapButton = true,
  GarrisonLandingPageMinimapButton = true,
  GarrisonMinimapButton = true,
  AddonCompartmentFrame = true,
  MiniMapVoiceChatFrame = true,
  MiniMapRecordingButton = true,
  MiniMapPing = true,
  MinimapCompassFrame = true,
  -- RothMinimap
  RothMinimapBagFrame = true,
  RothMinimapBagButton = true,
  RothMinimapSkinFrame = true,
  RothMinimapMover = true,
}

local IGNORE_PATTERNS = {
  "^HandyNotes",
  "^GatherMatePin",
  "^GatherNote",
  "^GatherArchNote",
  "^QuestPointerPOI",
  "^poiMinimap",
  "^DugisArrow",
  "^ZGVMarker",
  "^GPSArrow",
  "^TTMinimapButton",
}

local function isIgnoredName(name)
  if not name or name == "" then return true end
  if IGNORE_NAMES[name] then return true end
  for i = 1, #IGNORE_PATTERNS do
    if name:find(IGNORE_PATTERNS[i]) then
      return true
    end
  end
  return false
end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------

local bagButton
local bagFrame
local isOpen = false

local collected = {}
local sortedInfos = {}
local sortedDirty = true

-- Hide/show hook suppression (weak-key table)
local suppressHooks = setmetatable({}, { __mode = "k" })

local lastScanTime = 0
local lastGlobalFallbackScan = 0

local autoCloseToken = 0
local openTicker

-- Exclusion caches
local excludeSignature
local excludeExactSet = {}
local excludeSubstringList = {}

-- Lifecycle / scan scratch
local lifecycleFrame
local lifecycleRescanQueued = false
local scanStackFrames = {}
local scanStackDepths = {}
local scanVisited = {}

---------------------------------------------------------------------------
-- DB helpers
---------------------------------------------------------------------------

local function getButtonsDB()
  local root = ns.db
  if type(root) ~= "table" then return {} end
  if type(root.buttons) ~= "table" then
    root.buttons = {}
  end
  return root.buttons
end

local function clamp(v, lo, hi)
  v = tonumber(v) or 0
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

---------------------------------------------------------------------------
-- Safe foreign-frame access helpers
---------------------------------------------------------------------------

local function safeGetName(frame)
  local ok, name = pcall(function() return frame:GetName() end)
  if ok then return name end
end

local function safeGetObjectType(frame)
  local ok, objType = pcall(function() return frame:GetObjectType() end)
  if ok then return objType end
end

local function safeIsShown(frame)
  local ok, shown = pcall(function() return frame:IsShown() end)
  if ok then return shown end
end

local function safeIsForbidden(frame)
  local ok, forbidden = pcall(function()
    return frame.IsForbidden and frame:IsForbidden()
  end)
  if not ok then
    return true
  end
  return forbidden and true or false
end

local function safeIsProtected(frame)
  local ok, protected = pcall(function()
    return frame:IsProtected()
  end)
  if not ok then
    return true
  end
  return protected and true or false
end

local function safeGetSize(frame)
  local ok, w, h = pcall(function()
    return frame:GetWidth(), frame:GetHeight()
  end)
  if ok then
    return w, h
  end
end

local function safeGetCenter(frame)
  local ok, x, y = pcall(function()
    return frame:GetCenter()
  end)
  if ok then
    return x, y
  end
end

local function safeGetParent(frame)
  local ok, parent = pcall(function() return frame:GetParent() end)
  if ok then return parent end
end

local function safeGetScale(frame)
  local ok, scale = pcall(function() return frame:GetScale() end)
  if ok then return scale end
end

local function safeGetFrameStrata(frame)
  local ok, strata = pcall(function() return frame:GetFrameStrata() end)
  if ok then return strata end
end

local function safeGetFrameLevel(frame)
  local ok, level = pcall(function() return frame:GetFrameLevel() end)
  if ok then return level end
end

local function safeGetPoints(frame)
  local points = {}
  local okCount, numPoints = pcall(function() return frame:GetNumPoints() end)
  if not okCount or type(numPoints) ~= "number" then
    return points
  end

  for i = 1, numPoints do
    local okPoint, point, rel, relPoint, x, y = pcall(function()
      return frame:GetPoint(i)
    end)
    if okPoint and point then
      points[#points + 1] = { point, rel, relPoint, x, y }
    end
  end
  return points
end

local function safeGetChildren(parent)
  local ok, kids = pcall(function() return { parent:GetChildren() } end)
  if ok and type(kids) == "table" then
    return kids
  end
  return nil
end

local function safeHasLiveScript(frame, scriptName)
  local ok, has, fn = pcall(function()
    if not frame:HasScript(scriptName) then
      return false, nil
    end
    return true, frame:GetScript(scriptName)
  end)
  if ok and has and type(fn) == "function" then
    return true, fn
  end
  return false, nil
end

local function withSuppressedHook(frame, callback)
  suppressHooks[frame] = true
  local ok = pcall(callback)
  suppressHooks[frame] = nil
  return ok
end

local function hideNative(frame)
  if not frame then return end
  if InCombatLockdown() and safeIsProtected(frame) then return end
  withSuppressedHook(frame, function()
    pcall(function() frame:Hide() end)
  end)
end

local function showNative(frame)
  if not frame then return end
  if InCombatLockdown() and safeIsProtected(frame) then return end
  withSuppressedHook(frame, function()
    pcall(function() frame:Show() end)
  end)
end

---------------------------------------------------------------------------
-- Exclusion cache
---------------------------------------------------------------------------

local function refreshExcludeCache()
  local db = getButtonsDB()
  local exact = tostring(db.excludeExact or "")
  local subs = tostring(db.excludeSubstrings or db.exclude or "")
  local sig = exact .. "\31" .. subs
  if excludeSignature == sig then
    return
  end

  wipe(excludeExactSet)
  wipe(excludeSubstringList)

  for token in exact:gmatch("[^,%s]+") do
    excludeExactSet[token:lower()] = true
  end

  for token in subs:gmatch("[^,%s]+") do
    excludeSubstringList[#excludeSubstringList + 1] = token:lower()
  end

  excludeSignature = sig
end

local function isUserExcluded(name)
  if not name then return false end
  refreshExcludeCache()

  local lower = name:lower()
  if excludeExactSet[lower] then
    return true
  end

  for i = 1, #excludeSubstringList do
    if lower:find(excludeSubstringList[i], 1, true) then
      return true
    end
  end

  return false
end

local function writeExcludeExactCacheToDB()
  local keys = {}
  for token in pairs(excludeExactSet) do
    keys[#keys + 1] = token
  end
  table.sort(keys)

  local db = getButtonsDB()
  db.excludeExact = table.concat(keys, ",")
  excludeSignature = nil
end

local function toggleExactExclusion(name)
  if not name or name == "" then return end
  refreshExcludeCache()
  local key = name:lower()
  if excludeExactSet[key] then
    excludeExactSet[key] = nil
  else
    excludeExactSet[key] = true
  end
  writeExcludeExactCacheToDB()
end

---------------------------------------------------------------------------
-- Collection / sorting
---------------------------------------------------------------------------

-- collected[frame] = {
--   frame = frame,
--   name = "FrameName",
--   sortKey = "framename",
--   origW = 31,
--   origH = 31,
--   wantsShown = true/false,
--   hooksInstalled = true/false,
--   original = { parent, points, w, h, scale, strata, level },
--   inBag = true/false,
--   anchorLock = true/false,
-- }

local function markSortedDirty()
  sortedDirty = true
end

local function rebuildSortedIfNeeded()
  if not sortedDirty then return end
  wipe(sortedInfos)
  for _, info in pairs(collected) do
    if info and info.name then
      sortedInfos[#sortedInfos + 1] = info
    end
  end
  table.sort(sortedInfos, function(a, b)
    return (a.sortKey or a.name) < (b.sortKey or b.name)
  end)
  sortedDirty = false
end

local function shouldHideOriginals()
  local db = getButtonsDB()
  if db.bag == false then
    return false
  end
  -- If toggle is hidden and bag is closed, keep originals visible so the user
  -- never loses access to minimap buttons.
  if db.showToggle == false and not isOpen then
    return false
  end
  if isOpen then
    return true
  end
  return db.stashWhenClosed ~= false
end

local function canModifyFrame(frame)
  if not frame then return false end
  if safeIsForbidden(frame) then return false end
  if InCombatLockdown() and safeIsProtected(frame) then return false end
  return true
end

local function unlockFrameAnchors(info)
  if not info or not info.anchorLock then return end
  local frame = info.frame
  if not frame then
    info.anchorLock = false
    info.savedSetPoint = nil
    info.savedClearAllPoints = nil
    return
  end

  pcall(function()
    if type(info.savedSetPoint) == "function" then
      frame.SetPoint = info.savedSetPoint
    end
    if type(info.savedClearAllPoints) == "function" then
      frame.ClearAllPoints = info.savedClearAllPoints
    end
  end)

  info.anchorLock = false
  info.savedSetPoint = nil
  info.savedClearAllPoints = nil
end

local function lockFrameAnchors(info)
  if not info or info.anchorLock then return end
  local frame = info.frame
  if not frame then return end

  local setPoint = frame.SetPoint
  local clearAllPoints = frame.ClearAllPoints
  if type(setPoint) ~= "function" or type(clearAllPoints) ~= "function" then
    return
  end

  local ok = pcall(function()
    info.savedSetPoint = setPoint
    info.savedClearAllPoints = clearAllPoints
    frame.SetPoint = function() end
    frame.ClearAllPoints = function() end
  end)
  if ok then
    info.anchorLock = true
  end
end

local function snapshotOriginalPlacement(info)
  if not info or not info.frame then return false end
  if info.original then return true end

  local frame = info.frame
  local w, h = safeGetSize(frame)
  local scale = safeGetScale(frame)
  local strata = safeGetFrameStrata(frame)
  local level = safeGetFrameLevel(frame)

  info.original = {
    parent = safeGetParent(frame),
    points = safeGetPoints(frame),
    w = tonumber(w) or tonumber(info.origW) or 31,
    h = tonumber(h) or tonumber(info.origH) or 31,
    scale = tonumber(scale) or 1,
    strata = strata,
    level = tonumber(level),
    fixedStrata = frame.GetFixedFrameStrata and frame:GetFixedFrameStrata(),
    fixedLevel = frame.GetFixedFrameLevel and frame:GetFixedFrameLevel(),
    scripts = {
      OnDragStart = frame:GetScript("OnDragStart"),
      OnDragStop = frame:GetScript("OnDragStop"),
    },
  }

  return true
end

local function restoreButtonPlacement(info)
  if not info or not info.frame then return false end
  local frame = info.frame
  if not canModifyFrame(frame) then return false end

  unlockFrameAnchors(info)

  local original = info.original
  if original then
    pcall(frame.SetParent, frame, original.parent or Minimap or UIParent)
    pcall(frame.ClearAllPoints, frame)
    if type(original.points) == "table" and #original.points > 0 then
      for i = 1, #original.points do
        local point = original.points[i]
        if point and point[1] then
          pcall(frame.SetPoint, frame, point[1], point[2], point[3], point[4], point[5])
        end
      end
    end

    if original.w and original.h then
      pcall(frame.SetSize, frame, original.w, original.h)
    end
    if original.scale and original.scale > 0 then
      pcall(frame.SetScale, frame, original.scale)
    end
    if type(original.strata) == "string" and original.strata ~= "" then
      pcall(frame.SetFrameStrata, frame, original.strata)
    end
    if original.level then
      pcall(frame.SetFrameLevel, frame, original.level)
    end
    if original.fixedStrata ~= nil and frame.SetFixedFrameStrata then
      pcall(frame.SetFixedFrameStrata, frame, original.fixedStrata)
    end
    if original.fixedLevel ~= nil and frame.SetFixedFrameLevel then
      pcall(frame.SetFixedFrameLevel, frame, original.fixedLevel)
    end
    if original.scripts then
      if original.scripts.OnDragStart then frame:SetScript("OnDragStart", original.scripts.OnDragStart) end
      if original.scripts.OnDragStop then frame:SetScript("OnDragStop", original.scripts.OnDragStop) end
    end
  end

  info.inBag = false
  return true
end

local function placeButtonInBag(info, index, size, cols)
  if not info or not info.frame then return false end
  if not bagFrame or not bagFrame.content then return false end

  local frame = info.frame
  if not canModifyFrame(frame) then return false end
  if not snapshotOriginalPlacement(info) then return false end

  unlockFrameAnchors(info)

  local row = math.floor((index - 1) / cols)
  local col = (index - 1) % cols

  local ok = pcall(function()
    if frame.SetFixedFrameStrata then frame:SetFixedFrameStrata(false) end
    if frame.SetFixedFrameLevel then frame:SetFixedFrameLevel(false) end
    frame:SetScript("OnDragStart", nil)
    frame:SetScript("OnDragStop", nil)
    frame:SetParent(bagFrame.content)
    frame:ClearAllPoints()
    frame:SetPoint(
      "TOPLEFT",
      bagFrame.content,
      "TOPLEFT",
      col * (size + GRID_PAD),
      -(row * (size + GRID_PAD))
    )
    frame:SetScale(1)
    frame:SetSize(size, size)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel((bagFrame:GetFrameLevel() or 100) + 10 + index)
    -- Enforce interaction
    if frame.EnableMouse then frame:EnableMouse(true) end
    if frame.RegisterForClicks then frame:RegisterForClicks("AnyUp") end
    if frame.SetHitRectInsets then frame:SetHitRectInsets(0, 0, 0, 0) end
  end)
  if not ok then
    restoreButtonPlacement(info)
    return false
  end

  lockFrameAnchors(info)
  info.inBag = true
  showNative(frame)
  return true
end

local function restoreAllButtonsToOriginal()
  for _, info in pairs(collected) do
    if info.inBag or info.anchorLock then
      restoreButtonPlacement(info)
    end
  end
end

local function applyNativeVisibility(info)
  local frame = info and info.frame
  if not frame then return end

  if isOpen then
    return
  end

  if info.inBag or info.anchorLock then
    restoreButtonPlacement(info)
  end

  if shouldHideOriginals() then
    hideNative(frame)
  elseif info.wantsShown == false then
    hideNative(frame)
  else
    showNative(frame)
  end
end

local function applyNativeVisibilityAll()
  for _, info in pairs(collected) do
    applyNativeVisibility(info)
  end
end

local function restoreNativeVisibilityAll()
  for _, info in pairs(collected) do
    restoreButtonPlacement(info)
    if info.wantsShown == false then
      hideNative(info.frame)
    else
      showNative(info.frame)
    end
  end
end

local function dropCollected(frame)
  local info = collected[frame]
  if not info then return end
  restoreButtonPlacement(info)
  unlockFrameAnchors(info)
  collected[frame] = nil
  markSortedDirty()
end

---------------------------------------------------------------------------
-- Shared helpers
---------------------------------------------------------------------------

local scheduleAutoClose

local GLOBAL_CANDIDATE_PATTERNS = {
  '^LibDBIcon10_',
  'MinimapButton',
  'MiniMapButton',
  'MinimapIcon',
  'MiniMapIcon',
  'LDBIcon',
  'Broker',
  'Launcher',
}

---------------------------------------------------------------------------
-- Collection hooks
---------------------------------------------------------------------------

local function countDisplayableButtons()
  local count = 0
  for _, info in pairs(collected) do
    if info.name and not isUserExcluded(info.name) and info.wantsShown ~= false then
      count = count + 1
    end
  end
  return count
end

local function updateBagButtonBadge()
  if not bagButton then return end
  if not bagButton.countText then return end

  local count = countDisplayableButtons()
  if count > 0 then
    bagButton.countText:SetText(count > 99 and "99+" or tostring(count))
    bagButton.countText:Show()
  else
    bagButton.countText:Hide()
  end
end

local function installVisibilityHooks(info)
  if not info or info.hooksInstalled then return end
  if type(hooksecurefunc) ~= "function" then return end

  local frame = info.frame
  if not frame then return end

  local function onShown(self)
    local data = collected[self]
    if not data then return end
    if suppressHooks[self] then return end
    data.wantsShown = true
    if not isOpen and shouldHideOriginals() then
      hideNative(self)
    end
    if isOpen then
      M:Layout()
    else
      updateBagButtonBadge()
    end
  end

  local function onHidden(self)
    local data = collected[self]
    if not data then return end
    if suppressHooks[self] then return end
    data.wantsShown = false
    if isOpen then
      M:Layout()
    else
      updateBagButtonBadge()
    end
  end

  local okShow = pcall(hooksecurefunc, frame, "Show", onShown)
  local okHide = pcall(hooksecurefunc, frame, "Hide", onHidden)
  info.hooksInstalled = okShow and okHide

  if type(frame.HookScript) == "function" then
    pcall(frame.HookScript, frame, "OnMouseUp", function(self, mouseButton)
      local data = collected[self]
      if not data or not data.inBag or not isOpen then return end
      if mouseButton ~= "RightButton" or not IsControlKeyDown() then return end

      toggleExactExclusion(data.name)
      C_Timer.After(0, function()
        if InCombatLockdown() then
          M._pendingCombatRescan = true
          return
        end
        M:Rescan(true)
        if isOpen then
          M:Layout()
        end
      end)
    end)

    pcall(frame.HookScript, frame, "OnEnter", function(self)
      local data = collected[self]
      if not data or not data.inBag then return end
      autoCloseToken = autoCloseToken + 1
    end)

    pcall(frame.HookScript, frame, "OnLeave", function(self)
      local data = collected[self]
      if not data or not data.inBag then return end
      if scheduleAutoClose then
        scheduleAutoClose()
      end
    end)
  end
end

local function collectButton(frame, name, w, h)
  if not frame or not name then return 0 end

  local existing = collected[frame]
  if existing then
    existing.name = name
    existing.sortKey = name:lower()
    if type(w) == "number" and w > 0 then existing.origW = w end
    if type(h) == "number" and h > 0 then existing.origH = h end
    if not existing.original then
      snapshotOriginalPlacement(existing)
    end
    return 0
  end

  local shown = safeIsShown(frame)
  local info = {
    frame = frame,
    name = name,
    sortKey = name:lower(),
    origW = tonumber(w) or 31,
    origH = tonumber(h) or 31,
    wantsShown = shown ~= false,
    hooksInstalled = false,
    original = nil,
    inBag = false,
    anchorLock = false,
    savedSetPoint = nil,
    savedClearAllPoints = nil,
  }

  collected[frame] = info
  markSortedDirty()

  snapshotOriginalPlacement(info)
  installVisibilityHooks(info)
  applyNativeVisibility(info)
  return 1
end

local function pruneCollected()
  for frame, info in pairs(collected) do
    if not frame or not info then
      dropCollected(frame)
    else
      if safeIsForbidden(frame) then
        dropCollected(frame)
      else
        local name = safeGetName(frame)
        if not name or name == "" then
          dropCollected(frame)
        elseif name ~= info.name then
          info.name = name
          info.sortKey = name:lower()
          markSortedDirty()
        end
      end
    end
  end
end

---------------------------------------------------------------------------
-- Scanning
---------------------------------------------------------------------------

local function isUnderMinimapScrollContainer(child)
  local sc = Minimap and Minimap.ScrollContainer
  if not sc then return false end

  local parent = safeGetParent(child)
  for _ = 1, 6 do
    if not parent then break end
    if parent == sc then return true end
    if parent == Minimap then break end
    parent = safeGetParent(parent)
  end
  return false
end

local function isLikelyGlobalButtonName(globalName)
  if type(globalName) ~= "string" or globalName == "" then
    return false
  end

  for i = 1, #GLOBAL_CANDIDATE_PATTERNS do
    if globalName:find(GLOBAL_CANDIDATE_PATTERNS[i]) then
      return true
    end
  end

  return false
end

local function isSkippedScanSubtree(frame)
  if not frame then return false end

  local sc = Minimap and Minimap.ScrollContainer
  if sc and frame == sc then
    return true
  end

  if MinimapCluster then
    if MinimapCluster.IndicatorFrame and frame == MinimapCluster.IndicatorFrame then
      return true
    end
    if MinimapCluster.Tracking and frame == MinimapCluster.Tracking then
      return true
    end
  end

  local name = safeGetName(frame)
  if name == "MinimapScrollContainer" then
    return true
  end

  return false
end

local function isFrameNearMinimap(frame)
  if not frame or not Minimap then
    return false
  end

  local fx, fy = safeGetCenter(frame)
  local mx, my = safeGetCenter(Minimap)
  if not fx or not fy or not mx or not my then
    return false
  end

  local fw, fh = safeGetSize(frame)
  local mw, mh = safeGetSize(Minimap)
  fw, fh = tonumber(fw) or 0, tonumber(fh) or 0
  mw, mh = tonumber(mw) or 160, tonumber(mh) or 160

  local dx = math.abs(fx - mx)
  local dy = math.abs(fy - my)
  local limitX = (mw * 1.8) + (fw * 0.5) + 24
  local limitY = (mh * 1.8) + (fh * 0.5) + 24
  return dx <= limitX and dy <= limitY
end

local function probeChild(child, db, nameHint, requireNearMinimap)
  if type(child) ~= "table" and type(child) ~= "userdata" then
    return false
  end

  if safeIsForbidden(child) then return false end
  if safeIsProtected(child) then return false end

  local objType = safeGetObjectType(child)
  if objType ~= "Button" and objType ~= "Frame" then
    return false
  end

  local name = safeGetName(child)
  if (type(name) ~= "string" or name == "") and type(nameHint) == "string" and nameHint ~= "" then
    name = nameHint
  end
  if type(name) ~= "string" or name == "" then
    return false
  end

  if isIgnoredName(name) then return false end
  if isUserExcluded(name) then return false end

  if db.onlyLibDBIcon and not name:find("^LibDBIcon10_") then
    return false
  end

  local looksLikeMinimapButton = isLikelyGlobalButtonName(name)

  local w, h = safeGetSize(child)
  w = tonumber(w) or 0
  h = tonumber(h) or 0
  if w < 8 or h < 8 or w > 120 or h > 120 then
    return false
  end

  local hasClick = false
  local okClick = safeHasLiveScript(child, "OnClick")
  local okMouseUp = safeHasLiveScript(child, "OnMouseUp")
  local okMouseDown = safeHasLiveScript(child, "OnMouseDown")
  if okClick or okMouseUp or okMouseDown then
    hasClick = true
  end

  local hasDataObject = false
  local okObj, dataObject = pcall(function() return child.dataObject end)
  if okObj and type(dataObject) == "table" then
    hasDataObject = true
  end

  if not hasClick and not hasDataObject and not looksLikeMinimapButton and not name:find("^LibDBIcon10_") then
    return false
  end

  if isUnderMinimapScrollContainer(child) then
    return false
  end

  if requireNearMinimap and not isFrameNearMinimap(child) then
    return false
  end

  return true, name, w, h
end

local function errSilent()
end

local function safeProbe(child, db, nameHint, requireNearMinimap)
  local ok, keep, name, w, h = xpcall(probeChild, errSilent, child, db, nameHint, requireNearMinimap)
  if ok and keep then
    return true, name, w, h
  end
  return false
end

local function scanChildrenDeep(root, db, maxDepth)
  if not root then return 0 end

  wipe(scanStackFrames)
  wipe(scanStackDepths)
  wipe(scanVisited)

  local top = 1
  scanStackFrames[top] = root
  scanStackDepths[top] = 0
  scanVisited[root] = true

  local added = 0
  maxDepth = clamp(maxDepth or ROOT_SCAN_MAX_DEPTH, 0, 6)

  while top > 0 do
    local parent = scanStackFrames[top]
    local depth = scanStackDepths[top]
    scanStackFrames[top] = nil
    scanStackDepths[top] = nil
    top = top - 1

    local kids = safeGetChildren(parent)
    if kids then
      for i = 1, #kids do
        local child = kids[i]
        if child and not scanVisited[child] then
          scanVisited[child] = true

          if not collected[child] then
            local isBtn, name, w, h = safeProbe(child, db, nil, false)
            if isBtn then
              added = added + collectButton(child, name, w, h)
            end
          end

          if depth < maxDepth and not isSkippedScanSubtree(child) then
            local objType = safeGetObjectType(child)
            if objType == "Frame" or objType == "Button" then
              top = top + 1
              scanStackFrames[top] = child
              scanStackDepths[top] = depth + 1
            end
          end
        end
      end
    end
  end

  wipe(scanStackFrames)
  wipe(scanStackDepths)
  wipe(scanVisited)
  return added
end

local function getLibDBIcon()
  if not _G.LibStub then return nil end
  local ok, lib = pcall(LibStub, "LibDBIcon-1.0", true)
  if ok and type(lib) == "table" then
    return lib
  end
  return nil
end

local function scanLibDBIconButtons(db)
  local lib = getLibDBIcon()
  if not lib then return 0 end

  local names = {}
  local seen = {}

  if type(lib.GetButtonList) == "function" then
    local ok, list = pcall(lib.GetButtonList, lib)
    if ok and type(list) == "table" then
      for i = 1, #list do
        local name = list[i]
        if type(name) == "string" and not seen[name] then
          seen[name] = true
          names[#names + 1] = name
        end
      end
    end
  end

  if type(lib.objects) == "table" then
    for name in pairs(lib.objects) do
      if type(name) == "string" and not seen[name] then
        seen[name] = true
        names[#names + 1] = name
      end
    end
  end

  local added = 0
  for i = 1, #names do
    local name = names[i]
    local okBtn, btn = pcall(lib.GetMinimapButton, lib, name)
    if okBtn and btn and not collected[btn] then
      local isBtn, realName, w, h = safeProbe(btn, db, name, false)
      if isBtn then
        added = added + collectButton(btn, realName, w, h)
      end
    end
  end

  return added
end

local lazyScanActive = false
local function startLazyGlobalFallback(db)
  if lazyScanActive then return end
  lazyScanActive = true

  local candidates = {}
  local lastKey = nil

  local function processCandidates()
    local added = 0
    for i = 1, #candidates do
      local globalName = candidates[i]
      local obj = _G[globalName]
      if obj and not collected[obj] then
        local isBtn, name, w, h = safeProbe(obj, db, globalName, true)
        if isBtn then
          added = added + collectButton(obj, name, w, h)
        end
      end
    end
    
    lazyScanActive = false
    lastGlobalFallbackScan = GetTime()

    if added > 0 then
      markSortedDirty()
      applyNativeVisibilityAll()
      updateBagButtonBadge()
      if isOpen then M:Layout() end
    end
  end

  local function step()
    if InCombatLockdown() then
      C_Timer.After(1, step)
      return
    end

    local t0 = debugprofilestop()
    
    while true do
      local k, v = next(_G, lastKey)
      if not k then
        table.sort(candidates)
        processCandidates()
        return
      end

      lastKey = k
      if isLikelyGlobalButtonName(k) then
         candidates[#candidates + 1] = k
      end

      -- Yield if we spent more than 2ms in this frame
      if debugprofilestop() - t0 > 2 then
        C_Timer.After(0.01, step)
        return
      end
    end
  end

  C_Timer.After(0.01, step)
end

function M:Rescan(force)
  local db = getButtonsDB()
  if db.bag == false then
    return 0
  end

  if InCombatLockdown() then
    M._pendingCombatRescan = true
    return 0
  end

  local now = GetTime()
  if not force and (now - lastScanTime) < SCAN_THROTTLE then
    return 0
  end
  lastScanTime = now

  refreshExcludeCache()
  pruneCollected()

  local added = 0
  added = added + scanLibDBIconButtons(db)

  if not db.onlyLibDBIcon then
    added = added + scanChildrenDeep(Minimap, db, ROOT_SCAN_MAX_DEPTH)
    added = added + scanChildrenDeep(MinimapCluster, db, ROOT_SCAN_MAX_DEPTH)
  end

  -- Global fallback is intentionally force-only to avoid heavy full-G scans
  -- during normal gameplay. Now lazy to avoid UI hitching.
  if force and (now - lastGlobalFallbackScan) >= 0.5 then
    startLazyGlobalFallback(db)
  end

  if added > 0 then
    markSortedDirty()
  end

  applyNativeVisibilityAll()
  updateBagButtonBadge()
  return added
end

local function queueLifecycleRescan(delay, force)
  if lifecycleRescanQueued then
    return
  end
  lifecycleRescanQueued = true

  C_Timer.After(delay or 0.35, function()
    lifecycleRescanQueued = false

    local db = getButtonsDB()
    if db.bag == false then
      return
    end

    if InCombatLockdown() then
      M._pendingCombatRescan = true
      return
    end

    M:Rescan(force and true or false)
    if isOpen then
      M:Layout()
    end
  end)
end

local function ensureLifecycleHooks()
  if lifecycleFrame then
    return
  end

  lifecycleFrame = CreateFrame("Frame")
  lifecycleFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  lifecycleFrame:RegisterEvent("ADDON_LOADED")
  lifecycleFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
      return
    end
    queueLifecycleRescan(0.35, false)
  end)
end

local function stopOpenTicker()
  if openTicker then
    openTicker:Cancel()
    openTicker = nil
  end
end

local function startOpenTicker()
  stopOpenTicker()
  openTicker = C_Timer.NewTicker(OPEN_SCAN_INTERVAL, function()
    if not isOpen then
      stopOpenTicker()
      return
    end

    if InCombatLockdown() then
      M._pendingCombatRescan = true
      return
    end

    local added = M:Rescan(false)
    if isOpen then
      if added > 0 then
        M:Layout()
      else
        updateBagButtonBadge()
      end
    end
  end)
end

---------------------------------------------------------------------------
-- Auto-close
---------------------------------------------------------------------------

scheduleAutoClose = function()
  local db = getButtonsDB()
  if db.openOnHover == false then return end
  if not bagFrame or not isOpen then return end
  if bagFrame.pinned then return end

  autoCloseToken = autoCloseToken + 1
  local token = autoCloseToken

  local delay = clamp(db.hoverCloseDelay or 0.25, 0.1, 2.0)
  C_Timer.After(delay, function()
    if token ~= autoCloseToken then return end
    if not isOpen or not bagFrame then return end
    if bagFrame.pinned then return end
    if bagFrame:IsMouseOver() then return end
    if bagButton and bagButton:IsMouseOver() then return end
    M:CloseBag()
  end)
end

---------------------------------------------------------------------------
-- UI creation
---------------------------------------------------------------------------

local function createBagFrame()
  if bagFrame then return end

  bagFrame = CreateFrame("Frame", "RothMinimapBagFrame", UIParent, "BackdropTemplate")
  bagFrame:SetFrameStrata("DIALOG")
  bagFrame:SetFrameLevel(100)
  bagFrame:SetSize(220, 100)
  bagFrame:SetClampedToScreen(true)
  bagFrame:EnableMouse(true)
  bagFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  bagFrame:SetBackdropColor(0.06, 0.06, 0.06, 0.92)
  bagFrame:SetBackdropBorderColor(0.6, 0.5, 0.3, 0.7)
  bagFrame:Hide()

  local title = bagFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  title:SetPoint("TOPLEFT", 8, -5)
  title:SetTextColor(0.9, 0.8, 0.5)
  title:SetText("Minimap Buttons")
  bagFrame.title = title

  local close = CreateFrame("Button", nil, bagFrame, "UIPanelCloseButton")
  close:SetSize(18, 18)
  close:SetPoint("TOPRIGHT", -1, -1)
  close:SetScript("OnClick", function()
    bagFrame.pinned = false
    M:CloseBag()
  end)

  local content = CreateFrame("Frame", nil, bagFrame)
  content:SetPoint("TOPLEFT", FRAME_PAD, -HEADER_H)
  content:SetSize(1, 1)
  bagFrame.content = content

  local empty = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  empty:SetPoint("CENTER", 0, 0)
  empty:SetText("No buttons collected\n|cff666666/rmb scan|r")
  empty:Hide()
  bagFrame.emptyText = empty

  bagFrame:SetScript("OnLeave", function()
    scheduleAutoClose()
  end)
  bagFrame:SetScript("OnEnter", function()
    autoCloseToken = autoCloseToken + 1
  end)

  tinsert(UISpecialFrames, "RothMinimapBagFrame")
end

local function createBagButton()
  if bagButton then return end

  bagButton = CreateFrame("Button", "RothMinimapBagButton", Minimap or UIParent)
  bagButton:SetSize(26, 26)
  bagButton:SetFrameStrata("HIGH")
  bagButton:SetFrameLevel((Minimap and Minimap:GetFrameLevel() or 5) + 80)
  bagButton:RegisterForClicks("AnyUp")

  local icon = bagButton:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("TOPLEFT", 3, -3)
  icon:SetPoint("BOTTOMRIGHT", -3, 3)
  icon:SetTexture(BAG_TOGGLE_ICON)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  icon:SetVertexColor(1, 1, 1, 1)
  bagButton.icon = icon

  -- Mask the icon to be round so it fits inside the ring without black corners
  local mask = bagButton:CreateMaskTexture()
  mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
  mask:SetPoint("TOPLEFT", icon, "TOPLEFT")
  mask:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
  icon:AddMaskTexture(mask)

  local ring = bagButton:CreateTexture(nil, "OVERLAY")
  ring:SetPoint("TOPLEFT", bagButton, "TOPLEFT", 0, 0)
  ring:SetPoint("BOTTOMRIGHT", bagButton, "BOTTOMRIGHT", 0, 0)
  ring:SetTexture(136430) -- Interface\\Minimap\\MiniMap-TrackingBorder
  ring:SetTexCoord(0, 0.6, 0, 0.6)
  ring:SetVertexColor(1, 1, 1, 0.95)
  bagButton.ring = ring

  local hl = bagButton:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.18)
  bagButton:SetHighlightTexture(hl)

  local countText = bagButton:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
  countText:SetPoint("BOTTOMRIGHT", 1, 1)
  countText:SetTextColor(1, 0.85, 0.35)
  countText:Hide()
  bagButton.countText = countText

  bagButton:SetScript("OnEnter", function(self)
    autoCloseToken = autoCloseToken + 1

    local db = getButtonsDB()
    if db.openOnHover ~= false then
      if bagFrame then bagFrame.pinned = false end
      M:OpenBag()
    end

    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Minimap Buttons", 1, 1, 1)
    GameTooltip:AddLine(countDisplayableButtons() .. " button(s) available", 0.7, 0.7, 0.7)
    if db.pinOnClick == false then
      GameTooltip:AddLine("LeftClick: open/close", 0.5, 0.5, 0.5)
    else
      GameTooltip:AddLine("LeftClick: pin/unpin", 0.5, 0.5, 0.5)
    end
    GameTooltip:AddLine("RightClick: rescan", 0.5, 0.5, 0.5)
    GameTooltip:AddLine("Ctrl+RightClick on button: exclude/include", 0.5, 0.5, 0.5)
    GameTooltip:Show()
  end)

  bagButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
    scheduleAutoClose()
  end)

  bagButton:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "RightButton" then
      M:Rescan(true)
      if isOpen then
        M:Layout()
      end
      return
    end

    local db = getButtonsDB()
    local pinOnClick = db.pinOnClick ~= false

    if not isOpen then
      if bagFrame then bagFrame.pinned = pinOnClick and true or false end
      M:OpenBag()
    else
      if not pinOnClick then
        if bagFrame then bagFrame.pinned = false end
        M:CloseBag()
      elseif bagFrame and bagFrame.pinned then
        bagFrame.pinned = false
        M:CloseBag()
      else
        if bagFrame then bagFrame.pinned = true end
      end
    end
  end)
end

local function refreshBagButtonAnchor()
  if not bagButton then return end

  local parent = Minimap or UIParent
  if bagButton:GetParent() ~= parent then
    bagButton:SetParent(parent)
  end

  bagButton:ClearAllPoints()
  if Minimap then
    bagButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 2, 2)
  else
    bagButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -4)
  end
end

local function ensureUI()
  ensureLifecycleHooks()
  createBagFrame()
  createBagButton()
  refreshBagButtonAnchor()
end

---------------------------------------------------------------------------
-- Layout
---------------------------------------------------------------------------

local function shouldShowInfoInBag(info)
  if not info or not info.frame then return false end
  if not info.name or info.name == "" then return false end
  if isUserExcluded(info.name) then return false end
  if info.wantsShown == false then return false end
  if safeIsForbidden(info.frame) then return false end
  return true
end

function M:Layout()
  if not bagFrame or not isOpen then return end

  rebuildSortedIfNeeded()

  local db = getButtonsDB()
  local size = clamp(db.buttonSize or BUTTON_SIZE, 18, 48)
  local cols = clamp(db.columns or GRID_COLS, 2, 12)

  local visibleCount = 0
  for i = 1, #sortedInfos do
    local info = sortedInfos[i]
    if shouldShowInfoInBag(info) then
      local slot = visibleCount + 1
      if placeButtonInBag(info, slot, size, cols) then
        visibleCount = slot
      end
    elseif info.inBag or info.anchorLock then
      restoreButtonPlacement(info)
    end
  end

  if bagFrame.emptyText then
    bagFrame.emptyText:SetShown(visibleCount == 0)
  end

  local rows = math.max(1, math.ceil(math.max(visibleCount, 1) / cols))
  local actualCols = math.max(1, math.min(cols, math.max(visibleCount, 1)))

  local contentW = actualCols * size + (actualCols - 1) * GRID_PAD
  local contentH = rows * size + (rows - 1) * GRID_PAD

  bagFrame.content:SetSize(contentW, contentH)

  local w = FRAME_PAD + contentW + FRAME_PAD
  local h = HEADER_H + contentH + FRAME_PAD
  w = clamp(w, 140, 520)
  h = clamp(h, 60, 520)
  bagFrame:SetSize(w, h)

  if bagFrame.title then
    bagFrame.title:SetText("Minimap Buttons (" .. visibleCount .. ")")
  end

  updateBagButtonBadge()
end

---------------------------------------------------------------------------
-- Open / close
---------------------------------------------------------------------------

local function placeBagFrameNearButtonOrCursor()
  local db = getButtonsDB()

  bagFrame:ClearAllPoints()
  if db.openAtCursor then
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x = x / scale
    y = y / scale
    bagFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + 12, y + 12)
  else
    bagFrame:SetPoint("BOTTOMLEFT", bagButton, "TOPLEFT", -4, 4)
  end
end

function M:OpenBag()
  ensureUI()

  local db = getButtonsDB()
  if db.bag == false then return end

  if isOpen then
    M:Layout()
    return
  end

  isOpen = true
  placeBagFrameNearButtonOrCursor()
  bagFrame:Show()

  M:Rescan(false)
  M:Layout()
  startOpenTicker()
end

function M:CloseBag()
  if not isOpen then return end
  isOpen = false
  stopOpenTicker()

  if bagFrame then
    bagFrame:Hide()
  end

  restoreAllButtonsToOriginal()
  applyNativeVisibilityAll()
  updateBagButtonBadge()
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function M:Apply()
  ensureUI()

  local db = getButtonsDB()
  if db.bag == false then
    M:Disable()
    return
  end

  if db.showToggle == false then
    bagButton:Hide()
  else
    bagButton:Show()
  end

  M:Rescan(false)

  if not M._warmupDone then
    M._warmupDone = true
    C_Timer.After(1, function()
      M:Rescan(false)
      if isOpen then M:Layout() end
    end)
    C_Timer.After(4, function()
      M:Rescan(false)
      if isOpen then M:Layout() end
    end)
    C_Timer.After(8, function()
      M:Rescan(true)
      if isOpen then M:Layout() end
    end)
  end

  if not M._ldbiHooked then
    local lib = getLibDBIcon()
    if lib and type(lib.RegisterCallback) == "function" then
      M._ldbiHooked = true
      M._ldbiCallbackOwner = M._ldbiCallbackOwner or CreateFrame("Frame")
      pcall(lib.RegisterCallback, lib, M._ldbiCallbackOwner, "LibDBIcon_IconCreated", function()
        if InCombatLockdown() then
          M._pendingCombatRescan = true
          return
        end
        M:Rescan(true)
        if isOpen then
          M:Layout()
        end
      end)
    end
  end

  if isOpen then
    M:Layout()
  end
end

function M:Disable()
  stopOpenTicker()

  if isOpen then
    M:CloseBag()
  end

  restoreNativeVisibilityAll()

  if bagFrame then
    bagFrame:Hide()
  end
  if bagButton then
    bagButton:Hide()
  end

  wipe(collected)
  wipe(sortedInfos)
  sortedDirty = true
end

function M:OnCombatChanged(inCombat)
  if inCombat then
    return
  end

  local db = getButtonsDB()
  if db.bag == false then
    return
  end

  if M._pendingCombatRescan then
    M._pendingCombatRescan = false
    M:Rescan(true)
  else
    M:Rescan(false)
  end

  if isOpen then
    M:Layout()
  end
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

SLASH_ROTHMINIMAPBUTTONS1 = "/rmb"
SlashCmdList.ROTHMINIMAPBUTTONS = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  ensureUI()

  if msg == "scan" then
    M:Rescan(true)
    if isOpen then M:Layout() end
    print("|cff66ccffRothMinimap:|r Scanned. Tracking " .. tostring(countDisplayableButtons()) .. " button(s).")
    return
  end

  if msg == "reset" then
    restoreNativeVisibilityAll()
    wipe(collected)
    wipe(sortedInfos)
    sortedDirty = true
    M:Rescan(true)
    if isOpen then M:Layout() end
    print("|cff66ccffRothMinimap:|r Button bag reset.")
    return
  end

  if msg == "list" or msg == "dump" then
    local count = 0
    for _, info in pairs(collected) do
      count = count + 1
      print("|cff66ccffRMB|r " .. tostring(info.name or "?") .. "  wantsShown=" .. tostring(info.wantsShown))
      if count > 60 then break end
    end
    if count == 0 then
      print("|cff66ccffRMB|r No buttons tracked.")
    end
    return
  end

  if isOpen then
    if bagFrame then bagFrame.pinned = false end
    M:CloseBag()
  else
    if bagFrame then bagFrame.pinned = true end
    M:OpenBag()
  end
end
