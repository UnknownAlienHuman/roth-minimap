local frames, timers, tickers, errors = {}, {}, {}, {}
local combat, hybrid, housing = false, false, false

canaccessvalue = function(value)
  return not (type(value) == "table" and rawget(value, "__bad"))
end
canaccesstable = canaccessvalue
InCombatLockdown = function() return combat end
DEFAULT_CHAT_FRAME = { messages = {}, AddMessage = function(self, message) self.messages[#self.messages + 1] = message end }
SlashCmdList = {}

local function animationGroup(owner)
  local group = { owner = owner, scripts = {}, playing = false, animations = {} }
  function group:CreateAnimation(animationType)
    local animation = { animationType = animationType, values = {} }
    self.animations[#self.animations + 1] = animation
    return setmetatable(animation, {
      __index = function(tableValue, key)
        return function(_, value, secondValue)
          if secondValue ~= nil then
            tableValue.values[key] = { value, secondValue }
          else
            tableValue.values[key] = value
          end
        end
      end,
    })
  end
  function group:SetLooping(value) self.looping = value end
  function group:IsPlaying() return self.playing end
  function group:SetScript(key, value) self.scripts[key] = value end
  function group:Play()
    self.playing = true
    if self.scripts.OnPlay then self.scripts.OnPlay(self) end
  end
  function group:Stop()
    local wasPlaying = self.playing
    self.playing = false
    if self.scripts.OnStop and wasPlaying then self.scripts.OnStop(self) end
  end
  function group:Finish()
    self.playing = false
    if self.scripts.OnFinished then self.scripts.OnFinished(self) end
  end
  return group
end

local function object(parent)
  local value = {
    parent = parent,
    scripts = {},
    hooks = {},
    events = {},
    eventCallbacks = {},
    textures = {},
    maskTextures = {},
    fontStrings = {},
    points = {},
    shown = true,
    alpha = 1,
    alphaReadable = true,
    accessible = true,
    width = 0,
    height = 0,
    strata = "MEDIUM",
    level = 0,
  }

  function value:CanBeAccessedInContext() return self.accessible end
  function value:IsForbidden() return false end
  function value:RegisterEvent(event) self.events[event] = true end
  function value:UnregisterEvent(event) self.events[event] = nil end
  function value:RegisterEventCallback(event, callback) self.eventCallbacks[event] = callback end
  function value:UnregisterEventCallback(event) self.eventCallbacks[event] = nil end
  function value:SetScript(script, callback) self.scripts[script] = callback end
  function value:HookScript(script, callback)
    local hooks = self.hooks[script] or {}
    hooks[#hooks + 1] = callback
    self.hooks[script] = hooks
  end
  function value:RunScript(script, ...)
    if self.scripts[script] then self.scripts[script](self, ...) end
    for _, callback in ipairs(self.hooks[script] or {}) do callback(self, ...) end
  end
  function value:EnableMouse(enabled) self.mouse = enabled end
  function value:SetPoint(...) self.points[#self.points + 1] = { ... } end
  function value:ClearAllPoints() self.points = {} end
  function value:SetAllPoints(target) self.allPoints = target or true end
  function value:SetSize(width, height) self.width, self.height = width, height end
  function value:SetWidth(width) self.width = width end
  function value:SetHeight(height) self.height = height end
  function value:GetWidth() return self.width end
  function value:GetHeight() return self.height end
  function value:SetFrameStrata(strata) self.strata = strata end
  function value:GetFrameStrata() return self.strata end
  function value:SetFrameLevel(level) self.level = level end
  function value:GetFrameLevel() return self.level end
  function value:SetClampedToScreen(value) self.clamped = value end
  function value:SetAlpha(alpha) self.alpha = alpha end
  function value:GetAlpha()
    if not self.alphaReadable then return { __bad = true } end
    return self.alpha
  end
  function value:SetShown(shown) if shown then self:Show() else self:Hide() end end
  function value:Show()
    if not self.shown then
      self.shown = true
      self:RunScript("OnShow")
    end
  end
  function value:Hide()
    if self.shown then
      self.shown = false
      self:RunScript("OnHide")
    end
  end
  function value:IsShown() return self.shown end
  function value:IsVisible()
    return self.shown and (not self.parent or self.parent:IsVisible())
  end
  function value:SetBackdrop(backdrop) self.backdrop = backdrop end
  function value:SetBackdropColor(...) self.backdropColor = { ... } end
  function value:SetBackdropBorderColor(...) self.backdropBorderColor = { ... } end
  function value:CreateAnimationGroup() return animationGroup(self) end

  return value
end

local function texture(parent)
  local value = object(parent)
  value.masks = {}
  function value:SetTexture(asset) self.texture = asset end
  function value:SetBlendMode(mode) self.blendMode = mode end
  function value:SetVertexColor(...) self.vertexColor = { ... } end
  function value:SetTexCoord(...) self.texCoord = { ... } end
  function value:AddMaskTexture(mask) self.masks[#self.masks + 1] = mask end
  parent.textures[#parent.textures + 1] = value
  return value
end

local function maskTexture(parent)
  local value = object(parent)
  function value:SetTexture(asset) self.texture = asset end
  function value:SetTexCoord(...) self.texCoord = { ... } end
  parent.maskTextures[#parent.maskTextures + 1] = value
  return value
end

CreateFrame = function(_, _, parent)
  local frame = object(parent)
  function frame:CreateTexture() return texture(self) end
  function frame:CreateMaskTexture() return maskTexture(self) end
  function frame:CreateFontString()
    local fontString = object(self)
    function fontString:SetText(text) self.text = text end
    function fontString:SetTextColor(...) self.textColor = { ... } end
    self.fontStrings[#self.fontStrings + 1] = fontString
    return fontString
  end
  frames[#frames + 1] = frame
  return frame
end

local function fireEvent(event, ...)
  for _, frame in ipairs(frames) do
    if frame.events[event] and frame.scripts.OnEvent then
      frame.scripts.OnEvent(frame, event, ...)
    end
    local callback = frame.eventCallbacks[event]
    if callback then callback(frame, ...) end
  end
end

local function hasRawEvent(event)
  for _, frame in ipairs(frames) do
    if frame.events[event] then return true end
  end
  return false
end

local function hasCallbackEvent(event)
  for _, frame in ipairs(frames) do
    if frame.eventCallbacks[event] then return true end
  end
  return false
end

EventRegistry = {
  RegisterCallback = function(_, event, callback, owner)
    EventRegistry[event] = { callback = callback, owner = owner }
  end,
}

C_Timer = {
  NewTimer = function(delay, callback)
    local timer = { delay = delay, callback = callback, cancelled = false }
    function timer:Cancel() self.cancelled = true end
    timers[#timers + 1] = timer
    return timer
  end,
  NewTicker = function(interval, callback)
    local ticker = { interval = interval, callback = callback, cancelled = false }
    function ticker:Cancel() self.cancelled = true end
    tickers[#tickers + 1] = ticker
    return ticker
  end,
}

local settings = {}
Settings = {
  VarType = { Boolean = "boolean", Number = "number", String = "string" },
  RegisterVerticalLayoutCategory = function()
    return { GetID = function() return 1 end }
  end,
  RegisterAddOnSetting = function(_, variable, key, tableRef, valueType, _, defaultValue)
    if tableRef[key] == nil then tableRef[key] = defaultValue end
    local setting = { variable = variable, key = key, tableRef = tableRef, valueType = valueType }
    function setting:SetValueChangedCallback(callback) self.callback = callback end
    function setting:GetValue() return self.tableRef[self.key] end
    function setting:SetValue(value)
      self.tableRef[self.key] = value
      if self.callback then self.callback(self, value) end
    end
    function setting:NotifyUpdate()
      if self.callback then self.callback(self, self.tableRef[self.key]) end
    end
    settings[variable] = setting
    return setting
  end,
  CreateCheckbox = function() end,
  CreateSlider = function() end,
  CreateSliderOptions = function() return {} end,
  CreateControlTextContainer = function()
    local container = { data = {} }
    function container:Add(value, label)
      self.data[#self.data + 1] = { value = value, label = label }
    end
    function container:GetData() return self.data end
    return container
  end,
  CreateDropdown = function(_, setting, getOptions) setting.options = getOptions() end,
  RegisterAddOnCategory = function() end,
  OpenToCategory = function() end,
  NotifyUpdate = function(variable)
    if settings[variable] then settings[variable]:NotifyUpdate() end
  end,
}

EventUtil = { ContinueOnAddOnLoaded = function(_, callback) callback() end }
geterrorhandler = function()
  return function(message) errors[#errors + 1] = message end
end

Minimap = object()
Minimap.width = 198
Minimap.height = 198
Minimap.strata = "LOW"
Minimap.level = 10
Minimap.zoom = 0
Minimap.zoomLevels = 6
Minimap.mask = "ThirdPartyMask"
Minimap.maskWrites = 0
function Minimap:SetMaskTexture(asset)
  self.mask = asset
  self.maskWrites = self.maskWrites + 1
end
function Minimap:GetZoom() return self.zoom end
function Minimap:GetZoomLevels() return self.zoomLevels end
function Minimap:SetZoom(value) self.zoom = value end
function Minimap:CreateTexture() return texture(self) end
Minimap:SetScript("OnMouseWheel", function(self, delta)
  if delta > 0 then
    self.zoom = math.min(self.zoom + 1, self.zoomLevels - 1)
  elseif delta < 0 then
    self.zoom = math.max(self.zoom - 1, 0)
  end
end)

local function alphaObject(alpha)
  local value = object()
  value.alpha = alpha
  return value
end

MinimapCompassTexture = alphaObject(0.8)
MinimapBackdrop = alphaObject(0.7)
MinimapCluster = { BorderTop = alphaObject(0.6) }

C_Minimap = { ShouldUseHybridMinimap = function() return hybrid end }
C_Housing = { IsInsideHouse = function() return housing end }

local nativeWidget = object(Minimap)
nativeWidget.level = 11

return {
  event = fireEvent,
  timers = timers,
  tickers = tickers,
  errors = errors,
  settings = settings,
  native = nativeWidget,
  hasRawEvent = hasRawEvent,
  hasCallbackEvent = hasCallbackEvent,
  setCombat = function(value) combat = value end,
  setHybrid = function(value) hybrid = value end,
  setHousing = function(value) housing = value end,
}
