fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dvr_shockwave'
author 'VLight'
version '1.0.0'
description 'Onde de choc qui projette et étourdit brièvement'

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
