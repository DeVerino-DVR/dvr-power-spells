---@diagnostic disable: trailing-space, redundant-parameter, undefined-global
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartNetworkedParticleFxLoopedOnEntityBone = StartNetworkedParticleFxLoopedOnEntityBone
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local SetTimeout = SetTimeout
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local DrawLightWithRange = DrawLightWithRange
local SetCamCoord = SetCamCoord
local SetCamRot = SetCamRot
local SetCamActive = SetCamActive
local RenderScriptCams = RenderScriptCams
local DoesEntityExist = DoesEntityExist
local GetGameTimer = GetGameTimer
local GetGameplayCamRot = GetGameplayCamRot
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local SetEntityVelocity = SetEntityVelocity
local IsControlPressed = IsControlPressed
local IsControlJustPressed = IsControlJustPressed
local CreateThread = CreateThread
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local StartShapeTestCapsule = StartShapeTestCapsule
local GetShapeTestResult = GetShapeTestResult
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord

local isTransplanning = false
local transplanStartTime = 0
local transplanCam = nil
local localDuration = Config.Transplanner.duration
local transvalisReturnPosition = nil
local teleportedPlayers = {} -- Liste des joueurs téléportés pour le return
local localFX = {
    smoke = nil,
    aura = nil,
    trails = {},
    pulseStart = 0,
    nextTrailAt = 0,
    lastCoords = nil,
    motionTrailLoaded = false,
    jobTrail = nil,
    color = nil
}

local remoteStates = {}
local syncTickRate = 50 -- Envoyer la position toutes les 50ms pour une synchronisation fluide
local lastSyncTime = 0

local function SetTransvalisState(active)
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('transvalisActive', active, false)
    end
end

-- Fonction pour obtenir la configuration actuelle de transvalis
local function GetTransvalisConfig()
    if exports['th_transvalis'] and exports['th_transvalis'].GetTransvalisConfig then
        return exports['th_transvalis']:GetTransvalisConfig()
    end
    return Config.SpellConfig.default
end

local function SaveReturnPosition()
    local playerPed = cache.ped
    if not playerPed then return end

    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    transvalisReturnPosition = {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = heading
    }
end

local function ReturnTeleportedPlayers()
    local playerPed = cache.ped
    if not playerPed then return end

    -- Vérifier qu'on a une position de retour
    if not transvalisReturnPosition then
        lib.notify({
            title = 'Erreur',
            description = 'Aucune position de retour sauvegardée',
            type = 'error'
        })
        return
    end

    -- Vérifier que le sort est équipé
    local hasSpell = false
    if exports['th_power'] and exports['th_power'].GetSpell then
        local ok, has, level = pcall(function()
            return exports['th_power']:GetSpell('transvalis')
        end)
        if ok and has and level then
            hasSpell = true
        end
    end

    if not hasSpell then
        lib.notify({
            title = 'Erreur',
            description = 'Vous devez avoir le sort Transvalis équipé',
            type = 'error'
        })
        return
    end

    -- Vérifier que le sort est sélectionné
    local selectedSpell = nil
    if exports['th_power'] and exports['th_power'].getSelectedSpell then
        selectedSpell = exports['th_power']:getSelectedSpell()
    end

    if selectedSpell ~= 'transvalis' then
        lib.notify({
            title = 'Erreur',
            description = 'Vous devez avoir le sort Transvalis sélectionné',
            type = 'error'
        })
        return
    end

    -- Vérifier que la baguette est équipée
    local weapon = cache.weapon
    local wandHash = GetHashKey('WEAPON_WAND')
    if weapon ~= wandHash then
        lib.notify({
            title = 'Erreur',
            description = 'Vous devez avoir la baguette en main',
            type = 'error'
        })
        return
    end

    local config = GetTransvalisConfig()
    local myServerId = GetPlayerServerId(PlayerId())
    TriggerServerEvent('th_transvalis:broadcastStart', myServerId, 2000, nil)

    local returnPos = transvalisReturnPosition
    local playersToReturn = {}
    if config.bringPlayers then
        local myCoords = GetEntityCoords(playerPed)
        local radius = config.bringRadius or 5.0
        local r2 = radius * radius

        for _, playerData in ipairs(teleportedPlayers) do
            local targetPlayer = GetPlayerFromServerId(playerData.serverId)
            if targetPlayer ~= -1 then
                local targetPed = GetPlayerPed(targetPlayer)
                if targetPed and targetPed > 0 and DoesEntityExist(targetPed) then
                    local targetCoords = GetEntityCoords(targetPed)
                    local dx = targetCoords.x - myCoords.x
                    local dy = targetCoords.y - myCoords.y
                    if (dx * dx + dy * dy) <= r2 then
                        table.insert(playersToReturn, playerData)
                    end
                end
            end
        end
    end

    CreateThread(function()
        Wait(2000)

        local ped = cache.ped
        if not ped then return end

        if exports['th_transvalis'] and exports['th_transvalis'].StopTransplanning then
            exports['th_transvalis']:StopTransplanning(false)
        end

        Wait(50)

        if ped and returnPos then
            SetEntityCoords(ped, returnPos.x, returnPos.y, returnPos.z, false, false, false, true)
            SetEntityHeading(ped, returnPos.h)
        end

        Wait(200)

        TriggerServerEvent('th_transvalis:broadcastStart', myServerId, 4000, nil)

        if config.bringPlayers and #playersToReturn > 0 then
            Wait(100)

            local returnTargets = {}
            for _, playerData in ipairs(playersToReturn) do
                if playerData.serverId and playerData.originalCoords then
                    local returnCoords = {
                        x = tonumber(playerData.originalCoords.x),
                        y = tonumber(playerData.originalCoords.y),
                        z = tonumber(playerData.originalCoords.z)
                    }
                    if returnCoords.x and returnCoords.y and returnCoords.z then
                        table.insert(returnTargets, {
                            serverId = playerData.serverId,
                            originalCoords = returnCoords
                        })
                    end
                end
            end

            if #returnTargets > 0 then
                TriggerServerEvent('th_transvalis:teleportMultiplePlayers', returnTargets, returnPos)
            end
        end

        Wait(4000)

        if exports['th_transvalis'] and exports['th_transvalis'].StopTransplanning then
            exports['th_transvalis']:StopTransplanning(false)
        end
        
        local pedCoords = GetEntityCoords(ped)
        local arrivalCoords = {
            x = pedCoords.x,
            y = pedCoords.y,
            z = pedCoords.z
        }
        TriggerServerEvent('th_transvalis:broadcastArrivalEffects', myServerId, arrivalCoords)

        teleportedPlayers = {}
        transvalisReturnPosition = nil
        if config.bringPlayers and #playersToReturn > 0 then
            lib.notify({
                title = 'Retour effectué',
                description = string.format('Vous et %d joueur(s) ramené(s) à votre position initiale', #playersToReturn),
                type = 'success'
            })
        else
            lib.notify({
                title = 'Retour effectué',
                description = 'Vous avez été ramené à votre position initiale',
                type = 'success'
            })
        end
    end)
end

-- Fonction pour téléporter les joueurs autour de soi
local function BringNearbyPlayers(radius)
    local config = GetTransvalisConfig()
    if not config.bringPlayers then return end

    radius = radius or config.bringRadius or 5.0
    local myPed = cache.ped
    if not myPed then return end

    local myCoords = GetEntityCoords(myPed)
    local r2 = radius * radius
    local targets = {}

    -- Trouver les joueurs dans le rayon
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            if ped and ped ~= 0 then
                local coords = GetEntityCoords(ped)
                local dx = coords.x - myCoords.x
                local dy = coords.y - myCoords.y
                if (dx * dx + dy * dy) <= r2 then
                    local serverId = GetPlayerServerId(player)
                    table.insert(targets, {
                        serverId = serverId,
                        originalCoords = {
                            x = coords.x,
                            y = coords.y,
                            z = coords.z,
                            h = GetEntityHeading(ped)
                        }
                    })
                end
            end
        end
    end

    if #targets == 0 then
        lib.notify({
            title = 'Aucun joueur',
            description = 'Aucun joueur trouvé dans le rayon spécifié',
            type = 'info'
        })
        return
    end

    -- Sauvegarder les joueurs pour le return
    teleportedPlayers = targets

    -- Téléporter les joueurs vers soi
    for _, target in ipairs(targets) do
        TriggerServerEvent('th_transvalis:teleportPlayerToMe', target.serverId, myCoords)
    end

    lib.notify({
        title = 'Bring Players',
        description = string.format('%d joueur(s) téléporté(s) vers vous', #targets),
        type = 'success'
    })
end

local function EnsureAsset(asset)
    if not asset then
        return false
    end

    RequestNamedPtfxAsset(asset)
    while not HasNamedPtfxAssetLoaded(asset) do
        Wait(0)
    end

    return true
end

local function SetLoopColour(handle, colour)
    if not handle or not colour then
        return
    end

    local r = colour.r or 0.0
    local g = colour.g or 0.0
    local b = colour.b or 0.0

    if r > 1.0 or g > 1.0 or b > 1.0 then
        r = r / 255.0
        g = g / 255.0
        b = b / 255.0
    end

    SetParticleFxLoopedColour(handle, r, g, b, false)
end

local function NormalizeTrailColor(color)
    local jobColors = Config.JobTrailColors
    local default = jobColors and jobColors.default

    if type(color) == 'string' then
        local key = color:lower():gsub('^%s*(.-)%s*$', '%1')
        
        -- Vérifier d'abord si c'est une couleur personnalisée
        if Config.SpellConfig and Config.SpellConfig.customColors then
            for _, colorData in ipairs(Config.SpellConfig.customColors) do
                if colorData.value == key then
                    color = colorData.color
                    break
                end
            end
        end
        
        -- Si ce n'est pas une couleur personnalisée, vérifier les couleurs de job
        if type(color) == 'string' and jobColors and jobColors[key] then
            color = jobColors[key]
        elseif type(color) == 'string' then
            color = default
        end
    elseif type(color) ~= 'table' then
        color = default
    end

    if type(color) ~= 'table' then
        color = { r = 255, g = 255, b = 255 }
    end

    local function clamp(val)
        val = tonumber(val) or 0
        if val < 0 then return 0 end
        if val > 255 then return 255 end
        return val
    end

    return {
        r = clamp((color and color.r) or color[1]),
        g = clamp((color and color.g) or color[2]),
        b = clamp((color and color.b) or color[3])
    }
end

local function CleanupJobTrail(container)
    if not container then
        return
    end

    if container.attached then
        StopParticleFxLooped(container.attached, true)
        RemoveParticleFx(container.attached, true)
        container.attached = nil
    end
end

local function EnsureJobTrailAttached(container, entity)
    local cfg = Config.Effects.jobTrail
    if not cfg or not container or not entity then
        return
    end

    if container.attached then
        return
    end

    local dict = cfg.asset or 'scr_ba_bb'
    if not EnsureAsset(dict) then
        return
    end

    UseParticleFxAssetNextCall(dict)
    local scale = cfg.scale or 0.1
    local bone = cfg.bone or 24818
    -- Utiliser la version NON-réseau pour éviter que les autres joueurs voient la fumée
    -- La traînée est synchronisée manuellement via les events
    local fx = StartParticleFxLoopedOnEntityBone(
        cfg.effect or 'scr_ba_bb_plane_smoke_trail',
        entity,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        bone,
        scale + 0.0,
        false, false, false
    )

    if fx then
        SetLoopColour(fx, container.color or cfg.default_color or { r = 255, g = 255, b = 255 })
        container.attached = fx
    end
end

local function StartTimedLoopAtCoord(cfg, coords)
    if not cfg or not coords then
        return
    end

    if not EnsureAsset(cfg.asset) then
        return
    end

    UseParticleFxAsset(cfg.asset)
    local fx = StartParticleFxLoopedAtCoord(
        cfg.name,
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        cfg.scale or 1.0,
        false, false, false, false
    )

    if not fx then
        return
    end

    SetTimeout(cfg.duration or 1500, function()
        StopParticleFxLooped(fx, 0)
        RemoveParticleFx(fx, false)
    end)
end

local function PlayNonLoopedEffect(cfg, coords)
    if not cfg or not coords then
        return
    end

    if not EnsureAsset(cfg.asset) then
        return
    end

    local offset = cfg.offset
    if offset then
        coords = vector3(coords.x + offset.x, coords.y + offset.y, coords.z + offset.z)
    end

    for _ = 1, (cfg.count or 1) do
        UseParticleFxAssetNextCall(cfg.asset)
        StartParticleFxNonLoopedAtCoord(
            cfg.effect,
            coords.x, coords.y, coords.z,
            0.0, 0.0, 0.0,
            cfg.scale or 1.0,
            false, false, false
        )
    end

    if cfg.light then
        local lightCfg = cfg.light
        local startTime <const> = GetGameTimer()
        local duration <const> = lightCfg.duration or 400

        CreateThread(function()
            local now = GetGameTimer()
            while now - startTime < duration do
                local progress <const> = (now - startTime) / duration
                local fade <const> = 1.0 - progress
                DrawLightWithRange(
                    coords.x, coords.y, coords.z,
                    lightCfg.color.r,
                    lightCfg.color.g,
                    lightCfg.color.b,
                    lightCfg.radius or 5.0,
                    (lightCfg.intensity or 9.0) * fade
                )
                Wait(0)
                now = GetGameTimer()
            end
        end)
    end
end

local function PulseLight(coords, settings, startTime)
    if not coords or not settings or not settings.color then
        return
    end

    local now <const> = GetGameTimer()
    local period <const> = settings.period or 1800
    local phase = ((now - (startTime or now)) % period) / period
    local wave <const> = 0.5 + 0.5 * math.sin(phase * 2.0 * math.pi)

    DrawLightWithRange(
        coords.x, coords.y, coords.z,
        settings.color.r,
        settings.color.g,
        settings.color.b,
        settings.radius or 6.0,
        (settings.intensity or 10.0) * wave
    )
end

local function StartSmokeFx(entity)
    if not DoesEntityExist(entity) then
        return nil
    end

    local handles = {}
    local mainCfg <const> = Config.Effects.blackSmoke
    local secondaryCfg <const> = Config.Effects.additionalSmoke

    if mainCfg and EnsureAsset(mainCfg.asset) then
        UseParticleFxAsset(mainCfg.asset)
        handles.primary = StartParticleFxLoopedOnEntity(
            mainCfg.name,
            entity,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            mainCfg.scale or 1.0,
            false, false, false
        )

        if handles.primary then
            SetLoopColour(handles.primary, mainCfg.color)
            if mainCfg.alpha then
                SetParticleFxLoopedAlpha(handles.primary, mainCfg.alpha)
            end
        end
    end

    if secondaryCfg and EnsureAsset(secondaryCfg.asset) then
        UseParticleFxAsset(secondaryCfg.asset)
        handles.secondary = StartParticleFxLoopedOnEntity(
            secondaryCfg.name,
            entity,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            secondaryCfg.scale or 1.0,
            false, false, false
        )

        if handles.secondary then
            SetLoopColour(handles.secondary, secondaryCfg.color)
            if secondaryCfg.alpha then
                SetParticleFxLoopedAlpha(handles.secondary, secondaryCfg.alpha)
            end
        end
    end

    return handles
end

local function StopSmokeFx(handles)
    if not handles then
        return
    end

    if handles.primary then
        StopParticleFxLooped(handles.primary, 0)
        RemoveParticleFx(handles.primary, false)
    end

    if handles.secondary then
        StopParticleFxLooped(handles.secondary, 0)
        RemoveParticleFx(handles.secondary, false)
    end
end

local function StartAura(entity)
    local cfg = Config.Effects.aura
    if not cfg or not DoesEntityExist(entity) then
        return nil
    end

    if not EnsureAsset(cfg.asset) then
        return nil
    end

    UseParticleFxAsset(cfg.asset)
    local handle = StartParticleFxLoopedOnEntity(
        cfg.effect,
        entity,
        cfg.offset and cfg.offset.x or 0.0,
        cfg.offset and cfg.offset.y or 0.0,
        cfg.offset and cfg.offset.z or 0.0,
        0.0, 0.0, 0.0,
        cfg.scale or 1.0,
        false, false, false
    )

    if handle then
        SetLoopColour(handle, cfg.color)
        if cfg.alpha then
            SetParticleFxLoopedAlpha(handle, cfg.alpha)
        end
    end

    return handle
end

local function StopAura(handle)
    if handle then
        StopParticleFxLooped(handle, false)
    end
end

local function SpawnTrailFx(trailTable, coords)
    local cfg = Config.Effects.trail
    if not cfg or not coords then
        return
    end

    if not EnsureAsset(cfg.asset) then
        return
    end

    UseParticleFxAssetNextCall(cfg.asset)
    local fx = StartParticleFxLoopedAtCoord(
        cfg.effect,
        coords.x, coords.y, coords.z + (cfg.offset or -0.5),
        0.0, 0.0, 0.0,
        cfg.scale or 1.0,
        false, false, false, false
    )

    if not fx then
        return
    end

    SetLoopColour(fx, cfg.color)
    if cfg.alpha then
        SetParticleFxLoopedAlpha(fx, cfg.alpha)
    end

    trailTable[#trailTable + 1] = fx

    SetTimeout(cfg.lifetime or 2200, function()
        StopParticleFxLooped(fx, 0)
        RemoveParticleFx(fx, false)

        for i = #trailTable, 1, -1 do
            if trailTable[i] == fx then
                table.remove(trailTable, i)
                break
            end
        end
    end)
end

local function CleanupTrailTable(trailTable)
    for i = #trailTable, 1, -1 do
        StopParticleFxLooped(trailTable[i], 0)
        RemoveParticleFx(trailTable[i], false)
        trailTable[i] = nil
    end
end

local function EnsureMotionTrailAsset(container)
    if not container then
        return false
    end

    if container.motionTrailLoaded then
        return true
    end

    local cfg = Config.Effects.motionTrail
    if not cfg then
        return false
    end

    container.motionTrailLoaded = EnsureAsset(cfg.asset)
    return container.motionTrailLoaded
end

local function ResolveCollision(ped, fromCoords, targetCoords)
    local probeCfg = Config.Transplanner.collisionProbe
    if not probeCfg or not ped or not fromCoords or not targetCoords then
        return targetCoords
    end

    if #(targetCoords - fromCoords) <= 0.01 then
        return targetCoords
    end

    local handle = StartShapeTestCapsule(
        fromCoords.x, fromCoords.y, fromCoords.z + (probeCfg.verticalOffset or 0.2),
        targetCoords.x, targetCoords.y, targetCoords.z + (probeCfg.verticalOffset or 0.2),
        probeCfg.radius or 0.35,
        12,
        ped,
        7
    )

    local result = 1
    local hit, hitCoords, surfaceNormal

    while result == 1 do
        result, hit, hitCoords, surfaceNormal = GetShapeTestResult(handle)
    end

    if hit == 1 and hitCoords and surfaceNormal then
        local pushback = probeCfg.pushback or 0.25
        targetCoords = vector3(
            hitCoords.x - surfaceNormal.x * pushback,
            hitCoords.y - surfaceNormal.y * pushback,
            hitCoords.z - surfaceNormal.z * pushback
        )
    end

    if probeCfg.minClearance then
        local found, groundZ = GetGroundZFor_3dCoord(targetCoords.x, targetCoords.y, targetCoords.z, false)
        if found and targetCoords.z < groundZ + probeCfg.minClearance then
            targetCoords = vector3(targetCoords.x, targetCoords.y, groundZ + probeCfg.minClearance)
        end
    end

    if Config.Transplanner.maxHeight and targetCoords.z > Config.Transplanner.maxHeight then
        targetCoords = vector3(targetCoords.x, targetCoords.y, Config.Transplanner.maxHeight)
    end

    return targetCoords
end

-- Version avec couleur personnalisée pour les joueurs distants
local function EmitMotionTrailWithColor(container, fromCoords, toCoords, trailColor)
    local cfg = Config.Effects.motionTrail
    if not cfg or not fromCoords or not toCoords then
        return
    end

    local distance = #(toCoords - fromCoords)
    local spacing = cfg.spacing or 0.5
    if distance <= 0.0 then
        return
    end

    if not EnsureMotionTrailAsset(container) then
        return
    end

    local computed = math.floor(distance / spacing)
    local steps = math.max(1, math.min(cfg.maxSegments or 5, computed))

    local dir = toCoords - fromCoords
    local horizontalLen = math.sqrt(dir.x * dir.x + dir.y * dir.y)
    local yaw = math.deg(math.atan(dir.y, dir.x))
    local pitch = horizontalLen > 0.0 and -math.deg(math.atan(dir.z, horizontalLen)) or (dir.z >= 0.0 and -90.0 or 90.0)
    local roll = yaw + 90.0

    local stepVector = vector3(dir.x / steps, dir.y / steps, dir.z / steps)
    local randomness = cfg.randomness or 0.0
    local offsetZ = cfg.offset or 0.0

    -- Utiliser la couleur fournie ou la couleur par défaut
    local color = trailColor or cfg.color or { r = 255, g = 255, b = 255 }

    for i = 0, steps do
        local pos = vector3(
            fromCoords.x + stepVector.x * i,
            fromCoords.y + stepVector.y * i,
            fromCoords.z + stepVector.z * i
        )

        if randomness > 0.0 then
            pos = vector3(
                pos.x + (math.random() - 0.5) * randomness,
                pos.y + (math.random() - 0.5) * randomness,
                pos.z + (math.random() - 0.5) * randomness * 0.5
            )
        end

        if EnsureAsset(cfg.asset) then
            UseParticleFxAsset(cfg.asset)
            local fx = StartParticleFxLoopedAtCoord(
                cfg.effect,
                pos.x, pos.y, pos.z + offsetZ,
                pitch or 0.0, roll or 0.0, yaw or 0.0,
                cfg.scale or 1.15,
                false, false, false, false
            )

            if fx then
                container.trails = container.trails or {}
                container.trails[#container.trails + 1] = fx

                SetLoopColour(fx, color)
                if cfg.alpha then
                    SetParticleFxLoopedAlpha(fx, cfg.alpha)
                end

                SetTimeout(cfg.lifetime or 800, function()
                    StopParticleFxLooped(fx, 0)
                    RemoveParticleFx(fx, false)

                    if container.trails then
                        for ti = #container.trails, 1, -1 do
                            if container.trails[ti] == fx then
                                table.remove(container.trails, ti)
                                break
                            end
                        end
                    end
                end)
            end
        end
    end
end

local function EmitMotionTrail(container, fromCoords, toCoords)
    local cfg = Config.Effects.motionTrail
    if not cfg or not fromCoords or not toCoords then
        return
    end

    local distance = #(toCoords - fromCoords)
    local spacing = cfg.spacing or 0.5
    -- If zero distance, nothing to do
    if distance <= 0.0 then
        return
    end

    -- Ensure asset is loaded (try to preload once)
    if not EnsureMotionTrailAsset(container) then
        return
    end

    -- Compute number of steps; ensure at least 1 so we always emit something
    local computed = math.floor(distance / spacing)
    local steps = math.max(1, math.min(cfg.maxSegments or 5, computed))

    local dir = toCoords - fromCoords
    local horizontalLen = math.sqrt(dir.x * dir.x + dir.y * dir.y)
    -- Rotation pour suivre la direction du mouvement (particles emit sideways/backwards relative to movement)
    local yaw = math.deg(math.atan(dir.y, dir.x))
    local pitch = horizontalLen > 0.0 and -math.deg(math.atan(dir.z, horizontalLen)) or (dir.z >= 0.0 and -90.0 or 90.0)
    local roll = yaw + 90.0

    local stepVector = vector3(dir.x / steps, dir.y / steps, dir.z / steps)
    local randomness = cfg.randomness or 0.0
    local offsetZ = cfg.offset or 0.0

    for i = 0, steps do
        local pos = vector3(
            fromCoords.x + stepVector.x * i,
            fromCoords.y + stepVector.y * i,
            fromCoords.z + stepVector.z * i
        )

        if randomness > 0.0 then
            pos = vector3(
                pos.x + (math.random() - 0.5) * randomness,
                pos.y + (math.random() - 0.5) * randomness,
                pos.z + (math.random() - 0.5) * randomness * 0.5
            )
        end
        -- Use looped particle at each segment and manage its lifetime so the trail stays visible.
        if EnsureAsset(cfg.asset) then
            UseParticleFxAsset(cfg.asset)
            local fx = StartParticleFxLoopedAtCoord(
                cfg.effect,
                pos.x, pos.y, pos.z + offsetZ,
                pitch or 0.0, roll or 0.0, yaw or 0.0,
                cfg.scale or 1.15,
                false, false, false, false
            )

            if fx then
                -- store handle so CleanupTrailTable can remove it later
                container.trails = container.trails or {}
                container.trails[#container.trails + 1] = fx

                -- Utiliser la couleur du container si disponible, sinon la couleur de la config
                SetLoopColour(fx, container.color or cfg.color)
                if cfg.alpha then
                    SetParticleFxLoopedAlpha(fx, cfg.alpha)
                end

                SetTimeout(cfg.lifetime or 800, function()
                    StopParticleFxLooped(fx, 0)
                    RemoveParticleFx(fx, false)

                    -- remove from container.trails
                    if container.trails then
                        for ti = #container.trails, 1, -1 do
                            if container.trails[ti] == fx then
                                table.remove(container.trails, ti)
                                break
                            end
                        end
                    end
                end)
            end
        end
    end
end

-- Créer un prop invisible local pour représenter un joueur distant
local function CreateGhostEntity(coords)
    local model = GetHashKey('prop_mp_placement_med')
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    if not HasModelLoaded(model) then
        return nil
    end

    local ghost = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    if ghost and ghost ~= 0 then
        SetEntityVisible(ghost, false, false)
        SetEntityCollision(ghost, false, false)
        SetEntityAlpha(ghost, 0, false)
        -- Ne pas freeze pour pouvoir déplacer l'entité
    end
    SetModelAsNoLongerNeeded(model)
    return ghost
end

local function InitializeRemoteState(state)
    if state.initialized then
        return
    end

    local player = GetPlayerFromServerId(state.serverId)
    if player == -1 then
        return
    end

    local ped = GetPlayerPed(player)
    if not DoesEntityExist(ped) then
        return
    end

    -- Preload critical assets without blocking
    local smokeCfg = Config.Effects.blackSmoke
    if smokeCfg and smokeCfg.asset and not HasNamedPtfxAssetLoaded(smokeCfg.asset) then
        RequestNamedPtfxAsset(smokeCfg.asset)
        return
    end

    local auraCfg = Config.Effects.aura
    if auraCfg and auraCfg.asset and not HasNamedPtfxAssetLoaded(auraCfg.asset) then
        RequestNamedPtfxAsset(auraCfg.asset)
        return
    end

    state.ped = ped
    state.initialized = true
    state.pulseStart = GetGameTimer()
    state.nextTrailAt = 0
    state.lastCoords = GetEntityCoords(ped)
    state.motionTrailLoaded = false

    -- Variables pour l'interpolation de position
    state.targetCoords = nil
    state.interpolationStart = nil
    state.interpolationDuration = 50 -- Durée d'interpolation en ms (correspond au syncTickRate)
    state.hasSync = false
    state.syncedCoords = nil
    state.prevSyncedCoords = nil
    state.lastInterpolatedCoords = nil

    -- Créer un ghost entity local pour les effets visuels synchronisés
    state.ghostEntity = CreateGhostEntity(state.lastCoords)

    if not state.endTime then
        local durationMs = tonumber(state.durationMs) or Config.Transplanner.duration
        state.endTime = GetGameTimer() + durationMs
    end

    -- Try to preload motion trail asset for this remote state so trails don't flicker
    pcall(function()
        EnsureMotionTrailAsset(state)
    end)

    -- Pour les joueurs distants, on ne crée AUCUN effet local
    -- Seule la traînée synchronisée via syncPositionClient est utilisée
    -- Cela évite la "boule de fumée" disgracieuse
end

-- Fonction pour mettre à jour la position cible d'un joueur distant
local function UpdateRemotePosition(serverId, coords)
    local state = remoteStates[serverId]
    if not state then
        return
    end

    if not coords or type(coords.x) ~= 'number' then
        return
    end

    -- Sauvegarder la position précédente pour l'interpolation
    local prevCoords = state.syncedCoords or state.lastCoords
    if prevCoords then
        state.prevSyncedCoords = vector3(prevCoords.x, prevCoords.y, prevCoords.z)
    end

    -- Définir la nouvelle position synchronisée
    state.syncedCoords = vector3(coords.x, coords.y, coords.z)
    state.interpolationStart = GetGameTimer()
    state.hasSync = true
end

-- Fonction pour obtenir la position interpolée d'un joueur distant
local function GetInterpolatedRemoteCoords(state)
    if not state then
        return nil
    end

    -- Si pas de synchronisation, utiliser la position du ped
    if not state.hasSync or not state.syncedCoords then
        if state.ped and DoesEntityExist(state.ped) then
            return GetEntityCoords(state.ped)
        end
        return state.lastCoords
    end

    local now = GetGameTimer()
    local elapsed = now - (state.interpolationStart or now)
    local duration = state.interpolationDuration or 50
    local t = math.min(elapsed / duration, 1.0)

    -- Si pas de position précédente, retourner directement la position synchronisée
    if not state.prevSyncedCoords then
        return state.syncedCoords
    end

    -- Interpolation linéaire entre la position précédente et la position cible
    local startCoords = state.prevSyncedCoords
    local targetCoords = state.syncedCoords

    local newX = startCoords.x + (targetCoords.x - startCoords.x) * t
    local newY = startCoords.y + (targetCoords.y - startCoords.y) * t
    local newZ = startCoords.z + (targetCoords.z - startCoords.z) * t

    return vector3(newX, newY, newZ)
end

-- Fonction pour mettre à jour les effets visuels à la position interpolée
local function UpdateRemoteEffects(state)
    if not state or not state.initialized then
        return
    end

    local coords = GetInterpolatedRemoteCoords(state)
    if not coords then
        return
    end

    -- Déplacer le ghost entity aux coordonnées interpolées
    -- Les effets attachés (smoke, aura) suivront automatiquement
    if state.ghostEntity and DoesEntityExist(state.ghostEntity) then
        SetEntityCoordsNoOffset(state.ghostEntity, coords.x, coords.y, coords.z, false, false, false)
    end

    -- Note: La traînée de mouvement est maintenant gérée par l'event syncPositionClient
    -- qui reçoit les vraies coordonnées from/to du joueur source

    state.lastInterpolatedCoords = coords
    return coords
end

local function StopRemoteTransplan(serverId, coords)
    local state = remoteStates[serverId]
    if not state then
        return
    end

    if state.smoke then
        StopSmokeFx(state.smoke)
        state.smoke = nil
    end

    -- Nettoyer la fumée aux coordonnées
    if state.smokeCoord then
        StopParticleFxLooped(state.smokeCoord, 0)
        RemoveParticleFx(state.smokeCoord, false)
        state.smokeCoord = nil
        state.smokeCoordPos = nil
    end

    CleanupJobTrail(state.jobTrail)

    if state.aura then
        StopAura(state.aura)
        state.aura = nil
    end

    CleanupTrailTable(state.trails or {})

    -- Supprimer le ghost entity
    if state.ghostEntity and DoesEntityExist(state.ghostEntity) then
        DeleteEntity(state.ghostEntity)
        state.ghostEntity = nil
    end

    local endCoords = coords
    if type(endCoords) ~= 'table' or type(endCoords.x) ~= 'number' or type(endCoords.y) ~= 'number' or type(endCoords.z) ~= 'number' then
        endCoords = state.syncedCoords or state.lastInterpolatedCoords or state.lastCoords
    end
    if (type(endCoords) ~= 'table' or type(endCoords.x) ~= 'number') and state.ped and DoesEntityExist(state.ped) then
        local p = GetEntityCoords(state.ped)
        endCoords = { x = p.x, y = p.y, z = p.z }
    end

    if endCoords and type(endCoords.x) == 'number' and type(endCoords.y) == 'number' and type(endCoords.z) == 'number' then
        StartTimedLoopAtCoord(Config.Effects.teleportEnd, endCoords)
        PlayNonLoopedEffect(Config.Effects.release, endCoords)
        PlayNonLoopedEffect(Config.Effects.shadowBurst, endCoords)
    end

    remoteStates[serverId] = nil
end

local function StartRemoteTransplan(serverId, duration, color)
    local now <const> = GetGameTimer()
    if remoteStates[serverId] then
        StopRemoteTransplan(serverId)
    end

    local trailColor = NormalizeTrailColor(color or 'noir')
    local durationMs = tonumber(duration) or Config.Transplanner.duration

    remoteStates[serverId] = {
        serverId = serverId,
        startTime = now,
        durationMs = durationMs,
        endTime = nil,
        expiresAt = now + durationMs + 12000,
        trails = {},
        smoke = nil,
        aura = nil,
        initialized = false,
        pulseStart = now,
        nextTrailAt = 0,
        lastCoords = nil,
        trailCfg = Config.Effects.trail,
        pulseCfg = Config.Effects.pulseLight,
        motionTrailLoaded = false,
        trailColor = trailColor, -- Couleur de la traînée pour la synchronisation
        jobTrail = {
            color = trailColor,
            attached = nil
        }
    }

    InitializeRemoteState(remoteStates[serverId])
end

local function StopTransplanning(sync)
    if not isTransplanning then return end
    isTransplanning = false
    SetTransvalisState(false)
    local playerPed = cache.ped

    if localFX.smoke then
        StopSmokeFx(localFX.smoke)
        localFX.smoke = nil
    end

    if localFX.aura then
        StopAura(localFX.aura)
        localFX.aura = nil
    end

    -- Nettoyer la fumée aux coordonnées (quand immobile)
    if localFX.smokeCoord then
        StopParticleFxLooped(localFX.smokeCoord, 0)
        RemoveParticleFx(localFX.smokeCoord, false)
        localFX.smokeCoord = nil
    end

    CleanupJobTrail(localFX.jobTrail)
    localFX.jobTrail = nil

    CleanupTrailTable(localFX.trails)
    localFX.trails = {}
    localFX.nextTrailAt = 0
    localFX.lastCoords = nil
    localFX.motionTrailLoaded = false

    if transplanCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(transplanCam, false)
        transplanCam = nil
    end

    TransitionFromBlurred(0)
    SetPedMotionBlur(playerPed, false)
    
    SetEntityVisible(playerPed, true, false)
    SetEntityAlpha(playerPed, 255, false)
    ResetEntityAlpha(playerPed)
    
    local currentCoords = GetEntityCoords(playerPed)
    
    SetEntityCollision(playerPed, true, true)
    FreezeEntityPosition(playerPed, false)
    SetEntityInvincible(playerPed, false)
    SetEntityHasGravity(playerPed, true)
    SetPedCanRagdoll(playerPed, true)
    SetEntityVelocity(playerPed, 0.0, 0.0, 0.0)
    
    local groundZ = currentCoords.z
    local foundGround, groundZCoord = GetGroundZFor_3dCoord(currentCoords.x, currentCoords.y, currentCoords.z + 100.0, false)
    
    if foundGround then
        groundZ = groundZCoord
    end
    
    if currentCoords.z > groundZ + 2.0 then
        SetEntityCoords(playerPed, currentCoords.x, currentCoords.y, groundZ + 1.0, false, false, false, false)
    end
    
    local finalCoords = GetEntityCoords(playerPed)
    StartTimedLoopAtCoord(Config.Effects.teleportEnd, finalCoords)
    PlayNonLoopedEffect(Config.Effects.release, finalCoords)
    PlayNonLoopedEffect(Config.Effects.shadowBurst, finalCoords)

    if sync ~= false then
        TriggerServerEvent('th_transvalis:syncStop')
    end
end

local function StartTransplanning(duration, trailColor)
    if isTransplanning then
        StopTransplanning()
        return
    end
    
    isTransplanning = true
    transplanStartTime = GetGameTimer()
    localDuration = duration or Config.Transplanner.duration
    localFX.trails = {}
    localFX.lastCoords = nil
    localFX.motionTrailLoaded = false
    local playerPed = cache.ped
    local originalCoords = GetEntityCoords(playerPed)

    SetTransvalisState(true)
    
    StartTimedLoopAtCoord(Config.Effects.teleportStart, originalCoords)
    PlayNonLoopedEffect(Config.Effects.shadowBurst, originalCoords)
    
    SetEntityVisible(playerPed, false, false)
    SetEntityAlpha(playerPed, 0, false)

    SetEntityCollision(playerPed, false, false)
    FreezeEntityPosition(playerPed, false)
    SetEntityInvincible(playerPed, true)
    SetPedCanRagdoll(playerPed, false)
    SetEntityHasGravity(playerPed, false)
    SetPedMotionBlur(playerPed, false)
    localFX.lastCoords = originalCoords
    
    localFX.color = NormalizeTrailColor(trailColor or 'default')
    localFX.jobTrail = {
        color = localFX.color,
        attached = nil
    }

    -- Désactivé pour éviter la synchronisation réseau de la fumée
    -- localFX.smoke = StartSmokeFx(playerPed, localFX)
    -- localFX.aura = StartAura(playerPed, localFX)
    localFX.pulseStart = GetGameTimer()
    localFX.nextTrailAt = 0

    if not transvalisReturnPosition then
        SaveReturnPosition()
    end
    pcall(function()
        EnsureMotionTrailAsset(localFX)
    end)

    local camCoords = GetEntityCoords(playerPed)
    local camRot = GetGameplayCamRot(2)
    
    transplanCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    
    local camDistance = 8.0
    local camHeightOffset = 2.0
    local radZ = math.rad(camRot.z)
    local radX = math.rad(camRot.x)
    
    local backwardX = math.sin(radZ) * math.abs(math.cos(radX))
    local backwardY = -math.cos(radZ) * math.abs(math.cos(radX))
    local backwardZ = -math.sin(radX)
    
    local camX = camCoords.x + backwardX * camDistance
    local camY = camCoords.y + backwardY * camDistance
    local camZ = camCoords.z + backwardZ * camDistance + camHeightOffset
    
    SetCamCoord(transplanCam, camX, camY, camZ)
    SetCamRot(transplanCam, camRot.x, camRot.y, camRot.z, 2)
    SetCamActive(transplanCam, true)
    RenderScriptCams(true, false, 0, true, true)
end

CreateThread(function()
    while true do
        local sleep = 100
        
        if isTransplanning then
            sleep = 0
            local playerPed = cache.ped
            local currentTime = GetGameTimer()
            local elapsed = currentTime - transplanStartTime
            local remaining = localDuration - elapsed
            
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 68, true)
            DisableControlAction(0, 70, true)
            DisableControlAction(0, 91, true)
            DisableControlAction(0, 92, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)

            if remaining <= 0 then
                StopTransplanning()
            else
                -- Maintenir gravité et ragdoll désactivés chaque frame (comme Vol)
                SetPedCanRagdoll(playerPed, false)
                SetEntityHasGravity(playerPed, false)

                local baseSpeed = (Config.Transplanner.noclipSpeed and Config.Transplanner.noclipSpeed.normal) or Config.Transplanner.speed
                local speed = baseSpeed
                if IsControlPressed(0, Config.Controls.speedUp) then
                    speed = Config.Transplanner.noclipSpeed.fast
                elseif IsControlPressed(0, Config.Controls.slowDown) then
                    speed = Config.Transplanner.noclipSpeed.slow
                end

                local coords = GetEntityCoords(playerPed)
                local previousCoords = localFX.lastCoords or coords
                local camRot = GetGameplayCamRot(2)

                if transplanCam then
                    local camDistance = 8.0
                    local camHeightOffset = 2.0

                    local radZ = math.rad(camRot.z)
                    local radX = math.rad(camRot.x)

                    local backwardX = math.sin(radZ) * math.abs(math.cos(radX))
                    local backwardY = -math.cos(radZ) * math.abs(math.cos(radX))
                    local backwardZ = -math.sin(radX)

                    local camX = coords.x + backwardX * camDistance
                    local camY = coords.y + backwardY * camDistance
                    local camZ = coords.z + backwardZ * camDistance + camHeightOffset

                    SetCamCoord(transplanCam, camX, camY, camZ)
                    SetCamRot(transplanCam, camRot.x, camRot.y, camRot.z, 2)
                end

                local radZ = math.rad(camRot.z)
                local radX = math.rad(camRot.x)

                local forwardX = -math.sin(radZ) * math.abs(math.cos(radX))
                local forwardY = math.cos(radZ) * math.abs(math.cos(radX))
                local forwardZ = math.sin(radX)

                -- Construire le vecteur de direction (comme Vol)
                local moveDir = vector3(0.0, 0.0, 0.0)
                local isMoving = false

                if IsControlPressed(0, Config.Controls.forward) then
                    moveDir = moveDir + vector3(forwardX, forwardY, forwardZ)
                    isMoving = true
                end
                if IsControlPressed(0, Config.Controls.backward) then
                    moveDir = moveDir - vector3(forwardX, forwardY, forwardZ)
                    isMoving = true
                end

                local rightX = math.cos(radZ)
                local rightY = math.sin(radZ)

                if IsControlPressed(0, Config.Controls.left) then
                    moveDir = moveDir - vector3(rightX, rightY, 0.0)
                    isMoving = true
                end
                if IsControlPressed(0, Config.Controls.right) then
                    moveDir = moveDir + vector3(rightX, rightY, 0.0)
                    isMoving = true
                end

                if IsControlPressed(0, Config.Controls.up) then
                    moveDir = moveDir + vector3(0.0, 0.0, 1.0)
                    isMoving = true
                end
                if IsControlPressed(0, Config.Controls.down) then
                    moveDir = moveDir - vector3(0.0, 0.0, 1.0)
                    isMoving = true
                end

                if IsControlJustPressed(0, Config.Controls.cancel) then
                    StopTransplanning()
                end

                -- jobTrail désactivé, EmitMotionTrail gère la traînée avec la bonne couleur

                if isMoving then
                    -- EN MOUVEMENT: supprimer la fumée locale si elle existe
                    if localFX.smokeCoord then
                        StopParticleFxLooped(localFX.smokeCoord, 0)
                        RemoveParticleFx(localFX.smokeCoord, false)
                        localFX.smokeCoord = nil
                    end

                    -- Normaliser la direction et appliquer la vélocité (comme Vol)
                    local len = #moveDir
                    if len > 0.1 then
                        moveDir = moveDir / len
                    end

                    local velSpeed = speed * 60.0

                    -- Vérifier la collision avant d'appliquer la vélocité
                    local targetCoords = coords + moveDir * speed
                    if Config.Transplanner.maxHeight and targetCoords.z > Config.Transplanner.maxHeight then
                        targetCoords = vector3(targetCoords.x, targetCoords.y, Config.Transplanner.maxHeight)
                    end
                    targetCoords = ResolveCollision(playerPed, coords, targetCoords)

                    -- Recalculer la direction après collision
                    local resolvedDir = targetCoords - coords
                    local resolvedLen = #resolvedDir
                    if resolvedLen > 0.001 then
                        resolvedDir = resolvedDir / resolvedLen
                        SetEntityVelocity(playerPed, resolvedDir.x * velSpeed, resolvedDir.y * velSpeed, resolvedDir.z * velSpeed)
                    else
                        SetEntityVelocity(playerPed, 0.0, 0.0, 0.0)
                    end

                    if Config.Effects.motionTrail and previousCoords then
                        EmitMotionTrail(localFX, previousCoords, targetCoords)
                    end

                    localFX.lastCoords = targetCoords

                    -- Synchroniser la position ET la traînée avec les autres joueurs (EN MOUVEMENT)
                    if currentTime - lastSyncTime >= syncTickRate then
                        lastSyncTime = currentTime
                        local myServerId = GetPlayerServerId(PlayerId())
                        TriggerServerEvent('th_transvalis:syncPosition', myServerId, {
                            x = targetCoords.x,
                            y = targetCoords.y,
                            z = targetCoords.z
                        }, {
                            x = previousCoords.x,
                            y = previousCoords.y,
                            z = previousCoords.z
                        }, localFX.color, true) -- true = en mouvement
                    end
                else
                    SetEntityVelocity(playerPed, 0.0, 0.0, 0.0)
                    localFX.lastCoords = coords

                    -- IMMOBILE: afficher la fumée locale
                    if not localFX.smokeCoord then
                        local smokeCfg = Config.Effects.motionTrail
                        if smokeCfg and EnsureAsset(smokeCfg.asset) then
                            UseParticleFxAsset(smokeCfg.asset)
                            local fx = StartParticleFxLoopedAtCoord(
                                smokeCfg.effect,
                                coords.x, coords.y, coords.z,
                                0.0, 0.0, 0.0,
                                smokeCfg.scale or 0.5,
                                false, false, false, false
                            )
                            if fx then
                                SetLoopColour(fx, localFX.color or smokeCfg.color)
                                if smokeCfg.alpha then
                                    SetParticleFxLoopedAlpha(fx, smokeCfg.alpha)
                                end
                                localFX.smokeCoord = fx
                            end
                        end
                    end

                    -- Synchroniser même quand immobile pour que les autres voient la bonne position (IMMOBILE)
                    if currentTime - lastSyncTime >= syncTickRate then
                        lastSyncTime = currentTime
                        local myServerId = GetPlayerServerId(PlayerId())
                        TriggerServerEvent('th_transvalis:syncPosition', myServerId, {
                            x = coords.x,
                            y = coords.y,
                            z = coords.z
                        }, nil, localFX.color, false) -- false = immobile
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local hasLocal = isTransplanning
        local hasRemote = next(remoteStates) ~= nil

        if not hasLocal and not hasRemote then
            Wait(400)
        else
            local now <const> = GetGameTimer()

            if hasLocal then
                -- SpawnTrailFx et jobTrail désactivés, EmitMotionTrail gère tout avec la bonne couleur

                if Config.Effects.pulseLight then
                    local coords = GetEntityCoords(cache.ped)
                    PulseLight(vector3(coords.x, coords.y, coords.z + 0.7), Config.Effects.pulseLight, localFX.pulseStart)
                end
            end

            for serverId, state in pairs(remoteStates) do
                if not state.initialized then
                    if state.expiresAt and now >= state.expiresAt then
                        remoteStates[serverId] = nil
                    else
                        InitializeRemoteState(state)
                    end
                end

                if state and state.endTime and now >= state.endTime then
                    StopRemoteTransplan(serverId)
                elseif state then
                    -- Obtenir les coordonnées interpolées (synchronisées ou du ped)
                    local coords = UpdateRemoteEffects(state)

                    if coords then
                        -- Mettre à jour lastCoords pour le prochain cycle
                        state.lastCoords = coords
                    elseif state.ped and DoesEntityExist(state.ped) then
                        -- Fallback: utiliser la position du ped si pas de coordonnées synchronisées
                        coords = GetEntityCoords(state.ped)

                        -- Aussi mettre à jour le ghost entity en fallback
                        if state.ghostEntity and DoesEntityExist(state.ghostEntity) then
                            SetEntityCoordsNoOffset(state.ghostEntity, coords.x, coords.y, coords.z, false, false, false)
                        end

                        state.lastCoords = coords
                    end
                    -- Note: Tous les autres effets (jobTrail, trail, pulseLight) sont désactivés
                    -- pour les joueurs distants. Seule la traînée synchronisée via syncPositionClient est utilisée.
                end
            end

            Wait(1)
        end
    end
end)

RegisterNetEvent('th_transvalis:start', function(sourceId, duration, trailColor)
    if not sourceId then
        return
    end

    local me <const> = GetPlayerServerId(PlayerId())

    if sourceId ~= me then
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

        if hasShield then
            return
        end
    end

    if sourceId == me then
        StartTransplanning(duration, trailColor)
    else
        StartRemoteTransplan(sourceId, duration, trailColor or 'noir')
    end
end)

RegisterNetEvent('th_transvalis:stop', function(sourceId, coords)
    if not sourceId then
        return
    end

    local me <const> = GetPlayerServerId(PlayerId())
    if sourceId == me then
        StopTransplanning(false)
    else
        StopRemoteTransplan(sourceId, coords)
    end
end)

RegisterNetEvent('th_transvalis:arrivalEffects', function(sourceId, coords)
    if not sourceId or not coords then
        return
    end

    if type(coords.x) == "number" and type(coords.y) == "number" and type(coords.z) == "number" then
        StartTimedLoopAtCoord(Config.Effects.teleportEnd, coords)
        PlayNonLoopedEffect(Config.Effects.release, coords)
        PlayNonLoopedEffect(Config.Effects.shadowBurst, coords)
    end
end)

-- Event pour recevoir la synchronisation de position des autres joueurs
RegisterNetEvent('th_transvalis:syncPositionClient', function(sourceId, coords, fromCoords, trailColor, isMoving)
    if not sourceId or not coords then
        return
    end

    local me = GetPlayerServerId(PlayerId())
    if sourceId == me then
        return
    end

    -- Mettre à jour la position cible pour l'interpolation
    UpdateRemotePosition(sourceId, coords)

    -- Gérer les effets visuels selon si le joueur est en mouvement ou non
    local state = remoteStates[sourceId]
    if not state then
        return
    end

    -- Forcer l'initialisation si pas encore fait
    if not state.initialized then
        InitializeRemoteState(state)
    end

    -- Vérifier à nouveau après tentative d'initialisation
    if not state.initialized then
        return
    end

    -- Mettre à jour la couleur de la traînée si fournie
    if trailColor then
        state.trailColor = trailColor
    end

    if isMoving then
        -- EN MOUVEMENT: afficher la traînée, cacher la fumée
        if state.smoke then
            StopSmokeFx(state.smoke)
            state.smoke = nil
        end
        if state.aura then
            StopAura(state.aura)
            state.aura = nil
        end
        -- Supprimer la fumée aux coordonnées si elle existe
        if state.smokeCoord then
            StopParticleFxLooped(state.smokeCoord, 0)
            RemoveParticleFx(state.smokeCoord, false)
            state.smokeCoord = nil
            state.smokeCoordPos = nil
        end

        -- Créer la traînée de mouvement
        if fromCoords and Config.Effects.motionTrail then
            local from = vector3(fromCoords.x, fromCoords.y, fromCoords.z)
            local to = vector3(coords.x, coords.y, coords.z)
            local dist = #(to - from)

            if dist > 0.1 then
                EmitMotionTrailWithColor(state, from, to, state.trailColor)
            end
        end
    else
        -- IMMOBILE: afficher la fumée aux coordonnées (pas attachée à une entité)
        local coordsVec = vector3(coords.x, coords.y, coords.z)

        -- Utiliser la même config que motionTrail pour la fumée immobile (scale visible)
        local smokeCfg = Config.Effects.motionTrail

        -- Créer ou mettre à jour la fumée aux coordonnées
        if not state.smokeCoord then
            -- Créer la fumée aux coordonnées
            if smokeCfg and EnsureAsset(smokeCfg.asset) then
                UseParticleFxAsset(smokeCfg.asset)
                local fx = StartParticleFxLoopedAtCoord(
                    smokeCfg.effect,
                    coords.x, coords.y, coords.z,
                    0.0, 0.0, 0.0,
                    smokeCfg.scale or 0.5,
                    false, false, false, false
                )
                if fx then
                    -- Utiliser la couleur de traînée du joueur
                    SetLoopColour(fx, state.trailColor or smokeCfg.color)
                    if smokeCfg.alpha then
                        SetParticleFxLoopedAlpha(fx, smokeCfg.alpha)
                    end
                    state.smokeCoord = fx
                    state.smokeCoordPos = coordsVec
                end
            end
        else
            -- Si la position a changé significativement, recréer la fumée
            if state.smokeCoordPos then
                local dist = #(coordsVec - state.smokeCoordPos)
                if dist > 0.5 then
                    -- Supprimer l'ancienne fumée
                    StopParticleFxLooped(state.smokeCoord, 0)
                    RemoveParticleFx(state.smokeCoord, false)
                    state.smokeCoord = nil
                    state.smokeCoordPos = nil

                    -- Recréer la fumée à la nouvelle position
                    if smokeCfg and EnsureAsset(smokeCfg.asset) then
                        UseParticleFxAsset(smokeCfg.asset)
                        local fx = StartParticleFxLoopedAtCoord(
                            smokeCfg.effect,
                            coords.x, coords.y, coords.z,
                            0.0, 0.0, 0.0,
                            smokeCfg.scale or 0.5,
                            false, false, false, false
                        )
                        if fx then
                            SetLoopColour(fx, state.trailColor or smokeCfg.color)
                            if smokeCfg.alpha then
                                SetParticleFxLoopedAlpha(fx, smokeCfg.alpha)
                            end
                            state.smokeCoord = fx
                            state.smokeCoordPos = coordsVec
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('th_transvalis:cancelRequested', function()
    if isTransplanning then
        StopTransplanning()
    end
end)

RegisterNetEvent('th_transvalis:clientTeleport', function(coords)
    if not coords or type(coords) ~= "table" then
        return
    end

    if type(coords.x) ~= "number" or type(coords.y) ~= "number" or type(coords.z) ~= "number" then
        return
    end

    local playerPed = cache.ped
    if not playerPed or not DoesEntityExist(playerPed) then
        return
    end

    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local entityToTeleport = playerPed

    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        entityToTeleport = vehicle
    end

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetEntityCoords(entityToTeleport, coords.x, coords.y, coords.z, false, false, false, true)

    if entityToTeleport == playerPed and coords.h then
        SetEntityHeading(playerPed, coords.h)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if isTransplanning then
        StopTransplanning(false)
    end

    -- Nettoyer tous les états distants et leurs ghost entities
    for serverId, state in pairs(remoteStates) do
        if state.ghostEntity and DoesEntityExist(state.ghostEntity) then
            DeleteEntity(state.ghostEntity)
        end
        StopRemoteTransplan(serverId)
    end

    SetTransvalisState(false)
    TransitionFromBlurred(0)
end)

RegisterNetEvent('th_transvalis:saveReturnPosition')
AddEventHandler('th_transvalis:saveReturnPosition', SaveReturnPosition)

RegisterNetEvent('th_transvalis:bringNearbyPlayers')
AddEventHandler('th_transvalis:bringNearbyPlayers', BringNearbyPlayers)

RegisterNetEvent('th_transvalis:returnTeleportedPlayers')
AddEventHandler('th_transvalis:returnTeleportedPlayers', ReturnTeleportedPlayers)

RegisterCommand('transvalis_return', function()
    ReturnTeleportedPlayers()
end, false)

local function SetTeleportedPlayers(players)
    if type(players) == 'table' then
        teleportedPlayers = players
    end
end

exports('ReturnTeleportedPlayers', ReturnTeleportedPlayers)
exports('StartTransplanning', StartTransplanning)
exports('StopTransplanning', StopTransplanning)
exports('SaveReturnPosition', SaveReturnPosition)
exports('SetTeleportedPlayers', SetTeleportedPlayers)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    SetTransvalisState(false)
    if isTransplanning then
        StopTransplanning()
    end

    -- Nettoyer les ghost entities restants
    for serverId, state in pairs(remoteStates) do
        if state and state.ghostEntity and DoesEntityExist(state.ghostEntity) then
            DeleteEntity(state.ghostEntity)
        end
    end
end)
