fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'th_firepillar'
author 'VLight'
version '1.0.0'
description 'Pilier de feu avec rotation et réplication'

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

