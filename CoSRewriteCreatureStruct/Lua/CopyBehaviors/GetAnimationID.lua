GetAnimationID = function(legacyCreature: Folder, newCreature: Configuration, legacyObject: Instance?, newObject: Instance?, attrName: string?)
	local anim = legacyObject::Animation
	local id = tostring(anim.AnimationId)
	(newObject::Instance):SetAttribute(attrName, id)
end;