GetDegradedSpeedForClass = function(legacyCreature: Folder, newCreature: Configuration, legacyObject: Instance?, newObject: Instance?, attrName: string?)
	-- For aquatics on land, for terrestrial in water
	-- TEMP: Mimic values
	if legacyObject then
		-- May be nil (mainly for FlySpeed)
		if attrName and attrName:find("Swim") then
			(newObject::Instance):SetAttribute(attrName::string, (legacyObject::NumberValue).Value / 2)
		else
			(newObject::Instance):SetAttribute(attrName::string, (legacyObject::NumberValue).Value)
		end
	else
		(newObject::Instance):SetAttribute(attrName::string, 0)
	end
end;