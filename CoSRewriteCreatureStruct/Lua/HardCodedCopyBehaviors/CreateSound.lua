CreateSound = function(legacyCreature: Folder, newCreature: Configuration)
	local ORDER = {"Broadcast", "Friendly", "Aggressive", "Speak"}
	for i = 1, 4 do
		local legacyObject = legacyCreature.Sounds:FindFirstChild(tostring(i))
		if not legacyObject then continue end

		local sound = legacyObject::Sound
		local newObject: Instance = newCreature.CreatureVisuals.Sounds[ORDER[i]]
		newObject:SetAttribute("ID", tostring(sound.SoundId))
		newObject:SetAttribute("Range", sound.RollOffMaxDistance)
		newObject:SetAttribute("Volume", sound.Volume)
		newObject:SetAttribute("Pitch", sound.PlaybackSpeed)
	end
end;