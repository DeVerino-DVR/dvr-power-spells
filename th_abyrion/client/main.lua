---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter, deprecated
local activeCircles = {}
local wandParticles = {}
local allParticles = {}
local burningPlayers = {}
local burningFx = {}

local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local DrawLightWithRange = DrawLightWithRange
local DoesEntityExist = DoesEntityExist
local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local SetPedToRagdoll = SetPedToRagdoll
local ApplyForceToEntity = ApplyForceToEntity
local vector3 = vector3

local function HasProtheaShield()
    local hasShield = false
    if LocalPlayer and LocalPlayer.state then
        hasShield = LocalPlayer.state.protheaShield == true
    end
    if not hasShield and exports['th_prothea'] and exports['th_prothea'].hasLocalShield then
        local ok, result = pcall(function()
            return exports['th_prothea']:hasLocalShield()
        end)
        hasShield = ok and result == true
    end
    return hasShield
end

local function EnsureAsset(asset)
    if not asset then return false end
    RequestNamedPtfxAsset(asset)
    local timeout = 0
    while not HasNamedPtfxAssetLoaded(asset) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    return HasNamedPtfxAssetLoaded(asset)
end

local function GetLevelConfig(level)
    local lvl = tonumber(level) or 1
    if lvl < 1 then lvl = 1 end
    if lvl > 5 then lvl = 5 end
    return Config.Levels[lvl]
end

local function StopWandFx(playerPed)
    local handle = wandParticles[playerPed]
    if handle then
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
        allParticles[handle] = nil
        wandParticles[playerPed] = nil
    end
end

local function PlayWandFx(playerPed)
    local weapon = GetCurrentPedWeaponEntityIndex and GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or not DoesEntityExist(weapon) then
        return nil
    end

    if not EnsureAsset('core') then return nil end

    UseParticleFxAsset('core')
    local handle = StartParticleFxLoopedOnEntity('veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.55, false, false, false)

    if handle then
        SetParticleFxLoopedColour(handle, 0.0, 0.8, 0.2, false)
        SetParticleFxLoopedAlpha(handle, 220)
        wandParticles[playerPed] = handle
        allParticles[handle] = { createdTime = GetGameTimer(), type = 'wand' }
    end

    return handle
end

local function CreateFlameAtPosition(coords, scale, colorIndex, height)
    local handles = {}

    if EnsureAsset('ns_ptfx') then
        UseParticleFxAssetNextCall('ns_ptfx')
        local fx = StartParticleFxLoopedAtCoord('fire', coords.x, coords.y, coords.z - 0.8, 0.0, 0.0, 0.0, scale, false, false, false, false)
        if fx then
            -- Alterner entre vert et noir
            if colorIndex % 2 == 0 then
                SetParticleFxLoopedColour(fx, 0.0, 0.6, 0.15, false)
            else
                SetParticleFxLoopedColour(fx, 0.05, 0.15, 0.05, false)
            end
            SetParticleFxLoopedAlpha(fx, 0.9)
            handles[#handles + 1] = fx
            allParticles[fx] = { createdTime = GetGameTimer(), type = 'flame' }
        end
    end

    return handles
end

local function AnimateCircleCreation(centerCoords, levelConfig, sourceServerId, circleId)
    local radius = levelConfig.radius
    local flameCount = levelConfig.flameCount
    local scale = levelConfig.flameScale
    local height = levelConfig.flameHeight

    local angleStep = (2 * math.pi) / flameCount
    local animDuration = 800
    local delayPerFlame = animDuration / flameCount

    local flameHandles = {}

    CreateThread(function()
        for i = 1, flameCount do
            if not activeCircles[circleId] then break end
            local angle = -((i - 1) * angleStep)
            local x = centerCoords.x + radius * math.cos(angle)
            local y = centerCoords.y + radius * math.sin(angle)
            local z = centerCoords.z

            local flamePos = vector3(x, y, z)
            local handles = CreateFlameAtPosition(flamePos, scale, i, height)

            for _, handle in ipairs(handles) do
                flameHandles[#flameHandles + 1] = handle
            end

            if activeCircles[circleId] then
                activeCircles[circleId].particles = flameHandles
            end

            Wait(math.floor(delayPerFlame))
        end
    end)

    return flameHandles
end

local function CreateFlameCircle(centerCoords, level, sourceServerId, circleId)
    local levelConfig = GetLevelConfig(level)
    circleId = circleId or ('abyrion_%s_%s'):format(sourceServerId, GetGameTimer())

    -- Niveau 5: pas de fin automatique (toggle manuel)
    local endTime = nil
    if level < 5 then
        endTime = GetGameTimer() + levelConfig.duration
    end

    activeCircles[circleId] = {
        id = circleId,
        center = centerCoords,
        radius = levelConfig.radius,
        level = level,
        sourceServerId = sourceServerId,
        startTime = GetGameTimer(),
        endTime = endTime,
        particles = {},
        levelConfig = levelConfig,
        lastDamageTick = {}
    }

    AnimateCircleCreation(centerCoords, levelConfig, sourceServerId, circleId)

    return circleId
end

local function CleanupCircle(circleId, animated)
    local circle = activeCircles[circleId]
    if not circle then return end

    -- Mark as being destroyed to prevent damage
    activeCircles[circleId] = nil

    if circle.particles then
        if animated and #circle.particles > 0 then
            -- Animated cleanup - remove flames one by one like creation
            local flameCount = #circle.particles
            local animDuration = 800
            local delayPerFlame = animDuration / flameCount

            CreateThread(function()
                for i = 1, flameCount do
                    local handle = circle.particles[i]
                    if handle then
                        StopParticleFxLooped(handle, false)
                        RemoveParticleFx(handle, false)
                        allParticles[handle] = nil
                    end
                    Wait(math.floor(delayPerFlame))
                end
            end)
        else
            -- Instant cleanup
            for _, handle in ipairs(circle.particles) do
                StopParticleFxLooped(handle, false)
                RemoveParticleFx(handle, false)
                allParticles[handle] = nil
            end
        end
    end
end

local function IsInDamageZone(playerCoords, circle)
    local dx = playerCoords.x - circle.center.x
    local dy = playerCoords.y - circle.center.y
    local distanceFromCenter = math.sqrt(dx * dx + dy * dy)

    local thickness = (Config.Barrier and Config.Barrier.damageThickness) or 0.8
    local innerRadius = circle.radius - thickness
    local outerRadius = circle.radius + thickness

    if distanceFromCenter >= innerRadius and distanceFromCenter <= outerRadius then
        local heightDiff = math.abs(playerCoords.z - circle.center.z)
        local maxHeight = (Config.Barrier and Config.Barrier.collisionHeight) or 3.0
        if heightDiff <= maxHeight then
            return true, distanceFromCenter
        end
    end

    return false, distanceFromCenter
end

local function GetPushDirection(playerCoords, circleCenter)
    local dx = playerCoords.x - circleCenter.x
    local dy = playerCoords.y - circleCenter.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist < 0.1 then
        local angle = math.random() * 2 * math.pi
        return vector3(math.cos(angle), math.sin(angle), 0.1)
    end

    return vector3(dx / dist, dy / dist, 0.15)
end

local function ApplyPushback(ped, pushDir, force)
    if not DoesEntityExist(ped) then return end

    SetPedToRagdoll(ped, 800, 800, 0, false, false, false)

    ApplyForceToEntity(
        ped,
        1,
        pushDir.x * force,
        pushDir.y * force,
        pushDir.z * force * 0.5,
        0.0, 0.0, 0.0,
        0, false, true, true, false, true
    )
end

CreateThread(function()
    while true do
        local hasActiveCircles = next(activeCircles) ~= nil

        if not hasActiveCircles then
            Wait(200)
        else
            local now = GetGameTimer()
            local myPed = cache.ped
            local myCoords = GetEntityCoords(myPed)
            local myServerId = GetPlayerServerId(PlayerId())

            for circleId, circle in pairs(activeCircles) do
                if circle.endTime and now >= circle.endTime then
                    CleanupCircle(circleId)
                else
                    if circle.sourceServerId ~= myServerId and not HasProtheaShield() then
                        local inZone, dist = IsInDamageZone(myCoords, circle)

                        if inZone then
                            local lastTick = circle.lastDamageTick[myServerId] or 0
                            local tickRate = circle.levelConfig.tickRate or 500

                            if now - lastTick >= tickRate then
                                circle.lastDamageTick[myServerId] = now

                                local currentHealth = GetEntityHealth(myPed)
                                local newHealth = currentHealth - circle.levelConfig.damage
                                if newHealth < 0 then newHealth = 0 end
                                SetEntityHealth(myPed, newHealth)

                                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)

                                if not burningPlayers[myServerId] then
                                    burningPlayers[myServerId] = true
                                    local burnDamage = circle.levelConfig.burnDamage
                                    local burnDuration = circle.levelConfig.burnDuration
                                    local tickCount = math.floor(burnDuration / 1000)
                                    local damagePerTick = math.floor(burnDamage / math.max(1, tickCount))

                                    TriggerServerEvent('th_abyrion:playerBurning', myServerId, burnDuration)

                                    CreateThread(function()
                                        for i = 1, tickCount do
                                            if not burningPlayers[myServerId] then break end
                                            Wait(1000)
                                            local health = GetEntityHealth(myPed)
                                            SetEntityHealth(myPed, math.max(0, health - 3))
                                        end
                                        burningPlayers[myServerId] = nil
                                    end)
                                end
                            end
                        end
                    end
                end
            end

            Wait(50)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(30000)

        local now = GetGameTimer()
        local toRemove = {}

        local activeHandles = {}
        for _, circle in pairs(activeCircles) do
            if circle.particles then
                for _, handle in ipairs(circle.particles) do
                    activeHandles[handle] = true
                end
            end
        end

        for handle, data in pairs(allParticles) do
            if not activeHandles[handle] and now - data.createdTime > 30000 then
                toRemove[#toRemove + 1] = handle
            end
        end

        for _, handle in ipairs(toRemove) do
            StopParticleFxLooped(handle, false)
            RemoveParticleFx(handle, false)
            allParticles[handle] = nil
        end
    end
end)

RegisterNetEvent('th_abyrion:prepare', function(level, isToggleOff)
    local ped = cache.ped
    local coords = GetEntityCoords(ped)

    -- Don't play sound when removing level 5 circle
    if not isToggleOff and Config.Sounds and Config.Sounds.cast then
        pcall(function()
            -- REPLACE WITH YOUR SOUND SYSTEM
            -- exports['lo_audio']:playSound({
            -- id = ('abyrion_cast_%s'):format(GetGameTimer()),
            -- url = Config.Sounds.cast,
            -- volume = 0.5,
            -- loop = false,
            -- spatial = true,
            -- pos = { x = coords.x, y = coords.y, z = coords.z }
            -- })
        end)
    end

    if not isToggleOff then
        PlayWandFx(ped)
    end

    CreateThread(function()
        Wait(400)

        local castCoords = GetEntityCoords(ped)
        TriggerServerEvent('th_abyrion:cast', castCoords, level)

        Wait(600)
        StopWandFx(ped)
    end)
end)

RegisterNetEvent('th_abyrion:otherPlayerCasting', function(sourceServerId)
    local myId = GetPlayerServerId(PlayerId())
    if sourceServerId == myId then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    local casterCoords = GetEntityCoords(casterPed)
    local myCoords = GetEntityCoords(cache.ped)
    local dist = #(myCoords - casterCoords)

    if dist <= 20.0 and Config.Sounds and Config.Sounds.cast then
        pcall(function()
            -- REPLACE WITH YOUR SOUND SYSTEM
            -- exports['lo_audio']:playSound({
            -- id = ('abyrion_cast_%s_%s'):format(sourceServerId, GetGameTimer()),
            -- url = Config.Sounds.cast,
            -- volume = math.max(0.1, 0.5 - (dist / 20.0)),
            -- loop = false,
            -- spatial = true,
            -- distance = 10.0,
            -- pos = { x = casterCoords.x, y = casterCoords.y, z = casterCoords.z }
            -- })
        end)
    end

    PlayWandFx(casterPed)
    SetTimeout(1500, function()
        StopWandFx(casterPed)
    end)
end)

RegisterNetEvent('th_abyrion:spawnCircle', function(sourceServerId, coords, level, circleId)
    if not coords then return end

    local centerCoords = vector3(coords.x, coords.y, coords.z)
    CreateFlameCircle(centerCoords, level, sourceServerId, circleId)
end)

RegisterNetEvent('th_abyrion:destroyCircle', function(circleId, animated)
    CleanupCircle(circleId, animated)
end)

RegisterNetEvent('th_abyrion:showBurningFx', function(targetServerId, duration)
    local targetPlayer = GetPlayerFromServerId(targetServerId)
    if targetPlayer == -1 then return end

    local targetPed = GetPlayerPed(targetPlayer)
    if not DoesEntityExist(targetPed) then return end

    CreateThread(function()
        if EnsureAsset('ns_ptfx') then
            UseParticleFxAssetNextCall('ns_ptfx')
            local fx = StartParticleFxLoopedOnEntity('fire', targetPed, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.8, false, false, false)
            if fx and fx ~= 0 then
                SetParticleFxLoopedColour(fx, 0.0, 1.0, 0.3, false)
                SetParticleFxLoopedAlpha(fx, 1.0)

                SetTimeout(duration, function()
                    if fx then
                        StopParticleFxLooped(fx, false)
                        RemoveParticleFx(fx, false)
                    end
                end)
            end
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for circleId, _ in pairs(activeCircles) do
        CleanupCircle(circleId)
    end

    for ped, handle in pairs(wandParticles) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    wandParticles = {}

    for handle, _ in pairs(allParticles) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    allParticles = {}

    RemoveNamedPtfxAsset('core')
    RemoveNamedPtfxAsset('ns_ptfx')
end)
