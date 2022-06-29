HealRadiusValues = function(creature: Instance, attributeContainer: Instance, attrName: string, attrValue: any):  (boolean, string?, number?)
	local range = attributeContainer:GetAttribute("PassiveHealingRange");
	local disabledNotice = "This creature is incapable of passive healing, so this value cannot be edited."
	local enabled = range > 0
	if attrName == "PassiveHealingPerSecond" then
		if enabled then
			if attrValue == 0 then
				return true, "The passive healing range is greater than zero, but this creature still cannot heal because this value is 0!", 3
			end
			return true, nil, nil
		end
		return false, disabledNotice, 1
	elseif attrName == "PassiveHealWhenSelfRest" then
		return enabled, if not enabled then disabledNotice else nil, if not enabled then 1 else nil
	elseif attrName == "PassiveHealWhenOthersRest" then
		return enabled, if not enabled then disabledNotice else nil, if not enabled then 1 else nil
	elseif attrName == "PassiveHealingPackOnly" then
		return enabled, if not enabled then disabledNotice else nil, if not enabled then 1 else nil
	end

	return true, nil, nil
end;