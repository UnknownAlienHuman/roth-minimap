local E=dofile("tests/runtime_stubs_env.lua")
local event,timers,tickers,settings,native=E.event,E.timers,E.tickers,E.settings,E.native
local function setCombat(v) E.setCombat(v) end

local legacy={version=18,enabled=true,square=false,hideBlizzardArt=true,skinEnabled=false,
 visual={border={alpha=.75,color={.2,.3,.4}},runes={enabled=true,outAlpha=.25,color={.9,.5,.1}},vignette={enabled=false,alpha=.15}},
 fire={enabled=true,outAlpha=.11,combatAlpha=.55,outFPS=2,combatFPS=9},
 ping={enabled=true,where="chat",duration=4,sound=true},zoom={mousewheel=true,autoReset=true,delay=4,mode="smooth"}}
RothMinimapDB=legacy
local ns={};assert(loadfile("RothMinimap.lua"))("RothMinimap",ns)
assert(ns.db==legacy and ns.db.version==6 and ns.db.squareMask==false and ns.db.skin.enabled==false)
assert(ns.db.skin.borderColor[1]==.2 and ns.db.skin.borderColor[4]==.75 and ns.db.skin.runesColor[4]==.25)
assert(ns.db.skin.vignette==false and ns.db.skin.vignetteAlpha==.15 and ns.db.skin.fireFPS==9)
assert(ns.db.ping.where=="chat" and ns.db.ping.duration==4 and ns.db.ping.sound==nil)
assert(ns.db.visual==nil and ns.db.fire==nil and ns.db.skinEnabled==nil and _G.RothMinimap==nil)
for _,p in ipairs{"modules/Skin.lua","modules/Ping.lua","modules/Zoom.lua","Options.lua"}do assert(loadfile(p))("RothMinimap",ns)end
assert(settings.ROTH_MINIMAP_PING_WHERE and #settings.ROTH_MINIMAP_PING_WHERE.options==2)

ns.db.enabled=true;ns.db.squareMask=true;ns.db.skin.enabled=true;ns.db.skin.border=true;ns.db.skin.runes=true;ns.db.skin.vignette=true;ns.db.skin.fire=true;ns.db.ping.enabled=true;ns.db.ping.where="toast";ns.db.zoom.autoReset=true
assert(ns.ApplyAll());assert(Minimap.mask:find("mask_square.tga",1,true));assert(MinimapCompassTexture.alpha==0 and MinimapCluster.BorderTop.alpha==0 and MinimapBackdrop.alpha==.7)
assert(ns.skin.frame:GetFrameStrata()=="LOW" and ns.skin.frame:GetFrameLevel()==10 and ns.skin.frame:GetFrameLevel()<native:GetFrameLevel())
assert(#tickers>0 and not tickers[#tickers].cancelled)
MinimapCompassTexture.alpha=.35;assert(ns.ApplyAll());ns.db.hideBlizzardArt=false;assert(ns.ApplyAll());assert(MinimapCompassTexture.alpha==.35)

Minimap.zoom=1;Minimap:RunScript("OnMouseWheel",1);assert(Minimap.zoom==1);local z=timers[#timers];assert(z.delay==4 and not z.cancelled);assert(ns.ApplyAll() and not z.cancelled);z.callback();assert(Minimap.zoom==0)
local secret=setmetatable({},{__tostring=function()error("secret")end,__eq=function()error("secret")end,__index=function()error("secret")end})
event("MINIMAP_PING",secret,secret,secret);assert(ns.ping.toast and ns.ping.toast:IsShown())
ns.skin:Pulse();ns.skin.pulseGroup:Stop();assert(not ns.skin.pulseGroup.owner:IsShown() and ns.skin.pulseGroup.owner:GetAlpha()==0)
local ticker=tickers[#tickers];ns.skin.frame:Hide();assert(ticker.cancelled)

ns.skin.frame:Show();ns.db.skin.fire=false;setCombat(true);assert(ns.ApplyAll()==false);assert(not ns.skin.frame.textures[3]:IsShown() and ns.GetStatus().pendingApply);setCombat(false);event("PLAYER_REGEN_ENABLED");assert(not ns.GetStatus().pendingApply)
local n=#timers;ns.QueueRefresh(false);ns.QueueRefresh(false);ns.QueueRefresh(true);assert(#timers==n+1);timers[#timers].callback()

local root,skin,ping,zoom=ns.db,ns.db.skin,ns.db.ping,ns.db.zoom;local real,count=ns.ApplyAll,0;ns.ApplyAll=function(...)count=count+1;return real(...)end
assert(ns.ResetDB() and count==1);assert(ns.db==root and ns.db.skin==skin and ns.db.ping==ping and ns.db.zoom==zoom and ns.db.version==6)

RothMinimapDB={version=5,enabled="bad",skin={fireFPS=99,outset=-4,borderColor={2,-1,.5,.2}},ping={where="bad",duration=0},zoom={autoReset=false,delay=99}}
local ns2={};assert(loadfile("RothMinimap.lua"))("RothMinimap",ns2);assert(ns2.db.version==6 and ns2.db.enabled==true and ns2.db.skin.fireFPS==20 and ns2.db.skin.outset==0);assert(ns2.db.ping.where=="toast" and ns2.db.ping.duration==1 and ns2.db.zoom.delay==10)
RothMinimapDB="corrupt";local ns3={};assert(loadfile("RothMinimap.lua"))("RothMinimap",ns3);assert(type(ns3.db)=="table" and ns3.db.version==6 and ns3.db.skin.fireFPS==8)
print("PASS: migration, direct events, draw order, visibility, zoom, combat deferral and Settings reset")
