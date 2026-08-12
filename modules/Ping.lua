-- Roth Minimap - Ping notification
--
-- Listens for MINIMAP_PING and shows a small toast under the minimap.
-- Optional sound is intentionally neutral (no chat/whisper alarm).

local ADDON, ns = ...

ns.ping = ns.ping or {}
local M = ns.ping

local toast, text
local ag, fadeIn, hold, fadeOut

local function ensureToast()
  if toast then return end

  toast = CreateFrame("Frame", "RothMinimapPingToast", UIParent, "BackdropTemplate")
  toast:SetSize(220, 42)
  toast:SetFrameStrata("HIGH")
  toast:SetFrameLevel(300)
  toast:SetPoint("TOP", Minimap, "BOTTOM", 0, -8)

  toast:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  toast:SetBackdropColor(0, 0, 0, 0.60)
  toast:SetBackdropBorderColor(1, 1, 1, 0.15)
  toast:Hide()

  text = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("CENTER", toast, "CENTER", 0, 0)
  text:SetJustifyH("CENTER")
  text:SetText("")

  ag = toast:CreateAnimationGroup()
  fadeIn = ag:CreateAnimation("Alpha")
  fadeIn:SetOrder(1)
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(0.10)

  hold = ag:CreateAnimation("Alpha")
  hold:SetOrder(2)
  hold:SetFromAlpha(1)
  hold:SetToAlpha(1)
  hold:SetDuration(2.50)

  fadeOut = ag:CreateAnimation("Alpha")
  fadeOut:SetOrder(3)
  fadeOut:SetFromAlpha(1)
  fadeOut:SetToAlpha(0)
  fadeOut:SetDuration(0.35)

  ag:SetScript("OnFinished", function()
    toast:Hide()
  end)
end

local function showToast(msg, dur)
  ensureToast()
  text:SetText(msg)
  toast:Show()
  ag:Stop()
  hold:SetDuration(dur or 3.0)
  ag:Play()
end

local function playPingSound()
  if not (PlaySound and SOUNDKIT) then return end
  -- Avoid 'tell message' style alarm; prefer neutral UI ping if available.
  local kit = SOUNDKIT.MAP_PING or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPEN
  if kit then
    pcall(PlaySound, kit, "Master")
  end
end

local function onPing(_, unit)
  local db = ns.db and ns.db.ping
  if not (db and db.enabled) then return end

  local name = UnitName(unit) or "?"
  local msg = name .. " ping"

  if db.where == "chat" then
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPing:|r " .. msg)
  else
    showToast(msg, db.duration)
  end

  if ns.skin and ns.skin.Pulse then
    ns.skin:Pulse("ping")
  end

  if db.sound then
    playPingSound()
  end
end

function M:Apply()
  local db = ns.db and ns.db.ping
  if not db then return end

  if db.enabled then
    if not self._registered then
      ns.RegisterEvent("MINIMAP_PING", onPing)
      self._registered = true
    end
  else
    if self._registered then
      ns.UnregisterEvent("MINIMAP_PING", onPing)
      self._registered = false
    end
  end
end

function M:Disable()
  if self._registered then
    ns.UnregisterEvent("MINIMAP_PING", onPing)
    self._registered = false
  end
  if toast then toast:Hide() end
end
