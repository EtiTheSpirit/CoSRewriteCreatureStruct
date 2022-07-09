EnableIfCanFly = function(creature: Instance, attributeContainer: Instance, attrName: string, attrValue: any): (boolean, string?, number?)
	local agility = (creature::any).Specifications.Mobility.Agility
	local flightAnims = (creature::any).CreatureVisuals.Animations.Aerial

	local flySpeed = agility:GetAttribute("FlySpeed")
	local hasIdle = not string.isNilOrEmpty(flightAnims:GetAttribute("FlyIdle"))
	local hasGlide = not string.isNilOrEmpty(flightAnims:GetAttribute("Glide"))

	local isFlier = flySpeed > 0 and hasIdle and hasGlide

	if isFlier then
		return true, nil, nil
	else
		return false, "This creature is not a flier, so this property does nothing.", 1
	end
end;