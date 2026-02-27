fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'th_juliusis'
author 'VLight'
version '1.0.0'
description 'Sort Juliusis qui fait tomber la cible'

-- dependencies {
    --     'lo_audio' -- REPLACE: Use your own audio resource
-- }

shared_scripts {
    -- '@ox_lib/init.lua', -- REQUIRED: Install ox_lib (https://github.com/overextended/ox_lib)
    'config.lua'
-- }

client_scripts {
    'client/main.lua'
-- }

server_scripts {
    'server/main.lua'
-- }
