GetAquaAffinity = function(legacyCreature: Folder, newCreature: Configuration)
	local data = legacyCreature:FindFirstChild("Data") :: Instance
	local data = data:FindFirstChild("Stats") :: Instance
	local isAquatic = data:FindFirstChild("Aquatic") ~= nil
	local isSemi = data:FindFirstChild("SemiAquatic") ~= nil
	if isAquatic then
		(newCreature::any).Specifications.MainInfo.Capabilities.Passive:SetAttribute("AquaAffinity", SonariaConstants.AquaAffinity.Aquatic)
	elseif isSemi then
		(newCreature::any).Specifications.MainInfo.Capabilities.Passive:SetAttribute("AquaAffinity", SonariaConstants.AquaAffinity.SemiAquatic)
	else
		(newCreature::any).Specifications.MainInfo.Capabilities.Passive:SetAttribute("AquaAffinity", SonariaConstants.AquaAffinity.Terrestrial)
	end
end;