local flib_position = require("__flib__.position")

local stations = {}

function stations.on_init()
    global.stations = {} ---@type LuaEntity[]
end

---@param event EventData.on_built_entity
function stations.on_built(event)
    table.insert(global.stations, event.created_entity)
end

---@return uint
function stations.count()
    return #global.stations --[[@as uint]]
end

---@param position MapPosition
---@return LuaEntity?
function stations.find_closest_to(position)
    local closest = nil
    local min = math.huge
    local id = 1
    while id <= stations.count() do
        local station = global.stations[id]
        if not station.valid then
            global.stations[id] = global.stations[stations.count()]
            table.remove(global.stations)

            goto continue
        end

        local dist = flib_position.distance(position, station.position)
        if dist < min then
            closest = station
            min = dist
        end

        id = id + 1
        ::continue::
    end

    return closest
end

return stations
