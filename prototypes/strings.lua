local prefix = "alt-constructron-"

---@param str string
---@return string
local function with_prefix(str)
    return prefix .. str
end

---@type table<string, string>
local strings = {
    -- Own
    worker = with_prefix("worker"),
    station = with_prefix("station"),
    technology = with_prefix("technology"),

    -- Commonly Used
    entity_ghost = "entity-ghost",
    tile_ghost = "tile-ghost",
    construction_robot = "construction-robot",
}

return strings
