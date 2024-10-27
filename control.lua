-- Constants
local CHECK_INTERVAL = 600  -- 10 sec (600 t)

-- Checking the ammo level for an entity
local function check_ammo(entity, ammo_threshold)
    if entity and entity.valid then
        local inventory

        -- Determining the type of inventory
        if entity.type == "ammo-turret" or entity.type == "artillery-turret" then
            inventory = entity.get_inventory(defines.inventory.turret_ammo)
        elseif entity.type == "artillery-wagon" then
            inventory = entity.get_inventory(defines.inventory.artillery_wagon_ammo)
        elseif entity.type == "car" then
            inventory = entity.get_inventory(defines.inventory.car_ammo)
        elseif entity.type == "tank" then
            inventory = entity.get_inventory(defines.inventory.tank_ammo)
        elseif entity.type == "spider-vehicle" then
            inventory = entity.get_inventory(defines.inventory.spider_ammo)
        end

        if inventory and #inventory > 0 then
            local low_ammo = false
            for i = 1, #inventory do
                local ammo = inventory[i].count
                if ammo == 0 then
                    return "NO_AMMO"  -- No ammo in any slot
                elseif ammo < ammo_threshold then
                    low_ammo = true  -- At least one low ammo slot
                end
            end
            if low_ammo then
                return "LOW_AMMO"
            end
        end
    end
    return nil
end

-- Event handler for checking ammo level
local function on_tick(event)
    if event.tick % CHECK_INTERVAL ~= 0 then return end

    local ammo_threshold = settings.global["turret_alerts_low_ammo_threshold"].value
    local turret_alerts_enabled = settings.global["turret_alerts_enabled"].value
    local car_alerts_enabled = settings.global["turret_alerts_car_enabled"].value
    local artillery_alerts_enabled = settings.global["turret_alerts_artillery_enabled"].value
    local tank_alerts_enabled = settings.global["turret_alerts_tank_enabled"].value
    local spidetron_alerts_enabled = settings.global["turret_alerts_spidetron_enabled"].value

    for _, player in pairs(game.connected_players) do
        local alerts = {}
        for _, surface in pairs(game.surfaces) do

            -- Checking ammo levels for turrets
            if turret_alerts_enabled then
                for _, turret in pairs(surface.find_entities_filtered{type = {"ammo-turret", "artillery-turret"}}) do
                    local status = check_ammo(turret, ammo_threshold)
                    if status == "NO_AMMO" then
                        table.insert(alerts, {entity = turret, icon = {type = "virtual", name = "no_ammo_signal"}, message = {"alerts.empty"}})
                    elseif status == "LOW_AMMO" then
                        table.insert(alerts, {entity = turret, icon = {type = "virtual", name = "low_ammo_signal"}, message = {"alerts.low"}})
                    end
                end
            end

            -- Checking vehicle ammunition levels
            if car_alerts_enabled then
                for _, vehicle in pairs(surface.find_entities_filtered{type = "car"}) do
                    local status = check_ammo(vehicle, ammo_threshold)
                    if status == "NO_AMMO" then
                        table.insert(alerts, {entity = vehicle, icon = {type = "virtual", name = "no_ammo_signal"}, message = {"alerts.empty"}})
                    elseif status == "LOW_AMMO" then
                        table.insert(alerts, {entity = vehicle, icon = {type = "virtual", name = "low_ammo_signal"}, message = {"alerts.low"}})
                    end
                end
            end
            
            -- Checking the ammunition level for artillery wagons
            if artillery_alerts_enabled then
                for _, artillery in pairs(surface.find_entities_filtered{type = "artillery-wagon"}) do
                    local status = check_ammo(artillery, ammo_threshold)
                    if status == "NO_AMMO" then
                        table.insert(alerts, {entity = artillery, icon = {type = "virtual", name = "no_ammo_signal"}, message = {"alerts.empty"}})
                    elseif status == "LOW_AMMO" then
                        table.insert(alerts, {entity = artillery, icon = {type = "virtual", name = "low_ammo_signal"}, message = {"alerts.low"}})
                    end
                end
            end
            
            -- Checking tank ammunition levels
            if tank_alerts_enabled then
                for _, tank in pairs(surface.find_entities_filtered{type = "tank"}) do
                    local status = check_ammo(tank, ammo_threshold)
                    if status == "NO_AMMO" then
                        table.insert(alerts, {entity = tank, icon = {type = "virtual", name = "no_ammo_signal"}, message = {"alerts.empty"}})
                    elseif status == "LOW_AMMO" then
                        table.insert(alerts, {entity = tank, icon = {type = "virtual", name = "low_ammo_signal"}, message = {"alerts.low"}})
                    end
                end
            end

            -- Checking Spidertron Ammo Levels
            if spidetron_alerts_enabled then
                for _, spidetron in pairs(surface.find_entities_filtered{type = "spider-vehicle"}) do
                    local status = check_ammo(spidetron, ammo_threshold)
                    if status == "NO_AMMO" then
                        table.insert(alerts, {entity = spidetron, icon = {type = "virtual", name = "no_ammo_signal"}, message = {"alerts.empty"}})
                    elseif status == "LOW_AMMO" then
                        table.insert(alerts, {entity = spidetron, icon = {type = "virtual", name = "low_ammo_signal"}, message = {"alerts.low"}})
                    end
                end
            end
        end
        
        -- Display alerts for a player with a localized entity name
        for _, alert in pairs(alerts) do
            player.add_custom_alert(alert.entity, alert.icon, {"", alert.entity.localised_name, " ", alert.message}, true)
        end
    end
end

-- Registering the on_tick event
script.on_event(defines.events.on_tick, on_tick)
