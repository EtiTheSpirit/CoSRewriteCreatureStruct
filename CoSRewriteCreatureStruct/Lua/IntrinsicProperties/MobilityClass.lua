MobilityClass = function(creature: Configuration)
	local aqua = (creature::any).Specifications.MainInfo.Capabilities.Passive:GetAttribute("AquaAffinity")
	local flightAnimations = (creature::any).CreatureVisuals.Animations.Aerial

	local function IsNilOr0Asset(assetId: string)
		if string.isNilOrEmpty(assetId) then
			return true
		end
		if assetId == "rbxassetid://0" then
			return true
		end
		if assetId == "https://www.roblox.com/asset/?id=0" then
			return true
		end
		return false
	end

	local isFlier = not IsNilOr0Asset(flightAnimations:GetAttribute("FlyIdle")) and not IsNilOr0Asset(flightAnimations:GetAttribute("Glide"))
	if isFlier then
		if aqua == SonariaConstants.AquaAffinity.Terrestrial then
			return "Flier"
		elseif aqua == SonariaConstants.AquaAffinity.Aquatic then
			return "Aquatic Flier"
		elseif aqua == SonariaConstants.AquaAffinity.SemiAquatic then
			return "All Terrain"
		else
			return "Flier + Unrecognized Aqua Affinity \"" .. tostring(aqua) .. "\""
		end
	else
		if aqua == SonariaConstants.AquaAffinity.Terrestrial then
			return "Land"
		elseif aqua == SonariaConstants.AquaAffinity.Aquatic then
			return "Aquatic"
		elseif aqua == SonariaConstants.AquaAffinity.SemiAquatic then
			return "Semi-aquatic"
		else
			return "Unrecognized Aqua Affinity \"" .. tostring(aqua) .. "\""
		end
	end
end;