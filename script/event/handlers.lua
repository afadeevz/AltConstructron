local handlers = {}

local function on_constuctron_placed(event)
    log("CTRON PLACED");
end

script.on_event(defines.events.on_built_entity, on_constuctron_placed, {
    { filter = "name", name = "alt-constructron" }
})

return handlers
