-- Defines all locals

local group = "user"
local players = {}
local onduty = false
local idsOnPlayers = false

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

-- Opens admin menu

RegisterKeyMapping("openAdmin", "Admin Menu", "keyboard", 'HOME')

RegisterCommand("openAdmin",function(source, args)
	ESX.TriggerServerCallback('kn:core:isGroupAllowed', function(result) 
		if result then
			group = result
			ESX.TriggerServerCallback('kn:admin:getPlayers', function(allPlayers, total)
				SetNuiFocus(true, true)
				SendNUIMessage({type = 'open', players = allPlayers, total = total})
			end)
		end
	end)
end)

RegisterCommand('ar', function(source, args)
	if checkDuty() then
		if IsPedInAnyVehicle(PlayerPedId(), false) then
			local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
			SetVehicleEngineHealth(vehicle, 1000)
			SetVehicleEngineOn( vehicle, true, true )
			SetVehicleFixed(vehicle)
		end
	end
end)

RegisterNetEvent('kn:admin:slay')
AddEventHandler('kn:admin:slay', function(g)
	SetEntityHealth(PlayerPedId(), 0)
end)

-- Duty Code

RegisterNUICallback('duty', function(data, cb)
	if group ~= 'user' then
		ped = PlayerPedId()
		if data.type == 'duty' then
			if not onduty then
				onduty = true
			else
				SetPedComponentVariation(PlayerPedId(), 9, 0, 0)
				onduty = false
			end
			TriggerEvent("pNotify:SendNotification",{
				text = "<h2>Admin Notification</h2>" .. "<h1>"..GetPlayerName(PlayerId()).."</h1>" .. "<p>You toggled admin mode.</p>",
				type = "success",
				timeout = (1000),
				layout = "centerLeft",
				queue = "global"
			})
		elseif data.type == 'ids' then
			idsOnPlayers = not idsOnPlayers
		end
	end
end)

Citizen.CreateThread(function()
	sleep =  1000
	while true do
		Citizen.Wait(sleep)
		if idsOnPlayers then
			for _, i in pairs(GetActivePlayers()) do
				if NetworkIsPlayerActive(i) then
		
					local iPed = GetPlayerPed(i)
					local lPlayer = PlayerId()
					if iPed ~= PlayerId() then
						if DoesEntityExist(iPed) then
							distance = #(GetEntityCoords(GetPlayerPed(PlayerId())) - GetEntityCoords(iPed))
							if distance < 10 then
								DrawText3D(GetEntityCoords(iPed)["x"], GetEntityCoords(iPed)["y"], GetEntityCoords(iPed)["z"], GetPlayerServerId(i) .. "  |  " .. GetPlayerName(i) .. (NetworkIsPlayerTalking(i) and "~n~~g~Talking..." or ""))
							end
						end
					end
				end
			end
			sleep = 0
		elseif onduty then
			sleep = 900
			if group == 'superadmin' then
				SetPedComponentVariation(PlayerPedId(), 9, 4, 2)
			elseif group == 'dev' then
				SetPedComponentVariation(PlayerPedId(), 9, 4, 4)
			elseif group == 'admin' then
				SetPedComponentVariation(PlayerPedId(), 9, 4, 0)
			end
		else
			sleep = 1000
		end
	end
end)

function DrawText3D(x,y,z, text)
    local onScreen,_x,_y = World3dToScreen2d(x,y,z)
    local px,py,pz = table.unpack(GetGameplayCamCoord())
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
 
    local scale = (1/dist)*2
    local fov = (1/GetGameplayCamFov())*100
    local scale = scale*fov

    if onScreen then
		SetTextScale(0.80, 0.80)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 215)
		SetTextEntry("STRING")
		SetTextCentre(1)
		SetTextOutline()
		AddTextComponentString(text)
		DrawText(_x,_y)
    end
end

RegisterNUICallback('close', function(data, cb)
	SetNuiFocus(false)
	players = {}
end)

RegisterNUICallback('kick', function(data, cb)
	TriggerServerEvent('kn:admin:kick', data.user, data.param, GetPlayerName(data.user))
end)

RegisterNUICallback('ban', function(data, cb)
	TriggerServerEvent('kn:admin:ban', data.user, data.param, data.length, true)
end)

RegisterNUICallback('ban-offline', function(data, cb)
	TriggerServerEvent('kn:admin:ban', data.user, data.param, data.length, false)
end)

RegisterNUICallback('quick', function(data, cb)
	if checkDuty() then
		if data.type == 'screenshot' then
			exports['screenshot-basic']:requestScreenshotUpload(Config.Screenshotwebhook, 'files[]', function(data2)
				local photo = json.decode(data2)
				link = photo.attachments[1].proxy_url;
				TriggerServerEvent('kn:admin:quick', data.id, data.type, link)
            end)
		else
			TriggerServerEvent('kn:admin:quick', data.id, data.type)
		end
	end
end)

local clip = false

RegisterKeyMapping("noclip", "Noclip", "keyboard", 'F7')

RegisterCommand('noclip', function()
	if group ~= 'user' then
		if checkDuty() then
			TriggerEvent('kn:admin:noClip')
			clip = true
		end
	end
end)

function checkDuty()
	if Config.RequiredDuty then
		if onduty then
			return true 
		else
			return false
			TriggerEvent("pNotify:SendNotification",{
				text = "<h2>Admin Notification</h2>" .. "<h1>ADMIN:</h1>" .. "<p>You must be out of roleplay!</p>",
				type = "success",
				timeout = (1000),
				layout = "centerLeft",
				queue = "global"
			})
		end
	else
		return true
	end
end

--SPECTATE

InSpectatorMode	= false
TargetSpectate	= -1
local spectating = {} -- stores sepctated people

local LastSpecPosition	= nil
local polarAngleDeg		= 0;
local azimuthAngleDeg	= 90;
local radius			= -3.5;
local cam 				= nil
local PlayerDate		= {}
local ShowInfos			= false
local group

function polar3DToWorld3D(entityPosition, radius, polarAngleDeg, azimuthAngleDeg)
	-- convert degrees to radians
	local polarAngleRad   = polarAngleDeg   * math.pi / 180.0
	local azimuthAngleRad = azimuthAngleDeg * math.pi / 180.0

	local pos = {
		x = entityPosition.x + radius * (math.sin(azimuthAngleRad) * math.cos(polarAngleRad)),
		y = entityPosition.y - radius * (math.sin(azimuthAngleRad) * math.sin(polarAngleRad)),
		z = entityPosition.z - radius * math.cos(azimuthAngleRad)
	}

	return pos
end

function drawTxt_spec(x, y, width, height, scale, text, r, g, b, a)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2 + 0.005)
end

RegisterNetEvent("kn:admin:spectate")
AddEventHandler("kn:admin:spectate", function(target, pos)
	if TargetSpectate ~= target then
		if (InSpectatorMode) then
			spectating["source_"..TargetSpectate] = false
		end
		spectate(target, pos, false)
	else
		resetNormalCamera()
	end		
end)

RegisterNUICallback('stopspectating', function(data, cb)
	resetNormalCamera()
end)

function spectate(_targetinfo, _targetpos, _changing) -- It's not pretty, but it works
	local targetpos = _targetpos
	local targetid = nil
	local target = nil

	resetNormalCamera()

	if not _changing then LastSpecPosition = GetEntityCoords(PlayerPedId()) end

	InSpectatorMode = true
	TargetSpectate  = _targetinfo.source
	spectating["source_"..TargetSpectate] = true

	-- Set up the player ped to spectate
	local playerPed = GetPlayerPed(-1)
	SetEntityVisible(playerPed, false, 0)
	SetEntityCoords(playerPed, targetpos.x, targetpos.y, targetpos.z - 25.0, 0.0, 0.0, 0.0, false)
	SetEntityInvincible(playerPed, true)

	local targetPlayer = GetPlayerFromServerId(TargetSpectate)
	local targetPed = GetPlayerPed(targetPlayer)

	--if targetPlayer == -1 then
		--ESX.ShowNotification("Failed to spectate player, they didn't exist!?")
	--else
		RequestCollisionAtCoord(targetpos.x, targetpos.y, targetpos.z)
		NetworkSetInSpectatorMode(true, targetPed)

		Citizen.CreateThread(function()
			local _spec = TargetSpectate
			while InSpectatorMode and spectating["source_".._spec] == true do
				SetEntityCoords(playerPed, targetpos.x, targetpos.y, targetpos.z - 25.0, 0.0, 0.0, 0.0, false)
				SetEntityHealth(playerPed, 200)
				SetEntityVisible(playerPed, false, 0)
	
				if DoesEntityExist(targetPed) then
					targetpos = GetEntityCoords(targetPed)
					local _name   = _targetinfo.name
					local _id 	  = _targetinfo.source
					local _health = GetEntityHealth(targetPed)
					local _armour = GetPedArmour(targetPed)
	
					if (_health > 200) then
						_health = _health .. " ~s~(health appears high when dead)"
					end
	
					drawTxt_spec(0.51, 0.83, 1.0, 1.0, 0.45, "Name: ~b~".._name, 200, 200, 200, 255)
					drawTxt_spec(0.51, 0.86, 1.0, 1.0, 0.45, "Id: ~b~".._id, 200, 200, 200, 255)
					drawTxt_spec(0.51, 0.90, 1.0, 1.0, 0.45, "Health: ~b~".._health, 200, 200, 200, 255)
					drawTxt_spec(0.51, 0.93, 1.0, 1.0, 0.45, "Armour: ~b~".._armour, 200, 200, 200, 255)
				end
	
				Wait(1)
			end
		end)
	--end
end

function resetNormalCamera()
	NetworkSetInSpectatorMode(false)
	InSpectatorMode = false
	spectating["source_"..TargetSpectate] = false
	TargetSpectate  = -1	

	local playerPed = GetPlayerPed(-1)
	Wait(500)
	if LastSpecPosition then
		SetEntityCoords(playerPed, LastSpecPosition.x, LastSpecPosition.y, LastSpecPosition.z - 0.95, 0.0, 0.0, 0.0, false)
		LastSpecPosition = nil
	end
	SetEntityInvincible(playerPed, false)
	SetEntityVisible(playerPed, true, 0)
end

function getNextPlayer(previous_player)
	local temp_list = playerList
	table.sort(temp_list, function(a,b) return a.source < b.source end)

	for i=1, #temp_list, 1 do
		if (temp_list[i].source == TargetSpectate) then
			if (previous_player) then
				if (i ~= 1) then
					return temp_list[i-1]
				else
					return -1
				end
			else
				if (i ~= #temp_list) then
					return temp_list[i+1]
				else
					return -1
				end
			end
		end
	end

	return -1
end

function SpectateNext()
	local _target = getNextPlayer(false)
	if (_target ~= -1) then
		ESX.ShowNotification("Now spectating ".._target.source.." (".._target.name..")")
		spectating["source_"..TargetSpectate] = false
		spectate(_target, vector3(_target.coords[1], _target.coords[2], _target.coords[3]), true)
	end
end

function SpectatePrevious()
	local _target = getNextPlayer(true)
	if (_target ~= -1) then
		ESX.ShowNotification("Now spectating ".._target.source.." (".._target.name..")")
		spectating["source_"..TargetSpectate] = false
		spectate(_target, vector3(_target.coords[1], _target.coords[2], _target.coords[3]), true)
	end
end

Citizen.CreateThread(function()
  	while true do

		Wait(0)

		if InSpectatorMode then
			if IsControlJustPressed(0, 108) then
				-- Previous Player
				SpectatePrevious()
			end

			if IsControlJustPressed(0, 109) then
				-- Next Player
				SpectateNext()
			end

			if IsControlJustPressed(0, 110) then				
				resetNormalCamera()
			end
		end

  	end


end)