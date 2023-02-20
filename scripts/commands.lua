local storage = require("scripts.storage")
local jobs = require("scripts.jobs")

---@param data CustomCommandData
local function handler(data)
    if not data.parameter then
        return
    end

    if data.parameter == "storage_reset" then
        storage.reset()
        storage.info()
    elseif data.parameter == "storage_info" then
        storage.info()
    elseif data.parameter == "info" then
        jobs.info()
        storage.info()
    else
        game.print("error")
    end
end

commands.add_command("alt_ctron", "", handler)
