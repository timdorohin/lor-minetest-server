hunger = {}

-- HUD statbar values
hunger.hunger = {}
hunger.hunger_out = {}

-- HUD item ids
local hunger_hud = {}

HUNGER_HUD_TICK = 0.1

--Some hunger settings
hunger.exhaustion = {} -- Exhaustion is experimental!

HUNGER_HUNGER_TICK = 800 -- time in seconds after that 1 hunger point is taken 
HUNGER_EXHAUST_DIG = 3  -- exhaustion increased this value after digged node
HUNGER_EXHAUST_PLACE = 1 -- exhaustion increased this value after placed
HUNGER_EXHAUST_MOVE = 0.3 -- exhaustion increased this value if player movement detected
HUNGER_EXHAUST_LVL = 160 -- at what exhaustion player saturation gets lowerd


--load custom settings
local set = io.open(minetest.get_modpath("hunger").."/hunger.conf", "r")
if set then 
	dofile(minetest.get_modpath("hunger").."/hunger.conf")
	set:close()
end

local function custom_hud(player)
 if minetest.setting_getbool("enable_damage") then
 --hunger
	hb.init_hudbar(player, "saturation", hunger.get_hunger(player))
 end
end

dofile(minetest.get_modpath("hunger").."/hunger.lua")

-- register saturation hudbar
hb.register_hudbar("saturation", 0xFFFFFF, "Saturation", { icon = "hunger_icon.png", bar = "hunger_bar.png" }, 20, 30, false)

-- update hud elemtens if value has changed
local function update_hud(player)
	local name = player:get_player_name()
 --hunger
	local h_out = tonumber(hunger.hunger_out[name])
	local h = tonumber(hunger.hunger[name])
	if h_out ~= h then
		hunger.hunger_out[name] = h
		hb.change_hudbar(player, "saturation", h)
	end
end

hunger.get_hunger = function(player)
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

hunger.set_hunger = function(player)
	local inv = player:get_inventory()
	local name = player:get_player_name()
	local value = hunger.hunger[name]
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
	hunger.hunger[name] = hunger.get_hunger(player)
	hunger.hunger_out[name] = hunger.hunger[name]
	hunger.exhaustion[name] = 0
	custom_hud(player)
	hunger.set_hunger(player)
end)

minetest.register_on_respawnplayer(function(player)
	-- reset hunger (and save)
	local name = player:get_player_name()
	hunger.hunger[name] = 20
	hunger.set_hunger(player)
	hunger.exhaustion[name] = 0
end)

local main_timer = 0
local timer = 0
local timer2 = 0
minetest.after(2.5, function()
	minetest.register_globalstep(function(dtime)
	 main_timer = main_timer + dtime
	 timer = timer + dtime
	 timer2 = timer2 + dtime
		if main_timer > HUNGER_HUD_TICK or timer > 4 or timer2 > HUNGER_HUNGER_TICK then
		 if main_timer > HUNGER_HUD_TICK then main_timer = 0 end
		 for _,player in ipairs(minetest.get_connected_players()) do
			local name = player:get_player_name()

			-- only proceed if damage is enabled
			if minetest.setting_getbool("enable_damage") then
			 local h = tonumber(hunger.hunger[name])
			 local hp = player:get_hp()
			 if timer > 4 then
				-- heal player by 1 hp if not dead and saturation is > 15 (of 30)
				if h > 15 and hp > 0 and player:get_breath() > 0 then
					player:set_hp(hp+1)
				-- or damage player by 1 hp if saturation is < 2 (of 30)
				elseif h <= 1 and minetest.setting_getbool("enable_damage") then
					if hp-1 >= 0 then player:set_hp(hp-1) end
				end
			 end
			 -- lower saturation by 1 point after xx seconds
			 if timer2 > HUNGER_HUNGER_TICK then
				if h > 0 then
					h = h-1
					hunger.hunger[name] = h
					hunger.set_hunger(player)
				end
			 end

			 -- update all hud elements
			 update_hud(player)
			
			local controls = player:get_player_control()
			-- Determine if the player is walking
			if controls.up or controls.down or controls.left or controls.right then
				hunger.handle_node_actions(nil, nil, player)
			end
			end
		 end
		
		end
		if timer > 4 then timer = 0 end
		if timer2 > HUNGER_HUNGER_TICK then timer2 = 0 end
	end)
end)
