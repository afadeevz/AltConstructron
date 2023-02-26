local storage = {}

function storage.on_init()
    storage.reset()
end

function storage.reset()
    global.storage = {} ---@type table<string, int>
end

function storage.info()
    game.print("Storage:")
    for name, value in pairs(global.storage) do
        game.print(name .. " = " .. value)
    end
end

---@param item string
---@param count int
function storage.add(item, count)
    global.storage[item] = global.storage[item] or 0
    global.storage[item] = global.storage[item] + count
    -- game.print("Storage[" .. item .. "] = " .. global.storage[item])
end

---@param item string
---@param count int
function storage.trash(item, count)
    global.storage[item] = global.storage[item] or 0
    global.storage[item] = math.max(0, global.storage[item] - count)
    -- game.print("Storage[" .. item .. "] = " .. global.storage[item])
end

---@param item string
---@return int
function storage.get(item)
    return global.storage[item] or 0
end

---@param event EventData.on_built_entity
function storage.on_ghost_placed(event)
    local entity = event.created_entity
    storage.add_stacks(entity.ghost_prototype.items_to_place_this, -1)
    if entity.ghost_type ~= 'tile' then
        storage.add_items(entity.item_requests, -1)
    end
end

---@param tile LuaTile
function storage.on_tile_marked_for_deconstruction(tile)
    storage.add_stacks(tile.prototype.items_to_place_this, 1)
end

---@param event EventData.on_marked_for_deconstruction
function storage.on_marked_for_deconstruction(event)
    local entity = event.entity
    storage.add_stacks(entity.prototype.items_to_place_this, 1)

    for inv_id = 1, 8 do
        local inv = entity.get_inventory(inv_id)
        if not inv then
            goto continue
        end

        storage.add_items(inv.get_contents(), 1)
        ::continue::
    end
end

---@param event EventData.on_pre_ghost_deconstructed
function storage.on_request_proxy_deconstructed(event)
    for name, count in pairs(event.ghost.item_requests) do
        storage.add_items(event.ghost.item_requests, 1)
    end
end

---@param event EventData.on_pre_ghost_deconstructed
function storage.on_ghost_deconstructed(event)
    storage.add_stacks(event.ghost.ghost_prototype.items_to_place_this, 1)
end

---@param stacks ItemStackDefinition[]
---@param multiplier int
function storage.add_stacks(stacks, multiplier)
    if stacks == nil then
        return
    end

    for _, item in ipairs(stacks) do
        local name, count
        name = item.name
        count = item.count or 1
        storage.add(name, count * multiplier)
    end
end

---@param items table<string, uint>
---@param multiplier int
function storage.add_items(items, multiplier)
    for item, count in pairs(items) do
        storage.add(item, count * multiplier)
    end
end

return storage
