HealRadiusValues = function(creature: Instance, attributeContainer: Instance, attrName: string, attrValue: any):  (boolean, string?, number?)
	local range = attributeContainer:GetAttribute("PassiveHealingRange");
	if attrName == "PassiveHealingPerSecond" then
		if range > 0 then
			if attrValue == 0 then
				return true, "The passive healing range is greater than zero, but this creature still cannot heal because this value is 0!", 3
			end
			return true, nil, nil
		end
		return false, nil, nil
	elseif attrName == "PassiveHealWhenSelfRest" then
		return range > 0, nil, nil
	elseif attrName == "PassiveHealWhenOthersRest" then
		return range > 0, nil, nil
	elseif attrName == "PassiveHealingPackOnly" then
		return range > 0, nil, nil
	end

	return true, nil, nil
end;