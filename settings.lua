--settings.lua


data:extend({
    {
        type = "bool-setting",
        name = "gun-turret-alerts-enabled",
        setting_type = "runtime-per-user",
        default_value = true
    },
	{
        type = "int-setting",
        name = "gun-turret-alerts-threshold",
        setting_type = "runtime-per-user",
        default_value = 8,
		minimum_value = 0
		
    }
	
})