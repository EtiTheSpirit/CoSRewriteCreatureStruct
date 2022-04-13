CopyPalette = function(legacyCreature: Folder, newCreature: Configuration)
	for j = 1, 2 do
		local legacyObject = legacyCreature:FindFirstChild("Palette" .. j)
		if not legacyObject then continue end

		local newObject = (newCreature::any).CreatureVisuals.Palettes:FindFirstChild("Palette" .. j)
		local paletteFolder = legacyObject::Folder
		local newPaletteObject = newObject::Instance & {Colors: Configuration}
		newPaletteObject:SetAttribute("Enabled", true)
		for i = 1, 12 do
			local orgColor = paletteFolder:FindFirstChild(tostring(i)) :: Color3Value
			local color = Color3.new(0.5, 0.5, 0.5);
			if not orgColor then
				warn("Missing color index " .. tostring(i) .. " from " .. legacyCreature.Name .. "! Defaulting to middle gray.")
			else
				color = orgColor.Value
			end

			local h,s,v = color:ToHSV()
			-- x0.6, min 0.01
			-- x1.4, max 0.99
			local lowest = Color3.fromHSV(h, s, math.max(v * 0.6, 0.01))
			local highest = Color3.fromHSV(h, s, math.min(v * 1.4, 0.99))

			newPaletteObject.Colors:SetAttribute("Color" .. string.format("%02d", i), ColorSequence.new(lowest, highest))
		end
	end
end;