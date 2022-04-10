GetBreathIfString = function(legacyCreature: Folder, newCreature: Configuration, legacyObject: Instance?, newObject: Instance?, attrName: string?)
	-- NOTE PROVIDED: Some very old creatures have a prototype numeric breath value, which exists in rewrite as Air.
	-- The value should be discarded if it is numeric as air is a completely different unit now.
	if (legacyObject::Instance):IsA("StringValue") then
		local breath = (legacyObject::StringValue).Value
		newObject:SetAttribute(attrName, breath)
	end
end;