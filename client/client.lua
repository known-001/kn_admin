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
	ESX.TriggerServerCallback('kn:admin:isAllowed', function(result) 
		print(result)
		if result ~= 'user' then
			group = result
			ESX.TriggerServerCallback('kn:admin:getPlayers', function(allPlayers, total, bans)
				SetNuiFocus(true, true)
				SendNUIMessage({type = 'open', players = allPlayers, total = total, bans = bans})
			end)
		end
	end)
end)

RegisterCommand('ar', function(source, args)
	if checkDuty('repairCar') then
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
	if checkDuty('kick') then
		TriggerServerEvent('kn:admin:kick', data.user, data.param, GetPlayerName(data.user))
	end
end)

RegisterNUICallback('ban', function(data, cb)
	if checkDuty('ban') then
		TriggerServerEvent('kn:admin:ban', data.user, data.param, data.length, true)
	end
end)

RegisterNUICallback('ban-offline', function(data, cb)
	if checkDuty('ban') then
		TriggerServerEvent('kn:admin:ban', data.user, data.param, data.length, false)
	end
end)

RegisterNUICallback('quick', function(data, cb)
	if checkDuty(data.type) then
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
		if checkDuty('noclip') then
			toggleNoclip()
			clip = true
		end
	end
end)

function checkDuty(type)
	if Config.Duty.requireAll then
		for k,v in pairs(Config.Duty) do
			if type == k then
				if not v then
					return true
				elseif v and onduty then
					return true
				else
					TriggerEvent("pNotify:SendNotification",{
						text = "<h2>Admin Notification</h2>" .. "<h1>ADMIN:</h1>" .. "<p>You must be out of roleplay!</p>",
						type = "success",
						timeout = (1000),
						layout = "centerLeft",
						queue = "global"
					})
					return false
				end
			end
		end
	else
		return true
	end
end
