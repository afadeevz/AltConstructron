local strings = require("prototypes.strings")

local technology = table.deepcopy(data.raw.technology.spidertron)
technology.name = strings.technology
technology.prerequistes = {
    "spidertron",
    "robotics"
}
technology.effects = { {
    type = "unlock-recipe",
    recipe = strings.worker
}, {
    type = "unlock-recipe",
    recipe = strings.station
} }

data:extend {
    technology,
}
