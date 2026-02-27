fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'th_waterpillar'
author 'VLight'
version '1.0.0'
description 'Pilier d\'eau projeté vers l\'avant'

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

