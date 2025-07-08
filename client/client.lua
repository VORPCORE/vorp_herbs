local VorpCore = exports.vorp_core:GetCore()
local isPicking = false
local Prompt
local Group = GetRandomIntInRange(0, 0xffffff)
local GroupName


local function CreatePickPrompt(promptText, controlAction)
    local str = promptText
    Prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(Prompt, controlAction)
    str = VarString(10, "LITERAL_STRING", str)
    UiPromptSetText(Prompt, str)
    UiPromptSetEnabled(Prompt, false)
    UiPromptSetVisible(Prompt, false)
    UiPromptSetHoldMode(Prompt, 1000)
    UiPromptSetGroup(Prompt, Group, 0)
    UiPromptRegisterEnd(Prompt)
end

local function PlayerPick(destination, index, plantCoords, isProp)
    UiPromptSetEnabled(Prompt, false)
    UiPromptSetVisible(Prompt, false)
    if not isPicking then
        isPicking = true
        VorpCore.Callback.TriggerAsync("vorp_herbs:CheckItemsCapacity", function(canCarryAll, looted)
            if canCarryAll then
                local ped = PlayerPedId()
                TaskTurnPedToFaceCoord(ped, plantCoords.x, plantCoords.y, plantCoords.z, -1)
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
            elseif not canCarryAll and looted then
                VorpCore.NotifyRightTip(Config.Language.cantpick, 4000)
            elseif not canCarryAll then
                VorpCore.NotifyRightTip(Config.Language.NoRoomForItems, 4000)
            end
            Wait(1000)
            isPicking = false
        end, destination, index, plantCoords, isProp)
    end
end

local function CreatePlant(destination, index)
    local plantModel = GetHashKey(destination.plantModel)
    if not HasModelLoaded(plantModel) then
        RequestModel(plantModel, false)
        repeat Wait(0) until HasModelLoaded(plantModel)
    end
    local plantModelObject = CreateObject(plantModel, destination.coords.x, destination.coords.y, destination.coords.z,
        false, false, false)
    repeat Wait(0) until DoesEntityExist(plantModelObject)
    PlaceEntityOnGroundProperly(plantModelObject, false)
    FreezeEntityPosition(plantModelObject, true)
    Config.Plants[index].plant = plantModelObject
end

function GetClosestObject(coords, prophash)
    local ped = PlayerPedId()
    local objects = GetGamePool('CObject')
    local closestDistance = -1
    local closestObject = nil
    coords = coords or GetEntityCoords(ped)

    for i = 1, #objects do
        if GetEntityModel(objects[i]) == prophash then
            local objectCoords = GetEntityCoords(objects[i])
            local distance = #(objectCoords - coords)
            if closestDistance == -1 or closestDistance > distance then
                closestDistance = distance
                closestObject = objects[i]
            end
        end
    end
    return closestObject
end

CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession
    CreatePickPrompt(Config.Language.PromptText, Config.ControlAction)
    local function getDist(pedcoords, coords)
        if not coords then return end
        return #(pedcoords - coords)
    end
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        if not IsEntityDead(ped) then
            for k, v in pairs(Config.Plants) do
                local distance = getDist(pedCoords, v.coords)

                if v.placeprop and v.coords and v.plantModel then
                    if distance and distance <= 100 then
                        if not v.plant then
                            CreatePlant(v, k)
                        end
                    else
                        if v.plant then
                            DeleteEntity(v.plant)
                            v.plant = nil
                        end
                    end
                end

                if v.islocation and v.coords and distance and distance <= Config.MinimumDistance and not isPicking then
                    sleep = 0
                    GroupName = Config.Language.PromptGroupName .. ": " .. (v.name or "Plant")
                    GroupName = VarString(10, "LITERAL_STRING", GroupName)
                    UiPromptSetActiveGroupThisFrame(Group, GroupName, 0, 0, 0, 0)
                    UiPromptSetEnabled(Prompt, true)
                    UiPromptSetVisible(Prompt, true)
                    if UiPromptHasHoldModeCompleted(Prompt) then
                        PlayerPick(v, k, v.coords, false)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession
    CreatePickPrompt(Config.Language.PromptText, Config.ControlAction)
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        if not IsEntityDead(ped) then
            for k, v in pairs(Config.Plants) do
                if not v.placeprop and not v.islocation and v.plantModel then
                    local plantModel = GetHashKey(v.plantModel)
                    local plantDetected = DoesObjectOfTypeExistAtCoords(pedCoords.x, pedCoords.y, pedCoords.z,
                        Config.MinimumDistance, plantModel, false)
                    if not isPicking and plantDetected == 1 then
                        sleep = 0
                        GroupName = Config.Language.PromptGroupName .. ": " .. (v.name or "Plant")
                        GroupName = VarString(10, "LITERAL_STRING", GroupName)
                        UiPromptSetActiveGroupThisFrame(Group, GroupName, 0, 0, 0, 0)
                        UiPromptSetEnabled(Prompt, true)
                        UiPromptSetVisible(Prompt, true)
                        if UiPromptHasHoldModeCompleted(Prompt) then
                            local plantEntity = GetClosestObject(pedCoords, plantModel)
                            if plantEntity then
                                local plantCoords = GetEntityCoords(plantEntity)
                                PlayerPick(v, k, plantCoords, true) 
                            else
                                print("No plant entity found nearby")
                            end
                        end
                        break
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == 'vorp_herbs' then
        for _, v in pairs(Config.Plants) do
            if v.plant then
                DeleteEntity(v.plant)
            end
        end
    end
end)
