local VorpCore = exports.vorp_core:GetCore()
local CoordsLooted = {}
local PropsLooted = {}

VorpCore.Callback.Register("vorp_herbs:CheckItemsCapacity", function(source, callback, destination, key, plantCoords, isProp)
    local _source = source
    local itemsToGive = {}


    if not key then
        return callback(false)
    end

    if isProp then
        for k, v in ipairs(PropsLooted) do
            if v.x == plantCoords.x and v.y == plantCoords.y and v.z == plantCoords.z then 
                return callback(false,true)
            end
        end
    else
        if CoordsLooted[key] then
            return callback(false, true)
        end
    end

    local rewardAmount = math.random(destination.minReward, destination.maxReward)
    for _, rewardItem in ipairs(destination.reward) do
        local canCarryItem = exports.vorp_inventory:canCarryItem(_source, rewardItem, rewardAmount)
        if canCarryItem then
            table.insert(itemsToGive, { name = rewardItem, count = rewardAmount })
        end
    end

    if #itemsToGive > 0 then
        for _, item in ipairs(itemsToGive) do
            exports.vorp_inventory:addItem(_source, item.name, item.count)
            VorpCore.NotifyRightTip(_source, "You got " .. item.count .. "x " .. item.name, 4000)
        end
        table.wipe(itemsToGive)
        if isProp then
            table.insert(PropsLooted, plantCoords)
            SetTimeout(destination.cooldown * 60000, function()
                for i, coords in ipairs(PropsLooted) do
                    if coords.x == plantCoords.x and coords.y == plantCoords.y and coords.z == plantCoords.z then
                        table.remove(PropsLooted, i)
                        break
                    end
                end
            end)
        else
            CoordsLooted[key] = true
            SetTimeout(destination.cooldown * 60000, function()
                CoordsLooted[key] = nil
            end)
        end
        return callback(true)
    end

    return callback(false)
end)