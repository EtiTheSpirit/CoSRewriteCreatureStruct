BoneBreakLigamentTear = function(creature: Instance, attributeContainer: Instance, attrName: string, attrValue: any):  (boolean, string?, number?)
	if attrName ~= "BoneBreaker" then
		local isBB = attributeContainer:GetAttribute("BoneBreaker") == true
		if not isBB then
			return false, "This creature is incapable of causing bone break or ligament tear, so this property is disabled.", 1
		else
			return true, nil, nil
		end
	end
	return true, nil, nil
end;