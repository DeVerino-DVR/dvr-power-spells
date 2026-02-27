fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dvr_tenebris'
author 'VLight'
version '1.0.0'
description 'Sort ultime de magie noire - Explosion apocalyptique de ténèbres et flammes'

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
