
-- Generate new foods on map

function farming.mgv6ongen(minp, maxp, seed)

	if maxp.y < 2 and minp.y > 0 then return end

	local perlin1 = minetest.get_perlin(329, 3, 0.6, 100)

	-- Assume X and Z lengths are equal
	local divlen = 16
	local divs = (maxp.x-minp.x)/divlen+1

	for divx=0,divs-1 do
		for divz=0,divs-1 do

			local x0 = minp.x + math.floor((divx+0)*divlen)
			local z0 = minp.z + math.floor((divz+0)*divlen)
			local x1 = minp.x + math.floor((divx+1)*divlen)
			local z1 = minp.z + math.floor((divz+1)*divlen)

			-- Determine plant amount from perlin noise
			local plant_amount = math.floor(perlin1:get2d({x=x0, y=z0}) ^ 3 * 9)

			-- Find random positions for plant
			local pr = PseudoRandom(seed+420)

			for i=0,plant_amount do

				local x = pr:next(x0, x1)
				local z = pr:next(z0, z1)

				-- Find ground level (0...15)
				local ground_y = nil

				for y=30,0,-1 do
					if minetest.get_node({x=x,y=y,z=z}).name ~= "air" then
						ground_y = y
						break
					end
				end
				
				if ground_y then

					local p = {x=x,y=ground_y+1,z=z}
					local nn = minetest.get_node(p).name

					-- Check if the node can be replaced
					if minetest.registered_nodes[nn]
					and minetest.registered_nodes[nn].buildable_to then

						nn = minetest.get_node({x=x,y=ground_y,z=z}).name

						-- If dirt with grass, add plant in various stages of maturity
						if nn == "default:dirt_with_grass" then
						
							local type = math.random(1,11)
							local plant

							if type == 1 and ground_y > 15 then
								plant = "farming:potato_"..pr:next(3, 4)
							elseif type == 2 then
								plant = "farming:tomato_"..pr:next(7, 8)
							elseif type == 3 then
								plant = "farming:carrot_"..pr:next(7, 8)
							elseif type == 4 then
								plant = "farming:cucumber_4"
							elseif type == 5 then
								plant = "farming:corn_"..pr:next(7, 8)
							elseif type == 6 and ground_y > 20 then
								plant = "farming:coffee_5"
							elseif type == 7 and minetest.find_node_near(p, 3, {"group:water"}) then
								plant = "farming:melon_8"
							elseif type == 8 and ground_y > 15 then
								plant = "farming:pumpkin_8"
							elseif type == 9 and ground_y > 5 then
								plant = "farming:raspberry_4"
							elseif type == 10 and ground_y > 10 then
								plant = "farming:rhubarb_3"
							elseif type == 11 and ground_y > 5 then
								plant = "farming:blueberry_4"
							end

							-- Add plant
							if plant then
								minetest.set_node(p, {name=plant})
							end
						end
					end
				end
			end
		end
	end
end

-- Enable in mapgen v6 only (disabled)

minetest.register_on_mapgen_init(function(mg_params)
	--if mg_params.mgname == "v6" then
		minetest.register_on_generated(farming.mgv6ongen)
	--end
end)
