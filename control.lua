require("scripts.event_handlers")
local jobs = require("scripts.jobs")
local workers = require("scripts.workers")
local scheduler = require("scripts.scheduler")

script.on_init(function()
    jobs.on_init()
    workers.on_init()
    scheduler.on_init()
end)
