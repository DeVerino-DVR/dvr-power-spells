---@diagnostic disable: param-type-mismatch, missing-parameter, redundant-parameter, undefined-global
local vec = vec or vector3
local cache = cache
local madvr_sqrt = math.sqrt
local PlayerId = PlayerId
local GetPlayerFromServerId = GetPlayerFromServerId

local Liquid = {}

local function startThread(fn)
    if fn then
        CreateThread(fn)
    end
end

local function isLocalSource(sourceId)
    if cache.serverId and sourceId == cache.serverId then
        return true
    end
    local playerId = cache.playerId or PlayerId()
    return GetPlayerFromServerId(sourceId) == playerId
end

local function handleApplyEvent(sourceId, enabled, _, _)
    if not isLocalSource(sourceId) then
        return
    end

    if not Liquid.ped or not Liquid.ped.getId then
        Liquid.pendingState = enabled
        return
    end

    Liquid:toggleLuquidMove(enabled)
end

local function normalizeDirection(x, y, z)
    local magnitude = madvr_sqrt(x * x + y * y + z * z)
    if magnitude ~= 0.0 then
        local inv = 1.0 / magnitude
        return vector3(x * inv, y * inv, z * inv)
    end
    return vector3(0.0, 0.0, 0.0)
end

local function drawAimMarker(coords)
    local x, y, z = table.unpack(coords)
    SetDrawOrigin(x, y, z, 0)
    RequestStreamedTextureDict('helicopterhud', false)
    DrawSprite('helicopterhud', 'hud_dest', 0.0, 0.0, 0.02, 0.03, 0.0, 255, 0, 0, 255)
    ClearDrawOrigin()
end

function Liquid:registerClass()
    Liquid.constructor()
end

local function startPedLoops(self)
    startThread(function()
        while true do
            Wait(0)
            local ped = cache.ped or PlayerPedId()
            local coords = cache.coords or (ped ~= 0 and GetEntityCoords(ped)) or nil
            if ped ~= 0 and coords then
                self.ped = {
                    getId = ped,
                    getCoords = coords,
                    getHealth = GetEntityHealth(ped),
                    getHeading = GetEntityHeading(ped)
                }
                if self.pendingState ~= nil then
                    self:toggleLuquidMove(self.pendingState)
                    SetEntityInvincible(ped, true)
                    self.pendingState = nil
                end
                if self.luquid then
                    local hitCoords, _, entity = self:rayCastGamePlayCamera(50.0, -1)
                    self.aimEntity = DoesEntityExist(entity) and (IsEntityAVehicle(entity) or IsEntityAPed(entity)) and entity or false
                    if hitCoords and (IsEntityAVehicle(entity) or IsEntityAPed(entity)) then
                        local entityCoords = GetEntityCoords(entity)
                        drawAimMarker(vec(entityCoords.x, entityCoords.y, entityCoords.z + 1.0))
                    end
                end
            end
        end
    end)

    startThread(function()
        while true do
            Wait(200)
            if self.ped then
                local nearbyEntities = {}
                for ped in self:EnumeratePeds() do
                    if DoesEntityExist(ped) and ped ~= self.ped.getId and #(self.ped.getCoords - GetEntityCoords(ped)) <= 50.0 then
                        nearbyEntities[#nearbyEntities + 1] = ped
                    end
                end
                for vehicle in self:EnumerateVehicles() do
                    if DoesEntityExist(vehicle) and #(self.ped.getCoords - GetEntityCoords(vehicle)) <= 50.0 then
                        nearbyEntities[#nearbyEntities + 1] = vehicle
                    end
                end
                self.entities = nearbyEntities
            end
        end
    end)
end

local function handleLiquidMovement(self)
    local groundOffset = -0.5
    local landingDecalHandle
    local movedForward = false
    local burstApplied = false

    local function pushEntity(entity)
        if not DoesEntityExist(entity) then
            return
        end
        local pedCoords = self.ped.getCoords
        local entityCoords = GetEntityCoords(entity)
        local closeRange = #(pedCoords - entityCoords) <= 5.0
        local direction = pedCoords - entityCoords
        if not closeRange then
            ApplyForceToEntity(entity, 3, direction.x, direction.y, direction.z, 0.0, 0.0, 0.0, 1, false, false, true, false, false)
            SetEntityVelocity(entity, direction.x, direction.y, direction.z)
            SetEntityNoCollisionEntity(self.ped.getId, entity, false)
        else
            AddExplosion(entityCoords, 70, 3000.0, true, false, 1.0)
            Wait(10)
            DeleteEntity(entity)
        end
    end

    local function waitUntilLanded()
        while true do
            Wait(100)
            local pedCoords = self.ped.getCoords
            local _, groundZ = self:getGroundCoords(pedCoords, groundOffset)
            self:ParticleFxLoopedOnEntityBone({
                pDict = 'core',
                pName = 'bul_decal_oil',
                bone = 24818,
                scale = 5.0
            })
            if tonumber(pedCoords.z) <= tonumber(groundZ) then
                self.moveLiquidParticle = self:ParticleFxLoopedOnEntityBone({
                    pDict = 'scr_xm_aq',
                    pName = 'scr_xm_aq_final_kill_plane_delta',
                    bone = 24818,
                    scale = 1.0
                })
                SetEntityVisible(self.ped.getId, not self.luquid, 0)
                break
            end
        end
    end

    local function addLandingDecal()
        startThread(function()
            Wait(100)
            local decal = self:addDecal('4010', false, vec(0.0, 0.0, groundOffset))
            landingDecalHandle = decal
        end)
    end

    local function removeLandingDecal()
        if landingDecalHandle then
            RemoveDecal(landingDecalHandle)
            landingDecalHandle = nil
        end
    end

    startThread(function()
        while true do
            Wait(100)
            if not self.luquid then
                break
            end
            for vehicle in self:EnumerateVehicles() do
                if DoesEntityExist(vehicle) and #(self.ped.getCoords - GetEntityCoords(vehicle)) <= 4.0 then
                    SetEntityCollision(vehicle, false)
                    SetEntityVelocity(vehicle)
                end
            end
        end
    end)

    startThread(function()
        waitUntilLanded()
        addLandingDecal()
        while true do
            Wait(0)
            DisableControlAction(0, 24, self.luquid)
            DisableControlAction(0, 32, self.luquid)
            DisableControlAction(0, 33, self.luquid)
            DisableControlAction(0, 34, self.luquid)
            DisableControlAction(0, 35, self.luquid)
            if self.luquid_power_run then
                self:togglePowerRun()
            end
            if self.luquid then
                local pedId = self.ped.getId
                local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(pedId)
                SetEntityHeading(pedId, heading)
                if IsDisabledControlJustPressed(0, 24) and self.aimEntity and type(self.aimEntity) ~= 'boolean' then
                    local target = self.aimEntity
                    AddExplosion(GetEntityCoords(target), 70, 3000.0, true, false, 1.0)
                    Wait(10)
                    DeleteEntity(target)
                    burstApplied = true
                elseif IsDisabledControlPressed(0, 24) and not burstApplied then
                    for _, entity in pairs(self.entities or {}) do
                        pushEntity(entity)
                    end
                else
                    burstApplied = false
                end
                if IsDisabledControlPressed(0, 32) then
                    local pedCoords = self.ped.getCoords
                    local forward = GetEntityForwardVector(pedId)
                    local targetPos = pedCoords + forward * 1.0
                    local groundCoords = self:getGroundCoords(targetPos, groundOffset)
                    self:addDecal('4010', 3.0, vec(0.0, 0.0, groundOffset))
                    SetEntityCoords(pedId, groundCoords, false, false, false, false)
                    movedForward = true
                elseif movedForward then
                    removeLandingDecal()
                    addLandingDecal()
                    movedForward = false
                else
                    local ground, groundZ = self:getGroundCoords(nil, groundOffset)
                    if ground then
                        SetEntityCoords(pedId, ground, false, false, false, false)
                        self.lastGround = ground
                        self.lastGroundZ = groundZ or ground.z
                    end
                end
            else
                StopParticleFxLooped(self.moveLiquidParticle, true)
                removeLandingDecal()
                self:ParticleFxLoopedOnEntityBone({
                    pDict = 'core',
                    pName = 'bul_decal_oil',
                    bone = 24818,
                    scale = 5.0
                })
                break
            end
        end
    end)
end

local function playLiquidIntro(self)
    startThread(function()
        local pedId = self.ped.getId

        -- Jouer l'animation zombie agony
        RequestAnimDict('zombies_animations')
        while not HasAnimDictLoaded('zombies_animations') do
            Wait(10)
        end
        TaskPlayAnim(pedId, 'zombies_animations', 'agony', 8.0, -8.0, -1, 1, 0, false, false, false)

        local bones = {
            31086,
            24818,
            40269,
            45509,
            61163,
            28252,
            51826,
            52301
        }

        local particleHandles = {}
        for i = 1, #bones do
            local handle = self:ParticleFxLoopedOnEntityBone({
                pDict = 'core',
                pName = 'ent_dst_dust',
                bone = bones[i],
                scale = 0.3,
                color = { r = 0, g = 0, b = 0 }
            })
            particleHandles[#particleHandles + 1] = handle
        end

        -- Ajouter les particules d'huile noire une après l'autre
        for i = 1, #bones do
            local oilParticle = self:ParticleFxLoopedOnEntityBone({
                pDict = 'core',
                pName = 'bul_decal_oil',
                bone = bones[i],
                scale = 5.0
            })
            particleHandles[#particleHandles + 1] = oilParticle
            Wait(200)  -- Délai entre chaque particule d'huile
        end

        Wait(1400)  -- Temps restant pour compléter les 3 secondes (3000 - 8*200 = 1400)

        -- Arrêter l'animation et les particules
        ClearPedTasks(pedId)
        for _, handle in pairs(particleHandles) do
            StopParticleFxLooped(handle, true)
        end
        RemoveAnimDict('zombies_animations')
    end)
end

function Liquid:toggleLuquidMove(desiredState)
    if not self.ped or not self.ped.getId then
        return
    end

    local pedId = self.ped.getId
    local nextState = desiredState
    if nextState == nil then
        nextState = not self.luquid
    end

    if nextState == self.luquid then
        return
    end

    self.luquid = nextState
    if self.luquid then
        playLiquidIntro(self)
        Wait(3000)

        local groundVec, groundZ = self:getGroundCoords(self.ped.getCoords, 0.0)
        self.lastGround = groundVec or self.ped.getCoords
        self.lastGroundZ = groundZ or self.ped.getCoords.z
        handleLiquidMovement(self)
    end
    if not self.luquid then
        SetEntityVisible(pedId, true, 0)
    end

    SetEntityCollision(pedId, not self.luquid, false)
    local baseCoords = self.lastGround or self.ped.getCoords
    local targetZ = (self.lastGroundZ or baseCoords.z) - 0.2 + 0.0001
    SetEntityCoords(pedId, vec(baseCoords.x, baseCoords.y, targetZ), false, false, false, false)

    if self.luquid then
        self:playAnim(self.ped.getId, 'move_fall@beastjump', 'high_land_stand', 1)
    end
end

local function playRunParticles(self)
    startThread(function()
        local bones = {
            45509, 40269, 60309, 28422, 57005, 63931, 36864, 58217, 51826, 31086, 24818, 2992, 22711, 23553, 24816,
            24817, 24818, 36864, 56604, 5232, 37119, 43810, 61007, 14201, 24806, 35502, 52301, 57717, 65245, 10706,
            61163, 28252, 61163
        }
        while true do
            local handles = {}
            for i = 1, #bones do
                handles[#handles + 1] = self:ParticleFxNonLoopedOnPedBone({
                    pDict = 'scr_powerplay',
                    pName = 'sp_powerplay_beast_appear_trails',
                    bone = bones[i],
                    scale = 2.0
                })
            end
            for _, handle in pairs(handles) do
                RemoveParticleFx(handle)
            end
            if not self.luquid_power_run then
                break
            end
            Wait(1000)
        end
    end)
end

local function handlePowerRun(self)
    startThread(function()
        while true do
            Wait(0)
            DisableControlAction(0, 24, self.luquid_power_run)
            if self.luquid_power_run then
                if IsPedFalling(self.ped.getId) then
                    self:stopAnim()
                end
                local pedCoords = self.ped.getCoords
                local forward = GetEntityForwardVector(self.ped.getId)
                local isMoving = IsPedRunning(self.ped.getId) and 1 or IsPedSprinting(self.ped.getId) and 1 or IsPedWalking(self.ped.getId) and 0
                if not IsPedRagdoll(self.ped.getId) then
                    if isMoving == 1 then
                        local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(self.ped.getId)
                        local _, groundZ = GetGroundZFor_3dCoord(pedCoords.x, pedCoords.y, pedCoords.z)
                        local forceZ = 0.0
                        if math.floor(pedCoords.z) - math.floor(groundZ) >= 1 then
                            forceZ = -30.0
                        end
                        SetEntityVelocity(self.ped.getId, forward.x * 60.0, forward.y * 60.0)
                        ApplyForceToEntity(self.ped.getId, 1, forward.x, forward.y, forceZ, 0.0, 0.0, 0.0, 1, false, true, true, true, true)
                        SetEntityHeading(self.ped.getId, heading)
                        ResetPlayerStamina(PlayerId())
                    elseif isMoving == 0 then
                        FreezeEntityPosition(self.ped.getId, true)
                        FreezeEntityPosition(self.ped.getId, false)
                        Wait(1000)
                    end
                end
            else
                FreezeEntityPosition(self.ped.getId, true)
                FreezeEntityPosition(self.ped.getId, false)
                break
            end
        end
    end)
end

function Liquid:togglePowerRun()
    local pedId = self.ped.getId
    self.luquid_power_run = not self.luquid_power_run
    self:ParticleFxNonLoopedOnEntity({
        pDict = 'veh_sanctus',
        pName = 'veh_sanctus_backfire',
        bone = 24818,
        scale = 10.0
    })
    PlaySoundFromEntity(-1, 'Whoosh_1s_R_to_L', pedId, 'MP_LOBBY_SOUNDS', 0, 0)
    SetEntityVisible(pedId, not self.luquid_power_run, 0)
    if self.luquid_power_run then
        playRunParticles(self)
        handlePowerRun(self)
    end
    self.run_particle = self.luquid_power_run and self:ParticleFxLoopedOnEntityBone({
        pDict = 'scr_xm_heat',
        pName = 'scr_xm_heat_camo',
        bone = 24818,
        scale = 2.0
    }) or StopParticleFxLooped(self.run_particle, true)
end

function Liquid:ParticleFxNonLoopedOnEntity(data)
    local dict = data.pDict
    local name = data.pName
    local offSet = data.offSet or vec(0.0, 0.0, 0.0)
    local rot = data.rot or vec(0.0, 0.0, 0.0)
    local scale = data.scale or 0.0
    UseParticleFxAssetNextCall(dict)
    while not HasNamedPtfxAssetLoaded(dict) do
        RequestNamedPtfxAsset(dict)
        Wait(10)
    end
    SetPtfxAssetNextCall(dict)
    local handle = StartNetworkedParticleFxNonLoopedOnEntity(name, self.ped.getId, offSet.x, offSet.y, offSet.z, rot.x, rot.y, rot.z, scale, 0, 0, 0)
    SetParticleFxNonLoopedColour(handle, 0, 0, 0)
    RemoveNamedPtfxAsset(dict)
    return handle
end

function Liquid:ParticleFxNonLoopedOnPedBone(data)
    local dict = data.pDict
    local name = data.pName
    local offSet = data.offSet or vec(0.0, 0.0, 0.0)
    local rot = data.rot or vec(0.0, 0.0, 0.0)
    local bone = data.bone or 31086
    local scale = data.scale or 0.0
    while not HasNamedPtfxAssetLoaded(dict) do
        RequestNamedPtfxAsset(dict)
        Wait(10)
    end
    SetPtfxAssetNextCall(dict)
    local handle = StartNetworkedParticleFxNonLoopedOnPedBone(name, self.ped.getId, offSet.x, offSet.y, offSet.z, rot.x, rot.y, rot.z, bone, scale, 0, 0, 0)
    SetParticleFxNonLoopedColour(handle, 0, 0, 0)
    RemoveNamedPtfxAsset(dict)
    return handle
end

function Liquid:ParticleFxLoopedOnEntityBone(data)
    local dict = data.pDict
    local name = data.pName
    local offSet = data.offSet or vec(0.0, 0.0, 0.0)
    local rot = data.rot or vec(0.0, 0.0, 0.0)
    local bone = data.bone or 31086
    local scale = data.scale or 0.0
    local color = data.color or { r = 0, g = 0, b = 0 }
    while not HasNamedPtfxAssetLoaded(dict) do
        RequestNamedPtfxAsset(dict)
        Wait(10)
    end
    SetPtfxAssetNextCall(dict)
    local handle = StartNetworkedParticleFxLoopedOnEntityBone(name, self.ped.getId, offSet.x, offSet.y, offSet.z, rot.x, rot.y, rot.z, bone, scale, 0, 0, 0)
    SetParticleFxLoopedColour(handle, color.r, color.g, color.b)
    RemoveNamedPtfxAsset(dict)
    return handle
end

function Liquid:ParticleFxNonLoopedAtCoord(data)
    local dict = data.pDict
    local name = data.pName
    local pos = data.pos or vec(0.0, 0.0, 0.0)
    local rot = data.rot or vec(0.0, 0.0, 0.0)
    local scale = data.scale or 0.0
    local color = data.color or { r = 0, g = 0, b = 0 }
    while not HasNamedPtfxAssetLoaded(dict) do
        RequestNamedPtfxAsset(dict)
        Wait(10)
    end
    SetPtfxAssetNextCall(dict)
    local handle = StartNetworkedParticleFxNonLoopedAtCoord(name, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, scale)
    SetParticleFxLoopedColour(handle, color.r, color.g, color.b)
    RemoveNamedPtfxAsset(dict)
    return handle
end

local function rotationToDirection(rotation)
    local rad = {
        x = math.pi / 180 * rotation.x,
        y = math.pi / 180 * rotation.y,
        z = math.pi / 180 * rotation.z
    }
    return {
        x = -math.sin(rad.z) * math.abs(math.cos(rad.x)),
        y = math.cos(rad.z) * math.abs(math.cos(rad.x)),
        z = math.sin(rad.x)
    }
end

function Liquid:getForwardVectorAtCoords(distance)
    local camRot = GetGameplayCamRot()
    local camCoord = GetGameplayCamCoord()
    local dir = rotationToDirection(camRot)
    return vec(camCoord.x + dir.x * distance, camCoord.y + dir.y * distance, camCoord.z + dir.z * distance)
end

function Liquid:rayCastGamePlayCamera(distance, flags, castType)
    local camRot = GetGameplayCamRot()
    local camCoord = GetGameplayCamCoord()
    local dir = rotationToDirection(camRot)
    local target = { x = camCoord.x + dir.x * distance, y = camCoord.y + dir.y * distance, z = camCoord.z + dir.z * distance }
    local ray = StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, target.x, target.y, target.z, flags or 1, -1, 1)
    local capsule = StartShapeTestCapsule(camCoord.x, camCoord.y, camCoord.z, target.x, target.y, target.z, 10.0, 7, self.ped and self.ped.getId or -1, 1)
    local handle = castType == 'point' and ray or capsule
    local hit, hitCoords, _, _, entity = GetShapeTestResult(handle)
    return hitCoords, hit, entity, vec(target.x, target.y, target.z)
end

function Liquid:playAnim(pedId, dict, anim, flag)
    local waited = 0
    while not HasAnimDictLoaded(dict) and waited <= 5000 do
        Wait(10)
        waited = waited + 100
        RequestAnimDict(dict)
    end
    TaskPlayAnim(pedId, dict, anim, 8.0, -8.0, -1, flag or 0, 0, false, false, false)
    RemoveAnimDict(dict)
end

function Liquid:stopAnim()
    ClearPedTasks(self.ped.getId)
end

function Liquid:addDecal(decalType, fade, offset)
    local decalId = tonumber(decalType) or 1010
    local pedOffset = GetOffsetFromEntityInWorldCoords(self.ped.getId, offset.x or 0.0, offset.y or 0.0, offset.z or -1.0)
    local handle = AddDecal(decalId, pedOffset.x, pedOffset.y, pedOffset.z, 0.0, 0.0, -1.0, normalizeDirection(0.0, 1.0, 0.0), 10.0, 10.0, 255, 255, 255, 1.0, -1.0, 0, 0, 0)
    startThread(function()
        if fade then
            Wait(100)
            FadeDecalsInRange(pedOffset.x, pedOffset.y, pedOffset.z, 1.0, fade)
        end
    end)
    return handle, pedOffset
end

function Liquid:notify(text)
    AddTextEntry('psychokinetic:basic:notify', text)
    BeginTextCommandThefeedPost('psychokinetic:basic:notify')
    DrawNotification(true, false)
end

function Liquid:getGroundCoords(pos, offset)
    local coords = pos or (self.ped and self.ped.getCoords) or cache.coords
    if not coords then
        return self.lastGround or vec(0.0, 0.0, 0.0), self.lastGroundZ or 0.0
    end

    local zOffset = offset or 0.0
    local baseZ = coords.z

    local startZ = baseZ + 50.0
    local endZ = baseZ - 200.0
    local rayHandle = StartShapeTestRay(coords.x, coords.y, startZ, coords.x, coords.y, endZ, -1, self.ped and self.ped.getId or -1, 1)
    local _, hit, hitPos = GetShapeTestResult(rayHandle)
    if hit == 1 and hitPos then
        local groundVec = vec(hitPos.x, hitPos.y, hitPos.z + zOffset)
        self.lastGround = groundVec
        self.lastGroundZ = hitPos.z
        return groundVec, hitPos.z
    end

    for i = 0, 1000 do
        local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + i + 0.0, true)
        if found then
            local groundVec = vec(coords.x, coords.y, groundZ + zOffset)
            self.lastGround = groundVec
            self.lastGroundZ = groundZ
            return groundVec, groundZ
        end
    end

    if self.lastGroundZ then
        return vec(coords.x, coords.y, self.lastGroundZ + zOffset), self.lastGroundZ
    end

    return vec(coords.x, coords.y, baseZ + zOffset), baseZ
end

local enumeratorGc = {
    __gc = function(state)
        if state.destructor and state.handle then
            state.destructor(state.handle)
        end
        state.destructor = nil
        state.handle = nil
    end
}

local function createEnumerator(firstFunc, nextFunc, endFunc)
    return coroutine.wrap(function()
        local iter, entity = firstFunc()
        if not entity or entity == 0 then
            endFunc(iter)
            return
        end
        local state = {
            handle = iter,
            destructor = endFunc
        }
        setmetatable(state, enumeratorGc)
        local continue = true
        repeat
            coroutine.yield(entity)
            continue, entity = nextFunc(iter)
        until not continue
        state.destructor, state.handle = nil, nil
        endFunc(iter)
    end)
end

function Liquid:EnumerateObjects()
    return createEnumerator(FindFirstObject, FindNextObject, EndFindObject)
end

function Liquid:EnumeratePeds()
    return createEnumerator(FindFirstPed, FindNextPed, EndFindPed)
end

function Liquid:EnumerateVehicles()
    return createEnumerator(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

function Liquid:EnumeratePickups()
    return createEnumerator(FindFirstPickup, FindNextPickup, EndFindPickup)
end

Liquid.constructor = function()
    local selfRef = Liquid
    selfRef.luquid = false
    selfRef.luquid_power_run = false
    selfRef.luquid_blackhole = false
    selfRef.aimEntity = nil
    selfRef.pendingState = nil
    startPedLoops(selfRef)
end

Liquid:registerClass()

RegisterNetEvent('dvr_liquid:apply', function(sourceId, enabled, duration, level)
    handleApplyEvent(sourceId, enabled, duration, level)
end)

CreateThread(function()
    while true do
        Wait(30000)
        collectgarbage()
    end
end)