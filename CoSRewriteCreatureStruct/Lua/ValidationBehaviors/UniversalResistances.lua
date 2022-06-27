UniversalResistances = function(creature: Instance, attributeContainer: Instance, attrName: string, attrValue: any): (boolean, string?, number?)
	if attrValue > 0 then
		return true, "This creature will resist <b>ALL</b> incoming damage of this type by this percentage!", 1
	elseif attrValue < 0 then
		return true, "This creature will take this percentage of extra damage from <b>ALL</b> incoming damage of this type!", 1
	end
	return true, nil, nil
end;