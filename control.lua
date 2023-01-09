require("scripts.event_handlers")
local job_pool = require("scripts.job_pool")
local workers = require("scripts.workers")

local function on_init()
    job_pool.on_init()
    workers.on_init()
end

script.on_init(on_init)
