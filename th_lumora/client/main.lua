-- REQUIRES: ESX Framework (es_extended) - Replace ESX.PlayerData calls with your framework
---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch
local activeLumosLights = {}
local lumosActive = false
local currentLumosId = nil
local lumosSound = nil
local currentLumosLevel = 0
local lumoraProjectiles = {}
local lastProjectileTime = 0
local PROJECTILE_COOLDOWN = 500
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
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local IsEntityDead = IsEntityDead
local IsPedFatallyInjured = IsPedFatallyInjured
local IsPedRagdoll = IsPedRagdoll
local PlayerPedId = PlayerPedId
local DrawLightWithRange = DrawLightWithRange
local CreateObject = CreateObject
local GetHashKey = GetHashKey
local SetEntityVisible = SetEntityVisible
local SPELL_ID <const> = 'lumora'
local PROJECTILE_SPEED <const> = 10.0
local PROJECTILE_FX_SCALE <const> = 3.0

local function IsPedUnableToCast(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return false
    end

    if IsEntityDead(ped) or IsPedFatallyInjured(ped) or ESX.PlayerData.dead then
        return true, 'Vous êtes inconscient, impossible de lancer un sort.'
    end

    if IsPedRagdoll(ped) then
        return true, 'Vous êtes à terre, impossible de lancer un sort.'
    end

    return false
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

local projectileIdCounter = 0

local function CleanupLumoraProjectile(projectileId)
    lumoraProjectiles[projectileId] = nil
end

local function CreateLumoraProjectile(startCoords, targetCoords)
    lib.requestNamedPtfxAsset('core', 5000)
    
    local direction = vector3(
        targetCoords.x - startCoords.x,
        targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z
    )
    local distance = #direction
    if distance <= 0.001 then distance = 0.001 end
    direction = direction / distance
    
    local duration = (distance / PROJECTILE_SPEED) * 1000.0
    local startTime = GetGameTimer()
    local endTime = startTime + duration
    
    projectileIdCounter = projectileIdCounter + 1
    local projectileId = projectileIdCounter
    
    lumoraProjectiles[projectileId] = {
        startCoords = startCoords,
        targetCoords = targetCoords,
        direction = direction,
        distance = distance,
        startTime = startTime,
        endTime = endTime
    }
end

CreateThread(function()
    while true do
        Wait(0)
        
        local currentTime = GetGameTimer()
        
        for projectileId, data in pairs(lumoraProjectiles) do
            if type(data) == "table" then
                if currentTime < data.endTime then
                    local progress = (currentTime - data.startTime) / (data.endTime - data.startTime)
                    progress = math.min(progress, 1.0)
                    
                    local newPos = vector3(
                        data.startCoords.x + (data.direction.x * data.distance * progress),
                        data.startCoords.y + (data.direction.y * data.distance * progress),
                        data.startCoords.z + (data.direction.z * data.distance * progress)
                    )
                    
                    UseParticleFxAsset('core')
                    StartParticleFxNonLoopedAtCoord(
                        'veh_exhaust_spacecraft',
                        newPos.x, newPos.y, newPos.z,
                        0.0, 0.0, 0.0,
                        PROJECTILE_FX_SCALE,
                        false, false, false
                    )
                    
                    DrawLightWithRange(newPos.x, newPos.y, newPos.z, 255, 255, 200, 20.0, 8.0)
                else
                    if not data.stagnationEndTime then
                        data.stagnationEndTime = currentTime + 5000
                    end
                    
                    if currentTime < data.stagnationEndTime then
                        UseParticleFxAsset('core')
                        StartParticleFxNonLoopedAtCoord(
                            'veh_exhaust_spacecraft',
                            data.targetCoords.x, data.targetCoords.y, data.targetCoords.z,
                            0.0, 0.0, 0.0,
                            PROJECTILE_FX_SCALE,
                            false, false, false
                        )
                        
                        DrawLightWithRange(data.targetCoords.x, data.targetCoords.y, data.targetCoords.z, 255, 255, 200, 20.0, 8.0)
                    else
                        CleanupLumoraProjectile(projectileId)
                    end
                end
            end
        end
    end
end)

local function FireLumoraProjectile()
    if currentLumosLevel < 5 then return end

    local currentTime = GetGameTimer()
    if currentTime - lastProjectileTime < PROJECTILE_COOLDOWN then return end
    lastProjectileTime = currentTime

    local playerPed = cache.ped
    local weapon = GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or weapon == 0 or not DoesEntityExist(weapon) then return end

    -- Animation de baguette
    lib.requestAnimDict(Config.Animation.dict)
    TaskPlayAnim(
        playerPed,
        Config.Animation.dict,
        Config.Animation.name,
        8.0, -8.0,
        Config.Animation.duration,
        Config.Animation.flag,
        0, false, false, false
    )

    local startCoords = GetOffsetFromEntityInWorldCoords(weapon, 0.0, 0.3, 0.0)
    
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local direction = RotationToDirection(camRot)
    
    local maxDistance = 50.0
    local endCoords = vector3(
        camCoords.x + direction.x * maxDistance,
        camCoords.y + direction.y * maxDistance,
        camCoords.z + direction.z * maxDistance
    )
    
    local raycast = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        endCoords.x, endCoords.y, endCoords.z,
        1 | 2 | 4 | 8 | 16,
        playerPed,
        0
    )
    
    local _, hit, hitCoords, _, _ = GetShapeTestResult(raycast)
    
    local targetCoords
    if hit and hitCoords and (hitCoords.x ~= 0.0 or hitCoords.y ~= 0.0 or hitCoords.z ~= 0.0) then
        targetCoords = hitCoords
    else
        targetCoords = endCoords
    end
    
    CreateLumoraProjectile(startCoords, targetCoords)
    TriggerServerEvent('th_lumora:fireProjectile', startCoords, targetCoords)
end

RegisterNetEvent('th_lumora:client:fireProjectile', function(casterServerId, startCoords, targetCoords)
    local myServerId = GetPlayerServerId(PlayerId())
    if casterServerId ~= myServerId then
        CreateLumoraProjectile(startCoords, targetCoords)
    end
end)

local function GetLightSettingsForLevel(level)
    local maxLevel = Config.MaxLevel or 5
    local normalizedLevel = math.floor(tonumber(level) or 0)
    if normalizedLevel < 0 then
        normalizedLevel = 0
    elseif normalizedLevel > maxLevel then
        normalizedLevel = maxLevel
    end

    if Config.LevelSettings and Config.LevelSettings[normalizedLevel] then
        return Config.LevelSettings[normalizedLevel], normalizedLevel
    end

    local ratio = maxLevel > 0 and (normalizedLevel / maxLevel) or 1.0
    local minFactor = 0.35
    local factor = minFactor + ((1.0 - minFactor) * ratio)

    return {
        range = Config.LightRance * factor,
        intensity = Config.LightIntensity * factor,
        maxDistance = Config.MaxDistance * factor,
        fallbackDistance = Config.FallbackDistance * factor
    }, normalizedLevel
end

local function CreateLumosLight(lightId, targetPlayerId, spellLevel)
    local targetPed = GetPlayerPed(targetPlayerId)
    
    if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
        return
    end

    local lightSettings = GetLightSettingsForLevel(spellLevel)
    local maxDistance = lightSettings.maxDistance or Config.MaxDistance
    local fallbackDistance = lightSettings.fallbackDistance or Config.FallbackDistance
    local lightRange = lightSettings.range or Config.LightRance
    local lightIntensity = lightSettings.intensity or Config.LightIntensity
    
    local playerPed = targetPed
    
    lib.requestNamedPtfxAsset('core', 5000)
    
    local boneIndex = GetPedBoneIndex(playerPed, 28422)
    local boneCoords = GetWorldPositionOfEntityBone(playerPed, boneIndex)
    local playerHeading = GetEntityHeading(playerPed)
    local headingRad = math.rad(playerHeading)
    local offsetX = 0.5 * math.cos(headingRad)
    local offsetY = 0.5 * math.sin(headingRad)
    local tipCoords = vector3(
        boneCoords.x + offsetX,
        boneCoords.y + offsetY,
        boneCoords.z
    )
    
    local weapon = GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or weapon == 0 or not DoesEntityExist(weapon) then
        return
    end
    
    UseParticleFxAsset('core')
    local particleId = StartNetworkedParticleFxLoopedOnEntity(
        'veh_exhaust_spacecraft',
        weapon,
        0.30, 0.02, 0.075,
        0.0, 0.0, 0.0,
        0.03,
        false, false, false
    )
    
    if particleId then
        SetParticleFxLoopedColour(particleId, 1.0, 1.0, 0.9, false)
        SetParticleFxLoopedAlpha(particleId, 1.0) 
        
        activeLumosLights[lightId] = {
            particleId = particleId,
            playerPed = playerPed,
            weapon = weapon,
            startTime = GetGameTimer(),
            settings = lightSettings
        }
        
        CreateThread(function()
            local lastLightCoords = nil
            local lastUpdateTime = 0
            local targetLightCoords = nil
            local lastSyncTime = 0
            
            while activeLumosLights[lightId] do
                local light = activeLumosLights[lightId]
                if light and light.weapon and DoesEntityExist(light.weapon) then
                    local currentTime = GetGameTimer()
                    local isLocalLight = (light.playerPed == cache.ped)
                    
                    if currentTime - lastUpdateTime > 50 then
                        local newLightCoords
                        
                        if isLocalLight then
                            if IsControlPressed(0, 25) then
                                local camCoords = GetGameplayCamCoord()
                                local camRotation = GetGameplayCamRot(0)
                                
                                local camDirection = vector3(
                                    -math.sin(math.rad(camRotation.z)) * math.cos(math.rad(camRotation.x)),
                                    math.cos(math.rad(camRotation.z)) * math.cos(math.rad(camRotation.x)),
                                    math.sin(math.rad(camRotation.x))
                                )
                                
                                local startCoords = GetOffsetFromEntityInWorldCoords(light.weapon, 0.0, 0.2, 0.0)
                                
                                local endCoords = vector3(
                                    startCoords.x + (camDirection.x * maxDistance),
                                    startCoords.y + (camDirection.y * maxDistance),
                                    startCoords.z + (camDirection.z * maxDistance)
                                )
                                
                                local raycast = StartShapeTestRay(
                                    startCoords.x, startCoords.y, startCoords.z,
                                    endCoords.x, endCoords.y, endCoords.z,
                                    1,
                                    light.playerPed,
                                    0
                                )
                                
                                local _, hit, hitCoords, _, hitEntity = GetShapeTestResult(raycast)
                                
                                if hit and hitCoords then
                                    newLightCoords = hitCoords
                                else
                                    newLightCoords = vector3(
                                        startCoords.x + (camDirection.x * fallbackDistance),
                                        startCoords.y + (camDirection.y * fallbackDistance),
                                        startCoords.z + (camDirection.z * fallbackDistance)
                                    )
                                end
                            else
                                newLightCoords = GetOffsetFromEntityInWorldCoords(light.weapon, 0.0, 0.3, 0.0)
                            end
                            
                            if currentTime - lastSyncTime > 100 then
                                LocalPlayer.state:set('lumosTarget', {
                                    x = newLightCoords.x,
                                    y = newLightCoords.y,
                                    z = newLightCoords.z
                                }, true)
                                lastSyncTime = currentTime
                            end
                        else
                            local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(light.playerPed))
                            local targetState = Player(targetServerId).state.lumosTarget
                            
                            if targetState and targetState.x then
                                newLightCoords = vector3(targetState.x, targetState.y, targetState.z)
                            else
                                newLightCoords = GetOffsetFromEntityInWorldCoords(light.weapon, 0.0, 0.3, 0.0)
                            end
                        end
                        
                        targetLightCoords = newLightCoords
                        lastUpdateTime = currentTime
                    end
                    
                    if targetLightCoords then
                        local lightCoords
                        if lastLightCoords then
                            local lerpFactor = 0.1
                            lightCoords = vector3(
                                lastLightCoords.x + (targetLightCoords.x - lastLightCoords.x) * lerpFactor,
                                lastLightCoords.y + (targetLightCoords.y - lastLightCoords.y) * lerpFactor,
                                lastLightCoords.z + (targetLightCoords.z - lastLightCoords.z) * lerpFactor
                            )
                        else
                            lightCoords = targetLightCoords
                        end
                        
                        lastLightCoords = lightCoords
                        
                        DrawLightWithRange(
                            lightCoords.x, lightCoords.y, lightCoords.z,
                            255, 255, 200,
                            lightRange,
                            lightIntensity
                        )
                    end
                end
                Wait(0)
            end
        end)
    end
end

local function RemoveLumosLight(lightId)
    if activeLumosLights[lightId] then
        local light = activeLumosLights[lightId]
        
        if light.particleId then
            StopParticleFxLooped(light.particleId, false)
        end
        
        if light.playerPed == cache.ped then
            LocalPlayer.state:set('lumosTarget', nil, true)
        end
        
        activeLumosLights[lightId] = nil
        
        lumosActive = false
        currentLumosId = nil
    end
end

local function IsLumoraUnlocked()
    if GetResourceState('th_power') ~= 'started' then
        return true
    end

    local ok, hasSpell = pcall(function()
        local unlocked = exports['th_power']:GetSpell(SPELL_ID)
        return unlocked
    end)

    if not ok then
        return true
    end

    return hasSpell == true
end

local function EnsureUnlocked()
    if IsLumoraUnlocked() then
        return true
    end

    return false
end

lib.addKeybind({
    name = 'lumora_toggle',
    description = '(SORTS) Lumora',
    defaultKey = 'L',
    onPressed = function(self)
        local lumosState <const> = LocalPlayer.state.lumos
        
        local weapon <const> = GetCurrentPedWeaponEntityIndex(PlayerPedId())
        if not weapon or weapon == 0 or not DoesEntityExist(weapon) then
            return
        end

        if not EnsureUnlocked() then
            return
        end
        
        if lumosState and lumosState.active then
            TriggerServerEvent('th_lumora:removeLight')
        else
            TriggerServerEvent('th_lumora:toggleLight')
        end
    end
})

AddStateBagChangeHandler('lumos', nil, function(bagName, key, value, _unused, replicated)
    local serverIdStr <const> = bagName:gsub('player:', '')
    if not serverIdStr or serverIdStr == '' then 
        return 
    end
    
    local serverIdNum <const> = tonumber(serverIdStr)
    
    local targetPlayerId = nil
    for i = 0, 255 do
        if GetPlayerServerId(i) == serverIdNum then
            targetPlayerId = i
            break
        end
    end
    
    if not targetPlayerId then 
        return 
    end
    
    if value and value.active and value.lightId then
        CreateLumosLight(value.lightId, targetPlayerId, value.level or 0)
        
        if targetPlayerId == PlayerId() then
            lumosActive = true
            currentLumosId = value.lightId
            currentLumosLevel = value.level or 0
            
            if lumosSound then
                lumosSound:stop()
            end
            
            -- REPLACE WITH YOUR SOUND SYSTEM
            -- lumosSound = exports['lo_audio']:playSound({
            -- id = 'lumos_activate_' .. GetGameTimer(),
            -- url = 'YOUR_SOUND_URL_HERE',
            -- volume = 0.2,
            -- distance = 10.0,
            -- loop = false
            -- })
        end
    else
        for lightId, light in pairs(activeLumosLights) do
            if light.playerPed == GetPlayerPed(targetPlayerId) then
                RemoveLumosLight(lightId)
                break
            end
        end
        
        if targetPlayerId == PlayerId() then
            lumosActive = false
            currentLumosId = nil
            currentLumosLevel = 0
            
            if lumosSound then
                lumosSound:stop()
                lumosSound = nil
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if lumosActive and IsDisabledControlJustPressed(0, 24) then
            FireLumoraProjectile()
        end
    end
end)

RegisterNetEvent('th_power:castSpellByKey', function(spellId)
    if spellId == SPELL_ID or spellId == 'lumos' then
        local ped <const> = (cache and cache.ped) or PlayerPedId()
        local blocked, reason = IsPedUnableToCast(ped)
        if blocked then
            if reason then
                if lib and lib.notify then
                    lib.notify({ description = reason, type = 'error' })
                else
                    print('[LUMORA] ' .. reason)
                end
            end
            return
        end

        local lumosState <const> = LocalPlayer.state.lumos
        
        local weapon <const> = GetCurrentPedWeaponEntityIndex(ped)
        if not weapon or weapon == 0 or not DoesEntityExist(weapon) then
            return
        end
        
        if lumosState and lumosState.active then
            TriggerServerEvent('th_lumora:removeLight')
        else
            TriggerServerEvent('th_lumora:toggleLight')
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for lightId, light in pairs(activeLumosLights) do
        if light.particleId then
            StopParticleFxLooped(light.particleId, false)
        end
    end
    
    lumoraProjectiles = {}
    
    if lumosSound then
        lumosSound:stop()
        lumosSound = nil
    end
    
    activeLumosLights = {}
    RemoveNamedPtfxAsset('core')
end)
