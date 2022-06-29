DefensiveEffectApplyExtension = function(creature: Instance, attributeContainer: Instance, attrName: string, attrValue: any):  (boolean, string?, number?)
	if attrName == "GiveToAttackerWhenReflecting" then
		local appliesToSelfExplicitly = attributeContainer:GetAttribute("ApplyTo") == SonariaConstants.DefensiveEffectApplicationTarget.Self
		if appliesToSelfExplicitly then
			return true, nil, nil
		else
			return false, "This effect does not explicitly apply to Self, so this property is not applicable to this effect and will be ignored.", 1
		end
	end
end;