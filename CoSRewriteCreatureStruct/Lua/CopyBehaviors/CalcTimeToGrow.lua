CalcTimeToGrow = function(legacyCreature: Folder, newCreature: Configuration, legacyObject: Instance?, newObject: Instance?, attrName: string?)
	local orgTimeToGrowS = (legacyObject::NumberValue).Value; -- Seconds
	(newObject::Instance):SetAttribute(attrName::string, orgTimeToGrowS / 60) -- Minutes
end;