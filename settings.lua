data:extend({
    {
        type = "bool-setting",
        name = "turret_alerts_enabled",
        setting_type = "runtime-global",
        default_value = true,
        order = "a"
    },
    {
        type = "bool-setting",
        name = "turret_alerts_car_enabled",
        setting_type = "runtime-global",
        default_value = true,
        order = "b"
    },
    {
        type = "bool-setting",
        name = "turret_alerts_tank_enabled",
        setting_type = "runtime-global",
        default_value = true,
        order = "c"
    },
    {
        type = "bool-setting",
        name = "turret_alerts_artillery_enabled",
        setting_type = "runtime-global",
        default_value = true,
        order = "d"
    },
    {
        type = "bool-setting",
        name = "turret_alerts_spidetron_enabled",
        setting_type = "runtime-global",
        default_value = true,
        order = "d"
    },
    {
        type = "int-setting",
        name = "turret_alerts_low_ammo_threshold",
        setting_type = "runtime-global",
        default_value = 8,
        minimum_value = 0,
        order = "e"
    }
})
