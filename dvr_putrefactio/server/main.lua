---@diagnostic disable: undefined-global, trailing-space, unused-local

local function IsValidTarget(target, caster)
    return target and target ~= caster and type(target) == 'number' and target > 0
end

RegisterNetEvent('dvr_putrefactio:broadcastProjectile', function(finalTargetCoords)
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
        clamped = exports['dvr_power']:ClampSpellCoords(_source, 'putrefactio', coords, nil, false) or coords
    end

    TriggerClientEvent('dvr_putrefactio:fireProjectile', -1, _source, clamped)
end)

local function RegisterPutrefactioModule()
    local moduleData <const> = {
        id = 'putrefactio',
        name = 'Putrefactio',
        description = "Sortilège de bannissement qui téléporte la cible vers un lieu maudit, la séparant du monde des vivants.",
        icon = 'portal-exit',
        color = 'green',
        cooldown = 600000,
        type = 'attack',
        level = 10,
        unforgivable = true,
        key = nil,
        sound = 'YOUR_SOUND_URL_HERE',
        soundType = "3d",
        image = "images/power/dvr_putrefactio.png",
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
                    title = 'Putrefactio',
                    description = 'Vous n\'avez pas de baguette équipée',
                    type = 'error',
                    icon = 'portal-exit'
                })
                return false
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or 1
            local data = {
                professor = { source = source },
                target = { source = target },
                spell = { id = 'putrefactio', name = 'Putrefactio', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }

            if IsValidTarget(target, source) then
                SetTimeout(1500, function()
                    TriggerClientEvent('dvr_putrefactio:teleportTarget', target)
                end)
            end
            exports['dvr_power']:LogSpellCast(data)

            TriggerClientEvent('dvr_putrefactio:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_putrefactio:prepareProjectile', source)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_putrefactio] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterPutrefactioModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterPutrefactioModule()
    end
end)
