SeeStatusEffects = function(creature: Instance, attributeContainer: Instance, attrName: string, attrValue: any): (boolean, string?, number?)
	if not attributeContainer:GetAttribute("SeeHealth") then
		return false, "This creature cannot see the health of other creatures, so this value does nothing.", 1
	end
	return true, nil, nil
end;