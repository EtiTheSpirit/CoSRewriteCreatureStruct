IsWarden =  function(creature: Configuration)
	local name = creature.Name
	if #name < 7 then return false end
	return name:sub(#name - 6) == " Warden"

	-- TODO: Detect when the creature has a defensive, self-applied status effect of Warden's Rage
	-- Maybe a different intrinsic property, "Overrides Warden's Rage"?
	-- It is possible to override the duration in the rewrite systems, and so that should be marked.
end;