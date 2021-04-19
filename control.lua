--control.lua
--This mod scans the map for cars and gun-turrets and places alerts when they are low. 

local get_ammo_flags = {
	["added"] = function (inventory)
		local no,low = false
		if inventory.is_empty() then
			no = true
		else
			local ammo_count = 0
			for i=1, #inventory do
				ammo_count = ammo_count + inventory[i].count
			end
			if ammo_count == 0 then
				no = true
			elseif ammo_count < player_threshold then
				low = true
			end
		end
		return no, low
	end,
	
	["individually"] = function (inventory)
		local no,low = false
		if inventory.is_empty() then
			no = true
		else
			for i=1, #inventory do
				if inventory[i].count == 0 then
					no = true
				elseif inventory[i].count < player_threshold then
					low = true
				end
			end
		end
		return no, low
	end,

	["selected"] = function (inventory,gun_index)
		local no,low = false
		if inventory.is_empty() then
			no = true
		else
			if not gun_index then
				gun_index = 1
			end
			if inventory[gun_index].count == 0 then
				no = true
			elseif inventory[gun_index].count < player_threshold then
				low = true
			end
		end
		return no, low
	end
}


script.on_init(function (event)
	-- index init
	global.ammo_entities = {}
end)

script.on_configuration_changed(function (event)
	-- index init fix
	global.ammo_entities = {}
end)

script.on_nth_tick(3600, function (event)
	--Every minute the surface is rescanned for car and ammo-turret type entities. This is stored in two global tables. 
	for index,surface in pairs(game.surfaces) do
		global.ammo_entities[index] = surface.find_entities_filtered{type = {"ammo-turret","car"}}
	end
end)

script.on_nth_tick(600, function (event)
	--Every 10 seconds recheck and give alerts to players for car and ammo-turret entities on the same force as them. 
	for _,player in pairs(game.connected_players) do
		
		turret_enabled = player.mod_settings["gun-turret-alerts-enabled"].value
		car_enabled = player.mod_settings["gun-turret-alerts-car-enabled"].value
		mode = player.mod_settings["gun-turret-alerts-mode"].value
		player_threshold = player.mod_settings["gun-turret-alerts-threshold"].value
		ammo_entities = global.ammo_entities[player.surface.name]

		if ammo_entities then
			for _,entity in pairs(ammo_entities) do
				if entity.valid and entity.force == player.force then

					local inventory
					if turret_enabled and entity.type == "ammo-turret" then
						inventory = entity.get_inventory(defines.inventory.turret_ammo)
					elseif car_enabled and entity.type == "car" and entity.prototype.guns then
						inventory = entity.get_inventory(defines.inventory.car_ammo)
					end

					local no, low = false
					if inventory and get_ammo_flags[mode] then
						if entity.type == "ammo-turret" then
							no, low = get_ammo_flags[mode](inventory)
						elseif entity.type == "car" then
							no, low = get_ammo_flags[mode](inventory,entity.selected_gun_index)
						end
					end

					if no then
						-- no ammo alert
						player.add_custom_alert(entity, {type = "virtual", name = "ammo-icon-red"}, {"gun-turret-alerts.message-empty", entity.localised_name}, true)
					elseif low then
						-- low ammo alert
						player.add_custom_alert(entity, {type = "virtual", name = "ammo-icon-yellow"}, {"gun-turret-alerts.message-low", entity.localised_name}, true)
					end
				end
			end
		end
	end
end)