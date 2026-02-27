---@diagnostic disable: undefined-global, trailing-space, unused-local

local function Notify(sourceId, payload)
    if not payload then return end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

--- Get nearby players in radius
local function GetPlayersInRadius(coords, radius)
    local players = {}
    local allPlayers = GetPlayers()

    for _, playerId in ipairs(allPlayers) do
        local ped = GetPlayerPed(playerId)
        if ped and DoesEntityExist(ped) then
            local playerCoords = GetEntityCoords(ped)
            local dist = #(playerCoords - coords)
            if dist <= radius then
                table.insert(players, tonumber(playerId))
            end
        end
    end

    return players
end

--- Prepare impact (damage)
RegisterNetEvent('th_tenebris:prepareImpact', function(impactCoords, spellLevel)
    local _source = source
    if not impactCoords then return end

    -- Apply damage via th_power
    if exports['th_power'] and exports['th_power'].ApplySpellDamage then
        local damagePerLevel = Config.Impact.damagePerLevel or 25
        local radius = Config.Impact.damageRadius or 12.0

        exports['th_power']:ApplySpellDamage(
            impactCoords,      -- coords
            spellLevel,        -- spellLevel
            damagePerLevel,    -- damagePerLevel
            radius,            -- radius
            _source,           -- sourceId
            'Tenebris'         -- spellName
        )
    end
end)

--- On impact - broadcast effects
RegisterNetEvent('th_tenebris:onImpact', function(impactCoords, spellLevel)
    local _source = source
    if not impactCoords then return end

    -- Broadcast impact effects to all clients
    TriggerClientEvent('th_tenebris:playImpactFx', -1, impactCoords)

    -- Find and knockback nearby players (SAUF LE LANCEUR!)
    local knockbackRadius = Config.Impact.knockbackRadius or 15.0
    local nearbyPlayers = GetPlayersInRadius(impactCoords, knockbackRadius)

    local forceUp = Config.Impact.knockbackForceUp or 25.0
    local forceHorizontal = Config.Impact.knockbackForceHorizontal or 20.0
    local ragdollTime = Config.Impact.ragdollTime or 4000

    for _, playerId in ipairs(nearbyPlayers) do
        -- NE PAS projeter le lanceur!
        if playerId ~= _source then
            TriggerClientEvent('th_tenebris:applyKnockback', playerId, impactCoords, spellLevel or 1, forceUp, forceHorizontal, ragdollTime)
        end
    end
end)

--- Create projectile - broadcast to all clients
RegisterNetEvent('th_tenebris:createProjectile', function(startPos, impactCoords, spellLevel)
    local _source = source
    if not startPos or not impactCoords then return end

    TriggerClientEvent('th_tenebris:createProjectile', -1, startPos, impactCoords, _source, spellLevel or 1)
end)

--- Register module
local function RegisterTenebrisModule()
    local moduleData = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 15000,
        type = Config.Module.type,
        isBasic = false,
        sound = 'YOUR_SOUND_URL_HERE',
        soundType = "3d",
        image = Config.Module.image or "images/power/th_tenebris.png",
        video = Config.Module.video or "",
        professor = Config.Module.professor ~= false,
        hidden = Config.Module.hidden or true,
        animation = {
            dict = Config.Animation.dict,
            name = Config.Animation.name,
            flag = Config.Animation.flag,
            duration = Config.Animation.duration,
            speedMultiplier = Config.Animation.speedMultiplier,
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or 1
            local data = {
                professor = { source = source },
                spell = { id = 'tenebris', name = 'Tenebris', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)

            TriggerClientEvent('th_tenebris:otherPlayerCasting', -1, source)
            TriggerClientEvent('th_tenebris:prepareCast', source, spellLevel)
            return true
        end
    }
    exports['th_power']:registerModule(moduleData, 0)
    print('[th_tenebris] ⚡ Module TENEBRIS enregistré - Sort ultime des ténèbres disponible ⚡')
end

--- Wait for th_power
CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    RegisterTenebrisModule()
end)

--- Re-register on th_power restart
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterTenebrisModule()
    end
end)
