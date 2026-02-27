---@diagnostic disable: trailing-space, undefined-global, param-type-mismatch
local petrificusRayProps = {}
local wandParticles = {}
local petrifiedEntities = {}
local petrifiedRotations = {}
local math_floor = math.floor
local math_max = math.max

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

local function CalculatePetrifyDuration(level)
    local maxDuration = Config.Petrificus.duration or 15000
    local minDuration = math.min(5000, maxDuration)
    local lvl = math.max(0, math.floor(tonumber(level) or 0))
    local ratio = math.min(lvl / 5.0, 1.0)

    return math.floor(minDuration + ((maxDuration - minDuration) * ratio))
end

local function TiltPedBackward(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return
    end

    if not petrifiedRotations[ped] then
        local rot = GetEntityRotation(ped, 2)
        petrifiedRotations[ped] = { x = rot.x or 0.0, y = rot.y or 0.0, z = rot.z or 0.0 }
    end

    local heading = GetEntityHeading(ped)
    -- Lean the entity backwards as if falling.
    SetEntityRotation(ped, -80.0, 0.0, heading, 2, true)
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

local function GetSpeedMultiplier()
    local mult = Config.Animation and Config.Animation.speedMultiplier or 1.0
    if mult <= 0.0 then
        mult = 1.0
    end
    return mult
end

local function GetAnimationTimings()
    local anim = Config.Animation or {}
    local speedMult = GetSpeedMultiplier()

    local projectileDelay = anim.propsDelay or 600
    local cleanupDelay = anim.cleanupDelay or 800
    local duration = anim.duration or 2200

    local scaledProjectile = math_floor(projectileDelay / speedMult)
    local scaledCleanup = math_floor(math_max(0, cleanupDelay) / speedMult)
    local scaledDuration = math_floor(duration / speedMult)

    if scaledDuration < scaledProjectile then
        scaledDuration = scaledProjectile
    end

    return scaledProjectile, scaledCleanup, scaledDuration
end

local function CreateWandParticles(playerPed, isNetworked)
    local weapon = GetCurrentPedWeaponEntityIndex(playerPed)
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

local function CreatePetrificusProjectile(startCoords, targetCoords, sourceServerId, targetEntity, level, petrifyDuration)
    local propModel = GetHashKey(Config.Projectile.model)
    lib.requestModel(propModel, 5000)
    
    local rayProp = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(rayProp, false, false)
    SetEntityAsMissionEntity(rayProp, true, true)
    SetEntityCompletelyDisableCollision(rayProp, false, false)
    SetEntityAlpha(rayProp, 100, false)
    
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
    local distance = #direction
    direction = direction / distance
    
    local heading = math.deg(math.atan(direction.y, direction.x)) + 90.0
    local pitch = -math.deg(math.asin(direction.z))
    local roll = 0.0
    
    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)
    
    local speedMult = GetSpeedMultiplier()
    local projectileDuration = Config.Projectile.duration or (distance / Config.Projectile.speed) * 1000.0
    projectileDuration = math_floor(projectileDuration / speedMult)
    if projectileDuration < 150 then
        projectileDuration = 150
    end
    local startTime = GetGameTimer()
    local endTime = startTime + projectileDuration
    local spellLevel = math.max(0, math.floor(tonumber(level) or 0))
    local effectDuration = petrifyDuration or CalculatePetrifyDuration(spellLevel)
    
    petrificusRayProps[rayProp] = {
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
        petrifyDuration = effectDuration,
        sourceServerId = sourceServerId
    }
end

CreateThread(function()
    while true do
        Wait(1)
        
        local currentTime = GetGameTimer()
        
        for propId, data in pairs(petrificusRayProps) do
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
                                        TriggerServerEvent('th_staturion:petrifyPlayer', targetServerId)
                                    else
                                        TriggerEvent('th_staturion:petrifyPed', data.targetEntity, data.petrifyDuration)
                                    end
                                end
                            end
                            
                            DeleteObject(data.prop)
                            SetEntityAsMissionEntity(data.prop, false, true)
                            DeleteEntity(data.prop)
                        end
                        
                        petrificusRayProps[propId] = nil
                    end
                else
                    petrificusRayProps[propId] = nil
                end
            end
        end
    end
end)

RegisterNetEvent('th_staturion:prepareProjectile', function()
    local casterPed = cache.ped
    
    CreateWandParticles(casterPed, true)
    local projectileDelay, cleanupDelay = GetAnimationTimings()
    
    CreateThread(function()
        Wait(math_max(0, projectileDelay))
        local handBone = GetPedBoneIndex(casterPed, Config.Projectile.handBone)
        local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)
        
        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        local direction = RotationToDirection(camRot)
        
        local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, 1000)
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
        
        TriggerServerEvent('th_staturion:broadcastProjectile', finalTargetCoords, targetEntity)
        
        Wait(math_max(0, cleanupDelay))
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_staturion:otherPlayerCasting', function(sourceServerId)
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
    
    local _, _, animDuration = GetAnimationTimings()
    SetTimeout(animDuration, function()
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_staturion:fireProjectile', function(sourceServerId, targetCoords, targetEntity, level, duration)
    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then 
        return 
    end
    
    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then 
        return 
    end

    local spellLevel = ResolveSpellLevel('staturion', sourceServerId, level)
    local petrifyDuration = duration or CalculatePetrifyDuration(spellLevel)
    local handBone = GetPedBoneIndex(casterPed, Config.Projectile.handBone)
    local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)
    
    CreatePetrificusProjectile(startCoords, targetCoords, sourceServerId, targetEntity, spellLevel, petrifyDuration)
end)

RegisterNetEvent('th_staturion:applyPetrify', function(duration, level)
    local hasShield = false
    if LocalPlayer and LocalPlayer.state then
        hasShield = LocalPlayer.state.protheaShield == true
    end

    if not hasShield then
        local ok, result = pcall(function()
            return exports['th_prothea'] and exports['th_prothea'].hasLocalShield and exports['th_prothea']:hasLocalShield()
        end)
        hasShield = ok and result == true
    end

    if hasShield then
        print('[Staturion] Pétrification ignorée (bouclier Prothea actif)')
        return
    end

    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('staturion', true, true)
    end

    local playerPed = cache.ped
    local playerCoords = GetEntityCoords(playerPed)
    local lockToken = GetGameTimer()
    local effectDuration = math.floor(duration or CalculatePetrifyDuration(level))
    TiltPedBackward(playerPed)
    CreateThread(function()
        while lockToken and lockToken + effectDuration > GetGameTimer() do
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
            DisableAllControlActions(3)
            Wait(0)
        end
    end)
    
    RequestNamedPtfxAsset(Config.Effects.petrifyEffect.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.petrifyEffect.asset) do
        Wait(0)
    end
    
    UseParticleFxAsset(Config.Effects.petrifyEffect.asset)
    local petrifyFx = StartParticleFxLoopedAtCoord(
        Config.Effects.petrifyEffect.name,
        playerCoords.x, playerCoords.y, playerCoords.z,
        0.0, 0.0, 0.0,
        Config.Effects.petrifyEffect.scale,
        false, false, false, false
    )
    
    Wait(1000)
    
    if petrifyFx then
        StopParticleFxLooped(petrifyFx, 0)
        RemoveParticleFx(petrifyFx, false)
    end
    RemoveNamedPtfxAsset(Config.Effects.petrifyEffect.asset)
    
    FreezeEntityPosition(playerPed, true)
    
    ExecuteCommand('e airforce2')
    
    RequestNamedPtfxAsset(Config.Effects.frozenAura.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.frozenAura.asset) do
        Wait(0)
    end
    
    UseParticleFxAsset(Config.Effects.frozenAura.asset)
    local frozenFx = StartParticleFxLoopedOnEntity(
        Config.Effects.frozenAura.name,
        playerPed,
        0.0, 0.0, 0.5,
        0.0, 0.0, 0.0,
        Config.Effects.frozenAura.scale,
        false, false, false
    )
    
    if frozenFx then
        SetParticleFxLoopedColour(frozenFx,
            Config.Effects.frozenAura.color.r,
            Config.Effects.frozenAura.color.g,
            Config.Effects.frozenAura.color.b,
            false
        )
    end
    
    petrifiedEntities[playerPed] = frozenFx
    
    lib.notify({
        title = 'Staturion',
        description = 'Vous êtes staturisé !',
        type = 'error',
        icon = 'snowflake',
        duration = 5000
    })
end)

RegisterNetEvent('th_staturion:removePetrify', function()
    local playerPed = cache.ped
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('staturion', false, true)
    end
    
    FreezeEntityPosition(playerPed, false)
    ExecuteCommand('e c')

    if petrifiedRotations[playerPed] then
        local rot = petrifiedRotations[playerPed]
        SetEntityRotation(playerPed, rot.x, rot.y, rot.z, 2, true)
        petrifiedRotations[playerPed] = nil
    end
    
    if petrifiedEntities[playerPed] then
        StopParticleFxLooped(petrifiedEntities[playerPed], 0)
        RemoveParticleFx(petrifiedEntities[playerPed], false)
        petrifiedEntities[playerPed] = nil
        RemoveNamedPtfxAsset(Config.Effects.frozenAura.asset)
    end
    
    lib.notify({
        title = 'Staturion',
        description = 'Vous êtes déstaturisé !',
        type = 'success',
        icon = 'heart',
        duration = 3000
    })
end)

RegisterNetEvent('th_staturion:petrifyPed', function(pedEntity, duration)
    if not DoesEntityExist(pedEntity) or not IsEntityAPed(pedEntity) then
        return
    end

    local effectDuration = math.floor(duration or CalculatePetrifyDuration(0))
    local pedCoords = GetEntityCoords(pedEntity)
    
    RequestNamedPtfxAsset(Config.Effects.petrifyEffect.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.petrifyEffect.asset) do
        Wait(0)
    end
    
    UseParticleFxAsset(Config.Effects.petrifyEffect.asset)
    local petrifyFx = StartParticleFxLoopedAtCoord(
        Config.Effects.petrifyEffect.name,
        pedCoords.x, pedCoords.y, pedCoords.z,
        0.0, 0.0, 0.0,
        Config.Effects.petrifyEffect.scale,
        false, false, false, false
    )
    
    Wait(1000)
    
    if petrifyFx then
        StopParticleFxLooped(petrifyFx, 0)
        RemoveParticleFx(petrifyFx, false)
    end
    RemoveNamedPtfxAsset(Config.Effects.petrifyEffect.asset)
    
    FreezeEntityPosition(pedEntity, true)
    TiltPedBackward(pedEntity)
    ClearPedTasksImmediately(pedEntity)
    
    SetBlockingOfNonTemporaryEvents(pedEntity, true)
    SetPedCanRagdoll(pedEntity, false)
    SetPedCanBeTargetted(pedEntity, false)
    SetPedFleeAttributes(pedEntity, 0, false)
    SetPedCombatAttributes(pedEntity, 17, true)
    
    lib.requestAnimDict('airforce@attention')
    TaskPlayAnim(pedEntity, 'airforce@attention', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)
    
    RequestNamedPtfxAsset(Config.Effects.frozenAura.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.frozenAura.asset) do
        Wait(0)
    end
    
    UseParticleFxAsset(Config.Effects.frozenAura.asset)
    local frozenFx = StartParticleFxLoopedOnEntity(
        Config.Effects.frozenAura.name,
        pedEntity,
        0.0, 0.0, 0.5,
        0.0, 0.0, 0.0,
        Config.Effects.frozenAura.scale,
        false, false, false
    )
    
    if frozenFx then
        SetParticleFxLoopedColour(frozenFx,
            Config.Effects.frozenAura.color.r,
            Config.Effects.frozenAura.color.g,
            Config.Effects.frozenAura.color.b,
            false
        )
    end
    
    petrifiedEntities[pedEntity] = frozenFx
    
    SetTimeout(effectDuration, function()
        if DoesEntityExist(pedEntity) then
            FreezeEntityPosition(pedEntity, false)
            SetBlockingOfNonTemporaryEvents(pedEntity, false)
            SetPedCanRagdoll(pedEntity, true)
            SetPedCanBeTargetted(pedEntity, true)
            ClearPedTasks(pedEntity)
            if petrifiedRotations[pedEntity] then
                local rot = petrifiedRotations[pedEntity]
                SetEntityRotation(pedEntity, rot.x, rot.y, rot.z, 2, true)
                petrifiedRotations[pedEntity] = nil
            end
            
            if petrifiedEntities[pedEntity] then
                StopParticleFxLooped(petrifiedEntities[pedEntity], 0)
                RemoveParticleFx(petrifiedEntities[pedEntity], false)
                petrifiedEntities[pedEntity] = nil
                RemoveNamedPtfxAsset(Config.Effects.frozenAura.asset)
            end
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('staturion', false, true)
    end
    
    for propId, data in pairs(petrificusRayProps) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            if data.trailFx then
                StopParticleFxLooped(data.trailFx, 0)
                RemoveParticleFx(data.trailFx, false)
            end
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
    
    for entity, fx in pairs(petrifiedEntities) do
        if DoesEntityExist(entity) then
            FreezeEntityPosition(entity, false)
            ClearPedTasks(entity)
            if fx then
                StopParticleFxLooped(fx, 0)
                RemoveParticleFx(fx, false)
            end
        end
    end
    
    petrificusRayProps = {}
    wandParticles = {}
    petrifiedEntities = {}
end)
