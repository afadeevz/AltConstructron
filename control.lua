require("scripts.event_handlers")
local jobs = require("scripts.jobs")
local workers = require("scripts.workers")

local function on_init()
    jobs.on_init()
    workers.on_init()
end

script.on_init(on_init)
