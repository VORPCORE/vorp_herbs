local VorpCore = exports.vorp_core:GetCore()
local CoordsLooted = {}
local PropsLooted = {}

local function coordsKey(coords)
    return string.format("%.3f_%.3f_%.3f", coords.x, coords.y, coords.z)
end

VorpCore.Callback.Register("vorp_herbs:CheckItemsCapacity",
    function(source, callback, destination, key, plantCoords, isProp)
        local _source = source
        local itemsToGive = {}

        if not key then
            return callback(false)
        end

        if isProp then
            local propKey = coordsKey(plantCoords)
            if PropsLooted[propKey] then
                return callback(false, true)
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
                local iteminfo = exports.vorp_inventory:getItemDB(rewardItem, callback)
                table.insert(itemsToGive, { name = rewardItem, count = rewardAmount, label = iteminfo.label })
            end
        end

        if #itemsToGive > 0 then
            for _, item in ipairs(itemsToGive) do
                exports.vorp_inventory:addItem(_source, item.name, item.count)
                VorpCore.NotifyRightTip(_source, "You got " .. item.count .. "x " .. item.label, 4000)
            end
            table.wipe(itemsToGive)
            if isProp then
                local propKey = coordsKey(plantCoords)
                PropsLooted[propKey] = true
                SetTimeout(destination.cooldown * 60000, function()
                    PropsLooted[propKey] = nil
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
