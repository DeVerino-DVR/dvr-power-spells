---@diagnostic disable: undefined-global, trailing-space, unused-local

--- Send notification to a player
local function Notify(sourceId, payload)
    if not payload then return end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

--- Get caster level (helper function)
local function GetCasterLevel(sourceId)
    if exports['th_power'] and exports['th_power'].GetPlayerLevel then
        local ok, level = pcall(function()
            return exports['th_power']:GetPlayerLevel(sourceId)
        end)
        if ok and level then
            return math.floor(tonumber(level) or 1)
        end
    end
    return 1
end

--- Event: Broadcast wall creation to all clients
RegisterNetEvent('th_wallis:broadcastWall', function(targetCoords, direction, spellLevel)
    local _source <const> = source

    if not targetCoords then
        return
    end

    -- Clamp spell level
    local level = spellLevel or GetCasterLevel(_source)
    if level < 1 then level = 1 end
    if level > 5 then level = 5 end

    -- Broadcast to all clients to spawn the wall
    TriggerClientEvent('th_wallis:spawnWall', -1, _source, targetCoords, direction, level)

    if Config.Debug then
        print(string.format('[th_wallis] Wall created - Level %d - Coords: %.2f, %.2f, %.2f',
            level, targetCoords.x, targetCoords.y, targetCoords.z))
    end
end)

--- Register the Wallis module with th_power
local function RegisterWallisModule()
    local anim <const> = Config.Animation or {}
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 15000,
        type = Config.Module.type,
        isBasic = false,
        sound = Config.Sounds and Config.Sounds.cast and Config.Sounds.cast.url or '',
        soundType = "3d",
        image = Config.Module.image or "images/power/th_wallis.png",
        video = Config.Module.video or "",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = anim.dict,
            name = anim.name,
            flag = anim.flag or 0,
            duration = anim.duration or 2000,
            speedMultiplier = anim.speedMultiplier or 1.5
        },
        onCast = function(hasItem, raycast, source, target, level)
            -- Check if player has wand equipped
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end

            -- Get spell level
            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            if spellLevel < 1 then spellLevel = 1 end
            if spellLevel > 5 then spellLevel = 5 end

            -- Log spell cast
            local data = {
                professor = { source = source },
                spell = { id = 'wallis', name = 'Wallis', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil }
            }
            exports['th_power']:LogSpellCast(data)

            -- Notify other players about casting (for visual sync)
            TriggerClientEvent('th_wallis:otherPlayerCasting', -1, source)

            -- Start cast sequence on caster's client
            TriggerClientEvent('th_wallis:prepareCast', source, spellLevel)

            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_wallis] Module enregistré avec succès')
end

-- Wait for th_power to be ready before registering
CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterWallisModule()
end)

-- Re-register if th_power restarts
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterWallisModule()
    end
end)

