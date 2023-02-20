local Worker = require("scripts.workers.Worker")

local workers = {}

function workers.on_init()
    global.workers = {} ---@type Worker[]
end

---@param event EventData.on_built_entity
function workers.on_worker_placed(event)
    local id = workers.count() + 1
    global.workers[id] = Worker.create(event.created_entity, id, Worker.StatesEnum.Idle)
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
        global.workers[id].id = id
        global.workers[workers.count()] = nil
        return nil
    end

    return worker
end

return workers
