--!strict
-- Creature Info Provider
-- Successor to the previous iteration, "DinoData", designed for use with the new creature data structure.
-- Has at least 185,749,141,281,185,392 more brain cells.
-- Need context-aware data (e.g. for a specific character in the world)? Use CharacterInfoProvider instead. 
-- It extends this (providing species access) but allows the character to override some data. 
-- That means that every method here is usable in that other module too!

-- Note that when this object creates data from one of the template creatures, it is disjointed from the template.
-- That is, once it creates the data, it will use its own cache, and modifying the object will do nothing.

-- The most important note to take is that this is multi-sided (can be required from both the client and server) and is synchronized.
-- Use this to your advantage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local CreaturesFolder = ReplicatedStorage.Creatures 
local EtiLibs = ReplicatedStorage.EtiLibs
local table = require(EtiLibs.Extension.Table)
local string = require(EtiLibs.Extension.String)
local math = require(EtiLibs.Extension.Math)
local bit32 = require(EtiLibs.Extension.Bit32)
local ColorTool = require(EtiLibs.Mathematical.ColorTool)
local GUID = require(EtiLibs.Data.GUID)
local info, warnstack, printstack = unpack(require(EtiLibs.Extension.LogExtensions))

local CoreData = ReplicatedStorage.CoreData
local ReplicatedCode = ReplicatedStorage.ReplicatedCode

local ModelPrep = require(script.ModelPrep)

local CyclicRequire = require(EtiLibs.Data.CyclicRequire)

local AbilityRegistry = require(CoreData.Registries.AbilityRegistry)
local StatusEffectRegistry; StatusEffectRegistry = CyclicRequire.Require(CoreData.Registries.StatusEffectRegistry, function(export) StatusEffectRegistry = export end)
local DietRegistry = require(CoreData.Registries.DietRegistry)
local SonariaConstants = require(CoreData.SonariaConstants)
local CreatureColorRegistry = require(ReplicatedCode.System.CreatureColors)
local AbilityType = require(CoreData.Registries.AbilityRegistry.AbilityType)
type Ability = AbilityType.Ability

local SpeciesInfoProvider = {}
SpeciesInfoProvider.__eq = function (left, right): boolean
	if rawequal(left, right) then return true end
	if rawequal(left, nil) or rawequal(right, nil) then return false end
	if left.GetName == nil or right.GetName == nil then return false end
	if (left:GetName() == right:GetName()) then
		return true
	end
	return false
end
SpeciesInfoProvider.__index = SpeciesInfoProvider
SpeciesInfoProvider.__tostring = function(cdat)
	return string.csFormat("Species[Name=\"{0}\"]", cdat:GetName())
end

-- A cache of all creatures who have had the For method called with their species name.
local CreatureDataCache: {[string]: Species} = {}

-- A cache of intrinsic properties for a given species. The very nature of these properties makes these often a bit more than a lookup (for some of them, at least)
-- and so caching the value is a good idea, especially considering that creature data is immutable.
local IntrinsicData: {[string]: IntrinsicProperties} = {}

-- A generic cache for other values, such as the list of attributes on the creature.
type Lookup = {[string]: any}
local AltRepresentationCache: {[string]: Lookup} = {}


-- Constants
-- For AltRepresentationCache. These are the keys.
local CacheKey = table.deepFreeze({
	ALL_FLAGS = "AllFlags",
	FUNC_FLAGS = "FunctionalFlags",
	DISPLAY_FLAGS = "DisplayFlags",
	-- CREATURE_ABILITIES = "ActiveAbility",
	MODELS = "Models",
	-- RADIATION = "Radioactivity",
	CREATURE_PASSIVE_ABILITIES = "PassiveAbilities",
	ALL_ABILITIES = "AllAbilities",
	DIET = "Diet",
})

local UNUSED_COLORS_NIL_NOT_BLACK = true			
-- If this is true, colors on palettes that are unused (where their color # is greater than the number of colors to use
-- or where the palette is disabled) will be set to nil in this data structure. If this is false, they will be set to
-- an all-black color sequence.
-- Recommended value: true

local USE_NIL_ANIMATIONS_INSTEAD_OF_ZERO_ID = true	
-- If this is true, animations without IDs or with and ID of 0 will be set to nil in the reflected data structure.
-- If this is false, the animations will keep a zero ID which will cause an error if they are loaded.
-- Recommended value: true

-- DATA CONSTANTS // DO NOT EDIT
local RNG = Random.new()

-- TYPEDEFS
local CreatureTypeDefs = require(CoreData.TypeDefinitions.CreatureTypeDefs)
type CreaturePalette = CreatureTypeDefs.CreaturePalette
type Flags = CreatureTypeDefs.Flags
type IntrinsicProperties = CreatureTypeDefs.IntrinsicProperties
type SoundInfo = CreatureTypeDefs.SoundInfo
type AnimationConfiguration = CreatureTypeDefs.AnimationConfiguration
type LandAnimations = CreatureTypeDefs.LandAnimations
type AerialAnimations = CreatureTypeDefs.AerialAnimations
type AquaticAnimations = CreatureTypeDefs.AquaticAnimations
type ActionAnimations = CreatureTypeDefs.ActionAnimations
type CreatureSpecs = CreatureTypeDefs.CreatureSpecs
export type CreatureData = CreatureTypeDefs.CreatureData
type CreatureOffensiveAilmentStats = CreatureTypeDefs.CreatureOffensiveAilmentStats
type CreatureDefensiveAilmentStats = CreatureTypeDefs.CreatureDefensiveAilmentStats
type CreatureResistanceStats = CreatureTypeDefs.CreatureResistanceStats
type CreatureAreaAilmentStats = CreatureTypeDefs.CreatureAreaAilmentStats

-----------------------------------------------------------------
----------------------SYSTEM-WIDE HELPERS------------------------
-----------------------------------------------------------------
local function PutReadOnlyData(self: Species, key: string, value: any)
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local name = self.RawData.Name :: string
	AltRepresentationCache[name] = AltRepresentationCache[name] or {}
	AltRepresentationCache[name][key] = value
end

local function GetReadOnlyData(self: Species, key: string): any?
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local name = self.RawData.Name :: string
	if AltRepresentationCache[name] then
		return AltRepresentationCache[name][key]
	end
	return nil
end

------------------------------------------------------------------
----------------------INTRINSIC PROPERTIES------------------------
------------------------------------------------------------------
-- // All properties of this species that are emergent from other
-- // attributes or properties, and cannot be directly set themselves.

-- Returns the sort type of this creature on the main menu. If the creature does not have a gacha explicitly defined, this also determines the gacha.
-- NOTE: This is unreliable for getting classification for the Gacha system. Use GetGacha() instead for that purpose, which is corrected to reflect appropriately creature data.
function SpeciesInfoProvider:GetSort(): string?
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local data: CreatureData = self.RawData
	if IntrinsicData[data.Name].Sort.Set then
		return IntrinsicData[data.Name].Sort.Value :: string
	end

	local attrs = data.Specifications.Attributes
	local isDevOnly = attrs.ForFunction.DeveloperUseOnly
	local hasPaidLimit = attrs.ForFunction.HasPaidContentLimits
	local isLimitedGacha = attrs.ForFunction.InLimitedGacha
	if isDevOnly or hasPaidLimit then
		IntrinsicData[data.Name].Sort = {Set = true, Value = nil}
		return nil
	elseif isLimitedGacha then
		IntrinsicData[data.Name].Sort = {Set = true, Value = "Limited"}
		return "Limited"
	end

	local caps = data.Specifications.MainInfo.Capabilities
	local aquaAffinity = caps.Passive.AquaAffinity

	if aquaAffinity == SonariaConstants.AquaAffinity.Aquatic then
		IntrinsicData[data.Name].Sort = {Set = true, Value = "Sea"}
		return "Sea"
	elseif aquaAffinity == SonariaConstants.AquaAffinity.SemiAquatic then
		IntrinsicData[data.Name].Sort = {Set = true, Value = "SemiAquatic"}
		return "SemiAquatic"
	end

	if self:IsFlier() then
		IntrinsicData[data.Name].Sort = {Set = true, Value = "Sky"}
		return "Sky"
	end

	IntrinsicData[data.Name].Sort = {Set = true, Value = "Land"}
	return "Land"
end

-- Returns the name of the Gacha this creature appears in, or nil if they do not appear in one.
function SpeciesInfoProvider:GetGacha(): string?
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local data: CreatureData = self.RawData
	if IntrinsicData[data.Name].Gacha.Set then
		return IntrinsicData[data.Name].Gacha.Value :: string
	end
	
	local attrs = data.Specifications.Attributes
	local isDevOnly = attrs.ForFunction.DeveloperUseOnly
	local hasPaidLimit = attrs.ForFunction.HasPaidContentLimits
	local isLimitedGacha = attrs.ForFunction.InLimitedGacha
	if isDevOnly or hasPaidLimit then
		IntrinsicData[data.Name].Gacha = {Set = true, Value = nil}
		return nil
	elseif isLimitedGacha then
		IntrinsicData[data.Name].Gacha = {Set = true, Value = "Limited"}
		return "Limited"
	end

	local forced = data.Specifications.Attributes.ForFunction.ForcedGachaList
	if string.isNilOrEmpty(forced) then
		local gacha = self:GetSort()
		IntrinsicData[data.Name].Gacha = {Set = true, Value = gacha}
		return gacha
	end
	IntrinsicData[data.Name].Gacha = {Set = true, Value = forced}
	return forced
end

-- Returns whether or not this creature can fly (including by flapping their wings to gain speed).
function SpeciesInfoProvider:IsFlier(): boolean
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	-- TODO: Keep flight intrinsic, or allow runtime changes?
	-- TODO: How do we handle creatures like (butterfly thing?) where it can't fly as child but can as adult?
	local data: CreatureData = self.RawData
	if IntrinsicData[data.Name].IsFlier.Set then
		return IntrinsicData[data.Name].IsFlier.Value :: boolean -- Definitely not nil if it's set.
	end

	local aerial = data.CreatureVisuals.Animations.Aerial
	local caps = data.Specifications.MainInfo.Capabilities.Passive
	local flyIdleAnim = aerial.FlyIdle
	local glideAnim = aerial.Glide

	local hasFlyIdle = if flyIdleAnim ~= nil then flyIdleAnim.AnimationId ~= "" else false
	local hasGlide = if glideAnim ~= nil then glideAnim.AnimationId ~= "" else false
	local isFlier = hasFlyIdle and hasGlide and caps.OnlyGlide ~= true

	IntrinsicData[data.Name].IsFlier = {Set = true, Value = isFlier}
	return isFlier
end

-- Returns whether or not this creature is a glider and incapable of complete flight. This is the counterpart to IsFlier().
function SpeciesInfoProvider:IsGlider(): boolean
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	-- TODO: Keep flight intrinsic, or allow runtime changes?
	-- TODO: How do we handle creatures like (butterfly thing?) where it can't fly as child but can as adult?
	local data = self.RawData
	if IntrinsicData[data.Name].IsGlider.Set then
		return IntrinsicData[data.Name].IsGlider.Value :: boolean -- Definitely not nil if it's set.
	end

	local aerial = data.CreatureVisuals.Animations.Aerial
	local caps = data.Specifications.MainInfo.Capabilities.Passive
	local glideAnim = aerial.Glide
	local isGlider = (if glideAnim ~= nil then glideAnim.AnimationId ~= "" else false) and caps.OnlyGlide

	IntrinsicData[data.Name].IsGlider = {Set = true, Value = isGlider}
	return isGlider
end

-- Returns whether or not this creature is capable of mobility in the air. This is identical to (IsFlier() or IsGlider()).
function SpeciesInfoProvider:IsAerial(): boolean
	local self: Species = self::any
	return self:IsFlier() or self:IsGlider()
end

-- Returns whether or not this creature has the ability to ambush others based on if the ambush speed multiplier is greater than one.
-- This is an offensive ability that grants extra speed to predators.
function SpeciesInfoProvider:CanAmbush(): boolean
	local self: Species = self::any
	local canAmbush = self:GetAmbushSpeedMultiplier() > 1 
	-- Yes, greater than one. 1>x>0 is an invalid range (slows you down when you ambush)
	return canAmbush
end

-- Returns whether or not this creature is a nightstalker. Nightstalker is an intrinsic attribute that occurs if Nightvision is greater than 3.
function SpeciesInfoProvider:IsNightstalker(): boolean
	local self: Species = self::any
	local isStalker = self:GetNightvision() > 3
	return isStalker
end

-- Returns whether or not this creature counts as a warden.
function SpeciesInfoProvider:IsWarden(): boolean
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local data = self.RawData
	if IntrinsicData[data.Name].IsWarden.Set then
		return IntrinsicData[data.Name].IsWarden.Value :: boolean
	end
	local isWarden = string.EndsWith(self.RawData.Name, " Warden")
	IntrinsicData[data.Name].IsWarden = {Set = true, Value = isWarden}
	return isWarden
end

-- Returns whether or not this creature has paid content limits applied.
-- This attribute was previously named "GamepassCreature". This value is identical.
function SpeciesInfoProvider:HasPaidContentLimits(): boolean
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local data = self.RawData
	return data.Specifications.Attributes.ForFunction.HasPaidContentLimits
end

-- Returns whether or not this creature is unable to have its bones broken, ligaments torn, and is unable to bleed.
function SpeciesInfoProvider:IsUnbreakable(): boolean
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local data = self.RawData
	if IntrinsicData[data.Name].IsUnbreakable.Set then
		return IntrinsicData[data.Name].IsUnbreakable.Value :: boolean
	end

	IntrinsicData[data.Name].IsUnbreakable = {
		Set = true, 
		Value = self:IsImmuneTo(StatusEffectRegistry.Effects.BoneBreak)
			and self:IsImmuneTo(StatusEffectRegistry.Effects.LigamentTear)
	}
	return IntrinsicData[data.Name].IsUnbreakable.Value :: boolean
end

-- Returns the ID of this model's published object, which permits rendering a thumbnail with no 3D overhead.
function SpeciesInfoProvider:GetPublishedModelID(): number
	local self: Species = self::any
	local id = self.RawData.ThumbnailModelID
	if not id then
		warn("Failed to resolve a missing model ID for " .. tostring(self))
		return 0
	end
	return id
end

-- Returns the roblox thumb URI pointing towards this creature's thumbnail icon.
function SpeciesInfoProvider:GetIconURI(): string
	local self: Species = self::any
	local id = self:GetPublishedModelID()
	if id == 0 then
		id = 9107568500 -- "No Icon" as an image.
	end
	return string.csFormat("rbxthumb://type=Asset&id={0}&w=150&h=150", id)
end

------ Below: Not really intrinsic, but still similar in nature.
-- Returns the aquatic state of this creature, as defined in SonariaConstants.AquaAffinity
function SpeciesInfoProvider:GetAquaAffinity(): string
	local self: Species = self::any
	local data = self.RawData
	return data.Specifications.MainInfo.Capabilities.Passive.AquaAffinity
end

-- Returns whether or not this creature is aquatic. Going onto land will cause them to take damage, and they must remain in the water at all times.
function SpeciesInfoProvider:IsAquatic(): boolean
	local self: Species = self::any
	return self:GetAquaAffinity() == SonariaConstants.AquaAffinity.Aquatic
end

-- Returns whether or not this creature is semiaquatic. This allows them to swim for prolonged amounts of time and have better mobility in water, and also to be on land.
function SpeciesInfoProvider:IsSemiAquatic(): boolean
	local self: Species = self::any
	return self:GetAquaAffinity() == SonariaConstants.AquaAffinity.SemiAquatic
end

-- Returns whether or not the creature is terrestrial, or only lives on land (all aquatic attributes and aerial attributes must be false)
function SpeciesInfoProvider:IsTerrestrial(): boolean
	local self: Species = self::any
	return not (self:IsAquatic() or self:IsSemiAquatic() or self:IsAerial())
end

-- An alias method that represents whether or not a creature is generally associated with water, or more specifically, their Aqua Affinity type was not set to Terrestrial.
function SpeciesInfoProvider:IsAssociatedWithWater(): boolean
	local self: Species = self::any
	return self:GetAquaAffinity() ~= SonariaConstants.AquaAffinity.Terrestrial
end

------------------------------------------------------------------
--------------------------TAGS & FLAGS----------------------------
------------------------------------------------------------------

-- Returns the name of this species. Mostly useful for if a reference to the species is not available.
function SpeciesInfoProvider:GetName(): string
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Name
end

-- Returns the name of this creature for use in English texts. 
-- Depending on this creature's settings, this may return different values for different inputs.
-- For ease of access, the input value is a numeric amount.
function SpeciesInfoProvider:GetNameForAmount(amount: number?): string
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	if amount == 1 or not self.RawData.PluralName then
		-- Singular
		return self.RawData.Name
	else
		-- Plural
		if self.RawData.PluralName then
			return self.RawData.PluralName
		end

		local name = self.RawData.Name
		if string.EndsWith(name, 's') then
			return name .. "es"
		else
			return name .. "s"
		end
	end
end

-- Returns the concept artist behind this creature. This may be multiple people as well depending on the creature.
function SpeciesInfoProvider:GetConceptArtist(): string
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Artists
end

-- Returns the description of this creature, which is the text displayed on the main menu.
function SpeciesInfoProvider:GetDescription(): string
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Description
end

-- Returns the values of all flags that classify as functional.
function SpeciesInfoProvider:GetFunctionalFlags(): {[string]: any}
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.

	local cached = GetReadOnlyData(self, CacheKey.FUNC_FLAGS)
	if cached then
		return cached
	end
	local data = self.RawData :: CreatureData

	local retn = {}
	for attrName, attrValue in pairs(data.Specifications.Attributes.ForFunction) do
		if attrValue then
			retn[attrName] = attrValue
		end
	end

	PutReadOnlyData(self, CacheKey.FUNC_FLAGS, retn)
	return retn
end

-- Returns the values of all flags that classify as flair/display.
function SpeciesInfoProvider:GetDisplayFlags(): {[string]: any}
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.

	local cached = GetReadOnlyData(self, CacheKey.DISPLAY_FLAGS)
	if cached then
		return cached
	end
	local data = self.RawData :: CreatureData

	local retn = {}
	for attrName, attrValue in pairs(data.Specifications.Attributes.ForShow) do
		if attrValue then
			retn[attrName] = attrValue
		end
	end

	PutReadOnlyData(self, CacheKey.DISPLAY_FLAGS, retn)
	return retn
end

-----------------------------------------------------------------
---------------------------- STATS ------------------------------
-----------------------------------------------------------------
-- // All stats for this creature organized by category

------------------------------------------------------------------
----------------------------- DIET -------------------------------
------------------------------------------------------------------

-- Returns a string representing the food type of this creature. The values returned are preset, defined under FoodType in the SonariaConstants module.
-- For reference, these values are: "Herbivore", "Carnivore", "Omnivore", "Photovore", and "Photocarni".
function SpeciesInfoProvider:GetFoodType(): string
	local self: Species = self::any
	local cached = GetReadOnlyData(self, CacheKey.DIET)
	if cached then 
		return cached 
	end
	local retn = DietRegistry.GetNameFromFlags(self:CanEatMeat(), self:CanEatPlants(), self:CanDrinkWater())
	PutReadOnlyData(self, CacheKey.DIET, retn)
	return retn
end

-- Returns this creature's appetite at age 100, which is the number representing how much food they can eat at most.
function SpeciesInfoProvider:GetMaxAppetite(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Diet.Appetite
end

-- Returns this creature's thirst appetite at age 100, which is the number representing how much water they can drink at most.
function SpeciesInfoProvider:GetMaxThirstAppetite(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Diet.ThirstAppetite
end

-- Returns whether or not this creature can eat plants, specifically returning true if they are an Herbivore or Omnivore.
function SpeciesInfoProvider:CanEatPlants(): boolean
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Diet.CanEatPlants
end

-- Returns whether or not this creature can eat meat, specifically returning true if they are a Carnivore, Omnivore, or Photocarni.
function SpeciesInfoProvider:CanEatMeat(): boolean
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Diet.CanEatMeat
end

-- Returns whether or not this creature can eat in general.
function SpeciesInfoProvider:CanEatFood(): boolean
	local self: Species = self::any
	return self:CanEatPlants() or self:CanEatMeat()
end

-- Returns whether or not this creature can drink water, specifically returning if they are *not* a Photocarni.
function SpeciesInfoProvider:CanDrinkWater(): boolean
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Diet.CanDrinkWater
end

------------------------------------------------------------------
--------------------- SIZE / GROWTH / TIER -----------------------
------------------------------------------------------------------
-- Returns the time in minutes that it takes this creature to grow.
function SpeciesInfoProvider:GetTimeToGrow(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Size.MinutesToGrow
end

-- Multiply by 60, divide by 99
-- This is because TimeToGrow is in minutes now (get seconds from *60), then divide by 99 because we that value is how long
-- it takes to gain 99 age points, 99 because creature age has a minimum of 1, not 0.
local CONST_GROWTH_TIME_MOD = 60 / 99

-- Returns how long it takes for the creature's age to go up by 1, in seconds.
function SpeciesInfoProvider:GetGrowthTickLength(): number
	local self: Species = self::any
	return self:GetTimeToGrow() * CONST_GROWTH_TIME_MOD
end

-- Returns this creature's tier, which is a generalization of its size, speed, and mass.
function SpeciesInfoProvider:GetTier(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Size.Tier
end

-- Returns this creature's weight at age 100, which is used for damage scaling (heavier creatures do more damage to lighter creatures).
function SpeciesInfoProvider:GetMaxWeight(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Size.Weight
end

-- Returns this creature's pickup weight at age 100, which is used to determine which creatures they can carry, and which creatures can carry them.
function SpeciesInfoProvider:GetMaxPickupWeight(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Size.PickupWeight
end

-- Returns an age value (0-100) for this creature given the amount of time it has been alive, which is expected to be in seconds, not minutes.
-- If the time to grow for this creature is zero, this returns 100.
function SpeciesInfoProvider:GetAgeForTime(timeAlive: number): number
	local self: Species = self::any
	local timeInMinutes = timeAlive / 60
	local relative = math.clampRatio01(timeInMinutes / self:GetTimeToGrow(), 1) 
	-- protected against NAN, that's what the second param is, the default if x/0 is passed in
	return math.round(relative * 100)
end

------------------------------------------------------------------
---------------------------- GENERIC -----------------------------
------------------------------------------------------------------
-- Returns the amount of air this creature has at age 100. A replacement for using stamina underwater.
function SpeciesInfoProvider:GetMaxAir(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.Mobility.Endurance.Air
end

-- Returns the amount of air regeneration this creature has.
function SpeciesInfoProvider:GetAirRegenPerSecond(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.Mobility.Endurance.AirRegenPerSecond
end

-- Returns the ambush speed multiplier of this creature. Unless someone's brain went sicko mode, this should be a value equal to 0, or greater than 1. It should never be between 0 and 1.
-- To check for whether or not this creature is capable of ambushing, consider using CanAmbush() instead.
function SpeciesInfoProvider:GetAmbushSpeedMultiplier(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Stats.AmbushSpeedMultiplier
end

-- Returns the amount of health this creature regenerates per tick when unaffected by any ailments. This value is a percentage of their maximum health.
function SpeciesInfoProvider:GetHealPercentPerSecond(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Stats.HealPercentPerSecond / 100
end

-- Returns the standard maximum health for this creature when at age 100 without any modifications or mutations.
function SpeciesInfoProvider:GetMaxHealth(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Stats.Health
end

-- Returns this creature's nightvision, which is a value in the range of 1 and 4. These values have names associated with them in the SonariaConstants module.
-- To check for Nightstalker, consider using IsNightstalker()
function SpeciesInfoProvider:GetNightvision(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Stats.Nightvision
end

------------------------------------------------------------------
---------------------------- ATTACKS -----------------------------
------------------------------------------------------------------

--[[
	MainInfo.Stats:
			AreaAilments: {[string]: CreatureAreaAilmentStats},
			MeleeAilments: {[string]: CreatureOffensiveAilmentStats},
			DefensiveAilments: {[string]: CreatureDefensiveAilmentStats},
			AilmentResistances: {[string]: CreatureResistanceStats}
--]]

-- Returns all ailments this creature inflicts on melee attack.
function SpeciesInfoProvider:GetAilmentsOnMelee(): {[string]: CreatureOffensiveAilmentStats}
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local stats = self.RawData.Specifications.MainInfo.Stats
	return stats.MeleeAilments
end

-- Returns all ailments this creature inflicts on attackers that attack them.
function SpeciesInfoProvider:GetDefensiveAilments(): {[string]: CreatureDefensiveAilmentStats}
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local stats = self.RawData.Specifications.MainInfo.Stats
	return stats.DefensiveAilments
end

-- Returns all ailments this creature can inflict under certain contexts within a given range.
function SpeciesInfoProvider:GetAreaOfEffectAilments(): {[string]: CreatureAreaAilmentStats}
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local stats = self.RawData.Specifications.MainInfo.Stats
	return stats.AreaAilments
end

-- Returns whether or not this creature has a breath attack.
function SpeciesInfoProvider:HasBreathAttack(): boolean
	local self: Species = self::any
	return not string.isNilOrEmpty(self:GetBreathType())
end

-- Returns the name of this creature's breath attack type, or an empty string if it does not have one.
-- Consider using HasBreathAttack() to determine if the creature has the ability to use a breath.
-- The names of breaths are defined in ReplicatedStorage.Storage.AbilityStats
function SpeciesInfoProvider:GetBreathType(): string?
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local breathType = self.RawData.Specifications.MainInfo.Stats.Attack.BreathType
	if string.isNilOrEmpty(breathType) then
		return nil
	end
	return breathType
end

-- Returns whether or not this creature heals their target when using melee instead of damaging.
function SpeciesInfoProvider:IsMeleeHealer(): boolean
	local self: Species = self::any
	return self:GetMaxDamage() < 0
end

-- Returns the amount of damage this creature will do when it is at age 100.
function SpeciesInfoProvider:GetMaxDamage(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Stats.Attack.Damage
end

-- Returns the amount of time, in seconds, that a creature must wait between melee attacks.
function SpeciesInfoProvider:GetDelayBetweenAttacks(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Stats.Attack.AttackDelaySeconds
end

------------------------------------------------------------------
-------------------------- RESISTANCES ---------------------------
------------------------------------------------------------------

-- Returns whether or not this creature is immune to the given status effect, optionally with the given specific sub-ailment.
-- Note that this requires duration and level resistance to both be 100%.
-- If the given sub-ailment is an empty string or nil, then the default status without a sub-ailment is checked.
-- The subailment is delivered in condensed form, e.g. Poison$Radioactive for the statusEffect parameter.
-- Because this method is unaware of age, it returns a value reflecting the creature at age 100. This may not be correct for the creature elsewhere.
function SpeciesInfoProvider:IsImmuneTo(statusEffect: string): boolean
	local self: Species = self::any
	local level, duration = self:GetRawStatusEffectSubtractionFactor(statusEffect)
	return level == 1 and duration == 1
end

-- Returns this creature's capability to reduce the given input status effect, optionally with the given specific sub-ailment.
-- This returns two values, the first being the resistance to levels, the second being resistance to duration.
-- THE RETURN VALUE ***MUST*** BE APPLIED AS FOLLOWS:
--[[
	local originalLevel = ... -- Some level, say, an effect coming in from an attack.
	-- For ease of access, say there is no duration.
	local levelResistanceFactor, _ = self:GetRawStatusEffectFactor(...)
	originalLevel -= originalLevel * levelResistanceFactor
	-- ^ Subtract (original * factor) from original.
	-- ^ This is the important bit!
--]]
-- This is not affected by other status effects as this is the species default. To get a more contextually-aware result, use
-- CharacterInfo instead.
function SpeciesInfoProvider:GetRawStatusEffectSubtractionFactor(statusEffect: string): (number, number)
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local resistances: {[string]: CreatureResistanceStats} = self.RawData.Specifications.MainInfo.Stats.AilmentResistances

	local resistance = resistances[statusEffect]
	if resistance then
		local reductionOfLevel = math.min(resistance.LevelResistance / 100, 1)
		local reductionOfDuration = math.min(resistance.DurationResistance / 100, 1)
		return reductionOfLevel, reductionOfDuration
	end
	return 0, 0
end

------------------------------------------------------------------
--------------------------- MOBILITY -----------------------------
------------------------------------------------------------------
-- Returns this creature's base walk speed (at age 100) without any context as to what ailments or buffs it has.
function SpeciesInfoProvider:GetWalkSpeed(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.Mobility.Agility.WalkSpeed
end

-- Returns this creature's base sprint speed (at age 100) without any context as to what ailments or buffs it has.
function SpeciesInfoProvider:GetSprintSpeed(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.Mobility.Agility.SprintSpeed
end

-- Returns this creature's base swimming speed (at age 100) without any context as to what ailments or buffs it has.
function SpeciesInfoProvider:GetSwimSpeed(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.Mobility.Agility.SwimSpeed
end

-- Returns this creature's base speed swimming speed (at age 100) without any context as to what ailments or buffs it has.
function SpeciesInfoProvider:GetSwimFastSpeed(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.Mobility.Agility.SwimFastSpeed
end

-- Returns this creature's base flight speed (at age 100) without any context as to what ailments or buffs it has, or 0 if it is incapable of flight.
function SpeciesInfoProvider:GetFlySpeed(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	if not self:IsAerial() then
		return 0
	end
	local agility = self.RawData.Specifications.Mobility.Agility
	return agility.FlySpeed
end

-- Returns this creature's turn radius.
function SpeciesInfoProvider:GetTurnRadius(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.Mobility.Agility.StudTurnRadius
end

-- Returns the velocity that is set on the Y axis when jumping.
function SpeciesInfoProvider:GetJumpImpulsePower(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.Mobility.Agility.JumpImpulsePower
end

-- Returns this creature's turn *rate*, which is tied to the turn radius. This is the value used by the new character controller.
function SpeciesInfoProvider:GetInternalTurnRate(): number
	local self: Species = self::any
	-- local RealTurnRadius = (1 - Data.TurnRadius.Value/10) * math.max(1.6 * (1 - Player.Slot.Value.Age.Value/100), 1)
	-- (self.Swimming and (self.Aquatic and 0.042 or 0.02) or 0.042 * (1.5 - self.SprintSpeed) * RealTurnRadius * (self.Aquatic and 1.15 or 1)

	-- For turn radius, larger values denote slower turning.
	-- For turn rate, *smaller* values denote slower turning.

	local studs = self:GetTurnRadius()
	if studs == math.huge then
		return 0
	end
	return math.map(studs, 7, 62.5, 3.35, 0.45)
end

--[[
local function InternalTurnRateToStudsApprox(rate: number)
	-- Func is inverse f(x)=25/x (*roughly)
	return 25 / rate
end
--]]

-- Returns this creature's maximum stamina at age 100.
function SpeciesInfoProvider:GetMaxStamina(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.Mobility.Endurance.Stamina
end

-- Returns this creature's base stamina regen without any context as to what ailments or buffs it has.
function SpeciesInfoProvider:GetStaminaRegen(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.Mobility.Endurance.StaminaRegenPerSecond
end

------------------------------------------------------------------
-------------------------- ABILITIES -----------------------------
------------------------------------------------------------------
-- Returns the name of this creature's current active ability, active meaning it requires Q to work. 
-- To see the passive capabilities of this creature, use GetPassiveAbilities().
function SpeciesInfoProvider:GetActiveAbilityName(): string?
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local abName = self.RawData.Specifications.MainInfo.Capabilities.Abilities.AbilityName
	if string.isNilOrWhitespace(abName) then return nil end
	return abName
end

-- Returns a reference to this creature's active ability, or nil if they do not have one.
function SpeciesInfoProvider:GetActiveAbility(): Ability?
	local self: Species = self::any
	local name = self:GetActiveAbilityName()
	if name == nil then return nil end
	return AbilityRegistry.GetAbility(name::string) :: Ability
end

-- An alias to checking if self:GetActiveAbilityName() is not nil or empty.
function SpeciesInfoProvider:HasActiveAbility(): boolean
	local self: Species = self::any
	return not string.isNilOrEmpty(self:GetActiveAbilityName())
end

-- Returns the name(s) of this creature's passive abilities (which is the name of the attribute). Attributes ending in "Chance" will have the word "Chance" trimmed off.
-- Returns an empty array if none of these values are enabled.
-- This strictly returns PASSIVE abilities, or, qualities that always apply (such as bone break chance)
-- To get a list of the abilities that are active (require the player to press Q), use GetActiveAbilities().
-- Generally speaking, it is better to use the specific getter methods when possible (see below).
function SpeciesInfoProvider:GetPassiveAbilities(): {string}
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local cached = GetReadOnlyData(self, CacheKey.CREATURE_PASSIVE_ABILITIES)
	if cached then
		return cached
	end

	local retn = {}
	for attrName, attrValue in pairs(self.RawData.Specifications.MainInfo.Capabilities.Passive) do
		local _, newName = string.EndsWithGetBefore(attrName, "Chance")
		local realName = newName or attrName

		if typeof(attrValue) == "boolean" then
			if attrValue then
				table.insert(retn, realName)
			end
		elseif typeof(attrValue) == "number" then
			if attrValue > 0 then
				table.insert(retn, realName)
			end
		end
	end
	table.freeze(retn)
	PutReadOnlyData(self, CacheKey.CREATURE_PASSIVE_ABILITIES, retn)
	return retn
end

-- Returns whether or not this creature has the active ability with the given name.
-- This does not validate that the given string is a valid ability, and will instead return false for invalid abilities due to how it works.
-- It is recommended that you sample from SonariaConstants (module) for the ability name rather than hardcoding the string.
function SpeciesInfoProvider:HasAbility(ability: string): boolean
	local self: Species = self::any
	return self:GetActiveAbilityName() == ability
end

-- Returns the chance associated with abilities. Only some abilities should actually use this, such as defensive paralysis.
-- Returns a value in a range of 0 to 1.
function SpeciesInfoProvider:GetAbilityChance(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return math.clampRatio01(self.RawData.Specifications.MainInfo.Capabilities.Abilities.ChanceIfApplicable / 100, 1)
end

-- Returns the range associated with abilities. Only some abilities should actually use this (a lot of them actually)
function SpeciesInfoProvider:GetAbilityRange(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Capabilities.Abilities.RangeIfApplicable
end

-- Returns whether or not this creature can see the health of other creatures.
function SpeciesInfoProvider:CanSeeHealth(): boolean
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Capabilities.Passive.SeeHealth
end

-- Returns the range in which this creature will cause the regen amount per tick of nearby creatures to go up.
function SpeciesInfoProvider:GetPassiveHealingRange(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Capabilities.Passive.PassiveHealingRange
end

-- Returns the actual health per second healed by passive healing.
function SpeciesInfoProvider:GetPassiveHealingPerSecond(): number
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Capabilities.Passive.PassiveHealingPerSecond
end

-- Returns whether or not this creature can only do its passive healing whilst resting.
function SpeciesInfoProvider:DoPassiveHealingWhenRestingOnly(): boolean
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Capabilities.Passive.PassiveHealWhenRestingOnly
end

-- Returns whether or not this creature's passive healing only applies to packmates
function SpeciesInfoProvider:DoPassiveHealingOnPackOnly(): boolean
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.Specifications.MainInfo.Capabilities.Passive.PassiveHealingPackOnly
end

-- Returns whether or not GetPassiveHealingRange has a value greater than zero.
function SpeciesInfoProvider:IsPassiveHealer()
	local self: Species = self::any
	return self:GetPassiveHealingRange() > 0
end

-----------------------------------------------------------------
-------------------------- APPEARANCE ---------------------------
-----------------------------------------------------------------
-- // All data pertaining to the appearance of this creature.
-- // Also provides a means of verifying appearance data, such as palettes.


------------------------------------------------------------------
---------------------------- MODELS ------------------------------
------------------------------------------------------------------

-- Returns all models as a 3-element array in the order: Child, Teen, Adult
function SpeciesInfoProvider:GetAllGameplayModels(): {Model}
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local cached = GetReadOnlyData(self, CacheKey.MODELS)
	if cached then
		return cached
	end
	local data: CreatureData = self.RawData
	local retn = {
		data.CreatureVisuals.Models.Child :: Model,
		data.CreatureVisuals.Models.Teen :: Model,
		data.CreatureVisuals.Models.Adult :: Model
	}
	table.freeze(retn)
	PutReadOnlyData(self, CacheKey.MODELS, retn)
	return retn
end

-- Returns the charactermodel for this species by the given name.
-- This is the direct reference, not a clone.
-- The name should be "Child", "Teen", "Adult", or "Customizer". This will raise an error if anything else is input.
function SpeciesInfoProvider:GetModelByName(name: string): Model
	local self: Species = self::any
	if name == SonariaConstants.Age.Child then
		return self:GetModelForAge(0)
	elseif name == SonariaConstants.Age.Teen then
		return self:GetModelForAge(33)
	elseif name == SonariaConstants.Age.Adult then
		return self:GetModelForAge(66)
	elseif name == SonariaConstants.Age.Customizer then
		return self:GetCustomizerModel()
	end
	error("Invalid name \"" .. tostring(name) .. "\". Expecting either Child, Teen, or Adult.", 2)
end

-- Returns a reference to the appropriate age model (Child/Teen/Adult) for this species for the given time that it has been alive in seconds.
-- This is the direct reference, not a clone.
function SpeciesInfoProvider:GetModelForTime(time: number): Model
	local self: Species = self::any
	return self:GetModelForAge(self:GetAgeForTime(time))
end

-- Returns a reference to the appropriate age model (Child/Teen/Adult) for this species at the given age.
-- This is a constant expression, and has no variation between creatures (save for the model reference it returns).
-- This is the direct reference, not a clone.
function SpeciesInfoProvider:GetModelForAge(age: number): Model
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local data: CreatureData = self.RawData
	if age < 33 then
		return data.CreatureVisuals.Models.Child :: Model
	elseif age < 66 then
		return data.CreatureVisuals.Models.Teen :: Model
	end
	return data.CreatureVisuals.Models.Adult :: Model
end

-- Returns a reference to the model for this creature used in the customizer, which has perfect collisions.
-- This is the direct reference, not a clone.
function SpeciesInfoProvider:GetCustomizerModel(): Model
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local data: CreatureData = self.RawData
	return data.CreatureVisuals.Models.AdultCustomizer :: Model
end

------------------------------------------------------------------
----------------------------- BLOOD ------------------------------
------------------------------------------------------------------
-- Returns the color of this creature's blood when pooled on the ground.
function SpeciesInfoProvider:GetBloodColor(): Color3
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.CreatureVisuals.BloodDisplay.BloodColor
end

-- Returns the color of this creature's blood when dropping out of their body.
function SpeciesInfoProvider:GetBloodDropColor(): Color3
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.CreatureVisuals.BloodDisplay.BloodDropColor
end

-- Returns the material to use on the blood drops and pools from this creature.
function SpeciesInfoProvider:GetBloodMaterial(): Enum.Material
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.CreatureVisuals.BloodDisplay.BloodMaterial
end

-- !!! warning "Not for use in foreign policy toggles!"
--     This is a species-specific attribute that determines if *this creature* bleeds. This will **not** be `false` if the current policy does not allow blood.
-- 
-- Returns whether or not this creature bleeds (visually) when damaged. This is not implemented.
function SpeciesInfoProvider:CreatureVisuallyBleeds(): boolean
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.CreatureVisuals.BloodDisplay.HasBlood
end

------------------------------------------------------------------
--------------------------- PALETTES -----------------------------
------------------------------------------------------------------

local function GetPaletteFromArgs(self: Species, paletteOrIndex: number | CreaturePalette): CreaturePalette
	if typeof(paletteOrIndex) == "number" then
		return self:GetPalette(paletteOrIndex::number)
	else
		return paletteOrIndex::CreaturePalette
	end
end

-- Returns whether or not this creature has a palette at the given index, 1, 2, or 3. Inputing a number out of the range of 1-3 will throw an error.
function SpeciesInfoProvider:HasPalette(paletteIndex: number): boolean
	local self: Species = self::any
	return self:GetPalette(paletteIndex).Enabled
end

-- Returns the raw palette info for the palette with the given index, 1, 2, or 3. Inputing a number out of the range of 1-3 will throw an error.
function SpeciesInfoProvider:GetPalette(paletteIndex: number): CreaturePalette
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	if typeof(paletteIndex) ~= "number" or paletteIndex < 1 or paletteIndex > 2 then
		error("Palette index out of range or invalid. Expected a numeric value between 1 and 2, got " .. tostring(paletteIndex), 2)
	end
	local palettes: any = self.RawData.CreatureVisuals.Palettes
	return palettes["Palette" .. tostring(math.floor(paletteIndex))] :: CreaturePalette
end

-- Returns all enabled colors on the given palette. If the palette is disabled, this will return an empty array.
function SpeciesInfoProvider:GetColorsOfPalette(paletteOrIndex: number | CreaturePalette): {ColorSequence}
	local self: Species = self::any
	local palette = GetPaletteFromArgs(self, paletteOrIndex) -- Let this error out if it does.
	if not palette.Enabled then return {} end
	if palette.NumberOfColorsToUse == 0 then return {} end

	local retn = {}
	for i = 1, palette.NumberOfColorsToUse do
		local color = palette["Color" .. string.format("%02d", i)] :: ColorSequence
		table.insert(retn, color)
	end
	return retn
end

-- Returns whether or not the given color index (1-12) is valid on the given palette (the palette is enabled and its NumberOfColorsToUse property is greater than that index.)
function SpeciesInfoProvider:IsColorIndexValid(paletteOrIndex: number | CreaturePalette, colorIndex: number): boolean
	local self: Species = self::any
	local palette = GetPaletteFromArgs(self, paletteOrIndex) -- Let this error out if it does.
	return palette.Enabled and palette.NumberOfColorsToUse >= colorIndex
end

-- Returns the given color from the given palette. Depending on the value of the module's UNUSED_COLORS_NIL_NOT_BLACK setting, this may return nil or an all-black sequence.
-- If strict is true, this will error instead of returning nil. Good for cases where input must be validated beforehand and should never be incorrect when this is called.
function SpeciesInfoProvider:GetColorOnPalette(paletteOrIndex: number | CreaturePalette, colorIndex: number, strict: boolean?): ColorSequence?
	local self: Species = self::any
	local palette = GetPaletteFromArgs(self, paletteOrIndex) -- Let this error out if it does.
	local colorIndexName = "Color" .. string.format("%02d", colorIndex)
	if self:IsColorIndexValid(palette, colorIndex) then
		return palette[colorIndexName] :: ColorSequence
	else
		if strict then
			local reason;
			if palette.Enabled == false then
				reason = "This palette is not active and cannot be used."
			else
				if colorIndex < 1 or colorIndex > 12 then
					reason = "The color index is out of range (needs to be between 1-12, but got " .. tostring(colorIndex) .. ")"
				else
					reason = "The color at this index is not enabled. NumberOfColorsToUse (or, the highest possible index) is " .. tostring(palette.NumberOfColorsToUse)
				end
			end
			error(colorIndexName .. " on Palette" .. tostring(palette.Index) .. " is not enabled! Reason: " .. reason, 2)
		else
			return palette[colorIndexName] :: ColorSequence? -- Just return it anyway.
		end
	end
end

------------------------------------------------------------------
---------------------------- SOUNDS ------------------------------
------------------------------------------------------------------
-- Creates a new SoundInstance from the given info.
local function SoundFromInfo(soundInfo: SoundInfo): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = soundInfo.ID
	sound.RollOffMaxDistance = soundInfo.Range
	sound.RollOffMinDistance = 25
	sound.RollOffMode = Enum.RollOffMode.Inverse
	sound.Volume = soundInfo.Volume
	CollectionService:AddTag(sound, SonariaConstants.InstanceTags.AffectedByDistanceEQ)
	CollectionService:AddTag(sound, SonariaConstants.InstanceTags.MuffleNearDeath)
	return sound
end

-- Returns an array of four newly created sound instances in the order of Broadcast, Friendly, Aggressive, Speak
-- These sounds are named appropriately for the game ("1", "2", "3", and "4") and have a nil parent.
function SpeciesInfoProvider:GetAllSounds(): {Sound}
	local self: Species = self::any
	return {
		self:NewBroadcastSoundInstance(),
		self:NewFriendlySoundInstance(),
		self:NewAggressiveSoundInstance(),
		self:NewSpeakSoundInstance()
	}
end

-- Returns a new instance of this creature's Broadcast sound type. This should be directly parented to new characters, not cloned.
function SpeciesInfoProvider:NewBroadcastSoundInstance(): Sound
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local sound = SoundFromInfo(self.RawData.CreatureVisuals.Sounds.Broadcast)
	sound.Name = SonariaConstants.CreatureCallType.Broadcast .. "Call"
	return sound
end

-- Returns a new instance of this creature's Friendly sound type. This should be directly parented to new characters, not cloned.
function SpeciesInfoProvider:NewFriendlySoundInstance(): Sound
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local sound = SoundFromInfo(self.RawData.CreatureVisuals.Sounds.Friendly)
	sound.Name = SonariaConstants.CreatureCallType.Friendly .. "Call"
	return sound
end

-- Returns a new instance of this creature's Aggressive sound type. This should be directly parented to new characters, not cloned.
function SpeciesInfoProvider:NewAggressiveSoundInstance(): Sound
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local sound = SoundFromInfo(self.RawData.CreatureVisuals.Sounds.Aggressive)
	sound.Name = SonariaConstants.CreatureCallType.Aggressive .. "Call"
	return sound
end

-- Returns a new instance of this creature's Speak sound type. This should be directly parented to new characters, not cloned.
function SpeciesInfoProvider:NewSpeakSoundInstance(): Sound
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	local sound = SoundFromInfo(self.RawData.CreatureVisuals.Sounds.Speak)
	sound.Name = SonariaConstants.CreatureCallType.Speak .. "Call"
	return sound
end

------------------------------------------------------------------
-------------------------- ANIMATIONS ----------------------------
------------------------------------------------------------------
-- All methods will return nil if the creature does not have that animation.*
-- * Unless USE_NIL_ANIMATIONS_INSTEAD_OF_ZERO_ID has been set to FALSE,
-- from which they will return an animation instance whose ID is rbxassetid://0

-- Returns a template Animation object representing this creature's pose in the customizer. Also serves as their thumbnail pose.
function SpeciesInfoProvider:GetCustomizationPose(): Animation?
	local self: Species = self::any
	return self:GetActionAnimations().CustomizationPose
end

-- Returns a package of template Animation objects containing all land animations
function SpeciesInfoProvider:GetLandAnimations(): LandAnimations
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.CreatureVisuals.Animations.Land
end

-- Returns a package of template Animation objects containing all aerial animations
function SpeciesInfoProvider:GetAerialAnimations(): AerialAnimations
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.CreatureVisuals.Animations.Aerial
end

-- Returns a package of template Animation objects containing all aquatic animations
function SpeciesInfoProvider:GetAquaticAnimations(): AquaticAnimations
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.CreatureVisuals.Animations.Aquatic
end

-- Returns a package of template Animation objects containing all attack animations
function SpeciesInfoProvider:GetActionAnimations(): ActionAnimations
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.CreatureVisuals.Animations.Actions
end

-- Returns a package of animation settings.
function SpeciesInfoProvider:GetAnimationSettings(): AnimationConfiguration
	local self: Species = self::any
	if not self.RawData then self = (self::any).BaseInfo end -- In case it is called on the context of a character.
	return self.RawData.CreatureVisuals.Animations.Settings
end

---------------------------------------------------------------------------------------

-- Returns a template Animation object for the idle animation.
function SpeciesInfoProvider:GetIdleAnimation(): Animation?
	local self: Species = self::any
	return self:GetLandAnimations().Idle
end

-- Returns a template Animation object for the land walk animation.
function SpeciesInfoProvider:GetWalkAnimation(): Animation?
	local self: Species = self::any
	return self:GetLandAnimations().Walk
end

-- Returns the speed at which the walk animation (GetWalkAnimation()) should play at.
function SpeciesInfoProvider:GetWalkAnimationSpeed(): number
	local self: Species = self::any
	return self:GetAnimationSettings().WalkAnimationSpeed
end

-- Returns a template Animation object for the land run animation.
function SpeciesInfoProvider:GetRunAnimation(): Animation?
	local self: Species = self::any
	return self:GetLandAnimations().Run
end

-- Returns the speed at which the run animation (GetRunAnimation()) should play at.
function SpeciesInfoProvider:GetRunAnimationSpeed(): number
	local self: Species = self::any
	return self:GetAnimationSettings().RunAnimationSpeed
end

-- Returns a template Animation object for a land creature falling.
function SpeciesInfoProvider:GetFallAnimation(): Animation?
	local self: Species = self::any
	return self:GetLandAnimations().Fall
end

-- Returns a template Animation object for a land creature jumping.
function SpeciesInfoProvider:GetJumpAnimation(): Animation?
	local self: Species = self::any
	return self:GetLandAnimations().Jump
end

---------------------------------------------------------------
-- Returns a template Animation object for an aquatic creature idle in the water.
function SpeciesInfoProvider:GetSwimIdleAnimation(): Animation?
	local self: Species = self::any
	return self:GetAquaticAnimations().SwimIdle
end

-- Returns a template Animation object for both aquatic and land creatures swimming. This serves as a land creature's water idle.
function SpeciesInfoProvider:GetSwimAnimation(): Animation?
	local self: Species = self::any
	return self:GetAquaticAnimations().Swim
end

-- Returns a template Animation object for swimming quickly in water.
function SpeciesInfoProvider:GetSwimFastAnimation(): Animation?
	local self: Species = self::any
	return self:GetAquaticAnimations().SwimFast
end

---------------------------------------------------------------
-- Returns a template Animation object for a flying creature taking off.
function SpeciesInfoProvider:GetTakeoffAnimation(): Animation?
	local self: Species = self::any
	return self:GetAerialAnimations().Takeoff
end

-- Returns a template Animation object for a flying creature idle in the air.
function SpeciesInfoProvider:GetFlyIdleAnimation(): Animation?
	local self: Species = self::any
	return self:GetAerialAnimations().FlyIdle
end

-- Returns a template Animation object for a flying creature flying in any given direction.
function SpeciesInfoProvider:GetFlyForwardAnimation(): Animation?
	local self: Species = self::any
	return self:GetAerialAnimations().FlyForward
end

-- Returns a template Animation object for a flying creature gliding in any given direction.
function SpeciesInfoProvider:GetGlideAnimation(): Animation?
	local self: Species = self::any
	return self:GetAerialAnimations().Glide
end

-- Returns a template Animation object for a glider flapping their wings once.
function SpeciesInfoProvider:GetFlapAnimation(): Animation?
	local self: Species = self::any
	return self:GetAerialAnimations().Flap
end

-- Returns a template Animation object for a flying creature entering a dive.
function SpeciesInfoProvider:GetDiveAnimation(): Animation?
	local self: Species = self::any
	return self:GetAerialAnimations().Dive
end

---------------------------------------------------------------
-- Returns a template Animation object for a creature sitting down.
function SpeciesInfoProvider:GetSitAnimation(): Animation?
	local self: Species = self::any
	return self:GetActionAnimations().Sit
end

-- Returns a template Animation object for a creature laying down or sleeping.
function SpeciesInfoProvider:GetLayAnimation(): Animation?
	local self: Species = self::any
	return self:GetActionAnimations().Lay
end

-- Returns a template Animation object for a creature cowering.
function SpeciesInfoProvider:GetCowerAnimation(): Animation?
	local self: Species = self::any
	return self:GetActionAnimations().Cower
end

-- Returns a template Animation object for a creature exhibiting aggression.
function SpeciesInfoProvider:GetAggressionAnimation(): Animation?
	local self: Species = self::any
	return self:GetActionAnimations().Aggression
end

-- Returns a template Animation object for a land creature rolling in mud to hide their scent or get the mud buff.
function SpeciesInfoProvider:GetMudRollAnimation(): Animation?
	local self: Species = self::any
	return self:GetActionAnimations().MudRoll
end

-- Returns a template Animation object for eating any food.
function SpeciesInfoProvider:GetEatAnimation(): Animation?
	local self: Species = self::any
	return self:GetActionAnimations().Eat
end

-- Returns a template Animation object for drinking from a source of potable water.
function SpeciesInfoProvider:GetDrinkAnimation(): Animation?
	local self: Species = self::any
	return self:GetActionAnimations().Drink
end

-- Returns a template Animation object for clinging against a wall. Mostly relevant for fliers and gliders.
function SpeciesInfoProvider:GetWallClingAnimation(): Animation?
	local self: Species = self::any
	return self:GetActionAnimations().WallGrab
end

-----------------------------------------------------------------
--------------------------- HELPERS -----------------------------
-----------------------------------------------------------------
local AssetPrefixes = {
	"https://www.roblox.com/asset/?id=",
	"http://www.roblox.com/asset/?id=",
	"rbxassetid://"
}
local function IsZeroOrEmptyAssetID(value)
	local foundAnyValid = false
	for i = 1, #AssetPrefixes do
		local prefix = AssetPrefixes[i]
		local startsWith, idStr = string.StartsWithGetAfter(value, prefix)
		if startsWith then
			foundAnyValid = true
			local id = tonumber(idStr)
			if (not id) or id == 0 then
				return true
			end
		end
	end
	if not foundAnyValid then
		return true
	end
	return false
end

local function AttributeToInstance(value: any, class: string): Instance?
	if class == "Animation" then
		if IsZeroOrEmptyAssetID(value) then
			if USE_NIL_ANIMATIONS_INSTEAD_OF_ZERO_ID then
				return nil
			else
				value = "rbxassetid://0" -- Override it so that both missing and pre-existing get set to self.
			end
		end

		local instance = Instance.new("Animation")
		instance.AnimationId = value
		return instance
	elseif class == "Sound" then
		local instance = Instance.new("Sound")
		instance.SoundId = value
		return instance
	else
		error("Unsupported instance type " .. tostring(class))
	end
end

local function CopyData(creatureDataStruct: Instance, destination: {[string]: any?}, specialSection: string?)
	for attrName, attrValue in pairs(creatureDataStruct:GetAttributes()) do
		if specialSection == "Animations" then
			if typeof(attrValue) == "string" then
				destination[attrName] = AttributeToInstance(attrValue, "Animation")
			elseif typeof(attrValue) == "number" then
				-- This is a speed value. Specialer special handling.
				destination[attrName] = attrValue
			else
				warn("Unexpected type " .. typeof(attrValue) .. " when populating animations? " .. attrName .. "=" .. tostring(attrValue))
			end
			--[[
		elseif specialSection == "Sounds" then
			destination[attrName] = AttributeToInstance(attrValue, "Sound")--]]
		else
			if attrName == "BloodMaterial" then
				destination[attrName] = Enum.Material[attrValue]
			else
				destination[attrName] = attrValue
			end
		end
	end
	for _, obj in pairs(creatureDataStruct:GetChildren()) do
		if obj.Name:sub(1, 1) == "_" then continue end
		destination[obj.Name] = destination[obj.Name] or {}

		if obj.Name == "Models" then
			continue -- Skip
		elseif obj.Name == "Animations" then
			-- Special section: Animations
			-- All string attributes need to be converted to Animation instances.
			specialSection = "Animations"
		elseif obj.Name == "Sounds" then
			specialSection = "Sounds"
			-- Yeah still apply self.
		elseif obj.Name == "Palettes" then
			continue -- Skip
		end

		CopyData(obj, destination[obj.Name]::any, specialSection)
		-- Don't reset specialSection. Parent recursion calls to CopyData will not have it set.
		-- By not resetting it, the section applies to all children, thus ensuring that all descendants of a special object
		-- get the same treatment (e.g. a child of Animations is treated like an animation container, not like generic data.)
	end
end

local function RegisterCreatureColors(creature: Species)
	for paletteIndex = 1, 2 do
		local palette = creature:GetPalette(paletteIndex)
		if not palette.Enabled then continue end

		for i = 1, palette.NumberOfColorsToUse do
			CreatureColorRegistry.Append(creature:GetName(), paletteIndex, palette[string.format("Color%02d", i)])
		end
	end
end

-----------------------------------------------------------------
------------------------- CONSTRUCTOR ---------------------------
-----------------------------------------------------------------

-- Creates a new instance or returns a cached instance of creature metadata for the given species name.
-- Can optionally be a Model, which is expected to be someone's character model (where the model has its Name property set to the name of the species)
function SpeciesInfoProvider.For(inputRef: string | Configuration): Species

	local speciesName: string;
	local creature: Instance?;
	if typeof(inputRef) == "string" then
		speciesName = inputRef
	elseif typeof(inputRef) == "Instance" and inputRef:IsA("Configuration") then
		-- speciesName = inputRef.Name
		if inputRef.Parent == CreaturesFolder then
			creature = inputRef;
		end
	else
		local cls = typeof(inputRef)
		if cls == "Instance" then
			cls = (inputRef::any).ClassName
		end
		error("Invalid parameter for inputRef, expected string or model, got " .. tostring(cls), 2)
	end

	debug.profilebegin("SpeciesInfoProvider::ctor => " .. speciesName)

	if CreatureDataCache[speciesName] then
		return CreatureDataCache[speciesName]
	end

	if not creature then
		creature = CreaturesFolder:FindFirstChild(speciesName)
		if not creature then
			error("Invalid species \"" .. tostring(speciesName) .. "\".")
		end
	end

	-- At this point...
	local creature = creature::any -- Tell type checker to just stop caring lol

	local cdat: any = { -- Partial creature data.
		Name = speciesName,
		PluralName = creature:GetAttribute("PluralName"),
		Description = creature:GetAttribute("Description"),
		CreatureVisuals = {
			Models = {
				Child = creature.CreatureVisuals.Models.Child,
				Teen = creature.CreatureVisuals.Models.Teen,
				Adult = creature.CreatureVisuals.Models.Adult
			},
			Palettes = {
				Palette1 = {}::any,
				Palette2 = {}::any
			};
		}
	}

	-- MODEL CLASSIFICATION ------------------------------------------------
	for class, model in pairs(cdat.CreatureVisuals.Models) do
		model:SetAttribute("AgeName", class)
		ModelPrep.Prepare(model)
	end

	-- PALETTE COPYING -----------------------------------------------------
	for palIdx = 1, 2 do
		local palName = "Palette" .. tostring(palIdx)
		local dataPalette = cdat.CreatureVisuals.Palettes[palName]
		local instPalette = creature.CreatureVisuals.Palettes[palName]

		dataPalette.Index = palIdx -- This is mostly for internal use.
		dataPalette.Enabled = instPalette:GetAttribute("Enabled")

		local colorsToUse = instPalette:GetAttribute("NumberOfColorsToUse")
		dataPalette.NumberOfColorsToUse = colorsToUse
		for clrIdx = 1, 12 do
			local colorName = "Color" .. string.format("%02d", clrIdx)
			local instClr = instPalette:GetAttribute(colorName)
			if clrIdx > colorsToUse then
				if UNUSED_COLORS_NIL_NOT_BLACK then
					instClr = nil
				else
					instClr = ColorSequence.new(Color3.new())
				end
			end
			dataPalette[colorName] = instClr
		end
	end

	CopyData(creature, cdat, nil) -- Populate the struct with the real data.

	local provider = setmetatable({
		Object = creature,
		RawData = cdat
	}, SpeciesInfoProvider) :: any
	table.deepFreeze(provider)

	CreatureDataCache[speciesName] = provider::any
	IntrinsicData[speciesName] = {
		Sort = {Set = false},
		Gacha = {Set = false},
		IsFlier = {Set = false},
		IsGlider = {Set = false},
		CanEmitRadiation = {Set = false},
		CanDefensivelyParalyze = {Set = false},
		CanAmbush = {Set = false},
		IsNightstalker = {Set = false},
		IsWarden = {Set = false},
		IsUnbreakable = {Set = false}
	}
	RegisterCreatureColors(provider)

	debug.profileend()

	return provider::any
end

function SpeciesInfoProvider.CreateCreatureForSpawn(inputRef: string | Configuration | Species, ageModelName: string): Model
	if game:GetService("RunService"):IsClient() then
		error("WELL UR NOT ALLOWED")
		return nil::any
	end
	local species: Species;
	if (typeof(inputRef) == "table") then
		species = inputRef::any
	else
		species = SpeciesInfoProvider.For(inputRef)
	end
	local duplicate = species:GetModelByName(ageModelName):Clone()
	return duplicate
end

function SpeciesInfoProvider.GetAgeNameForAge(age: number): string
	if age < 33 then
		return SonariaConstants.Age.Child
	elseif age < 66 then
		return SonariaConstants.Age.Teen
	end
	return SonariaConstants.Age.Adult
end

-- A statically bound variant of GetClampedAgeMultiplier in CharacterInfoProvider
-- If min is not defined, it defaults to 0.15
-- If max is not defined, it defaults to 1.
function SpeciesInfoProvider.StaticGetClampedAgeMultiplier(age: number, min: number?, max: number?)
	return math.clamp(age / 100, min or 0.15, max or 1)
end

-- Overrides the data of the given stored slot to be the given species at the given age with the given flags.
-- This does not respect any typical game behaviors! Anything that is overwritten here (read "special palettes, pets") will be DELETED if this is called.
-- Ensure data is returned to the owner before calling this method!
function SpeciesInfoProvider.OverrideStoredSlotData(species: string, age: number, flags: number, slot: {[any]: any}, skipGUIDAssignment: boolean?)
	if game:GetService("RunService"):IsClient() then
		error("WELL UR NOT ALLOWED")
	end
	
	if bit32.btest(flags, SonariaConstants.CreatureFlags.Dead) then
		warnstack("Something attempted to create a new creature with the dead flag set! Are you sure this is what you wanted?")
	end
	
	local data = SpeciesInfoProvider.For(species)
	local ageMult = SpeciesInfoProvider.StaticGetClampedAgeMultiplier(age)
	slot.Age = age
	slot.Flags = flags
	slot.Food = data:GetMaxAppetite() * ageMult
	slot.Water = data:GetMaxThirstAppetite() * ageMult
	if not skipGUIDAssignment then
		slot.GUID = GUID.new()
	end
	slot.Health = data:GetMaxHealth() * ageMult
	slot.SpecialPalette = string.Empty
	slot.Species = data:GetName()
	slot.ArbJson = {}
	slot.Customization = {}
	slot.PersistentStatusEffects = {}
	slot.Pets = {}
end

SpeciesInfoProvider.CreaturesFolder = CreaturesFolder

export type SpeciesInfoProvider = typeof(SpeciesInfoProvider)
export type SpeciesInstance = {
	RawData: CreatureData,
	Object: Instance
}
export type Species = SpeciesInfoProvider & SpeciesInstance

table.freeze(SpeciesInfoProvider)
return SpeciesInfoProvider