fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dvr_silencis'
author 'Thorn Hollow'
version '1.0.0'
description 'Silencis spell module - Mute target voice (mute voix RP)'

shared_scripts {
    -- '@ox_lib/init.lua', -- REQUIRED: Install ox_lib (https://github.com/overextended/ox_lib)
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    -- '@oxmysql/lib/MySQL.lua', -- REQUIRED: Install oxmysql (https://github.com/overextended/oxmysql)
    'server/main.lua'
}

