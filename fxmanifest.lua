fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'piercer_entdebug'
author 'PIERCER (FrameZero) - discord.gg/jZ3vTmdjU7'
version '1.1.0'
description 'Find out what is behind "Tried to access invalid entity" errors on your FiveM server'

-- Permissão e notificação ficam com a framezero_bridge
-- (ESX, QBCore, Qbox, vRP, vRPex, Creative ou standalone).
dependency 'framezero_bridge'

shared_scripts {
    'config.lua',
}

server_scripts {
    '@framezero_bridge/import.lua',
    'server.lua',
}
