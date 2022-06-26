Gacha = function(creature: Configuration)
	local forFunction: Configuration = (creature::any).Specifications.Attributes.ForFunction
	local mobility: Configuration = (creature::any).Specifications.Mobility.Agility
	local caps: Configuration = (creature::any).Specifications.MainInfo.Capabilities.Passive

	local isDevOnly = forFunction:GetAttribute("DeveloperUseOnly")
	local hasPaidLimit = forFunction:GetAttribute("HasPaidContentLimits")
	local isLimited = forFunction:GetAttribute("InLimitedGacha")

	if isDevOnly or hasPaidLimit then
		return "(No Gacha)"
	elseif isLimited then
		return "Limited"
	end

	local forcedTarget = forFunction:GetAttribute("ForcedGachaList")
	if not string.isNilOrEmpty(forcedTarget) then
		return forcedTarget
	end

	local flightAnims = (creature::any).CreatureVisuals.Animations.Aerial
	local flySpeed = mobility:GetAttribute("FlySpeed")
	local hasIdle = not string.isNilOrEmpty(flightAnims:GetAttribute("FlyIdle"))
	local hasGlide = not string.isNilOrEmpty(flightAnims:GetAttribute("Glide"))

	local canFly = flySpeed > 0 and hasIdle and hasGlide
	local aquaAffinity = caps:GetAttribute("AquaAffinity")

	local isLandAndSea = aquaAffinity == SonariaConstants.AquaAffinity.SemiAquatic
	if canFly and isLandAndSea then
		return "All Terrain"
	elseif canFly then
		return "Sky"
	elseif aquaAffinity == SonariaConstants.AquaAffinity.Terrestrial then
		return "Land"
	elseif aquaAffinity == SonariaConstants.AquaAffinity.Aquatic then
		return "Sea"
	elseif isLandAndSea then
		return "Semi-Aquatic"
	end

	return "Land" -- This is the fallback in the species object
end;