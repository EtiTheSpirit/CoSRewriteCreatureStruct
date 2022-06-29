StatusEffect = function(creature: Instance, attributeContainer: Instance, attrName: string, attrValue: any): (boolean, string?, number?)
	if attrName == "Name" then
		if attributeContainer.Parent.Name == "MeleeAilments" then
			if attrValue == "BoneBreak" or attrValue == "LigamentTear" then
				return true, "This enforces that " .. attrValue .. " is applied under all circumstances when damaging someone (regardless of weight), which may have unintended results! If you want to add bone breaking and ligament tearing to a creature, consider modifying the dedicated stats in Specifications.MainInfo.Capabilities.Passive", 2
			elseif attrValue == "GodMode" then
				return true, "what", 1
			end
		elseif attributeContainer.Parent.Name == "DefensiveAilments" then
			if attrValue == "WardensRage" then
				if attributeContainer:GetAttribute("ApplyTo") ~= "Attacker" then
					if (string.endsWith(creature.Name, " Warden")) then
						return true, "This will override the values of Warden's Rage on this warden!", 1
					else
						return true, "This will add Warden's Rage to this creature (which is not a warden)!", 1
					end
				end
			elseif attrValue == "GodMode" then
				return true, "what", 1
			end
		end
	elseif attrName == "ApplyTo" then
		if attrValue ~= "Self" then
			return true, "This will give Warden's Rage to the person that attacked this creature, which is probably not what you want.", 2
		end
	end
	return true, nil, nil
end;