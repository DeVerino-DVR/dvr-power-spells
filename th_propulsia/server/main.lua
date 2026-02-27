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

--- Trigger water explosion
RegisterNetEvent('th_propulsia:trigger', function(explosionCoords)
    local _source = source
    if not explosionCoords then return end

    -- Broadcast visual effects to all clients (avec le serverId du lanceur pour la synchro)
    TriggerClientEvent('th_propulsia:playExplosionFx', -1, explosionCoords, _source)

    -- Apply self propulsion to caster
    TriggerClientEvent('th_propulsia:applySelfPropulsion', _source)

    -- Find and knockback nearby players (excluding caster)
    local radius = Config.Propulsion.knockbackRadius or 8.0
    local nearbyPlayers = GetPlayersInRadius(explosionCoords, radius)

    for _, playerId in ipairs(nearbyPlayers) do
        if playerId ~= _source then
            TriggerClientEvent('th_propulsia:applyKnockback', playerId, explosionCoords)
        end
    end
end)

--- Register module with th_power
local function RegisterPropulsiaModule()
    local moduleData = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 9000,
        type = Config.Module.type,
        isBasic = false,
        sound = '',
        soundType = "3d",
        image = Config.Module.image or "images/power/th_propulsia.png",
        video = Config.Module.video or "",
        professor = Config.Module.professor ~= false,
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

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                spell = { id = 'propulsia', name = 'Propulsia', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)

            TriggerClientEvent('th_propulsia:otherPlayerCasting', -1, source)
            TriggerClientEvent('th_propulsia:prepareCast', source)
            return true
        end
    }
    exports['th_power']:registerModule(moduleData, 0)
    print('[th_propulsia] Module enregistré avec succès')
end

--- Wait for th_power to start
CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    RegisterPropulsiaModule()
end)

--- Re-register on th_power restart
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterPropulsiaModule()
    end
end)
