local storage = {}

function storage.on_init()
    global.storage = global.storage or {} ---@type table<string, int>
end

---@param event EventData.on_built_entity
function storage.on_ghost_placed(event)
    storage.add_items(event.created_entity.ghost_prototype.items_to_place_this, 1)
end

---@param event EventData.on_marked_for_deconstruction
function storage.on_marked_for_deconstruction(event)
    storage.add_items(event.entity.prototype.items_to_place_this, 1)
end

---@param items ItemStackDefinition[]
---@param multiplier int
function storage.add_items(items, multiplier)
    if items == nil then
        return
    end

    for _, item in ipairs(items) do
        local name, count
        name = item.name
        count = item.count or 1
        global.storage[name] = global.storage[name] or 0
        global.storage[name] = global.storage[name] + count * multiplier
    end
end

return storage
