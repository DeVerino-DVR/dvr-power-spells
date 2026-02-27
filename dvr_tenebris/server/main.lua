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
RegisterNetEvent('dvr_tenebris:prepareImpact', function(impactCoords, spellLevel)
    local _source = source
    if not impactCoords then return end

    -- Apply damage via dvr_power
    if exports['dvr_power'] and exports['dvr_power'].ApplySpellDamage then
        local damagePerLevel = Config.Impact.damagePerLevel or 25
        local radius = Config.Impact.damageRadius or 12.0

        exports['dvr_power']:ApplySpellDamage(
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
RegisterNetEvent('dvr_tenebris:onImpact', function(impactCoords, spellLevel)
    local _source = source
    if not impactCoords then return end

    -- Broadcast impact effects to all clients
    TriggerClientEvent('dvr_tenebris:playImpactFx', -1, impactCoords)

    -- Find and knockback nearby players (SAUF LE LANCEUR!)
    local knockbackRadius = Config.Impact.knockbackRadius or 15.0
    local nearbyPlayers = GetPlayersInRadius(impactCoords, knockbackRadius)

    local forceUp = Config.Impact.knockbackForceUp or 25.0
    local forceHorizontal = Config.Impact.knockbackForceHorizontal or 20.0
    local ragdollTime = Config.Impact.ragdollTime or 4000

    for _, playerId in ipairs(nearbyPlayers) do
        -- NE PAS projeter le lanceur!
        if playerId ~= _source then
            TriggerClientEvent('dvr_tenebris:applyKnockback', playerId, impactCoords, spellLevel or 1, forceUp, forceHorizontal, ragdollTime)
        end
    end
end)

--- Create projectile - broadcast to all clients
RegisterNetEvent('dvr_tenebris:createProjectile', function(startPos, impactCoords, spellLevel)
    local _source = source
    if not startPos or not impactCoords then return end

    TriggerClientEvent('dvr_tenebris:createProjectile', -1, startPos, impactCoords, _source, spellLevel or 1)
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
        image = Config.Module.image or "images/power/dvr_tenebris.png",
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
            exports['dvr_power']:LogSpellCast(data)

            TriggerClientEvent('dvr_tenebris:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_tenebris:prepareCast', source, spellLevel)
            return true
        end
    }
    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_tenebris] ⚡ Module TENEBRIS enregistré - Sort ultime des ténèbres disponible ⚡')
end

--- Wait for dvr_power
CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    RegisterTenebrisModule()
end)

--- Re-register on dvr_power restart
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterTenebrisModule()
    end
end)
