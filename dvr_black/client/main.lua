---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local PlayerId = PlayerId
local GetPlayerServerId = GetPlayerServerId
local DoesEntityExist = DoesEntityExist
local GetPedBoneIndex = GetPedBoneIndex
local RequestAnimDict = RequestAnimDict
local HasAnimDictLoaded = HasAnimDictLoaded
local TaskPlayAnim = TaskPlayAnim
local StopAnimTask = StopAnimTask
local IsEntityPlayingAnim = IsEntityPlayingAnim
local SetPedHeadOverlay = SetPedHeadOverlay
local SetPedHeadOverlayColor = SetPedHeadOverlayColor
local GetPedHeadOverlayData = GetPedHeadOverlayData
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxLoopedOnEntityBone = StartParticleFxLoopedOnEntityBone
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local GetGameTimer = GetGameTimer
local TriggerServerEvent = TriggerServerEvent
local Wait = Wait
local CreateThread = CreateThread
local RegisterNetEvent = RegisterNetEvent
local AddEventHandler = AddEventHandler
local GetCurrentResourceName = GetCurrentResourceName
local pairs = pairs
local type = type
local tonumber = tonumber
local madvr_max = math.max
local madvr_floor = math.floor

local blackPlayers = {}
local savedMakeup = {}
local appliedPed = {}
local activeTransitionFx = {}
local loadedPtfxAssets = {}

local function IsMakeupProfile(value)
    return type(value) == 'table'
        and (value.overlay_id ~= nil or value.style ~= nil or value.opacity ~= nil or value.colour_type ~= nil)
end

local MAKEUP_RGB_BY_INDEX <const> = {
    [0] = { r = 153, g = 37, b = 50 },
    [1] = { r = 200, g = 57, b = 93 },
    [2] = { r = 189, g = 81, b = 108 },
    [3] = { r = 184, g = 99, b = 122 },
    [4] = { r = 166, g = 82, b = 107 },
    [5] = { r = 177, g = 67, b = 76 },
    [6] = { r = 127, g = 49, b = 51 },
    [7] = { r = 164, g = 100, b = 93 },
    [8] = { r = 193, g = 135, b = 121 },
    [9] = { r = 203, g = 160, b = 150 },
    [10] = { r = 198, g = 145, b = 143 },
    [11] = { r = 171, g = 111, b = 99 },
    [12] = { r = 176, g = 96, b = 80 },
    [13] = { r = 168, g = 76, b = 51 },
    [14] = { r = 180, g = 113, b = 120 },
    [15] = { r = 202, g = 127, b = 146 },
    [16] = { r = 237, g = 156, b = 190 },
    [17] = { r = 231, g = 117, b = 164 },
    [18] = { r = 222, g = 62, b = 129 },
    [19] = { r = 179, g = 76, b = 110 },
    [20] = { r = 113, g = 39, b = 57 },
    [21] = { r = 79, g = 31, b = 42 },
    [22] = { r = 170, g = 34, b = 47 },
    [23] = { r = 222, g = 32, b = 52 },
    [24] = { r = 207, g = 8, b = 19 },
    [25] = { r = 229, g = 84, b = 112 },
    [26] = { r = 220, g = 63, b = 181 },
    [27] = { r = 194, g = 39, b = 178 },
    [28] = { r = 160, g = 28, b = 169 },
    [29] = { r = 110, g = 24, b = 117 },
    [30] = { r = 115, g = 20, b = 101 },
    [31] = { r = 86, g = 22, b = 92 },
    [32] = { r = 109, g = 26, b = 157 },
    [33] = { r = 27, g = 55, b = 113 },
    [34] = { r = 29, g = 78, b = 167 },
    [35] = { r = 30, g = 116, b = 187 },
    [36] = { r = 33, g = 163, b = 206 },
    [37] = { r = 37, g = 194, b = 210 },
    [38] = { r = 35, g = 204, b = 165 },
    [39] = { r = 39, g = 192, b = 125 },
    [40] = { r = 27, g = 156, b = 50 },
    [41] = { r = 20, g = 134, b = 4 },
    [42] = { r = 112, g = 208, b = 65 },
    [43] = { r = 197, g = 234, b = 52 },
    [44] = { r = 225, g = 227, b = 47 },
    [45] = { r = 255, g = 221, b = 38 },
    [46] = { r = 250, g = 192, b = 38 },
    [47] = { r = 247, g = 138, b = 39 },
    [48] = { r = 254, g = 89, b = 16 },
    [49] = { r = 190, g = 110, b = 25 },
    [50] = { r = 247, g = 201, b = 127 },
    [51] = { r = 251, g = 229, b = 192 },
    [52] = { r = 245, g = 245, b = 245 },
    [53] = { r = 179, g = 180, b = 179 },
    [54] = { r = 145, g = 145, b = 145 },
    [55] = { r = 86, g = 78, b = 78 },
    [56] = { r = 24, g = 14, b = 14 },
    [57] = { r = 88, g = 150, b = 158 },
    [58] = { r = 77, g = 111, b = 140 },
    [59] = { r = 26, g = 43, b = 85 },
    [60] = { r = 160, g = 126, b = 107 },
    [61] = { r = 130, g = 99, b = 85 },
    [62] = { r = 109, g = 83, b = 70 },
    [63] = { r = 62, g = 45, b = 39 }
}

local function EnsurePtfxAsset(asset)
    if not asset or asset == '' then
        return false
    end

    if loadedPtfxAssets[asset] == true then
        return true
    end

    RequestNamedPtfxAsset(asset)
    while not HasNamedPtfxAssetLoaded(asset) do
        Wait(0)
    end

    -- On considère l'asset chargé après le loop (comme dvr_transvalis)
    loadedPtfxAssets[asset] = true
    return true
end

local function EnsureMinChannel(colour, minChannel)
    if not colour then
        return colour
    end

    local minVal = tonumber(minChannel) or 0
    if minVal <= 0 then
        return colour
    end
    if minVal > 255 then
        minVal = 255
    end

    local r = tonumber(colour.r) or tonumber(colour[1]) or 0
    local g = tonumber(colour.g) or tonumber(colour[2]) or 0
    local b = tonumber(colour.b) or tonumber(colour[3]) or 0

    local maxVal = madvr_max(r, g, b)
    if maxVal < 1 then
        return { r = minVal, g = minVal, b = minVal }
    end
    if maxVal >= minVal then
        return { r = r, g = g, b = b }
    end

    local factor = minVal / maxVal
    return {
        r = madvr_floor(r * factor),
        g = madvr_floor(g * factor),
        b = madvr_floor(b * factor)
    }
end

local function SetLoopColour(handle, colour)
    if not handle or handle == 0 or not colour then
        return
    end

    local r = colour.r or colour[1] or 0.0
    local g = colour.g or colour[2] or 0.0
    local b = colour.b or colour[3] or 0.0

    if r > 1.0 or g > 1.0 or b > 1.0 then
        r = r / 255.0
        g = g / 255.0
        b = b / 255.0
    end

    SetParticleFxLoopedColour(handle, r, g, b, false)
end

local function GetMakeupRgb(colourIndex)
    local idx = tonumber(colourIndex)
    if idx == nil then
        return nil
    end

    idx = madvr_floor(idx)
    return MAKEUP_RGB_BY_INDEX[idx]
end

local function StopTransitionFx(serverId)
    local handle = activeTransitionFx[serverId]
    if not handle or handle == 0 then
        activeTransitionFx[serverId] = nil
        return
    end

    StopParticleFxLooped(handle, 0)
    RemoveParticleFx(handle, false)
    activeTransitionFx[serverId] = nil
end

local function PlayTransitionFx(serverId, ped, profile)
    if not serverId or not ped or ped == 0 or not DoesEntityExist(ped) then
        return
    end

    local cfg = Config and Config.TransitionFx
    if type(cfg) ~= 'table' then
        cfg = {}
    end

    local attachMode = cfg.attach or 'entity'
    local asset = cfg.asset or 'ns_ptfx'
    local effect = cfg.effect or 'fire'
    local duration = tonumber(cfg.duration) or 1200
    local alpha = cfg.alpha
    local scale = tonumber(cfg.scale) or 1.5
    local minChannel = tonumber(cfg.min_channel) or 0

    local function ResolveBoneIndex(boneId)
        local bone = tonumber(boneId)
        if not bone then
            return 0
        end
        return GetPedBoneIndex(ped, bone)
    end

    local boneIndex = ResolveBoneIndex(cfg.bone)
    if not boneIndex or boneIndex == 0 then
        boneIndex = ResolveBoneIndex(31086)
    end

    local offset = cfg.offset
    if type(offset) ~= 'table' then
        if attachMode == 'bone' then
            offset = { x = 0.0, y = 0.0, z = 0.0 }
        else
            offset = { x = 0.0, y = 0.0, z = 0.65 }
        end
    end
    local rot = cfg.rot or { x = 0.0, y = 0.0, z = 0.0 }

    local colourIndex = profile and profile.colour
    local rgb = EnsureMinChannel(GetMakeupRgb(colourIndex), minChannel) or { r = 255, g = 255, b = 255 }

    StopTransitionFx(serverId)

    if not EnsurePtfxAsset(asset) then
        return
    end

    local function StartOnBone(index)
        if not index or index == 0 then
            return 0
        end

        UseParticleFxAsset(asset)
        UseParticleFxAssetNextCall(asset)
        return StartParticleFxLoopedOnEntityBone(
            effect,
            ped,
            offset.x or 0.0, offset.y or 0.0, offset.z or 0.0,
            rot.x or 0.0, rot.y or 0.0, rot.z or 0.0,
            index,
            scale,
            false, false, false
        )
    end

    local function StartOnEntity()
        local entityOffset = offset
        if attachMode == 'bone' then
            entityOffset = cfg.fallback_entity_offset or { x = 0.0, y = 0.0, z = 0.65 }
        end

        UseParticleFxAsset(asset)
        UseParticleFxAssetNextCall(asset)
        return StartParticleFxLoopedOnEntity(
            effect,
            ped,
            entityOffset.x or 0.0, entityOffset.y or 0.0, entityOffset.z or 0.0,
            rot.x or 0.0, rot.y or 0.0, rot.z or 0.0,
            scale,
            false, false, false
        )
    end

    local handle

    if attachMode == 'bone' then
        handle = StartOnBone(boneIndex)
        if not handle or handle == 0 then
            handle = StartOnEntity()
        end
    else
        handle = StartOnEntity()
        if not handle or handle == 0 then
            handle = StartOnBone(boneIndex)
        end
    end

    if not handle or handle == 0 then
        if Config and Config.Debug then
            print(('[dvr_black] PTFX FAIL asset=%s effect=%s attach=%s bone=%s scale=%s'):format(
                tostring(asset),
                tostring(effect),
                tostring(attachMode),
                tostring(cfg.bone),
                tostring(scale)
            ))
        end
        return
    end

    activeTransitionFx[serverId] = handle
    SetLoopColour(handle, rgb)

    if alpha ~= nil then
        SetParticleFxLoopedAlpha(handle, alpha)
    end

    CreateThread(function()
        Wait(duration)
        if activeTransitionFx[serverId] == handle then
            StopTransitionFx(serverId)
        end
    end)
end

local function ResolveMakeupProfile(profile)
    if IsMakeupProfile(profile) then
        return profile
    end

    local makeupCfg = Config and Config.Makeup
    if IsMakeupProfile(makeupCfg) then
        return makeupCfg
    end

    if type(makeupCfg) == 'table' then
        if IsMakeupProfile(makeupCfg.default) then
            return makeupCfg.default
        end
    end

    return false
end

local function GetPedByServerId(serverId)
    if not serverId then
        return nil
    end

    local player <const> = GetPlayerFromServerId(serverId)
    if not player or player == -1 then
        return nil
    end

    local ped <const> = GetPlayerPed(player)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return nil
    end

    return ped
end

local function IsLocalServerId(serverId)
    local playerId = PlayerId()
    if playerId == nil then
        return false
    end

    local localServerId = GetPlayerServerId(playerId)
    if localServerId == nil then
        return false
    end

    return serverId == localServerId
end

local function PlayAgonyAnimation(pedId, durationMs)
    if not pedId or pedId == 0 or not DoesEntityExist(pedId) then
        return
    end

    RequestAnimDict('zombies_animations')
    while not HasAnimDictLoaded('zombies_animations') do
        Wait(10)
    end
    TaskPlayAnim(pedId, 'zombies_animations', 'agony', 8.0, -8.0, -1, 1, 0, false, false, false)

    local duration = tonumber(durationMs)
    if duration and duration > 0 then
        CreateThread(function()
            Wait(duration)

            if DoesEntityExist(pedId) and IsEntityPlayingAnim(pedId, 'zombies_animations', 'agony', 3) then
                StopAnimTask(pedId, 'zombies_animations', 'agony', -8.0)
            end
        end)
    end
end

local function CaptureMakeup(ped, overlayId, fallbackColourType)
    local ok, value, colourType, firstColour, secondColour, opacity = GetPedHeadOverlayData(ped, overlayId)
    if not ok then
        return {
            value = 255,
            colourType = fallbackColourType or 1,
            firstColour = 0,
            secondColour = 0,
            opacity = 0.0
        }
    end

    return {
        value = value,
        colourType = colourType,
        firstColour = firstColour,
        secondColour = secondColour,
        opacity = opacity
    }
end

local function EnsureSavedMakeup(serverId, ped, makeupCfg)
    local overlayId <const> = makeupCfg.overlay_id or 4

    local entry = savedMakeup[serverId]
    if entry and entry.ped == ped and entry.data and entry.overlayId == overlayId then
        return entry.data, overlayId
    end

    local original = CaptureMakeup(ped, overlayId, makeupCfg.colour_type or 1)
    savedMakeup[serverId] = {
        ped = ped,
        overlayId = overlayId,
        data = original
    }
    return original, overlayId
end

local function ApplyBlackMakeup(serverId, ped, profile)
    local makeupCfg <const> = ResolveMakeupProfile(profile)
    if not makeupCfg then
        return
    end
    local _, overlayId <const> = EnsureSavedMakeup(serverId, ped, makeupCfg)

    local overlayValue = makeupCfg.style
    if overlayValue == nil then
        overlayValue = makeupCfg.fallback_style
    end
    if overlayValue == nil then
        overlayValue = 10
    end

    SetPedHeadOverlay(ped, overlayId, overlayValue, makeupCfg.opacity or 1.0)
    SetPedHeadOverlayColor(ped, overlayId, makeupCfg.colour_type or 1, makeupCfg.colour or 0, makeupCfg.secondary_colour or 0)

    appliedPed[serverId] = ped
end

local function RestoreMakeup(serverId, ped)
    local entry = savedMakeup[serverId]
    local original = entry and entry.data
    local overlayId = entry and entry.overlayId

    if overlayId == nil then
        overlayId = ResolveMakeupProfile(nil).overlay_id or 4
        if overlayId == nil or overlayId == false then
            return
        end
    end

    if original then
        local value = original.value ~= nil and original.value or 255
        local opacity = original.opacity ~= nil and original.opacity or 0.0

        SetPedHeadOverlay(ped, overlayId, value, opacity)

        if value ~= 255 and value ~= -1 then
            SetPedHeadOverlayColor(
                ped,
                overlayId,
                original.colourType or 1,
                original.firstColour or 0,
                original.secondColour or 0
            )
        end
    else
        SetPedHeadOverlay(ped, overlayId, 255, 0.0)
    end

    savedMakeup[serverId] = nil
    appliedPed[serverId] = nil
end

local function SetBlackState(serverId, enabled, profile)
    if enabled then
        local resolved <const> = ResolveMakeupProfile(profile)
        if not resolved then
            return
        end
        blackPlayers[serverId] = resolved
        local ped = GetPedByServerId(serverId)
        if ped then
            ApplyBlackMakeup(serverId, ped, resolved)
        end
        return
    end

    blackPlayers[serverId] = nil
    local ped = GetPedByServerId(serverId)
    if ped then
        RestoreMakeup(serverId, ped)
    else
        savedMakeup[serverId] = nil
        appliedPed[serverId] = nil
    end
end

RegisterNetEvent('dvr_black:sync', function(serverId, enabled, profile)
    SetBlackState(serverId, enabled == true, profile)
end)

RegisterNetEvent('dvr_black:transitionFx', function(serverId, profile, enabled)
    local ped = GetPedByServerId(serverId)
    if not ped then
        return
    end

    local resolved = ResolveMakeupProfile(profile)
    if enabled == true and IsLocalServerId(serverId) then
        local duration = (Config and Config.TransitionFx and tonumber(Config.TransitionFx.duration)) or 1200
        PlayAgonyAnimation(ped, duration)
        PlayTransitionFx(serverId, ped, resolved)
    end

    if enabled == false and IsLocalServerId(serverId) then
        local duration = (Config and Config.TransitionFx and tonumber(Config.TransitionFx.duration)) or 1200
        PlayAgonyAnimation(ped, duration)
        PlayTransitionFx(serverId, ped, resolved)
    end
end)

CreateThread(function()
    Wait(2500)
    TriggerServerEvent('dvr_black:requestSync')

    while true do
        Wait(1000)
        for serverId, profile in pairs(blackPlayers) do
            local ped = GetPedByServerId(serverId)
            if ped then
                ApplyBlackMakeup(serverId, ped, profile)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    for serverId in pairs(activeTransitionFx) do
        StopTransitionFx(serverId)
    end

    for serverId, _ in pairs(blackPlayers) do
        local ped = GetPedByServerId(serverId)
        if ped then
            RestoreMakeup(serverId, ped)
        end
    end

    blackPlayers = {}
    savedMakeup = {}
    appliedPed = {}
end)
