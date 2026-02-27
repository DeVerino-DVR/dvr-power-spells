fx_version 'cerulean'
game 'gta5'
author 'VLight'
description 'Putrefactio Spell Module for dvr_power'
version '1.0.0'

shared_scripts {
    -- '@ox_lib/init.lua', -- REQUIRED: Install ox_lib (https://github.com/overextended/ox_lib)
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}
