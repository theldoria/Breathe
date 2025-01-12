
-- C:/home/tools/lua-5.1.5/lua5.1 load.lua

local Globals = {
   Functions = { },
   Variables = {
      C_Timer = {},
      C_UnitAuras = {},
   },
   SavedVariables = { }
}

function Globals.Functions.GetTime()
   return 0
end

local Libs = {
   ['AceAddon-3.0'] = {},
   ['AceConfig-3.0'] = {},
   ['AceConfigDialog-3.0'] = {},
   ['AceDB-3.0'] = {},
   ['AceDBOptions-3.0'] = {},
   ['AceLocale-3.0'] = {},
   ['AceEvent-3.0'] = {},
   ['AceConsole-3.0'] = {},
}
function Globals.Functions.LibStub(lib)
   return Libs[lib]
end
local AceLocale = Libs['AceLocale-3.0']
function AceLocale:GetLocale(addonName)
   local definedTable = self.defined['enUS']
   self.used = self.used or {}

   setmetatable(self.used, {
                   __index = function(t, key)
                      t[key] = true  -- Mark the key as used
                      if definedTable[key] then
                         return definedTable[key] -- Return the value from the defined table
                      else
                         return tostring(key) -- Fallback
                      end
                   end
   })

   return self.used
end
function AceLocale:NewLocale(addonName, language)
   self.defined = self.defined or {}
   self.defined[language] = {}
   return self.defined[language]
end
function AceLocale:Dump()
   for language, defines in pairs(self.defined) do
      for key, value in pairs(defines) do
         print(language, key, value)
      end
   end
   for key, value in pairs(self.used) do
      print(key, value)
   end
end

local Addon = {}
local AceAddon = Libs['AceAddon-3.0']
function AceAddon:NewAddon(addonName, ...)
   return Addon
end

local Timers = { realtime = false, list = {} }
function Globals.Variables.C_Timer.After(time, fkt)
   Timers:after(time, fkt)
end
function Globals.Variables.C_Timer.NewTicker(time, fkt)
   Timers:after(time, fkt)
end
function Timers:after(time, fkt)
   if self.realtime then
      -- Execute in realtime
      local start = os.time()
      local co = coroutine.create(function()
            while os.time() - start < time do
               coroutine.yield()
            end
            fkt()
            io.flush()
      end)
      table_insert(self.list, co)
      coroutine.resume(co)
   else
      -- Insert callbacks in list
      table_insert(self.list, {time = time, fkt = fkt})
   end
end
function Timers:wait()
   if self.realtime then
      -- Wait for timers to complete
      while #self.list > 0 do
         for i = #self.list, 1, -1 do
            if coroutine.status(self.list[i]) == 'dead' then
               table.remove(self.list, i)
            else
               coroutine.resume(self.list[i])
            end
         end
      end
   else
      -- Execute timer with lowest time
      while #self.list > 0 do
         local index
         local time
         for i, timer in ipairs(self.list) do
            if not index or timer.time and timer.time < time then
               index = i
               time = timer.time
            end
         end
         if index then
            local fkt = self.list[index].fkt
            if fkt then
               fkt()
               self.list[index].fkt = nil
            end
            table.remove(self.list, index)
         end
      end
   end
end
function Timers:reset()
   self.list = {}
end
function Timers:dump()
end

function Globals.Variables.C_UnitAuras.GetAuraDataByIndex(index)
   return nil
end

local SavedVariables = { 'BreatheDB' }

function SavedVariables:has_key(key)
   for index, value in ipairs(self) do
      if value == key then
         return index
      end
   end

   return false
end

setmetatable(Globals, {
                __index = function(_t, key)
                   if Globals.Functions[key] then
                      return Globals.Functions[key]
                   elseif Globals.Variables[key] then
                      return Globals.Variables[key]
                   elseif Globals.SavedVariables[key] then
                      -- Access loaded saved variable
                      return Globals.SavedVariables[key]
                   elseif SavedVariables:has_key(key) then
                      -- Access unloaded saved variable
                      return nil
                   elseif rawget(_G, key) then
                      return rawget(_G, key)
                   else
                      print('Access undefined global ' .. tostring(key))
                      return nil
                   end
                end,
                __newindex = function(t, key, value)
                   if Globals.Variables[key] ~= nil then
                      -- print('Change global ' .. tostring(t) .. ' ' .. tostring(key) .. ' = ' ..  tostring(value))
                      Globals.Variables[key] = value
                   elseif Globals.SavedVariables[key] then
                      -- print('Change saved variable ' .. tostring(t) .. ' ' .. tostring(key) .. ' = ' ..  tostring(value))
                      Globals.SavedVariables[key] = value
                   elseif SavedVariables:has_key(key) then
                      -- print('Set saved variable ' .. tostring(t) .. ' ' .. tostring(key) .. ' = ' ..  tostring(value))
                      Globals.SavedVariables[key] = value
                   else
                      error('New global ' .. tostring(t) .. ' ' .. tostring(key) .. ' = ' ..  tostring(value))
                      rawset(t, key, value)
                   end
                end
})

-- Function to read and process the toc file
local function processTocFile(addonName, directory, tocfilename, T, G)
   local env = setmetatable(G, { __index = Globals,
                                 __newindex = Globals })

   -- Open the file for reading
   local file = io.open(directory .. '/' .. tocfilename, 'r')
   if not file then
      error('Could not open file: ' .. tocfilename)
   end

   -- Read the file line by line
   for line in file:lines() do
      -- Trim leading and trailing whitespace
      line = line:match('^%s*(.-)%s*$')

      -- Skip empty lines and comments
      if line ~= '' and not line:match('^##') then
         -- Load .lua files
         if line:match('%.lua$') and not line:match('^Libs') then
            local filename = line
            local filepath = directory .. '/' .. filename
            local filechunk, loadError = loadfile(filepath)
            if not filechunk then
               print('Error loading file:', loadError)
            else
               setfenv(filechunk, env)
               local success, execError = pcall(filechunk, addonName, T)
               if not success then
                  print('Error executing file:', filename, execError)
                  print(debug.traceback())
               end
            end
         end
      end
   end

   -- Close the file
   file:close()
end

local addons = {}
local function loadAddon(addonName, directory)
   addons[addonName] = { T = {}, G = {} }
   processTocFile(addonName, directory, addonName .. '.toc', addons[addonName].T, addons[addonName].G)
end

loadAddon('Breathe', '..')
AceLocale:Dump()
