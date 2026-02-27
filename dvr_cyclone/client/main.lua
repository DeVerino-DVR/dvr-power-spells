---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local SetParticleFxLoopedScale = SetParticleFxLoopedScale
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local GetEntityCoords = GetEntityCoords
local GetEntityHeightAboveGround = GetEntityHeightAboveGround
local GetEntityModel = GetEntityModel
local IsThisModelAPlane = IsThisModelAPlane
local IsEntityAPed = IsEntityAPed
local ApplyForceToEntityCenterOfMass = ApplyForceToEntityCenterOfMass
local DoesEntityExist = DoesEntityExist
local vector3 = vector3
local NetworkRequestControlOfEntity = NetworkRequestControlOfEntity
local NetworkHasControlOfEntity = NetworkHasControlOfEntity
local ShakeGameplayCam = ShakeGameplayCam
local GetGameTimer = GetGameTimer
local IsPedAPlayer = IsPedAPlayer
local SetPedToRagdoll = SetPedToRagdoll
local SetEntityMaxSpeed = SetEntityMaxSpeed
local SetEntityCoords = SetEntityCoords
local SetEntityCollision = SetEntityCollision
local SetEntityVisible = SetEntityVisible
local CreateObject = CreateObject
local DeleteObject = DeleteObject
local GetHashKey = GetHashKey
local RequestModel = RequestModel
local HasModelLoaded = HasModelLoaded
local IsModelInCdimage = IsModelInCdimage
local FindFirstVehicle = FindFirstVehicle
local FindNextVehicle = FindNextVehicle
local EndFindVehicle = EndFindVehicle
local FindFirstPed = FindFirstPed
local FindNextPed = FindNextPed
local EndFindPed = EndFindPed
local FindFirstObject = FindFirstObject
local FindNextObject = FindNextObject
local EndFindObject = EndFindObject
local GetDistanceBetweenCoords = GetDistanceBetweenCoords
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local PlayerPedId = PlayerPedId
local GetVehiclePedIsIn = GetVehiclePedIsIn
local GetEntityType = GetEntityType
local ActivatePhysics = ActivatePhysics
local SetEntityDynamic = SetEntityDynamic
local FreezeEntityPosition = FreezeEntityPosition
local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_sqrt = math.sqrt
local math_abs = math.abs
local math_random = math.random
local math_pi = math.pi

local wandParticles = {}
local allParticles = {}
local activeCyclones = {}
local myServerId = nil
local LoopedParticle = {}
local TornadoParticle = {}
local ActiveEntity = {}
local TornadoVortex = {}
ActiveEntity.__index = ActiveEntity
TornadoVortex.__index = TornadoVortex
LoopedParticle.__index = LoopedParticle
TornadoParticle.__index = TornadoParticle

local function LoadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and IsModelInCdimage(hash) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end
    return hash
end

local VORTEX_SETTINGS = {
    FORCE_SCALE = 1.2,              
    TOP_ENTITY_SPEED = 35.0,        
    MAX_ENTITY_DIST = 35.0,         
    HORIZONTAL_PULL_FORCE = 0.8,    
    VERTICAL_PULL_FORCE = 0.45,     
    ROTATION_SPEED = 3.5,           
    TANGENT_FORCE = 2.5,            
    RADIUS = 8.0,                   
    MAX_PARTICLE_LAYERS = 5,        
    PARTICLE_COUNT = 1,             
    LAYER_SEPARATION_SCALE = 18.0,  
    GIRTH_MOD = 5.0,                
    THROW_PEDS = true,
    THROW_VEHICLES = true
}

function LoopedParticle:new(assetName, fxName)
    local o = {
        Handle = -1,
        AssetName = assetName,
        FxName = fxName,
        _scale = 0.0,
        _alpha = 0.0
    }
    setmetatable(o, self)
    return o
end

function LoopedParticle:Exists()
    return self.Handle ~= -1 and DoesParticleFxLoopedExist(self.Handle)
end

function LoopedParticle:IsLoaded()
    return HasNamedPtfxAssetLoaded(self.AssetName)
end

function LoopedParticle:Load()
    RequestNamedPtfxAsset(self.AssetName)
end

function LoopedParticle:Scale(scale)
    if self.Handle ~= -1 then
        SetParticleFxLoopedScale(self.Handle, scale)
        self._scale = scale
    end
end

function LoopedParticle:Alpha(alpha)
    if self.Handle ~= -1 then
        SetParticleFxLoopedAlpha(self.Handle, alpha)
        self._alpha = alpha
    end
end

function LoopedParticle:Start(entity, scale, offset, rotation)
    if self.Handle ~= -1 then
        return false
    end
    self._scale = scale
    offset = offset or vector3(0.0, 0.0, 0.0)
    rotation = rotation or vector3(0.0, 0.0, 0.0)
    
    UseParticleFxAssetNextCall(self.AssetName)
    self.Handle = StartParticleFxLoopedOnEntity(self.FxName, entity, offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, scale, false, false, false)
    return self.Handle ~= -1
end

function LoopedParticle:Remove()
    if self.Handle == -1 then
        return false
    end
    StopParticleFxLooped(self.Handle, false)
    RemoveParticleFx(self.Handle, false)
    self.Handle = -1
    return true
end

function TornadoParticle:new(vortex, position, angle, fxAsset, fxName, radius, layerIdx, settings)
    local o = {
        Parent = vortex,
        _centerPos = position,
        _rotation = angle,
        _ptfx = LoopedParticle:new(fxAsset, fxName),
        _radius = radius,
        _offset = vector3(0.0, 0.0, settings.LAYER_SEPARATION_SCALE * layerIdx),
        LayerIndex = layerIdx,
        _layerMask = 0.0,
        _angle = 0.0,
        _prop = nil,
        _settings = settings
    }
    setmetatable(o, self)
    o:Setup(position)
    o:PostSetup()
    return o
end

function TornadoParticle:Setup(position)
    local model = LoadModel("prop_beachball_02")
    local prop = CreateObject(model, position.x, position.y, position.z, false, false, false)
    SetEntityCollision(prop, false, false)
    SetEntityVisible(prop, false, false)
    self._prop = prop
    return prop
end

function TornadoParticle:PostSetup()
    self._layerMask = 1.0 - self.LayerIndex / self._settings.MAX_PARTICLE_LAYERS
    self._layerMask = self._layerMask * 0.1 * self.LayerIndex
    self._layerMask = 1.0 - self._layerMask
    if self._layerMask <= 0.3 then
        self._layerMask = 0.3
    end
end

function TornadoParticle:StartFx(scale)
    if not self._ptfx:IsLoaded() then
        self._ptfx:Load()
        local timeout = 0
        while not self._ptfx:IsLoaded() and timeout < 50 do
            Wait(10)
            timeout = timeout + 1
        end
    end
    self._ptfx:Start(self._prop, scale)
    self._ptfx:Alpha(0.5)
end

function TornadoParticle:SetScale(scale)
    self._ptfx:Scale(scale)
end

function TornadoParticle:OnUpdate(gameTime, deltaTime)
    self._centerPos = self.Parent._position + self._offset
    
    if math_abs(self._angle) > math_pi * 2.0 then
        self._angle = 0.0
    end
    
    self._angle = self._angle - self._settings.ROTATION_SPEED * self._layerMask * deltaTime
    
    local vortex = self.Parent._position
    local nx = math_min(self._offset.z, math_max(-self._offset.z, self._offset.x + math_random(-10, 10) / 50))
    local ny = math_min(self._offset.z, math_max(-self._offset.z, self._offset.y + math_random(-10, 10) / 50))
    self._offset = vector3(nx, ny, self._offset.z)
    
    local offset = self._offset
    self:SetScale(3.0 + self._offset.z / self._settings.GIRTH_MOD)
    
    if self._prop and DoesEntityExist(self._prop) then
        SetEntityCoords(self._prop, vortex.x + offset.x, vortex.y + offset.y, vortex.z + offset.z, false, false, false, false)
    end
end

function TornadoParticle:Destroy()
    self._ptfx:Remove()
    if self._prop and DoesEntityExist(self._prop) then
        DeleteObject(self._prop)
    end
    self._prop = nil
end

function ActiveEntity:new(entity, xBias, yBias)
    local o = {
        Entity = entity,
        XBias = xBias or 0.0,
        YBias = yBias or 0.0,
        IsPlayer = (entity == PlayerPedId())
    }
    setmetatable(o, self)
    return o
end

function TornadoVortex:new(initialPosition, settings, profile, sourceServerId)
    local o = {
        _position = initialPosition,
        _destination = initialPosition,
        _particles = {},
        _activeEntities = {},
        _activeEntityCount = 0,
        _nextUpdateTime = 0,
        _settings = settings,
        _profile = profile,
        _sourceServerId = sourceServerId,
        _casterPed = nil,
        ForceScale = settings.FORCE_SCALE * (profile.forceMult or 1.0)
    }
    setmetatable(o, self)
    
    if sourceServerId then
        local casterPlayer = GetPlayerFromServerId(sourceServerId)
        if casterPlayer and casterPlayer ~= -1 then
            o._casterPed = GetPlayerPed(casterPlayer)
        end
    end
    
    return o
end

function TornadoVortex:Build()
    local settings = self._settings
    local layerSize = settings.LAYER_SEPARATION_SCALE
    local baseRadius = settings.RADIUS * (self._profile.radiusMult or 1.0)
    local particleCount = settings.PARTICLE_COUNT
    local maxLayers = settings.MAX_PARTICLE_LAYERS
    local particleAsset = 'core'
    local particleName = 'ent_amb_smoke_foundry'
    local multiplier = 360 / math_max(particleCount, 1)
    local baseParticleSize = 2.0  

    for i = 0, maxLayers - 1 do
        local layerRadius = baseRadius + (i * 0.5)
        local layerHeight = layerSize * i
        local particleSize = baseParticleSize + (i * 0.2)
        
        for angle = 0, particleCount - 1 do
            local position = vector3(self._position.x, self._position.y, self._position.z + layerHeight)
            local rotation = vector3(angle * multiplier, 0, 0)
            
            local particle = TornadoParticle:new(self, position, rotation, particleAsset, particleName, layerRadius, i, settings)
            particle:StartFx(particleSize)
            table.insert(self._particles, particle)
        end
    end
end

function TornadoVortex:RemoveEntity(entityIdx)
    local ent = self._activeEntities[entityIdx]
    if ent and ent.Entity and DoesEntityExist(ent.Entity) then
        SetEntityMaxSpeed(ent.Entity, 2500.0)
    end
    self._activeEntities[entityIdx] = nil
    self._activeEntityCount = self._activeEntityCount - 1
end

function TornadoVortex:PushBackEntity(entity)
    table.insert(self._activeEntities, entity)
    self._activeEntityCount = self._activeEntityCount + 1
end

function TornadoVortex:CollectNearbyEntities(maxDistanceDelta)
    local pos = self._position
    local profile = self._profile
    local casterPed = self._casterPed
    local casterVehicle = nil
    
    if casterPed and DoesEntityExist(casterPed) then
        casterVehicle = GetVehiclePedIsIn(casterPed, false)
        if casterVehicle == 0 then casterVehicle = nil end
    end
    
    local function TryAddEnt(entity)
        if not entity or entity == 0 or not DoesEntityExist(entity) then return end
        
        if entity == casterPed then return end
        if casterVehicle and entity == casterVehicle then return end
        
        local entityCoords = GetEntityCoords(entity)
        local dist = #(pos - entityCoords)
        
        if dist < maxDistanceDelta * 2 then
            local found = false
            for _, e in pairs(self._activeEntities) do
                if e and e.Entity == entity then
                    found = true
                    break
                end
            end
            
            if not found then
                if not NetworkHasControlOfEntity(entity) then
                    NetworkRequestControlOfEntity(entity)
                end
                
                local ent = ActiveEntity:new(entity, 0.0, 0.0)
                self:PushBackEntity(ent)
            end
        end
    end
    
    if profile.affectVehicles then
        local handle, vehicle = FindFirstVehicle()
        local success = true
        while success do
            if vehicle and vehicle ~= 0 then
                TryAddEnt(vehicle)
            end
            success, vehicle = FindNextVehicle(handle)
        end
        EndFindVehicle(handle)
    end
    
    if profile.affectPeds then
        local handle, ped = FindFirstPed()
        local success = true
        while success do
            if ped and ped ~= 0 then    
                if ped ~= casterPed then
                    local isPlayer = IsPedAPlayer(ped)
                    if (isPlayer and profile.affectPlayers) or (not isPlayer and profile.affectPeds) then
                        TryAddEnt(ped)
                    end
                end
            end
            success, ped = FindNextPed(handle)
        end
        EndFindPed(handle)
    end
    
    if profile.affectObjects then
        local handle, obj = FindFirstObject()
        local success = true
        while success do
            if obj and obj ~= 0 and DoesEntityExist(obj) then
                local isOurProp = false
                for _, particle in ipairs(self._particles) do
                    if particle and particle._prop == obj then
                        isOurProp = true
                        break
                    end
                end
                if not isOurProp then
                    TryAddEnt(obj)
                end
            end
            success, obj = FindNextObject(handle)
        end
        EndFindObject(handle)
    end
end

function TornadoVortex:UpdatePulledEntities(gameTime, maxDistanceDelta)
    local settings = self._settings
    local verticalForce = settings.VERTICAL_PULL_FORCE * (self._profile.forceMult or 1.0)
    local horizontalForce = settings.HORIZONTAL_PULL_FORCE * (self._profile.forceMult or 1.0)
    local tangentForce = (settings.TANGENT_FORCE or 2.5) * (self._profile.forceMult or 1.0)
    local topSpeed = settings.TOP_ENTITY_SPEED
    local radius = settings.RADIUS * (self._profile.radiusMult or 1.0)
    
    for idx, entData in pairs(self._activeEntities) do
        if entData and entData.Entity then
            local entity = entData.Entity
            
            if not DoesEntityExist(entity) then
                self:RemoveEntity(idx)
            else
                local entityCoords = GetEntityCoords(entity)
                local centerXY = vector3(self._position.x, self._position.y, entityCoords.z)
                local toCenter = centerXY - entityCoords
                local dist = #toCenter
                
                if dist > maxDistanceDelta * 2.5 or GetEntityHeightAboveGround(entity) > 150.0 then
                    self:RemoveEntity(idx)
                else
                    if not NetworkHasControlOfEntity(entity) then
                        NetworkRequestControlOfEntity(entity)
                    end
                    
                    if NetworkHasControlOfEntity(entity) then
                        local entityType = GetEntityType(entity)
                        
                        if entityType == 1 then 
                            SetPedToRagdoll(entity, 800, 800, 0, false, false, false)
                        elseif entityType == 3 then 
                            ActivatePhysics(entity)
                            SetEntityDynamic(entity, true)
                            FreezeEntityPosition(entity, false)
                        end

                        local dirToCenter = dist > 0.1 and (toCenter / dist) or vector3(0, 0, 0)
                        
                        local distRatio = math_min(dist / radius, 2.0)
                        local pullStrength = horizontalForce * distRatio * 1.5
                        
                        if dist > radius then
                            pullStrength = pullStrength * 2.0
                        elseif dist < radius * 0.3 then
                            pullStrength = -0.3 
                        end
                        
                        local centripetal = dirToCenter * pullStrength
                        
                        local tangentDir = vector3(-dirToCenter.y, dirToCenter.x, 0.0)
                        local spinStrength = tangentForce * (1.0 - distRatio * 0.3) 
                        local tangential = tangentDir * spinStrength
                        
                        local heightAbove = entityCoords.z - self._position.z
                        local maxHeight = settings.LAYER_SEPARATION_SCALE * settings.MAX_PARTICLE_LAYERS * 0.6
                        local vertStrength = verticalForce
                        
                        if heightAbove > maxHeight * 0.5 then
                            vertStrength = vertStrength * 0.3
                        elseif heightAbove > maxHeight * 0.8 then
                            vertStrength = -0.2 
                        end
                        
                        local vertical = vector3(0, 0, vertStrength)
                        
                        local totalForce = centripetal + tangential + vertical
                        
                        if IsThisModelAPlane(GetEntityModel(entity)) then
                            totalForce = totalForce * 3.0
                        end
                        
                        ApplyForceToEntityCenterOfMass(entity, 1, totalForce.x, totalForce.y, totalForce.z, false, false, true, false)
                        
                        SetEntityMaxSpeed(entity, topSpeed)
                    end
                end
            end
        end
    end
end

function TornadoVortex:OnUpdate(gameTime, deltaTime)
    local settings = self._settings
    local maxEntityDist = settings.MAX_ENTITY_DIST * (self._profile.radiusMult or 1.0)
    
    if gameTime > self._nextUpdateTime then
        self:CollectNearbyEntities(maxEntityDist)
        self._nextUpdateTime = gameTime + 50
    end
    
    for i = 1, #self._particles do
        if self._particles[i] then
            self._particles[i]:OnUpdate(gameTime, deltaTime)
        end
    end
    
    self:UpdatePulledEntities(gameTime, maxEntityDist)
end

function TornadoVortex:Dispose()
    for i = 1, #self._particles do
        if self._particles[i] then
            self._particles[i]:Destroy()
            self._particles[i] = nil
        end
    end
    self._particles = {}
    
    for idx, entData in pairs(self._activeEntities) do
        if entData and entData.Entity and DoesEntityExist(entData.Entity) then
            SetEntityMaxSpeed(entData.Entity, 2500.0)
        end
    end
    self._activeEntities = {}
    self._activeEntityCount = 0
end

CreateThread(function()
    while not myServerId do
        myServerId = GetPlayerServerId(PlayerId())
        Wait(100)
    end
end)

local lastCastLevel = 1

local function clampLevel(level)
    local numeric = math_floor(tonumber(level) or 1)
    if numeric < 1 then return 1 end
    if numeric > 5 then return 5 end
    return numeric
end

local function BuildCycloneProfile(level)
    local lvl = clampLevel(level)
    local levelCfg = (Config.Levels or {})[lvl] or {}

    return {
        level = lvl,
        forceMult = levelCfg.forceMult or 1.0,
        radiusMult = levelCfg.radiusMult or 1.0,
        duration = levelCfg.duration or Config.Cyclone.duration or 6000,
        affectPlayers = levelCfg.affectPlayers ~= false,
        affectPeds = levelCfg.affectPeds ~= false,
        affectObjects = levelCfg.affectObjects == true,
        affectVehicles = levelCfg.affectVehicles == true,
        shakeDistance = Config.Cyclone.shakeDistance or 30.0,
        shakeIntensity = (Config.Cyclone.shakeIntensity or 0.35) * (levelCfg.shakeMult or 1.0)
    }
end

local function HasProtheaShield()
    local hasShield = false
    if LocalPlayer and LocalPlayer.state then
        hasShield = LocalPlayer.state.protheaShield == true
    end
    if not hasShield and exports['dvr_prothea'] and exports['dvr_prothea'].hasLocalShield then
        local ok, result = pcall(function()
            return exports['dvr_prothea']:hasLocalShield()
        end)
        hasShield = ok and result == true
    end
    return hasShield
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
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Wait(0) end

    UseParticleFxAssetNextCall('core')
    local fx = StartParticleFxLoopedAtCoord('ent_amb_tnl_bubbles_sml', GetEntityCoords(playerPed), 0.0, 0.0, 0.0, 0.9, false, false, false, false)
    if fx then
        wandParticles[playerPed] = fx
        allParticles[fx] = { createdTime = GetGameTimer(), type = 'wand' }
    end
end

local function RotationToDirection(rotation)
    local radX = rotation.x * (math.pi / 180.0)
    local radZ = rotation.z * (math.pi / 180.0)
    return vector3(
        -math.sin(radZ) * math.abs(math.cos(radX)),
        math.cos(radZ) * math.abs(math.cos(radX)),
        math.sin(radX)
    )
end

local function FindTargetCoords(profile)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local dir = RotationToDirection(camRot)
    local maxDist = 50.0

    local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, maxDist)
    if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
        return coords
    end

    return vector3(
        camCoords.x + dir.x * maxDist,
        camCoords.y + dir.y * maxDist,
        camCoords.z + dir.z * maxDist
    )
end

RegisterNetEvent('dvr_cyclone:prepare', function(level)
    lastCastLevel = clampLevel(level or lastCastLevel or 1)
    local profile = BuildCycloneProfile(lastCastLevel)
    local ped = cache.ped
    PlayWandFx(ped)

    CreateThread(function()
        Wait(900)
        local targetCoords = FindTargetCoords(profile)
        TriggerServerEvent('dvr_cyclone:trigger', targetCoords)
        SetTimeout(600, function()
            StopWandFx(ped)
        end)
    end)
end)

RegisterNetEvent('dvr_cyclone:otherPlayerCasting', function(sourceServerId, level)
    local myId = GetPlayerServerId(PlayerId())
    if sourceServerId == myId then return end

    if level then
        lastCastLevel = clampLevel(level or lastCastLevel or 1)
    end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    PlayWandFx(casterPed)
    SetTimeout(2000, function()
        StopWandFx(casterPed)
    end)
end)

RegisterNetEvent('dvr_cyclone:createCyclone', function(sourceServerId, targetCoords, level)
    if not targetCoords then return end

    local profile = BuildCycloneProfile(level or 1)
    
    local _, groundZ = GetGroundZFor_3dCoord(targetCoords.x, targetCoords.y, targetCoords.z + 800.0, false)
    local spawnPos = vector3(targetCoords.x, targetCoords.y, groundZ - 10.0)
    
    local vortex = TornadoVortex:new(spawnPos, VORTEX_SETTINGS, profile, sourceServerId)
    vortex:Build()
    
    local cycloneData = {
        vortex = vortex,
        sourceServerId = sourceServerId,
        endTime = GetGameTimer() + profile.duration,
        profile = profile,
        lastUpdate = GetGameTimer()
    }
    
    table.insert(activeCyclones, cycloneData)
end)

CreateThread(function()
    local lastFrameTime = GetGameTimer()
    
    while true do
        if #activeCyclones == 0 then
            Wait(400)
        else
            Wait(15)
            
            local now = GetGameTimer()
            local deltaTime = (now - lastFrameTime) / 1000.0
            lastFrameTime = now
            
            if deltaTime > 0.1 then deltaTime = 0.1 end
            
            for i = #activeCyclones, 1, -1 do
                local c = activeCyclones[i]
                
                if now >= (c.endTime or 0) then
                    if c.vortex then
                        c.vortex:Dispose()
                    end
                    table.remove(activeCyclones, i)
                else
                    if c.vortex then
                        c.vortex:OnUpdate(now, deltaTime)
                    end
                    
                    local profile = c.profile
                    local hasShield = HasProtheaShield()
                    local localServerId = myServerId or GetPlayerServerId(PlayerId())
                    local isCaster = c.sourceServerId and localServerId and c.sourceServerId == localServerId
                    
                    if profile.affectPlayers and not hasShield and not isCaster then
                        local playerCoords = GetEntityCoords(cache.ped)
                        local dist = #(playerCoords - c.vortex._position)
                        local maxShake = profile.shakeDistance or 30.0
                        
                        if dist < maxShake then
                            local factor = 1.0 - (dist / maxShake)
                            local intensity = (profile.shakeIntensity or 0.35) * factor
                            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity)
                        end
                    end
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for ped, fx in pairs(wandParticles) do
        StopParticleFxLooped(fx, false)
        RemoveParticleFx(fx, false)
    end
    wandParticles = {}

    for handle, _ in pairs(allParticles) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    allParticles = {}

    for _, c in ipairs(activeCyclones) do
        if c.vortex then
            c.vortex:Dispose()
        end
    end
    activeCyclones = {}

    RemoveNamedPtfxAsset('core')
    RemoveNamedPtfxAsset('scr_agencyheistb')
end)
