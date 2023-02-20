local workers = require("scripts.workers.workers")
local Worker = require("scripts.workers.Worker")
local jobs = require("scripts.jobs")

local scheduler = {}

function scheduler.on_init()
    global.scheduler_active_worker_id = global.scheduler_active_worker_id or 1 --[[@as uint]]
end

function scheduler.on_tick()
    -- jobs.gc()
    -- jobs.shuffle()

    if workers.count() == 0 then
        return
    end

    local worker = scheduler.get_active_worker()
    if not worker then
        scheduler.fix_active_worker_id()
        return
    end

    Worker.on_tick(worker)
    scheduler.select_next_worker()
end

function scheduler.get_active_worker()
    return workers.get(global.scheduler_active_worker_id)
end

function scheduler.select_next_worker()
    if workers.count() == 0 then
        global.scheduler_active_worker_id = 1 ---@type uint
        return
    end

    global.scheduler_active_worker_id = global.scheduler_active_worker_id % workers.count() + 1 --[[@as uint]]
end

function scheduler.fix_active_worker_id()
    if workers.count() == 0 then
        global.scheduler_active_worker_id = 1 ---@type uint
        return
    end

    global.scheduler_active_worker_id = (global.scheduler_active_worker_id - 1) % workers.count() + 1 --[[@as uint]]
end

return scheduler
