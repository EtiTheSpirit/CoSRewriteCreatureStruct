CanJump = function(creature: Configuration)
	local agility: Configuration = (creature::any).Specifications.Mobility.Agility
	return (agility:GetAttribute("JumpImpulsePower") or 0) > 0;
end;