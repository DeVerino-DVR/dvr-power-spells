---@diagnostic disable: undefined-global, trailing-space, unused-local

--- Send notification to a player
local function Notify(sourceId, payload)
    if not payload then return end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

-- Event: Broadcast signal projectile to all clients (projectile flies from wand to target)
RegisterNetEvent('th_meteora:broadcastSignalProjectile', function(targetCoords, spellLevel)
    local _source <const> = source

    if not targetCoords then
        return
    end

    -- Broadcast to all clients to spawn the signal projectile
    -- When it arrives at target, it triggers the meteor shower locally on each client
    TriggerClientEvent('th_meteora:spawnSignalProjectile', -1, _source, targetCoords, spellLevel or 1)
end)

-- Event: Apply damage for a single meteor impact (uses centralized damage system)
RegisterNetEvent('th_meteora:applyMeteorDamage', function(impactCoords, spellLevel, meteorIndex)
    local _source <const> = source

    if not impactCoords or not spellLevel then
        return
    end

    -- Use centralized damage system from th_power
    local damagePerLevel = Config.Damage and Config.Damage.perLevel or 60
    local damageRadius = Config.Damage and Config.Damage.radius or 4.0

    -- Apply damage with protection against native explosion damage
    -- Each meteor impact triggers this, so damage stacks if player is hit by multiple meteors
    exports['th_power']:ApplySpellDamage(
        impactCoords,
        spellLevel,
        damagePerLevel,
        damageRadius,
        _source,
        'Meteora',
        800  -- Protection duration (slightly longer for meteor shower)
    )

    if Config.Debug then
        print(string.format('[th_meteora] Meteor %d impact - Level %d - Coords: %.2f, %.2f, %.2f',
            meteorIndex or 0, spellLevel, impactCoords.x, impactCoords.y, impactCoords.z))
    end
end)

--- Register the Meteora module with th_power
local function RegisterMeteoraModule()
    local anim <const> = Config.Animation or {}
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 12000,
        type = Config.Module.type,
        isBasic = false,
        sound = Config.Sounds and Config.Sounds.cast and Config.Sounds.cast.url or '',
        soundType = "3d",
        image = Config.Module.image or "images/power/th_meteora.png",
        video = Config.Module.video or "",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = anim.dict,
            name = anim.name,
            flag = anim.flag or 0,
            duration = anim.duration or 2500,
            speedMultiplier = anim.speedMultiplier or 1.8
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
                spell = { id = 'meteora', name = 'Meteora', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil }
            }
            exports['th_power']:LogSpellCast(data)

            -- Notify other players about casting (for visual sync)
            TriggerClientEvent('th_meteora:otherPlayerCasting', -1, source)

            -- Start cast sequence on caster's client
            TriggerClientEvent('th_meteora:prepareCast', source, spellLevel)

            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_meteora] Module enregistré avec succès')
end

-- Wait for th_power to be ready before registering
CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterMeteoraModule()
end)

-- Re-register if th_power restarts
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterMeteoraModule()
    end
end)

