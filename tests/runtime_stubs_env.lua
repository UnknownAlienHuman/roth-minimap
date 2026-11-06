local frames,timers,tickers={}, {}, {}
local combat=false
canaccessvalue=function(v)return not(type(v)=="table" and rawget(v,"__bad"))end
canaccesstable=canaccessvalue
InCombatLockdown=function()return combat end
DEFAULT_CHAT_FRAME={AddMessage=function()end}; SlashCmdList={}

local function animGroup(owner)
  local g={owner=owner,scripts={},playing=false}
  function g:CreateAnimation() local a={values={}};return setmetatable(a,{__index=function(t,k)return function(_,v)t.values[k]=v end end}) end
  function g:SetScript(k,v)self.scripts[k]=v end
  function g:Play()self.playing=true;if self.scripts.OnPlay then self.scripts.OnPlay(self)end end
  function g:Stop()self.playing=false;if self.scripts.OnStop then self.scripts.OnStop(self)end end
  return g
end
local function object(parent)
  local o={parent=parent,scripts={},hooks={},events={},textures={},shown=true,alpha=1,width=0,height=0,strata="MEDIUM",level=0}
  function o:CanBeAccessedInContext()return true end; function o:IsForbidden()return false end
  function o:RegisterEvent(e)self.events[e]=true end; function o:UnregisterEvent(e)self.events[e]=nil end
  function o:SetScript(k,v)self.scripts[k]=v end
  function o:HookScript(k,v)local h=self.hooks[k]or{};h[#h+1]=v;self.hooks[k]=h end
  function o:RunScript(k,...)if self.scripts[k]then self.scripts[k](self,...)end;for _,f in ipairs(self.hooks[k]or{})do f(self,...)end end
  function o:EnableMouse(v)self.mouse=v end; function o:SetPoint(...)self.point={...}end; function o:SetAllPoints(v)self.all=v or true end
  function o:SetSize(w,h)self.width,self.height=w,h end; function o:GetWidth()return self.width end; function o:GetHeight()return self.height end
  function o:SetFrameStrata(v)self.strata=v end; function o:GetFrameStrata()return self.strata end
  function o:SetFrameLevel(v)self.level=v end; function o:GetFrameLevel()return self.level end
  function o:SetAlpha(v)self.alpha=v end; function o:GetAlpha()return self.alpha end
  function o:SetShown(v)if v then self:Show()else self:Hide()end end
  function o:Show()if not self.shown then self.shown=true;self:RunScript("OnShow")end end
  function o:Hide()if self.shown then self.shown=false;self:RunScript("OnHide")end end
  function o:IsShown()return self.shown end; function o:IsVisible()return self.shown and(not self.parent or self.parent:IsVisible())end
  function o:SetBackdrop(v)self.backdrop=v end; function o:SetBackdropColor(...)self.bg={...}end; function o:SetBackdropBorderColor(...)self.edge={...}end
  function o:CreateAnimationGroup()return animGroup(self)end
  return o
end
local function texture(parent)local t=object(parent);function t:SetTexture(v)self.texture=v end;function t:SetBlendMode(v)self.blend=v end;function t:SetVertexColor(...)self.color={...}end;function t:SetTexCoord(...)self.coord={...}end;parent.textures[#parent.textures+1]=t;return t end
CreateFrame=function(_,_,parent)local f=object(parent);function f:CreateTexture()return texture(self)end;function f:CreateFontString()local s=object(self);function s:SetText(v)self.text=v end;return s end;frames[#frames+1]=f;return f end
local function event(name,... )for _,f in ipairs(frames)do if f.events[name]and f.scripts.OnEvent then f.scripts.OnEvent(f,name,...)end end end
EventRegistry={RegisterCallback=function(_,n,cb,owner)EventRegistry[n]={cb=cb,owner=owner}end}
C_Timer={
 NewTimer=function(d,cb)local t={delay=d,callback=cb};function t:Cancel()self.cancelled=true end;timers[#timers+1]=t;return t end,
 NewTicker=function(d,cb)local t={interval=d,callback=cb};function t:Cancel()self.cancelled=true end;tickers[#tickers+1]=t;return t end,
}
local settings={}
Settings={VarType={Boolean="boolean",Number="number",String="string"},
 RegisterVerticalLayoutCategory=function()return{GetID=function()return 1 end}end,
 RegisterAddOnSetting=function(_,var,key,tbl,typ,_,default)if tbl[key]==nil then tbl[key]=default end;local s={var=var,key=key,tbl=tbl,typ=typ};function s:SetValueChangedCallback(cb)self.cb=cb end;function s:NotifyUpdate()if self.cb then self.cb(self,self.tbl[self.key])end end;settings[var]=s;return s end,
 CreateCheckbox=function()end,CreateSlider=function()end,CreateSliderOptions=function()return{}end,
 CreateControlTextContainer=function()local c={data={}};function c:Add(v,l)self.data[#self.data+1]={value=v,label=l}end;function c:GetData()return self.data end;return c end,
 CreateDropdown=function(_,s,get)s.options=get()end,RegisterAddOnCategory=function()end,OpenToCategory=function()end,
 NotifyUpdate=function(v)if settings[v]then settings[v]:NotifyUpdate()end end}
EventUtil={ContinueOnAddOnLoaded=function(_,cb)cb()end};geterrorhandler=function()return function(e)error(e,0)end end

Minimap=object();Minimap.width=198;Minimap.height=198;Minimap.strata="LOW";Minimap.level=10;Minimap.zoom=0;Minimap.zoomLevels=6
function Minimap:SetMaskTexture(v)self.mask=v end;function Minimap:GetZoom()return self.zoom end;function Minimap:GetZoomLevels()return self.zoomLevels end;function Minimap:SetZoom(v)self.zoom=v end;function Minimap:CreateTexture()return texture(self)end
local function alpha(v)local o=object();o.alpha=v;return o end
MinimapCompassTexture=alpha(.8);MinimapBackdrop=alpha(.7);MinimapCluster={BorderTop=alpha(.6)}
local native=object(Minimap);native.level=11


return {event=event,timers=timers,tickers=tickers,settings=settings,native=native,setCombat=function(v)combat=v end}
