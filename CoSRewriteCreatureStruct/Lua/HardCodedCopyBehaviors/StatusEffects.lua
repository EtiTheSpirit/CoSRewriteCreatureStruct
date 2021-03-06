StatusEffects = function(legacyCreature: Folder, newCreature: Configuration)
	local stats = (legacyCreature::any).Data.Stats

	-- Local functions in function bodies are generally not a good idea but since this code is procgen it'll have to do
	local function CreateOffensiveAilment(name: string, stack: boolean, level: number?, duration: number?, levelLimit: Vector2?, durationLimit: Vector2?)
		local ailment = Instance.new("Configuration")
		ailment.Name = name
		ailment:SetAttribute("AllowStacking", stack)
		ailment:SetAttribute("AlwaysOverrideSubAilment", false)
		ailment:SetAttribute("Level", level or 0)
		ailment:SetAttribute("Duration", duration or 0)
		ailment:SetAttribute("StackLevelLimits", levelLimit or Vector2.new())
		ailment:SetAttribute("StackDurationLimits", durationLimit or Vector2.new())
		ailment:SetAttribute("RandomChance", 100)
		return ailment
	end
	local function CreateDefensiveAilment(name: string, stack: boolean, level: number?, duration: number?, levelLimit: Vector2?, durationLimit: Vector2?, applyTo: string?, onMelee: boolean?, onBreath: boolean?, onAbility: boolean?, onEnv: boolean?)
		local ailment = CreateOffensiveAilment(name, stack, level, duration, levelLimit, durationLimit)
		ailment:SetAttribute("ApplyTo", applyTo or SonariaConstants.DefensiveEffectApplicationTarget.Attacker)
		ailment:SetAttribute("ApplyWhenDamagedByMelee", if onMelee ~= nil then onMelee else true)
		ailment:SetAttribute("ApplyWhenDamagedByBreath", if onBreath ~= nil then onBreath else false)
		ailment:SetAttribute("ApplyWhenDamagedByAbility", if onAbility ~= nil then onAbility else false)
		ailment:SetAttribute("ApplyWhenDamagedByEnvironment", if onEnv ~= nil then onEnv else false)
		return ailment
	end
	local function CreateAilmentResistance(name: string, levelReduction: number?, durationReduction: number?, scaleWithAge: boolean?, inverseScale: boolean?)
		local ailment = Instance.new("Configuration")
		ailment.Name = name

		local levelReduction = levelReduction or 0
		local durationReduction = durationReduction or 0
		local scaledLevelReduction = if scaleWithAge then 0 else levelReduction
		local scaledDurationReduction = if scaleWithAge then 0 else durationReduction

		ailment:SetAttribute("AdultLevelResistance", if inverseScale then scaledLevelReduction else levelReduction)
		ailment:SetAttribute("AdultDurationResistance", if inverseScale then scaledDurationReduction else durationReduction)
		ailment:SetAttribute("BabyLevelResistance", if inverseScale then levelReduction else scaledLevelReduction)
		ailment:SetAttribute("BabyDurationResistance", if inverseScale then durationReduction else scaledDurationReduction)
		return ailment
	end

	local offensiveCtr = (newCreature::any).Specifications.MainInfo.Stats.MeleeAilments
	local defensiveCtr = (newCreature::any).Specifications.MainInfo.Stats.DefensiveAilments
	local resistanceCtr = (newCreature::any).Specifications.MainInfo.Stats.AilmentResistances

	if stats:FindFirstChild("Bleed") then
		-- Offensive
		local level = stats.Bleed.Value
		if level == 0 then return end
		local fx = CreateOffensiveAilment("Bleed", true, level)
		fx.Parent = offensiveCtr
	end
	if stats:FindFirstChild("PoisonAttack") then
		-- Offensive
		local level = stats.PoisonAttack.Value
		if level == 0 then return end
		local fx = CreateOffensiveAilment("Poison", true, level)
		fx.Parent = offensiveCtr
	end
	if stats:FindFirstChild("NecroPoison") then
		-- Defensive
		local level = stats.NecroPoison.Value
		if level == 0 then return end
		local fx = CreateDefensiveAilment("NecroPoison", true, level)
		fx.Parent = defensiveCtr
	end
	if stats:FindFirstChild("BleedDefense") then
		-- Resistance
		local resist = stats.BleedDefense.Value -- will be from 0 to 100.
		if resist == 0 then return end
		local fx = CreateAilmentResistance("Bleed", resist, resist, true, false)
		fx.Parent = resistanceCtr
	end
	if stats:FindFirstChild("PoisonDefense") then
		-- Defensive (not resistance like bleed, this is not a mistake)
		local level = stats.PoisonDefense.Value
		if level == 0 then return end
		local fx = CreateDefensiveAilment("Poison", true, level)
		fx.Parent = defensiveCtr
	end
	if stats:FindFirstChild("PoisonResistance") then
		-- Resistance		
		local resist = stats.PoisonResistance.Value -- will be from 0 to 100.
		if resist == 0 then return end
		local fx = CreateAilmentResistance("Poison", resist, resist, true, false)
		fx.Parent = resistanceCtr
	end
	if stats:FindFirstChild("NecroPoisonResistance") then
		-- Resistance
		local resist = stats.NecroPoisonResistance.Value -- will be from 0 to 100.
		if resist == 0 then return end
		local fx = CreateAilmentResistance("NecroPoison", resist, resist, true, false)
		fx.Parent = resistanceCtr
	end
	if stats:FindFirstChild("SerratedTeeth") then
		-- Offensive, always 40s. Resets to 40s if it already exists.
		local fx = CreateOffensiveAilment("SerratedTeeth", false, 0, 40, Vector2.new(), Vector2.new(0, 40))
		fx.Parent = offensiveCtr
	end
	if stats:FindFirstChild("Confusion") then
		-- Offensive, 15s. Does not reset if it already exists.
		local fx = CreateOffensiveAilment("Shock$Confused", false, 0, 15, Vector2.new(), Vector2.new(0, 15))
		fx.Parent = offensiveCtr
	end
	if stats:FindFirstChild("Paralysis") then
		-- Offensive, 1s
		local fx = CreateOffensiveAilment("Paralyzed", false, 0, 1, Vector2.new(), Vector2.new(0, 1))
		fx.Parent = offensiveCtr
	end
	if stats:FindFirstChild("BurnAttack") then
		-- Offensive
		local level = stats.BurnAttack.Value
		if level == 0 then return end
		local fx = CreateOffensiveAilment("Burn", true, level)
		fx.Parent = offensiveCtr
	end
	if stats:FindFirstChild("Guilt") then
		-- Not a defensive effect, but instead an attribute.
		(newCreature::any).Specifications.MainInfo.Capabilities.Passive:SetAttribute("CauseGuiltDuration", 30)
	end
	if stats:FindFirstChild("StickyTeeth") then
		-- Defensive, applies StuckTeeth, 6s
		local fx = CreateDefensiveAilment("StuckTeeth", false, 0, 6, Vector2.new(), Vector2.new(6, 6))
		fx.Parent = defensiveCtr
	end
	if stats:FindFirstChild("BleedBlock") then
		-- Defensive
		local level = stats.BleedBlock.Value
		if level == 0 then return end
		local fx = CreateDefensiveAilment("Bleed", true, level)
		fx.Parent = defensiveCtr
	end
	if stats:FindFirstChild("BurnDefense") then
		-- Defensive
		local level = stats.BurnDefense.Value
		if level == 0 then return end
		local fx = CreateDefensiveAilment("Burn", true, level)
		fx.Parent = defensiveCtr
	end
	if stats:FindFirstChild("DefensiveParalyze") then
		-- Defensive, always 5s
		local fx = CreateDefensiveAilment("Paralyzed", false, 0, 5, Vector2.new(), Vector2.new(5, 5))
		fx.Parent = defensiveCtr
	end

	local holidays = {
		Valentines = SonariaConstants.Holidays.Valentines;
		Easter = SonariaConstants.Holidays.Easter;
		Christmas = SonariaConstants.Holidays.Christmas;
		Christmas2021 = SonariaConstants.Holidays.Christmas;
	}
	for key, sc in pairs(holidays) do
		if stats.Parent:FindFirstChild(key) then
			(newCreature::any).Specifications.Attributes.ForShow:SetAttribute("Holiday", sc)
			break
		end
	end
end;