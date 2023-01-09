local jobs = require("scripts.jobs")
local workers = require("scripts.workers")
local scheduler = require("scripts.scheduler")

local handlers = {}

script.on_event(defines.events.on_built_entity,
    function(event)
        local entity = event.created_entity
        local type = entity.type
        local name = entity.name
        if name == "alt-constructron" then
            workers.on_worker_placed(event)
        elseif type == "entity-ghost" or type == "tile-ghost" then
            jobs.on_ghost_placed(event)
        else
            game.print("on_built_entity: unknown entity type")
        end
    end, {
    { filter = "name", name = "alt-constructron", mode = "or" },
    { filter = "name", name = "entity-ghost", mode = "or" },
    { filter = "name", name = "tile-ghost" }
})

script.on_event(defines.events.on_marked_for_deconstruction,
    function(event)
        jobs.on_marked_for_deconstruction(event)
    end
)

script.on_nth_tick(1,
    function()
        scheduler.on_tick()
    end
)

return handlers
