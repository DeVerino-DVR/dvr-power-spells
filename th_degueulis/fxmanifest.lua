fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'th_degueulis'
author 'VLight'
description 'Sort Degueulis - fait vomir la cible via scully_emotemenu.'
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
