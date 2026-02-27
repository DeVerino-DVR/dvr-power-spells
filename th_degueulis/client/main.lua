---@diagnostic disable: undefined-global, trailing-space, missing-parameter
local PlayerPedId = PlayerPedId
local DoesEntityExist = DoesEntityExist
local TaskPlayAnim = TaskPlayAnim
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local StartParticleFxLoopedOnEntityBone = StartParticleFxLoopedOnEntityBone
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveParticleFxFromEntity = RemoveParticleFxFromEntity
local GetPedBoneIndex = GetPedBoneIndex
local ClearPedTasks = ClearPedTasks
local GetGameTimer = GetGameTimer

local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local PlayerId = PlayerId
local GetPlayerServerId = GetPlayerServerId
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local vector3 = vector3

local activePukeFx = {}
local activeProjectiles = {}

local function CreateProjectile(startCoords, targetCoords, sourceServerId, targetServerId)
    local cfg = Config.Projectile or {}
    local modelHash = GetHashKey(cfg.model or 'wizardsV_nib_avadakedavra_ray')
    if not lib or not lib.requestModel then return end

    lib.requestModel(modelHash, 5000)

    local prop = CreateObject(modelHash, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(prop, false, false)
    SetEntityAsMissionEntity(prop, true, true)
    SetEntityCompletelyDisableCollision(prop, true, false)
    SetEntityAlpha(prop, 255, false)

    local direction = vector3(
        targetCoords.x - startCoords.x,
        targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z
    )
    local distance = #direction
    if distance <= 0.001 then distance = 0.001 end
    direction = direction / distance

    local heading = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch = -math.deg(math.asin(direction.z))

    SetEntityCoords(prop, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(prop, pitch, 0.0, heading, 2, true)

    local duration = cfg.duration or ((distance / (cfg.speed or 80.0)) * 1000.0)
    local startTime = GetGameTimer()
    local endTime = startTime + duration

    activeProjectiles[prop] = {
        prop = prop,
        startCoords = startCoords,
        targetCoords = targetCoords,
        direction = direction,
        distance = distance,
        startTime = startTime,
        endTime = endTime,
        heading = heading,
        pitch = pitch,
        sourceServerId = sourceServerId,
        targetServerId = targetServerId
    }
end

local function StopPukeFxForPed(ped)
    local entry = activePukeFx[ped]
    if entry then
        if entry.handle then
            StopParticleFxLooped(entry.handle, false)
            RemoveParticleFx(entry.handle, false)
        end
        activePukeFx[ped] = nil
    end
    if ped and DoesEntityExist(ped) and RemoveParticleFxFromEntity then
        RemoveParticleFxFromEntity(ped)
    end
    if entry and entry.asset then
        RemoveNamedPtfxAsset(entry.asset)
    else
        RemoveNamedPtfxAsset('scr_paletoscore')
    end
end

local function StopPukeAnim(ped)
    if ped and DoesEntityExist(ped) then
        ClearPedTasks(ped)
    end
end

local function StopPukeForPed(ped)
    StopPukeFxForPed(ped)
    StopPukeAnim(ped)
end

local function PlayPukeEffect(targetServerId)
    local cfg = Config.Puke or {}
    local animCfg = cfg.anim or {}
    local ptfx = cfg.ptfx or {}
    local myServerId = GetPlayerServerId(PlayerId())
    local effectDuration = ptfx.duration or 4500

    local ped

    if not targetServerId or targetServerId == myServerId then
        ped = cache and cache.ped or PlayerPedId()
    else
        local playerIdx = GetPlayerFromServerId(targetServerId)
        if playerIdx == -1 then return end
        ped = GetPlayerPed(playerIdx)
    end

    if not ped or not DoesEntityExist(ped) then return end

    StopPukeForPed(ped)
    print(('[th_degueulis] start puke for ped %s'):format(ped))

    local animDuration = -1
    local animFlag = 1
    if animCfg.dict and animCfg.name then
        if lib and lib.requestAnimDict then
            lib.requestAnimDict(animCfg.dict)
        end
        animDuration = animCfg.duration
        if animDuration == nil or animDuration <= 0 then
            animDuration = -1
        end
        animFlag = animCfg.flag
        if animFlag == nil then
            animFlag = 1
        end
        TaskPlayAnim(
            ped,
            animCfg.dict,
            animCfg.name,
            8.0,
            -8.0,
            animDuration,
            animFlag,
            0.0,
            false,
            false,
            false
        )
    end

    local waitBeforeFx = ptfx.wait or 200
    if waitBeforeFx > 0 then
        Wait(waitBeforeFx)
    end

    local asset = ptfx.asset or 'scr_paletoscore'
    RequestNamedPtfxAsset(asset)
    while not HasNamedPtfxAssetLoaded(asset) do
        Wait(0)
    end

    UseParticleFxAsset(asset)
    local offset = ptfx.offset or { x = 0.0, y = 0.0, z = 0.0 }
    local rot = ptfx.rot or { x = 0.0, y = 0.0, z = 0.0 }
    local scale = ptfx.scale or 1.0
    local boneIndex = GetPedBoneIndex(ped, ptfx.bone or 31086)

    local fxHandle = StartParticleFxLoopedOnEntityBone(
        ptfx.name or 'scr_trev_puke',
        ped,
        offset.x, offset.y, offset.z,
        rot.x, rot.y, rot.z,
        boneIndex,
        scale,
        false, false, false
    )
    activePukeFx[ped] = { handle = fxHandle, asset = asset }

    if effectDuration and effectDuration > 0 then
        SetTimeout(effectDuration, function()
            StopPukeForPed(ped)
            print(('[th_degueulis] stop puke for ped %s (timeout %dms)'):format(ped, effectDuration))
        end)    
    end
end

RegisterNetEvent('th_degueulis:playPuke', function(targetServerId)
    PlayPukeEffect(targetServerId)
end)

RegisterNetEvent('th_degueulis:fireProjectile', function(sourceServerId, targetCoords, targetServerId)
    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    local handBone = GetPedBoneIndex(casterPed, Config.Projectile.handBone or 28422)
    local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)
    CreateProjectile(startCoords, targetCoords, sourceServerId, targetServerId)
end)

CreateThread(function()
    while true do
        Wait(1)

        local now = GetGameTimer()

        for propId, data in pairs(activeProjectiles) do
            if type(data) == "table" and DoesEntityExist(propId) then
                if now < data.endTime then
                    local progress = (now - data.startTime) / (data.endTime - data.startTime)
                    progress = math.min(progress, 1.0)

                    local newPos = vector3(
                        data.startCoords.x + (data.direction.x * data.distance * progress),
                        data.startCoords.y + (data.direction.y * data.distance * progress),
                        data.startCoords.z + (data.direction.z * data.distance * progress)
                    )

                    SetEntityCoords(propId, newPos.x, newPos.y, newPos.z, false, false, false, false)
                    SetEntityRotation(propId, data.pitch, 0.0, data.heading, 2, true)
                else
                    if DoesEntityExist(propId) then
                        DeleteObject(propId)
                        DeleteEntity(propId)
                    end
                    if data.targetServerId then
                        TriggerServerEvent('th_degueulis:onImpact', data.targetServerId)
                    end
                    activeProjectiles[propId] = nil
                end
            else
                activeProjectiles[propId] = nil
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for ped, _ in pairs(activePukeFx) do
        StopPukeFxForPed(ped)
    end
    for propId, data in pairs(activeProjectiles) do
        if type(data) == "table" and DoesEntityExist(propId) then
            DeleteObject(propId)
            DeleteEntity(propId)
        end
    end
    activeProjectiles = {}
end)
