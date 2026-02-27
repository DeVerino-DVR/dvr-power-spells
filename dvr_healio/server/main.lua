---@diagnostic disable: trailing-space
local function GetCasterLevel(sourceId)
    local ok, hasSpell, level = pcall(function()
        return exports['dvr_power']:GetSpell(sourceId, 'healio')
    end)

    if ok and hasSpell then
        return math.floor(tonumber(level) or 0)
    end

    return 0
end

RegisterNetEvent('dvr_healio:broadcastProjectile', function(finalTargetCoords)
    local _source <const> = source
    if not finalTargetCoords then
        return
    end

    local spellLevel = GetCasterLevel(_source)
    TriggerClientEvent('dvr_healio:fireProjectile', -1, _source, finalTargetCoords, spellLevel)
end)

local function RegisterHealioModule()
    local moduleData <const> = {
        id = 'healio',
        name = 'Healio',
        description = "Diffuse une brume verdoyante régénératrice soignant blessures légères et maux mineurs.",
        icon = 'heart-pulse',
        color = 'green',
        cooldown = 15000,
        type = 'support',
        level = 1,
        unforgivable = false,
        key = nil,
        image = "images/power/healtarget.png",
        video = "YOUR_VIDEO_URL_HERE",
        sound = 'YOUR_SOUND_URL_HERE',
        soundType = "3d",
        animation = {
            dict = "export@nib@wizardsv_wand_attack_2",
            name = "nib@wizardsv_wand_attack_2",
            flag = 0,
            duration = 2000,
            speedMultiplier = 4.0,
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Healio',
                    description = 'Vous n\'avez pas de baguette équipée',
                    type = 'error',
                    icon = 'heart-pulse'
                })
                return false
            end
            
            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                spell = { id = 'healio', name = 'Healio', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)
            
            TriggerClientEvent('dvr_healio:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_healio:prepareProjectile', source)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_healio] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    
    Wait(500)
    RegisterHealioModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterHealioModule()
    end
end)
