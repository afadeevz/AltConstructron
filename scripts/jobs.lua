local flib_position = require("__flib__.position")

local jobs = {}

---@enum JobType
jobs.Type = {
    Build = 1,
    Deconstruct = 2,
}

---@class Job
---@field type JobType
---@field entity LuaEntity

function jobs.on_init()
    global.jobs = global.jobs or {} ---@type Job[]
end

---@param event EventData.on_built_entity
function jobs.on_ghost_placed(event)
    table.insert(global.jobs, {
        type = jobs.Type.Build,
        entity = event.created_entity,
    })
end

---@param event EventData.on_marked_for_deconstruction
function jobs.on_marked_for_deconstruction(event)
    table.insert(global.jobs, {
        type = jobs.Type.Deconstruct,
        entity = event.entity,
    })
end

function jobs.select_next()
    if jobs.count() == 0 then
        global.scheduler_active_job_id = 1
    else
        global.scheduler_active_job_id = global.scheduler_active_job_id % jobs.count() + 1
    end
end

---@param id uint
---@return Job?
function jobs.get(id)
    local job = global.jobs[id]
    if not job.entity.valid then
        global.jobs[id] = global.jobs[jobs.count()]
        table.remove(global.jobs)
        jobs.select_next()
        return nil
    end

    jobs.select_next()
    return job
end

---@param position MapPosition
---@param filter fun(Job): boolean
---@return Job?
function jobs.find_close_to(position, filter)
    local iters = 0
    local min = math.huge
    local closest = nil

    while true do
        if iters ^ 2 > jobs.count() then
            game.print("jobs.find_close_to: " .. iters .. " iters")
            return closest
        end

        if jobs.count() == 0 then
            return nil
        end

        local id = math.random(1, jobs.count()) --[[@as uint]]
        local job = jobs.get(id)
        if job and filter(job) then
            local dist = flib_position.distance(position, job.entity.position)
            if dist < min then
                min = dist
                closest = job
            end
        end

        iters = iters + 1
    end
end

---@return uint
function jobs.count()
    return #global.jobs --[[@as uint]]
end

function jobs.gc()
    global.jobs_gc_id = global.jobs_gc_id or 0 ---@type uint

    if jobs.count() == 0 then
        return
    end

    local iters = 0
    local deleted = 0
    while true do
        if iters ^ 4 > jobs.count() then
            -- game.print("jobs.gc: " .. iters .. " iters, " .. deleted .. " deleted")
            return
        end

        global.jobs_gc_id = 1 + global.jobs_gc_id % jobs.count()
        local job = global.jobs[global.jobs_gc_id]
        if job.entity.valid then
            goto continue
        end

        while global.jobs_gc_id < jobs.count() and not global.jobs[jobs.count()].entity.valid do
            if iters ^ 4 > jobs.count() then
                -- game.print("jobs.gc: " .. iters .. " iters, " .. deleted .. " deleted")
                return
            end
            table.remove(global.jobs)
            iters = iters + 1
            deleted = deleted + 1
        end

        global.jobs[global.jobs_gc_id] = global.jobs[jobs.count()]
        table.remove(global.jobs)
        deleted = deleted + 1
        if jobs.count() == 0 then
            -- game.print("jobs.gc: " .. iters .. " iters, " .. deleted .. " deleted")
            return
        end

        ::continue::
        iters = iters + 1
    end
end

return jobs
