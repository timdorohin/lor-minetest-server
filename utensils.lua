
local S = farming.intllib

-- wooden bowl
minetest.register_craftitem("farming:bowl", {
	description = S("Wooden Bowl"),
	inventory_image = "farming_bowl.png",
	groups = {food_bowl = 1, flammable = 2},
})

minetest.register_craft({
	output = "farming:bowl 4",
	recipe = {
		{"group:wood", "", "group:wood"},
		{"", "group:wood", ""},
	}
})
