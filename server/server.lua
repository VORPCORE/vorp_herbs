local VorpCore = exports.vorp_core:GetCore()

RegisterServerEvent("vorp_herbs:GiveReward")
AddEventHandler("vorp_herbs:GiveReward", function(destination)
    local _source = source
    local coords = GetEntityCoords(GetPlayerPed(_source))
    local dist = #(coords - destination.coords)
    local newTable = {}

    if dist <= 2.5 then
        local allItemsCanBeCarried = true
        local itemsToCheck = {}

        if destination.reward and type(destination.reward) == "table" then
            for _, item in ipairs(destination.reward) do
                local rewardAmount = 1
                if destination.minReward and destination.maxReward then
                    rewardAmount = math.random(destination.minReward, destination.maxReward)
                end
                table.insert(itemsToCheck, { name = item, count = rewardAmount })
            end
        end

        for _, itemInfo in ipairs(itemsToCheck) do
            local canCarryItem = exports.vorp_inventory:canCarryItem(_source, itemInfo.name, itemInfo.count)
            local canCarryItems = exports.vorp_inventory:canCarryItems(_source, itemsToCheck)

            if not canCarryItem or not canCarryItems then
                allItemsCanBeCarried = false
                break
            end
        end

        if allItemsCanBeCarried then
            for _, itemInfo in ipairs(itemsToCheck) do
                exports.vorp_inventory:addItem(_source, itemInfo.name, itemInfo.count)
                table.insert(newTable, itemInfo)
            end
            TriggerClientEvent("vorp_herbs:VerifyPickup", _source, true, newTable, destination)
            newTable = {}
        else
            VorpCore.NotifyRightTip(_source, Config.Language.NoRoomForItems, 4000)
            TriggerClientEvent("vorp_herbs:VerifyPickup", _source, false, {}, destination)
        end
    else
        VorpCore.NotifyRightTip(_source, Config.Language.TooFarFromPlant, 4000)
        TriggerClientEvent("vorp_herbs:VerifyPickup", _source, false, {}, destination)
    end
end)
