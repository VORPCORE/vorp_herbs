local LIB <const> = Import({ "/config", "entities", "prompts" })
local Config <const> = LIB.Config --[[@as vorp_herbs_config]]
local Core <const> = exports.vorp_core:GetCore()
local Object <const> = LIB.Object   ---[[@as ENTITIES]]
local Prompts <const> = LIB.Prompts ---[[@as PROMPTS]]
local isPicking = false
local PLAYER_IS_DEAD = false

local function PlayerPick(index, plantCoords, isProp)
    if not isPicking then
        isPicking = true
        Core.Callback.TriggerAsync("vorp_herbs:CheckItemsCapacity", function(canCarryAll, looted)
            if canCarryAll then
                local ped <const> = PlayerPedId()
                TaskTurnPedToFaceCoord(ped, plantCoords.x, plantCoords.y, plantCoords.z, -1)
                Wait(2000)
                ClearPedTasks(ped)
                local dict = "mech_ransack@shelf@h150cm@d80cm@reach_up@pickup@vertical@right_50cm@a"
                RequestAnimDict(dict)
                repeat Wait(0) until HasAnimDictLoaded(dict)
                TaskPlayAnim(ped, dict, "enter_rf", 8.0, 8.0, -1, 1, 0, false, false, false)
                TaskPlayAnim(ped, dict, "base", 8.0, 8.0, -1, 1, 0, false, false, false)
                Wait(700)
                ClearPedTasks(ped)
                RemoveAnimDict(dict)
            elseif not canCarryAll and looted then
                Core.NotifyRightTip(Config.Language.cantpick, 4000)
            elseif not canCarryAll then
                Core.NotifyRightTip(Config.Language.NoRoomForItems, 4000)
            end
            Wait(1000)
            isPicking = false
        end, index, plantCoords, isProp)
    end
end

local function getObject(plantModel)
    local gamePool <const> = GetGamePool("CObject")
    local plantEntity = 0
    local distance = math.huge
    for _, object in ipairs(gamePool) do
        if GetEntityModel(object) == plantModel then
            local objectDistance <const> = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(object))
            if objectDistance < distance then
                distance = objectDistance
                plantEntity = object
            end
        end
    end
    return plantEntity
end

local function createPlant(v)
    return Object:Create({
        Model = v.plantModel,
        Pos = v.coords,
        Options = { PlaceOnGround = true },
    })
end

local function createPrompt(v, index, isProp, coords)
    return Prompts:Register({
        locations = { { coords = coords, label = v.name, distance = 2.0 } },
        prompts = { { type = 'Hold', key = Config.ControlAction, label = Config.Language.PromptText, mode = 'Hold', holdTime = 3000 } },
        sleep = 700,
    }, function()
        if not isPicking then
            PlayerPick(index, coords, isProp)
        end
    end, true)
end

-- creates models or uses just location
CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession

    while true do
        local sleep = 1000

        if not PLAYER_IS_DEAD then
            local ped <const> = PlayerPedId()
            local pedCoords <const> = GetEntityCoords(ped)
            for k, v in ipairs(Config.Plants) do
                -- is location for prop or no prop spawn
                if v.coords and v.islocation then
                    local distance <const> = #(pedCoords - v.coords)
                    if distance and distance <= 100 then
                        if not v.plant and v.placeprop and v.plantModel then
                            v.plant = createPlant(v)
                        end

                        if not v.prompt then
                            v.prompt = createPrompt(v, k, false, v.coords)
                        end
                    else
                        if v.plant then
                            v.plant:Delete()
                            v.plant = nil
                        end
                        if v.prompt then
                            v.prompt:Destroy()
                            v.prompt = nil
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)


CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession

    while true do
        local sleep = 1000

        if not PLAYER_IS_DEAD then
            local ped <const> = PlayerPedId()
            local pedCoords <const> = GetEntityCoords(ped)

            for k, v in ipairs(Config.Plants) do
                -- only for finding world props
                if not v.placeprop and not v.islocation and v.plantModel then
                    local plantModel <const> = GetHashKey(v.plantModel)
                    local plantEntity = 0
                    local plantDetected <const> = DoesObjectOfTypeExistAtCoords(pedCoords.x, pedCoords.y, pedCoords.z, 2.0, plantModel, false)
                    if not isPicking and plantDetected == 1 then
                        if not v.prompt1 then
                            plantEntity = GetClosestObjectOfType(pedCoords.x, pedCoords.y, pedCoords.z, 2.5, plantModel, false, false, false)
                            -- if plantEntity is 0, get the object from the game pool the native is failing to get this object somehow
                            if plantEntity == 0 then
                                plantEntity = getObject(plantModel)
                            end

                            if plantEntity > 0 and DoesEntityExist(plantEntity) then
                                local plantCoords <const> = GetEntityCoords(plantEntity)
                                v.prompt1 = createPrompt(v, k, true, plantCoords)
                            end
                        end
                    end

                    if plantEntity > 0 and DoesEntityExist(plantEntity) then
                        local distance <const> = #(pedCoords - GetEntityCoords(plantEntity))
                        if distance > 2.0 then
                            if v.prompt1 then
                                v.prompt1:Destroy()
                                v.prompt1 = nil
                                plantEntity = 0
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)


AddEventHandler("vorp_core:Client:OnPlayerDeath", function()
    PLAYER_IS_DEAD = true
end)

RegisterNetEvent("vorp_core:Client:OnPlayerRevive", function()
    PLAYER_IS_DEAD = false
end)
