---@diagnostic disable: trailing-space, undefined-global
local GetEntityCoords = GetEntityCoords
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local GetEntityForwardVector = GetEntityForwardVector
local NetworkRequestControlOfEntity = NetworkRequestControlOfEntity
local NetworkHasControlOfEntity = NetworkHasControlOfEntity
local NetToPed = NetToPed
local DoesEntityExist = DoesEntityExist
local IsPedDeadOrDying = IsPedDeadOrDying
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local SetTimeout = SetTimeout
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local ShakeGameplayCam = ShakeGameplayCam
local AddExplosion = AddExplosion
local TaskPlayAnim = TaskPlayAnim
local vector3 = vector3
local SetPedToRagdoll = SetPedToRagdoll
local SetEntityVelocity = SetEntityVelocity
local ApplyForceToEntity = ApplyForceToEntity

local function ResolveCastLevel(spellId, sourceId, providedLevel)
    local numeric = tonumber(providedLevel)
    if numeric then
        return math.floor(numeric)
    end

    local cache = spellCastLevelCache
    if cache and cache[sourceId] and cache[sourceId][spellId] and cache[sourceId][spellId].level then
        return math.floor(tonumber(cache[sourceId][spellId].level) or 0)
    end

    return 0
end

local function BuildRepulsarSettings(level, incoming)
    if incoming then
        return {
            radius = incoming.radius or Config.expulsar.radius,
            force = incoming.force or Config.expulsar.force,
            upwardForce = incoming.upwardForce or Config.expulsar.upwardForce
        }
    end

    local lvl = math.max(0, math.floor(tonumber(level) or 0))
    local ratio = math.min(lvl / 5.0, 1.0)
    local minRadius = 12.0
    local minForce = 18.0
    local minUpward = 2.5

    return {
        radius = minRadius + ((Config.expulsar.radius - minRadius) * ratio),
        force = minForce + ((Config.expulsar.force - minForce) * ratio),
        upwardForce = minUpward + ((Config.expulsar.upwardForce - minUpward) * ratio)
    }
end

local function CreateShockwaveEffects(coords)
    RequestNamedPtfxAsset(Config.Effects.shockwaveParticles.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.shockwaveParticles.asset) do
        Wait(0)
    end
    
    UseParticleFxAssetNextCall(Config.Effects.shockwaveParticles.asset)
    local fx = StartParticleFxNonLoopedAtCoord(
        Config.Effects.shockwaveParticles.name,
        coords.x,
        coords.y,
        coords.z,
        0.0, 0.0, 0.0,
        Config.Effects.shockwaveParticles.scale,
        false, false, false
    )
    
    SetTimeout(100, function()
        RemoveNamedPtfxAsset(Config.Effects.shockwaveParticles.asset)
    end)
end

local SOUND_URL = 'YOUR_SOUND_URL_HERE'
local SOUND_MAX_DISTANCE = 25.0
local SOUND_VOLUME = 0.3

RegisterNetEvent('th_repulsar:playSound', function(sourceServerId, casterCoords)
    if not casterCoords then return end

    local myCoords = GetEntityCoords(cache.ped)
    local dist = #(myCoords - vector3(casterCoords.x, casterCoords.y, casterCoords.z))

    if dist <= SOUND_MAX_DISTANCE then
        local volume = math.max(0.05, SOUND_VOLUME * (1.0 - (dist / SOUND_MAX_DISTANCE)))
        pcall(function()
            -- REPLACE WITH YOUR SOUND SYSTEM
            -- exports['lo_audio']:playSound({
            -- id = ('expulsar_cast_%s_%s'):format(sourceServerId, GetGameTimer()),
            -- url = SOUND_URL,
            -- volume = volume,
            -- loop = false,
            -- spatial = true,
            -- distance = 10.0,
            -- pos = { x = casterCoords.x, y = casterCoords.y, z = casterCoords.z }
            -- })
        end)
    end
end)

RegisterNetEvent('th_repulsar:castSpell', function(settings, level, targetServerId)
    local casterPed <const> = cache.ped
    local targetId = tonumber(targetServerId)
    local spellLevel <const> = ResolveCastLevel('expulsar', GetPlayerServerId(PlayerId()), level)
    local expulsarSettings <const> = BuildRepulsarSettings(spellLevel, settings)

    if not targetId or targetId <= 0 then
        lib.notify({
            title = 'Expulsar',
            description = 'Aucune cible visée',
            type = 'error',
            icon = 'wind'
        })
        return
    end

    local targetPlayer = GetPlayerFromServerId(targetId)
    if not targetPlayer or targetPlayer == -1 then
        lib.notify({
            title = 'Expulsar',
            description = 'Cible introuvable',
            type = 'error',
            icon = 'wind'
        })
        return
    end

    local targetPed = GetPlayerPed(targetPlayer)
    if not targetPed or targetPed == 0 or IsPedDeadOrDying(targetPed, true) then
        lib.notify({
            title = 'Expulsar',
            description = 'Cible invalide',
            type = 'error',
            icon = 'wind'
        })
        return
    end

    local casterCoords = GetEntityCoords(casterPed)
    local targetCoords = GetEntityCoords(targetPed)
    local distance = #(targetCoords - casterCoords)
    local maxDistance = expulsarSettings.radius or Config.expulsar.radius or 20.0

    if distance > maxDistance then
        lib.notify({
            title = 'Expulsar',
            description = 'Cible hors de portée',
            type = 'error',
            icon = 'wind'
        })
        return
    end

    lib.requestAnimDict(Config.Animation.dict)
    TaskPlayAnim(
        casterPed,
        Config.Animation.dict,
        Config.Animation.name,
        8.0, -8.0,
        Config.Animation.duration,
        Config.Animation.flag,
        0,
        false, false, false
    )

    Wait(500)

    CreateShockwaveEffects(targetCoords)

    AddExplosion(
        targetCoords.x, targetCoords.y, targetCoords.z,
        Config.Effects.explosion.type,
        Config.Effects.explosion.damage,
        Config.Effects.explosion.isAudible,
        Config.Effects.explosion.isInvisible,
        Config.Effects.explosion.cameraShake
    )

    local direction = vector3(
        targetCoords.x - casterCoords.x,
        targetCoords.y - casterCoords.y,
        0.0
    )
    local magnitude = #direction

    if magnitude <= 0.01 then
        local forward = GetEntityForwardVector(casterPed)
        direction = vector3(forward.x, forward.y, 0.0)
        magnitude = #direction
    end

    if magnitude > 0 then
        direction = direction / magnitude
    end

    local velocity = vector3(
        direction.x * expulsarSettings.force,
        direction.y * expulsarSettings.force,
        expulsarSettings.upwardForce
    )

    TriggerServerEvent('th_repulsar:applyForce', targetId, velocity)

    local maxShakeDistance = math.min(maxDistance, Config.Effects.cameraShake.maxDistance or maxDistance)
    if distance < maxShakeDistance then
        local intensity = (Config.Effects.cameraShake.intensity or 0.3) * (expulsarSettings.force / Config.expulsar.force)
        intensity = intensity * (1.0 - (distance / maxShakeDistance))
        ShakeGameplayCam(Config.Effects.cameraShake.name, intensity)
    end
end)

RegisterNetEvent('th_repulsar:receiveForce', function(velocity)
    if not velocity then return end
    
    local playerPed <const> = cache.ped
    
    SetPedToRagdoll(playerPed, 2000, 2000, 0, false, false, false)
    
    SetEntityVelocity(playerPed, velocity.x, velocity.y, velocity.z)
    
    ApplyForceToEntity(
        playerPed,
        1,
        velocity.x, velocity.y, velocity.z,
        0.0, 0.0, 0.0,
        0,
        false, true, true, false, true
    )
end)

RegisterNetEvent('th_repulsar:visualForce', function(targetServerId, targetNetId, velocity)
    if not targetServerId or not velocity then return end

    local myId = GetPlayerServerId(PlayerId())
    if myId == targetServerId then
        return
    end

    local targetPlayer = GetPlayerFromServerId(targetServerId)
    local targetPed = (targetPlayer and targetPlayer ~= -1) and GetPlayerPed(targetPlayer) or nil

    if (not targetPed or targetPed == 0 or not DoesEntityExist(targetPed)) and targetNetId then
        targetPed = NetToPed(targetNetId)
    end

    if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
        return
    end

    local attempts = 0
    while not NetworkHasControlOfEntity(targetPed) and attempts < 5 do
        NetworkRequestControlOfEntity(targetPed)
        Wait(0)
        attempts = attempts + 1
    end

    SetPedToRagdoll(targetPed, 2000, 2000, 0, false, false, false)
    SetEntityVelocity(targetPed, velocity.x or 0.0, velocity.y or 0.0, velocity.z or 0.0)
    ApplyForceToEntity(
        targetPed,
        1,
        velocity.x or 0.0, velocity.y or 0.0, velocity.z or 0.0,
        0.0, 0.0, 0.0,
        0,
        false, true, true, false, true
    )
end)
