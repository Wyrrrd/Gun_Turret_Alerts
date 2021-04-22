--control.lua
--This mod scans the map for cars and gun-turrets and places alerts when they are low on ammo.

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
	--Whenever an ammo-turret or car type entity is built, add it to the global table.
	local index = event.created_entity.surface.name.."_"..event.created_entity.force.name
	if global.ammo_entities[index] then
		table.insert(global.ammo_entities[index], event.created_entity)
	end
end

local function remove_entity_from_list(event)
	--Whenever an ammo-turret or car type entity dies / is mined, remove it from the global table.
	local index = event.entity.surface.name.."_"..event.entity.force.name
	if global.ammo_entities[index] then
		for i,entity in pairs(global.ammo_entities[index]) do
			if (entity == event.entity) then
				table.remove(global.ammo_entities[index], i)
				break
			end
		end
	end
end

local function add_force_to_list(event)
	--Whenever a player of an unscanned force joins the game or a force is created, add all ammo-turret or car type entities of that force to the global table.
	local player, force
	if event.player_index then
		player = game.get_player(event.player_index)
		force = player.force
	elseif event.force then
		force = event.force
		if force.connected_players then
			player = force.connected_players[1]
		end
	end

	if player and force and not global.ammo_entities[player.surface.name.."_"..force.name] then
		for _,surface in pairs(game.surfaces) do
			global.ammo_entities[surface.name.."_"..force.name] = surface.find_entities_filtered{type = {"ammo-turret","car"}, force = force, to_be_deconstructed = false}
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
		force = source
	end

	if force and not force.connected_players then
		for surface_name,_ in pairs(game.surfaces) do
			global.ammo_entities[surface_name.."_"..force.name] = nil
		end
	end
end

local function init_list()
	-- index init
	global.ammo_entities = {}
	local param = {}
	for _,force in pairs(game.forces) do
		param.force = force
		add_force_to_list(param)
	end
end

local function generate_alerts()
	--Every 10 seconds recheck and give alerts to players for car and ammo-turret entities on the same force as them.
	for _,player in pairs(game.connected_players) do
		
		local turret_enabled = player.mod_settings["gun-turret-alerts-enabled"].value
		local car_enabled = player.mod_settings["gun-turret-alerts-car-enabled"].value
		local mode = player.mod_settings["gun-turret-alerts-mode"].value
		local player_threshold = player.mod_settings["gun-turret-alerts-threshold"].value
		local ammo_entities = global.ammo_entities[player.surface.name.."_"..player.force.name]

		if ammo_entities then
			for _,entity in pairs(ammo_entities) do
				if entity.valid and entity.force == player.force then

					--Get ammo inventory based on entity type, skip cars without guns
					local inventory
					if turret_enabled and entity.type == "ammo-turret" then
						inventory = entity.get_inventory(defines.inventory.turret_ammo)
					elseif car_enabled and entity.type == "car" and not table_is_empty(entity.prototype.guns) then
						inventory = entity.get_inventory(defines.inventory.car_ammo)
					end

					--Check for states of no or low ammo based on mode
					local ammo_flag
					if inventory and get_ammo_flag[mode] then
						if entity.type == "ammo-turret" then
							ammo_flag = get_ammo_flag[mode](inventory, player_threshold)
						elseif entity.type == "car" then
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

script.on_event(defines.events.on_built_entity, add_entity_to_list, {{filter="type", type = "ammo-turret"},{filter="type", type = "car"}})
script.on_event(defines.events.on_robot_built_entity, add_entity_to_list, {{filter="type", type = "ammo-turret"},{filter="type", type = "car"}})

script.on_event(defines.events.on_player_mined_entity, remove_entity_from_list, {{filter="type", type = "ammo-turret"},{filter="type", type = "car"}})
script.on_event(defines.events.on_robot_mined_entity, remove_entity_from_list, {{filter="type", type = "ammo-turret"},{filter="type", type = "car"}})
script.on_event(defines.events.on_entity_died, remove_entity_from_list, {{filter="type", type = "ammo-turret"},{filter="type", type = "car"}})

script.on_nth_tick(600, generate_alerts)