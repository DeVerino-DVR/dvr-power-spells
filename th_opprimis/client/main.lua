---@diagnostic disable: undefined-global, trailing-space, param-type-mismatch
local Config <const> = Config
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local DoesEntityExist = DoesEntityExist
local Wait = Wait
local CreateThread = CreateThread
local TaskPlayAnim = TaskPlayAnim
local RequestAnimDict = RequestAnimDict
local HasAnimDictLoaded = HasAnimDictLoaded
local ClearPedTasks = ClearPedTasks
local SetPedCanRagdoll = SetPedCanRagdoll
local DisableControlAction = DisableControlAction

local isHandcuffed = false
local handcuffDuration = 0
local casterServerId = nil
local handcuffEndTime = 0

local ropeProp = nil
local ROPE_PROP_MODEL = 'bzzz_prop_gag_b'
local ROPE_BONE = 18905 -- SKEL_L_Hand
local ROPE_OFFSET = vector3(-0.02, -0.01, 0.1)
local ROPE_ROTATION = vector3(-13.0, -109.0, 3.55)

local function loadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 5000 do
            Wait(10)
            timeout = timeout + 10
        end
    end
    return HasAnimDictLoaded(dict)
end

local function loadModel(model)
    local hash = type(model) == 'string' and GetHashKey(model) or model
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 5000 do
            Wait(10)
            timeout = timeout + 10
        end
    end
    return HasModelLoaded(hash)
end

local function attachRopeProp()
    local ped = PlayerPedId()

    if ropeProp and DoesEntityExist(ropeProp) then
        DeleteEntity(ropeProp)
        ropeProp = nil
    end

    if not loadModel(ROPE_PROP_MODEL) then
        print('[th_opprimis] Erreur: Impossible de charger le modele ' .. ROPE_PROP_MODEL)
        return
    end

    local coords = GetEntityCoords(ped)
    local hash = GetHashKey(ROPE_PROP_MODEL)

    ropeProp = CreateObject(hash, coords.x, coords.y, coords.z, true, true, true)

    if not ropeProp or ropeProp == 0 then
        print('[th_opprimis] Erreur: Impossible de creer le prop de corde')
        return
    end

    local boneIndex = GetPedBoneIndex(ped, ROPE_BONE)

    AttachEntityToEntity(
        ropeProp,
        ped,
        boneIndex,
        ROPE_OFFSET.x,
        ROPE_OFFSET.y,
        ROPE_OFFSET.z,
        ROPE_ROTATION.x,
        ROPE_ROTATION.y,
        ROPE_ROTATION.z,
        true,
        true,
        false,
        true,
        1,
        true
    )

    SetModelAsNoLongerNeeded(hash)
end

local function removeRopeProp()
    if ropeProp and DoesEntityExist(ropeProp) then
        DeleteEntity(ropeProp)
        ropeProp = nil
    end
end

local function playCuffedAnimation()
    local ped = PlayerPedId()
    local anim = Config.Animations.cuffed

    if loadAnimDict(anim.dict) then
        TaskPlayAnim(ped, anim.dict, anim.name, 8.0, -8.0, -1, anim.flag, 0, false, false, false)
    end
end

local function stopAnimations()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end

local disabledControls = {
    24, 25, 45, 47, 58, 37, 44,
    140, 141, 142, 143, 257, 263, 264,
    23, 75, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74,
    38, 39, 40, 41, 42, 43, 46,
    27, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181,
    51, 52, 54, 55, 56, 57, 73, 99, 100,
    85, 81, 82, 83, 84,
    182, 183, 244, 245, 246, 288, 289, 303, 199, 200,
    29, 36
}

local function startHandcuffThread()
    CreateThread(function()
        local myPed = PlayerPedId()

        playCuffedAnimation()

        SetPedCanRagdoll(myPed, false)
        SetCurrentPedWeapon(myPed, `WEAPON_UNARMED`, true)

        while isHandcuffed do
            Wait(0)

            myPed = PlayerPedId()

            for _, control in ipairs(disabledControls) do
                DisableControlAction(0, control, true)
            end
            DisablePlayerFiring(PlayerId(), true)
            SetCurrentPedWeapon(myPed, `WEAPON_UNARMED`, true)

            if not IsEntityPlayingAnim(myPed, Config.Animations.cuffed.dict, Config.Animations.cuffed.name, 3) then
                playCuffedAnimation()
            end
        end

        SetPedCanRagdoll(myPed, true)
        DisablePlayerFiring(PlayerId(), false)
        stopAnimations()
    end)
end

RegisterNetEvent('th_opprimis:onHandcuffed', function(duration, casterId)
    isHandcuffed = true
    handcuffDuration = duration
    casterServerId = casterId
    handcuffEndTime = GetGameTimer() + (duration * 1000)

    SetTimeout(500, function()
        if isHandcuffed then
            attachRopeProp()
            startHandcuffThread()
        end
    end)
end)

RegisterNetEvent('th_opprimis:onReleased', function()
    isHandcuffed = false
    handcuffDuration = 0
    casterServerId = nil
    handcuffEndTime = 0

    removeRopeProp()
    stopAnimations()
end)

AddStateBagChangeHandler('opprimis_handcuffed', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(bagName, key, value, reserved, replicated)
    if value == true and not isHandcuffed then
        isHandcuffed = true
        SetTimeout(500, function()
            if isHandcuffed then
                attachRopeProp()
                startHandcuffThread()
            end
        end)
    elseif value == false and isHandcuffed then
        isHandcuffed = false
        removeRopeProp()
        stopAnimations()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    isHandcuffed = false
    removeRopeProp()

    local ped = PlayerPedId()
    SetPedCanRagdoll(ped, true)
    ClearPedTasks(ped)
end)

exports('isLocalHandcuffed', function()
    return isHandcuffed
end)
