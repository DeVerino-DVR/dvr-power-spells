---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local thunderProjectiles = {}
local wandParticles = {}
local casterElectric = {}
local allParticles = {}
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxNonLoopedOnEntity = StartParticleFxNonLoopedOnEntity
local StartNetworkedParticleFxNonLoopedOnEntity = StartNetworkedParticleFxNonLoopedOnEntity
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local DeleteObject = DeleteObject
local DeleteEntity = DeleteEntity
local DoesEntityExist = DoesEntityExist
local GetGameTimer = GetGameTimer
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetEntityCoords = GetEntityCoords
local SetEntityCoords = SetEntityCoords
local SetEntityRotation = SetEntityRotation
local SetEntityCollision = SetEntityCollision
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetEntityCompletelyDisableCollision = SetEntityCompletelyDisableCollision
local SetEntityVisible = SetEntityVisible
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local GetHashKey = GetHashKey
local CreateObject = CreateObject
local SetPedToRagdoll = SetPedToRagdoll
local ShakeGameplayCam = ShakeGameplayCam
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StartNetworkedParticleFxLoopedAtCoord = StartNetworkedParticleFxLoopedAtCoord

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

local function StopWandTrail(playerPed)
    local handle = wandParticles[playerPed]
    if handle then
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
        allParticles[handle] = nil
        wandParticles[playerPed] = nil
    end
end

local function StopCasterElectric(ped)
    local handle = casterElectric[ped]
    if handle then
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
        allParticles[handle] = nil
        casterElectric[ped] = nil
    end
end

local function RemoveWandParticles(playerPed)
    StopWandTrail(playerPed)
    StopCasterElectric(playerPed)
end

local function RotationToDirection(rotation)
    local adjustedRotation<const> = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction<const> = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local function GetShotTimings()
    local timings = Config.Projectile and Config.Projectile.shotTimings
    local cleaned = {}

    if type(timings) == "table" then
        for _, t in ipairs(timings) do
            local ms = math.floor(tonumber(t) or -1)
            if ms >= 0 then
                cleaned[#cleaned + 1] = ms
            end
        end
    end

    if #cleaned == 0 then
        cleaned = { 250 }
    else
        table.sort(cleaned)
    end

    return cleaned
end

local function CreateWandParticles(playerPed, isNetworked)
    -- Small smoke trail on wand during cast.
    local particleCfg<const> = Config.Effects and Config.Effects.particle
    if particleCfg then
        RequestNamedPtfxAsset(particleCfg.dict)
        while not HasNamedPtfxAssetLoaded(particleCfg.dict) do
            Wait(0)
        end

        UseParticleFxAsset(particleCfg.dict)
        UseParticleFxAssetNextCall(particleCfg.dict)

        local fx
        if isNetworked then
            fx = StartNetworkedParticleFxLoopedOnEntity(particleCfg.name, playerPed, particleCfg.offset.x,
                particleCfg.offset.y, particleCfg.offset.zstart or 0.0, particleCfg.rot.x, particleCfg.rot.y,
                particleCfg.rot.z, 1.0, false, false, false)
        else
            fx = StartParticleFxLoopedOnEntity(particleCfg.name, playerPed, particleCfg.offset.x, particleCfg.offset.y,
                particleCfg.offset.zstart or 0.0, particleCfg.rot.x, particleCfg.rot.y, particleCfg.rot.z, 1.0, false,
                false, false)
        end

        if fx then
            SetParticleFxLoopedAlpha(fx, particleCfg.alpha or 1.0)
            wandParticles[playerPed] = fx
            allParticles[fx] = {
                createdTime = GetGameTimer(),
                type = 'wandTrail'
            }
        end
    end

    -- Electrical arc on caster body.
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end
    UseParticleFxAssetNextCall('core')
    local elec = StartParticleFxLoopedOnEntity('ent_brk_sparking_wires', playerPed, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
    if elec then
        casterElectric[playerPed] = elec
        allParticles[elec] = { createdTime = GetGameTimer(), type = 'casterElectric' }
    end
end

local function AttachProjectileTrail(rayProp, isNetworked)
    if not rayProp or not DoesEntityExist(rayProp) then
        return
    end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    UseParticleFxAsset('core')
    UseParticleFxAssetNextCall('core')

    if isNetworked then
        StartNetworkedParticleFxNonLoopedOnEntity('veh_light_red_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0)
    else
        StartParticleFxNonLoopedOnEntity('veh_light_red_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0)
    end

    local trailHandle
    if isNetworked then
        trailHandle = StartNetworkedParticleFxLoopedOnEntity('veh_light_red_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0,
            0.0, 0.55, false, false, false)
    else
        trailHandle = StartParticleFxLoopedOnEntity('veh_light_red_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0, 0.55,
            false, false, false)
    end

    allParticles[trailHandle] = {
        createdTime = GetGameTimer(),
        type = 'projectileTrail'
    }

    return trailHandle
end

local function TransferWandTrailToProjectile(casterPed, rayProp)
    StopWandTrail(casterPed)
    return AttachProjectileTrail(rayProp, false)
end

local function SpawnLightningAtCoord(coords)
    local props = Config.Effects and Config.Effects.props or {}
    local spawned = {}
    local spawnZ = coords.z or 0.0

    if props.sub then
        local subModel<const> = GetHashKey(props.sub)
        lib.requestModel(subModel, 5000)
        local subObj<const> = CreateObject(subModel, coords.x, coords.y, spawnZ - 0.3, false, false, false)
        if DoesEntityExist(subObj) then
            SetEntityCollision(subObj, false, false)
            SetEntityAsMissionEntity(subObj, true, true)
            SetEntityCompletelyDisableCollision(subObj, true, false)
            SetEntityRotation(subObj, 0.0, 0.0, 0.0, 2, true)
            SetEntityLodDist(subObj, 2000)
            if SetEntityDistanceCullingRadius then
                SetEntityDistanceCullingRadius(subObj, 2000.0)
            end
            spawned[#spawned + 1] = subObj
        end
    end

    if props.main then
        local mainModel<const> = GetHashKey(props.main)
        lib.requestModel(mainModel, 5000)
        local mainObj<const> = CreateObject(mainModel, coords.x, coords.y, spawnZ - 0.7, false, false, false)
        if DoesEntityExist(mainObj) then
            SetEntityCollision(mainObj, false, false)
            SetEntityAsMissionEntity(mainObj, true, true)
            SetEntityCompletelyDisableCollision(mainObj, true, false)
            SetEntityRotation(mainObj, 0.0, 0.0, 0.0, 2, true)
            SetEntityLodDist(mainObj, 2000)
            if SetEntityDistanceCullingRadius then
                SetEntityDistanceCullingRadius(mainObj, 2000.0)
            end
            spawned[#spawned + 1] = mainObj
        end
    end

    if props.boltSmall then
        local boltModel<const> = GetHashKey(props.boltSmall)
        lib.requestModel(boltModel, 5000)
        local boltObj<const> = CreateObject(boltModel, coords.x, coords.y, spawnZ - 1.1, false, false, false)
        if DoesEntityExist(boltObj) then
            SetEntityCollision(boltObj, false, false)
            SetEntityAsMissionEntity(boltObj, true, true)
            SetEntityCompletelyDisableCollision(boltObj, true, false)
            SetEntityRotation(boltObj, 0.0, 0.0, 0.0, 2, true)
            SetEntityLodDist(boltObj, 2000)
            if SetEntityDistanceCullingRadius then
                SetEntityDistanceCullingRadius(boltObj, 2000.0)
            end
            spawned[#spawned + 1] = boltObj
        end
    end

    SetTimeout(2000, function()
        for _, obj in ipairs(spawned) do
            if DoesEntityExist(obj) then
                SetEntityVisible(obj, false, false)
                DeleteEntity(obj)
                DeleteObject(obj)
            end
        end
    end)
end

local function SpawnImpactParticles(coords)
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    local handles = {}
    local function addFx(name, offsetZ, scale)
        UseParticleFxAssetNextCall('core')
        local fx = StartParticleFxLoopedAtCoord(name, coords.x, coords.y, coords.z + offsetZ, 0.0, 0.0, 0.0, scale or 1.0, false, false, false, false)
        if fx then
            handles[#handles + 1] = fx
            allParticles[fx] = { createdTime = GetGameTimer(), type = 'impact' }
        end
    end

    addFx('ent_brk_sparking_wires', -0.2, 1.0)
    addFx('veh_exhaust_heli_cargobob_misfire', -0.2, 0.9)
    addFx('veh_exhaust_spacecraft', -0.25, 1.1)
    addFx('bul_rubber_dust', -0.3, 0.8)
    addFx('exp_water', 0.0, 0.6)
    addFx('ent_amb_fountain_pour', -0.4, 0.7)

    SetTimeout(2500, function()
        for _, fx in ipairs(handles) do
            StopParticleFxLooped(fx, false)
            RemoveParticleFx(fx, false)
            allParticles[fx] = nil
        end
        RemoveNamedPtfxAsset('core')
    end)
end

local function CleanupProjectile(propId)
    local data = thunderProjectiles[propId]
    if not data then
        return
    end

    if data.trailHandle then
        StopParticleFxLooped(data.trailHandle, false)
        RemoveParticleFx(data.trailHandle, false)
        allParticles[data.trailHandle] = nil
        data.trailHandle = nil
    end

    if DoesEntityExist(propId) then
        SetEntityVisible(propId, false, false)
        SetEntityCoords(propId, 0.0, 0.0, -5000.0, false, false, false, false)
        DeleteEntity(propId)
        DeleteObject(propId)
    end

    thunderProjectiles[propId] = nil
end

local function CreateThunderProjectile(startCoords, targetCoords, sourceServerId, casterPed, targetId, level, shotIndex, shotTotal)
    local boltModelName = "wizardsV_nib_wizards_lightning_sub2"
    local boltModel<const> = GetHashKey(boltModelName)
    lib.requestModel(boltModel, 5000)

    local rayProp<const> = CreateObject(boltModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(rayProp, false, false)
    SetEntityAsMissionEntity(rayProp, true, true)
    SetEntityCompletelyDisableCollision(rayProp, true, false)

    local direction = vector3(targetCoords.x - startCoords.x, targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z)
    local distance = #direction
    if distance <= 0.001 then
        distance = 0.001
    end
    direction = direction / distance

    local heading<const> = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch<const> = -math.deg(math.asin(direction.z))
    local roll<const> = 0.0

    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)

    local trailHandle<const> = TransferWandTrailToProjectile(casterPed, rayProp)

    local duration<const> = (distance / (Config.Projectile.speed or 45.0)) * 1000.0
    local startTime<const> = GetGameTimer()
    local endTime<const> = startTime + duration

    thunderProjectiles[rayProp] = {
        prop = rayProp,
        startCoords = startCoords,
        targetCoords = targetCoords,
        direction = direction,
        distance = distance,
        startTime = startTime,
        endTime = endTime,
        heading = heading,
        pitch = pitch,
        roll = roll,
        sourceServerId = sourceServerId,
        trailHandle = trailHandle,
        targetId = targetId or 0,
        level = level or 0,
        shotIndex = shotIndex or 1,
        shotTotal = shotTotal or 1
    }
end

CreateThread(function()
    while true do
        Wait(30000)

        local currentTime = GetGameTimer()
        local toRemove = {}

        for particleHandle, particleData in pairs(allParticles) do
            if currentTime - (particleData.createdTime or 0) > 10000 then
                toRemove[#toRemove + 1] = particleHandle
            end
        end

        for _, particleHandle in ipairs(toRemove) do
            StopParticleFxLooped(particleHandle, false)
            RemoveParticleFx(particleHandle, false)
            allParticles[particleHandle] = nil
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1)

        local currentTime<const> = GetGameTimer()

        for propId, data in pairs(thunderProjectiles) do
            if type(data) == "table" then
                if currentTime < data.endTime and DoesEntityExist(data.prop) then
                    local progress = (currentTime - data.startTime) / (data.endTime - data.startTime)
                    progress = math.min(progress, 1.0)

                    local newPos<const> = vector3(data.startCoords.x + (data.direction.x * data.distance * progress),
                        data.startCoords.y + (data.direction.y * data.distance * progress), data.startCoords.z +
                            (data.direction.z * data.distance * progress))

                    SetEntityCoords(data.prop, newPos.x, newPos.y, newPos.z, false, false, false, false)

                    if data.heading and data.pitch and data.roll then
                        SetEntityRotation(data.prop, data.pitch, data.roll, data.heading, 2, true)
                    end
                end

                if currentTime >= data.endTime then
                    if DoesEntityExist(data.prop) then
                        local propCoords<const> = GetEntityCoords(data.prop)
                        
                        local isLocalCaster = GetPlayerServerId(PlayerId()) == data.sourceServerId
                        local isLastShot = (data.shotIndex or 1) >= (data.shotTotal or 1)
                        
                        -- IMPORTANT: Notify server BEFORE explosion to protect players
                        if isLocalCaster then
                            TriggerServerEvent('th_thunder:applyLightningDamage', propCoords, data.level or 0)
                        end
                        
                        -- Delay to let server protect players before explosion (increased for reliability)
                        Wait(200)
                        
                        -- Visual effects (lightning props and particles)
                        SpawnLightningAtCoord(propCoords)
                        SpawnImpactParticles(propCoords)

                        if isLocalCaster and isLastShot then
                            TriggerServerEvent('th_thunder:ragdollTarget', data.targetId or 0, data.level or 0)
                            local casterPlayerId = GetPlayerFromServerId(data.sourceServerId)
                            local casterPed = (casterPlayerId ~= -1) and GetPlayerPed(casterPlayerId) or cache.ped
                            if casterPed and DoesEntityExist(casterPed) then
                                RemoveWandParticles(casterPed)
                            end
                        end

                        local playerCoords<const> = GetEntityCoords(cache.ped)
                        local dist = #(playerCoords - propCoords)
                        local shakeCfg = Config.Effects and Config.Effects.shake
                        if shakeCfg then
                            local baseIntensity = shakeCfg.intensity or 0.25
                            local maxDist = (shakeCfg.maxDistance and shakeCfg.maxDistance ~= math.huge) and shakeCfg.maxDistance or nil
                            local factor = maxDist and (1.0 - (dist / maxDist)) or 1.0
                            factor = math.max(0.0, factor)
                            local shake = math.max(0.15, (baseIntensity * 10.0) * factor)
                            
                            -- Explosion for visual/sound effects only (players are protected)
                            AddExplosion(
                                propCoords.x, 
                                propCoords.y, 
                                propCoords.z, 
                                2, 
                                0.1, 
                                true, 
                                false, 
                                shake * 0.3
                            )
                        end

                        SetEntityVisible(data.prop, false, false)
                        SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                        Wait(50)
                        DeleteEntity(data.prop)
                        DeleteObject(data.prop)
                    end

                    CleanupProjectile(propId)
                end
            end
        end
    end
end)

local function GetRagdollDuration(level)
    local base = Config.Ragdoll.baseDuration or 2000
    local perLevel = Config.Ragdoll.perLevel or 0
    local max = Config.Ragdoll.maxDuration or 5000
    local lvl = tonumber(level) or 0
    local duration = base + (perLevel * lvl)
    return math.min(duration, max)
end

RegisterNetEvent('th_thunder:applyRagdoll', function(level)
    if HasProtheaShield() then
        print('[Thunder] Ragdoll ignoré (bouclier Prothea actif)')
        return
    end

    local duration<const> = GetRagdollDuration(level)
    SetPedToRagdoll(cache.ped, duration, duration, 0, false, false, false)
end)

local function PlayLaunchSound(coords)
    if not Config.Sounds or not Config.Sounds.launch then
        return
    end

    -- REPLACE WITH YOUR SOUND SYSTEM
    -- exports['lo_audio']:playSound({
    -- id = ('th_thunder_launch_%s'):format(GetGameTimer()),
    -- url = Config.Sounds.launch.url,
    -- volume = Config.Sounds.launch.volume or 1.0,
    -- loop = false,
    -- spatial = true,
    -- distance = 10.0,
    -- pos = {
    -- x = coords.x,
    -- y = coords.y,
    -- z = coords.z
    -- }
    -- })
end

local function PlayCastSound(coords)
    if not Config.Sounds or not Config.Sounds.cast then
        return
    end

    -- REPLACE WITH YOUR SOUND SYSTEM
    -- exports['lo_audio']:playSound({
    -- id = ('th_thunder_cast_%s'):format(GetGameTimer()),
    -- url = Config.Sounds.cast.url,
    -- volume = Config.Sounds.cast.volume or 1.0,
    -- loop = false,
    -- spatial = true,
    -- distance = 10.0,
    -- pos = {
    -- x = coords.x,
    -- y = coords.y,
    -- z = coords.z
    -- }
    -- })
end

RegisterNetEvent('th_thunder:prepareProjectile', function(targetId, level)
    local casterPed<const> = cache.ped

    CreateWandParticles(casterPed, true)
    local handBone<const> = GetPedBoneIndex(casterPed, 28422)
    local handPos<const> = GetWorldPositionOfEntityBone(casterPed, handBone)
    PlayCastSound(handPos)

    CreateThread(function()
        local shotTimings<const> = GetShotTimings()
        if #shotTimings == 0 then
            return
        end

        local camCoords<const> = GetGameplayCamCoord()
        local camRot<const> = GetGameplayCamRot(2)
        local direction<const> = RotationToDirection(camRot)

        local _, _, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, Config.Projectile.maxDistance or 1200.0)
        local finalTargetCoords

        if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
            finalTargetCoords = coords
        else
            finalTargetCoords = vector3(camCoords.x + direction.x * (Config.Projectile.maxDistance or 1200.0),
                camCoords.y + direction.y * (Config.Projectile.maxDistance or 1200.0),
                camCoords.z + direction.z * (Config.Projectile.maxDistance or 1200.0))
        end

        local lastDelay = 0
        for index, delayMs in ipairs(shotTimings) do
            local waitTime = delayMs - lastDelay
            if waitTime > 0 then
                Wait(waitTime)
            end

            local startCoords<const> = GetWorldPositionOfEntityBone(casterPed, handBone)
            PlayLaunchSound(startCoords)
            TriggerServerEvent('th_thunder:broadcastProjectile', finalTargetCoords, targetId or 0, level or 0, index, #shotTimings)

            lastDelay = delayMs
        end
    end)
end)

RegisterNetEvent('th_thunder:otherPlayerCasting', function(sourceServerId)
    local myServerId<const> = GetPlayerServerId(PlayerId())

    if sourceServerId == myServerId then
        return
    end

    local casterPlayer<const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then
        return
    end

    local casterPed<const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then
        return
    end

    CreateWandParticles(casterPed, true)
end)

RegisterNetEvent('th_thunder:spawnProjectile', function(sourceServerId, targetCoords, targetId, level, shotIndex, shotTotal)
    local casterPlayer<const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then
        return
    end

    local casterPed<const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then
        return
    end

    if not targetCoords then
        return
    end

    local handBone<const> = GetPedBoneIndex(casterPed, 28422)
    local startCoords<const> = GetWorldPositionOfEntityBone(casterPed, handBone)
    CreateThunderProjectile(startCoords, targetCoords, sourceServerId, casterPed, targetId or 0, level or 0, shotIndex or 1, shotTotal or 1)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    for propId, data in pairs(thunderProjectiles) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            DeleteEntity(data.prop)
            DeleteObject(data.prop)
        end
    end
    thunderProjectiles = {}

    for ped, handle in pairs(wandParticles) do
        RemoveParticleFx(handle, false)
    end
    wandParticles = {}
    for ped, handle in pairs(casterElectric) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    casterElectric = {}

    for particleHandle, _ in pairs(allParticles) do
        StopParticleFxLooped(particleHandle, false)
        RemoveParticleFx(particleHandle, false)
    end
    allParticles = {}

    RemoveNamedPtfxAsset('core')
    RemoveNamedPtfxAsset('ns_ptfx')
end)
