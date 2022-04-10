ConvFlySpeed = function(legacyCreature: Folder, newCreature: Configuration, legacyObject: Instance?, newObject: Instance?, attrName: string?)
	-- There is no real scale for this so the idea is a scale where fly speed 10 is maybe 50 studs/sec and fly speed 25 is 200 studs/sec
	local orgSpeedValue = (legacyObject::NumberValue).Value
	local newSpeedValue = math.lerp(orgSpeedValue, 10, 25, 50, 200); -- Convert a range of 10 to 25 => 50 to 200
	(newObject::Instance):SetAttribute(attrName::string, newSpeedValue)
end;