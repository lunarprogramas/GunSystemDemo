# GunSystemDemo
Its a RCL gun system for the ROBLOX engine.
You require permission from me if you wish to use it, unauthorized usage is not permitted and will result in a DMCA claim.


# Examples

> This is how you would setup the configuration files for the gun system I made.

Settings in the tool:
```lua
return {
	Animations = {
		Equipt = "rbxassetid://129370008286067",
		Fire = "rbxassetid://102645883244277",
		Reload = "rbxassetid://123140806968534"
	},
	
	Name = "Glock 17",
	Type = "Secondary",
	BurstType = "Single",
	
	Damage = 4.6,
	MaxAmmo = 15,
	FireRate = 0.05,
	ReloadTime = 2.5
}
```

Permissions in the tool:
```lua
return { "All" }
```
