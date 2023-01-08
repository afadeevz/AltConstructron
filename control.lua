require("script.event_handlers")
local job_pool = require("script.job_pool")

local function on_init()
    job_pool.on_init()
end

script.on_init(on_init)
