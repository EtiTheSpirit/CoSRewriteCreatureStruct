IsWarden = {
	Name = "Warden";
	Type = "boolean";
	Callback = function(creature: Configuration)
		local name = creature.Name
		if #name < 7 then return false end
		return name:sub(#name - 6) == "Warden"
	end;
};