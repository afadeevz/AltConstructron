local workers = {}

function workers.on_init()
    global.workers = global.workers or {}
end

function workers.on_worker_placed(event)
    table.insert(global.workers, event.created_entity)
end

return workers
