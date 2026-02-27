---@diagnostic disable: undefined-global, trailing-space, unused-local
local function GetCasterLevel(sourceId)
    local ok, hasSpell, level = pcall(function()
        return exports['th_power']:GetSpell(sourceId, 'explusar')
    end)

    if ok and hasSpell then
        return math.floor(tonumber(level) or 0)
    end

    return 0
end

local function BuildRepulsarSettings(level)
    local lvl = math.max(0, math.floor(tonumber(level) or 0))
    local ratio = math.min(lvl / 5.0, 1.0)

    local maxRadius = Config.expulsar.radius or 35.0
    local minRadius = 12.0
    local maxForce = Config.expulsar.force or 5.0
    local minForce = 1.0
    local maxUpward = Config.expulsar.upwardForce or 5.0
    local minUpward = 2.5

    return {
        radius = minRadius + ((maxRadius - minRadius) * ratio),
        force = minForce + ((maxForce - minForce) * ratio),
        upwardForce = minUpward + ((maxUpward - minUpward) * ratio)
    }
end

RegisterNetEvent('th_repulsar:applyForce', function(targetServerId, velocity)
    local _source <const> = source
    
    if not targetServerId or not velocity then return end

    if exports['th_prothea'] and exports['th_prothea'].hasActiveShield and exports['th_prothea']:hasActiveShield(targetServerId) then
        print(string.format('[Expulsar] annulé par Prothea pour %s', targetServerId))
        return
    end

    local casterLevel = GetCasterLevel(_source)
    local settings = BuildRepulsarSettings(casterLevel)

    local x = tonumber(velocity.x) or 0.0
    local y = tonumber(velocity.y) or 0.0
    local z = tonumber(velocity.z) or 0.0
    local magnitude = math.sqrt((x * x) + (y * y) + (z * z))
    local maxForce = settings.force * 1.05

    if magnitude > 0 and magnitude > maxForce then
        local scale = maxForce / magnitude
        x, y, z = x * scale, y * scale, z * scale
    end

    local maxUpward = settings.upwardForce * 1.1
    if z > maxUpward then
        z = maxUpward
    end

    local targetPed = GetPlayerPed(targetServerId)
    local targetNetId = targetPed and NetworkGetNetworkIdFromEntity(targetPed) or nil

    TriggerClientEvent('th_repulsar:visualForce', -1, targetServerId, targetNetId, { x = x, y = y, z = z })
    TriggerClientEvent('th_repulsar:receiveForce', targetServerId, { x = x, y = y, z = z })
end)

local function RegisterRepulsarModule()
    local moduleData <const> = {
        id = 'explusar',
        name = 'Expulsar',
        description = "Libère une décharge brutale de magie repoussant violemment la cible.",
        icon = 'wind',
        color = 'blue',
        cooldown = 15000,
        type = 'attack',
        level = 3,
        unforgivable = false,
        image = "images/power/givepower.png",
        video = "YOUR_VIDEO_URL_HERE",
        sound = nil,
        soundType = nil,
        animation = {
            dict = Config.Animation.dict,
            name = Config.Animation.name,
            flag = Config.Animation.flag,
            duration = Config.Animation.duration,
            speedMultiplier = Config.Animation.speedMultiplier
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Expulsar',
                    description = 'Vous n\'avez pas de baguette équipée',
                    type = 'error',
                    icon = 'wind'
                })
                return false
            end

            local targetId = tonumber(target)
            if not targetId or targetId <= 0 then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Explusar',
                    description = 'Aucune cible visée',
                    type = 'error',
                    icon = 'wind'
                })
                return false
            end

            local casterPed = GetPlayerPed(source)
            local targetPed = GetPlayerPed(targetId)
            if not casterPed or casterPed == 0 or not targetPed or targetPed == 0 then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Explusar',
                    description = 'Cible introuvable',
                    type = 'error',
                    icon = 'wind'
                })
                return false
            end

            local casterCoords = GetEntityCoords(casterPed)
            local targetCoords = GetEntityCoords(targetPed)
            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local settings = BuildRepulsarSettings(spellLevel)
            local maxDistance = settings.radius or Config.expulsar.radius or 20.0
            local distance = #(casterCoords - targetCoords)

            if distance > maxDistance then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Explusar',
                    description = 'Cible trop éloignée',
                    type = 'error',
                    icon = 'wind'
                })
                return false
            end

            local data = {
                professor = { source = source },
                target = { source = targetId }, -- f
                spell = { id = 'explusar', name = 'Explusar', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)
            
            -- Broadcast sound to nearby players (25m)
            TriggerClientEvent('th_repulsar:playSound', -1, source, casterCoords)

            TriggerClientEvent('th_repulsar:castSpell', source, settings, spellLevel, targetId)
            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_repulsar] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    RegisterRepulsarModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterRepulsarModule()
    end
end)
