GetHealRadiusValuesForSpecies = function(legacyCreature: Folder, newCreature: Configuration)
	-- Pack healer has a radius of 20 (brequewk, look for Healer value in stats, pack only, but at all times, does not affect self)
	-- Ura has a radius of 50 (only Ura has this, it has its own code, affects self and everyone, but only when laying)

	-- breq does a +10% speed boost, which is not functional here (this must be an amount boost), so an arbitrary value will be
	-- assigned for now until it is decied in restat.

	-- ura adds 5% health every 6 seconds. This must be converted into % per 1 second.

	--[[
		PassiveHealingRange
		PassiveHealingPerSecond
		PassiveHealWhenSelfRest
		PassiveHealWhenOthersRest
		PassiveHealingPackOnly
	--]]

	local container = (newCreature::any).Specifications.MainInfo.Capabilities.Passive
	local isPackHealer = (legacyCreature::any).Data.Stats:FindFirstChild("Healer")
	if isPackHealer then
		-- These values are what the game used in old live if the Healer tag was present.
		container:SetAttribute("PassiveHealingRange", 20)
		container:SetAttribute("PassiveHealingPerSecond", 2)
		container:SetAttribute("PassiveHealWhenSelfRest", true)
		container:SetAttribute("PassiveHealWhenOthersRest", false)
		container:SetAttribute("PassiveHealingPackOnly", true)
	elseif legacyCreature.Name == "Ura" then
		-- These values are what the game used in old live if the species was Ura.
		container:SetAttribute("PassiveHealingRange", 50)
		container:SetAttribute("PassiveHealingPerSecond", 1) -- Technically this is 5% per 5 seconds. Oh well.
		container:SetAttribute("PassiveHealWhenSelfRest", true)
		container:SetAttribute("PassiveHealWhenOthersRest", true)
		container:SetAttribute("PassiveHealingPackOnly", false)
	end
end;