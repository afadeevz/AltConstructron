local jobs = {}

---@alias Job LuaEntity

function jobs.on_init()
    global.jobs = global.jobs or {}
end

function jobs.on_ghost_placed(event)
    table.insert(global.jobs, event.created_entity)
end

function jobs.on_marked_for_deconstruction(event)
    table.insert(global.jobs, event.entity)
end

function jobs.select_next()
    if jobs.count() == 0 then
        global.scheduler_active_job_id = 1
    else
        global.scheduler_active_job_id = global.scheduler_active_job_id % jobs.count() + 1
    end
end

---@return Job?
function jobs.get(id)
    local job = global.jobs[id]
    if not job.valid then
        global.jobs[id] = global.jobs[jobs.count()]
        table.remove(global.jobs)
        jobs.select_next()
        return nil
    end

    jobs.select_next()
    return job
end

function jobs.count()
    return #global.jobs
end

return jobs
