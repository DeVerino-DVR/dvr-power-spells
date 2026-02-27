local function GetCasterLevel(sourceId)
    local ok, hasSpell, level = pcall(function()
        return exports['th_power']:GetSpell(sourceId, 'transvalis')
    end)

    if ok and hasSpell then
        return math.floor(tonumber(level) or 0)
    end

    return 0
end

local function CalculateTransDuration(level)
    local maxDuration <const> = Config.Transplanner.duration or 15000
    local minDuration <const> = math.floor(maxDuration * 0.35)
    local lvl <const> = math.max(0, math.floor(tonumber(level) or 0))
    local ratio <const> = math.min(lvl / 5.0, 1.0)

    return math.floor(minDuration + ((maxDuration - minDuration) * ratio))
end

local function RegisterTransplannerModule()
    local moduleData <const> = {
        id = 'transvalis',
        name = 'Transvalis',
        description = "Permet une traversée rapide des airs, porté par une force magique soutenue.",
        icon = 'ghost',
        color = 'purple',
        cooldown = 30000,
        type = 'utility',
        level = 5,
        unforgivable = false,
        key = nil,
        image = "images/power/shadowbomb.png",
        video = "YOUR_VIDEO_URL_HERE",
        sound = 'YOUR_SOUND_URL_HERE',
        soundType = "3d",
        professor = false,
        noWandTrail = true,
        animation = {
            dict = 'export@nib@broomstick_summon_in',
            name = 'nib@broomstick_summon_in',
            flag = 0,
            duration = 2000
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Transvalis',
                    description = 'Vous n\'avez pas de baguette équipée',
                    type = 'error',
                    icon = 'ghost'
                })
                return false
            end

            local spellLevel <const> = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local duration <const> = CalculateTransDuration(spellLevel)

            local trailColor = nil
            local playerState = Player(source).state
            if playerState and playerState.transvalisCustomColor then
                trailColor = playerState.transvalisCustomColor
            end

            if not trailColor then
                if playerState and playerState.job and playerState.job.name then
                    trailColor = playerState.job.name
                else
                    trailColor = 'default'
                end
            end

            local data = {
                professor = { source = source },
                --target = { source = target }, -- f
                spell = { id = 'transvalis', name = 'Transvalis', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)

            TriggerClientEvent('th_transvalis:start', -1, source, duration, trailColor)
            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_transvalis] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end
    
    Wait(500)
    RegisterTransplannerModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterTransplannerModule()
    end
end)

RegisterNetEvent('th_transvalis:syncStop', function()
    local src <const> = source
    TriggerClientEvent('th_transvalis:stop', -1, src)
end)

-- Event pour synchroniser la position du transplanage en temps réel
RegisterNetEvent('th_transvalis:syncPosition', function(sourceId, coords, fromCoords, trailColor, isMoving)
    local src = source

    -- Vérification de sécurité
    if src ~= sourceId then
        return
    end

    if not coords or type(coords) ~= "table" then
        return
    end

    if type(coords.x) ~= "number" or type(coords.y) ~= "number" or type(coords.z) ~= "number" then
        return
    end

    -- Valider fromCoords si présent
    local validFromCoords = nil
    if fromCoords and type(fromCoords) == "table" and type(fromCoords.x) == "number" and type(fromCoords.y) == "number" and type(fromCoords.z) == "number" then
        validFromCoords = fromCoords
    end

    -- Broadcaster la position et les données de traînée à tous les autres clients
    TriggerClientEvent('th_transvalis:syncPositionClient', -1, sourceId, coords, validFromCoords, trailColor, isMoving)
end)

RegisterNetEvent('th_transvalis:teleportPlayer', function(targetServerId, coords)
    local src = source

    if type(coords) ~= "table" or type(coords.x) ~= "number" or type(coords.y) ~= "number" or type(coords.z) ~= "number" then
        return
    end

    if not targetServerId or targetServerId == src then
        return
    end

    if not GetPlayerName(targetServerId) then
        return
    end

    TriggerClientEvent('th_transvalis:clientTeleport', targetServerId, coords)
end)

RegisterNetEvent('th_transvalis:teleportSinglePlayer', function(targetServerId, coords)
    local src = source

    if type(coords) ~= "table" or type(coords.x) ~= "number" or type(coords.y) ~= "number" or type(coords.z) ~= "number" then
        return
    end

    if not targetServerId or targetServerId == src then
        return
    end

    if not GetPlayerName(targetServerId) then
        return
    end

    TriggerClientEvent('th_transvalis:clientTeleport', targetServerId, coords)
end)

RegisterNetEvent('th_transvalis:teleportPlayerToMe', function(targetServerId, myCoords)
    local src = source

    if not myCoords or type(myCoords) ~= "table" then
        return
    end

    if type(myCoords.x) ~= "number" or type(myCoords.y) ~= "number" or type(myCoords.z) ~= "number" then
        return
    end

    if not targetServerId or targetServerId == src then
        return
    end

    if not GetPlayerName(targetServerId) then
        return
    end

    TriggerClientEvent('th_transvalis:clientTeleport', targetServerId, myCoords)
end)

RegisterNetEvent('th_transvalis:startMenuTeleport', function(sourceId, duration, trailColor)
    local src = source
    
    if src ~= sourceId then
        return
    end
    
    TriggerClientEvent('th_transvalis:start', -1, sourceId, duration, trailColor)
end)

RegisterNetEvent('th_transvalis:teleportMultiplePlayers', function(targets, destinationCoords)
    local src = source

    if not destinationCoords or type(destinationCoords) ~= "table" then
        return
    end

    if type(destinationCoords.x) ~= "number" or type(destinationCoords.y) ~= "number" or type(destinationCoords.z) ~= "number" then
        return
    end

    if type(targets) ~= "table" then
        return
    end

    local offsetRadius = 1.5
    local playerIndex = 0

    for _, target in ipairs(targets) do
        if target and target.serverId then
            local targetServerId = target.serverId
            local playerName = GetPlayerName(targetServerId)
            
            if targetServerId and targetServerId ~= src and playerName then
                playerIndex = playerIndex + 1
                local angle = (playerIndex * (360.0 / #targets)) * (math.pi / 180.0)
                local offsetDistance = offsetRadius * (0.5 + math.random() * 0.5)
                
                local offsetX = destinationCoords.x + math.cos(angle) * offsetDistance
                local offsetY = destinationCoords.y + math.sin(angle) * offsetDistance
                local offsetZ = destinationCoords.z

                TriggerClientEvent('th_transvalis:clientTeleport', targetServerId, {
                    x = offsetX,
                    y = offsetY,
                    z = offsetZ
                })
            end
        end
    end
end)


RegisterNetEvent('th_transvalis:broadcastStart', function(sourceId, duration, trailColor)
    local src = source

    if src ~= sourceId then
        return
    end

    local actualTrailColor = trailColor
    local playerState = Player(src).state
    if playerState and playerState.transvalisCustomColor then
        actualTrailColor = playerState.transvalisCustomColor
    end

    if not actualTrailColor then
        if playerState and playerState.job and playerState.job.name then
            actualTrailColor = playerState.job.name
        else
            actualTrailColor = 'default'
        end
    end

    TriggerClientEvent('th_transvalis:start', -1, sourceId, duration, actualTrailColor)
end)

RegisterNetEvent('th_transvalis:broadcastArrivalEffects', function(sourceId, coords)
    local src = source

    if src ~= sourceId then
        return
    end

    if not coords or type(coords) ~= "table" then
        return
    end

    if type(coords.x) ~= "number" or type(coords.y) ~= "number" or type(coords.z) ~= "number" then
        return
    end

    TriggerClientEvent('th_transvalis:arrivalEffects', -1, sourceId, coords)
end)

RegisterNetEvent('th_transvalis:stopMenuTeleport', function(sourceId)
    local src = source

    if src ~= sourceId then
        return
    end

    TriggerClientEvent('th_transvalis:stop', -1, sourceId)
end)
