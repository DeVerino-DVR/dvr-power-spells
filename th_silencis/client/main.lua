---@diagnostic disable: undefined-global, trailing-space, param-type-mismatch
local Config <const> = Config
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId

local silencisMutedPlayers = {}

AddStateBagChangeHandler('silencis_muted', nil, function(bagName, key, value, reserved, replicated)
    local serverIdStr = bagName:gsub('player:', '')
    if not serverIdStr or serverIdStr == '' then return end
    
    local targetServerId = tonumber(serverIdStr)
    if not targetServerId then return end
    
    local localPlayerId = GetPlayerServerId(PlayerId())
    
    if targetServerId == localPlayerId then return end
    
    if value == true then
        MumbleSetVolumeOverrideByServerId(targetServerId, 0.0)
        silencisMutedPlayers[targetServerId] = true
    else
        if silencisMutedPlayers[targetServerId] then
            MumbleSetVolumeOverrideByServerId(targetServerId, -1.0)
            silencisMutedPlayers[targetServerId] = nil
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    for targetServerId, _ in pairs(silencisMutedPlayers) do
        MumbleSetVolumeOverrideByServerId(targetServerId, -1.0)
    end
    silencisMutedPlayers = {}
end)
