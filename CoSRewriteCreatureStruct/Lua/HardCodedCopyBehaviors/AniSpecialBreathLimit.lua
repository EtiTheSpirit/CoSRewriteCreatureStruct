AniSpecialBreathLimit = function(legacyCreature: Folder, newCreature: Configuration)
	if legacyCreature.Name == "Ani" then
		(newCreature::any).Specifications.Attributes.ForFunction:SetAttribute("PreventPlushieBreathSwaps", true)
	end
end;