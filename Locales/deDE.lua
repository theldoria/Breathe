local AceLocale = LibStub('AceLocale-3.0')
local L = AceLocale:NewLocale('Breathe', 'deDE')

if not L then return end

L[' cancelled'] = ' abgebrochen.'
L[' seconds.'] = ' Sekunden.'
L[' will be cancelled after '] = ' wird abgebrochen nach '
L['Cancel monitored spells when the UI is reloaded.'] = 'Breche überwachte Zauber beim Laden der Oberfläche ab.'
L['Cancel Spells on Reload'] = 'Zauberabbruch beim Laden'
L['Comma-separated list of spell IDs to monitor.'] = 'Kommagetrennte Liste der zu überwachenden Zauber-IDs, z.B. 5384.'
L['Don\'t forget to breathe!'] = 'Vergiss nicht zu atmen!'
L['Spell '] = 'Zauber '
L['Spell IDs'] = 'Zauber-IDs'
L['Time in seconds before a read alert is shown.'] = 'Zeit in Sekunden, bevor ein rot pulsierender Alarm gezeigt wird.'
L['Time in seconds before spell is cancelled.'] = 'Zeit in Sekunden, bevor die Aura abgebrochen wird.'
L['Time to Alert'] = 'Zeit bis zum Alarm'
L['Time to Cancel'] = 'Zeit bis zum Abbrechen'
