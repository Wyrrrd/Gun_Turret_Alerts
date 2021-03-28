--control.lua
--This mod scans the map for cars and gun-turrets and places alerts when they are low. 

script.on_init(function (event)
	-- turret index init
	global.turret_entities = {}
	global.car_entities = {}
end)

script.on_nth_tick(3600, function (event)
	--Every minute the surface is rescanned for car and ammo-turret type entities. This is stored in two global tables. 
	for index,surface in pairs(game.surfaces) do
		global.turret_entities[index] = surface.find_entities_filtered{type = "ammo-turret"}
		global.car_entities[index] = surface.find_entities_filtered{type = "car"}
	end
end)

script.on_nth_tick(600, function (event)
	--Every 10 seconds recheck and give alerts to players for car and ammo-turret entities on the same force as them. 
	for _,player in pairs(game.connected_players) do
		
		GTA_turret_enabled = player.mod_settings["gun-turret-alerts-enabled"].value
		GTA_car_enabled = player.mod_settings["gun-turret-alerts-car-enabled"].value
		player_threshold = player.mod_settings["gun-turret-alerts-threshold"].value
		turret_entities = global.turret_entities[player.surface.name]
		car_entities = global.car_entities[player.surface.name]

		if GTA_turret_enabled and turret_entities then
			for _,turret_entity in pairs(turret_entities) do
				if turret_entity.valid and turret_entity.force == player.force then
					inv_var = turret_entity.get_inventory(defines.inventory.turret_ammo)
					if inv_var.is_empty() then
						-- no ammo alert
						player.add_custom_alert(turret_entity, {type = "item", name = "piercing-rounds-magazine"}, "Out of ammo", true)
					elseif inv_var[1].count < player_threshold then
						-- low ammo alert
						player.add_custom_alert(turret_entity, {type = "item", name = "firearm-magazine"}, "Ammo low", true)
					end
				end
			end
		end

		
		if GTA_car_enabled and car_entities then
			for _,car_entity in pairs(car_entities) do
				-- extra check if car has gun
				if car_entity.valid and car_entity.force == player.force and car_entity.selected_gun_index then
					inv_var = car_entity.get_inventory(defines.inventory.car_ammo)
					if inv_var.is_empty() then
						-- no ammo alert
						player.add_custom_alert(car_entity, {type = "item", name = "piercing-rounds-magazine"}, "Out of ammo", true)
					elseif inv_var[1].count < player_threshold then
						-- low ammo alert
						player.add_custom_alert(car_entity, {type = "item", name = "firearm-magazine"}, "Ammo low", true)
					end
				end
			end
		end
	end
end)