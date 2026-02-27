---@diagnostic disable: trailing-space, deprecated, undefined-global
local wandParticles = {}
local reviveEffects = {}
local ravivioRayProps = {}

local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local SetParticleFxLoopedEvolution = SetParticleFxLoopedEvolution
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset

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

    RequestNamedPtfxAsset(Config.Effects.wandParticles.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.wandParticles.asset) do
        Wait(0)
    end

    UseParticleFxAsset(Config.Effects.wandParticles.asset)
    local handle
    if isNetworked then
        handle = StartNetworkedParticleFxLoopedOnEntity(
            Config.Effects.wandParticles.name,
            weapon,
            0.95, 0.0, 0.1,
            0.0, 0.0, 0.0,
            Config.Effects.wandParticles.scale,
            false, false, false
        )
    else
        handle = StartParticleFxLoopedOnEntity(
            Config.Effects.wandParticles.name,
            weapon,
            0.95, 0.0, 0.1,
            0.0, 0.0, 0.0,
            Config.Effects.wandParticles.scale,
            false, false, false
        )
    end

    SetParticleFxLoopedEvolution(handle, 'speed', 1.0, false)
    SetParticleFxLoopedColour(
        handle,
        Config.Effects.wandParticles.color.r,
        Config.Effects.wandParticles.color.g,
        Config.Effects.wandParticles.color.b,
        false
    )
    SetParticleFxLoopedAlpha(handle, 255.0)

    wandParticles[playerPed] = handle

    return handle
end

local function RemoveWandParticles(playerPed)
    if wandParticles[playerPed] then
        StopParticleFxLooped(wandParticles[playerPed], false)
        RemoveParticleFx(wandParticles[playerPed], false)
        wandParticles[playerPed] = nil
        RemoveNamedPtfxAsset(Config.Effects.wandParticles.asset)
    end
end

local function CreateReviveEffect(targetPed)
    if not DoesEntityExist(targetPed) then
        return
    end

    local coords = GetEntityCoords(targetPed)

    RequestNamedPtfxAsset(Config.Effects.reviveParticles.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.reviveParticles.asset) do
        Wait(0)
    end

    UseParticleFxAsset(Config.Effects.reviveParticles.asset)
    local handle = StartParticleFxLoopedAtCoord(
        Config.Effects.reviveParticles.name,
        coords.x,
        coords.y,
        coords.z + 1.0,
        0.0, 0.0, 0.0,
        Config.Effects.reviveParticles.scale,
        false, false, false, false
    )

    SetParticleFxLoopedColour(
        handle,
        Config.Effects.reviveParticles.color.r,
        Config.Effects.reviveParticles.color.g,
        Config.Effects.reviveParticles.color.b,
        false
    )

    SetTimeout(Config.Effects.reviveParticles.duration, function()
        StopParticleFxLooped(handle, 0)
        RemoveParticleFx(handle, false)
        RemoveNamedPtfxAsset(Config.Effects.reviveParticles.asset)
    end)
end

local function CreateRavivioProjectile(startCoords, targetCoords, targetServerId, casterServerId)
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

    ravivioRayProps[rayProp] = {
        prop = rayProp,
        startCoords = startCoords,
        targetCoords = targetCoords,
        direction = direction,
        distance = distance,
        startTime = startTime,
        endTime = endTime,
        speed = Config.Projectile.speed,
        targetServerId = targetServerId,
        casterServerId = casterServerId
    }
end

RegisterNetEvent('th_ravivio:prepareCast', function()
    local casterPed <const> = cache.ped

    CreateWandParticles(casterPed, true)

    CreateThread(function()
        Wait(Config.Animation.propsDelay)

        local camCoords <const> = GetGameplayCamCoord()
        local camRot <const> = GetGameplayCamRot(2)
        local direction <const> = RotationToDirection(camRot)

        local _, _, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, 1000)
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

        TriggerServerEvent('th_ravivio:broadcastProjectile', finalTargetCoords)

        Wait(800)
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_ravivio:fireProjectile', function(sourceServerId, targetCoords, targetPlayerId)
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

    CreateRavivioProjectile(startCoords, targetCoords, targetPlayerId, sourceServerId)
end)

RegisterNetEvent('th_ravivio:otherPlayerCasting', function(sourceServerId)
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

    SetTimeout(2000, function()
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_ravivio:playReviveEffect', function(targetServerId)
    local targetPlayer <const> = GetPlayerFromServerId(targetServerId)
    if targetPlayer == -1 then
        return
    end

    local targetPed <const> = GetPlayerPed(targetPlayer)
    if not DoesEntityExist(targetPed) then
        return
    end

    CreateReviveEffect(targetPed)
end)

-- Thread pour animer les projectiles
CreateThread(function()
    while true do
        Wait(1)

        local currentTime <const> = GetGameTimer()
        local myServerId = GetPlayerServerId(PlayerId())

        for propId, data in pairs(ravivioRayProps) do
            if type(data) == "table" then
                if DoesEntityExist(data.prop) then
                    if currentTime < data.endTime then
                        local progress = (currentTime - data.startTime) / (data.endTime - data.startTime)
                        progress = math.min(progress, 1.0)

                        local newPos <const> = vector3(
                            data.startCoords.x + (data.direction.x * data.distance * progress),
                            data.startCoords.y + (data.direction.y * data.distance * progress),
                            data.startCoords.z + (data.direction.z * data.distance * progress)
                        )

                        SetEntityCoords(data.prop, newPos.x, newPos.y, newPos.z, false, false, false, false)
                    else
                        -- Le projectile est arrivé à destination
                        if DoesEntityExist(data.prop) then
                            DeleteObject(data.prop)
                            SetEntityAsMissionEntity(data.prop, false, true)
                            DeleteEntity(data.prop)
                        end

                        -- Seul le caster déclenche le revive (pour éviter les duplications)
                        if data.casterServerId and data.casterServerId == myServerId then
                            if data.targetServerId and data.targetServerId > 0 then
                                TriggerServerEvent('th_ravivio:projectileHit', data.targetServerId)
                            end
                        end

                        ravivioRayProps[propId] = nil
                    end
                else
                    ravivioRayProps[propId] = nil
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for propId, data in pairs(ravivioRayProps) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            DeleteObject(data.prop)
            DeleteEntity(data.prop)
        end
    end

    for _, handle in pairs(wandParticles) do
        if handle then
            StopParticleFxLooped(handle, false)
            RemoveParticleFx(handle, false)
        end
    end

    ravivioRayProps = {}
    wandParticles = {}
    reviveEffects = {}
end)
