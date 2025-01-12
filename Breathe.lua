local addonName, _T = ...

local AceAddon = LibStub('AceAddon-3.0')
local AceConfig = LibStub('AceConfig-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')
local AceDB = LibStub('AceDB-3.0')
local AceDBOptions = LibStub('AceDBOptions-3.0')
local AceLocale = LibStub('AceLocale-3.0')

local Breathe = AceAddon:NewAddon('Breathe', 'AceEvent-3.0', 'AceConsole-3.0')
local L = AceLocale:GetLocale('Breathe')

local defaults = {
   profile = {
      time = 300,               -- Time in s, defaults to 5 minutes
      alertTime = 340,          -- Time in s
      spellIds = {5384},        -- Default to hunter ability Feign Death
      cancelOnReload = true,    -- Cancel spells on reload
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
         time = {
            type = 'range',
            name = L['Time to Cancel'],
            desc = L['Time in seconds before spell is cancelled.'],
            descStyle = 'inline',
            min = 1,
            softMin = 10,
            max = 359,
            softMax = 350,
            step = 1,
            get = function(_info) return self.db.profile.time end,
            set = function(_info, value) self.db.profile.time = value end,
            order = 1,
         },
         alertTime = {
            type = 'range',
            name = L['Time to Alert'],
            desc = L['Time in seconds before a read alert is shown.'],
            descStyle = 'inline',
            min = 1,
            softMin = 1,
            max = 360,
            softMax = 350,
            step = 1,
            get = function(_info) return self.db.profile.alertTime end,
            set = function(_info, value) self.db.profile.alertTime = value end,
            order = 2,
         },
         spellIds = {
            type = 'input',
            name = L['Spell IDs'],
            desc = L['Comma-separated list of spell IDs to monitor.'],
            descStyle = 'inline',
            get = function(_info) return table.concat(self.db.profile.spellIds, ', ') end,
            set = function(_info, value)
               local ids = {}
               for id in string.gmatch(value, '%d+') do
                  table.insert(ids, tonumber(id))
               end
               self.db.profile.spellIds = ids
            end,
            order = 3
         },
         cancelOnReload = {
            type = 'toggle',
            name = L['Cancel Spells on Reload'],
            desc = L['Cancel monitored spells when the UI is reloaded.'],
            get = function(_info) return self.db.profile.cancelOnReload end,
            set = function(_info, value) self.db.profile.cancelOnReload = value end,
            order = 4,
         },
      },
   }

   AceConfig:RegisterOptionsTable('Breathe_Options', options)
   self.optionsFrame = AceConfigDialog:AddToBlizOptions('Breathe_Options', 'Breathe')

   self.optionsFrame.profiles = AceDBOptions:GetOptionsTable(self.db)
   AceConfig:RegisterOptionsTable('Breathe_Profiles', self.optionsFrame.profiles)
   AceConfigDialog:AddToBlizOptions('Breathe_Profiles', L['Profiles'], 'Breathe')
end

function Breathe:OnEnable()
   self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
   if self.db.profile.cancelOnReload then
      -- Maybe someone reloaded with an active aura... better cancel it immediatly...
      Breathe:CancelSpells()
   end
end

function Breathe:OnDisable()
   self:UnregisterAllEvents()
end

local function CreatePulseFrame()
   local frame = CreateFrame('Frame', 'BreathePulseFrame', UIParent)
   frame:SetFrameStrata('BACKGROUND')
   frame:SetWidth(UIParent:GetWidth())
   frame:SetHeight(UIParent:GetHeight())
   frame:SetPoint('CENTER', UIParent, 'CENTER')
   frame.texture = frame:CreateTexture(nil, 'BACKGROUND')
   frame.texture:SetAllPoints(frame)
   frame.texture:SetColorTexture(1, 0, 0, 0.5) -- Red color with 50% opacity

   local ag = frame:CreateAnimationGroup()
   local pulse = ag:CreateAnimation('Alpha')
   pulse:SetFromAlpha(0.5)
   pulse:SetToAlpha(1)
   pulse:SetDuration(0.5)
   pulse:SetSmoothing('IN_OUT')
   pulse:SetOrder(1)

   local pulseBack = ag:CreateAnimation('Alpha')
   pulseBack:SetFromAlpha(1)
   pulseBack:SetToAlpha(0.5)
   pulseBack:SetDuration(0.5)
   pulseBack:SetSmoothing('IN_OUT')
   pulseBack:SetOrder(2)

   ag:SetLooping('REPEAT')
   ag:Play()

   frame:Hide()
   return frame
end

local pulseFrame = CreatePulseFrame()

function Breathe:UNIT_SPELLCAST_SUCCEEDED(_event, unit, _, spellId)
   if unit == 'player' and tContains(self.db.profile.spellIds, spellId) then
      C_Timer.After(self.db.profile.time, function()
                       self:CancelSpell(spellId)
      end)
      C_Timer.After(self.db.profile.alertTime, function()
                       self:AlertSpell(spellId)
      end)

      local spellName = GetSpellInfo(spellId)
      self:Print(L['Spell '] .. spellName .. L[' will be cancelled after '] .. self.db.profile.time .. L[' seconds.'])
   end
end

function Breathe:CancelSpells()
   for i = 1, 40 do
      local spellName, _, _, _, _, _, _, _, _, buffSpellId = UnitBuff('player', i)
      if buffSpellId then
         if tContains(self.db.profile.spellIds, buffSpellId) then
            CancelUnitBuff('player', i)
            self:Print(L['Spell '] .. spellName .. L[' cancelled.'])
         end
      else
         break
      end
   end
end

function Breathe:AlertSpell(spellId)
   for i = 1, 40 do
      local _spellName, _, _, _, _, _, _, _, _, buffSpellId = UnitBuff('player', i)
      if buffSpellId then
         if buffSpellId == spellId then
            pulseFrame:Show()
            break
         end
      else
         break
      end
   end
end

function Breathe:CancelSpell(spellId)
   for i = 1, 40 do
      local spellName, _, _, _, _, _, _, _, _, buffSpellId = UnitBuff('player', i)
      if buffSpellId then
         if buffSpellId == spellId then
            CancelUnitBuff('player', i)
            self:Print(L['Spell '] .. spellName .. L[' cancelled.'])
         end
      else
         break
      end
   end
   pulseFrame:Hide()
end

