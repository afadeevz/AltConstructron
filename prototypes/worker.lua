local strings = require("prototypes.strings")

local worker_entity = table.deepcopy(data.raw["spider-vehicle"].spidertron)
worker_entity.name = strings.worker
worker_entity.minable.result = strings.worker

local worker_item = table.deepcopy(data.raw["item-with-entity-data"].spidertron)
worker_item.name = strings.worker
worker_item.order = "b[personal-transport]-c[spidertron]-ab[constructron]"
worker_item.place_result = strings.worker

local worker_recipe = table.deepcopy(data.raw.recipe.spidertron)
worker_recipe.name = strings.worker
worker_recipe.ingredients = { { "spidertron", 1 } }
worker_recipe.result = strings.worker

data:extend {
    worker_entity,
    worker_item,
    worker_recipe,
}
