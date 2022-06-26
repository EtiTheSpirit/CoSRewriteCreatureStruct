AniSpecialBreathLimit = function(legacyCreature: Folder, newCreature: Configuration)
	if legacyCreature.Name == "Ani" then
		-- n.b. no moon here, moon can swap
		(newCreature::any).Specifications.Attributes.ForFunction:SetAttribute("PreventPlushieBreathSwaps", true)
	end
end;