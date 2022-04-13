GetAnimationID = function(legacyCreature: Folder, newCreature: Configuration, legacyObject: Instance?, newObject: Instance?, attrName: string?)
	local anim = legacyObject::Animation
	if not anim then
		(newObject::Instance):SetAttribute(attrName::string, string.Empty)
		return;
	end
	local id = tostring(anim.AnimationId);
	(newObject::Instance):SetAttribute(attrName::string, id)
end;