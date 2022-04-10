ConvHealRate = function(legacyCreature: Folder, newCreature: Configuration, legacyObject: Instance?, newObject: Instance?, attrName: string?)
	-- Original value was % healed per 15 seconds.
	-- Now it is % healed per second
	local orgValue = (legacyObject::NumberValue).Value;
	(newObject::Instance):SetAttribute(attrName::string, orgValue / 15)
end;