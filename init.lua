hud = {}

-- HUD statbar values
hud.armor = {}
hud.armor_out = {}

-- HUD item ids
local armor_hud = {}
local armor_hud_bg = {}

HUD_TICK = 0.1

--load custom settings
local set = io.open(minetest.get_modpath("hbarmor").."/hud.conf", "r")
if set then 
	dofile(minetest.get_modpath("hbarmor").."/hud.conf")
	set:close()
end

local function custom_hud(player)
 local name = player:get_player_name()

 if minetest.setting_getbool("enable_damage") then
	hb.init_hudbar(player, "armor")
 end
end

--register and define armor HUD bar
hb.register_hudbar("armor", 0xFFFFFF, "Armor", { icon = "hbarmor_icon.png", bar = "hbarmor_bar.png" }, 0, 20, false, "%s: %d/%d")

--needs to be defined for older version of 3darmor
function hud.set_armor()
end


dofile(minetest.get_modpath("hbarmor").."/armor.lua")

-- update hud elemtens if value has changed
local function update_hud(player)
	local name = player:get_player_name()
 --armor
	local arm_out = tonumber(hud.armor_out[name])
	if not arm_out then arm_out = 0 end
	local arm = tonumber(hud.armor[name])
	if not arm then arm = 0 end
	if arm_out ~= arm then
		hud.armor_out[name] = arm
		hb.change_hudbar(player, "armor", arm)
		-- hide armor bar completely when there is none
		if (not armor.def[name].count or armor.def[name].count == 0) and arm == 0 then
			hb.hide_hudbar(player, "armor")
		else
			hb.unhide_hudbar(player, "armor")
		end
	end
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	hud.armor[name] = 0
	hud.armor_out[name] = 0
	custom_hud(player)
end)

minetest.register_on_respawnplayer(function(player)
end)

local main_timer = 0
local timer = 0
minetest.after(2.5, function()
	minetest.register_globalstep(function(dtime)
	 main_timer = main_timer + dtime
	 timer = timer + dtime
		if main_timer > HUD_TICK or timer > 4 then
		 if main_timer > HUD_TICK then main_timer = 0 end
		 for _,player in ipairs(minetest.get_connected_players()) do
			local name = player:get_player_name()

			-- only proceed if damage is enabled
			if minetest.setting_getbool("enable_damage") then
			 hud.get_armor(player)

			 -- update all hud elements
			 update_hud(player)
			
			end
		 end
		
		end
		if timer > 4 then timer = 0 end
	end)
end)
