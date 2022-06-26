ManageAquaAffinity = function(creature: Instance, attributeContainer: Instance, attrName: string, attrValue: any):  (boolean, string?, number?)
	if attrValue == SonariaConstants.AquaAffinity.AllTerrain then
		attributeContainer:SetAttribute(attrName, SonariaConstants.AquaAffinity.SemiAquatic);
		warn("Creature Parameter [" .. tostring(attributeContainer:GetFullName()) .. "] has had its Aqua Affinity changed to SemiAquatic, because AllTerrain is not a valid option. All terrain creatures are determined by being semiaquatic and being capable of flight. Set FlySpeed > 0 and define flight idle and glide animations to enable flight.")
	end

	return true, nil, nil
end;