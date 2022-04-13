ConvertDiet = function(legacyCreature: Folder, newCreature: Configuration)
	local ft = (legacyCreature::any).Data.FoodType.Value
	local isPhoto = (legacyCreature::any).Data:FindFirstChild("Photocarni") or (legacyCreature::any).Data:FindFirstChild("Photovore")

	local canEatMeat = true;
	local canEatPlants = true;
	local canDrinkWater = true;
	if ft == "Herbivore" then
		canEatPlants = not isPhoto; -- Photovores cannot eat, only drink.
		canEatMeat = false;
	elseif ft == "Carnivore" then
		canDrinkWater = not isPhoto; -- Photocarnis cannot drink, only eat.
		canEatPlants = false;
	end

	(newCreature::any).Specifications.MainInfo.Diet:SetAttribute("CanEatMeat", canEatMeat);
	(newCreature::any).Specifications.MainInfo.Diet:SetAttribute("CanEatPlants", canEatPlants);
	(newCreature::any).Specifications.MainInfo.Diet:SetAttribute("CanDrinkWater", canDrinkWater);
end;