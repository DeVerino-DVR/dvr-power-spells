---@diagnostic disable: trailing-space
local castCache = {}

local function clampLevel(level)
    local numeric = math.floor(tonumber(level) or 0)
    if numeric < 0 then
        return 0
    end
    if numeric > 5 then
        return 5
    end
    return numeric
end

RegisterNetEvent('dvr_accyra:broadcastProjectile', function(finalTargetCoords)
    local _source <const> = source
    if not finalTargetCoords then
        return
    end
    
    local castInfo = castCache[_source]
    local level = clampLevel(castInfo and castInfo.level or 0)
    
    TriggerClientEvent('dvr_accyra:fireProjectile', -1, _source, finalTargetCoords, level)
    castCache[_source] = nil
end)

local function RegisterAccioModule()
    local moduleData <const> = {
        id = 'accyra',
        name = 'Accyra',
        description = "Fait naître une force d’attraction mystique aspirant objets et êtres vivants vers le lanceur.",
        icon = 'hand-point-up',
        color = 'blue',
        cooldown = 10000,
        type = 'utility',
        level = 3,
        unforgivable = false,
        key = nil,
        sound = 'YOUR_SOUND_URL_HERE',
        soundType = "3d",
        image = "images/power/emopiaga.png",
        video = "YOUR_VIDEO_URL_HERE",
        animation = {
            dict = 'export@nib@wizardsv_avada_kedrava',
            name = 'nib@wizardsv_avada_kedrava',
            flag = 0,
            duration = 3000,
            speedMultiplier = 2.5,
        },
        onCast = function(hasItem, raycast, source, target, spellLevel)
            if not hasItem then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Accyra',
                    description = 'Vous n\'avez pas de baguette équipée',
                    type = 'error',
                    icon = 'hand-point-up'
                })
                return false
            end
            
            local level <const> = clampLevel(spellLevel)
            castCache[source] = {
                level = level
            }

            local data = {
                professor = { source = source },
                --target = { source = target }, -- f
                spell = { id = 'accyra', name = 'Accyra', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)
            
            TriggerClientEvent('dvr_accyra:otherPlayerCasting', -1, source, level)
            TriggerClientEvent('dvr_accyra:prepareProjectile', source, level)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_accyra] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    
    Wait(500)
    RegisterAccioModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterAccioModule()
    end
end)
