-- Roth Minimap — Options Panel (v4)
--
-- Settings → AddOns → Roth Minimap
--
-- Architecture (v4 — fixed scroll):
--   Canvas (registered with Settings.RegisterCanvasLayoutCategory)
--     └─ widgets anchored TOPLEFT→previous BOTTOMLEFT
--
-- WoW 12.x Settings API wraps the canvas in its own ScrollFrame.
-- We do NOT nest a second ScrollFrame (that caused the v3 scroll bug
-- where content vanished on scroll due to double-scroll conflict).
-- Canvas height is set to totalH so the outer ScrollFrame works correctly.

local ADDON, ns = ...

local O = {}
ns.options = O

-- ─── constants ──────────────────────────────────────────────────────────────
local INDENT   = 16
local PAD_Y    = 4       -- vertical gap between widgets
local PAD_SEC  = 14      -- extra gap before section header
local SLIDER_W = 180
local EDIT_W   = 260
local EDIT_H   = 26
local CONTENT_W = 540    -- fixed content width (avoids GetWidth()==0 at build time)

local FONT_HEADER = "GameFontNormalLarge"
local FONT_NORMAL = "GameFontHighlight"
local FONT_SMALL  = "GameFontHighlightSmall"
local FONT_DIM    = "GameFontDisableSmall"

-- ─── DB shorthand ───────────────────────────────────────────────────────────
local function dbGet(path)
  local t = ns.db
  for i = 1, #path do
    if type(t) ~= "table" then return nil end
    t = t[path[i]]
  end
  return t
end

local function dbSet(path, value)
  local t = ns.db
  for i = 1, #path - 1 do
    local k = path[i]
    if type(t[k]) ~= "table" then t[k] = {} end
    t = t[k]
  end
  t[path[#path]] = value
end

local function queueApply(reason)
  if ns.QueueApply then ns:QueueApply(reason or "settings") end
end

-- ─── Widget factory ──────────────────────────────────────────────────────────
-- Each factory returns (widget, heightConsumed).
-- `anchor` = previous widget (or the canvas for the first one).
-- `yOff`   = extra negative Y offset from the anchor's bottom.

local function makeHeader(parent, anchor, text, yOff)
  local h = parent:CreateFontString(nil, "ARTWORK", FONT_HEADER)
  h:SetPoint("TOPLEFT", anchor, anchor == parent and "TOPLEFT" or "BOTTOMLEFT", 0, -(yOff or PAD_SEC))
  h:SetText(text)

  local rule = parent:CreateTexture(nil, "ARTWORK")
  rule:SetHeight(1)
  rule:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -4)
  rule:SetPoint("RIGHT", parent, "RIGHT", -8, 0)
  rule:SetColorTexture(0.4, 0.4, 0.4, 0.5)

  local totalH = h:GetStringHeight() + 4 + 1 + (yOff or PAD_SEC)
  return h, totalH, rule
end

local function makeLabel(parent, anchor, text, yOff)
  local lbl = parent:CreateFontString(nil, "ARTWORK", FONT_DIM)
  lbl:SetPoint("TOPLEFT", anchor, anchor == parent and "TOPLEFT" or "BOTTOMLEFT",
               0, -(yOff or PAD_Y))
  lbl:SetText(text)
  lbl:SetJustifyH("LEFT")
  lbl:SetWordWrap(true)
  lbl:SetWidth(CONTENT_W - INDENT * 2)
  local totalH = lbl:GetStringHeight() + (yOff or PAD_Y)
  return lbl, totalH
end

local function makeCheck(parent, anchor, label, dbPath, yOff, onChange)
  local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
  cb:SetPoint("TOPLEFT", anchor, anchor == parent and "TOPLEFT" or "BOTTOMLEFT",
              0, -(yOff or PAD_Y))
  cb.Text:SetFontObject(FONT_NORMAL)
  cb.Text:SetText(label)

  cb:SetChecked(dbGet(dbPath) == true)
  cb:SetScript("OnClick", function(self)
    local val = self:GetChecked()
    dbSet(dbPath, val)
    if onChange then onChange(val) end
    queueApply("check:" .. table.concat(dbPath, "."))
  end)

  local totalH = math.max(cb:GetHeight(), 24) + (yOff or PAD_Y)
  return cb, totalH
end

local function makeSlider(parent, anchor, label, dbPath, lo, hi, step, yOff, fmt, onChange)
  step = step or 1
  fmt  = fmt or "%.0f"

  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(42)
  row:SetPoint("TOPLEFT", anchor, anchor == parent and "TOPLEFT" or "BOTTOMLEFT",
               0, -(yOff or PAD_Y))
  row:SetWidth(CONTENT_W - INDENT)

  local lbl = row:CreateFontString(nil, "ARTWORK", FONT_NORMAL)
  lbl:SetPoint("TOPLEFT")
  lbl:SetText(label)

  local val = row:CreateFontString(nil, "ARTWORK", FONT_SMALL)
  val:SetPoint("LEFT", lbl, "RIGHT", 8, 0)

  local sl = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
  sl:SetWidth(SLIDER_W)
  sl:SetHeight(17)
  sl:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -2)
  sl:SetMinMaxValues(lo, hi)
  sl:SetValueStep(step)
  sl:SetObeyStepOnDrag(true)
  sl.Low:SetText(string.format(fmt, lo))
  sl.High:SetText(string.format(fmt, hi))

  local current = tonumber(dbGet(dbPath)) or lo
  sl:SetValue(current)
  val:SetText(string.format(fmt, current))

  sl:SetScript("OnValueChanged", function(self, v)
    v = math.floor(v / step + 0.5) * step
    val:SetText(string.format(fmt, v))
    dbSet(dbPath, v)
    if onChange then onChange(v) end
    queueApply("slider:" .. table.concat(dbPath, "."))
  end)

  local totalH = 42 + (yOff or PAD_Y)
  return row, totalH
end

local function makeEditBox(parent, anchor, label, dbPath, yOff, onChange)
  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(EDIT_H + 16)
  row:SetPoint("TOPLEFT", anchor, anchor == parent and "TOPLEFT" or "BOTTOMLEFT",
               0, -(yOff or PAD_Y))
  row:SetWidth(CONTENT_W - INDENT)

  local lbl = row:CreateFontString(nil, "ARTWORK", FONT_NORMAL)
  lbl:SetPoint("TOPLEFT")
  lbl:SetText(label)

  local eb = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
  eb:SetSize(EDIT_W, EDIT_H)
  eb:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 4, -2)
  eb:SetAutoFocus(false)
  eb:SetFontObject(FONT_SMALL)
  eb:SetText(tostring(dbGet(dbPath) or ""))

  local function commit(self)
    local newValue = self:GetText() or ""
    local oldValue = tostring(dbGet(dbPath) or "")
    if newValue == oldValue then return end
    dbSet(dbPath, newValue)
    if onChange then onChange(newValue) end
    queueApply("edit:" .. table.concat(dbPath, "."))
  end

  eb:SetScript("OnEnterPressed", function(self)
    commit(self)
    self:ClearFocus()
  end)
  eb:SetScript("OnEditFocusLost", function(self)
    commit(self)
  end)
  eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

  local totalH = EDIT_H + 16 + (yOff or PAD_Y)
  return row, totalH
end

-- Collapsible group: checkbox toggles a clipping container.
-- Container height is 1 when collapsed; expanded to content height.
-- The *container* should be used as `prev` for subsequent widgets.
local function makeCollapsible(parent, anchor, label, yOff, onResize)
  local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
  cb:SetPoint("TOPLEFT", anchor, anchor == parent and "TOPLEFT" or "BOTTOMLEFT",
              0, -(yOff or PAD_Y))
  cb.Text:SetFontObject(FONT_NORMAL)
  cb.Text:SetText(label)
  cb:SetChecked(false)

  local container = CreateFrame("Frame", nil, parent)
  container:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 0, -2)
  container:SetWidth(CONTENT_W - INDENT * 2)
  container:SetClipsChildren(true)
  container:SetHeight(1) -- collapsed by default

  local expandedH = 1

  cb:SetScript("OnClick", function(self)
    local show = self:GetChecked()
    if show then
      self.Text:SetText(label:gsub("▸", "▾"))
      container:SetHeight(expandedH)
      if onResize then onResize(expandedH - 1) end
    else
      self.Text:SetText(label:gsub("▾", "▸"))
      container:SetHeight(1)
      if onResize then onResize(-(expandedH - 1)) end
    end
  end)

  container.SetExpandedHeight = function(_, h)
    expandedH = h
  end

  local cbH = math.max(cb:GetHeight(), 24) + 2 + (yOff or PAD_Y)
  return cb, container, cbH
end

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local function makeMediaSelect(parent, anchor, label, mediaType, dbPath, yOff, onChange)
  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(42)
  row:SetPoint("TOPLEFT", anchor, anchor == parent and "TOPLEFT" or "BOTTOMLEFT", 0, -(yOff or PAD_Y))
  row:SetWidth(CONTENT_W)

  local lbl = row:CreateFontString(nil, "ARTWORK", FONT_NORMAL)
  lbl:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
  lbl:SetText(label)

  local drop = CreateFrame("Frame", "RothMedia-"..table.concat(dbPath,"-"), row, "UIDropDownMenuTemplate")
  drop:SetPoint("TOPRIGHT", row, "TOPRIGHT", 16, 2)
  
  if not LSM then return row, 42 + (yOff or PAD_Y) end
  
  UIDropDownMenu_SetWidth(drop, 160)
  UIDropDownMenu_Initialize(drop, function(self, level)
    local info = UIDropDownMenu_CreateInfo()
    local list = LSM:HashTable(mediaType)
    if not list then return end
    for name, path in pairs(list) do
      info.text = name
      info.arg1 = name
      info.func = function(_, arg1)
        UIDropDownMenu_SetSelectedName(drop, arg1)
        dbSet(dbPath, arg1)
        if onChange then onChange(arg1) end
        queueApply("media:"..table.concat(dbPath, "."))
      end
      info.checked = (dbGet(dbPath) == name)
      UIDropDownMenu_AddButton(info, level)
    end
  end)
  UIDropDownMenu_SetSelectedName(drop, dbGet(dbPath) or "Arial Narrow")

  return row, 42 + (yOff or PAD_Y)
end

local function makeColorPicker(parent, anchor, label, dbPath, yOff, onChange)
  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(24)
  row:SetPoint("TOPLEFT", anchor, anchor == parent and "TOPLEFT" or "BOTTOMLEFT", 0, -(yOff or PAD_Y))
  row:SetWidth(CONTENT_W)

  local lbl = row:CreateFontString(nil, "ARTWORK", FONT_NORMAL)
  lbl:SetPoint("LEFT", row, "LEFT", 0, 0)
  lbl:SetText(label)

  local btn = CreateFrame("Button", nil, row)
  btn:SetSize(16, 16)
  btn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
  
  local tex = btn:CreateTexture(nil, "OVERLAY")
  tex:SetAllPoints()
  tex:SetColorTexture(1, 1, 1, 1)

  local function updateColor()
    local color = dbGet(dbPath) or {1, 1, 1, 1}
    local r, g, b, a = color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1, color.a or color[4] or 1
    tex:SetColorTexture(r, g, b, a)
  end
  updateColor()

  btn:SetScript("OnClick", function()
    local color = dbGet(dbPath) or {1, 1, 1, 1}
    local cr, cg, cb, ca = color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1, color.a or color[4] or 1
    
    local function setDBColor(rest)
      local r, g, b = ColorPickerFrame:GetColorRGB()
      local a = ColorPickerFrame.hasOpacity and ColorPickerFrame:GetColorAlpha() or 1
      if rest then
        r, g, b, a = rest.r, rest.g, rest.b, rest.a
      end
      dbSet(dbPath, {r, g, b, a})
      tex:SetColorTexture(r, g, b, a)
      if onChange then onChange(r, g, b, a) end
      queueApply("color:"..table.concat(dbPath, "."))
    end

    if ColorPickerFrame.SetupColorPickerAndShow then
      ColorPickerFrame:SetupColorPickerAndShow({
        r = cr, g = cg, b = cb, opacity = ca,
        hasOpacity = true,
        swatchFunc = setDBColor,
        opacityFunc = setDBColor,
        cancelFunc = setDBColor,
        previousValues = {r = cr, g = cg, b = cb, a = ca},
      })
    else
      ColorPickerFrame.func = setDBColor
      ColorPickerFrame.opacityFunc = setDBColor
      ColorPickerFrame.cancelFunc = setDBColor
      ColorPickerFrame.hasOpacity = true
      ColorPickerFrame.opacity = ca
      ColorPickerFrame.previousValues = {r = cr, g = cg, b = cb, a = ca}
      ColorPickerFrame:SetColorRGB(cr, cg, cb)
      ColorPickerFrame:Show()
    end
  end)

  return row, 24 + (yOff or PAD_Y)
end

-- ─── Panel builders ────────────────────────────────────────────────────────────
-- v6: Restored explicit ScrollFrame to fix overflow/лесенка on 10.x+.

local categoryID

local function initCanvas(name)
  local panel = CreateFrame("Frame")
  panel.name = name
  
  local safeName = "RothMinimapOptionsScroll" .. name:gsub("%s+", ""):gsub("[%&%p]+", "")
  local scrollFrame = CreateFrame("ScrollFrame", safeName, panel, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 8, -8)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 8)
  scrollFrame:SetClipsChildren(true)
  
  local scrollBar = _G[safeName.."ScrollBar"]
  if scrollBar then
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 6, 16)
  end
  
  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(CONTENT_W + 16, 1)
  scrollFrame:SetScrollChild(content)

  local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText(name)

  local rule = content:CreateTexture(nil, "ARTWORK")
  rule:SetHeight(1)
  rule:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  rule:SetPoint("RIGHT", content, "RIGHT", -16, 0)
  rule:SetColorTexture(0.4, 0.4, 0.4, 0.5)

  content.prev = rule
  content.totalH = 16 + title:GetStringHeight() + 8 + 1 + PAD_SEC
  
  panel.content = content
  panel.scrollFrame = scrollFrame
  
  return panel, content
end

local function addWidget(content, widget, h)
  content.prev = widget
  content.totalH = content.totalH + h
end

local function addResetButton(content)
  local resetBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
  resetBtn:SetSize(140, 24)
  resetBtn:SetPoint("TOPLEFT", content.prev, "BOTTOMLEFT", 0, -PAD_SEC * 2)
  resetBtn:SetText("Reset All Defaults")
  resetBtn:SetScript("OnClick", function()
    StaticPopup_Show("ROTHMINIMAP_RESET_CONFIRM")
  end)
  addWidget(content, resetBtn, 24 + PAD_SEC * 2 + 20)
end

local function buildLayout()
  local panel, content = initCanvas("Roth Minimap: General")
  local prev = content.prev
  local w, h
  local function add(extW, extH) addWidget(content, extW, extH); prev = content.prev end

  w, h = makeSlider(content, prev, "Minimap Size",
                    {"size"}, 120, 400, 5, nil, "%.0f px");      add(w, h)
  w, h = makeSlider(content, prev, "Scale",
                    {"scale"}, 0.50, 2.00, 0.05, nil, "%.2f");   add(w, h)
  w, h = makeCheck(content, prev, "Enable Mover  (Alt-drag to reposition)",
                   {"mover","enabled"});                          add(w, h)
  w, h = makeCheck(content, prev, "Quick World Map  (Shift-click minimap)",
                   {"quickMap","enabled"});                        add(w, h)
  w, h = makeCheck(content, prev, "Hide Addon Compartment button",
                   {"hideAddonCompartment"});                      add(w, h)
  w, h = makeMediaSelect(content, prev, "Zone Text Font", "font", {"zoneText", "font"}); add(w, h)
  w, h = makeLabel(content, prev,
    "Blizzard minimap art, zoom buttons and north tag are always hidden by design in Roth Minimap."); add(w, h)

  addResetButton(content)
  content:SetHeight(content.totalH)
  return panel
end

local function buildSkin()
  local panel, content = initCanvas("Skin & Effects")
  local prev = content.prev
  local w, h
  local function add(extW, extH) addWidget(content, extW, extH); prev = content.prev end

  w, h = makeCheck(content, prev, "Square Minimap", {"square"}); add(w, h)
  w, h = makeCheck(content, prev, "Enable Diablo Skin", {"skinEnabled"}); add(w, h)

  w, h = makeHeader(content, prev, "Shadow & Layers", PAD_SEC); add(w, h)
  w, h = makeCheck(content, prev, "Drop Shadow", {"shadow","enabled"}); add(w, h)
  w, h = makeSlider(content, prev, "Shadow Opacity", {"shadow","alpha"}, 0, 1, 0.02, nil, "%.2f"); add(w, h)
  w, h = makeSlider(content, prev, "Border Opacity", {"visual","border","alpha"}, 0, 1, 0.05, nil, "%.2f"); add(w, h)
  w, h = makeColorPicker(content, prev, "Border Color", {"visual","border","color"}); add(w, h)
  w, h = makeCheck(content, prev, "Runes Overlay", {"visual","runes","enabled"}); add(w, h)
  w, h = makeColorPicker(content, prev, "Runes Color", {"visual","runes","color"}); add(w, h)
  w, h = makeSlider(content, prev, "Runes Combat Alpha", {"visual","runes","combatAlpha"}, 0, 1, 0.05, nil, "%.2f"); add(w, h)
  w, h = makeCheck(content, prev, "Glow Overlay", {"visual","glow","enabled"}); add(w, h)
  w, h = makeColorPicker(content, prev, "Glow Color", {"visual","glow","color"}); add(w, h)
  w, h = makeSlider(content, prev, "Glow Combat Alpha", {"visual","glow","combatAlpha"}, 0, 1, 0.05, nil, "%.2f"); add(w, h)
  w, h = makeCheck(content, prev, "Vignette (inner darken)", {"visual","vignette","enabled"}); add(w, h)
  w, h = makeSlider(content, prev, "Vignette Alpha", {"visual","vignette","alpha"}, 0, 0.60, 0.02, nil, "%.2f"); add(w, h)
  w, h = makeCheck(content, prev, "Charred Edge", {"visual","char","enabled"}); add(w, h)
  w, h = makeSlider(content, prev, "Charred Alpha", {"visual","char","alpha"}, 0, 1, 0.05, nil, "%.2f"); add(w, h)

  w, h = makeHeader(content, prev, "Fire Animations", PAD_SEC); add(w, h)
  w, h = makeCheck(content, prev, "Combat Flash FX", {"visual","fx","enabled"}); add(w, h)
  w, h = makeCheck(content, prev, "Fire Animation", {"fire","enabled"}); add(w, h)
  w, h = makeSlider(content, prev, "Fire — Out-of-Combat Alpha", {"fire","outAlpha"}, 0, 0.60, 0.02, nil, "%.2f"); add(w, h)
  w, h = makeSlider(content, prev, "Fire — Combat Alpha", {"fire","combatAlpha"}, 0, 1, 0.05, nil, "%.2f"); add(w, h)

  local advCb, advBox, advCbH
  advCb, advBox, advCbH = makeCollapsible(content, prev, "▸ Advanced Fire / Breath / Reactive", PAD_Y, function(delta)
    content.totalH = content.totalH + delta
    content:SetHeight(content.totalH)
  end)
  add(advCb, advCbH)
  content.totalH = content.totalH + 1
  prev = advBox

  do
    local ap = advBox; local aH = 0; local aw, aprev
    aw, h = makeSlider(ap, ap, "Fire FPS — Out of Combat", {"fire","outFPS"}, 1, 16, 1, 2, "%.0f"); aH = aH + h; aprev = aw
    aw, h = makeSlider(ap, aprev, "Fire FPS — Combat", {"fire","combatFPS"}, 1, 30, 1, nil, "%.0f"); aH = aH + h; aprev = aw
    aw, h = makeCheck(ap, aprev, "Combat Flare on Enter", {"fire","combatFlare"}); aH = aH + h; aprev = aw
    aw, h = makeSlider(ap, aprev, "Flare Duration (sec)", {"fire","flareDuration"}, 0.05, 0.80, 0.01, nil, "%.2f"); aH = aH + h; aprev = aw
    aw, h = makeSlider(ap, aprev, "Fade Out Duration (sec)", {"fire","fadeOutDuration"}, 0.2, 3.0, 0.1, nil, "%.1f"); aH = aH + h; aprev = aw
    aw, h = makeCheck(ap, aprev, "Breathing Overlay", {"fire","breath","enabled"}); aH = aH + h; aprev = aw
    aw, h = makeSlider(ap, aprev, "Breath Period — OOC (sec)", {"fire","breath","outPeriod"}, 1.0, 12.0, 0.2, nil, "%.1f"); aH = aH + h; aprev = aw
    aw, h = makeSlider(ap, aprev, "Breath Period — Combat (sec)", {"fire","breath","combatPeriod"}, 0.5, 6.0, 0.1, nil, "%.1f"); aH = aH + h; aprev = aw
    aw, h = makeCheck(ap, aprev, "Reactive FX (ping/damage/low-HP glow)", {"fire","reactive","enabled"}); aH = aH + h; aprev = aw
    aw, h = makeCheck(ap, aprev, "Dim While Mounted", {"fire","reactive","dimWhileMounted"}); aH = aH + h; aprev = aw
    aw, h = makeCheck(ap, aprev, "Dim While Resting", {"fire","reactive","dimWhileResting"}); aH = aH + h; aprev = aw
    aw, h = makeSlider(ap, aprev, "Dim Factor", {"fire","reactive","dimFactor"}, 0.10, 1.0, 0.05, nil, "%.2f"); aH = aH + h; aprev = aw
    advBox:SetExpandedHeight(aH + 8)
  end

  content:SetHeight(content.totalH)
  return panel
end

local function buildModules()
  local panel, content = initCanvas("Modules (Ping & Zoom)")
  local prev = content.prev
  local w, h
  local function add(extW, extH) addWidget(content, extW, extH); prev = content.prev end

  w, h = makeCheck(content, prev, "Ping Toast (show who pinged)", {"ping","enabled"}); add(w, h)
  w, h = makeCheck(content, prev, "Ping Sound", {"ping","sound"}); add(w, h)
  
  w, h = makeHeader(content, prev, "Zoom", PAD_SEC); add(w, h)
  w, h = makeCheck(content, prev, "Mouse Wheel Zoom", {"zoom","mousewheel"}); add(w, h)
  w, h = makeCheck(content, prev, "Auto Zoom Reset", {"zoom","autoReset"}); add(w, h)

  content:SetHeight(content.totalH)
  return panel
end

local function buildButtonBag()
  local panel, content = initCanvas("Button Bag")
  local prev = content.prev
  local w, h
  local function add(extW, extH) addWidget(content, extW, extH); prev = content.prev end

  w, h = makeCheck(content, prev, "Enable Button Bag", {"buttons","bag"}); add(w, h)
  w, h = makeCheck(content, prev, "Show Toggle Icon on Minimap", {"buttons","showToggle"}); add(w, h)
  w, h = makeSlider(content, prev, "Button Size (px)", {"buttons","buttonSize"}, 20, 48, 1); add(w, h)
  w, h = makeSlider(content, prev, "Grid Columns", {"buttons","columns"}, 2, 12, 1); add(w, h)
  w, h = makeCheck(content, prev, "Stash Buttons When Bag Closed", {"buttons","stashWhenClosed"}); add(w, h)
  w, h = makeCheck(content, prev, "Open Bag on Hover", {"buttons","openOnHover"}); add(w, h)
  w, h = makeCheck(content, prev, "Only Collect LibDBIcon Buttons", {"buttons","onlyLibDBIcon"}); add(w, h)
  w, h = makeLabel(content, prev, "Limits collection to buttons from LibDBIcon. Fewer false positives, but misses addons that create minimap buttons manually."); add(w, h)
  w, h = makeEditBox(content, prev, "Exclude — Exact Frame Names (comma-separated)", {"buttons","excludeExact"}); add(w, h)
  w, h = makeEditBox(content, prev, "Exclude — Substring Tokens (comma-separated)", {"buttons","excludeSubstrings"}); add(w, h)

  content:SetHeight(content.totalH)
  return panel
end

-- Confirmation dialog for reset
StaticPopupDialogs["ROTHMINIMAP_RESET_CONFIRM"] = {
  text = "Reset all Roth Minimap settings to defaults?\n\nThis will reload the UI.",
  button1 = "Reset",
  button2 = "Cancel",
  OnAccept = function() ns:ResetDB(true) end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-- ─── Registration ────────────────────────────────────────────────────────────

local function register()
  if categoryID then return end
  
  if Settings and Settings.RegisterCanvasLayoutCategory then
    local mainPanel = buildLayout()
    local category = Settings.RegisterCanvasLayoutCategory(mainPanel, "Roth Minimap")
    categoryID = category.ID
    Settings.RegisterAddOnCategory(category)
    
    local pSkin = buildSkin()
    Settings.RegisterCanvasLayoutSubcategory(category, pSkin, "Skin & Effects")
    
    local pMods = buildModules()
    Settings.RegisterCanvasLayoutSubcategory(category, pMods, "Modules")
    
    local pBag = buildButtonBag()
    Settings.RegisterCanvasLayoutSubcategory(category, pBag, "Button Bag")
    
  elseif InterfaceOptions_AddCategory then
    local mainPanel = buildLayout()
    mainPanel.name = "Roth Minimap"
    InterfaceOptions_AddCategory(mainPanel)
    categoryID = "Roth Minimap"
    
    local pSkin = buildSkin()
    pSkin.name = "Skin & Effects"
    pSkin.parent = "Roth Minimap"
    InterfaceOptions_AddCategory(pSkin)
    
    local pMods = buildModules()
    pMods.name = "Modules"
    pMods.parent = "Roth Minimap"
    InterfaceOptions_AddCategory(pMods)
    
    local pBag = buildButtonBag()
    pBag.name = "Button Bag"
    pBag.parent = "Roth Minimap"
    InterfaceOptions_AddCategory(pBag)
  end
end

-- ─── Init ────────────────────────────────────────────────────────────────────
-- Lazy registration: we do NOT build or register the panel on ADDON_LOADED.
-- The panel is built on the first :Open() call (when the user actually opens
-- Settings). This saves ~2–5 ms of frame creation at login.

local initDone = false
function O:Init()
  if initDone then return end
  initDone = true
  -- Pre-register the category name so it appears in the Settings list,
  -- but defer full panel build to first Open.
  C_Timer.After(0, register)
end

function O:Open()
  if not initDone then self:Init() end
  -- Ensure panel is built
  if not categoryID then register() end
  if Settings and Settings.OpenToCategory then
    Settings.OpenToCategory(categoryID or "Roth Minimap")
  elseif InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory("Roth Minimap")
  end
end
