local alt_constructron = table.deepcopy(data.raw["spider-vehicle"]["spidertron"])
alt_constructron.name = "alt-constructron"
alt_constructron.minable.result = "alt-constructron"

local alt_constructron_item = table.deepcopy(data.raw["item-with-entity-data"]["spidertron"])
alt_constructron_item.name = "alt-constructron"
alt_constructron_item.order = "b[personal-transport]-c[spidertron]-ab[constructron]"
alt_constructron_item.place_result = "alt-constructron"

alt_constructron_recipe = table.deepcopy(data.raw.recipe["spidertron"])
alt_constructron_recipe.name = "alt-constructron"
alt_constructron_recipe.ingredients = { { "spidertron", 1 } }
alt_constructron_recipe.result = "alt-constructron"

alt_constructron_technology = table.deepcopy(data.raw.technology["spidertron"])
alt_constructron_technology.name = "alt-constructron"
alt_constructron_technology.prerequistes = {
    "constructron",
    "robotics"
}
alt_constructron_technology.effects = { {
    type = "unlock-recipe",
    recipe = "alt-constructron"
} }

data:extend {
    alt_constructron,
    alt_constructron_item,
    alt_constructron_recipe,
    alt_constructron_technology
}
