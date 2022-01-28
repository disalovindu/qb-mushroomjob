QBCore = nil
local QBCore = exports['qb-core']:GetCoreObject()
isLoggedIn = true

local menuOpen = false
local wasOpen = false

Citizen.CreateThread(function() 
    while true do
        Citizen.Wait(10)
        if QBCore == nil then
            TriggerEvent("QBCore:GetObject", function(obj) QBCore = obj end)    
            Citizen.Wait(200)
        end
    end
end)

local spawnedWeed = 0
local weedPlants = {}

local isPickingUp, isProcessing, isProcessing2 = false, false, false

RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
	CheckCoords2()
	Citizen.Wait(1000)
	local coords = GetEntityCoords(PlayerPedId())
	if GetDistanceBetweenCoords(coords, Config.CircleZones.MushroomField.coords, true) < 1000 then
		SpawnWeedPlants2()
	end
end)

function CheckCoords2()
	Citizen.CreateThread(function()
		while true do
			local coords = GetEntityCoords(PlayerPedId())
			if GetDistanceBetweenCoords(coords, Config.CircleZones.MushroomField.coords, true) < 1000 then
				SpawnWeedPlants2()
			end
			Citizen.Wait(1 * 60000)
		end
	end)
end

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		CheckCoords2()
	end
end)
Citizen.CreateThread(function()--weed
	while true do
		Citizen.Wait(0)

		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local nearbyObject, nearbyID
		
		
		for i=1, #weedPlants, 1 do
			if GetDistanceBetweenCoords(coords, GetEntityCoords(weedPlants[i]), false) < 1 then
				nearbyObject, nearbyID = weedPlants[i], i
			end
		end

		if nearbyObject and IsPedOnFoot(playerPed) then

			if not isPickingUp then
				QBCore.Functions.Draw2DText(0.5, 0.88, 'Press ~g~[E]~w~ to Pick up Mushroom ', 0.4)
			end

			if IsControlJustReleased(0, 38) and not isPickingUp then
				isPickingUp = true
				TaskStartScenarioInPlace(playerPed, 'world_human_gardener_plant', 0, false)
				--PROP_HUMAN_BUM_BIN animazione
				--prop_cs_cardbox_01 oggetto di spawn  prop_plant_01a
				QBCore.Functions.Progressbar("search_register", "Picking Up Mushroom..", 6500, false, true, {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
					disableInventory = true,
				}, {}, {}, {}, function() -- Done
					ClearPedTasks(GetPlayerPed(-1))
					QBCore.Functions.DeleteObject(nearbyObject)

					table.remove(weedPlants, nearbyID)
					spawnedWeed = spawnedWeed - 1

					TriggerServerEvent('qb-mushroomjob:pickedUpMushroom')
				end, function()
					ClearPedTasks(GetPlayerPed(-1))
				end) -- Cancel

				isPickingUp = false
			end
		else
			Citizen.Wait(500)
		end
	end
end)


AddEventHandler('onResourceStop', function(resource) --weedPlants
	if resource == GetCurrentResourceName() then
		for k, v in pairs(weedPlants) do
			QBCore.Functions.DeleteObject(v)
		end
	end
end)
function SpawnWeedPlants2() --This spawns in the Weed plants, 
	while spawnedWeed < 20 do
		Citizen.Wait(1)
		local weedCoords = GenerateWeedCoords2()
--prop_barrel_01a  prop_plant_01a
		QBCore.Functions.SpawnLocalObject('prop_stoneshroom1', weedCoords, function(obj) --- change this prop to whatever plant you are trying to use 
			PlaceObjectOnGroundProperly(obj)
			FreezeEntityPosition(obj, true)
			

			table.insert(weedPlants, obj)
			spawnedWeed = spawnedWeed + 1
		end)
	end
	Citizen.Wait(45 * 60000)
end


function ValidateWeedCoord(plantCoord) --This is a simple validation checker
	if spawnedWeed > 0 then
		local validate = true

		for k, v in pairs(weedPlants) do
			if GetDistanceBetweenCoords(plantCoord, GetEntityCoords(v), true) < 5 then
				validate = false
			end
		end

		if GetDistanceBetweenCoords(plantCoord, Config.CircleZones.MushroomField.coords, false) > 50 then
			validate = false
		end

		return validate
	else
		return true
	end
end

function GenerateWeedCoords2() --This spawns the weed plants at the designated location
	while true do
		Citizen.Wait(1)

		local weedCoordX, weedCoordY

		math.randomseed(GetGameTimer())
		local modX = math.random(-10, 10)

		Citizen.Wait(100)

		math.randomseed(GetGameTimer())
		local modY = math.random(-10, 10)

		weedCoordX = Config.CircleZones.MushroomField.coords.x + modX
		weedCoordY = Config.CircleZones.MushroomField.coords.y + modY

		local coordZ = GetCoordZWeed(weedCoordX, weedCoordY)
		local coord = vector3(weedCoordX, weedCoordY, coordZ)

		if ValidateWeedCoord(coord) then
			return coord
		end
	end
end

function GetCoordZWeed(x, y) ---- Set the coordinates relative to the heights near where you want the circle spawning
	local groundCheckHeights = { 31.0, 32.0, 33.0, 34.0, 35.0, 36.0, 37.0, 38.0, 39.0, 40.0, 50.0 }

	for i, height in ipairs(groundCheckHeights) do
		local foundGround, z = GetGroundZFor_3dCoord(x, y, height)

		if foundGround then
			return z
		end
	end

	return 31.85
end

Citizen.CreateThread(function() --- check that makes sure you have the materials needed to process
	while QBCore == nil do
		Citizen.Wait(200)
	end
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)

		if GetDistanceBetweenCoords(coords, Config.CircleZones.MakeStew.coords, true) < 1 then
			DrawMarker(2, Config.CircleZones.MakeStew.coords.x, Config.CircleZones.MakeStew.coords.y, Config.CircleZones.MakeStew.coords.z - 0.2 , 0, 0, 0, 0, 0, 0, 0.3, 0.2, 0.15, 255, 0, 0, 100, 0, 0, 0, true, 0, 0, 0)

			
			if not isProcessing then
				QBCore.Functions.DrawText3D(Config.CircleZones.MakeStew.coords.x, Config.CircleZones.MakeStew.coords.y, Config.CircleZones.MakeStew.coords.z, 'Press ~g~[ E ]~w~ to Make Mushroom Stew')
			end

			if IsControlJustReleased(0, 38) and not isProcessing then
				local s1 = false
				local hasWeed = false

				QBCore.Functions.TriggerCallback('QBCore:HasItem', function(result)
					hasWeed = result
					s1 = true
				end, 'mushroom')
				
				while(not s1) do
					Citizen.Wait(100)
				end

				if (hasWeed) then
					Processweed3()
				elseif (hasWeed) then
					QBCore.Functions.Notify('You dont have Mushroom.', 'error')
				end
			end
		else
			Citizen.Wait(500)
		end
	end
end)


function Processweed3()  -- simple animations to loop while process is taking place
	isProcessing = true
	local playerPed = PlayerPedId()

	--
	TaskStartScenarioInPlace(playerPed, "CODE_HUMAN_MEDIC_TEND_TO_DEAD", 0, true)
	SetEntityHeading(PlayerPedId(), 108.06254)

	QBCore.Functions.Progressbar("search_register", "Making Mushroom Stew..", 15000, false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
		disableInventory = true,
	}, {}, {}, {}, function()
	 TriggerServerEvent('qb-mushroomjob:MakeStew') -- Done

		local timeLeft = Config.Delays.MakeStew / 1000

		while timeLeft > 0 do
			Citizen.Wait(1000)
			timeLeft = timeLeft - 1

			if GetDistanceBetweenCoords(GetEntityCoords(playerPed), Config.CircleZones.MakeStew.coords, false) > 4 then
				TriggerServerEvent('qb-mushroomjob:cancelProcessing3')
				break
			end
		end
		ClearPedTasks(GetPlayerPed(-1))
	end, function()
		ClearPedTasks(GetPlayerPed(-1))
	end) -- Cancel
		
	
	isProcessing = false
end


Citizen.CreateThread(function() --- check that makes sure you have the materials needed to process
	while QBCore == nil do
		Citizen.Wait(200)
	end
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)

		if GetDistanceBetweenCoords(coords, Config.CircleZones.SellStew.coords, true) < 1 then
			DrawMarker(2, Config.CircleZones.SellStew.coords.x, Config.CircleZones.SellStew.coords.y, Config.CircleZones.SellStew.coords.z - 0.2 , 0, 0, 0, 0, 0, 0, 0.3, 0.2, 0.15, 255, 0, 0, 100, 0, 0, 0, true, 0, 0, 0)

			
			if not isProcessing2 then
				QBCore.Functions.DrawText3D(Config.CircleZones.SellStew.coords.x, Config.CircleZones.SellStew.coords.y, Config.CircleZones.SellStew.coords.z, 'Press ~g~[ E ]~w~ to Sell')
			end

			if IsControlJustReleased(0, 38) and not isProcessing2 then
	            local s1 = false
				local hasWeed = false

				QBCore.Functions.TriggerCallback('QBCore:HasItem', function(result)
					hasWeed = result
					s1 = true
				end, 'mushroom_stew')
				
				while(not s1) do
					Citizen.Wait(100)
				end

				if (hasWeed) then
					SellDrug3()
				elseif (hasWeed) then
					QBCore.Functions.Notify('You dont have Stew.', 'error')
				end
			end
		else
			Citizen.Wait(500)
		end
	end
end)

function SellDrug3()  -- simple animations to loop while process is taking place
	isProcessing2 = true
	local playerPed = PlayerPedId()

	--
	TaskStartScenarioInPlace(playerPed, "CODE_HUMAN_MEDIC_TEND_TO_DEAD", 0, true)
	SetEntityHeading(PlayerPedId(), 108.06254)

	QBCore.Functions.Progressbar("search_register", "Selling Stew..", 15000, false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
		disableInventory = false,
	}, {}, {}, {}, function()
	 TriggerServerEvent('qb-mushroomjob:selld3') -- Done

		local timeLeft = Config.Delays.MakeStew / 1000

		while timeLeft > 0 do
			Citizen.Wait(500)
			timeLeft = timeLeft - 1

			if GetDistanceBetweenCoords(GetEntityCoords(playerPed), Config.CircleZones.MakeStew.coords, false) > 4 then
				--TriggerServerEvent('qb-mushroomjob:cancelProcessing3')
				break
			end
		end
		ClearPedTasks(GetPlayerPed(-1))
	end, function()
		ClearPedTasks(GetPlayerPed(-1))
	end) -- Cancel
		
	
	isProcessing2 = false
end

--Blips

CreateThread(function()
    -- local blip = AddBlipForCoord(2064.4783, 8316.6768, 41.1036)
    local blip = AddBlipForCoord(Config.CircleZones.MushroomField.coords)
    SetBlipSprite(blip, 270)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, 83)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Mushroom Field")
    EndTextCommandSetBlipName(blip)
end)

CreateThread(function()
    local blip = AddBlipForCoord(Config.CircleZones.MakeStew.coords)
    SetBlipSprite(blip, 270)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, 0.5)
    SetBlipColour(blip, 83)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Make Mushroom Stew")
    EndTextCommandSetBlipName(blip)
end)

CreateThread(function()
    local blip = AddBlipForCoord(Config.CircleZones.SellStew.coords)
    SetBlipSprite(blip, 270)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, 83)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Soup Shop")
    EndTextCommandSetBlipName(blip)
end)
