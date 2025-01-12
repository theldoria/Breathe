local addonName, _T = ...

local After = C_Timer.After
local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex
local GetTime = GetTime
local NewTicker = C_Timer.NewTicker

local AceAddon = LibStub('AceAddon-3.0')
local AceConfig = LibStub('AceConfig-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')
local AceDB = LibStub('AceDB-3.0')
local AceDBOptions = LibStub('AceDBOptions-3.0')
local AceLocale = LibStub('AceLocale-3.0')
local L = AceLocale:GetLocale(addonName)

local Breathe = AceAddon:NewAddon(addonName, 'AceEvent-3.0', 'AceConsole-3.0')

local defaults = {
   profile = {
      general = {
         cancelTime = 5,           -- Time in s
         alertTime = 10,           -- Time in s
         spellIds = {5384},        -- Default to hunter ability Feign Death
         cancelOnReload = true,    -- Cancel spells on reload
      },
      animation = {
         borderColor = {1, 1, 0, 0.5}, -- Default to yellow with 50% alpha
         fadeInAlpha = 0.5,
         fadeOutAlpha = 1,
         pulseDuration = 0.5,
      },
   },
}

function Breathe:OnInitialize()
   self.db = AceDB:New('BreatheDB', defaults, true)

   local options = {
      name = addonName .. ' v' .. GetAddOnMetadata(addonName, 'Version'),
      descStyle = 'inline',
      handler = Breathe,
      type = 'group',
      args = {
         general = {
            type = 'group',
            name = L['General Settings'],
            order = 1,
            args = {
               cancelTime = {
                  type = 'range',
                  name = L['Time to Cancel'],
                  desc = L['Time in seconds before spell/aura would expire.'],
                  min = 2,
                  softMin = 5,
                  max = 360,
                  softMax = 360,
                  step = 1,
                  get = function(_info) return self.db.profile.general.cancelTime end,
                  set = function(_info, value) self.db.profile.general.cancelTime = value end,
                  order = 1,
               },
               alertTime = {
                  type = 'range',
                  name = L['Time to Alert'],
                  desc = L['Time in seconds before spell/aura would expire.'],
                  min = 0,
                  softMin = 0,
                  max = 360,
                  softMax = 360,
                  step = 1,
                  get = function(_info) return self.db.profile.general.alertTime end,
                  set = function(_info, value) self.db.profile.general.alertTime = value end,
                  order = 2,
               },
               spellIds = {
                  type = 'input',
                  name = L['Spell IDs'],
                  desc = L['Comma-separated list of spell IDs to monitor.'],
                  get = function(_info) return table.concat(self.db.profile.general.spellIds, ', ') end,
                  set = function(_info, value)
                     local ids = {}
                     for id in string.gmatch(value, '%d+') do
                        table.insert(ids, tonumber(id))
                     end
                     self.db.profile.general.spellIds = ids
                  end,
                  order = 3
               },
            },
         },
         animation = {
            type = 'group',
            name = L['Animation Settings'],
            order = 2,
            args = {
               borderColor = {
                  type = 'color',
                  name = L['Border Color'],
                  desc = L['Select the border color.'],
                  get = function(_info)
                     local r, g, b, a = unpack(self.db.profile.animation.borderColor)
                     return r, g, b, a
                  end,
                  set = function(_info, r, g, b, a)
                     self.db.profile.animation.borderColor = {r, g, b, a}
                  end,
                  hasAlpha = true,
                  order = 1,
               },
               fadeInAlpha = {
                  type = 'range',
                  name = L['Fade In Alpha'],
                  desc = L['Set the alpha value for fade in.'],
                  min = 0,
                  max = 1,
                  step = 0.01,
                  get = function(_info) return self.db.profile.animation.fadeInAlpha end,
                  set = function(_info, value)
                     self.db.profile.animation.fadeInAlpha = value
                  end,
                  order = 2,
               },
               fadeOutAlpha = {
                  type = 'range',
                  name = L['Fade Out Alpha'],
                  desc = L['Set the alpha value for fade out.'],
                  min = 0,
                  max = 1,
                  step = 0.01,
                  get = function(_info) return self.db.profile.animation.fadeOutAlpha end,
                  set = function(_info, value)
                     self.db.profile.animation.fadeOutAlpha = value
                  end,
                  order = 3,
               },
               pulseDuration = {
                  type = 'range',
                  name = L['Pulse Duration'],
                  desc = L['Set the duration of the pulse animation.'],
                  min = 0.1,
                  max = 5,
                  step = 0.1,
                  get = function(_info) return self.db.profile.animation.pulseDuration end,
                  set = function(_info, value)
                     self.db.profile.animation.pulseDuration = value
                  end,
                  order = 4,
               },
            },
         },
      },
   }

   AceConfig:RegisterOptionsTable('Breathe_Options', options)
   self.optionsFrame = AceConfigDialog:AddToBlizOptions('Breathe_Options', 'Breathe')

   self.optionsFrame.profiles = AceDBOptions:GetOptionsTable(self.db)
   AceConfig:RegisterOptionsTable('Breathe_Profiles', self.optionsFrame.profiles)
   AceConfigDialog:AddToBlizOptions('Breathe_Profiles', L['Profiles'], 'Breathe')
end

local function CreatePulseFrame()
   local frame = CreateFrame('Frame', 'BreathePulseFrame', UIParent)
   frame:Hide()
   frame:SetFrameStrata('BACKGROUND')
   frame:SetWidth(UIParent:GetWidth())
   frame:SetHeight(UIParent:GetHeight())
   frame:SetPoint('CENTER', UIParent, 'CENTER')

   frame.texture = frame:CreateTexture(nil, 'BACKGROUND')
   frame.texture:SetAllPoints(frame)
   frame.texture:SetTexture('Interface\\AddOns\\Breathe\\assets\\border.png') -- Path to your image file

   -- Set the initial color from the database
   frame.texture:SetVertexColor(unpack(Breathe.db.profile.animation.borderColor))

   local ag = frame:CreateAnimationGroup()
   local pulse = ag:CreateAnimation('Alpha')
   pulse:SetFromAlpha(Breathe.db.profile.animation.fadeInAlpha)
   pulse:SetToAlpha(Breathe.db.profile.animation.fadeOutAlpha)
   pulse:SetDuration(Breathe.db.profile.animation.pulseDuration)
   pulse:SetSmoothing('IN_OUT')
   pulse:SetOrder(1)

   local pulseBack = ag:CreateAnimation('Alpha')
   pulseBack:SetFromAlpha(Breathe.db.profile.animation.fadeOutAlpha)
   pulseBack:SetToAlpha(Breathe.db.profile.animation.fadeInAlpha)
   pulseBack:SetDuration(Breathe.db.profile.animation.pulseDuration)
   pulseBack:SetSmoothing('IN_OUT')
   pulseBack:SetOrder(2)

   ag:SetLooping('REPEAT')

   frame:SetScript('OnShow', function()
                      Breathe.alertRunning = true
                      ag:Play()
   end)

   frame:SetScript('OnHide', function()
                      ag:Stop()
                      Breathe.alertRunning = false
   end)

   return frame
end

local function checkAurasRaw()
   Breathe:CheckAuras(false, false)
end

local function checkAuras()
   local success, err = pcall(checkAurasRaw)
   if not success then
      Breathe:Print('|cnRED_FONT_COLOR:error|r', err)
   end
end

function Breathe:checkAfter(category, after, expirationTime)
   -- self:Print('checkAfter', category, after, expirationTime, self.timer[category][expirationTime])
   if not self.timer[category][expirationTime] then
      self.timer[category][expirationTime] = After(after, checkAuras)
   end
end

function Breathe:removeCheckAfter(category, expirationTime)
   -- self:Print('removeCheckAfter', category, expirationTime, self.timer[category][expirationTime])
   self.timer[category][expirationTime] = nil
end

function Breathe:CheckAuras(setTimer, log)
   local currentTime = GetTime()
   local alertTime = self.db.profile.general.alertTime
   local cancelTime = self.db.profile.general.cancelTime
   local spellIds = self.db.profile.general.spellIds

   local alert = 0
   for index = 1, 40 do
      local aura = GetAuraDataByIndex('player', index)
      if not aura then
         break
      end
      local relevant  = tContains(spellIds, aura.spellId)
      if log then
         -- self:Print(L['Spell '] .. aura.name, aura.spellId, relevant)
      end
      if relevant then
         local remainingTime = aura.expirationTime - currentTime
         if remainingTime <= alertTime then
            alert = alert + 1
            Breathe:removeCheckAfter('alert', aura.expirationTime)
         elseif setTimer then
            Breathe:checkAfter('alert', remainingTime - alertTime, aura.expirationTime)
         end
         if remainingTime <= cancelTime then
            CancelUnitBuff('player', index)
            self:Print(L['Spell '] .. aura.name .. L[' cancelled.'])
            alert = alert - 1
            Breathe:removeCheckAfter('cancel', aura.expirationTime)
         elseif setTimer then
            Breathe:checkAfter('cancel', remainingTime - cancelTime, aura.expirationTime)
         end
      end
   end

   if alert > 0 then
      Breathe.pulseFrame:Show()
   elseif Breathe.alertRunning then
      Breathe.pulseFrame:Hide()
   end
end

function Breathe:OnEnable()
   Breathe.pulseFrame = CreatePulseFrame()

   local CHECK_INTERVAL = 1 -- Check every 1 second as a safety net
   self.timer = {
      cyclic = NewTicker(CHECK_INTERVAL, checkAuras),
      alert = {},
      cancel = {}
   }

   self:RegisterEvent('UNIT_AURA')

   -- Do initial check (after reload there might be existing auras)
   Breathe:CheckAuras(true, true)
end

function Breathe:UNIT_AURA(_event, unit, _info)
   if unit == 'player' then
      Breathe:CheckAuras(true, true)
   end
end

function Breathe:OnDisable()
   self:CancelAllTimers()
   self:UnregisterAllEvents()
end
