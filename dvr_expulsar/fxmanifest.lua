fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'VLight'
description 'Explusar - Spell that creates a shockwave to repel nearby enemies'
version '1.0.0'

shared_scripts {
    -- '@ox_lib/init.lua', -- REQUIRED: Install ox_lib (https://github.com/overextended/ox_lib)
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}
