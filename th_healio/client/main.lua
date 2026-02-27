---@diagnostic disable: trailing-space, deprecated, undefined-global
local healioRayProps = {}
local wandParticles = {}
local activeHealZones = {}

local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local SetParticleFxLoopedEvolution = SetParticleFxLoopedEvolution
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset

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

local function BuildHealSettings(level)
    local lvl = math.max(0, math.floor(tonumber(level) or 0))
    local ratio = math.min(lvl / 5.0, 1.0)

    local minRadius = 3.0
    local minHeal = 6
    local minDuration = 4000

    local radius = minRadius + ((Config.HealZone.radius - minRadius) * ratio)
    local healAmount = math.floor(minHeal + ((Config.HealZone.healAmount - minHeal) * ratio))
    local duration = math.floor(minDuration + ((Config.HealZone.duration - minDuration) * ratio))

    return {
        radius = radius,
        healAmount = healAmount,
        duration = duration,
        tickInterval = Config.HealZone.tickInterval
    }
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

local function CreateHealingZone(coords, settings)
    local healSettings = settings or BuildHealSettings(0)
    local zoneId = #activeHealZones + 1
    local effects = {}
    
    RequestNamedPtfxAsset(Config.Effects.healingParticles.asset)
    RequestNamedPtfxAsset(Config.Effects.smokeRing.asset)
    
    while not HasNamedPtfxAssetLoaded(Config.Effects.healingParticles.asset) or 
          not HasNamedPtfxAssetLoaded(Config.Effects.smokeRing.asset) do
        Wait(0)
    end
    
    if Config.Effects.healingParticles.count > 0 then
        UseParticleFxAssetNextCall(Config.Effects.healingParticles.asset)
        local healFx = StartParticleFxLoopedAtCoord(
            Config.Effects.healingParticles.name,
            coords.x,
            coords.y,
            coords.z + 0.2,
            0.0, 0.0, 0.0,
            Config.Effects.healingParticles.scale,
            false, false, false, false
        )
        table.insert(effects, healFx)
    end
    
    if Config.Effects.smokeRing.count > 0 then
        UseParticleFxAssetNextCall(Config.Effects.smokeRing.asset)
        local smokeFx = StartParticleFxLoopedAtCoord(
            Config.Effects.smokeRing.name,
            coords.x,
            coords.y,
            coords.z,
            0.0, 0.0, 0.0,
            Config.Effects.smokeRing.scale,
            false, false, false, false
        )
        SetParticleFxLoopedColour(smokeFx, 0.0, 1.0, 0.0, false)
        SetParticleFxLoopedAlpha(smokeFx, 200.0)
        table.insert(effects, smokeFx)
    end
    
    activeHealZones[zoneId] = {
        coords = coords,
        effects = effects,
        startTime = GetGameTimer(),
        endTime = GetGameTimer() + healSettings.duration,
        settings = healSettings
    }
    
    SetTimeout(healSettings.duration, function()
        if activeHealZones[zoneId] then
            for _, fx in ipairs(activeHealZones[zoneId].effects) do
                StopParticleFxLooped(fx, 0)
                RemoveParticleFx(fx, false)
            end
            RemoveNamedPtfxAsset(Config.Effects.healingParticles.asset)
            RemoveNamedPtfxAsset(Config.Effects.smokeRing.asset)
            activeHealZones[zoneId] = nil
        end
    end)
    
    return zoneId
end

local function CreateHealioProjectile(startCoords, targetCoords, sourceServerId, level)
    local numericLevel = math.max(0, math.floor(tonumber(level) or 0))
    local healSettings = BuildHealSettings(numericLevel)
    local propModel <const> = GetHashKey(Config.Projectile.model)
    lib.requestModel(propModel, 5000)
    
    local rayProp <const> = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(rayProp, false, false)
    SetEntityAsMissionEntity(rayProp, true, true)
    SetEntityCompletelyDisableCollision(rayProp, false, false)
    SetEntityAlpha(rayProp, 255, false) -- Visible comme Avada
    
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
    
    healioRayProps[rayProp] = {
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
        level = numericLevel,
        settings = healSettings
    }
end

CreateThread(function()
    while true do
        Wait(1)
        
        local currentTime <const> = GetGameTimer()
        
        for propId, data in pairs(healioRayProps) do
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
                        if DoesEntityExist(data.prop) then
                            local propCoords <const> = GetEntityCoords(data.prop)
                            local healSettings = data.settings or BuildHealSettings(data.level or 0)
                            
                            DeleteObject(data.prop)
                            SetEntityAsMissionEntity(data.prop, false, true)
                            DeleteEntity(data.prop)
                            CreateHealingZone(propCoords, healSettings)
                        end
                        
                        healioRayProps[propId] = nil
                    end
                else
                    healioRayProps[propId] = nil
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.HealZone.tickInterval)
        
        local playerPed = cache.ped
        local playerCoords = GetEntityCoords(playerPed)
        local now = GetGameTimer()
        
        for zoneId, zone in pairs(activeHealZones) do
            if type(zone) == "table" and zone.coords then
                if zone.endTime and now >= zone.endTime then
                    activeHealZones[zoneId] = nil
                    goto continue
                end

                local settings = zone.settings or BuildHealSettings(0)
                local distance = #(playerCoords - zone.coords)
                
                if distance <= (settings.radius or Config.HealZone.radius) then
                    local currentHealth = GetEntityHealth(playerPed)
                    local maxHealth = GetEntityMaxHealth(playerPed)
                    
                    if currentHealth < maxHealth then
                        local healAmount = settings.healAmount or Config.HealZone.healAmount
                        local newHealth = math.min(currentHealth + healAmount, maxHealth)
                        SetEntityHealth(playerPed, newHealth)
                    end
                end
            end
            ::continue::
        end
    end
end)

RegisterNetEvent('th_healio:prepareProjectile', function()
    local casterPed <const> = cache.ped
    
    CreateWandParticles(casterPed, true)
    
    CreateThread(function()
        Wait(Config.Timing.propsDelay)
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

        TriggerServerEvent('th_healio:broadcastProjectile', finalTargetCoords)

        Wait(Config.Timing.wandFxDuration - Config.Timing.propsDelay)
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_healio:otherPlayerCasting', function(sourceServerId)
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

    SetTimeout(Config.Timing.wandFxDuration, function()
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_healio:fireProjectile', function(sourceServerId, targetCoords, level)
    local casterPlayer <const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then 
        return 
    end
    
    local casterPed <const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then 
        return 
    end

    local castLevel = ResolveSpellLevel('healio', sourceServerId, level)
    
    local handBone <const> = GetPedBoneIndex(casterPed, Config.Projectile.handBone)
    local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
    
    CreateHealioProjectile(startCoords, targetCoords, sourceServerId, castLevel)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for propId, data in pairs(healioRayProps) do
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
    
    for _, zone in pairs(activeHealZones) do
        if type(zone) == "table" and zone.effects then
            for _, fx in ipairs(zone.effects) do
                StopParticleFxLooped(fx, 0)
                RemoveParticleFx(fx, false)
            end
        end
    end
    
    healioRayProps = {}
    wandParticles = {}
    activeHealZones = {}
end)
