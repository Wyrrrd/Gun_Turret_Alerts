--control.lua
--This mod scans the map for gun-turrets and places alerts when turrets are low. 

script.on_init(function (event)
	-- turret index init
	global.turret_entities = {}
end)

script.on_nth_tick(3600, function (event)
	--Every minute the surface is rescanned for ammo-turret type entities. This is stored in the global table. 
	for index,surface in pairs(game.surfaces) do
		global.turret_entities[index] = surface.find_entities_filtered{type = "ammo-turret"}
	end
end)

script.on_nth_tick(600, function (event)
	--Every 10 seconds recheck and give alerts to players for ammo-turret entities on the same force as them. 
	for _,player in pairs(game.connected_players) do
		
		GTA_enabled = player.mod_settings["gun-turret-alerts-enabled"].value
		player_threshold = player.mod_settings["gun-turret-alerts-threshold"].value
		turret_entities = global.turret_entities[player.surface.name]

		if GTA_enabled and turret_entities then
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
	end
end)