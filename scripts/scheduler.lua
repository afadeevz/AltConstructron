local workers = require("scripts.workers")
local jobs = require("scripts.jobs")

local scheduler = {}

function scheduler.on_init()
    global.scheduler_active_worker_id = global.scheduler_active_worker_id or 1
    global.scheduler_active_job_id = global.scheduler_active_job_id or 1
end

function scheduler.on_tick()
    if workers.count() == 0 then
        return
    end

    local worker = scheduler.get_active_worker()
    if worker == nil then
        scheduler.fix_active_worker_id()
        return
    end

    if workers.on_tick(worker) then
        scheduler.select_next_worker()
        return
    end

    if jobs.count() == 0 then
        return
    end

    local offset = (global.scheduler_active_worker_id - 1) / workers.count()
    local job = nil
    local retries = 0
    while job == nil do
        if retries ^ 3 > jobs.count() then
            return
        end
        local id_offset = math.floor(offset * jobs.count())
        local job_id = (global.scheduler_active_job_id + id_offset - 1) % jobs.count() + 1
        job = jobs.get(job_id)
        retries = retries + 1
    end

    workers.follow(worker, job)
    scheduler.select_next_worker()
end

function scheduler.get_active_worker()
    return workers.get(global.scheduler_active_worker_id)
end

function scheduler.select_next_worker()
    if workers.count() == 0 then
        global.scheduler_active_worker_id = 1
        return
    end

    global.scheduler_active_worker_id = global.scheduler_active_worker_id % workers.count() + 1
end

function scheduler.fix_active_worker_id()
    if workers.count() == 0 then
        global.scheduler_active_worker_id = 1
        return
    end

    global.scheduler_active_worker_id = (global.scheduler_active_worker_id - 1) % workers.count() + 1
end

return scheduler
