fx_version 'cerulean'
game 'gta5'
author 'VLight'
description 'Transplanner Spell Module - Teleportation with Ghost Mode'
version '1.0.0'

shared_scripts {
    -- '@ox_lib/init.lua', -- REQUIRED: Install ox_lib (https://github.com/overextended/ox_lib)
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/menu.lua'
}

server_scripts {
    'server/main.lua'
}
