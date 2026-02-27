---@diagnostic disable: undefined-global, trailing-space, unused-local, deprecated, param-type-mismatch
local putrefactioRayProps = {}
local wandParticles = {}
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local SetParticleFxLoopedEvolution = SetParticleFxLoopedEvolution
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local DeleteObject = DeleteObject
local DeleteEntity = DeleteEntity
local DoesEntityExist = DoesEntityExist
local AddExplosion = AddExplosion
local ShakeGameplayCam = ShakeGameplayCam
local GetGameTimer = GetGameTimer
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local GetEntityRotation = GetEntityRotation
local SetEntityCoords = SetEntityCoords
local SetEntityRotation = SetEntityRotation
local SetEntityAlpha = SetEntityAlpha
local SetEntityCollision = SetEntityCollision
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetEntityCompletelyDisableCollision = SetEntityCompletelyDisableCollision
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall

local TRAIL_COLOR <const> = { r = 40, g = 255, b = 110 }
local TRAIL_RADIUS <const> = 6.5
local TRAIL_INTENSITY <const> = 12.0
local TRAIL_INTERVAL <const> = 110
local IMPACT_COLOR <const> = { r = 55, g = 255, b = 140 }
local IMPACT_RADIUS <const> = 8.0
local IMPACT_INTENSITY <const> = 15.0
local IMPACT_DURATION <const> = 520

local function PulseLight(coords, color, radius, intensity, duration)
    if not coords then
        return
    end

    local start <const> = GetGameTimer()
    local total <const> = duration or 400
    local range <const> = radius or 5.0
    local power <const> = intensity or 8.0
    local clr <const> = color or IMPACT_COLOR

    CreateThread(function()
        while true do
            local elapsed <const> = GetGameTimer() - start
            if elapsed >= total then
                break
            end

            local fade <const> = 1.0 - (elapsed / total)
            DrawLightWithRange(
                coords.x, coords.y, coords.z,
                clr.r, clr.g, clr.b,
                range,
                power * fade
            )
            Wait(0)
        end
    end)
end

local function RotationToDirection(rotation)
    local adjustedRotation <const> = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction <const> = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local function CreateWandParticles(playerPed, isNetworked)
    local weapon <const> = GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or not DoesEntityExist(weapon) then
        return
    end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    UseParticleFxAsset('core')
    local handle
    if isNetworked then
        handle = StartNetworkedParticleFxLoopedOnEntity('veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.5, false, false, false)
    else
        handle = StartParticleFxLoopedOnEntity('veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.5, false, false, false)
    end

    SetParticleFxLoopedEvolution(handle, 'speed', 1.0, false)
    SetParticleFxLoopedColour(handle, 0.1, 1.0, 0.4, false)
    SetParticleFxLoopedAlpha(handle, 255.0)

    wandParticles[playerPed] = handle

    local handBone <const> = Config.Projectile.handBone or 28422
    local flashCoords = GetWorldPositionOfEntityBone(playerPed, handBone) or GetEntityCoords(playerPed)
    PulseLight(flashCoords, TRAIL_COLOR, 4.3, 11.0, 360)

    return handle
end

local function RemoveWandParticles(playerPed)
    if wandParticles[playerPed] then
        StopParticleFxLooped(wandParticles[playerPed], false)
        RemoveParticleFx(wandParticles[playerPed], false)
        wandParticles[playerPed] = nil
        RemoveNamedPtfxAsset('core')
    end
end

local function CreatePutrefactioProjectile(startCoords, targetCoords, sourceServerId)
    local playerPed <const> = cache.ped

    local propModel <const> = GetHashKey(Config.Projectile.model)
    lib.requestModel(propModel, 5000)

    local rayProp <const> = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(rayProp, false, false)
    SetEntityAsMissionEntity(rayProp, true, true)
    SetEntityCompletelyDisableCollision(rayProp, false, false)
    SetEntityAlpha(rayProp, 255, false)

    local direction = vector3(
        targetCoords.x - startCoords.x,
        targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z
    )
    local distance = #direction
    direction = direction / distance

    local heading <const> = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch <const> = -math.deg(math.asin(direction.z))
    local roll <const> = 0.0

    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)

    local duration <const> = Config.Projectile.duration or (distance / Config.Projectile.speed) * 1000.0
    local startTime <const> = GetGameTimer()
    local endTime <const> = startTime + duration

    putrefactioRayProps[rayProp] = {
        prop = rayProp,
        startCoords = startCoords,
        targetCoords = targetCoords,
        direction = direction,
        distance = distance,
        startTime = startTime,
        endTime = endTime,
        speed = Config.Projectile.speed,
        heading = heading,
        pitch = pitch,
        roll = roll,
        sourceServerId = sourceServerId,
        lastTrailFx = 0
    }
end

CreateThread(function()
    while true do
        local hasProjectiles = next(putrefactioRayProps) ~= nil
        if not hasProjectiles then
            Wait(200)
        else
            local currentTime <const> = GetGameTimer()

            for propId, data in pairs(putrefactioRayProps) do
                if type(data) == "table" and DoesEntityExist(data.prop) then
                    if currentTime < data.endTime then
                        local progress = (currentTime - data.startTime) / (data.endTime - data.startTime)
                        progress = math.min(progress, 1.0)

                        local newPos <const> = vector3(
                            data.startCoords.x + (data.direction.x * data.distance * progress),
                            data.startCoords.y + (data.direction.y * data.distance * progress),
                            data.startCoords.z + (data.direction.z * data.distance * progress)
                        )

                        SetEntityCoords(data.prop, newPos.x, newPos.y, newPos.z, false, false, false, false)
                        DrawLightWithRange(newPos.x, newPos.y, newPos.z, TRAIL_COLOR.r, TRAIL_COLOR.g, TRAIL_COLOR.b, TRAIL_RADIUS, TRAIL_INTENSITY)

                        if currentTime - (data.lastTrailFx or 0) >= TRAIL_INTERVAL then
                            RequestNamedPtfxAsset('core')
                            while not HasNamedPtfxAssetLoaded('core') do
                                Wait(0)
                            end

                            UseParticleFxAssetNextCall('core')
                            StartParticleFxNonLoopedAtCoord('ent_amb_elec_crackle', newPos.x, newPos.y, newPos.z, 0.0, 0.0, 0.0, 0.7, false, false, false)
                            data.lastTrailFx = currentTime
                        end
                    else
                        local propCoords <const> = GetEntityCoords(data.prop)

                        -- Jouer le son d'impact
                        if Config.ImpactSound and Config.ImpactSound.url then
                            local soundId = 'putrefactio_impact_' .. propId
                            -- REPLACE WITH YOUR SOUND SYSTEM
                            -- exports['lo_audio']:playSound({
                            -- id = soundId,
                            -- url = Config.ImpactSound.url,
                            -- volume = Config.ImpactSound.volume or 0.5,
                            -- pos = { x = propCoords.x, y = propCoords.y, z = propCoords.z },
                            -- radius = Config.ImpactSound.radius or 30.0
                            -- })
                        end

                        AddExplosion(
                            propCoords.x, propCoords.y, propCoords.z,
                            Config.Effects.explosion.type,
                            Config.Effects.explosion.damage,
                            Config.Effects.explosion.isAudible,
                            Config.Effects.explosion.isInvisible,
                            Config.Effects.explosion.cameraShake
                        )

                        RequestNamedPtfxAsset('core')
                        while not HasNamedPtfxAssetLoaded('core') do
                            Wait(0)
                        end
                        UseParticleFxAssetNextCall('core')
                        StartParticleFxNonLoopedAtCoord('ent_sht_elec_fire_sp', propCoords.x, propCoords.y, propCoords.z + 0.2, 0.0, 0.0, 0.0, 1.6, false, false, false)
                        PulseLight(propCoords, IMPACT_COLOR, IMPACT_RADIUS, IMPACT_INTENSITY, IMPACT_DURATION)

                        local playerCoords <const> = GetEntityCoords(cache.ped)
                        local distance = #(playerCoords - propCoords)

                        if distance < Config.Effects.cameraShake.maxDistance then
                            local intensity = Config.Effects.cameraShake.intensity * (1.0 - (distance / Config.Effects.cameraShake.maxDistance))
                            ShakeGameplayCam(Config.Effects.cameraShake.name, intensity)
                        end

                        local effects <const> = {}

                        RequestNamedPtfxAsset(Config.Effects.fireParticles.asset)
                        while not HasNamedPtfxAssetLoaded(Config.Effects.fireParticles.asset) do
                            Wait(0)
                        end

                        for angle = 0, 360, (360 / Config.Effects.fireParticles.count) do
                            local rad <const> = math.rad(angle)
                            local offsetX <const> = math.cos(rad) * Config.Effects.fireParticles.radius
                            local offsetY <const> = math.sin(rad) * Config.Effects.fireParticles.radius

                            UseParticleFxAssetNextCall(Config.Effects.fireParticles.asset)
                            local fx <const> = StartParticleFxLoopedAtCoord(
                                Config.Effects.fireParticles.name,
                                propCoords.x + offsetX,
                                propCoords.y + offsetY,
                                propCoords.z + 0.2,
                                0.0, 0.0, 0.0,
                                Config.Effects.fireParticles.scale,
                                false, false, false, false
                            )
                            SetParticleFxLoopedColour(fx, 0.0, 1.0, 0.0, 1.0)
                            table.insert(effects, fx)
                        end

                        RequestNamedPtfxAsset(Config.Effects.smokeParticles.asset)
                        while not HasNamedPtfxAssetLoaded(Config.Effects.smokeParticles.asset) do
                            Wait(0)
                        end

                        for i = 1, Config.Effects.smokeParticles.count do
                            UseParticleFxAssetNextCall(Config.Effects.smokeParticles.asset)
                            local smoke = StartParticleFxLoopedAtCoord(
                                Config.Effects.smokeParticles.name,
                                propCoords.x, propCoords.y, propCoords.z + 0.5,
                                0.0, 0.0, 0.0,
                                Config.Effects.smokeParticles.scale,
                                false, false, false, false
                            )
                            table.insert(effects, smoke)
                        end

                        SetTimeout(Config.Effects.fireParticles.duration, function()
                            for _, fx in ipairs(effects) do
                                StopParticleFxLooped(fx, 0)
                                RemoveParticleFx(fx, false)
                            end
                            RemoveNamedPtfxAsset(Config.Effects.fireParticles.asset)
                            RemoveNamedPtfxAsset(Config.Effects.smokeParticles.asset)
                        end)

                        DeleteObject(data.prop)
                        SetEntityAsMissionEntity(data.prop, false, true)
                        DeleteEntity(data.prop)
                        putrefactioRayProps[propId] = nil
                    end
                else
                    putrefactioRayProps[propId] = nil
                end
            end

            Wait(0)
        end
    end
end)

RegisterNetEvent('dvr_putrefactio:prepareProjectile', function()
    local casterPed <const> = cache.ped

    CreateWandParticles(casterPed, true)

    CreateThread(function()
        local speedMult = (Config.Animation and Config.Animation.speedMultiplier) or 1.0
        local delay = Config.Animation.propsDelay or 2100
        local adjustedDelay = delay / math.max(speedMult * 0.6, 0.1) + 50
        Wait(math.floor(adjustedDelay))
        local handBone <const> = GetPedBoneIndex(casterPed, Config.Projectile.handBone)
        local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)

        local camCoords <const> = GetGameplayCamCoord()
        local camRot <const> = GetGameplayCamRot(2)
        local direction <const> = RotationToDirection(camRot)

        local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, 1000)
        local finalTargetCoords

        if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
            finalTargetCoords = coords
        else
            finalTargetCoords = vector3(
                camCoords.x + direction.x * 1000.0,
                camCoords.y + direction.y * 1000.0,
                camCoords.z + direction.z * 1000.0
            )
        end

        TriggerServerEvent('dvr_putrefactio:broadcastProjectile', finalTargetCoords)

        Wait(800)
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('dvr_putrefactio:otherPlayerCasting', function(sourceServerId)
    local myServerId <const> = GetPlayerServerId(PlayerId())

    if sourceServerId == myServerId then
        return
    end

    local casterPlayer <const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then
        return
    end

    local casterPed <const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then
        return
    end

    CreateWandParticles(casterPed, true)

    SetTimeout(3000, function()
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('dvr_putrefactio:fireProjectile', function(sourceServerId, targetCoords)
    local casterPlayer <const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then
        return
    end

    local casterPed <const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then
        return
    end

    local handBone <const> = GetPedBoneIndex(casterPed, Config.Projectile.handBone)
    local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)

    CreatePutrefactioProjectile(startCoords, targetCoords, sourceServerId)
end)

RegisterNetEvent('dvr_putrefactio:teleportTarget', function()
    local ped <const> = cache.ped
    local coords <const> = Config.TeleportCoords

    DoScreenFadeOut(500)
    Wait(500)

    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w)

    Wait(500)
    DoScreenFadeIn(500)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for propId, data in pairs(putrefactioRayProps) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            DeleteObject(data.prop)
            DeleteEntity(data.prop)
        end
    end

    for playerPed, handle in pairs(wandParticles) do
        if handle then
            StopParticleFxLooped(handle, false)
            RemoveParticleFx(handle, false)
        end
    end

    putrefactioRayProps = {}
    wandParticles = {}
end)
