local job_pool = require("script.job_pool")

local workers = {}

function workers.on_init()
    global.workers = global.workers or {}
    global.workers_active_id = global.workers_active_id or 1
end

function workers.on_worker_placed(event)
    table.insert(global.workers, {
        target = nil,
        entity = event.created_entity,
    })
end

function workers.count()
    return #global.workers
end

function workers.get(id)
    return global.workers[id]
end

function workers.get_active()
    return global.workers[global.workers_active_id]
end

function workers.select_next()
    global.workers_active_id = global.workers_active_id % workers.count() + 1
end

function workers.on_tick()
    if workers.count() == 0 then
        return
    end

    local id = global.workers_active_id
    local worker = workers.get(id)
    if not worker.entity.valid then
        global.workers[id] = global.workers[workers.count()]
        table.remove(global.workers)
        global.workers_active_id = 1
        return
    end

    if worker.target ~= nil then
        if worker.target.valid ~= false then
            worker.entity.autopilot_destination = worker.target.position
            workers.select_next()
            return
        end

        worker.target = nil
    end

    if job_pool.count() == 0 then
        return
    end

    local job = job_pool.get_job()
    if job == nil then
        return
    end

    worker.target = job
    worker.entity.autopilot_destination = worker.target.position
    workers.select_next()
end

return workers
