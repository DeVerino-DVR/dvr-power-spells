fx_version 'cerulean'
game 'gta5'
author 'VLight'
description 'Ravivio Spell Module - Revive Dead Players'
version '1.0.0'

shared_scripts {
    -- '@ox_lib/init.lua', -- REQUIRED: Install ox_lib (https://github.com/overextended/ox_lib)
    -- '@es_extended/imports.lua', -- REQUIRED: Install es_extended or your framework
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}
