AirJumpCounter = function(creature: Instance, attributeContainer: Instance, attrName: string, attrValue: any): (boolean, string?, number?)
	if attributeContainer:GetAttribute("JumpImpulsePower") <= 0 then
		return false, "This creature applies no force when jumping, making it unable to jump. Air jumps are not applicable.", 1
	end
	return true, nil, nil
end;