local job_pool = {}

function job_pool.on_init()
    global.job_pool = global.job_pool or {}
end

function job_pool.on_ghost_placed(event)
    job_pool.on_init()
    table.insert(global.job_pool, event.created_entity)
end

return job_pool
