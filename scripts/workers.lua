local jobs = require("scripts.jobs")

local workers = {}

---@enum WorkerState
workers.State = {
    Idle = 1,
    Following = 2
}

---@class Worker
---@field entity LuaEntity
---@field target LuaEntity
---@field state WorkerState

function workers.on_init()
    global.workers = {} ---@type Worker[]
end

function workers.on_worker_placed(event)
    table.insert(global.workers, {
        target = nil,
        entity = event.created_entity,
        state = workers.State.Idle,
    })
end

---@param worker Worker
---@return boolean
function workers.on_tick(worker)
    local entity = worker.entity
    local target = worker.target

    if worker.state == workers.State.Idle then
        local limit = workers.robot_limit(worker)

        if workers.count_robots(worker) == limit then
            entity.clear_request_slot(1)
            return false
        else
            entity.set_request_slot({
                name = 'construction-robot',
                count = limit
            }, 1)
            return true
        end

    elseif worker.state == workers.State.Following then
        if workers.is_following(worker) and target.valid then
            entity.autopilot_destination = target.position
            return true
        end

        workers.stop(worker)
        return false
    else
        error("unknown worker state")
    end
end

function workers.count()
    return #global.workers
end

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
---@param target LuaEntity
function workers.follow(worker, target)
    worker.target = target
    worker.entity.autopilot_destination = target.position
    worker.state = workers.State.Following
end

---@param worker Worker
---@return boolean
function workers.is_following(worker)
    return worker.target ~= nil
end

---@param worker Worker
function workers.stop(worker)
    worker.target = nil
    worker.entity.autopilot_destination = nil
    worker.state = workers.State.Idle
end

---@param worker Worker
function workers.robot_limit(worker)
    return worker.entity.logistic_network.robot_limit
end

---@param worker Worker
---@return uint
function workers.count_robots(worker)
    return worker.entity.logistic_network.all_construction_robots
end

---@param worker Worker
---@return uint
function workers.count_items(worker, item_name)
    local inventory = worker.entity.get_inventory(defines.inventory.spider_trunk)
    if inventory == nil then
        error("inventory is nil")
    end

    local stacks = inventory.get_contents()
    return stacks[item_name]
end

return workers
