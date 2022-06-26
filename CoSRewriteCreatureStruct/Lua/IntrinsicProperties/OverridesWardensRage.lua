OverridesWardensRage = function(creature: Configuration)
	local statusContainer = (creature::any).Specifications.MainInfo.Stats.DefensiveAilments
	local wardensRage = statusContainer:FindFirstChild("WardensRage")
	if wardensRage then
		return true
	end
	return false
end;