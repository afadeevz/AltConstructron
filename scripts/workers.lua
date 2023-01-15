local jobs = require("scripts.jobs")
local stations = require("scripts.stations")
local strings = require("prototypes.strings")
local flib_position = require("__flib__.position")

local workers = {}

---@enum WorkerState
workers.State = {
    New = 0,
    Idle = 1,
    Working = 2,
    Refilling = 3,
}

---@class Worker
---@field entity LuaEntity
---@field job Job
---@field state WorkerState

function workers.on_init()
    global.workers = {} ---@type Worker[]
end

---@param event EventData.on_built_entity
function workers.on_worker_placed(event)
    table.insert(global.workers, {
        target = nil,
        entity = event.created_entity,
        state = workers.State.New,
    })
end

---@param worker Worker
---@param id uint
function workers.on_tick(worker, id)
    local entity = worker.entity
    local job = worker.job

    if worker.state == workers.State.New then
        workers.go_home(worker)

    elseif worker.state == workers.State.Idle then
        if not workers.has_enough_robots(worker) then
            workers.refill(worker)
            return
        end

        local job = jobs.find_close_to(worker.entity.position, function(j)
            return workers.can_take_job(worker, j)
        end)
        if job then
            workers.take_job(worker, job)
        end

    elseif worker.state == workers.State.Working then
        if not job or not job.entity.valid then
            workers.go_home(worker)
            return
        end

        local dist = flib_position.distance(entity.position, job.entity.position)
        local cell = entity.logistic_cell
        if (cell.to_charge_robot_count > 0
            or cell.charging_robot_count > 0)
            and dist > cell.construction_radius then
            workers.pause(worker)
        elseif cell.to_charge_robot_count == 0
            and cell.charging_robot_count == 0
            or dist <= cell.construction_radius then
            workers.jitter(worker, id)
        end

    elseif worker.state == workers.State.Refilling then
        if workers.requests_fulfilled(worker) then
            workers.set_state(worker, workers.State.Idle)
            return
        end

    else
        error("unknown worker state")
    end
end

---@return uint
function workers.count()
    return #global.workers --[[@as uint]]
end

---@param id uint
---@return Worker?
function workers.get(id)
    if id > workers.count() then
        error("invalid worker ID")
    end

    local worker = global.workers[id]
    if not worker.entity.valid then
        global.workers[id] = global.workers[workers.count()]
        table.remove(global.workers)
        return nil
    end

    return worker
end

---@param worker Worker
---@param job Job
function workers.can_take_job(worker, job)
    if not workers.has_enough_robots(worker) then
        return false
    end

    local inventory = worker.entity.get_inventory(defines.inventory.spider_trunk)
    if inventory == nil then
        return false
    end
    local contents = inventory.get_contents()

    if job.type == jobs.Type.Build then
        local items = job.entity.ghost_prototype.items_to_place_this
        if items == nil then
            return true
        end

        for _, stack in ipairs(items) do
            if (contents[stack.name] or 0) < stack.count then
                return false
            end
        end
        return true

    elseif job.type == jobs.Type.Deconstruct then
        local stack = inventory.find_empty_stack()
        if stack == nil then
            return false
        end

        return true
    end
end

---@param worker Worker
---@param new_state WorkerState
function workers.set_state(worker, new_state)
    -- game.print("Worker state: " .. worker.state .. " -> " .. new_state);
    worker.state = new_state
end

---@param worker Worker
---@param job Job
function workers.take_job(worker, job)
    worker.job = job
    workers.set_state(worker, workers.State.Working)
end

---@param worker Worker
---@param id uint
function workers.jitter(worker, id)
    local pos = worker.job.entity.position
    local r = 0.9 * worker.entity.logistic_cell.construction_radius
    local t = game.tick / 60 / 50 + id / workers.count() * 2 * math.pi
    pos.x = pos.x + r * math.sin(t)
    pos.y = pos.y + r * math.cos(t)
    worker.entity.autopilot_destination = pos
end

---@param worker Worker
---@return boolean
function workers.is_working(worker)
    return worker.job ~= nil
end

---@param worker Worker
function workers.stop(worker)
    worker.job = nil
    worker.entity.autopilot_destination = nil
    workers.set_state(worker, workers.State.Idle)
end

---@param worker Worker
function workers.pause(worker)
    worker.entity.autopilot_destination = nil
end

---@param worker Worker
function workers.continue(worker)
    worker.entity.autopilot_destination = worker.job.entity.position
end

---@param worker Worker
function workers.go_home(worker)
    workers.set_state(worker, workers.State.Idle)
    local closest = stations.find_closest_to(worker.entity.position)
    if not closest then
        return
    end

    worker.entity.autopilot_destination = closest.position
end

---@param worker Worker
function workers.refill(worker)
    -- worker.entity.logistic_cell
    workers.set_state(worker, workers.State.Refilling)
    local limit = workers.robots_limit(worker)
    if limit == 2 ^ 32 - 1 then
        limit = 0
    end

    worker.entity.set_request_slot({
        name = strings.construction_robot,
        count = limit
    }, 1)

    -- local robots = workers.count_items(worker, strings.construction_robot)
    -- if robots > limit then
    --     local delta = robots - limit
    --     local slot_idx = 1
    --     while delta > 0 do
    --         worker.entity.get_inventory(defines.inventory.spider_trash)

    --     end

    -- end
end

---@param worker Worker
---@return boolean
function workers.requests_fulfilled(worker)
    local inventory = workers.get_inventory(worker)
    local contents = inventory.get_contents()
    for id = 1, worker.entity.request_slot_count do
        local request = worker.entity.get_request_slot(id)
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

---@param worker Worker
function workers.robots_limit(worker)
    return worker.entity.logistic_network.robot_limit
end

---@param worker Worker
---@return uint
function workers.robots_count(worker)
    return worker.entity.logistic_network.all_construction_robots
end

---@param worker Worker
---@return boolean
function workers.has_enough_robots(worker)
    return workers.robots_count(worker) >= workers.robots_limit(worker)
end

---@param worker Worker
---@return uint
function workers.count_items(worker, item_name)
    return workers.get_inventory(worker).get_contents()[item_name] or 0
end

---@param worker Worker
---@return LuaInventory
function workers.get_inventory(worker)
    local inventory = worker.entity.get_inventory(defines.inventory.spider_trunk)
    if inventory == nil then
        error("inventory is nil")
    end

    return inventory
end

return workers
