GetStudTurnRadius = function(legacyCreature: Folder, newCreature: Configuration, legacyObject: Instance?, newObject: Instance?, attrName: string?)
	-- 7 => 62.5
	local orgTR = (legacyObject::NumberValue).Value
	local result = math.map(orgTR, 1, 9, 7, 62.5);
	(newObject::Instance):SetAttribute(attrName, result)
end;