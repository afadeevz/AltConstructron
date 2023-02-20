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

function jobs.info()
    game.print("Jobs: " .. jobs.count())
end

function jobs.on_init()
    global.jobs = global.jobs or {} ---@type Job[]
    global.jobs_active_id = global.jobs_active_id or 1 ---@type uint
end

---@param event EventData.on_built_entity
function jobs.on_ghost_placed(event)
    jobs.add({
        type = jobs.Type.Build,
        entity = event.created_entity,
    })
end

---@param event EventData.on_marked_for_deconstruction
function jobs.on_marked_for_deconstruction(event)
    jobs.add({
        type = jobs.Type.Deconstruct,
        entity = event.entity,
    })
end

---@param job Job
function jobs.add(job)
    if jobs.count() == 0 then
        global.jobs[jobs.count() + 1] = job
    else
        local id = math.random(1, jobs.count())
        global.jobs[jobs.count() + 1] = global.jobs[id]
        global.jobs[id] = job
    end
end

-- function jobs.select_next()
--     global.jobs_active_id = global.jobs_active_id or 1 ---@type uint

--     if jobs.count() == 0 then
--         global.jobs_active_id = 1
--     else
--         global.jobs_active_id = global.jobs_active_id % jobs.count() + 1
--     end
-- end

---@param id uint
---@return Job?
function jobs.get(id)
    local job = global.jobs[id]
    if not job.entity.valid then
        global.jobs[id] = global.jobs[jobs.count()]
        global.jobs[jobs.count()] = nil
        return nil
    end

    return job
end

---@param position MapPosition
---@param filter fun(job: Job): boolean
---@return Job?
function jobs.find_close_to(position, filter)
    local iters = 0
    local min = math.huge
    local closest = nil
    while true do
        if iters ^ 3 > jobs.count() then
            -- game.print("jobs.find_close_to: " .. iters .. " iters")
            return closest
        end

        if jobs.count() == 0 then
            return nil
        end

        global.jobs_active_id = 1 + global.jobs_active_id % jobs.count() --[[@as uint]]
        local job = jobs.get(global.jobs_active_id)
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

function jobs.shuffle()
    if jobs.count() <= 1 then
        return
    end

    local iters = 0

    while true do
        if iters ^ 5 > jobs.count() then
            -- game.print("jobs.gc: " .. iters .. " iters, " .. deleted .. " deleted")
            return
        end

        local id = math.random(1, jobs.count() - 1)
        local tmp = global.jobs[id]
        global.jobs[id] = global.jobs[jobs.count()]
        global.jobs[jobs.count()] = tmp

        iters = iters + 1
    end
end

function jobs.gc()
    global.jobs_gc_id = global.jobs_gc_id or 0 --[[@as uint]]

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
            global.jobs[jobs.count()] = nil
            iters = iters + 1
            deleted = deleted + 1
        end

        global.jobs[global.jobs_gc_id] = global.jobs[jobs.count()]
        global.jobs[jobs.count()] = nil
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
