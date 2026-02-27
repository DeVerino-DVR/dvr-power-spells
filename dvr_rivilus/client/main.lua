---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local cache = cache
local DoesEntityExist = DoesEntityExist
local GetEntityCoords = GetEntityCoords
local GetActivePlayers = GetActivePlayers
local GetPlayerPed = GetPlayerPed
local IsPedAPlayer = IsPedAPlayer
local IsPedDeadOrDying = IsPedDeadOrDying
local PlayerPedId = PlayerPedId
local GetGameTimer = GetGameTimer
local SetEntityDrawOutline = SetEntityDrawOutline
local SetEntityDrawOutlineColor = SetEntityDrawOutlineColor
local SetEntityDrawOutlineShader = SetEntityDrawOutlineShader
local FindFirstPed = FindFirstPed
local FindNextPed = FindNextPed
local EndFindPed = EndFindPed
local FindFirstObject = FindFirstObject
local FindNextObject = FindNextObject
local EndFindObject = EndFindObject
local FindFirstVehicle = FindFirstVehicle
local FindNextVehicle = FindNextVehicle
local EndFindVehicle = EndFindVehicle
local activeEffect = nil

local function Notify(payload)
    if payload then
        lib.notify(payload)
    end
end

local function ClearOutlines()
    if not activeEffect or not activeEffect.entities then
        activeEffect = nil
        return
    end

    for _, entry in ipairs(activeEffect.entities) do
        local entity = entry.entity
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            SetEntityDrawOutline(entity, false)
        end
    end

    activeEffect = nil
end

local function ApplyOutline(entity, color, isPed)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return false
    end

    -- Définir la couleur AVANT d'activer l'outline (important!)
    if color then
        SetEntityDrawOutlineColor(color.r or 255, color.g or 255, color.b or 255, color.a or 255)
    end

    -- Activer l'outline sur l'entité
    SetEntityDrawOutline(entity, true)

    return true
end

local function CollectTargets(origin, radius, maxEntities, allowedKinds)
    local targets = {}
    local seen = {}

    local allowPlayers = not allowedKinds or allowedKinds.player or (allowedKinds.ped and allowedKinds.player ~= false)
    local allowPeds = not allowedKinds or allowedKinds.ped
    local allowObjects = not allowedKinds or allowedKinds.object
    local allowVehicles = not allowedKinds or allowedKinds.vehicle

    local function isAllowed(kind)
        if not allowedKinds then
            return true
        end
        return allowedKinds[kind]
    end

    local function addEntity(entity, kind)
        if not entity or entity == 0 or seen[entity] or not isAllowed(kind) then
            return true
        end

        if not DoesEntityExist(entity) then
            return true
        end

        local coords = GetEntityCoords(entity)
        if #(coords - origin) > radius then
            return true
        end

        if kind == 'ped' and IsPedDeadOrDying(entity, true) then
            return true
        end

        targets[#targets + 1] = {
            entity = entity,
            kind = kind
        }
        seen[entity] = true

        if maxEntities and #targets >= maxEntities then
            return false
        end
        return true
    end

    if allowPlayers and GetActivePlayers then
        local players = GetActivePlayers()
        if players then
            for i = 1, #players do
                local ped = GetPlayerPed(players[i])
                if ped and ped ~= 0 and DoesEntityExist(ped) then
                    if not addEntity(ped, 'player') then
                        return targets
                    end
                end
            end
        end
    end

    if allowPeds then
        local handle, ped = FindFirstPed()
        if handle ~= -1 then
            local success = true
            repeat
                if not addEntity(ped, IsPedAPlayer(ped) and 'player' or 'ped') then
                    success = false
                    break
                end
                success, ped = FindNextPed(handle)
            until not success
            EndFindPed(handle)
        end
    end

    if allowObjects then
        local oHandle, obj = FindFirstObject()
        if oHandle ~= -1 then
            local success = true
            repeat
                if not addEntity(obj, 'object') then
                    success = false
                    break
                end
                success, obj = FindNextObject(oHandle)
            until not success
            EndFindObject(oHandle)
        end
    end

    if allowVehicles then
        local vHandle, veh = FindFirstVehicle()
        if vHandle ~= -1 then
            local success = true
            repeat
                if not addEntity(veh, 'vehicle') then
                    success = false
                    break
                end
                success, veh = FindNextVehicle(vHandle)
            until not success
            EndFindVehicle(vHandle)
        end
    end

    return targets
end

local function ResolveColor(kind, outline)
    outline = outline or Config.Outline or {}
    if kind == 'player' then
        return outline.players or outline.peds
    elseif kind == 'ped' then
        return outline.peds or outline.players
    elseif kind == 'vehicle' then
        return outline.vehicles or outline.objects or outline.peds
    end
    return outline.objects or outline.peds
end

local function StartReveal(settings)
    ClearOutlines()

    local scan = Config.Scan or {}
    local radius = (settings and settings.radius) or scan.baseRadius or 30.0
    local duration = (settings and settings.duration) or scan.duration or 8000
    local maxEntities = (settings and settings.maxEntities) or scan.maxEntities or 50
    local outline = settings and settings.outline or Config.Outline
    local allowedKinds = settings and settings.types

    local playerPed = cache and cache.ped or PlayerPedId()
    local origin = GetEntityCoords(playerPed)
    local targets = CollectTargets(origin, radius, maxEntities, allowedKinds)

    if #targets == 0 then
        Notify(Config.Messages and Config.Messages.nothingFound)
        return
    end

    for _, entry in ipairs(targets) do
        local color = ResolveColor(entry.kind, outline)
        local isPed = entry.kind == 'player' or entry.kind == 'ped'
        ApplyOutline(entry.entity, color, isPed)
    end

    activeEffect = {
        entities = targets,
        origin = origin,
        radius = radius,
        expiresAt = GetGameTimer() + duration
    }
    local effect = activeEffect

    Notify({
        title = 'Rivilus',
        description = ('Entités révélées : %d (rayon %.1fm)'):format(#targets, radius),
        type = 'success',
        icon = 'eye'
    })

    CreateThread(function()
        while activeEffect == effect and GetGameTimer() < effect.expiresAt do
            for i = #effect.entities, 1, -1 do
                local entry = effect.entities[i]
                local entity = entry.entity
                if not entity or entity == 0 or not DoesEntityExist(entity) then
                    table.remove(effect.entities, i)
                    goto continue
                end

                local coords = GetEntityCoords(entity)
                if #(coords - effect.origin) > (effect.radius * 1.25) then
                    SetEntityDrawOutline(entity, false)
                    table.remove(effect.entities, i)
                end

                ::continue::
            end

            if #effect.entities == 0 then
                break
            end

            Wait(250)
        end

        if activeEffect == effect then
            ClearOutlines()
        end
    end)
end

RegisterNetEvent('dvr_rivilus:reveal', function(settings)
    StartReveal(settings)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    ClearOutlines()
end)
