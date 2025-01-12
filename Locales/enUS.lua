--- -*- mode: lua; -*-
local addonName, _T = ...

local AceLocale = LibStub('AceLocale-3.0')
local L = AceLocale:NewLocale(addonName, 'enUS', true)

L['Comma-separated list of spell IDs to monitor.'] = 'Comma-separated list of spell IDs to monitor, e.g. 5384.'
L['Spell '] = 'Spell '
L['Spell IDs'] = 'Spell IDs'
L['Time in seconds before spell/aura would expire.'] = 'Time in seconds before spell/aura would expire.'
L['Time to Alert'] = 'Time to Alert'
L['Time to Cancel'] = 'Time to Cancel'
L['Profiles'] = 'Profiles'
L[' cancelled.'] = ' cancelled.'
L['General Settings'] = 'General Settings'
L['Animation Settings'] = 'Animation Settings'
L['Border Color'] = 'Border Color'
L['Select the border color.'] = 'Select the border color.'
L['Fade In Alpha'] = 'Fade In Alpha.'
L['Set the alpha value for fade in.'] = 'Set the alpha value for fade in.'
L['Fade Out Alpha'] = 'Fade Out Alpha.'
L['Set the alpha value for fade out.'] = 'Set the alpha value for fade out.'
L['Pulse Duration'] = 'Duration'
L['Set the duration of the pulse animation.'] = 'Set the duration of the pulse animation.'
