hud = {}

-- HUD statbar values
hud.hunger = {}
hud.hunger_out = {}

-- HUD item ids
local hunger_hud = {}

HUD_TICK = 0.1

--Some hunger settings
hud.exhaustion = {} -- Exhaustion is experimental!

HUD_HUNGER_TICK = 800 -- time in seconds after that 1 hunger point is taken 
HUD_HUNGER_EXHAUST_DIG = 3  -- exhaustion increased this value after digged node
HUD_HUNGER_EXHAUST_PLACE = 1 -- exhaustion increased this value after placed
HUD_HUNGER_EXHAUST_MOVE = 0.3 -- exhaustion increased this value if player movement detected
HUD_HUNGER_EXHAUST_LVL = 160 -- at what exhaustion player saturation gets lowerd


--load custom settings
local set = io.open(minetest.get_modpath("hunger").."/hud.conf", "r")
if set then 
	dofile(minetest.get_modpath("hunger").."/hud.conf")
	set:close()
end

local function custom_hud(player)
 local name = player:get_player_name()

 if minetest.setting_getbool("enable_damage") then
 --hunger
       	 player:hud_add({
		hud_elem_type = "statbar",
		position = HUD_HUNGER_POS,
		size = HUD_SIZE,
		text = "hud_hunger_bg.png",
		number = 20,
		alignment = {x=-1,y=-1},
		offset = HUD_HUNGER_OFFSET,
	 })
	local h = hud.hunger[name]
	if h == nil or h > 20 then h = 20 end
	 hunger_hud[name] = player:hud_add({
		hud_elem_type = "statbar",
		position = HUD_HUNGER_POS,
		size = HUD_SIZE,
		text = "hud_hunger_fg.png",
		number = h,
		alignment = {x=-1,y=-1},
		offset = HUD_HUNGER_OFFSET,
	 })
 end
end

dofile(minetest.get_modpath("hunger").."/hunger.lua")

-- update hud elemtens if value has changed
local function update_hud(player)
	local name = player:get_player_name()
 --hunger
	local h_out = tonumber(hud.hunger_out[name])
	local h = tonumber(hud.hunger[name])
	if h_out ~= h then
		hud.hunger_out[name] = h
		-- bar should not have more than 10 icons
		if h>20 then h=20 end
		player:hud_change(hunger_hud[name], "number", h)
	end
end

hud.get_hunger = function(player)
	local inv = player:get_inventory()
	if not inv then return nil end
	local hgp = inv:get_stack("hunger", 1):get_count()
	if hgp == 0 then
		hgp = 21
		inv:set_stack("hunger", 1, ItemStack({name=":", count=hgp}))
	else
		hgp = hgp
	end
	return hgp-1
end

hud.set_hunger = function(player)
	local inv = player:get_inventory()
	local name = player:get_player_name()
	local value = hud.hunger[name]
	if not inv  or not value then return nil end
	if value > 30 then value = 30 end
	if value < 0 then value = 0 end
	
	inv:set_stack("hunger", 1, ItemStack({name=":", count=value+1}))

	return true
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local inv = player:get_inventory()
	inv:set_size("hunger",1)
	hud.hunger[name] = hud.get_hunger(player)
	hud.hunger_out[name] = hud.hunger[name]
	hud.exhaustion[name] = 0
	custom_hud(player)
	hud.set_hunger(player)
end)

minetest.register_on_respawnplayer(function(player)
	-- reset hunger (and save)
	local name = player:get_player_name()
	hud.hunger[name] = 20
	hud.set_hunger(player)
	hud.exhaustion[name] = 0
end)

local main_timer = 0
local timer = 0
local timer2 = 0
minetest.after(2.5, function()
	minetest.register_globalstep(function(dtime)
	 main_timer = main_timer + dtime
	 timer = timer + dtime
	 timer2 = timer2 + dtime
		if main_timer > HUD_TICK or timer > 4 or timer2 > HUD_HUNGER_TICK then
		 if main_timer > HUD_TICK then main_timer = 0 end
		 for _,player in ipairs(minetest.get_connected_players()) do
			local name = player:get_player_name()

			-- only proceed if damage is enabled
			if minetest.setting_getbool("enable_damage") then
			 local h = tonumber(hud.hunger[name])
			 local hp = player:get_hp()
			 if HUD_ENABLE_HUNGER and timer > 4 then
				-- heal player by 1 hp if not dead and saturation is > 15 (of 30)
				if h > 15 and hp > 0 and player:get_breath() > 0 then
					player:set_hp(hp+1)
				-- or damage player by 1 hp if saturation is < 2 (of 30)
				elseif h <= 1 and minetest.setting_getbool("enable_damage") then
					if hp-1 >= 0 then player:set_hp(hp-1) end
				end
			 end
			 -- lower saturation by 1 point after xx seconds
			 if timer2 > HUD_HUNGER_TICK then
				if h > 0 then
					h = h-1
					hud.hunger[name] = h
					hud.set_hunger(player)
				end
			 end

			 -- update all hud elements
			 update_hud(player)
			
			local controls = player:get_player_control()
			-- Determine if the player is walking
			if controls.up or controls.down or controls.left or controls.right then
				hud.handle_node_actions(nil, nil, player)
			end
			end
		 end
		
		end
		if timer > 4 then timer = 0 end
		if timer2 > HUD_HUNGER_TICK then timer2 = 0 end
	end)
end)
