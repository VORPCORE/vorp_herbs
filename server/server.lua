local Lib <const> = Import "/config"
local Config <const> = Lib.Config --[[@as vorp_herbs_config]]
local Core <const> = exports.vorp_core:GetCore()
local CoordsLooted <const> = {}
local PropsLooted <const> = {}

local function coordsKey(coords)
    return string.format("%.3f_%.3f_%.3f", coords.x, coords.y, coords.z)
end

Core.Callback.Register("vorp_herbs:CheckItemsCapacity", function(source, callback, key, plantCoords, isProp)
    local _source = source
    local itemsToGive <const> = {}

    local value <const> = Config.Plants[key]
    if not value then
        return callback(false)
    end

    if isProp then
        local propKey <const> = coordsKey(plantCoords)
        if PropsLooted[propKey] then
            return callback(false, true)
        end
    else
        if CoordsLooted[key] then
            return callback(false, true)
        end
    end

    local rewardAmount <const> = math.random(value.minReward, value.maxReward)
    for _, rewardItem in ipairs(value.reward) do
        local canCarryItem <const> = exports.vorp_inventory:canCarryItem(_source, rewardItem, rewardAmount)
        if canCarryItem then
            local iteminfo <const> = exports.vorp_inventory:getItemDB(rewardItem)
            table.insert(itemsToGive, { name = rewardItem, count = rewardAmount, label = iteminfo.label })
        end
    end

    if #itemsToGive > 0 then
        for _, item in ipairs(itemsToGive) do
            local canCarryItem <const> = exports.vorp_inventory:canCarryItem(_source, item.name, item.count)
            if canCarryItem then
                exports.vorp_inventory:addItem(_source, item.name, item.count)
                Core.NotifyRightTip(_source, Config.Language.yougot .. item.count .. "x " .. item.label, 4000)
            else
                Core.NotifyRightTip(_source, Config.Language.noenoughspace, 4000)
            end
        end
        table.wipe(itemsToGive)
        if isProp then
            local propKey <const> = coordsKey(plantCoords)
            PropsLooted[propKey] = true
            SetTimeout(value.cooldown * 60000, function()
                PropsLooted[propKey] = nil
            end)
        else
            CoordsLooted[key] = true
            SetTimeout(value.cooldown * 60000, function()
                CoordsLooted[key] = nil
            end)
        end
        return callback(true)
    end

    return callback(false)
end)
