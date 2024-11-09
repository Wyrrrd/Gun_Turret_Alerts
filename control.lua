--control.lua
--This mod scans the map for gun-turrets, vehicles and artillery and places alerts when they are low on ammo.

--util functions

function table_is_empty(table)
    for _,_ in pairs(table) do
        return false
    end
    return true
end


--local functions

local get_ammo_flag = {
	--Applies mode to inventory, calculates and returns respective inventory flags
	--Uses boolean return value as ternary, with true = no ammo, false = low ammo and nil = enough ammo
	["added"] = function (inventory,player_threshold)
		if inventory.is_empty() then
			return true
		else
			local ammo_count = 0
			for i=1, #inventory do
				ammo_count = ammo_count + inventory[i].count
			end
			if ammo_count == 0 then
				return true
			elseif ammo_count < player_threshold then
				return false
			end
		end
	end,

	["individually"] = function (inventory,player_threshold)
		if inventory.is_empty() then
			return true
		else
			for i=1, #inventory do
				if inventory[i].count == 0 then
					return true
				elseif inventory[i].count < player_threshold then
					return false
				end
			end
		end
	end,

	["selected"] = function (inventory,player_threshold,gun_index)
		if inventory.is_empty() then
			return true
		else
			if not gun_index then
				-- default to first slot if no slot selected (probably multislot turret)
				gun_index = 1
			end
			if inventory[gun_index].count == 0 then
				return true
			elseif inventory[gun_index].count < player_threshold then
				return false
			end
		end
	end
}

local function add_entity_to_list(event)
	--Whenever an ammo-turret, vehicle or artillery type entity is built, add it to the global table.
	local entity = event.created_entity or event.entity
	local index = entity.surface.name.."_"..entity.force.name
	if storage.ammo_entities[index] then
		table.insert(storage.ammo_entities[index], entity)
	end
end

local function remove_entity_from_list(event)
	--Whenever an ammo-turret, vehicle or artillery type entity dies / is mined, remove it from the global table.
	local index = event.entity.surface.name.."_"..event.entity.force.name
	if storage.ammo_entities[index] then
		for i,entity in pairs(storage.ammo_entities[index]) do
			if (entity == event.entity) then
				table.remove(storage.ammo_entities[index], i)
				break
			end
		end
	end
end

local function add_force_to_list(event)
	--Whenever a player of an unscanned force joins the game or a force is created, add all ammo-turret, vehicle or artillery type entities of that force to the global table.
	local player, force
	if event.player_index then
		player = game.get_player(event.player_index)
		if player and player.valid then
			force = player.force
		end
	elseif event.force then
		force = event.force
		if force.valid and force.connected_players then
			player = force.connected_players[1]
		end
	end

	if player and player.valid and force and force.valid and not storage.ammo_entities[player.surface.name.."_"..force.name] then
		for _,surface in pairs(game.surfaces) do
			storage.ammo_entities[surface.name.."_"..force.name] = surface.find_entities_filtered{type = {"ammo-turret","car","artillery-turret","artillery-wagon","spider-vehicle"}, force = force, to_be_deconstructed = false}
		end
	end
end

local function remove_force_from_list(event)
	--Whenever the last player of a force leaves the game or forces are merged, remove all entities of that force from the global table.
	local force
	local param = {}
	if event.player_index and event.force then
		param.player_index = event.player_index
		add_force_to_list(param)
		force = event.force
	elseif event.player_index then
		force = game.get_player(event.player_index).force
	elseif event.force then
		force = event.force
	elseif event.source and event.destination then
		param.force = event.destination
		add_force_to_list(param)
		force = event.source
	end

	if force and not force.connected_players then
		for surface_name,_ in pairs(game.surfaces) do
			storage.ammo_entities[surface_name.."_"..force.name] = nil
		end
	end
end

local function remove_surface_from_list(event)
	--Whenever a surface is renamed or deleted, move/remove all entities in/from the global table.
	for _,force in pairs(game.forces) do
		local index
		if event.new_name then
			storage.ammo_entities[event.new_name.."_"..force.name] = table.deepcopy(storage.ammo_entities[event.old_name.."_"..force.name])
			index = event.old_name.."_"..force.name
		elseif event.surface_index then
			index = game.surfaces[event.surface_index].name.."_"..force.name
		end

		if index then
			storage.ammo_entities[index] = nil
		end
	end
end

local function init_list()
	--Create global table for existing forces
	storage.ammo_entities = {}
	local param = {}
	for _,force in pairs(game.forces) do
		param.force = force
		add_force_to_list(param)
	end
end

local function generate_alerts()
	--Every 10 seconds recheck and give alerts to players for ammo-turret, vehicle, spidertron or artillery type entities on the same force as them.
	for _,player in pairs(game.connected_players) do

		local turret_enabled = player.mod_settings["gun-turret-alerts-enabled"].value
		local car_enabled = player.mod_settings["gun-turret-alerts-car-enabled"].value
		local artillery_enabled = player.mod_settings["gun-turret-alerts-artillery-enabled"].value
		local mode = player.mod_settings["gun-turret-alerts-mode"].value
		local player_threshold = player.mod_settings["gun-turret-alerts-threshold"].value
		local autofull = player.mod_settings["gun-turret-alerts-z-automated-full"].value
		local ammo_entities = storage.ammo_entities[player.surface.name.."_"..player.force.name]

		if ammo_entities then
			for index,entity in pairs(ammo_entities) do
				if entity.valid then
					if entity.force == player.force then

						--Get ammo inventory based on entity type, skip vehicles without guns
						local inventory
						if turret_enabled and entity.type == "ammo-turret" then
							inventory = entity.get_inventory(defines.inventory.turret_ammo)
						elseif car_enabled and (entity.type == "car" or entity.type == "spider-vehicle") and not table_is_empty(entity.prototype.guns) then
							inventory = entity.get_inventory(defines.inventory.car_ammo)
						elseif artillery_enabled then
							if entity.type == "artillery-turret" then
								inventory = entity.get_inventory(defines.inventory.artillery_turret_ammo)
							elseif entity.type == "artillery-wagon" then
								inventory = entity.get_inventory(defines.inventory.artillery_wagon_ammo)
							end
						end

						--Check for states of no or low ammo based on mode
						local ammo_flag
						if inventory and get_ammo_flag[mode] then
							if entity.type == "ammo-turret" or entity.type == "artillery-turret" or entity.type == "artillery-wagon" then
								ammo_flag = get_ammo_flag[mode](inventory, player_threshold)
								if autofull and entity.prototype.automated_ammo_count then
									if entity.prototype.automated_ammo_count < player_threshold then
										ammo_flag = get_ammo_flag[mode](inventory, entity.prototype.automated_ammo_count)
									end
								end
							elseif entity.type == "car" or entity.type == "spider-vehicle" then
								ammo_flag = get_ammo_flag[mode](inventory, player_threshold, entity.selected_gun_index)
							end
						end

						--Create alert for present state
						if ammo_flag then
							-- no ammo alert
							player.add_custom_alert(entity, {type = "virtual", name = "ammo-icon-red"}, {"gun-turret-alerts.message-empty", entity.localised_name}, true)
						elseif ammo_flag == false then
							-- low ammo alert
							player.add_custom_alert(entity, {type = "virtual", name = "ammo-icon-yellow"}, {"gun-turret-alerts.message-low", entity.localised_name}, true)
						end
					end
				else
					ammo_entities[index] = nil
				end
			end
		end
	end
end


-- Event handlers

script.on_init(init_list)
script.on_configuration_changed(init_list)

script.on_event(defines.events.on_player_joined_game, add_force_to_list)
script.on_event(defines.events.on_player_left_game, remove_force_from_list)
script.on_event(defines.events.on_player_changed_force, remove_force_from_list)

script.on_event(defines.events.on_force_created, add_force_to_list)
script.on_event(defines.events.on_forces_merged, remove_force_from_list)

script.on_event(defines.events.on_surface_renamed, remove_surface_from_list)
script.on_event(defines.events.on_pre_surface_deleted, remove_surface_from_list)

script.on_event(defines.events.on_built_entity, add_entity_to_list, {{filter="type", type = "ammo-turret"},{filter="type", type = "car"},{filter="type", type = "spider-vehicle"},{filter="type", type = "artillery-turret"},{filter="type", type = "artillery-wagon"}})
script.on_event(defines.events.on_robot_built_entity, add_entity_to_list, {{filter="type", type = "ammo-turret"},{filter="type", type = "car"},{filter="type", type = "spider-vehicle"},{filter="type", type = "artillery-turret"},{filter="type", type = "artillery-wagon"}})
script.on_event(defines.events.script_raised_built, add_entity_to_list, {{filter="type", type = "ammo-turret"},{filter="type", type = "car"},{filter="type", type = "spider-vehicle"},{filter="type", type = "artillery-turret"},{filter="type", type = "artillery-wagon"}})
script.on_event(defines.events.script_raised_revive, add_entity_to_list, {{filter="type", type = "ammo-turret"},{filter="type", type = "car"},{filter="type", type = "spider-vehicle"},{filter="type", type = "artillery-turret"},{filter="type", type = "artillery-wagon"}})

script.on_event(defines.events.on_player_mined_entity, remove_entity_from_list, {{filter="type", type = "ammo-turret"},{filter="type", type = "car"},{filter="type", type = "spider-vehicle"},{filter="type", type = "artillery-turret"},{filter="type", type = "artillery-wagon"}})
script.on_event(defines.events.on_robot_mined_entity, remove_entity_from_list, {{filter="type", type = "ammo-turret"},{filter="type", type = "car"},{filter="type", type = "spider-vehicle"},{filter="type", type = "artillery-turret"},{filter="type", type = "artillery-wagon"}})
script.on_event(defines.events.on_entity_died, remove_entity_from_list, {{filter="type", type = "ammo-turret"},{filter="type", type = "car"},{filter="type", type = "spider-vehicle"},{filter="type", type = "artillery-turret"},{filter="type", type = "artillery-wagon"}})
script.on_event(defines.events.script_raised_destroy, remove_entity_from_list, {{filter="type", type = "ammo-turret"},{filter="type", type = "car"},{filter="type", type = "spider-vehicle"},{filter="type", type = "artillery-turret"},{filter="type", type = "artillery-wagon"}})

script.on_nth_tick(600, generate_alerts)