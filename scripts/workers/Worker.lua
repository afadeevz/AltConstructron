local stations = require("scripts.stations")
local jobs = require("scripts.jobs")
local flib_position = require("__flib__.position")
local storage = require("scripts.storage")
local strings = require("prototypes.strings")

local Worker = {}

---@class WorkerState
---@field on_start fun(worker: Worker)
---@field on_tick fun(worker: Worker)
---@field on_end fun(worker: Worker)

--------------------------------------------------------------------------------------------------------------------------------
local Idle = {} ---@type WorkerState

---@param self Worker
function Idle.on_start(self)
end

---@param self Worker
function Idle.on_tick(self)
    if Worker.has_to_wait_for_robots(self) then
        Worker.pause_walking(self)
        return
    else
        Worker.go_home(self)
    end

    if not Worker.has_enough_robots(self) then
        Worker.refill(self)
        return
    end

    local job = jobs.find_close_to(self.entity.position, function(j)
        return Worker.can_take_job(self, j)
    end)
    if job then
        Worker.take_job(self, job)
    elseif jobs.count() > 0 then
        Worker.refill(self)
    else
        Worker.set_state(self, Worker.StatesEnum.Docked)
    end
end

---@param self Worker
function Idle.on_end(self)
end

--------------------------------------------------------------------------------------------------------------------------------
local Work = {} ---@type WorkerState

---@param self Worker
function Work.on_start(self)
end

---@param self Worker
function Work.on_tick(self)
    local job = self.job
    local entity = self.entity

    if not job or not job.entity.valid or not Worker.can_take_job(self, job) then
        Worker.go_home(self)
        Worker.set_state(self, Worker.StatesEnum.Idle)
        return
    end

    local dist = flib_position.distance(entity.position, job.entity.position)
    local cell = entity.logistic_cell
    if (cell.to_charge_robot_count > 0
        or cell.charging_robot_count > 0)
        and dist > cell.construction_radius then
        Worker.pause_walking(self)
    elseif cell.to_charge_robot_count == 0
        and cell.charging_robot_count == 0
        or dist <= cell.construction_radius then
        Worker.jitter(self)
    end
end

---@param self Worker
function Work.on_end(self)
end

--------------------------------------------------------------------------------------------------------------------------------
local Refill = {} ---@type WorkerState

---@param self Worker
function Refill.on_start(self)
    local inventory = Worker.get_inventory(self)
    local contents = inventory.get_contents()
    local trash = Worker.get_trash(self)
    local slot_idx = 1

    do
        local limit = Worker.robots_limit(self)
        local robot_stacks_count = 1 + (limit - 1) / game.item_prototypes[strings.construction_robot].stack_size
        for idx = 1, robot_stacks_count do
            idx = idx --[[@as uint]]
            inventory.set_filter(idx, strings.construction_robot)
        end

        local robots = Worker.robots_count(self)
        if robots > limit then
            local delta = robots - limit
            if trash.find_empty_stack() then
                local count = trash.insert({
                    name = strings.construction_robot,
                    count = delta,
                })
                inventory.remove({
                    name = strings.construction_robot,
                    count = count,
                })
            end
        elseif robots < limit then
            self.entity.set_request_slot({
                name = strings.construction_robot,
                count = limit
            }, 1)
            slot_idx = slot_idx + 1 --[[@as uint]]
        end
    end

    local free_stacks_count = inventory.count_empty_stacks()
    for item, count in pairs(global.storage) do
        if count < 0 then
            local item_proto = game.item_prototypes[item]
            local stack_size = item_proto.stack_size
            local stacks_count = math.min( -count / stack_size, free_stacks_count) --[[@as uint]]
            free_stacks_count = free_stacks_count - stacks_count
            local item_count = math.ceil(stacks_count * stack_size - 0.5) --[[@as uint]]
            self.entity.set_request_slot({
                name = item,
                count = item_count,
            }, slot_idx)
            storage.add(item, item_count)

            slot_idx = slot_idx + 1 --[[@as uint]]
        elseif count > 0 then
            if contents[item] and contents[item] >= 0 and trash.find_empty_stack() then
                local min = math.min(count, contents[item]) --[[@as uint]]
                local trash_count = trash.insert({
                    name = item,
                    count = min,
                })
                inventory.remove({
                    name = item,
                    count = trash_count,
                })
                storage.trash(item, trash_count)
            end
        end
    end

    while slot_idx < self.entity.request_slot_count do
        slot_idx = slot_idx + 1 --[[@as uint]]
        self.entity.clear_request_slot(slot_idx)
    end
end

---@param self Worker
function Refill.on_tick(self)
    if Worker.has_to_wait_for_robots(self) then
        Worker.pause_walking(self)
        return
    end
    Worker.go_home(self)

    if Worker.requests_fulfilled(self) then
        Worker.set_state(self, Worker.StatesEnum.Idle)
        return
    end
end

---@param self Worker
function Refill.on_end(self)
    local slot_idx = 0
    while slot_idx < self.entity.request_slot_count do
        slot_idx = slot_idx + 1 --[[@as uint]]
        self.entity.clear_request_slot(slot_idx)
    end
end

--------------------------------------------------------------------------------------------------------------------------------
local Docked = {} ---@type WorkerState

---@param self Worker
function Docked.on_start(self)
end

---@param self Worker
function Docked.on_tick(self)
    if jobs.count() > 0 then
        Worker.set_state(self, Worker.StatesEnum.Idle)
        return
    end

    local inventory = Worker.get_inventory(self)
    local contents = inventory.get_contents()
    local trash = Worker.get_trash(self)

    if Worker.has_to_wait_for_robots(self) then
        Worker.pause_walking(self)
        return
    end
    Worker.go_home(self)

    for item, count in pairs(contents) do
        if item ~= strings.construction_robot then
            local trash_count = trash.insert({
                name = item,
                count = count,
            })
            if trash_count > 0 then
                inventory.remove({
                    name = item,
                    count = trash_count,
                })
            end
            storage.trash(item, trash_count)
        end
    end
end

---@param self Worker
function Docked.on_end(self)
end

--------------------------------------------------------------------------------------------------------------------------------

---@enum WorkerStatesEnum
Worker.StatesEnum = {
    Idle = 1,
    Work = 2,
    Refill = 3,
    Docked = 4,
}

---@enum WorkerStates
Worker.States = {
    Idle,
    Work,
    Refill,
    Docked,
}

---@class Worker
---@field entity LuaEntity
---@field job Job
---@field state WorkerStatesEnum
---@field id uint

---@param entity LuaEntity
---@param id uint
---@param state WorkerStatesEnum
---@return Worker
function Worker.create(entity, id, state)
    local worker = {
        entity = entity,
        state = state,
        id = id,
    }
    Worker.on_tick(worker)
    return worker
end

---@param self Worker
---@param state WorkerStatesEnum
function Worker.set_state(self, state)
    if self.state ~= state then
        -- game.print("Worker State: " .. self.state .. " -> " .. state)
    end

    Worker.States[self.state].on_end(self)
    self.state = state
    Worker.States[self.state].on_start(self)
    -- Worker.States[self.state].on_tick(self)
end

---@param self Worker
---@param job Job
---@return boolean
function Worker.can_take_job(self, job)
    if not Worker.has_enough_robots(self) then
        return false
    end

    if job.type == jobs.Type.Build then
        return Worker.can_take_build_job(self, job)
    elseif job.type == jobs.Type.Deconstruct then
        return Worker.can_take_deconstruct_job(self)
    else
        error("unknown job type")
    end
end

---@param self Worker
function Worker.on_tick(self)
    Worker.States[self.state].on_tick(self)
end

---@param self Worker
---@param job Job
---@return boolean
function Worker.can_take_build_job(self, job)
    local items = job.entity.ghost_prototype.items_to_place_this
    if items == nil then
        return true
    end

    local contents = Worker.get_inventory(self).get_contents()
    for _, stack in ipairs(items) do
        if (contents[stack.name] or 0) < stack.count then
            return false
        end
    end

    return true
end

---@param self Worker
---@return boolean
function Worker.can_take_deconstruct_job(self)
    local stack = Worker.get_inventory(self).find_empty_stack()
    if not stack then
        return false
    end

    return true
end

---@param self Worker
---@param job Job
function Worker.take_job(self, job)
    self.job = job
    Worker.set_state(self, Worker.StatesEnum.Work)
end

---@param self Worker
function Worker.jitter(self)
    local pos = self.job.entity.position
    local r = 0.25 * self.entity.logistic_cell.construction_radius
    local sin_cos = Worker.get_rand_sin_con(self.id)
    pos.x = pos.x + r * sin_cos[1]
    pos.y = pos.y + r * sin_cos[2]
    self.entity.autopilot_destination = pos
end

---@param self Worker
function Worker.pause_walking(self)
    self.entity.autopilot_destination = nil
end

---@param self Worker
function Worker.continue_walking(self)
    self.entity.autopilot_destination = self.job.entity.position
end

---@param self Worker
function Worker.go_home(self)
    local closest = stations.find_closest_to(self.entity.position)
    if not closest then
        return
    end

    local pos = closest.position
    local cell = self.entity.logistic_cell
    local r
    if cell then
        r = 0.9 * game.entity_prototypes[strings.station].logistic_radius
    else
        r = 0
    end
    local sin_cos = Worker.get_rand_sin_con(self.id)
    pos.x = pos.x + r * sin_cos[1]
    pos.y = pos.y + r * sin_cos[2]

    self.entity.autopilot_destination = pos
end

---@param self Worker
function Worker.refill(self)
    Worker.set_state(self, Worker.StatesEnum.Refill)
end

---@param self Worker
---@return boolean
function Worker.requests_fulfilled(self)
    local inventory = Worker.get_inventory(self)
    local contents = inventory.get_contents()
    for id = 1, self.entity.request_slot_count do
        id = id --[[@as uint]]
        local request = self.entity.get_request_slot(id)
        if not request then
            goto continue
        end

        if (request.count > (contents[request.name] or 0)) then
            return false
        end

        ::continue::
    end

    return true
end

---@param self Worker
---@return uint
function Worker.robots_limit(self)
    local network = self.entity.logistic_network
    if not network then
        return 0
    end

    local limit = network.robot_limit
    if limit == 2 ^ 32 - 1 then
        return 0
    end
    return limit
end

---@param self Worker
---@return uint
function Worker.robots_count(self)
    local network = self.entity.logistic_network
    if not network then
        return 0
    end

    return network.all_construction_robots
end

---@param self Worker
---@return boolean
function Worker.has_enough_robots(self)
    return Worker.robots_count(self) >= Worker.robots_limit(self)
end

---@param self Worker
---@return boolean
function Worker.has_to_wait_for_robots(self)
    local cell = self.entity.logistic_cell
    return cell and (cell.to_charge_robot_count > 0 or cell.charging_robot_count > 0)
end

---@param self Worker
---@return float
function Worker.get_construction_radius(self)
    local area = 0
    local equipment = self.entity.grid.equipment
    for idx = 1, #equipment do
        local eq = equipment[idx]
        if eq.type == "personal-roboport" then
            local radius = eq.prototype.logistic_parameters.construction_radius
            area = area + radius ^ 2
        end
    end
    return math.sqrt(area) --[[@as float]]
end

---@param self Worker
---@return uint
function Worker.count_items(self, item_name)
    return Worker.get_inventory(self).get_contents()[item_name] or 0
end

---@param self Worker
---@return LuaInventory
function Worker.get_inventory(self)
    local inventory = self.entity.get_inventory(defines.inventory.spider_trunk)
    if inventory == nil then
        error("inventory is nil")
    end

    return inventory
end

---@param self Worker
---@return LuaInventory
function Worker.get_trash(self)
    local inventory = self.entity.get_inventory(defines.inventory.spider_trash)
    if inventory == nil then
        error("inventory is nil")
    end

    return inventory
end

---@param seed uint
---@return table<double>
function Worker.get_rand_sin_con(seed)
    local sin = math.sin(seed * 456) --[[@as double]]
    local cos = math.cos(seed * 456) --[[@as double]]
    return { sin, cos }
end

return Worker
