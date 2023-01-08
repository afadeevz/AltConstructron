require("script.event_handlers")
local job_pool = require("script.job_pool")
local workers = require("script.workers")

local function on_init()
    job_pool.on_init()
    workers.on_init()
end

script.on_init(on_init)
