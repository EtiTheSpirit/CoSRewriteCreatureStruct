HolidayCurrency = function(creature: Instance, attributeContainer: Instance, attrName: string, attrValue: any):  (boolean, string?, number?)
	local isDevOnly = attributeContainer:GetAttribute("DeveloperUseOnly")
	if isDevOnly then
		return false, "This creature will never be sold, as it is marked as developer only.", 1;
	end

	local isInGacha = not string.isNilOrEmpty(attributeContainer:GetAttribute("ForcedGachaList")) or attributeContainer:GetAttribute("InLimitedGacha")
	if isInGacha then
		if attrValue > 0 then
			return true, "You probably don't want this! This creature is part of a gacha (for RNG) <i>and</i> - because this is greater than zero - is being sold in a holiday shop. <b>Set this value to 0 to fix this problem.</b>", 2
		end
	end
	return true, nil, nil
end;