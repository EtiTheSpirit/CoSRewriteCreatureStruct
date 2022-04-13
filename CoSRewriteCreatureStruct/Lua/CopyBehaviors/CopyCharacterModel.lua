CopyCharacterModel = function(legacyCreature: Folder, newCreature: Configuration, legacyObject: Instance?, newObject: Instance?, attrName: string?)
	local characterModel = (legacyObject::Model)
	if characterModel.Name == "Adult" then
		local dupe = characterModel:Clone()
		dupe.Name = "AdultCustomizer"
		warn("Converting adult " .. legacyCreature.Name .. "'s collisions into a customizer model. This might make studio freeze for a moment!")
		for index, object in pairs(dupe:GetChildren()) do
			if object:IsA("MeshPart") then
				object.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
			end
		end
		warn("Done with collision conversion.")
		dupe.PrimaryPart = dupe:FindFirstChild("HumanoidRootPart") :: BasePart
		dupe.Parent = newObject
	end
	local dupe = characterModel:Clone()
	dupe.PrimaryPart = dupe:FindFirstChild("HumanoidRootPart") :: BasePart
	dupe.Parent = newObject
end;