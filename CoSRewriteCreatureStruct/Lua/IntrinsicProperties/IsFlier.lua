IsFlier = function(creature: Configuration)
	local agility = (creature::any).Specifications.Mobility.Agility
	local flightAnims = (creature::any).CreatureVisuals.Animations.Aerial

	local flySpeed = agility:GetAttribute("FlySpeed")
	local hasIdle = not string.isNilOrEmpty(flightAnims:GetAttribute("FlyIdle"))
	local hasGlide = not string.isNilOrEmpty(flightAnims:GetAttribute("Glide"))

	return flySpeed > 0 and hasIdle and hasGlide
end;