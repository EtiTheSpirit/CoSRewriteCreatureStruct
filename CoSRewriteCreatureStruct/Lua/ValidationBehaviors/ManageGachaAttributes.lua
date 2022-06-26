ManageGachaAttributes = function(creature: Instance, attributeContainer: Instance, attrName: string, attrValue: any):  (boolean, string?, number?)
	-- ForcedGachaList, InLimitedGacha, HasPaidContentLimits
	local isDevOnly = attributeContainer:GetAttribute("DeveloperUseOnly")
	if isDevOnly then
		if attrName == "DeveloperUseOnly" then
			return true, nil, nil -- If this IS the dev only tag, then it should not be made immutable
		end
		if attrName == "HasPaidContentLimits" then
			return false, "This property cannot be set; this creature is marked as developer only, and has stricter limits than this setting no matter what.", 1
		end
		return false, "This property cannot be set; this creature is marked as developer only and cannot be part of a gacha.", 1
	end
	
	local hasPaidContentLimits = attributeContainer:GetAttribute("HasPaidContentLimits")
	if hasPaidContentLimits then
		if attrName == "HasPaidContentLimits" or attrName == "DeveloperUseOnly" then
			return true, nil, nil
		end
		return false, "This property cannot be set; this creature is marked as a paid creature and cannot be part of a gacha.", 1
	end

	if attrName == "ForcedGachaList" then
		if attrValue == "Limited" then
			warn("ForcedGachaList was manually set to \"Limited\". This is not allowed! Check the InLimitedGacha tickbox instead. This has been done for you.")
			attributeContainer:SetAttribute(attrName, string.Empty)
			attributeContainer:SetAttribute("InLimitedGacha", true)
			attrValue = string.Empty
		end

		if attributeContainer:GetAttribute("InLimitedGacha") then
			return false, "This creature is marked as part of the limited gacha.", 1
		end
	end
	return true, nil, nil
end;