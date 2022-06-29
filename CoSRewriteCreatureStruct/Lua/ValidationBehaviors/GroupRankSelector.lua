GroupRankSelector = function(creature: Instance, attributeContainer: Instance, attrName: string, attrValue: any): (boolean, string?, number?)
	-- Handles the generation of the game's ID map for what group ranks can trade a given species.
	local GroupRankBindings = {
		DisallowOwner = 255;
		DisallowCoOwner = 100;
		DisallowSonarDeveloper = 90;
		DisallowOtherDeveloper = 87;
		DisallowAdministrator = 85;
		DisallowTesting = 80;
		DisallowStaff = 79;
		DisallowContributor = 78;
		DisallowFriendsAndFamily = 10;
		DisallowContentCreator = 3;
		DisallowTester = 2;
		DisallowPlayer = 1;
		DisallowNonMember = 0;
	};

	local isDevOnly: boolean = (creature::any).Specifications.Attributes.ForFunction:GetAttribute("DeveloperUseOnly")
	if isDevOnly then
		return false, "This creature is marked as developer only - it will never be tradeable under any circumstances.", 1
	end
	
	if GroupRankBindings[attrName] then
		-- This is a plugin-only boolean value for the rank
		local result = {};
		for rankName, rankValue in pairs(GroupRankBindings) do
			if attributeContainer:GetAttribute(rankName) == true then
				table.insert(result, rankValue)
			end
		end
		attributeContainer:SetAttribute("DisallowedGroupRankArray", table.concat(result, ';'))

		return true, nil, nil
	elseif attrName == "DisallowedGroupRankArray" then
		-- This is the number list itself
		local values = {}
		local strings = string.split(attrValue, ';')
		for index, str in pairs(strings) do
			local val = tonumber(str)
			if val then
				table.insert(values, val)
			end
		end

		for rankName, rankValue in pairs(GroupRankBindings) do
			attributeContainer:SetAttribute(rankName, table.find(values, rankValue) ~= nil)
		end

		return false, nil, nil
	else
		warn("Cannot factor unknown group rank " .. tostring(attrName))
		return true, nil, nil
	end
end;