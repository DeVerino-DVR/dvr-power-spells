---@diagnostic disable: undefined-global, trailing-space, param-type-mismatch
local Config <const> = Config
local DrawLightWithRange = DrawLightWithRange
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local StartParticleFxNonLoopedOnEntity = StartParticleFxNonLoopedOnEntity
local StartParticleFxNonLoopedOnPedBone = StartParticleFxNonLoopedOnPedBone
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local DoesEntityExist = DoesEntityExist
local GetEntityCoords = GetEntityCoords
local GetGameTimer = GetGameTimer
local ShakeGameplayCam = ShakeGameplayCam
local Wait = Wait
local vector3 = vector3
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetCurrentPedWeaponEntityIndex = GetCurrentPedWeaponEntityIndex
local GetHashKey = GetHashKey
local SetCurrentPedWeapon = SetCurrentPedWeapon
local SetTimeout = SetTimeout
local CreateThread = CreateThread
local math_max = math.max
local math_floor = math.floor

local function getAnimationDuration()
    local anim = Config.Spell and Config.Spell.animation or {}
    local base = anim.duration or (Config.Spell and Config.Spell.castTime) or 0
    local speed = anim.speedMultiplier or 1.0
    if speed <= 0.0 then
        speed = 1.0
    end
    local buffer = anim.disarmBuffer or 120
    local extraDelay = anim.disarmExtraDelay or 0
    return math_max(0, math_floor((base / speed) + buffer + extraDelay))
end

local function getProjectileSpeed()
    local projectile = Config.Effect and Config.Effect.projectile or {}
    local speed = projectile.speed or 40.0
    return math_max(0.01, speed)
end

local function getProjectileTravelTime(distance)
    local speed = getProjectileSpeed()
    return (distance / speed) * 1000.0
end

local function playProjectileEffect(startCoords, targetCoords)
    local effect = Config.Effect
    if not effect or not effect.projectile then
        return
    end

    local projectile = effect.projectile
    local speed = getProjectileSpeed()

    if projectile.asset and projectile.name then
        lib.requestNamedPtfxAsset(projectile.asset)

        CreateThread(function()
            local distance = #(vector3(targetCoords.x, targetCoords.y, targetCoords.z) - vector3(startCoords.x, startCoords.y, startCoords.z))
            local travelTime = (distance / speed) * 1000
            local startTime = GetGameTimer()
            local endTime = startTime + travelTime

            local iterations = 0
            while GetGameTimer() < endTime do
                local elapsed = GetGameTimer() - startTime
                local progress = math.min(elapsed / travelTime, 1.0)

                local x = startCoords.x + (targetCoords.x - startCoords.x) * progress
                local y = startCoords.y + (targetCoords.y - startCoords.y) * progress
                local z = startCoords.z + (targetCoords.z - startCoords.z) * progress

                UseParticleFxAssetNextCall(projectile.asset)
                StartParticleFxNonLoopedAtCoord(
                    projectile.name,
                    x, y, z,
                    0.0, 0.0, 0.0,
                    projectile.scale or 1.0,
                    false, false, false
                )

                iterations = iterations + 1
                Wait(10)
            end

            RemoveNamedPtfxAsset(projectile.asset)
        end)
    end
end

local function playImpactEffect(coords)
    local effect = Config.Effect
    if not effect or not coords then
        return
    end

    local x, y, z = coords.x, coords.y, coords.z

    if effect.camera then
        if effect.camera.shake and effect.camera.amplitude then
            ShakeGameplayCam(effect.camera.shake, effect.camera.amplitude)
        end
    end

    if effect.impact and effect.impact.asset and effect.impact.name then
        lib.requestNamedPtfxAsset(effect.impact.asset)

        for i = 1, 3 do
            UseParticleFxAssetNextCall(effect.impact.asset)
            StartParticleFxNonLoopedAtCoord(
                effect.impact.name,
                x, y, z + 1.0,
                0.0, 0.0, 0.0,
                effect.impact.scale or 1.5,
                false, false, false
            )
            Wait(50)
        end

        SetTimeout(effect.impact.duration or 800, function()
            RemoveNamedPtfxAsset(effect.impact.asset)
        end)
    end

    if effect.light and effect.light.color then
        local light = effect.light
        CreateThread(function()
            local startTime = GetGameTimer()
            local duration = light.duration or 800
            while GetGameTimer() - startTime < duration do
                DrawLightWithRange(
                    x, y, z + 1.0,
                    light.color.r or 255,
                    light.color.g or 50,
                    light.color.b or 50,
                    light.distance or 5.0,
                    light.brightness or 2.5
                )
                Wait(0)
            end
        end)
    end
end

local function playDisarmHandSmoke(ped)
    if not DoesEntityExist(ped) then
        return
    end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    local handBone = GetPedBoneIndex(ped, 28422)
    UseParticleFxAssetNextCall('core')
    StartParticleFxNonLoopedOnPedBone(
        'ent_brk_gate_smoke',
        ped,
        0.02, 0.0, -0.05,
        0.0, 0.0, 0.0,
        handBone,
        1.0,
        false, false, false
    )

    SetTimeout(1200, function()
        RemoveNamedPtfxAsset('core')
    end)
end

RegisterNetEvent('th_desarmis:onCast', function(targetId)
    local messages = Config.Messages or {}

    if not targetId or targetId <= 0 then
        lib.notify(messages.noTarget)
        return
    end

    local targetPlayer = GetPlayerFromServerId(targetId)
    if targetPlayer == -1 then
        lib.notify(messages.noTarget)
        return
    end

    local targetPed = GetPlayerPed(targetPlayer)
    if not DoesEntityExist(targetPed) then
        lib.notify(messages.noTarget)
        return
    end

    local casterPed = cache.ped

    local startCoords
    local weapon = GetCurrentPedWeaponEntityIndex(casterPed)
    if weapon and DoesEntityExist(weapon) then
        startCoords = GetEntityCoords(weapon)
    else
        local handBone = GetPedBoneIndex(casterPed, 28422)
        startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)
    end

    local targetCoords = GetEntityCoords(targetPed)
    local distance = #(startCoords - targetCoords)
    local maxDistance = Config.MaxDistance or 15.0

    if distance > maxDistance then
        lib.notify(messages.noTarget)
        return
    end

    playProjectileEffect(startCoords, targetCoords)

    local effect = Config.Effect
    local travelTime = getProjectileTravelTime(distance)
    local animDelay = getAnimationDuration()
    local disarmDelay = math_max(travelTime, animDelay)

    SetTimeout(math.floor(disarmDelay), function()
        TriggerServerEvent('th_desarmis:disarmTarget', targetId)
    end)
end)

RegisterNetEvent('th_desarmis:disarmed', function()
    local messages = Config.Messages or {}
    lib.notify(messages.disarmed)

    local UNARMED_HASH = GetHashKey('WEAPON_UNARMED')
    SetCurrentPedWeapon(cache.ped, UNARMED_HASH, true)
end)

RegisterNetEvent('th_desarmis:playImpact', function(targetId)
    if not targetId or targetId <= 0 then
        return
    end

    local targetPlayer = GetPlayerFromServerId(targetId)
    if targetPlayer == -1 then
        return
    end

    local targetPed = GetPlayerPed(targetPlayer)
    if not DoesEntityExist(targetPed) then
        return
    end

    local targetCoords = GetEntityCoords(targetPed)
    playDisarmHandSmoke(targetPed)
    playImpactEffect(targetCoords)
end)
