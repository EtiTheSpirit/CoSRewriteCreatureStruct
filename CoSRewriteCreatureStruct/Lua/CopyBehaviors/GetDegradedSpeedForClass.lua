﻿GetDegradedSpeedForClass = function(legacyCreature: Folder, newCreature: Configuration, legacyObject: Instance?, newObject: Instance?, attrName: string?)
	-- For aquatics on land, for terrestrial in water
	-- TEMP: Mimic values
	if legacyObject then
		-- May be nil (mainly for FlySpeed)
		(newObject::Instance):SetAttribute(attrName, (legacyObject::NumberValue).Value)
	else
		(newObject::Instance):SetAttribute(attrName, 0)
	end
end;