---@diagnostic disable: undefined-global, trailing-space, unused-local
RegisterNetEvent('dvr_mortalis:broadcastProjectile', function(finalTargetCoords)
    local _source <const> = source
    if not finalTargetCoords then
        return
    end

    local coords = finalTargetCoords
    if type(coords) == 'table' and coords.x and coords.y and coords.z then
        coords = vector3(coords.x, coords.y, coords.z)
    end

    local clamped = coords
    if GetResourceState('dvr_power') == 'started' then
        clamped = exports['dvr_power']:ClampSpellCoords(_source, 'mortalis', coords, nil, false) or coords
    end
    
    TriggerClientEvent('dvr_mortalis:fireProjectile', -1, _source, clamped)
end)

local function RegisterAvadaKedavraModule()
    local moduleData <const> = {
        id = 'mortalis',
        name = 'Mortalis',
        description = "Sortilège interdit rompant le lien vital de la cible avec le Flux, entraînant la mort.",
        icon = 'skull',
        color = 'green',
        cooldown = 600000,
        type = 'attack',
        level = 10,
        unforgivable = true,
        key = nil,
        sound = 'YOUR_SOUND_URL_HERE',
        soundType = "3d",
        image = "images/power/snakebite.png",
        video = "YOUR_VIDEO_URL_HERE",
        professor = false,
        animation = {
            dict = 'export@nib@wizardsv_wand_attack_b5',
            name = 'nib@wizardsv_wand_attack_b5',
            flag = 0,
            duration = 3000,
            speedMultiplier = 8.5
        },
        onCast = function(hasItem, raycast, source, target)
            if not hasItem then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Mortalis',
                    description = 'Vous n\'avez pas de baguette équipée',
                    type = 'error',
                    icon = 'skull'
                })
                return false
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or 1
            local data = {
                professor = { source = source },
                target = { source = target }, -- f
                spell = { id = 'mortalis', name = 'Mortalis', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }

            SetTimeout(5000, function()
                local ok, applied = pcall(function()
                    return exports['dvr_power']:DealDamage(target, 100, 100, 'mortalis')
                end)
            end)
            exports['dvr_power']:LogSpellCast(data)
            
            TriggerClientEvent('dvr_mortalis:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_mortalis:prepareProjectile', source)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_mortalis] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    
    Wait(500)
    RegisterAvadaKedavraModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterAvadaKedavraModule()
    end
end)
