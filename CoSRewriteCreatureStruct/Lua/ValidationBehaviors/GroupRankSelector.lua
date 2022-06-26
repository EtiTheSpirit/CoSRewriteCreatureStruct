GroupRankSelector = function(creature: Instance, attributeContainer: Instance, attrName: string, attrValue: any): (boolean, string?, number?)
	-- Handles the generation of the game's ID map for what group ranks can trade a given species.
	local GroupRankBindings = {
		Owner = 255;
		CoOwner = 100;
		Developer = 90;
		OtherDeveloper = 87;
		Administrator = 85;
		Testing = 80;
		Staff = 79;
		Contributor = 78;
		FriendsAndFamily = 10;
		ContentCreator = 3;
		Tester = 2;
		Player = 1;
		NonMember = 0;
	};

	local isDevOnly: boolean = (creature::any).Specifications.MainInfo.Attributes.ForFunction:GetAttribute("DeveloperUseOnly")
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
		attributeContainer:SetAttribute("GroupRankArray", table.concat(result, ';'))
	else
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
	end

	return true, nil, nil
end;