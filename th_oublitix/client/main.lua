---@diagnostic disable: trailing-space, undefined-global, param-type-mismatch
local Config = require 'config'
local SendNUIMessage = SendNUIMessage
local oublitixRayProps = {}
local wandParticles = {}
local GetCurrentPedWeaponEntityIndex = GetCurrentPedWeaponEntityIndex
local DoesEntityExist = DoesEntityExist
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetPlayerServerId = GetPlayerServerId
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local SetTimeout = SetTimeout
local DeleteObject = DeleteObject
local DeleteEntity = DeleteEntity
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetEntityAlpha = SetEntityAlpha
local SetEntityCollision = SetEntityCollision
local SetEntityCompletelyDisableCollision = SetEntityCompletelyDisableCollision
local SetEntityCoords = SetEntityCoords
local SetEntityRotation = SetEntityRotation
local SetEntityHeading = SetEntityHeading
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local IsPedAPlayer = IsPedAPlayer
local IsEntityAPed = IsEntityAPed
local GetGameTimer = GetGameTimer
local GetHashKey = GetHashKey
local DisableAllControlActions = DisableAllControlActions
local EnableControlAction = EnableControlAction
local RequestAnimDict = RequestAnimDict
local HasAnimDictLoaded = HasAnimDictLoaded
local TaskPlayAnim = TaskPlayAnim
local RemoveAnimDict = RemoveAnimDict
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local ShakeGameplayCam = ShakeGameplayCam
local StopGameplayCamShaking = StopGameplayCamShaking

local function ResolveSpellLevel(spellId, sourceId, providedLevel)
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

local function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
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
    
    SetParticleFxLoopedColour(handle, 
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

local function CreateOublitixProjectile(startCoords, targetCoords, sourceServerId, targetEntity, level)
    local propModel = GetHashKey(Config.Projectile.model)
    lib.requestModel(propModel, 5000)
    
    local rayProp = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(rayProp, false, false)
    SetEntityAsMissionEntity(rayProp, true, true)
    SetEntityCompletelyDisableCollision(rayProp, false, false)
    SetEntityAlpha(rayProp, 255, false)
    
    RequestNamedPtfxAsset(Config.Effects.projectileTrail.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.projectileTrail.asset) do
        Wait(0)
    end
    
    UseParticleFxAsset(Config.Effects.projectileTrail.asset)
    local trailFx = StartParticleFxLoopedOnEntity(
        Config.Effects.projectileTrail.name,
        rayProp,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        Config.Effects.projectileTrail.scale,
        false, false, false
    )
    
    if trailFx then
        SetParticleFxLoopedColour(trailFx,
            Config.Effects.projectileTrail.color.r,
            Config.Effects.projectileTrail.color.g,
            Config.Effects.projectileTrail.color.b,
            false
        )
    end
    
    local direction = vector3(
        targetCoords.x - startCoords.x,
        targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z
    )
    local distance <const> = #direction
    direction = direction / distance
    
    local heading <const> = math.deg(math.atan(direction.y, direction.x)) + 90.0
    local pitch <const> = -math.deg(math.asin(direction.z))
    local roll <const> = 0.0
    
    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)
    
    local flightDuration <const> = Config.Projectile.duration or (distance / Config.Projectile.speed) * 1000.0
    local startTime <const> = GetGameTimer()
    local endTime <const> = startTime + flightDuration
    local spellLevel = math.max(0, math.floor(tonumber(level) or 0))
    
    oublitixRayProps[rayProp] = {
        prop = rayProp,
        startCoords = startCoords,
        targetCoords = targetCoords,
        direction = direction,
        distance = distance,
        startTime = startTime,
        endTime = endTime,
        targetEntity = targetEntity,
        trailFx = trailFx,
        level = spellLevel,
        sourceServerId = sourceServerId
    }
end

-- Thread to animate projectiles
CreateThread(function()
    while true do
        Wait(1)
        
        local currentTime <const> = GetGameTimer()
        
        for propId, data in pairs(oublitixRayProps) do
            if type(data) == "table" then
                if DoesEntityExist(data.prop) then
                    if currentTime < data.endTime then
                        local progress = (currentTime - data.startTime) / (data.endTime - data.startTime)
                        progress = math.min(progress, 1.0)
                        
                        local newPos = vector3(
                            data.startCoords.x + (data.direction.x * data.distance * progress),
                            data.startCoords.y + (data.direction.y * data.distance * progress),
                            data.startCoords.z + (data.direction.z * data.distance * progress)
                        )
                        
                        SetEntityCoords(data.prop, newPos.x, newPos.y, newPos.z, false, false, false, false)
                    else
                        if DoesEntityExist(data.prop) then 
                            if data.trailFx then
                                StopParticleFxLooped(data.trailFx, 0)
                                RemoveParticleFx(data.trailFx, false)
                            end
                            RemoveNamedPtfxAsset(Config.Effects.projectileTrail.asset)
                            
                            if data.targetEntity and DoesEntityExist(data.targetEntity) then
                                if IsEntityAPed(data.targetEntity) then
                                    if IsPedAPlayer(data.targetEntity) then
                                        local targetPlayer = NetworkGetPlayerIndexFromPed(data.targetEntity)
                                        local targetServerId = GetPlayerServerId(targetPlayer)
                                        TriggerServerEvent('th_oublitix:applySpell', targetServerId, data.level)
                                    end
                                end
                            end
                            
                            DeleteObject(data.prop)
                            SetEntityAsMissionEntity(data.prop, false, true)
                            DeleteEntity(data.prop)
                        end
                        
                        oublitixRayProps[propId] = nil
                    end
                else
                    oublitixRayProps[propId] = nil
                end
            end
        end
    end
end)

RegisterNetEvent('th_oublitix:prepareProjectile', function()
    local casterPed = cache.ped
    
    CreateWandParticles(casterPed, true)
    
    CreateThread(function()
        Wait(Config.Spell.animation.propsDelay or 800)
        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        local direction = RotationToDirection(camRot)
        
        local _, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, 1000)
        local finalTargetCoords
        local targetEntity = nil
        
        if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
            finalTargetCoords = coords
            if entityHit and DoesEntityExist(entityHit) and IsEntityAPed(entityHit) then
                targetEntity = entityHit
            end
        else
            finalTargetCoords = vector3(
                camCoords.x + direction.x * 1000.0,
                camCoords.y + direction.y * 1000.0,
                camCoords.z + direction.z * 1000.0
            )
        end
        
        TriggerServerEvent('th_oublitix:broadcastProjectile', finalTargetCoords, targetEntity)
        
        Wait(800)
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_oublitix:otherPlayerCasting', function(sourceServerId)
    local myServerId = GetPlayerServerId(PlayerId())
    
    if sourceServerId == myServerId then
        return
    end
    
    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then 
        return 
    end
    
    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then 
        return 
    end
      
    CreateWandParticles(casterPed, true)
    
    SetTimeout(2000, function()
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_oublitix:fireProjectile', function(sourceServerId, targetCoords, targetEntity, level)
    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then 
        return 
    end
    
    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then 
        return 
    end

    local spellLevel = ResolveSpellLevel('oublitix', sourceServerId, level)
    local handBone = GetPedBoneIndex(casterPed, Config.Projectile.handBone)
    local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)
    
    CreateOublitixProjectile(startCoords, targetCoords, sourceServerId, targetEntity, spellLevel)
end)

RegisterNetEvent('th_oublitix:applyEffect', function(rollbackMinutes, targetCoords)
    local playerPed = cache.ped
    local currentCoords = GetEntityCoords(playerPed)
    local currentHeading = GetEntityHeading(playerPed)
    
    -- Show notification
    lib.notify({
        title = Config.Messages.targetAffected.title,
        description = Config.Messages.targetAffected.description,
        type = Config.Messages.targetAffected.type,
        icon = Config.Messages.targetAffected.icon
    })
    
    -- Play teleport effect (departure)
    RequestNamedPtfxAsset(Config.Effects.teleportEffect.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.teleportEffect.asset) do
        Wait(0)
    end
    
    UseParticleFxAsset(Config.Effects.teleportEffect.asset)
    local teleportFx = StartParticleFxLoopedAtCoord(
        Config.Effects.teleportEffect.name,
        currentCoords.x, currentCoords.y, currentCoords.z,
        0.0, 0.0, 0.0,
        Config.Effects.teleportEffect.scale,
        false, false, false, false
    )
    
    Wait(300)
    
    -- Teleport to target position
    if targetCoords then
        SetEntityCoords(playerPed, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
    end
    
    -- Stop teleport effect
    if teleportFx then
        StopParticleFxLooped(teleportFx, 0)
        RemoveParticleFx(teleportFx, false)
    end
    RemoveNamedPtfxAsset(Config.Effects.teleportEffect.asset)
    
    -- Play sleep emote (kept for RP posture) and ensure it stays for the whole black screen
    RequestAnimDict(Config.SleepEmote.dict)
    while not HasAnimDictLoaded(Config.SleepEmote.dict) do
        Wait(0)
    end
    TaskPlayAnim(playerPed, Config.SleepEmote.dict, Config.SleepEmote.name, 8.0, 8.0, -1, Config.SleepEmote.flag, 0, false, false, false)
    local blackEndTime = GetGameTimer() + (Config.BlackScreenDuration * 1000)
    CreateThread(function()
        while GetGameTimer() < blackEndTime do
            if not IsEntityPlayingAnim(playerPed, Config.SleepEmote.dict, Config.SleepEmote.name, 3) then
                TaskPlayAnim(playerPed, Config.SleepEmote.dict, Config.SleepEmote.name, 8.0, 8.0, -1, Config.SleepEmote.flag, 0, false, false, false)
            end
            Wait(500)
        end
    end)
    
    -- Prepare forget message
    local forgetMessage = string.format(Config.Messages.forgetMessage, rollbackMinutes)
    
    -- Show UI overlay and message (acts as fade-to-black) on local NUI
    SendNUIMessage({ action = 'showOublitixOverlay', visible = true })
    Wait(200)
    SendNUIMessage({ action = 'showOublitixText', visible = true, message = forgetMessage })
    Wait(300)
    -- Safety resend
    SendNUIMessage({ action = 'showOublitixText', visible = true, message = forgetMessage })
    
    -- Teleport while screen is already blacked by UI
    if targetCoords then
        SetEntityCoords(playerPed, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
    end
    
    -- Disable all controls during black screen (UI fade only)
    local blackEndTime = GetGameTimer() + (Config.BlackScreenDuration * 1000)
    CreateThread(function()
        while GetGameTimer() < blackEndTime do
            DisableAllControlActions(0)
            EnableControlAction(0, 322, true) -- ESC
            Wait(0)
        end
    end)
    
    -- Keep screen black for full duration (15 seconds)
    while GetGameTimer() < blackEndTime do
        Wait(100)
    end
    
    -- Hide UI overlay and message (acts as fade-in)
    SendNUIMessage({ action = 'showOublitixText', visible = false })
    Wait(150)
    SendNUIMessage({ action = 'showOublitixOverlay', visible = false })
    Wait(300) -- short easing time

    -- Light camera shake to emphasize disorientation (3s)
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.25)
    SetTimeout(3000, function()
        StopGameplayCamShaking(true)
    end)
    
    -- Stop emote
    ClearPedTasks(playerPed)
    RemoveAnimDict(Config.SleepEmote.dict)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for _, data in pairs(oublitixRayProps) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            if data.trailFx then
                StopParticleFxLooped(data.trailFx, 0)
                RemoveParticleFx(data.trailFx, false)
            end
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
    
    oublitixRayProps = {}
    wandParticles = {}
end)

