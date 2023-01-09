local jobs = {}

function jobs.on_init()
    global.jobs = global.jobs or {}
    global.jobs_active_id = global.jobs_active_id or 1
end

function jobs.on_ghost_placed(event)
    table.insert(global.jobs, event.created_entity)
end

function jobs.on_marked_for_deconstruction(event)
    table.insert(global.jobs, event.entity)
end

function jobs.select_next()
    if jobs.count() == 0 then
        global.jobs_active_id = 1
    else
        global.jobs_active_id = global.jobs_active_id % jobs.count() + 1
    end
end

function jobs.get_job(offset)
    offset = offset or 0
    local id_offset = math.floor(offset * jobs.count())
    local id = (global.jobs_active_id + id_offset - 1) % jobs.count() + 1
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
