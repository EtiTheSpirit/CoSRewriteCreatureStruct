FlightType = function(creature: Configuration)
	local agility = (creature::any).Specifications.Mobility.Agility
	local flightAnims = (creature::any).CreatureVisuals.Animations.Aerial
	local passive = (creature::any).Specifications.MainInfo.Capabilities.Passive

	local flySpeed = agility:GetAttribute("FlySpeed")
	local hasIdle = not string.isNilOrEmpty(flightAnims:GetAttribute("FlyIdle"))
	local hasGlide = not string.isNilOrEmpty(flightAnims:GetAttribute("Glide"))

	local isFlier = flySpeed > 0 and hasIdle and hasGlide
	local isOnlyGlider = passive:GetAttribute("OnlyGlide") == true and isFlier

	if not isFlier then
		return "Cannot Fly"
	elseif isFlier and not isOnlyGlider then
		return "Flier"
	elseif isFlier and isOnlyGlider then
		return "Glider"
	else
		return "what"
	end
end;