local strings = require("prototypes.strings")

local station_entity = table.deepcopy(data.raw.roboport.roboport)
station_entity.name = strings.station
station_entity.minable.result = strings.station
station_entity.construction_radius = 0
station_entity.draw_construction_radius_visualization = false

local station_item = table.deepcopy(data.raw.item.roboport)
station_item.name = strings.station
station_item.order = "c[signal]-ab[alt-constructron-station]"
station_item.place_result = strings.station

local station_recipe = table.deepcopy(data.raw.recipe.roboport)
station_recipe.name = strings.station
station_recipe.ingredients = { { "roboport", 1 } }
station_recipe.result = strings.station

data:extend {
    station_entity,
    station_item,
    station_recipe,
}
