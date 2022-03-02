KN = nil
TriggerEvent('kn:getCode', function(obj) KN = obj end)

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local banned = ""
local bannedTable = {}

ESX.RegisterServerCallback('kn:admin:getPlayers', function(source, cb)
	totalPlayer = 0
	local players = {}
	for k,v in pairs(ESX.GetPlayers()) do
		players[GetPlayerIdentifiers(v)[1]] = {
			name = GetPlayerName(v),
			id = v,
			playtime = 'WIP'
		}
		totalPlayer = totalPlayer + 1
	end
	cb(players, totalPlayer)
end)

ESX.RegisterServerCallback('kn:admin:isAllowed', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	cb(xPlayer.getGroup())
end)

function loadBans()
	banned = LoadResourceFile(GetCurrentResourceName(), "bans.json") or ""
	if banned ~= "" then
		bannedTable = json.decode(banned)
	else
		bannedTable = {}
	end
end

RegisterCommand("refresh_bans", function()
	loadBans()
end, true)

function removeBan(id)
	bannedTable[id] = nil
	SaveResourceFile(GetCurrentResourceName(), "bans.json", json.encode(bannedTable), -1)
end

function isBanned(id)
	if bannedTable[id] ~= nil then
		if bannedTable[id].expire == 'perma' then
			return bannedTable[id]
		elseif bannedTable[id].expire < os.time() then
			if bannedTable[id].expire ~= -1 then
				removeBan(id)
				return false
			elseif bannedTable[id].expire == -1 then
				return bannedTable[id] 
			end
		else
			return bannedTable[id]
		end
	else
		return false
	end
end

function banUser(expireSeconds, id, re, playerId)
	if expireSeconds == 'perma' then
		bannedTable[id] = {
			banner = id,
			reason = re,
			expire = expireSeconds
		}

		banexpire = 'PERMA'

		SaveResourceFile(GetCurrentResourceName(), "bans.json", json.encode(bannedTable), -1)

		if playerId then
			msg = 'For '..re..' Expires PERMA'

			TriggerClientEvent('chat:addMessage', -1, {
				template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(153, 153, 153, 1);, rgba(255,255,255, 1)); border-radius: 19px;"><i class="fas fa-cog"></i> System:  The Player {0} has Been Banned {1}</div>',
				args = { GetPlayerName(playerId), msg }
			})
		end
	else

		bannedTable[id] = {
			banner = bannedBy,
			reason = re,
			expire = (os.time() + expireSeconds)
		}

		banexpire = (os.date("%c", os.time() + expireSeconds))

		SaveResourceFile(GetCurrentResourceName(), "bans.json", json.encode(bannedTable), -1)

		if playerId then
			msg = 'For '..re..' Expires '..(os.date("%c", (os.time() + expireSeconds)))

			TriggerClientEvent('chat:addMessage', -1, {
				template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(153, 153, 153, 1);, rgba(255,255,255, 1)); border-radius: 19px;"><i class="fas fa-cog"></i> System:  The Player {0} has Been Banned {1}</div>',
				args = { GetPlayerName(playerId), msg }
			})
		end
	end

	local report = {
		{
			["color"] = color,
			["title"] = "**The Player ".. id .." Has Been Banned**",
			["description"] = "Ban Reason: "..re.."\n\nBan Expire: "..banexpire.."\n\nSteam: "..id,
			["footer"] = {
				["text"] = "Made By Known",
			},
		}
	}
	PerformHttpRequest(Config.Banwebhook, function(err, text, headers) end, 'POST', json.encode({username = user, embeds = report}), { ['Content-Type'] = 'application/json' })
end

AddEventHandler('playerConnecting', function(user, set, d)
	for k,v in ipairs(GetPlayerIdentifiers(source))do
		local banData = isBanned(v)
		if banData ~= false then
			if banData.expire == 'perma' then
				set("🛑Banned for: " .. banData.reason .. "\n🕐Expires at : 00/00/0000 at 00:00")
				CancelEvent()
			else
				set("🛑Banned for: " .. banData.reason .. "\n🕐Expires at : " .. (os.date("%c", banData.expire)))
				CancelEvent()
			end
		end
	end
end)

--! For New Kick System

RegisterNetEvent('kn:admin:kick')
AddEventHandler('kn:admin:kick', function(user, msg, isActive)

	local playerHex = GetPlayerIdentifier(user)

	DropPlayer(user, msg)

	local report = {
		{
			["color"] = color,
			["title"] = "**The Player ".. GetPlayerName(user) .." Has Been Kicked**",
			["description"] = "Kick Reason: **"..msg.."\n\nSteam Hex: "..playerHex.."**",
			["footer"] = {
				["text"] = "Made By Known",
			},
		}
	}
	PerformHttpRequest(Config.Kickwebhook, function(err, text, headers) end, 'POST', json.encode({username = name, embeds = report}), { ['Content-Type'] = 'application/json' })
end)

-- ! For New Banning System

RegisterNetEvent('dropplayer')
AddEventHandler('dropplayer', function(reason, user, time)

	local msg = reason

	DropPlayer(user, msg)

end)

RegisterNetEvent('kn:admin:ban')
AddEventHandler('kn:admin:ban', function(user, reason, time, isActive)

	loadBans()

	if isActive then
		local playerHex = GetPlayerIdentifier(user)

		if time == "-1" then

			banUser('perma', playerHex, reason, user)
			TriggerEvent('dropplayer', reason, user)

		else

			time = time * 86400

			banUser(time, playerHex, reason, user)
			TriggerEvent('dropplayer', reason, user)
		end
	else
		if time == "-1" then

			banUser('perma', 'steam:'..user, reason)

		else

			time = time * 86400

			banUser(time, 'steam:'..user, reason)

		end
	end

end)

local statePlayers = {}

RegisterServerEvent('kn:admin:quick')
AddEventHandler('kn:admin:quick', function(id, type, link)
	setUp(id)
	if ESX.GetPlayerFromId(source).getGroup() ~= 'user' then
		local targetPlayer = GetPlayerPed(id)
		if type == "freeze" then 
			if statePlayers[id].frozen then
				FreezeEntityPosition(targetPlayer, false)
				statePlayers[id].frozen = false
			else
				FreezeEntityPosition(targetPlayer, true)
				statePlayers[id].frozen = true
			end
		end
		if type == "bring" then
			SetEntityCoords(targetPlayer, GetEntityCoords(GetPlayerPed(source)))
		end
		if type == "goto" then
			SetEntityCoords(GetPlayerPed(source), GetEntityCoords(targetPlayer))
		end
		if type == "screenshot" then
			local ids = ExtractIdentifiers(id)
			local message = {
				username = "Admin System", -- Bot Name
				embeds = {{
					color = 000000, -- Colour in Hex #000000
					author = {
						name = "KN Admin",
						icon_url = "https://i.imgur.com/DSYsW4y.png"
					},
					title = "Scrrenshot",
					description = "This is a screenshot of a players screen. If this has proof of a person breaking a rule please save and ban them.",
					fields = {
						{
							name = 'Player Name',
							value = GetPlayerName(id),
							inline = false 
						},
						{
							name = 'Discord Tag',
							value = "<@" ..ids.discord:gsub("discord:", "")..">",
							inline = false
						},
						{
							name = 'Rockstart ID',
							value = ids.license,
							inline = false
						},
						{
							name = 'Steam Profile',
							value = "\nhttps://steamcommunity.com/profiles/" ..tonumber(ids.steam:gsub("steam:", ""),16).."",
							inline = false
						}
					},
					image = {
						url = link
					},
					footer = {
						text = "Date: ".." • "..os.date("%x %X %p"),
						icon_url = "https://i.imgur.com/DSYsW4y.png",
					},
				}}, 
				avatar_url = "https://i.imgur.com/DSYsW4y.png" -- Bot Profile Pic
			}
		
			PerformHttpRequest(Config.Screenshotwebhook, function(err, text, headers) -- WEEBHOOK
				
			end, 'POST', json.encode(message), {
				['Content-Type'] = 'application/json' 
			})
		end
		if type == "heal" then
			TriggerClientEvent('mythic_hospital:client:FinishServices', id)
			TriggerClientEvent('esx_basicneeds:healPlayer', id)
		end
		if type == "slay" then
			TriggerClientEvent('kn:admin:slay', id)
		end
		if type == "spectate" then
			TriggerClientEvent('kn:admin:spectate', source, {source = id, name = GetPlayerName(id)}, GetEntityCoords(GetPlayerPed(id)))
		end
	end
end)

function ExtractIdentifiers(src)
    local identifiers = {
        steam = "",
        ip = "",
        discord = "",
        license = "",
        xbl = "",
        live = ""
    }

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)

        if string.find(id, "steam") then
            identifiers.steam = id
        elseif string.find(id, "ip") then
            identifiers.ip = id
        elseif string.find(id, "discord") then
            identifiers.discord = id
        elseif string.find(id, "license") then
            identifiers.license = id
        elseif string.find(id, "xbl") then
            identifiers.xbl = id
        elseif string.find(id, "live") then
            identifiers.live = id
        end
    end

    return identifiers
end

function setUp(id)
	if statePlayers[id] == nil then
		statePlayers[id] = {}		
	end
end