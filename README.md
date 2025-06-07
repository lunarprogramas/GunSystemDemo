# GunSystemDemo
Its a RCL gun system for the ROBLOX engine.


# Examples

> This is how you would setup the configuration files for the gun system I made.

Settings in the tool:
return {
	Animations = {
		Equipt = "rbxassetid://129370008286067",
		Fire = "rbxassetid://102645883244277"
	},
	
	Name = "Glock 17",
	Type = "Secondary",
	BurstType = "Automatic",
	
	Damage = 4.6,
	MaxAmmo = 1000,
	FireRate = 0.08
}

Permissions in the tool:
return { "All" }