-- -*- mode: lua; -*-

-- https://luacheck.readthedocs.io/en/stable/config.html
-- luacheck .

ignore = {
   '211/_.*',                   -- Ignore unused variables starting with '_'
   '212/_.*',                   -- Ignore unused arguments starting with '_'
   '212/self',                  -- Ignore unused 'self' arguments
}

exclude_files = {
   'Libs/**/*.lua',
}

max_line_length = 180
codes = true                    -- Show error codes

stds.wow = {
   globals = { -- these globals can be set and accessed.
   },

   read_globals = { -- these globals can only be accessed.
      'GetTime',
      'C_Timer',
      'C_UnitAuras',
      'CancelUnitBuff',
      'CreateFrame',
      'GetAddOnMetadata',
      'GetSpellInfo',
      'LibStub',
      'tContains',
      'UIParent',
      'UnitBuff',
   }
}

stds.wow_lua = {
   read_globals = {
      '_VERSION',
      'ipairs',
      'pairs',
      'pcall',
      'print',
      'string',
      'tonumber',
      'tostring',
      'unpack',
      table = { fields = { 'concat', 'insert', 'remove' } },
   }
}

std = {} -- 'lua51'
files['*.lua'].std = 'wow+wow_lua'
files['Locales/*.lua'].std = 'wow+wow_lua'
