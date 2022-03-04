local ESX = nil
local activeTime = {}
local SAVE_PLAYER_TIME = 60 * 60

-- ESX
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('kn:admin:getPlayTime', function(source, cb, player)
    local identifier = GetPlayerIdentifiers(player)[2]
    cb(math.floor(activeTime[identifier].timePlay / 3600))
end)

AddEventHandler('esx:playerLoaded', function(source)

    local _source = source
    local identifier = GetPlayerIdentifiers(_source)[2]
    activeTime[identifier] = {source = _source, joinTime = os.time(), timePlay = 0}
    MySQL.Async.fetchAll("SELECT activeTime FROM users WHERE identifier = @identifier", { ["@identifier"] = identifier }, function(result)
        if result then
            activeTime[identifier].timePlay = result[1].timePlay
        end

    end)

end)

AddEventHandler('playerDropped', function()
	
	local _source = source
    local identifier = GetPlayerIdentifiers(_source)[2]

    if activeTime[identifier] ~= nil then

        local leaveTime = os.time()
        local saveTime = leaveTime - activeTime[identifier].joinTime

        MySQL.Async.execute('UPDATE users SET activeTime = activeTime + ROUND(@activeTime, 0) WHERE identifier=@identifier', 
        {
            ['@identifier'] = identifier,
            ['@activeTime'] = saveTime
            
        }, function()

            activeTime[identifier] = nil

        end)

    end

end)

function SET_PLAYER_TIME()
    for k,v in pairs(ESX.GetPlayers()) do
        local identifier = GetPlayerIdentifiers(v)[2]
        local timeSart = os.time()
        local playedTime = timeSart - activeTime[identifier].joinTime
        activeTime[identifier].timePlay = activeTime[identifier].timePlay + playedTime
        MySQL.Async.execute('UPDATE users SET activeTime = ROUND(@activeTime, 0) WHERE identifier=@identifier', 
        {
            ['@identifier'] = identifier,
            ['@activeTime'] = activeTime[identifier].timePlay
            
        }, function()

        end)
    end

    print(('[kn_admin] [^2INFORMATION^7] SetPlayerTime() took %.0f seconds (%d items)'):format(os.clock() - timeSart, #activeTime))


    SetTimeout(SAVE_PLAYER_TIME, SET_PLAYER_TIME)
end

SET_PLAYER_TIME()