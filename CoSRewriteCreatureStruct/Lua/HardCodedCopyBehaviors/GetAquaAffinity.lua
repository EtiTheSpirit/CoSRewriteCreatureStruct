GetAquaAffinity = function(legacyCreature: Folder, newCreature: Configuration)
	local data = legacyCreature:FindFirstChild("Data") :: Instance
	local data = data:FindFirstChild("Stats") :: Instance
	local isAquatic = data:FindFirstChild("Aquatic") ~= nil
	local isSemi = data:FindFirstChild("SemiAquatic") ~= nil
	local flierInfo = data:FindFirstChild("FlySpeed")
	if flierInfo and (flierInfo::any).Value > 0 and isSemi then
		(newCreature::any).Specifications.MainInfo.Capabilities.Passive:SetAttribute("AquaAffinity", SonariaConstants.AquaAffinity.AllTerrain)
	elseif isAquatic then
		(newCreature::any).Specifications.MainInfo.Capabilities.Passive:SetAttribute("AquaAffinity", SonariaConstants.AquaAffinity.Aquatic)
	elseif isSemi then
		(newCreature::any).Specifications.MainInfo.Capabilities.Passive:SetAttribute("AquaAffinity", SonariaConstants.AquaAffinity.SemiAquatic)
	else
		(newCreature::any).Specifications.MainInfo.Capabilities.Passive:SetAttribute("AquaAffinity", SonariaConstants.AquaAffinity.Terrestrial)
	end
end;