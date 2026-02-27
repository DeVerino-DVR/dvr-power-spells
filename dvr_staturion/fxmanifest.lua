fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dvr_staturion'
author 'VLight'
version '1.0.0'
description 'Staturion Spell Module for dvr_power'

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
