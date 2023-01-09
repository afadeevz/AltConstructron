local job_pool = {}

function job_pool.on_init()
    global.job_pool = global.job_pool or {}
    global.job_pool_active_id = global.job_pool_active_id or 1
end

function job_pool.on_ghost_placed(event)
    table.insert(global.job_pool, event.created_entity)
end

function job_pool.on_marked_for_deconstruction(event)
    table.insert(global.job_pool, event.entity)
end

function job_pool.select_next()
    if job_pool.count() == 0 then
        global.job_pool_active_id = 1
    else
        global.job_pool_active_id = global.job_pool_active_id % job_pool.count() + 1
    end
end

function job_pool.get_job(offset)
    offset = offset or 0
    local id_offset = math.floor(offset * job_pool.count())
    local id = (global.job_pool_active_id + id_offset - 1) % job_pool.count() + 1
    local job = global.job_pool[id]
    if not job.valid then
        global.job_pool[id] = global.job_pool[job_pool.count()]
        table.remove(global.job_pool)
        job_pool.select_next()
        return nil
    end

    job_pool.select_next()
    return job
end

function job_pool.count()
    return #global.job_pool
end

return job_pool
