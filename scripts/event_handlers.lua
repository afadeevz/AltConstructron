local jobs = require("scripts.jobs")
local workers = require("scripts.workers.workers")
local scheduler = require("scripts.scheduler")
local storage = require("scripts.storage")
local stations = require("scripts.stations")
local strings = require("prototypes.strings")

local handlers = {}

script.on_nth_tick(1,
    function()
        scheduler.on_tick()
    end
)

script.on_event(defines.events.on_built_entity,
    function(event)
        local entity = event.created_entity
        local type = entity.type
        local name = entity.name
        if name == strings.worker then
            workers.on_worker_placed(event)
        elseif name == strings.station then
            stations.on_built(event)
        elseif type == strings.entity_ghost or type == strings.tile_ghost then
            jobs.on_ghost_placed(event)
            storage.on_ghost_placed(event)
        else
            game.print("on_built_entity: unknown entity type")
        end
    end, {
    { filter = "name", name = strings.worker,       mode = "or" },
    { filter = "name", name = strings.station,      mode = "or" },
    { filter = "name", name = strings.entity_ghost, mode = "or" },
    { filter = "name", name = strings.tile_ghost }
})

script.on_event(defines.events.on_marked_for_deconstruction,
    function(event)
        jobs.on_marked_for_deconstruction(event)
        if event.entity.name == "deconstructible-tile-proxy" then
            local entity = event.entity
            local surface = entity.surface
            local pos = entity.position
            local tile = surface.get_tile(pos.x, pos.y)
            storage.on_tile_marked_for_deconstruction(tile)
        else
            storage.on_marked_for_deconstruction(event)
        end
    end
)

script.on_event(defines.events.on_pre_ghost_deconstructed,
    function(event)
        if event.ghost.name == "item-request-proxy" then
            return storage.on_request_proxy_deconstructed(event)
        end
        storage.on_ghost_deconstructed(event)
    end
)

return handlers
