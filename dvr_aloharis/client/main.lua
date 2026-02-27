---@diagnostic disable: undefined-global, trailing-space, param-type-mismatch
local Config <const> = Config
local DrawLightWithRange = DrawLightWithRange
local DrawMarker = DrawMarker
local DrawLine = DrawLine
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StopParticleFxLooped = StopParticleFxLooped
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local DoesEntityExist = DoesEntityExist
local SetEntityDrawOutlineColor = SetEntityDrawOutlineColor
local SetEntityDrawOutline = SetEntityDrawOutline
local GetEntityCoords = GetEntityCoords
local GetCurrentPedWeaponEntityIndex = GetCurrentPedWeaponEntityIndex
local GetGameTimer = GetGameTimer
local PlaySoundFromCoord = PlaySoundFromCoord
local PlaySoundFrontend = PlaySoundFrontend
local ShakeGameplayCam = ShakeGameplayCam
local AnimpostfxPlay = AnimpostfxPlay
local AnimpostfxStop = AnimpostfxStop
local Wait = Wait
local string_lower = string.lower
local madvr_sin = math.sin
local madvr_random = math.random
local madvr_floor = math.floor
local madvr_max = math.max
local vector3 = vector3
local MAX_SPELL_LEVEL <const> = 5

local lastTargetedDoor = nil
local precastFx = nil

local function BuildProfile(spellLevel)
    local level = math.max(tonumber(spellLevel) or 0, 0)
    level = math.floor(level)
    if level > MAX_SPELL_LEVEL then
        level = MAX_SPELL_LEVEL
    end

    local normalized = level / MAX_SPELL_LEVEL
    local fxScale = 0.65 + (normalized * 1.2)
    local fxBrightness = 0.7 + (normalized * 1.3)
    local sparksMult = 0.6 + (normalized * 1.6)

    local stage = math.floor((normalized * 9) + 1)
    if stage < 1 then
        stage = 1
    elseif stage > 10 then
        stage = 10
    end

    local failBase = math.max(0.0, 0.85 - (normalized * 0.95))
    local failStageDrop = math.max(0.0, (10 - stage) * 0.03)
    local failChance = math.min(1.0, failBase + failStageDrop)
    if stage >= 10 then
        failChance = 0.0
    end

    return {
        level = level,
        normalized = normalized,
        fxScale = fxScale,
        fxBrightness = fxBrightness,
        sparksMult = sparksMult,
        failChance = failChance
    }
end

local function buildLookup(list, transform)
    local lookup = {}

    if not list or type(list) ~= 'table' then
        return lookup
    end

    for key, value in pairs(list) do
        if type(key) == 'number' then
            if value ~= nil then
                local entry = transform and transform(value) or value
                lookup[entry] = true
            end
        elseif value then
            local entry = value == true and key or value
            entry = transform and transform(entry) or entry
            lookup[entry] = true
        end
    end

    return lookup
end

local blacklistIdLookup = buildLookup(Config.Blacklist and Config.Blacklist.ids, tostring)
local blacklistNameLookup = buildLookup(Config.Blacklist and Config.Blacklist.names, function(val)
    return string_lower(val)
end)

local function notify(message)
    if message then
        lib.notify(message)
    end
end

local function doorIsBlacklisted(doorData)
    if not doorData then
        return false
    end

    if doorData.id and blacklistIdLookup[tostring(doorData.id)] then
        return true
    end

    if doorData.name and blacklistNameLookup[string_lower(doorData.name)] then
        return true
    end

    return false
end

local function matchesDoorEntity(door, entity)
    if not door or not entity or entity <= 0 then
        return false
    end

    if door.entity and door.entity == entity then
        return true
    end

    local double = door.doors
    if double then
        for i = 1, #double do
            if double[i].entity and double[i].entity == entity then
                return true
            end
        end
    end

    return false
end

local function GetSpeedMultiplier()
    local mult = Config.Spell and Config.Spell.animation and Config.Spell.animation.speedMultiplier or 1.0
    if mult <= 0.0 then
        mult = 1.0
    end
    return mult
end

local function GetAnimationTimings()
    local anim = Config.Spell and Config.Spell.animation or {}
    local speedMult = GetSpeedMultiplier()

    local duration = anim.duration or Config.Spell.castTime or 2000
    local markerDelay = anim.markerDelay or 600
    local cleanupDelay = anim.cleanupDelay or 600

    local scaledDuration = madvr_floor(duration / speedMult)
    local scaledMarker = madvr_floor(markerDelay / speedMult)
    local scaledCleanup = madvr_floor(madvr_max(0, cleanupDelay) / speedMult)

    if scaledDuration < scaledMarker then
        scaledDuration = scaledMarker
    end

    return scaledMarker, scaledCleanup, scaledDuration
end

local function stopPrecastEffect(keepDoorInfo)
    if not precastFx then
        if not keepDoorInfo and lastTargetedDoor then
            lastTargetedDoor = nil
        end
        return
    end

    local info = precastFx
    precastFx = nil
    info.stop = true

    if info.entity and DoesEntityExist(info.entity) then
        SetEntityDrawOutline(info.entity, false)
    end

    if not keepDoorInfo and lastTargetedDoor and lastTargetedDoor.id == info.id then
        lastTargetedDoor = nil
    end
end

local function playMisfireEffect(coords, profile)
    if not coords then
        return
    end

    local scale = (profile and profile.fxScale) or 1.0
    local alpha = (profile and profile.fxBrightness) or 1.0
    local sparksMult = (profile and profile.sparksMult) or 1.0
    local count = math.max(2, math.floor(4 * sparksMult))

    lib.requestNamedPtfxAsset('core')
    for i = 1, count do
        UseParticleFxAssetNextCall('core')
        StartParticleFxNonLoopedAtCoord(
            'ent_sht_steam',
            coords.x + ((madvr_random() - 0.5) * 0.5),
            coords.y + ((madvr_random() - 0.5) * 0.5),
            coords.z + 1.0 + ((madvr_random() - 0.5) * 0.2),
            0.0,
            0.0,
            madvr_random(0, 360),
            0.4 * scale,
            false,
            false,
            false
        )
    end

    UseParticleFxAssetNextCall('core')
    StartParticleFxNonLoopedAtCoord(
        'ent_amb_elec_crackle_sp',
        coords.x,
        coords.y,
        coords.z + 1.0,
        0.0,
        0.0,
        0.0,
        0.6 * scale,
        false,
        false,
        false
    )
    RemoveNamedPtfxAsset('core')

    PlaySoundFrontend(-1, 'CONTINUE', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.15 * alpha)
end

local function startPrecastEffect(door, entity)
    local preEffect = Config.PreEffect
    if not preEffect or not door or not door.coords then
        return
    end

    stopPrecastEffect(true)

    local coords = door.coords
    local origin = vector3(coords.x, coords.y, coords.z)
    local markerDelay, cleanupDelay, animDuration = GetAnimationTimings()
    local info = {
        id = door.id,
        entity = entity,
        coords = origin,
        started = GetGameTimer(),
        duration = animDuration,
        markerDelay = markerDelay,
        cleanupDelay = cleanupDelay,
        stop = false
    }

    precastFx = info

    if entity and DoesEntityExist(entity) and preEffect.outline and preEffect.outline.color then
        local c = preEffect.outline.color
        SetEntityDrawOutlineColor(c.r or 255, c.g or 255, c.b or 255, c.a or 255)
        SetEntityDrawOutline(entity, true)
    end

    CreateThread(function()
        while precastFx == info and not info.stop do
            local now = GetGameTimer()
            if info.duration and now - info.started > info.duration then
                break
            end

            local ped = cache.ped
            local wand = GetCurrentPedWeaponEntityIndex(ped)
            local startPos = (wand and wand ~= 0 and DoesEntityExist(wand)) and GetEntityCoords(wand) or GetEntityCoords(ped)

            local zOffset = preEffect.zOffset or 1.0
            local targetX, targetY, targetZ = info.coords.x, info.coords.y, info.coords.z + zOffset

            local beam = preEffect.beamColor or { r = 140, g = 220, b = 255, a = 210 }
            if not info.markerDelay or now - info.started >= info.markerDelay then
                DrawLine(
                    startPos.x,
                    startPos.y,
                    startPos.z + 0.05,
                    targetX,
                    targetY,
                    targetZ,
                    beam.r or 140,
                    beam.g or 220,
                    beam.b or 255,
                    beam.a or 210
                )
            end

            local marker = preEffect.marker
            if marker then
                local rotSpeed = marker.rotationSpeed or 8.0
                local rotZ = (now / rotSpeed) % 360
                DrawMarker(
                    marker.type or 28,
                    targetX,
                    targetY,
                    targetZ + (marker.zOffset or 0.0),
                    marker.dirX or 0.0,
                    marker.dirY or 0.0,
                    marker.dirZ or 0.0,
                    marker.rotX or 0.0,
                    marker.rotY or 0.0,
                    rotZ,
                    marker.scaleX or (marker.scale and marker.scale.x) or 0.35,
                    marker.scaleY or (marker.scale and marker.scale.y) or 0.35,
                    marker.scaleZ or (marker.scale and marker.scale.z) or 0.35,
                    marker.colorR or (marker.color and marker.color.r) or 140,
                    marker.colorG or (marker.color and marker.color.g) or 220,
                    marker.colorB or (marker.color and marker.color.b) or 255,
                    marker.colorA or (marker.color and marker.color.a) or 185,
                    false,
                    false,
                    2,
                    false,
                    nil,
                    nil,
                    false
                )
            end

            local light = preEffect.light
            if light and light.color then
                DrawLightWithRange(
                    targetX,
                    targetY,
                    targetZ,
                    light.color.r or 160,
                    light.color.g or 220,
                    light.color.b or 255,
                    light.distance or 6.5,
                    light.brightness or 3.0
                )
            end

            Wait(0)
        end

        if precastFx == info then
            stopPrecastEffect(false)
        end
    end)
end

RegisterNetEvent('dvr_aloharis:onCast', function(spellLevel)
    local messages = Config.Messages or {}
    -- REPLACE WITH YOUR DOOR LOCK SYSTEM (e.g. ox_doorlock: https://github.com/overextended/ox_doorlock)
    local door = exports.ox_doorlock:getClosestDoor()
    local maxDistance = Config.MaxDistance or 3.0

    if not door or not door.id or not door.distance or door.distance > maxDistance then
        notify(messages.noDoor)
        return
    end

    local hit, entity = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, maxDistance + 0.5)
    if hit and entity and entity > 0 and not matchesDoorEntity(door, entity) then
        notify(messages.noDoor)
        return
    end

    if doorIsBlacklisted(door) then
        notify(messages.blacklisted)
        return
    end

    if door.state == 0 then
        notify(messages.alreadyUnlocked)
        return
    end

    lastTargetedDoor = {
        id = door.id,
        coords = door.coords and vector3(door.coords.x, door.coords.y, door.coords.z) or nil,
        entity = (matchesDoorEntity(door, entity) and entity) or door.entity or (door.doors and door.doors[1] and door.doors[1].entity) or nil
    }

    local profile = BuildProfile(spellLevel)

    if madvr_random() < profile.failChance then
        stopPrecastEffect(false)
        if lastTargetedDoor and lastTargetedDoor.coords then
            playMisfireEffect(lastTargetedDoor.coords, profile)
        end
        notify(messages.failed)
        return
    end

    startPrecastEffect(door, lastTargetedDoor.entity)

    local coords = door.coords
    local payload = {
        id = door.id,
        name = door.name,
        coords = coords and { x = coords.x, y = coords.y, z = coords.z } or nil,
        state = door.state,
        level = spellLevel
    }

    TriggerServerEvent('dvr_aloharis:unlockDoor', payload)
end)

local function playUnlockEffect(data, profile)
    local effect = Config.Effect
    if not effect or not data then
        return
    end

    local coords = data.coords
    if (not coords or not coords.x) and lastTargetedDoor and lastTargetedDoor.id == data.id then
        coords = { x = lastTargetedDoor.coords and lastTargetedDoor.coords.x or 0.0, y = lastTargetedDoor.coords and lastTargetedDoor.coords.y or 0.0, z = lastTargetedDoor.coords and lastTargetedDoor.coords.z or 0.0 }
    end

    if not coords or not coords.x then
        return
    end

    local x, y, z = coords.x, coords.y, coords.z

    if effect.sound then
        if effect.sound.useFrontend then
            PlaySoundFrontend(-1, effect.sound.name or 'SELECT', effect.sound.set or 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        else
            PlaySoundFromCoord(-1, effect.sound.name or 'SELECT', x, y, z + (effect.sound.zOffset or 1.0), effect.sound.set or 'HUD_FRONTEND_DEFAULT_SOUNDSET', false, 0, false)
        end
    end

    if effect.camera and data.source == cache.serverId then
        if effect.camera.shake and effect.camera.amplitude then
            ShakeGameplayCam(effect.camera.shake, effect.camera.amplitude)
        end

        if effect.camera.postfx then
            local duration = effect.camera.postfxDuration or 1200
            AnimpostfxPlay(effect.camera.postfx, duration, false)
            SetTimeout(duration, function()
                AnimpostfxStop(effect.camera.postfx)
            end)
        end
    end

    local fxScaleMult = (profile and profile.fxScale) or 1.0
    local fxLightMult = (profile and profile.fxBrightness) or 1.0
    local fxSparksMult = (profile and profile.sparksMult) or 1.0

    if effect.burst then
        local burst = effect.burst

        if burst.rings and burst.rings.asset and burst.rings.name then
            lib.requestNamedPtfxAsset(burst.rings.asset)
            UseParticleFxAssetNextCall(burst.rings.asset)
            local handle = StartParticleFxLoopedAtCoord(
                burst.rings.name,
                x,
                y,
                z + (burst.rings.zOffset or 1.05),
                0.0,
                0.0,
                0.0,
                (burst.rings.scale or 1.4) * fxScaleMult,
                false,
                false,
                false,
                false
            )

            if handle then
                CreateThread(function()
                    Wait(burst.rings.duration or 2200)
                    StopParticleFxLooped(handle, false)
                    RemoveNamedPtfxAsset(burst.rings.asset)
                end)
            else
                RemoveNamedPtfxAsset(burst.rings.asset)
            end
        end

        if burst.shockwave and burst.shockwave.asset and burst.shockwave.name then
            lib.requestNamedPtfxAsset(burst.shockwave.asset)
            UseParticleFxAssetNextCall(burst.shockwave.asset)
            StartParticleFxNonLoopedAtCoord(
                burst.shockwave.name,
                x,
                y,
                z + (burst.shockwave.zOffset or 1.05),
                0.0,
                0.0,
                0.0,
                (burst.shockwave.scale or 1.0) * fxScaleMult,
                false,
                false,
                false
            )
            RemoveNamedPtfxAsset(burst.shockwave.asset)
        end

        if burst.sparks and burst.sparks.asset and burst.sparks.name then
            lib.requestNamedPtfxAsset(burst.sparks.asset)
            CreateThread(function()
                local iterations = math.max(1, math.floor((burst.sparks.count or 3) * fxSparksMult))
                local delay = burst.sparks.delay or 120
                for i = 1, iterations do
                    UseParticleFxAssetNextCall(burst.sparks.asset)
                    StartParticleFxNonLoopedAtCoord(
                        burst.sparks.name,
                        x + ((madvr_sin(GetGameTimer() / 45 + i) * 0.2) or 0.0),
                        y + ((madvr_sin(GetGameTimer() / 60 + i) * 0.2) or 0.0),
                        z + (burst.sparks.zOffset or 1.2),
                        0.0,
                        0.0,
                        0.0,
                        (burst.sparks.scale or 0.8) * fxScaleMult,
                        false,
                        false,
                        false
                    )
                    Wait(delay)
                end
                RemoveNamedPtfxAsset(burst.sparks.asset)
            end)
        end
    end

    if effect.lingering and effect.lingering.asset and effect.lingering.name then
        lib.requestNamedPtfxAsset(effect.lingering.asset)
        UseParticleFxAssetNextCall(effect.lingering.asset)
        local handle = StartParticleFxLoopedAtCoord(
            effect.lingering.name,
            x,
            y,
            z + (effect.lingering.zOffset or 1.0),
            0.0,
            0.0,
            0.0,
            (effect.lingering.scale or 0.9) * fxScaleMult,
            false,
            false,
            false,
            false
        )

        if handle then
            CreateThread(function()
                Wait(effect.lingering.duration or 1600)
                StopParticleFxLooped(handle, false)
                RemoveNamedPtfxAsset(effect.lingering.asset)
            end)
        else
            RemoveNamedPtfxAsset(effect.lingering.asset)
        end
    end

    if effect.light and effect.light.color then
        local light = effect.light
        CreateThread(function()
            local startTime = GetGameTimer()
            local duration = light.duration or 1400
            while GetGameTimer() - startTime < duration do
                DrawLightWithRange(
                    x,
                    y,
                    z + (light.zOffset or 1.0),
                    light.color.r or 160,
                    light.color.g or 220,
                    light.color.b or 255,
                    (light.distance or 9.0) * fxScaleMult,
                    (light.brightness or 4.0) * fxLightMult
                )
                Wait(0)
            end
        end)
    end

    local entityHandle = nil
    if lastTargetedDoor and lastTargetedDoor.id == data.id then
        entityHandle = lastTargetedDoor.entity
    end

    if entityHandle and DoesEntityExist(entityHandle) and effect.outline and effect.outline.color then
        local outline = effect.outline
        local color = outline.color
        SetEntityDrawOutlineColor(color.r or 160, color.g or 220, color.b or 255, color.a or 255)
        SetEntityDrawOutline(entityHandle, true)

        if outline.pulse then
            CreateThread(function()
                local startTime = GetGameTimer()
                local duration = outline.duration or 2000
                while DoesEntityExist(entityHandle) and GetGameTimer() - startTime < duration do
                    local pulse = math.floor(140 + (madvr_sin(GetGameTimer() / 120) * 80))
                    SetEntityDrawOutlineColor(color.r or 160, color.g or 220, color.b or 255, pulse)
                    Wait(0)
                end
                if DoesEntityExist(entityHandle) then
                    SetEntityDrawOutline(entityHandle, false)
                end
            end)
        else
            SetTimeout(outline.duration or 1800, function()
                if DoesEntityExist(entityHandle) then
                    SetEntityDrawOutline(entityHandle, false)
                end
            end)
        end
    end

    if lastTargetedDoor and lastTargetedDoor.id == data.id then
        lastTargetedDoor = nil
    end
end

RegisterNetEvent('dvr_aloharis:doorUnlocked', function(data)
    local messages = Config.Messages or {}
    if not data then
        return
    end

    stopPrecastEffect(data.success)

    if not data.success then
        if data.source == cache.serverId then
            local reason = data.reason or 'failed'
            notify(messages[reason] or messages.failed)
        end
        return
    end

    if data.source == cache.serverId then
        notify(messages.unlocked)
    end

    local profile = BuildProfile(data.level or 0)
    playUnlockEffect(data, profile)
end)
