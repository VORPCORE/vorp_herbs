local VorpCore = exports.vorp_core:GetCore()
local isPicking = false
local Prompt
local Group = GetRandomIntInRange(0, 0xffffff)
local GroupName
local usedPoints = {}
local processedPlants = {}
local plantCoords = nil



local function contains(table, element)
	if table ~= 0 then
		for k, v in pairs(table) do
			if v == element then
				return true
			end
		end
	end
	return false
end

local function roundCoords(coords, decimal)
	local multiplier = 10 ^ decimal
	local x = math.floor(coords.x * multiplier + 0.5) / multiplier
	local y = math.floor(coords.y * multiplier + 0.5) / multiplier
	local z = math.floor(coords.z * multiplier + 0.5) / multiplier
	return vec3(x, y, z)
end

local function isUsedNode(coords)
	return contains(usedPoints, roundCoords(coords, 2))
end

local function GetArrayKey(array, value)
	for k, v in pairs(array) do
		if v == value then
			return k
		end
	end
end

local function CreateVarString(p0, p1, variadic)
	return Citizen.InvokeNative(0xFA925AC00EB830B9, p0, p1, variadic, Citizen.ResultAsLong())
end

local function CreatePickPrompt(promptText, controlAction)
	local str = promptText
	Prompt = PromptRegisterBegin()
	PromptSetControlAction(Prompt, controlAction)
	str = CreateVarString(10, "LITERAL_STRING", str)
	PromptSetText(Prompt, str)
	PromptSetEnabled(Prompt, false)
	PromptSetVisible(Prompt, false)
	PromptSetHoldMode(Prompt, 1000)
	PromptSetGroup(Prompt, Group)
	PromptRegisterEnd(Prompt)
end

local function PlayerPick(destination)
	if destination then
		table.insert(usedPoints, roundCoords(destination.coords, 2))
		local ped = PlayerPedId()
		TaskTurnPedToFaceCoord(ped, destination.coords, -1)
		Wait(2000)
		ClearPedTasks(ped)
		local dict = "mech_ransack@shelf@h150cm@d80cm@reach_up@pickup@vertical@right_50cm@a"
		RequestAnimDict(dict)
		while not HasAnimDictLoaded(dict) do
			Wait(0)
		end
		TaskPlayAnim(ped, dict, "enter_rf", 8.0, 8.0, -1, 1, 0, false, false, false)
		TaskPlayAnim(ped, dict, "base", 8.0, 8.0, -1, 1, 0, false, false, false)
		RemoveAnimDict(dict)
		Wait(700)
		ClearPedTasks(ped)

		TriggerServerEvent("vorp_herbs:GiveReward", destination)
	end
end

local function formatItemsList(items)
	local itemList = ""
	for _, itemInfo in ipairs(items) do
		if itemList ~= "" then
			itemList = itemList .. ", "
		end
		itemList = itemList .. itemInfo.count .. " " .. itemInfo.name
	end
	return itemList
end

RegisterNetEvent("vorp_herbs:VerifyPickup")
AddEventHandler("vorp_herbs:VerifyPickup", function(success, items, location)
	local timeout = location.timeout or Config.Timeout
	local coords = roundCoords(location.coords, 2)
	local key = GetArrayKey(usedPoints, coords)
	if success then
		if timeout > 0 then
			isPicking = false
			VorpCore.NotifyRightTip(Config.Language.ItemsReceived .. formatItemsList(items), 4000)
			CreateThread(function()
				Wait(timeout * 60000)
				local removeKey = GetArrayKey(usedPoints, coords)
				if removeKey then
					table.remove(usedPoints, removeKey)
					processedPlants[coords] = nil
				else
					print(Config.Language.NoEntryFound)
				end
			end)
		else
			isPicking = false
			if key then
				table.remove(usedPoints, key)
				processedPlants[coords] = nil
			else
				print(Config.Language.NoEntryFound)
			end
		end
	else
		isPicking = false
		if key then
			table.remove(usedPoints, key)
		else
			print(Config.Language.NoEntryFound)
		end
		processedPlants[coords] = nil
	end
end)

local function CreatePlant(destination)
	if not DoesEntityExist(destination.plant) and not isUsedNode(destination.coords) then
		local plantModel = joaat(destination.plantModel)
		RequestModel(plantModel)
		while not HasModelLoaded(plantModel) do
			Citizen.Wait(0)
		end
		local plantModelObject = CreateObject(plantModel, destination.coords.x, destination.coords.y,
			destination.coords.z, true, true, true)
		Wait(500)
		Citizen.InvokeNative(0x9587913B9E772D29, plantModelObject, true)
		SetEntityAsMissionEntity(plantModelObject, true, true)
		destination.plant = plantModelObject
	end
end

CreateThread(function()
	CreatePickPrompt(Config.Language.PromptText, Config.ControlAction)

	while true do
		Wait(1000)

		local ped = PlayerPedId()
		local pedCoords = GetEntityCoords(ped)

		for k, v in pairs(Config.Locations) do
			local roundedCoords = roundCoords(v.coords, 2)
			if v.plantModel and GetDistanceBetweenCoords(pedCoords, roundedCoords) < 100 then
				if not DoesEntityExist(v.plant) and Citizen.InvokeNative(0xDA8B2EAF29E872E2, roundedCoords) then
					CreatePlant(v)
					Wait(250)
					if GetEntityHeightAboveGround(v.plant) > 0.0 then
						Citizen.InvokeNative(0x9587913B9E772D29, v.plant, true)
					end
				end
			end
			while GetDistanceBetweenCoords(pedCoords, roundedCoords) <= Config.MinimumDistance and not isPicking and not isUsedNode(roundedCoords) and not processedPlants[roundedCoords] and v.reward do
				Wait(1)
				pedCoords = GetEntityCoords(ped)
				GroupName = Config.Language.PromptGroupName .. " - " .. v.name
				GroupName = CreateVarString(10, "LITERAL_STRING", GroupName)
				PromptSetActiveGroupThisFrame(Group, GroupName)
				PromptSetEnabled(Prompt, true)
				PromptSetVisible(Prompt, true)

				if not processedPlants[roundedCoords] then
					if PromptHasHoldModeCompleted(Prompt) then
						isPicking = true
						plantCoords = roundedCoords
						PlayerPick(v)
						processedPlants[plantCoords] = true
					end
				end
			end

			while GetDistanceBetweenCoords(pedCoords, roundedCoords) <= Config.MinimumDistance and not isPicking and isUsedNode(roundedCoords) do
				Wait(1)
				pedCoords = GetEntityCoords(ped)
				GroupName = Config.Language.PromptGroupName .. " - " .. v.name
				GroupName = CreateVarString(10, "LITERAL_STRING", GroupName)
				PromptSetActiveGroupThisFrame(Group, GroupName)
				PromptSetEnabled(Prompt, false)
				PromptSetVisible(Prompt, Config.ShowUsedNodePrompt)
			end
		end

		local itemSet = CreateItemset(true)
		local size = Citizen.InvokeNative(0x59B57C4B06531E1E, GetEntityCoords(PlayerPedId()), Config.MinimumDistance,
			itemSet, 3, Citizen.ResultAsInteger())

		if size > 0 then
			for index = 0, size do
				local entity = GetIndexedItemInItemset(index, itemSet)
				local coords = roundCoords(GetEntityCoords(entity), 2)
				local model_hash = GetEntityModel(entity)

				for k, plant in ipairs(Config.Plants) do
					local pedCoords = GetEntityCoords(PlayerPedId())
					while plant.hash == model_hash and not isUsedNode(coords) and GetDistanceBetweenCoords(pedCoords, coords) < Config.MinimumDistance and plant.reward do
						Wait(1)
						pedCoords = GetEntityCoords(PlayerPedId())
						GroupName = Config.Language.PromptGroupName .. " - " .. plant.name
						GroupName = CreateVarString(10, "LITERAL_STRING", GroupName)
						PromptSetActiveGroupThisFrame(Group, GroupName)
						PromptSetEnabled(Prompt, true)
						PromptSetVisible(Prompt, true)

						local plantModelInLocations = false
						local locationData = nil
						for _, location in pairs(Config.Locations) do
							if location.plantModel == plant.hash then
								plantModelInLocations = true
								locationData = location
								break
							end
						end

						if plantModelInLocations and locationData then
							-- Use the reward from location configuration
							if not processedPlants[coords] then
								if PromptHasHoldModeCompleted(Prompt) then
									isPicking = true
									local rewardData = {
										coords = coords,
										reward = locationData.reward,
										name = locationData.name,
										minReward = locationData.minReward or plant.minReward or 0,
										maxReward = locationData.maxReward or plant.maxReward or 0
									}
									PlayerPick(rewardData)
									processedPlants[coords] = true 
								end
							end
						else
							-- Use the plant-specific reward if not in locations
							if not processedPlants[coords] and plant.reward then
								if PromptHasHoldModeCompleted(Prompt) then
									isPicking = true
									local fakeDestination = {
										coords = coords,
										reward = plant.reward,
										name = plant.name,
										minReward = plant.minReward or 0,
										maxReward = plant.maxReward or 0
									}
									PlayerPick(fakeDestination)
									processedPlants[coords] = true 
								end
							end
						end
					end

					while plant.hash == model_hash and isUsedNode(coords) and GetDistanceBetweenCoords(pedCoords, coords) < Config.MinimumDistance do
						Wait(1)
						pedCoords = GetEntityCoords(PlayerPedId())
						GroupName = Config.Language.PromptGroupName .. " - " .. plant.name
						GroupName = CreateVarString(10, "LITERAL_STRING", GroupName)
						PromptSetActiveGroupThisFrame(Group, GroupName)
						PromptSetEnabled(Prompt, false)
						PromptSetVisible(Prompt, Config.ShowUsedNodePrompt)
					end
				end
			end
		end

		if IsItemsetValid(itemSet) then
			DestroyItemset(itemSet)
		end
	end
end)
