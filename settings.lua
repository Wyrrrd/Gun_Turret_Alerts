--settings.lua


data:extend({
    {
        type = "bool-setting",
        name = "gun-turret-alerts-enabled",
        setting_type = "runtime-per-user",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "gun-turret-alerts-car-enabled",
        setting_type = "runtime-per-user",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "gun-turret-alerts-artillery-enabled",
        setting_type = "runtime-per-user",
        default_value = false
    },
    {
        type = "string-setting",
        name = "gun-turret-alerts-mode",
        setting_type = "runtime-per-user",
        allowed_values = {"added","individually","selected"},
        default_value = "selected"
    },
	{
        type = "int-setting",
        name = "gun-turret-alerts-threshold",
        setting_type = "runtime-per-user",
        default_value = 8,
		minimum_value = 0
    },
})