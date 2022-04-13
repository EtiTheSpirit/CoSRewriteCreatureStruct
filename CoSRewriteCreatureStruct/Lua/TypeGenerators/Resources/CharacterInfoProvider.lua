--!strict
-- A cousin to SpeciesInfoProvider, this has a similar API (minus all appearance-related functions) 
-- and represents the character-specific data *with* mutations and other effects.
-- Note that this extends the species info provider, so all methods of the species provider can be called from here too.
-- If this defines any methods that are also defined in the species info provider, then they are overridden by this when called
-- from this, but will still function as normal if invoked on the species data itself.
-- This is similar to typical OOP in something like Java or C#

-- The most important note to take is that this is multi-sided (can be required from both the client and server) and is synchronized.
-- Use this to your advantage.

--[[
	IMPORTANT NOTES FOR FUTURE MAINTAINERS:
	
	Replication is done via the pending replications table contained in each object. To register an object for replication, it needs to go into
	ReplicatedStats. The keys of ReplicatedStats are the relative path (relative to the Data folder in character) of the object that the attribute
	is contained on. The value is a array of all attributes of that object (by name) that must listen to updates.
	
	From this point, when the Character instance is created, it connects to GetAttributeChangedSignal for each of those, and automatically enqueues
	changes into the PendingChanges table. That is the end of the extents this module covers.
	
	From here, the client module CharacterStateReplicator (StarterPlayerScripts) does an update every [time], asking this instance if it has any pending
	data. If it does, it sends it to the server.
	
	The server follows this same model, with a slight deviation. If a value is changed on the server, it is auto-replicated as part of Roblox.
	The system will still send the event which prompts the client to mark that change as "expected" (the client cannot discern between a client
	side change vs a server side change, so it will mark it as a client-change no matter what. The server basically comes in and says "no, I
	did that, ignore it").
	
	For security, the client's pending changes array is static (since this is a singleton per client, and changes should not be visible for other
	clients, nor should it be accessible through the table.)
	
	ALSO:
	
	A lot of methods in SpeciesInfoProvider are overridden here, a lot of these for the sake of supporting runtime changes.
	Due to how Lua method calls work, `self` will not be the SpeciesInfoProvider instance in these cases, even if a method of
	SpeciesInfoProvider is called that isn't overridden here.
	
	Say there's a method :GetValue in both modules. SpeciesInfoProvider defines the base method, which returns 5, and this
	defines an override method which returns 10.
	
	Now say there's a method :GetValuePlusFive in SpeciesInfoProvider that calls GetValue. This does NOT need to be overridden:
	CharacterInfo:GetValuePlusFive() will pass CharacterInfo into the method's `self` parameter. When Lua realizes that the method
	doesn't actually exist in this module, it falls back to SpeciesInfoProvider, and most notably, *self is still THIS module*. Doesn't
	magically change to the other one. So when GetValuePlusFive calls GetValue, it'll still call it on this one (10), and so the return
	value will be 15.
--]]

--[[
// (java)
public class SpeciesInfoProvider {
	
	public float GetMaxHealth() {
		// Whatever here
	}

}

public class CharacterInfoProvider extends SpeciesInfoProvider {
	
	@Override
	public float GetMaxHealth() {
		float baseValue = super.GetMaxHealth(); // Call the original method in the class we are extending
		// Do whatever with mutations and return the value.
	}
	
}
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local EtiLibs = ReplicatedStorage.EtiLibs
local string = require(EtiLibs.Extension.String)
local table = require(EtiLibs.Extension.Table)
local math = require(EtiLibs.Extension.Math)
local bit32 = require(EtiLibs.Extension.Bit32)
local Attributes = require(EtiLibs.Instances.Attributes)
local InstanceHierarchy = require(EtiLibs.Instances.InstanceHierarchy)
local GUID = require(EtiLibs.Data.GUID)
local info, warnstack, printstack = unpack(require(EtiLibs.Extension.LogExtensions))
local InstanceKeyTable = require(EtiLibs.Storage.InstanceKeyTable)
type InstanceKeyTable<T> = InstanceKeyTable.InstanceKeyTable<T>

local CoreData = ReplicatedStorage.CoreData
local ReplicatedCode = ReplicatedStorage.ReplicatedCode

local CyclicRequire = require(EtiLibs.Data.CyclicRequire)

local CharacterPhysicsMarshaller; CharacterPhysicsMarshaller = CyclicRequire.Require(ReplicatedCode.World.CharacterPhysicsMarshaller, function(export) CharacterPhysicsMarshaller = export end)

local DietRegistry = require(CoreData.Registries.DietRegistry)
local StatusEffectRegistry; StatusEffectRegistry = CyclicRequire.Require(CoreData.Registries.StatusEffectRegistry, function(export) StatusEffectRegistry = export end)
local BreathRegistry; BreathRegistry = CyclicRequire.Require(CoreData.Registries.BreathRegistry, function(export) BreathRegistry = export end)
local AbilityRegistry; AbilityRegistry = CyclicRequire.Require(CoreData.Registries.AbilityRegistry, function(export) AbilityRegistry = export end)
local AbilityType = require(CoreData.Registries.AbilityRegistry.AbilityType)
type Ability = AbilityType.Ability

local StatusEffectType = require(CoreData.Registries.StatusEffectRegistry.StatusEffectType)
local BreathType = require(CoreData.Registries.BreathRegistry.BreathType)

local TableToAttributes = require(EtiLibs.Data.TableToAttributes)

-- local SaveSlotAccessor = require(script.SaveSlotAccessor)
local SpeciesInfoProvider = require(ReplicatedCode.CreatureCore.SpeciesInfoProvider)
local PetBoosts = require(ReplicatedStorage.CoreData.Registries.PlushieRegistry.PetBoosts)
local WorldInfoProvider = require(ReplicatedCode.World.WorldInfoProvider)
local CreatureTypeDefs = require(CoreData.TypeDefinitions.CreatureTypeDefs)
local DamageSource = require(ReplicatedCode.DataStructures.DamageSource)
local HealingSource = require(ReplicatedCode.DataStructures.HealingSource)
local AbstractSource = require(ReplicatedCode.DataStructures.AbstractSource)
local PackMarshaller = require(ReplicatedCode.System.PackMarshaller)

local SonariaConstants = require(CoreData.SonariaConstants)
local SonariaSettings = require(CoreData.SonariaSettings)

local ReplicateCharacterInfoEvent = script.ReplicateCharacterInfo
local CoreEvent = ReplicatedStorage.Events.CoreEvent

local PlayerReplicator = require(ReplicatedCode.System.PlayerReplicator)
type Replicator = PlayerReplicator.Replicator

local RNG = Random.new()
local APPLY_WEIGHT_BEFORE_STATUS = SonariaSettings.GetConstant(SonariaConstants.ConstantSettings.LegacyApplyWeightThenStatusForDamage)

local _trilean = require(EtiLibs.Data.Trilean)
local TRUE, FALSE, NEUTRAL = unpack(_trilean)
type trilean = _trilean.trilean

-- Strictly for use on the client. 
-- This protects pending changes from any nosy exploiters (at least a little bit better)
-- They can change self.PendingChanges til the cows come home and it's not gonna do anything.
-- Unfortunately people with stuff like Synapse can get into this and dig around all they want.
-- But hey, at least then hacking cos is p2w lol
local ClientAwaitingChangeConfirmation = false
local ClientPendingChanges: {PendingFieldChange} = {}

-- A reference to the analytics module. Only exists on the server. A dual-sided method that can be called (that drops the call on the client)
-- is directly below, as AnalyticsLog()
local _analyticsServerOnly: any;
local function AnalyticsLog(source: string, category: string, action: string, label: string?, value: number?): ()
	if game:GetService("RunService"):IsServer() then
		if not _analyticsServerOnly then
			_analyticsServerOnly = require(game:GetService("ServerScriptService").CoSCore.Analytics)
		end
		_analyticsServerOnly.Log(source, category, action, label, value)
	end
end

local function AnalyticsLogKill(victim: CharacterInfo, damage: DamageSource): ()
	if game:GetService("RunService"):IsServer() then
		if not _analyticsServerOnly then
			_analyticsServerOnly = require(game:GetService("ServerScriptService").CoSCore.Analytics)
		end
		_analyticsServerOnly.Log(string.csFormat(SonariaConstants.Analytics.SystemSource.CharacterManagerFormat, victim.Player.UserId), damage.Category, damage.Reason, damage.PlayerDamageType, damage.Amount)
	end
end

-- Uses Analytics.LogThenThrowException, which raises an error after logging it.
local function AnalyticsError(source: string, category: string, action: string, label: string?, value: number?, addedLevel: number?): ()
	if game:GetService("RunService"):IsServer() then
		if not _analyticsServerOnly then
			_analyticsServerOnly = require(game:GetService("ServerScriptService").CoSCore.Analytics)
		end
		_analyticsServerOnly.LogThenThrowException(source, category, action, label, value, 3 + (addedLevel or 0))
	else
		error(label, 2)
	end
end

local function AnalyticsErrorFromInstance(self: any, action: string, message: string, addedLevel: number?)

	local id: string | number;
	if self then
		local plr = self:GetPlayer()
		if not plr then
			id = "ERR_PLR_DESTROYED"
		else
			id = plr.UserId
		end
	else
		id = "(static)"
	end
	AnalyticsError(
		string.csFormat(SonariaConstants.Analytics.SystemSource.CharacterManagerFormat, id),
		SonariaConstants.Analytics.Categories.GameCoreSystem,
		action,
		message,
		nil,
		addedLevel
	)
end

-- A reference to the missions V2 system module. Only exists on the server. A dual-sided method that can be called (that drops the call on the client)
-- is directly below, as IncrementMissionProgress()
local _missionProgressControllerServerOnly: any;
local function IncrementMissionProgress(self: any, missionId: string, deltaValue: number)
	if game:GetService("RunService"):IsServer() then
		if not _missionProgressControllerServerOnly then 
			_missionProgressControllerServerOnly = require(game:GetService("ServerScriptService").CoSCore.MissionProgressController)
		end
		local instance = _missionProgressControllerServerOnly.Get(self:GetPlayer())
		instance:IncrementMissionProgress(missionId, deltaValue)
	end
end

local CharacterStats = {}
CharacterStats.__index = setmetatable(CharacterStats, SpeciesInfoProvider)
--CharacterStats.__metatable = "You want it? It's yours my friend, as long as you have enough rubies. [...] Sorry Link, I can't give credit! Come back when you're a little.. mmmm, richer!"
CharacterStats.__tostring = function (self: any)
	local player = self.Player
	local id = player and tostring(player.UserId) or "nil"
	return string.csFormat("CharacterData[Player=Player[Name={0}, ID={1}, IsPresent={2}], Species={3}]", player, id, tostring(player ~= nil and player:IsDescendantOf(Players), self.BaseInfo:GetName()))
end
-- Below: No longer works, metatables are different.
--[[
CharacterStats.__eq = function(left: any, right: any)
	if rawequal(left, right) then return true end
	if rawequal(left, nil) or rawequal(right, nil) then return false end -- nil == nil test is above, so this means one is nil, one isnt
	local leftType = typeof(left)
	if leftType == typeof(right) and leftType == "table" then
		local leftGUID = left.CurrentCharacterGUID
		if typeof(leftGUID) == "string" and leftGUID == right.CurrentCharacterGUID then
			return true
		end
	end
	return false
end
--]]

local Cache: InstanceKeyTable<CharacterInfo> = InstanceKeyTable.new() :: any
local ByGUID: InstanceKeyTable<CharacterInfo> = InstanceKeyTable.new() :: any
local QuickHelperCache: {[string]: any} = {}

local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()
local IS_STUDIO = RunService:IsStudio()

-- Asserts that this method is called from the client ONLY.
local function AssertIsClient()
	assert(IS_CLIENT, "Attempt to call method from Server. This method is client-only!")
end

-- Asserts that the client calling this method (if applicable) is the same as the player registered with the info.
-- This should be applied to all client-accessible setters.
local function AssertCallerIsSelf(self: any)
	-- If they (hacker) spoof all of this data successfully, congratulations, you've literally just taken some time out of your life
	-- turning someone else's controller into yours. You now have two. Greedy [i cant write the wrod im streaming if the mods find out i said bad word they will take away my steam acciount].
	if RunService:IsClient() then
		local playerTest = (self.Player == Players.LocalPlayer) and (self.Character == Players.LocalPlayer.Character)
		local shouldError = false
		if not playerTest then
			shouldError = true
		else
			-- One more thing: Hacker might've changed the player reference to themselves, so the last thing to do is
			-- check the data container object reference.
			-- #1: Make sure it's an instance. Don't want any metatable injection going on here.
			-- #2: Make sure it's a descendant of the current character, which must not be nil.
			local hasCharacter = Players.LocalPlayer.Character and Players.LocalPlayer.Character.Parent == WorldInfoProvider.CharacterFolder
			if typeof(self.DataContainerObject) ~= "Instance" or (hasCharacter and not self.DataContainerObject.Parent == Players.LocalPlayer.Character) then
				shouldError = true
			end
		end
		if shouldError then
			error("Invalid clientside call to setter from remote client.", 2)
		end
	end
end

-- Asserts that this method is called from the server ONLY.
local function AssertIsServer()
	assert(IS_SERVER, "Attempt to call method from Client. This method is server-only!")
end

local StatusEffectTemplate = { -- Represents an instance of a status effect.
	UsesDuration = false;
	Level = 0;
	StartedAt = 0;
	Duration = 0;
	SubAilment = string.Empty;
	Paused = false;
	PausedAt = 0;
};

-- This should be a reflection of the values in SpecificationsInstance's attributes. It exists solely to tell the character data builder
-- what values should exist under what names (as attributes)
local RuntimeSpecs = {
	Runtime = {
		State = {
			Sitting = false;
			Laying = false;
			Flying = false;
			Gliding = false;
			Swimming = false;
			MudRolling = false;
			Sprinting = false;
			Falling = false;
			Aggressing = false;
			Cowering = false;
			Shelter = string.Empty;
			BreathAttacking = false;
			BreathFuel = 0;
			Air = 0;
		};
		AbilityInfo = {
			LastUsedAt = 0;
			ExtraInfo = {};
		};
		StatusEffects = {}; -- PROCEDURALLY GENERATED WITH THE HELP OF THE STATUS EFFECT REGISTRY, SEE LOOP BELOW
		CombatInfo = {};
	};
};
local Specifications = table.joinTypes(table.deepishCopy(CreatureTypeDefs.IsolatedSpecifications, false), RuntimeSpecs);

-- A list of every replicatable status, grouped from instance name (relative to the Data folder in the character) =>
-- a table where keys are attribute names, and values are the corresponding setter methods' names.
-- For security, this table is frozen
-- Note that this is replicatable from both directions, though generally from client to server as the counterpart
-- is automatic as part of Roblox's engine.
local ReplicatedStats: {[string]: {[string]: string}} = table.deepFreeze({
	["Runtime.State"] = {
		["Sitting"] = "SetSitting",
		["Laying"] = "SetLaying",
		["Flying"] = "SetFlying",
		["Gliding"] = "SetGliding",
		["Swimming"] = "SetSwimming",
		["MudRolling"] = "SetRolling",
		["Sprinting"] = "SetSprinting",
		["Falling"] = "SetFalling",
		["Aggressing"] = "SetAggressing",
		["Cowering"] = "SetCowering",
		["BreathAttacking"] = "SetBreathAttacking"
	}
})

-- Will be procedurally generated and set as needed.
local AttributeLocks;

-- This type represents the object generated by the specifications table above.
-- Look at how slow studio will color code the text. It freezes if I press enter
type Specifications = CreatureTypeDefs.SpecificationsInstance
type StatusEffect = CreatureTypeDefs.StatusEffect
type NamedStatusEffect = CreatureTypeDefs.NamedStatusEffect;
type Species = SpeciesInfoProvider.Species
-- type Slot = CreatureTypeDefs.Slot
-- type DataTemplate = CreatureTypeDefs.DataTemplate
type CoSDataCharacter = CreatureTypeDefs.CoSDataCharacter
type CreatureOffensiveAilmentStats = CreatureTypeDefs.CreatureOffensiveAilmentStats
type CreatureDefensiveAilmentStats = CreatureTypeDefs.CreatureDefensiveAilmentStats
type CreatureResistanceStats = CreatureTypeDefs.CreatureResistanceStats
type CreatureAreaAilmentStats = CreatureTypeDefs.CreatureAreaAilmentStats
type DamageSource = DamageSource.DamageSource
type HealingSource = HealingSource.HealingSource
type AbstractSource = AbstractSource.AbstractSource
type SourceAilment = AbstractSource.SourceAilment
type Void = typeof(nil)

-- Create all status effects.
local __hasInitStatusEffects = false
function LateInitStatusEffects()
	if __hasInitStatusEffects then return end
	__hasInitStatusEffects = true
	
	for name in pairs(StatusEffectRegistry.Effects) do
		Specifications.Runtime.StatusEffects[name] = StatusEffectTemplate
	end
end

local function AppendPath(path: string, nextPathElement: string)
	if string.isNilOrEmpty(path) then
		return nextPathElement
	end
	return path .. "." .. nextPathElement
end

--[[
-- Looks at the cloned Data instance from the species that is parented to the character.
-- This will do a number of things
-- #1: Delete items whose values are DELETE_TOKEN (OBSOLETE)
-- #2: Create new values that are missing.
-- #3 (general): Translate the table into an instance "unioned" with the existing data instance.
-- On the initial call, tbl is the Specifications table.
-- outObjectAndAttrs is used to figure out which attributes (and on what object) should listen to changes for replication from the custom replicator.
local function VerifyContainer(tbl: any, current: Instance, pathUnified: string, outObjectAndAttrs: {any}, shouldMutateInstances: boolean)
	for index, value in pairs(tbl) do
		if typeof(value) == "table" then
			if current:FindFirstChild(index) then
				-- Object exists.
				VerifyContainer(value, current:FindFirstChild(index), AppendPath(pathUnified, index), outObjectAndAttrs, shouldMutateInstances)
			else
				if shouldMutateInstances then
					-- Object does NOT exist. Create it.
					local new = Instance.new("Folder")
					new.Name = index
					new.Parent = current
					VerifyContainer(value, new, AppendPath(pathUnified, index), outObjectAndAttrs, shouldMutateInstances)
				else
					warn("Failed to resolve object in Character Data: " .. tostring(index) .. " in " .. current:GetFullName())
				end
			end
		else
			-- DELETE_TOKEN is legacy now.
			-- The current trick is to check the existence of the equivalent index in the SPECIFICATIONS_ADDED table
			-- if such an element exists, then it should be deleted
			if value == DELETE_TOKEN and current:FindFirstChild(index) then
				if shouldMutateInstances then
					current:FindFirstChild(index):Destroy()
				end
				continue
			elseif value == DELETE_TOKEN then
				-- At this point, something went wrong. Maybe. Was it an attr?
				if shouldMutateInstances then
					if current:GetAttribute(index) == nil then
						warn("Key \"" .. index .. "\" was set to DELETE_TOKEN but this object or attribute didn't exist in the duplicated template data! Was it left behind by legacy data?")
					else
						current:SetAttribute(index, nil)
					end
				end
				continue
			end

			if shouldMutateInstances and current:GetAttribute(index) == nil then
				-- Missing attribute, this must be a newly created object. This means the table has the appropriate value.
				current:SetAttribute(index, value)
			end

			local stats = ReplicatedStats[pathUnified::string]
			if stats then
				if stats[index] then
					table.insert(outObjectAndAttrs, {current, index})
				end
			end
		end
	end
end
--]]



------------------------------------------------------------------
----------------------INTRINSIC OVERRIDES-------------------------
------------------------------------------------------------------

-- Extends the base species IsFlier() intrinsic method by adding a special case for Momola. Special. Very special.
function CharacterStats:IsFlier(): boolean
	local self: CharacterInfo = self::any
	if self:GetName() == "Momola" then
		-- TODO: A more future proof version of this!
		-- Allow creatures to define intrinsic properties on the fly somehow.
		-- Issue is there seems to be no clean way of doing this.
		if self:GetStageOfLife() ~= SonariaConstants.Age.Child then
			return true
		end
		return false
	end
	return self:GetBaseSpeciesInfo():IsFlier()
end

------------------------------------------------------------------
--------------------- MISCELLANEOUS GARBAGE ----------------------
------------------------------------------------------------------

-- Returns the underlying species-wide data for the species this character is currently using.
-- Strictly useful for accessing original values.
function CharacterStats:GetBaseSpeciesInfo(): Species
	local self: CharacterInfo = self::any
	return self.BaseInfo :: any -- Cast to any to reduce TC load.
end

-- Returns the player associated with this character data.
-- Note that due to how this type works, this may return nil if the player has left the game.
function CharacterStats:GetPlayer(): Player?
	local self: CharacterInfo = self::any
	return self.Player::any
end

-- Returns whether or not the referenced character is not nil, and if it is not, whether or not it's a child of WorldInfoProvider.CharacterFolder.
-- Being in any other location or being nil is invalid.
-- As an added requirement, the character must be the player's current character.
function CharacterStats:HasCharacter(): boolean
	local self: CharacterInfo = self::any
	if self.Character ~= nil and self.Character.Parent == WorldInfoProvider.CharacterFolder then
		local player = self:GetPlayer()
		if not player then
			warnstack("Attempted to call HasCharacter on an info object without a Player! This object is invalid.")
			return false
		else
			return player.Character == self.Character
		end
	end
	return false
end

-- Returns whether or not this instance should be considered valid.
function CharacterStats:IsValid(): boolean
	local self: CharacterInfo = self::any
	if table.isfrozen(self::any) then return false end -- Object disposed.

	local player = self:GetPlayer()
	if not player then return false end -- Missing player (they left)

	local character: Model = self.Character::any
	if not character then return false end
	if character.Parent ~= WorldInfoProvider.CharacterFolder then return false end
	if character ~= (player::Player).Character then return false end
	
	-- In case anyone wants to: No, the dead condition being true IS valid. Do not put it here as a reason to return false.

	return true
end

-- Returns the character associated with this player, which is the model this was instantiated on.
-- If the existence of the character is not known, use HasCharacter beforehand, as this will raise an error if no character exists.
function CharacterStats:GetCharacter(): CoSDataCharacter
	local self: CharacterInfo = self::any
	local character = self.Character
	if not character then
		error("No character found!", 2)
	end
	return character
end

-- Fully restores all stats of this creature.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:FullyRestore(): ()
	AssertIsServer()
	local self: CharacterInfo = self::any

	local slot = self:GetSlot()
	local shouldFinalize = self.ReplicatedPlayer:BeginBulkChanges()

	local repPlr = self.ReplicatedPlayer :: any
	repPlr:ChangeValueInCurrentSlot({"Flags"}, bit32.editFlags(slot.Flags, SonariaConstants.CreatureFlags.Dead, false))
	repPlr:ChangeValueInCurrentSlot({"Health"}, self.BaseInfo:GetMaxHealth())
	repPlr:ChangeValueInCurrentSlot({"Food"}, self.BaseInfo:GetMaxAppetite())
	repPlr:ChangeValueInCurrentSlot({"Water"}, self.BaseInfo:GetMaxThirstAppetite())
	if self:HasCharacter() then
		-- self:DirectHeal(slot.Health)
		-- TODO: New healing method.
		self:ReceiveDamageOrHealing(HealingSource.newScriptedHealth(1, true, true))
		self:CureAllStatusEffects()
	end

	if shouldFinalize then self.ReplicatedPlayer:FinalizeBulkChanges() end
end

-- Returns the number used for all calculations (in some manner) of stats relating to age. Ranges from 0.15 to 1 by default, unless a manual min/max is given.
function CharacterStats:GetClampedAgeMultiplier(min: number?, max: number?): number
	local self: CharacterInfo = self::any
	--return math.clamp(self:GetAge()::number / 100, min or 0.15, max or 1)
	return SpeciesInfoProvider.StaticGetClampedAgeMultiplier(self:GetAge(), min, max)
end

-- Returns the current phase of life this creature is in as a string, either "Child", "Teen", or "Adult"
function CharacterStats:GetStageOfLife(): string
	local self: CharacterInfo = self::any
	local age = self:GetAge()
	if age < 33 then
		return SonariaConstants.Age.Child
	elseif age < 66 then
		return SonariaConstants.Age.Teen
	else
		return SonariaConstants.Age.Adult
	end
end

--[[
-- Resizes this character to the given scale.
function CharacterStats:ResizeCharacter(scale: number): ()
	local self: CharacterInfo = self::any
	EtiLibs.Data.MotionTracker.TellLocation:FireClient(self:GetPlayer(), "AllowRootOffset")
	wait(0.2)

	for _, object: Instance in pairs(self:GetCharacter():GetDescendants()) do
		if object:IsA("BasePart") or object:IsA("SpecialMesh") then
			local object = object::BasePart
			object.Size = object.Size * scale
			for _, child in pairs(object:GetChildren()) do
				if child:IsA("JointInstance") then
					-- Set the Offset CFrames to itself adding (or subtracting) a scaled position of itself.
					child.C0 = child.C0 + child.C0.Position * (scale-1)
					child.C1 = child.C1 + child.C1.Position * (scale-1)
				end
			end
			if object:IsA("BasePart") then
				object.CustomPhysicalProperties = PhysicalProperties.new(0.05, 1, 0)
			end
		elseif object:IsA("Beam") then
			object.Width0 *= scale
			object.Width1 *= scale
		end
	end

	-- TODO: Use event.
	local recalcInstruction = Instance.new("BoolValue")
	recalcInstruction.Name = "RecalculateHeight"
	recalcInstruction.Parent = self:GetPlayer()
	game:GetService("Debris"):AddItem(recalcInstruction)

	wait(0.2)
	EtiLibs.Data.MotionTracker.TellLocation:FireClient(self:GetPlayer(), "DenyRootOffset")
end
--]]

-- Returns the current shelter value from cache, which can be compared using SonariaConstants.Shelter
-- This does not calculate the shelter value.
function CharacterStats:GetShelter(): number
	local self: CharacterInfo = self::any
	return self.DataContainerObject.Runtime.State:GetAttribute("Shelter") :: number
end

-- Sets the shelter level, which should be passed in specifically using SonariaConstants.Shelter
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:SetShelter(shelter: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	self.DataContainerObject.Runtime.State:SetAttribute("Shelter", shelter)
end

------------------------------------------------------------------
----------------------SLOT-SPECIFIC VALUES------------------------
------------------------------------------------------------------


------------------------------------------------------------------
--------- GENERAL INFORMATION

-- Returns whether or not this player owns the species for this character.
function CharacterStats:OwnsSpecies(): boolean
	local self: CharacterInfo = self::any
	local name = self.BaseInfo:GetName()
	local data = self.ReplicatedPlayer.InternalData::PlayerData
	return data.Species[name].Amount > 0
end

-- Returns the reference to the save data for the current slot this creature occupies.
-- Note that this is NOT the same as the typical "Player.Slot.Value" that you may be used to, for two reasons:
-- #1: Object slots were rendered obsolete and no longer exist. This is not a reference to an instance.
-- #2: This reflects upon the slot that this CharacterInfoProvider instance was created around, which if this object is
-- 		outdated (for example, because it wasn't disposed of properly, which is a problem in and of itself), 
-- 		may not be the actual live character's slot.
-- #3: This is read-only, and attempting to set anything will cause an error to occur.

-- For reference of what a slot object contains, check the instance in ServerScriptService.CoSCore.DataMarshaller.SlotTemplate
-- Note that the type def for slot may be outdated if there is a lack of maintainence (in which case, shame on whoever forgot to update
-- the type >:c) but otherwise the object should be considered the "correct" reference.
function CharacterStats:GetSlot(): Slot
	local self: CharacterInfo = self::any
	return self.OccupiedSlot
end

-- Returns the age of this character.
function CharacterStats:GetAge(): number
	local self: CharacterInfo = self::any
	return self:GetSlot().Age
end

-- Returns whether or not this character should change models, be it from growth or ... ungrowth? yeah.
function CharacterStats:ShouldChangeModels(): boolean
	local self: CharacterInfo = self::any
	local character = self:GetCharacter()
	return character:GetAttribute("AgeName") ~= self:GetStageOfLife()
end

-- Sets the creature's age to the given value. The value is clamped between 1 and 100.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:SetAge(age: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"Age"}, math.clamp(age, 1, 100))
end

-- Adds the given amount to the creature's age.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:AddAge(amount: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local slot = self:GetSlot()
	slot.Age = math.clamp(slot.Age + amount, 1, 100)
end

-- Returns whether or not this character is glimmering.
function CharacterStats:IsGlimmer(): boolean
	local self: CharacterInfo = self::any
	return bit32.btest(self:GetSlot().Flags, SonariaConstants.CreatureFlags.Glimmer)
end

-- Sets the glimmer state of this character to the given value.
-- An optional second boolean value can be set to true to skip visually updating the character model.
-- Its default value will result in this method also changing the material of the character.
-- Finally, this allows *removing* glimmer as well, which was not possible in the old system without a full respawn.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:SetGlimmer(value: boolean, onlySetData: boolean?): ()
	AssertIsServer()
	local self: CharacterInfo = self::any

	(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot(
		{"Flags"}, 
		bit32.editFlags(self:GetSlot().Flags, SonariaConstants.CreatureFlags.Glimmer, value)
	)
	if not onlySetData then
		local parts = self:GetCharacter():GetChildren()
		for index = 1, #parts do
			local object = parts[index]
			if object:IsA("BasePart") then
				if CollectionService:HasTag(object, "Glimmer") then
					--object.Material = if value then Enum.Material.Neon else Enum.Material[]
					local replacementMaterial: Enum.Material;
					if value then
						replacementMaterial = Enum.Material.Neon
					else
						local orgMtl = object:GetAttribute(SonariaConstants.MetadataKeys.OriginalMaterial)
						if orgMtl then
							-- Just try and if an error is thrown, let it throw, it shouldn't have ever come to the point of causing it.
							-- So if one is thrown, that needs to be fixed by a scripter, not quietly silenced.
							replacementMaterial = Enum.Material[orgMtl]
						else
							replacementMaterial = Enum.Material.Neon
						end
					end

					object.Material = replacementMaterial
				end
			end
		end
	end
end

-- Returns whether or not this character is an elder.
function CharacterStats:IsElder(): boolean
	local self: CharacterInfo = self::any
	return bit32.btest(self:GetSlot().Flags, SonariaConstants.CreatureFlags.Elder)
end

-- Sets whether or not this character is an elder. An optional second boolean value can be set to true to also perform the +10% scale increase.
-- Note that the scale increase will apply multiple times, and does not respect the size of the creature as it is now.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:SetElder(value: boolean, updateCharacter: boolean?): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot(
		{"Flags"}, 
		bit32.editFlags(self:GetSlot().Flags, SonariaConstants.CreatureFlags.Elder, value)
	)
	if updateCharacter then
		-- self:ResizeCharacter(1.1)
		warnstack("Character resizing has been temporarily disabled.")
	end
end

-- Returns whether or not this creature is nested.
function CharacterStats:IsNested(): boolean
	local self: CharacterInfo = self::any
	return bit32.btest(self:GetSlot().Flags, SonariaConstants.CreatureFlags.Nested)
end

-- Sets whether or not this creature is nested.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:SetNested(value: boolean): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot(
		{"Flags"}, 
		bit32.editFlags(self:GetSlot().Flags, SonariaConstants.CreatureFlags.Nested, value)
	)
end

-- Returns whether or not this creature is a male. Returns false if this creature is female.
-- The return value reflects on paid content limits / species ownership as well. Namely, if the species is unowned
-- and this has paid content limits, it always returns true, unless the force parameter is true.
function CharacterStats:IsMale(forceAllowFemale: boolean?): boolean
	local self: CharacterInfo = self::any
	local isMale = bit32.btest(self:GetSlot().Flags, SonariaConstants.CreatureFlags.IsMale)
	if isMale == true or forceAllowFemale == true then
		return isMale
	end

	if self:HasPaidContentLimits() and not self:OwnsSpecies() then
		return true -- Always male if this has paid content limits and they do not own the species.
	end

	return false -- The only remaining possibility is female so just hardcode a return false.
end

-- Sets whether or not this creature is a male. False means that it is female.
-- This method will always set to male if the species is unowned, unless the forceAllowFemale parameter is true.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:SetMale(male: boolean, forceAllowFemale: boolean?): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	if not forceAllowFemale and not male then
		if self:HasPaidContentLimits() and not self:OwnsSpecies() then
			male = true -- If the creature is paid and the player doesn't own it, make it male.
		end
	end

	(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot(
		{"Flags"}, 
		bit32.editFlags(self:GetSlot().Flags, SonariaConstants.CreatureFlags.IsMale, male)
	)
end

-- Returns whether or not this creature is dead.
function CharacterStats:IsDead(): boolean
	local self: CharacterInfo = self::any
	return bit32.btest(self:GetSlot().Flags, SonariaConstants.CreatureFlags.Dead)
end

-- Sets whether or not this creature is dead. Modifies the flags of the creature data in the appropriate save slot for this creature.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:SetDead(value: boolean): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot(
		{"Flags"}, 
		bit32.editFlags(self:GetSlot().Flags, SonariaConstants.CreatureFlags.Dead, value)
	);
	(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot(
		{"Health"}, 
		0
	)
end

-- Returns whether or not the character is sitting.
-- To check if the character is resting in general, consider using IsResting()
function CharacterStats:IsSitting(): boolean
	local self: CharacterInfo = self::any
	return self.DataContainerObject.Runtime.State:GetAttribute("Sitting")
end

-- Returns whether or not the character is laying down.
-- To check if the character is resting in general, consider using IsResting()
function CharacterStats:IsLaying(): boolean
	local self: CharacterInfo = self::any
	return self.DataContainerObject.Runtime.State:GetAttribute("Laying")
end

-- Returns whether or not the character is flying or gliding (or, more/less precisely, "not grounded").
function CharacterStats:IsFlyingOrGliding(): boolean
	local self: CharacterInfo = self::any
	if not self:IsAerial() then
		return false -- They are never flying/gliding if they aren't an aerial creature in the first place.
	end
	return self.DataContainerObject.Runtime.State:GetAttribute("Flying")
	-- The flight value is true for both flight and glide.
	-- If flight is false, but glide is true, then that's actually an invalid state and should be discarded.
end

-- Returns whether or not the character is specifically flying (creature can fly, spending stamina to fly.)
function CharacterStats:IsSpecificallyFlying(): boolean
	local self: CharacterInfo = self::any
	return self:IsFlyingOrGliding() and (not self.DataContainerObject.Runtime.State:GetAttribute("Gliding"))
end

-- Returns whether or not the character is gliding (be it in the air as a glider, or after pressing the button to toggle gliding.)
function CharacterStats:IsSpecificallyGliding(): boolean
	local self: CharacterInfo = self::any
	return self:IsFlyingOrGliding() and self.DataContainerObject.Runtime.State:GetAttribute("Gliding")
end

-- Returns whether or not the character is swimming.
function CharacterStats:IsSwimming(): boolean
	local self: CharacterInfo = self::any
	return self.DataContainerObject.Runtime.State:GetAttribute("Swimming")
end

-- Returns whether or not the character is running.
function CharacterStats:IsSprinting(): boolean
	local self: CharacterInfo = self::any
	return self.DataContainerObject.Runtime.State:GetAttribute("Sprinting")
end

-- Sets whether or not the player is sitting.
function CharacterStats:SetSitting(sitting: boolean): ()
	local self: CharacterInfo = self::any
	AssertCallerIsSelf(self)
	self.DataContainerObject.Runtime.State:SetAttribute("Sitting", sitting)
end

-- Sets whether or not the player is laying down.
function CharacterStats:SetLaying(laying: boolean): ()
	local self: CharacterInfo = self::any
	AssertCallerIsSelf(self)
	self.DataContainerObject.Runtime.State:SetAttribute("Laying", laying)
end

-- Sets whether or not the player is flying or gliding.
-- This method will do nothing if the species is not allowed to fly.
function CharacterStats:SetFlying(flying: boolean): ()
	local self: CharacterInfo = self::any
	AssertCallerIsSelf(self)
	if not self:IsAerial() then return end
	self.DataContainerObject.Runtime.State:SetAttribute("Flying", flying)
	if not self:IsFlier() then
		self.DataContainerObject.Runtime.State:SetAttribute("Gliding", flying)
	end
end

-- Sets whether or not the character's flight state is currently in glide mode.
function CharacterStats:SetGliding(gliding: boolean): ()
	local self: CharacterInfo = self::any
	AssertCallerIsSelf(self)
	if not self:IsAerial() then return end
	self.DataContainerObject.Runtime.State:SetAttribute("Gliding", gliding)
end

-- Sets whether or not the player is swimming.
function CharacterStats:SetSwimming(swimming: boolean): ()
	local self: CharacterInfo = self::any
	AssertCallerIsSelf(self)
	self.DataContainerObject.Runtime.State:SetAttribute("Swimming", swimming)
end

-- Sets whether or not the player is running.
function CharacterStats:SetSprinting(sprinting: boolean): ()
	local self: CharacterInfo = self::any
	AssertCallerIsSelf(self)
	self.DataContainerObject.Runtime.State:SetAttribute("Sprinting", sprinting)
end

-- Identical to IsSitting() or IsLaying(), providing a good reference point for if a creature is resting or not.
function CharacterStats:IsResting(): boolean
	local self: CharacterInfo = self::any
	return self:IsSitting() or self:IsLaying()
end

-- Whether or not the character is doing their mudroll animation.
function CharacterStats:IsRolling(): boolean
	local self: CharacterInfo = self::any
	return self.DataContainerObject.Runtime.State:GetAttribute("MudRolling")
end

-- Whether or not the character is doing their mudroll animation.
function CharacterStats:SetRolling(rolling: boolean): ()
	local self: CharacterInfo = self::any
	AssertCallerIsSelf(self)
	self.DataContainerObject.Runtime.State:SetAttribute("MudRolling", rolling)
end

-- Returns whether or not the character is falling, which means their character controller does not believe they are on the ground
-- and they aren't flying.
function CharacterStats:IsFalling(): boolean
	local self: CharacterInfo = self::any
	return self.DataContainerObject.Runtime.State:GetAttribute("Falling")
end

-- Sets whether or not the character is falling.
function CharacterStats:SetFalling(falling: boolean): ()
	local self: CharacterInfo = self::any
	AssertCallerIsSelf(self)
	self.DataContainerObject.Runtime.State:SetAttribute("Falling", falling)
end

-- Returns whether or not this creature is doing their aggressive pose.
function CharacterStats:IsAggressing(): boolean
	local self: CharacterInfo = self::any
	return self.DataContainerObject.Runtime.State:GetAttribute("Aggressing")
end

-- Sets whether or not this creature is doing their aggressive pose.
function CharacterStats:SetAggressing(aggro: boolean): ()
	local self: CharacterInfo = self::any
	AssertCallerIsSelf(self)
	self.DataContainerObject.Runtime.State:SetAttribute("Aggressing", aggro)
end

-- Returns whether or not this creature is doing their fearful pose.
function CharacterStats:IsCowering(): boolean
	local self: CharacterInfo = self::any
	return self.DataContainerObject.Runtime.State:GetAttribute("Cowering")
end

-- Sets whether or not this creature is doing their fearful pose.
function CharacterStats:SetCowering(cower: boolean): ()
	local self: CharacterInfo = self::any
	AssertCallerIsSelf(self)
	self.DataContainerObject.Runtime.State:SetAttribute("Cowering", cower)
end

-- Whether or not the creature is currently holding a pose that would prevent them from beginning a new one (until this one is done)
function CharacterStats:IsDoingPose(): boolean
	local self: CharacterInfo = self::any
	return self:IsResting() or self:IsRolling() or self:IsAggressing() or self:IsCowering()
end

-- Whether or not the character is in motion at the time of calling.
function CharacterStats:IsMoving(): boolean
	local self: CharacterInfo = self::any
	return (self:GetCharacter().PrimaryPart::BasePart).AssemblyLinearVelocity.Magnitude > 0.125
end

-- An alias method to check whether or not, under normal circumstances, the player is allowed to run.
function CharacterStats:CanSprint(): boolean
	local self: CharacterInfo = self::any
	return self:GetStamina() > 0
end

-- An alias that returns whether or not this player should be ignored by systems like sniffing.
function CharacterStats:IsDetectable(): boolean
	local self: CharacterInfo = self::any
	if self:HasStatusEffect(StatusEffectRegistry.Effects.Invisible) then
		return false
	end
	if self:HasStatusEffect(StatusEffectRegistry.Effects.Muddy) then
		return false
	end
	if self:HasStatusEffect(StatusEffectRegistry.Effects.NotSniffable) then
		return false
	end
	return true
end

------------------------------------------------------------------
----------------------INTRINSIC PROPERTIES------------------------
------------------------------------------------------------------

------ Below: Not really intrinsic, but still similar in nature.
-- Returns the aquatic state of this creature as defined by SonariaConstants.AquaAffinity
function CharacterStats:GetAquaAffinity(): string
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Capabilities.Passive:GetAttribute("AquaAffinity")
end

-- Returns whether or not this creature is aquatic. 
-- Going onto land will cause them to take damage, and they must remain in the water at all times.
function CharacterStats:IsAquatic(): boolean
	local self: CharacterInfo = self::any
	return self:GetAquaAffinity() == SonariaConstants.AquaAffinity.Aquatic
end

-- Returns whether or not this creature is semiaquatic. 
-- This allows them to swim for prolonged amounts of time and have better mobility in water, and also to be on land.
function CharacterStats:IsSemiAquatic(): boolean
	local self: CharacterInfo = self::any
	return self:GetAquaAffinity() == SonariaConstants.AquaAffinity.SemiAquatic
end

-- Returns whether or not the creature is terrestrial, or only lives on land (all aquatic attributes and aerial attributes must be false)
function CharacterStats:IsTerrestrial(): boolean
	local self: CharacterInfo = self::any
	return not (self:IsAquatic() or self:IsSemiAquatic() or self:IsAerial())
end

-- An alias method that represents whether or not a creature is generally associated with water.
-- This is identical to IsAquatic() or IsSemiAquatic()
function CharacterStats:IsAssociatedWithWater(): boolean
	local self: CharacterInfo = self::any
	return self:GetAquaAffinity() ~= SonariaConstants.AquaAffinity.Terrestrial
end

-- Returns whether or not this creature is unable to have its bones broken or ligaments torn.
function CharacterStats:IsUnbreakable(): boolean
	local self: CharacterInfo = self::any
	return  self:IsImmuneTo(StatusEffectRegistry.Effects.BoneBreak) 
		and self:IsImmuneTo(StatusEffectRegistry.Effects.LigamentTear)
end

------------------------------------------------------------------
----------------------------- DIET -------------------------------
------------------------------------------------------------------

-- Returns a string representing the food type of this creature. The values returned are preset, defined under FoodType in the SonariaConstants module.
-- For reference, these values are: "Herbivore", "Carnivore", "Omnivore", "Photovore", and "Photocarni".
function CharacterStats:GetFoodType(): string
	local self: CharacterInfo = self::any
	local retn = DietRegistry.GetNameFromFlags(self:CanEatMeat(), self:CanEatPlants(), self:CanDrinkWater())
	return retn
end

-- Returns whether or not this creature can eat plants, specifically returning true if they are an Herbivore or Omnivore.
function CharacterStats:CanEatPlants(): boolean
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Diet:GetAttribute("CanEatPlants") == true
end

-- Returns whether or not this creature can eat meat, specifically returning true if they are a Carnivore, Omnivore, or Photocarni.
function CharacterStats:CanEatMeat(): boolean
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Diet:GetAttribute("CanEatMeat") == true
end

-- Returns whether or not this creature can eat in general.
function CharacterStats:CanEatFood(): boolean
	local self: CharacterInfo = self::any
	return self:CanEatPlants() or self:CanEatMeat()
end

-- Returns whether or not this creature can drink water.
function CharacterStats:CanDrinkWater(): boolean
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Diet:GetAttribute("CanDrinkWater") == true
end

-- Returns this creature's appetite at its current age, which is the number representing how much food they can eat at most.
function CharacterStats:GetMaxAppetite(): number
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Diet:GetAttribute("Appetite")::number * self:GetClampedAgeMultiplier(0.25)
end

-- Returns this creature's thirst appetite at its current age, which is the number representing how much water they can drink at most.
function CharacterStats:GetMaxThirstAppetite(): number
	local self: CharacterInfo = self::any
	local thirst = self.DataContainerObject.MainInfo.Diet:GetAttribute("ThirstAppetite")::number
	thirst *= self:GetClampedAgeMultiplier(0.55)
	return math.max(1, thirst)
end

-- Returns whether or not this creature relies on light as one or all of its nutrient sources.
function CharacterStats:IsPhotoCreature(): boolean
	local self: CharacterInfo = self::any
	local canEat = self:CanEatFood()
	local canDrink = self:CanDrinkWater()
	if not canEat and not canDrink then
		-- A hypothetical creature that needs neither food nor water. Covering edge cases here (as of writing).
		return true -- Yes, this counts as photosynthesizing.
	end
	return canEat ~= canDrink 
	-- If this is true, then the creature only needs one either food or water, but not both and not neither.
	-- Following general game rules, this means that the missing resource is filled in by sunlight.
end

-- Returns the amount of food this creature currently has.
function CharacterStats:GetFood(): number
	local self: CharacterInfo = self::any
	return math.clamp(self:GetSlot().Food, 0, self:GetMaxAppetite())
end

-- Returns the amount of water this creature currently has.
function CharacterStats:GetWater(): number
	local self: CharacterInfo = self::any
	return math.clamp(self:GetSlot().Water, 0, self:GetMaxThirstAppetite())
end

-- Adds the given amount of food to this creature, clamping it at their appetite. Use a negative value to take food.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:AddFood(amount: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local slot: any = self:GetSlot();
	--slot.Food = math.clamp(slot.Food + amount, 0, self:GetMaxAppetite())
	(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"Food"}, math.clamp(slot.Food + amount, 0, self:GetMaxAppetite()))
end

-- Adds the given amount of water to this creature, clamping it at their thirst appetite. Use a negative value to take food.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:AddWater(amount: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local slot: any = self:GetSlot();
	--slot.Water = math.clamp(slot.Water + amount, 0, self:GetMaxThirstAppetite())
	(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"Water"}, math.clamp(slot.Water + amount, 0, self:GetMaxThirstAppetite()))
end

-- An alias that calls both AddFood and AddWater with the intent of saving one, very small network call.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:AddFoodAndWater(food: number, water: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local shouldFinalize = self.ReplicatedPlayer:BeginBulkChanges()
	self:AddFood(food)
	self:AddWater(water)
	if shouldFinalize then self.ReplicatedPlayer:FinalizeBulkChanges() end
end

-- Adds the given amount of food to this creature, clamping it at their appetite. Use a negative value to take food.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:AddFoodPercent(percent: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local slot: any = self:GetSlot();
	--slot.Food = math.clamp(slot.Food + amount, 0, self:GetMaxAppetite())
	local appetite = self:GetMaxAppetite();
	(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"Food"}, math.clamp(slot.Food + (percent * appetite), 0, appetite))
end

-- Adds the given amount of water to this creature, clamping it at their thirst appetite. Use a negative value to take food.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:AddWaterPercent(percent: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local slot: any = self:GetSlot();
	--slot.Water = math.clamp(slot.Water + amount, 0, self:GetMaxThirstAppetite())
	local thirstAppetite = self:GetMaxThirstAppetite();
	(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"Water"}, math.clamp(slot.Water + (percent * thirstAppetite), 0, thirstAppetite))
end

-- An alias that calls both AddFood and AddWater with the intent of saving one, very small network call.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:AddFoodAndWaterPercent(foodPercent: number, waterPercent: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local shouldFinalize = self.ReplicatedPlayer:BeginBulkChanges()
	self:AddFoodPercent(foodPercent)
	self:AddWaterPercent(waterPercent)
	if shouldFinalize then self.ReplicatedPlayer:FinalizeBulkChanges() end
end

-- Returns how much time (relative to some base value as a multiplier) needs to pass before
-- the player's food is decremented by 1.
function CharacterStats:GetFoodTickLengthModifier(): number
	local self: CharacterInfo = self::any
	local baseMultiplier = 1
	if WorldInfoProvider.IsNight() and self:IsPhotoCreature() and self:IsMoving() then
		baseMultiplier *= 0.5
	end
	if self:IsSprinting() then
		baseMultiplier *= 0.875
	end
	
	local levelResistance, _ = self:GetRawStatusEffectSubtractionFactor(StatusEffectRegistry.Effects.Cold)
	-- throwaway is duration resistance, not used here
	if levelResistance < 1 then
		-- Not immune
		local coldEffect = self:GetStatusEffect(StatusEffectRegistry.Effects.Cold)
		local reductionLevel = 0
		if coldEffect then
			if coldEffect.Level >= 20 then
				reductionLevel = 0.30
			elseif coldEffect.Level >= 10 then
				reductionLevel = 0.20
			else
				reductionLevel = 0.10
			end

			if SonariaSettings.GetConstant(SonariaConstants.ConstantSettings.ColdDebuffsScaleWithResistance) then
				local reductionLevelMult = 1 - levelResistance
				-- At level resistance 0, the reduction level multiplier is 100% (no change)
				-- At level resistance 1, it is 0.
				-- At level resistance -1 (100% weakness rather than resistance), it is 200% (twice as bad)
				reductionLevel *= reductionLevelMult
			end

			baseMultiplier -= baseMultiplier * reductionLevel
		end

	end

	if self:HasStatusEffect(StatusEffectRegistry.Effects.SnowShieldDeployed) then
		baseMultiplier *= 0.33
	end

	return self:ApplyPetMod(SonariaConstants.PetModifiedStats.Hunger, baseMultiplier)
end

-- Returns how much time (relative to some base value, meaning this is a multiplier) needs to pass before
-- the player's water is decremented by 1.
function CharacterStats:GetWaterTickLengthModifier(): number
	local self: CharacterInfo = self::any
	
	local baseMultiplier = 1
	
	if WorldInfoProvider.IsHotSeason() then
		baseMultiplier *= 0.90
	end
	if WorldInfoProvider.IsNight() and self:IsPhotoCreature() and self:IsMoving() then
		baseMultiplier *= 0.50
	end

	if self:HasStatusEffect(StatusEffectRegistry.Effects.SnowShieldDeployed) then
		baseMultiplier *= 0.33
	end

	return self:ApplyPetMod(SonariaConstants.PetModifiedStats.Thirst, baseMultiplier)
end

------------------------------------------------------------------
--------------------- SIZE / GROWTH / TIER -----------------------
------------------------------------------------------------------

-- Returns the maximum weight this creature can have at its current age. This is unaffected by status effects, only age.
function CharacterStats:GetMaxWeight(): number
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Size:GetAttribute("Weight") * self:GetClampedAgeMultiplier()
end

-- Returns the maximum pickup weight this creature can have at its current age. This is unaffected by status effects, only age.
function CharacterStats:GetMaxPickupWeight(): number
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Size:GetAttribute("PickupWeight") * self:GetClampedAgeMultiplier()
end


-- Returns this creature's weight at their current age, which is used for damage scaling (heavier creatures do more damage to lighter creatures) 
-- as well as controlling who can pick up who. This scales based on any applicable status effects.
function CharacterStats:GetWeight(): number
	local self: CharacterInfo = self::any
	local modifier = 1
	if self:HasStatusEffect(StatusEffectRegistry.Effectss.DroppedTail) then
		modifier *= 0.70
	end

	if self:HasStatusEffect(StatusEffectRegistry.Effects.Erosion) then
		modifier *= 0.80
	end

	if self:HasStatusEffect(StatusEffectRegistry.Effects.Harden) then
		modifier *= 1.25
	end

	return self:GetMaxWeight() * modifier
end

------------------------------------------------------------------
---------------------------- GENERIC -----------------------------
------------------------------------------------------------------

-- Alias method that applies the pet mod to the given adder, multiplier, and current value
-- This returns those three in that order, intended to replace whatever was passed in.
local function ApplyPetModAtIndex(self: CharacterInfo, stat: string, index: number, add: number, multiply: number, currentValue: number): (number, number, number)
	local pet = self:GetPetAtIndex(index)

	if pet and PetBoosts[pet].Type == stat then
		local boost = PetBoosts[pet]
		if boost.Mode == SonariaConstants.StatusModifierType.Multiplicative then
			multiply *= boost.Value
		elseif boost.Mode == SonariaConstants.StatusModifierType.Additive then
			add += boost.Value
		elseif boost.Mode == SonariaConstants.StatusModifierType.Constant then
			currentValue = boost.Value
		else
			AnalyticsErrorFromInstance(
				self, SonariaConstants.Analytics.Exceptions.MalformedDataException,
				"Pet Boost (" .. tostring(pet) .. ", Pet #" .. tostring(index) .. ") attempted to apply method \"" .. tostring(boost.Type) .. "\" which does not have a handler."
			)
		end
	end
	return add, multiply, currentValue
end

-- Acquires the pet boost associated with the given stat type, as seen in SonariaConstants.PetModifiedStats
-- Depending on how the pet applies its value, the result may change. Similarly to standard order of operations, 
-- pets that multiply the value are applied first, and then addition is performed later.
-- Pets that apply a constant value will override the input currentValue
-- If, for whatever reason, two pets both have constant values for a stat type, but the constant value is different, then that of 
-- pet2 will be used.
-- The input currentValue should be the value that would originally be used (prior to pet stat mods being applied)
-- For example, when getting max health, this should be the species default max health coupled with age/status effects/etc.
-- Which gets passed into this method and modified by the pets.
function CharacterStats:ApplyPetMod(stat: string, currentValue: number): number
	local self: CharacterInfo = self::any

	local add = 0
	local multiply = 1
	add, multiply, currentValue = ApplyPetModAtIndex(self, stat, 1, add, multiply, currentValue)
	add, multiply, currentValue = ApplyPetModAtIndex(self, stat, 2, add, multiply, currentValue)
	return (currentValue * multiply) + add
end

-- Returns the pet at the given index, which as of writing, is either 1 or 2.
-- A number that is not 1 or 2 will raise an error.
-- Returns the ID of the pet, or nil if no pet exists in this slot.
function CharacterStats:GetPetAtIndex(index: number): string?
	local self: CharacterInfo = self::any
	if index < 1 or index > 2 then
		error("Index out of range (expected either 1 or 2, got " .. tostring(index) .. ")")
	end
	local pet = self:GetSlot()["Pet" .. tostring(index)]
	if string.isNilOrEmpty(pet) then
		return nil
	end
	return pet
end

-- Returns the amount of air this creature currently has. A replacement for using stamina underwater. Currently unused, and returns stamina.
function CharacterStats:GetAir(): number
	local self: CharacterInfo = self::any
	return self:GetStamina()
end

-- Returns the amount of air this creature has at its current age. A replacement for using stamina underwater. Currently unused, and returns max stamina.
function CharacterStats:GetMaxAir(): number
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Stats:GetAttribute("Air")
end

-- Returns the ambush speed multiplier of this creature. Unless someone's brain went sicko mode, this should be a value equal to 0, or greater than 1. It should never be between 0 and 1.
-- To check for whether or not this creature is capable of ambushing, consider using CanAmbush() instead.
function CharacterStats:GetAmbushSpeedMultiplier(): number
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Stats:GetAttribute("AmbushSpeedMultiplier")
end

-- Returns whether or not this character is close to a pack healer.
function CharacterStats:IsNearPackHealer(): boolean
	local self: CharacterInfo = self::any
	if self:HasCharacter() then
		if self:IsPassiveHealer() then
			-- Ignore "function expects 2 args". it doesn't. type checker is drunk again
			return true
		end

		local character = self:GetCharacter()
		local myCharacterPosition = character:GetPivot().Position		
		local everyone: {Model} = WorldInfoProvider.CharacterFolder:GetChildren()
		for index = 1, #everyone do
			local person = everyone[index]
			local personCharacter: CharacterInfo = CharacterStats.TryGet(person, true) :: any
			if personCharacter and personCharacter:IsInPassiveHealingRange(myCharacterPosition) then
				return true
			end
		end
	end
	return false
end

-- Returns whether or not the given object is in range of MY ability. Vector3 is used verbatim. CFrame has its .Position property
-- extracted. BasePart and Model (or any other PVInstance) use the :GetPivot method
-- This always returns false if the current instance has no ability, or its range is 0.
function CharacterStats:IsInAbilityRange(affectedPersonPosition: Vector3 | CFrame | PVInstance): boolean
	local self: CharacterInfo = self::any
	if (not self:HasActiveAbility()) or self:GetAbilityRange() == 0 then return false end
	local coords: Vector3;
	if typeof(affectedPersonPosition) == "Vector3" then
		coords = affectedPersonPosition;
	elseif typeof(affectedPersonPosition) == "CFrame" then
		coords = affectedPersonPosition.Position;
	elseif typeof(affectedPersonPosition) == "Instance" then
		if affectedPersonPosition:IsA("PVInstance") then
			coords = affectedPersonPosition:GetPivot().Position
		else
			error("Invalid instance passed in (expecting PVInstance, got " .. affectedPersonPosition.ClassName .. ")", 2)
		end
	else
		error("Invalid type passed in (expecting Vector3, CFrame, or PVInstance, got " .. typeof(affectedPersonPosition) .. ")", 2)
	end

	local selfPos = self:GetCharacter():GetPivot().Position
	return (coords - selfPos).Magnitude <= self:GetAbilityRange()
end

-- Returns whether or not the given object is in range of MY passive healing. Vector3 is used verbatim. CFrame has its .Position property
-- extracted. BasePart and Model (or any other PVInstance) use the :GetPivot method.
-- This alwasy returns false if the instance this is called on is not registered as a passive healer.
function CharacterStats:IsInPassiveHealingRange(affectedPersonPosition: Vector3 | CFrame | PVInstance): boolean
	local self: CharacterInfo = self::any
	if not self:IsPassiveHealer() then return false end

	local coords: Vector3;
	if typeof(affectedPersonPosition) == "Vector3" then
		coords = affectedPersonPosition;
	elseif typeof(affectedPersonPosition) == "CFrame" then
		coords = affectedPersonPosition.Position;
	elseif typeof(affectedPersonPosition) == "Instance" then
		if affectedPersonPosition:IsA("PVInstance") then
			coords = affectedPersonPosition:GetPivot().Position
		else
			error("Invalid instance passed in (expecting PVInstance, got " .. affectedPersonPosition.ClassName .. ")", 2)
		end
	else
		error("Invalid type passed in (expecting Vector3, CFrame, or PVInstance, got " .. typeof(affectedPersonPosition) .. ")", 2)
	end

	local selfPos = self:GetCharacter():GetPivot().Position
	return (coords - selfPos).Magnitude <= self:GetPassiveHealingRange()
end

-- Returns an immutable array of CharacterInfo instances for each character in range of this character's ability.
-- Warning: This is a somewhat expensive function.
function CharacterStats:GetPlayersInAbilityRange(): {CharacterInfo}
	local self: CharacterInfo = self::any
	if (not self:HasActiveAbility()) or self:GetAbilityRange() == 0 then return table.freeze({}) end
	local all: {CharacterInfo} = CharacterStats.GetAll()
	local result: {CharacterInfo} = table.create(#all)
	for i = 1, #all do
		local character: CharacterInfo = all[i]::any
		if self:IsInAbilityRange(character:GetCharacter()) then
			table.insert(result, character)
		end
	end
	return table.freeze(result) :: any
end

-- Whether or not the character is taking passive damage that prevents healing naturally.
function CharacterStats:UnableToHealNaturally(): boolean
	local self: CharacterInfo = self::any
	local bleeding = self:HasStatusEffect(StatusEffectRegistry.Effects.Bleed)
	local poisoned = self:HasStatusEffect(StatusEffectRegistry.Effects.Poison)
	local roasted = self:HasStatusEffect(StatusEffectRegistry.Effects.Burn) and not self:IsSwimming()
	local eroding = self:HasStatusEffect(StatusEffectRegistry.Effects.Erosion)
	local starvedOrDehydrated = self:GetFood() == 0 or self:GetWater() == 0
	return bleeding or poisoned or roasted or eroding or starvedOrDehydrated
end

-- Returns the modifier to the amount of time to wait between heals.
function CharacterStats:GetHealDelayModifier(): number
	local self: CharacterInfo = self::any
	local timeToWaitMod = 1 -- For this, lower values are better.

	if self:HasStatusEffect(StatusEffectRegistry.Effects.Muddy) then
		timeToWaitMod *= 0.50
	end
	if self:IsNearPackHealer() then
		-- ignore this perfectly normal and logical error about how this function doesn't exist
		timeToWaitMod *= 0.75
	end
	if self:HasStatusEffect(StatusEffectRegistry.Effects.Adrenaline) then
		timeToWaitMod *= 2.00
	end

	return self:ApplyPetMod(SonariaConstants.PetModifiedStats.HealRate, timeToWaitMod)
end

-- Returns the percentage of this creature's max health that it regenerates per tick. This also applies effects and mutations.
-- Returns 0 if the creature is taking passive damage, such as damage from bleed.
-- To get ahold of the absolute amount that should be healed, use GetHealAmountForTick
function CharacterStats:GetHealPercentPerSecond(): number
	local self: CharacterInfo = self::any
	if self:UnableToHealNaturally() then
		return 0
	end

	local baseValue = self.BaseInfo:GetHealPercentPerSecond()
	baseValue /= 100 -- Since the internal value is 0-100
	local modifier = 1
	if self:IsResting() then
		modifier *= 1.50
	end

	local poison = self:GetStatusEffect(StatusEffectRegistry.Effects.Poison)
	if poison then
		if poison.Level >= 20 then
			modifier *= 0.50
		else
			modifier *= 0.75
		end
	end
	if self:HasStatusEffect(StatusEffectRegistry.Effects.CloggedLungs) then
		modifier *= 0.75
	end
	if self:IsElder() then
		modifier *= 0.70
	end
	if self:IsWarden() and self:HasStatusEffect(StatusEffectRegistry.Effects.WardensRage) then
		modifier *= self:GetHealthPercentage()
	end

	return baseValue * modifier
end

-- Returns the current absolute amount of health that should be healed at the time that this is called.
function CharacterStats:GetAbsoluteHealAmount(deltaTime: number): number
	local self: CharacterInfo = self::any
	return self:GetMaxHealth() * self:GetHealPercentPerSecond() * deltaTime
end

-- Returns the standard maximum health for this creature when at its current age. This also applies effects and updates the humanoid.
function CharacterStats:GetMaxHealth(): number
	local self: CharacterInfo = self::any
	local currentMod = self:GetClampedAgeMultiplier()::number
	if self:HasStatusEffect(StatusEffectRegistry.Effects.DroppedTail) then
		currentMod *= 0.70 -- 70% current value
	end
	if self:IsElder() then
		currentMod *= 1.05 -- 105% current value
	end
	local result = self.DataContainerObject.MainInfo.Stats:GetAttribute("Health")::number * currentMod
	local result = self:ApplyPetMod(SonariaConstants.PetModifiedStats.MaxHealth, result)
	local humanoid = self:GetCharacter().Humanoid
	humanoid.MaxHealth = result
	humanoid.Health = math.clamp(humanoid.Health, 0, result)
	return result
end

-- Returns the current amount of health that this character has.
function CharacterStats:GetHealth(): number
	local self: CharacterInfo = self::any
	local currentHealth = self:GetCharacter().Humanoid.Health
	local clamped = math.clamp(currentHealth, 0, self:GetMaxHealth())
	self:GetCharacter().Humanoid.Health = clamped
	return clamped
end

-- Returns the current amount of health that this character has as a percentage of their maximum health.
-- Will NEVER return a value outside of the 0 to 1 range. Protected against NaN (returns 0 if the result is NaN).
function CharacterStats:GetHealthPercentage(): number
	local self: CharacterInfo = self::any
	local currentHealth = self:GetCharacter().Humanoid.Health
	local maxHealth = self:GetMaxHealth()
	return math.clampRatio01(currentHealth / maxHealth, 0)
end

-- Directly set the health of the character to the given amount.
function CharacterStats:SetHealth(amount: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local humanoid = self:GetCharacter().Humanoid
	humanoid.Health = math.clamp(amount, 0, self:GetMaxHealth())
end

-- Returns this creature's nightvision, which is a value in the range of 1 and 4. These values have names associated with them in the SonariaConstants module.
-- To check for Nightstalker, consider using IsNightstalker()
-- Contrary to other methods being affected by context, this will NOT return 1 if the player is within range of a Nightstalker.
function CharacterStats:GetNightvision(): number
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Stats:GetAttribute("Nightvision")
end

------------------------------------------------------------------
------------------------ STATUS ATTACKS --------------------------
------------------------------------------------------------------

--[[
	MainInfo.Stats:
			AreaAilments: {[string]: CreatureAreaAilmentStats},
			MeleeAilments: {[string]: CreatureAilmentStats},
			DefensiveAilments: {[string]: CreatureAilmentStats},
			AilmentResistances: {[string]: CreatureResistanceStats}
			
	These three functions here will be a bit troublesome as they need to run fast, but can't cache due to the fact
	that character data is not immutable.
	
	TO INCREASE SPEED:
	- Use attributes (kind of already doing this)
	- Pre-allocate space where possible (table.create for arrays)
	- No verification of data integrity where the client won't even be able to tamper with it in the first place
--]]

-- Returns all ailments this creature inflicts on melee attack.
-- For speed, this method is unprotected and will not verify attributes. This may only have negative effects on the client,
-- where an exploiter has caused invalid data to occur.
function CharacterStats:GetAilmentsOnMelee(): {[string]: CreatureOffensiveAilmentStats}
	local self: CharacterInfo = self::any
	local cached = self.ArbCache[SonariaConstants.QuickCacheKeys.OffensiveAilments]
	if cached ~= nil then
		return cached
	end
	local stats = self.DataContainerObject.MainInfo.Stats.MeleeAilments
	local statObjects = stats:GetChildren()
	local length = #statObjects
	local result = {}
	for index = 1, length do
		local object = statObjects[index]
		result[object.Name] = table.freeze({
			Level = object:GetAttribute("Level");
			Duration = object:GetAttribute("Duration");
			StackLevelLimits = object:GetAttribute("StackLevelLimits");
			StackDurationLimits = object:GetAttribute("StackDurationLimits");
			RandomChance = object:GetAttribute("RandomChance");
		})
	end
	local final = table.freeze(result::any)
	self.ArbCache[SonariaConstants.QuickCacheKeys.OffensiveAilments] = final
	return final
end

-- Returns all ailments this creature inflicts on attackers that attack them.
-- For speed, this method is unprotected and will not verify attributes. This may only have negative effects on the client,
-- where an exploiter has caused invalid data to occur.
function CharacterStats:GetDefensiveAilments(): {[string]: CreatureDefensiveAilmentStats}
	local self: CharacterInfo = self::any
	local cached = self.ArbCache[SonariaConstants.QuickCacheKeys.DefensiveAilments]
	if cached ~= nil then
		return cached
	end
	local stats = self.DataContainerObject.MainInfo.Stats.DefensiveAilments
	local statObjects = stats:GetChildren()
	local length = #statObjects
	local result = {}
	for index = 1, length do
		local object = statObjects[index]
		result[object.Name] = table.freeze({
			Level = object:GetAttribute("Level");
			Duration = object:GetAttribute("Duration");
			StackLevelLimits = object:GetAttribute("StackLevelLimits");
			StackDurationLimits = object:GetAttribute("StackDurationLimits");
			RandomChance = object:GetAttribute("RandomChance");
		})
	end
	local final = table.freeze(result::any)
	self.ArbCache[SonariaConstants.QuickCacheKeys.DefensiveAilments] = final
	return final
end

-- Returns all ailments this creature can inflict under certain contexts within a given range.
-- For speed, this method is unprotected and will not verify attributes. This may only have negative effects on the client,
-- where an exploiter has caused invalid data to occur.
-- Reminder: The SpecificSubAilment field's values use...
-- - nil for "any sub effect", 
-- - empty string for "specifically no sub effect", 
-- - or an actual sub effect name.
-- (you can pass this argument directly into HasStatusEffect or InflictStatusEffect, which will return appropriately)
function CharacterStats:GetAreaOfEffectAilments(): {[string]: CreatureAreaAilmentStats}
	local self: CharacterInfo = self::any
	local stats = self.DataContainerObject.MainInfo.Stats.AreaAilments
	local cached = self.ArbCache[SonariaConstants.QuickCacheKeys.AoEAilments]
	if cached ~= nil then
		return cached
	end
	local statObjects = stats:GetChildren()
	local length = #statObjects
	local result = {}
	for index = 1, length do
		local object = statObjects[index]
		local tbl = {
			Range = object:GetAttribute("Range");
			InflictStrength = object:GetAttribute("InflictStrength");
			RequiredSelfEffect = object:GetAttribute("RequiredSelfEffect");
			SpecificSubEffect = string.Empty;
			WhenWithinLevel = object:GetAttribute("WhenWithinLevel");
		}
		local attr = object:GetAttribute("SpecificSubEffect")
		tbl.SpecificSubEffect = if string.isNilOrEmpty(attr) then nil::any elseif (attr:lower() == "any") then string.Empty else attr 

		result[object.Name] = table.freeze(tbl)
	end
	local final = table.freeze(result::any)
	self.ArbCache[SonariaConstants.QuickCacheKeys.AoEAilments] = final
	return final
end

------------------------------------------------------------------
---------------------------- ATTACKS -----------------------------
------------------------------------------------------------------

-- Returns the name of this creature's breath attack type, or an empty string if it does not have one.
-- Consider using HasBreathAttack() to determine if the creature has the ability to use a breath.
-- The names of breaths are defined in ReplicatedStorage.Storage.AbilityStats
function CharacterStats:GetBreathType(): string?
	local self: CharacterInfo = self::any
	local breathType = self.DataContainerObject.MainInfo.Stats.Attack:GetAttribute("BreathType")
	if string.isNilOrEmpty(breathType) then
		return nil
	end
	return breathType
end

-- Returns whether or not this creature heals their target when using melee instead of damaging.
function CharacterStats:IsMeleeHealer(): boolean
	local self: CharacterInfo = self::any
	return self:GetMaxDamage() < 0
end

-- Returns the amount of damage this creature will do at its current age. This is not affected by status effects, only age.
-- The return value of this method may be negative, which is true for healers.
function CharacterStats:GetMaxDamage(): number
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Stats.Attack:GetAttribute("Damage") * self:GetClampedAgeMultiplier()
end

-- Returns the amount of time, in seconds, that a creature must wait between melee attacks.
function CharacterStats:GetDelayBetweenAttacks(): number
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Stats.Attack:GetAttribute("AttackDelaySeconds") :: number
end

-- Whether or not this creature is using its breath attack.
function CharacterStats:IsBreathAttacking(): boolean
	local self: CharacterInfo = self::any
	return self.DataContainerObject.Runtime.State:GetAttribute("BreathAttacking") :: boolean
end

-- Sets whether or not this creature is using the breath attack it has.
function CharacterStats:SetBreathAttacking(attacking: boolean): ()
	local self: CharacterInfo = self::any
	AssertCallerIsSelf(self)
	if self:HasBreathAttack() then
		-- Friendly reminder that this falls back to the species itself.
		-- Species will use the method here for GetBreathType (up above). This means that if a runtime breath override is done, itll apply.
		self.DataContainerObject.Runtime.State:SetAttribute("BreathAttacking", attacking)
	end
end

-- The remaining fuel this creature has for its breath attack.
function CharacterStats:GetBreathFuel(): number
	local self: CharacterInfo = self::any
	return self.DataContainerObject.Runtime.State:GetAttribute("BreathFuel") :: number
end

------------------------------------------------------------------
-------------------------- RESISTANCES ---------------------------
------------------------------------------------------------------

-- Returns whether or not this creature is immune to the given status effect, optionally with the given specific sub-ailment.
-- If the given sub-ailment is an empty string or nil, then the default status without a sub-ailment is checked.
function CharacterStats:IsImmuneTo(statusEffect: string): boolean
	local self: CharacterInfo = self::any
	local level, duration = self:GetRawStatusEffectSubtractionFactor(statusEffect)
	return level == 1 and duration == 1
end

-- Returns this creature's capability to reduce the given input status effect, optionally with the given specific sub-ailment.
-- The statusEffect parameter also accepts an already joined name (e.g. Poison$Radioactive), but if this is passed in *and* a subailment
-- is passed in, then an error will occur.
-- This returns two values, the first being the resistance to levels, the second being resistance to duration.
-- THE RETURN VALUE ***MUST*** BE APPLIED AS FOLLOWS:
--[[
	local originalLevel = ... -- Some level, say, an effect coming in from an attack.
	-- For ease of access, say there is no duration.
	local levelResistanceFactor, _ = self:GetRawStatusEffectFactor(....)
	originalLevel -= originalLevel * levelResistanceFactor
	-- ^ Subtract (original * factor) from original.
	-- ^ This is the important bit, by the way
--]]
-- If the given sub-ailment is an empty string or nil, then the default status without a sub-ailment is checked.
function CharacterStats:GetRawStatusEffectSubtractionFactor(statusEffect: string): (number, number)
	local self: CharacterInfo = self::any
	local base = self.BaseInfo :: Species
	-- There's some special cases here.


	local name = statusEffect
	local statusEffect, subAilment = SplitSubAilment(statusEffect, false)
	local resistanceContainer = self.DataContainerObject.MainInfo.Stats.AilmentResistances:FindFirstChild(name)
	
	if not resistanceContainer then return 0, 0 end
	
	local baseLevelMultiplier = 0
	local baseDurationMultiplier = 0
	if resistanceContainer then
		baseLevelMultiplier = math.min(resistanceContainer:GetAttribute("LevelResistance") / 100, 1)
		baseDurationMultiplier = math.min(resistanceContainer:GetAttribute("DurationResistance") / 100, 1)
	end

	if resistanceContainer:GetAttribute("ScaleWithAge") then
		local clampedAgeMul = self:GetClampedAgeMultiplier()
		baseLevelMultiplier *= clampedAgeMul
		baseDurationMultiplier *= clampedAgeMul
	end

	local mulLevel, mulDuration = StatusEffectRegistry.GetEffectMagnitudeMultiplier(self, statusEffect, subAilment)
	baseLevelMultiplier *= mulLevel
	baseDurationMultiplier *= mulDuration

	baseLevelMultiplier = math.clamp01(baseLevelMultiplier)
	baseDurationMultiplier = math.clamp01(baseDurationMultiplier)

	if StatusEffectRegistry.GetStatusEffectInfo(statusEffect).Type == StatusEffectType.Harmful then
		local effect = self:GetStatusEffect(StatusEffectRegistry.Effects.SuppressingAilments)
		if effect then
			local resistance = math.clamp01(effect.Level / 20)
			baseLevelMultiplier -= baseLevelMultiplier * resistance
			baseDurationMultiplier -= baseDurationMultiplier * resistance
		end
	end

	return baseLevelMultiplier, baseDurationMultiplier
end

------------------------------------------------------------------
--------------------------- MOBILITY -----------------------------
------------------------------------------------------------------
local function GetSpeedMod(self: any, forRunning: boolean): number
	local self: CharacterInfo = self::any
	local currentMod = 1
	if self:HasStatusEffect(StatusEffectRegistry.Effects.Paralyzed) then
		-- note that this check checks for ALL variants of paralysis. Namely, as of writing, this includes being frozen.
		return 0
	end

	local slowed = self:GetStatusEffect(StatusEffectRegistry.Effects.Slowed)
	if slowed then
		currentMod *= 1 - math.clamp01(slowed.Level * 0.05)
	end

	if self:HasStatusEffect(StatusEffectRegistry.Effects.BoneBreak) then
		currentMod *= 0.10
	end

	if self:HasStatusEffect(StatusEffectRegistry.Effects.LigamentTear) then
		currentMod *= 0.50
	end

	if self:HasStatusEffect(StatusEffectRegistry.Effects.Harden) then
		currentMod *= 0.80
	end

	if self:HasStatusEffect(StatusEffectRegistry.Effects.Adrenaline) then
		currentMod *= 1.25
	end

	if self:HasStatusEffect(StatusEffectRegistry.EffectsWithSub.Fear_Speedy) then
		currentMod *= 1.50
	end
	
	local levelResistance, _ = self:GetRawStatusEffectSubtractionFactor(StatusEffectRegistry.Effects.Cold)
	-- throwaway is duration resistance, not used here
	if levelResistance < 1 then
		-- Not immune
		local coldEffect = self:GetStatusEffect(StatusEffectRegistry.Effects.Cold)
		local reductionLevel = 0
		if coldEffect then
			if coldEffect.Level >= 20 then
				reductionLevel = 0.30
			elseif coldEffect.Level >= 10 then
				reductionLevel = 0.20
			else
				reductionLevel = 0.10
			end
			
			if SonariaSettings.GetConstant(SonariaConstants.ConstantSettings.ColdDebuffsScaleWithResistance) then
				local reductionLevelMult = 1 - levelResistance
				-- At level resistance 0, the reduction level multiplier is 100% (no change)
				-- At level resistance 1, it is 0.
				-- At level resistance -1 (100% weakness rather than resistance), it is 200% (twice as bad)
				reductionLevel *= reductionLevelMult
			end
			
			currentMod -= currentMod * reductionLevel
		end
		
	end

	if self:IsElder() then
		if forRunning then
			currentMod *= 0.80 -- Slower run
		else
			currentMod *= 1.10 -- But faster walk
		end
	end

	local stage = self:GetStageOfLife()
	if stage == SonariaConstants.Age.Child then
		currentMod *= 1.20
	elseif stage == SonariaConstants.Age.Teen then
		currentMod *= 1.10
	end
	if self:HasStatusEffect(StatusEffectRegistry.Effects.DroppedTail) then
		currentMod *= 1.20
	end
	return currentMod
end

-- Returns this creature's walk speed at their current age and affected by any ailments or buffs.
function CharacterStats:GetWalkSpeed(): number
	local self: CharacterInfo = self::any
	local agility = self.DataContainerObject.Mobility.Agility
	return agility:GetAttribute("WalkSpeed")::number * GetSpeedMod(self, false)
end

-- Returns this creature's sprint speed at their current age and affected by any ailments or buffs.
function CharacterStats:GetSprintSpeed(): number
	local self: CharacterInfo = self::any
	local agility = self.DataContainerObject.Mobility.Agility
	return agility:GetAttribute("SprintSpeed")::number * GetSpeedMod(self, true)
end

-- Returns this creature's walk speed at their current age and affected by any ailments or buffs.
function CharacterStats:GetSwimSpeed(): number
	local self: CharacterInfo = self::any
	local agility = self.DataContainerObject.Mobility.Agility
	return agility:GetAttribute("SwimSpeed")::number * GetSpeedMod(self, false)
end

-- Returns this creature's sprint speed at their current age and affected by any ailments or buffs.
function CharacterStats:GetSwimFastSpeed(): number
	local self: CharacterInfo = self::any
	local agility = self.DataContainerObject.Mobility.Agility
	return agility:GetAttribute("SwimFastSpeed")::number * GetSpeedMod(self, true)
end

-- Returns either the sprint or walk speed based on whether or not the character is sprinting. Returns 0 if the character is doing a pose.
function CharacterStats:GetContextualGroundSpeed(): number
	local self: CharacterInfo = self::any
	if self:IsDoingPose() then
		return 0
	end
	if self:IsSprinting() then
		return self:GetSprintSpeed()
	else
		return self:GetWalkSpeed()
	end
end

-- Returns either the speedswim or normal swim speed of the character based on whether or not they are sprinting. Returns 0 if the character is doing a pose.
function CharacterStats:GetContextualSwimSpeed(): number
	local self: CharacterInfo = self::any
	if self:IsDoingPose() then
		return 0
	end
	if self:IsSprinting() then
		return self:GetSwimFastSpeed()
	else
		return self:GetSwimSpeed()
	end
end

-- Returns the speed associated with the creature's current actions, including flying, swimming, or walking. Returns 0 if the character is doing a pose.
function CharacterStats:GetFullyContextualSpeed(): number
	local self: CharacterInfo = self::any
	if self:IsDoingPose() then
		return 0
	end
	
	if self:IsFlyingOrGliding() then
		return self:GetFlySpeed()
	elseif self:IsSwimming() then
		return self:GetContextualSwimSpeed()
	else
		return self:GetContextualGroundSpeed()
	end
end

-- Returns this creature's flight speed at their current age and affected by any ailments or buffs.
function CharacterStats:GetFlySpeed(): number
	local self: CharacterInfo = self::any
	if not self:IsAerial() then
		return 0
	end

	local agility = self.DataContainerObject.Mobility.Agility
	return agility:GetAttribute("FlySpeed")
end

-- Returns this creature's turn radius, measured in studs.
function CharacterStats:GetTurnRadius(): number
	local self: CharacterInfo = self::any
	return self.DataContainerObject.Mobility.Agility:GetAttribute("StudTurnRadius")
end

-- Returns this creature's turn *rate*, which is tied to the turn radius. This is the value used by the new character controller.
-- Unlike the other values, this describes a uniform rate at which rotation is applied to the character controller. It is more meaningful
-- and far more consistent.
function CharacterStats:GetInternalTurnRate(): number
	local self: CharacterInfo = self::any
	-- local RealTurnRadius = (1 - Data.TurnRadius.Value/10) * math.max(1.6 * (1 - Player.Slot.Value.Age.Value/100), 1)
	-- (self.Swimming and (self.Aquatic and 0.042 or 0.02) or 0.042 * (1.5 - self.SprintSpeed) * RealTurnRadius * (self.Aquatic and 1.15 or 1)

	-- For turn radius, larger values denote slower turning.
	-- For turn rate, smaller values denote slower turning.

	local studs = self:GetTurnRadius()
	return math.map(studs, 7, 62.5, 3.35, 0.45)
end

--[[
local function InternalTurnRateToStudsApprox(rate: number)
	-- Func is inverse f(x)=25/x (*roughly)
	return 25 / rate
end
--]]

-- Returns this creature's maximum stamina at their current age.
function CharacterStats:GetMaxStamina(): number
	local self: CharacterInfo = self::any
	local endurance = self.DataContainerObject.Mobility.Endurance
	return endurance:GetAttribute("Stamina")
end

-- Returns this creature's stamina regen
function CharacterStats:GetStaminaRegen(): number
	local self: CharacterInfo = self::any

	local endurance = self.DataContainerObject.Mobility.Endurance
	local staminaRegen = endurance:GetAttribute("StaminaRegenPerSecond")::number
	local default = staminaRegen

	if self:HasStatusEffect(StatusEffectRegistry.Effects.WardensRage) then
		return staminaRegen * 2.00 -- Warden's Rage? Always 200% rate. No effects changing this. No garbage.
	end

	local poisoned = self:GetStatusEffect(StatusEffectRegistry.Effects.Poison)
	if poisoned then
		if poisoned.Level >= 20 then
			staminaRegen = 0 -- Don't return here. If clogged lungs is a thing, they need to actually start losing stamina.
		else
			local levelRatio = poisoned.Level / 20 -- behaves as if 30 is max
			staminaRegen *= 1 - levelRatio
			-- was a flat *= 0.75 but this is more interesting and people want it
		end
	end

	local bleeding = self:GetStatusEffect(StatusEffectRegistry.Effects.Bleed)
	if bleeding then
		--[[
		if bleeding.Level >= 20 then
			staminaRegen *= 0.50
		elseif bleeding.Level >= 10 then
			staminaRegen *= 0.75 -- yes 0.75
		end
		--]]
		local levelRatio = bleeding.Level / 30
		staminaRegen *= (1 - levelRatio)
	end

	local cold = self:GetStatusEffect(StatusEffectRegistry.Effects.Cold)
	if cold then
		if cold.Level >= 20 then
			--staminaRegen *= 0.75
			local subRatio = (cold.Level - 20) / 10 -- behaves as if 30 is max
			staminaRegen *= (1 - subRatio) / 2
		end
	end

	if self:HasStatusEffect(StatusEffectRegistry.Effects.CloggedLungs) then
		staminaRegen -= (default * 0.50)
	end
	-- Yes, it is possible for staminaRegen to be NEGATIVE at this point (actively TAKE stamina). That's intentional.

	return staminaRegen
end

-- Returns the current stamina for this character, clamped between 0 and its maximum.
function CharacterStats:GetStamina(): number
	local self: CharacterInfo = self::any
	local stamina = self.DataContainerObject.Mobility.Endurance:GetAttribute("Stamina")
	return math.clamp(stamina, 0, self:GetMaxStamina())
end

-- Directly sets the player's stamina to the given value, clamped between 0 and its maximum.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:SetStamina(stamina: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local stamina = math.clamp(stamina, 0, self:GetMaxStamina())
	self.DataContainerObject.Mobility.Endurance:SetAttribute("Stamina", stamina)
end

-- Directly adds (or subtracts, if the value is negative) the given amount of stamina from the character, 
-- clamped between 0 and its maximum.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:AddStamina(stamina: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local currentStamina = self.DataContainerObject.Mobility.Endurance:GetAttribute("Stamina")
	self.DataContainerObject.Mobility.Endurance:SetAttribute("Stamina", math.clamp(currentStamina + stamina, 0, self:GetMaxStamina()))
end

-- Directly adds (or subtracts, if the value is negative) the given amount of stamina 
-- as a percentage of the character's maximum, clamped between 0 and its maximum.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:AddStaminaPercentage(staminaPercentage: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local currentStamina = self.DataContainerObject.Mobility.Endurance:GetAttribute("Stamina")
	local maxStamina = self:GetMaxStamina()
	self.DataContainerObject.Mobility.Endurance:SetAttribute("Stamina", math.clamp(currentStamina + (maxStamina * staminaPercentage), 0, maxStamina))
end

-- Directly adds (or subtracts, if the value is negative) the given amount of stamina from the character, 
-- clamped between 0 and its maximum.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:AddAir(air: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local currentStamina = self.DataContainerObject.Mobility.Endurance:GetAttribute("Air")
	self.DataContainerObject.Mobility.Endurance:SetAttribute("Air", math.clamp(currentStamina + air, 0, self:GetMaxAir()))
end

-- Directly adds (or subtracts, if the value is negative) the given amount of stamina 
-- as a percentage of the character's maximum, clamped between 0 and its maximum.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:AddAirPercentage(airPercentage: number): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local currentStamina = self.DataContainerObject.Mobility.Endurance:GetAttribute("Air")
	local maxStamina = self:GetMaxAir()
	self.DataContainerObject.Mobility.Endurance:SetAttribute("Air", math.clamp(currentStamina + (maxStamina * airPercentage), 0, maxStamina))
end

------------------------------------------------------------------
-------------------------- ABILITIES -----------------------------
------------------------------------------------------------------
-- Returns the name of this creature's current active ability, active meaning it requires Q to work. 
-- To see the passive capabilities of this creature, use GetPassiveAbilities().
function CharacterStats:GetActiveAbilityName(): string?
	local self: CharacterInfo = self::any
	local abName = self.DataContainerObject.MainInfo.Capabilities.Abilities:GetAttribute("AbilityName")
	if string.isNilOrWhitespace(abName) then return nil end
	return abName
end

-- Returns the remaining cooldown time, in seconds. Returns 0 if this creature has no ability or does not have a cooldown in place.
function CharacterStats:GetRemainingAbilityCooldown(): number
	local self: CharacterInfo = self::any
	local active = self:GetActiveAbility() :: Ability
	if active then
		local lastUsedAt = self.DataContainerObject.Runtime.AbilityInfo:GetAttribute("LastUsedAt")
		local cd = active.Cooldown
		local waited = tick() - lastUsedAt
		if waited < cd then
			return (cd - waited)
		end
	end
	return 0
end

-- Returns the chance associated with abilities. Only some abilities should actually use this, such as defensive paralysis.
-- Returns a value in a range of 0 to 1.
function CharacterStats:GetAbilityChance(): number
	local self: CharacterInfo = self::any
	return math.clamp01(self.DataContainerObject.MainInfo.Capabilities.Abilities:GetAttribute("ChanceIfApplicable") / 100)
end

-- Returns the range associated with abilities. Only some abilities should actually use this (a lot of them actually)
function CharacterStats:GetAbilityRange(): number
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Capabilities.Abilities:GetAttribute("RangeIfApplicable")
end



-- Returns the name(s) of this creature's passive abilities (which is the name of the attribute). 
-- Returns an empty list if none of the abilities are enabled.
-- This strictly returns PASSIVE abilities, or, qualities that always apply (such as bone break chance)
-- To get the ability that is active (requires the player to press Q), use GetActiveAbility().
-- Generally speaking, it is better to use the specific getter methods when possible (see lines below).
function CharacterStats:GetPassiveAbilities(): {string}
	local self: CharacterInfo = self::any
	local retn = {}
	for attrName, attrValue in pairs(self.DataContainerObject.MainInfo.Capabilities.Passive:GetAttributes()) do
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
	return retn
end

-- Returns whether or not this creature can see the health of other creatures. Currently not implemented.
function CharacterStats:CanSeeHealth(): boolean
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Capabilities.Passive:GetAttribute("SeeHealth")
end

-- Returns whether or not this creature boosts the amount of health healed back per tick on nearby packmates. This was previously called "Pack Healer"
function CharacterStats:GetPassiveHealingRange(): number
	local self: CharacterInfo = self::any
	return self.DataContainerObject.MainInfo.Capabilities.Passive:GetAttribute("PassiveHealingRange")
end

-- Whether or not this creature is currently unable to be harmed. This is an alias for checking for the godmode status effect.
function CharacterStats:IsInvincible(): boolean
	local self: CharacterInfo = self::any
	return self:HasStatusEffect(StatusEffectRegistry.Effects.GodMode)
end

------------------------------------------------------------------
------------------------ STATUS EFFECTS --------------------------
------------------------------------------------------------------

-- GLOBAL CODE: Edit this to apply a handler for every creature.
-- This executes when a status effect has been added to this creature, the species does not matter.
-- This can be used to catch status effects and do any edge case handling for single species that have unique handling of these
-- effects.
-- Returns true if the effect is allowed to apply to the character, false if not (cancel the effect)
local function GlobalOnStatusEffectAdded(self: CharacterInfo, effect: NamedStatusEffect): boolean
	if self:IsInvincible() then
		if StatusEffectRegistry.AlignmentEquals(effect.Name, StatusEffectType.Harmful) then
			return false
		end
	end
	return true
end

-- GLOBAL CODE: Edit this to apply a handler for every creature.
-- THIS WILL NOT BE EXECUTED IF THE EFFECT'S ADDITION IS CANCELED.
-- This executes when a status effect has been removed from this creature, the species does not matter.
-- This can be used to catch status effects and do any edge case handling for single species that have unique handling of these
-- effects.
local function GlobalOnStatusEffectRemoved(self: CharacterInfo, effect: string): ()
	
end

-- This is the system that calls GlobalOnStatusEffectAdded as well as the handler for the specific effect.
local function _OnStatusEffectAddedRoutine(self: CharacterInfo, effect: NamedStatusEffect): boolean
	local result = GlobalOnStatusEffectAdded(self, effect)
	if not result then return false end
	
	return StatusEffectRegistry.ExecuteAddedCallbackOf(self, effect)
end

-- This is the system that calls GlobalOnStatusEffectRemoved as well as the handler for the specific effect.
-- THIS WILL NOT BE EXECUTED IF THE EFFECT'S ADDITION IS CANCELED.
local function _OnStatusEffectRemovedRoutine(self: CharacterInfo, effect: string): ()
	GlobalOnStatusEffectRemoved(self, effect)
	StatusEffectRegistry.ExecuteRemovedCallbackOf(self, effect)
end

-- Utility method which splits a compound ailment name e.g. Poison$Radioactive and splits it into its to parts.
-- If the explicitlyNoSubAilment parameter is true, or if the ailment name ends with $, then the subailment is returned as string.Empty
-- Otherwise, the subailment is returned as nil

-- NOTE: THIS METHOD HAS BEEN BENCHMARKED. The method used here is the fastest of three potential methods.
-- Test size: 1,000,000 strings, 250,000 across 4 tests
-- Method 1: string.find, string.split (SECOND, AVG. 0.223s)
-- Method 2: string.find, string.sub, string.sub (WINNER, AVG. 0.156s)
-- Method 3: string.split (LAST, AVG. 0.284s)
-- Calls before compute time is over 8ms: approx. 360000 calls.

-- n.b string.find calls used with Plain=TRUE, this is a huge difference in performance!
-- Takeaway: Don't lose sleep because this function is called twice consecutively by some method elsewhere.
function SplitSubAilment(name: string, explicitlyNoSubAilment: boolean?): (string, string?)
	local effectEnd, subStart = name:find('$', 1, true)
	if effectEnd then
		return name:sub(1, effectEnd - 1), (if explicitlyNoSubAilment then string.Empty else name:sub(subStart::number + 1))
	end
	return name, (if explicitlyNoSubAilment then string.Empty::string? else nil)
end

-- Really lazy alias method that joins a subailment to a parent ailment, granted the subailment is not nil.
function JoinSubAilment(name: string, subAilment: string?): string
	if not subAilment then return name end
	return name .. '$' .. subAilment::string
end

-- A utility function that returns the remaining time on a status effect. Returns 0 on leveled effects
-- NEVER returns less than zero.
local function GetRemainingTimeOnStatusEffect(statusEffect: StatusEffect): number
	if not statusEffect.UsesDuration then return 0 end
	if statusEffect.Paused then
		local timeSpentAlready = statusEffect.PausedAt - statusEffect.StartedAt
		return math.max(statusEffect.Duration - timeSpentAlready, 0)
	else
		local endsAt = statusEffect.StartedAt + statusEffect.Duration
		local difference = endsAt - tick()
		return math.max(difference, 0)
	end
end

-- A utility function that returns the remaining time on a status effect. Returns 0 on leveled effects
-- NEVER returns less than zero.
local function GetRemainingTimeOnStatusEffectRaw(startedAt: number, duration: number, isPaused: boolean, pausedAt: number): number
	if isPaused then
		local timeSpentAlready = pausedAt - startedAt
		return math.max(duration - timeSpentAlready, 0)
	else
		local endsAt = startedAt + duration
		local difference = endsAt - tick()
		return math.max(difference, 0)
	end
end

-- Returns whether or not the given status effect should still apply to the player.
-- The public version of this method is HasStatusEffect
--
-- Of the three validity test methods, this is the SLOWEST method*
-- *	IMPORTANT: most time is spent on building the StatusEffect instance
-- 		if you already have the object as a table beforehand, then this is the FASTEST

-- Average time for table assembly method: 0.16007391611735 seconds
-- (3 trials, 100,000 objects, where 20,000 objects were status effects with 0 level and duration, and the remaining 80,000 were random)
-- Notable performance losses occur at approximately 5208 calls per frame (at 60 fps, where "performance losses" start at taking >0.5 frames)
-- !!! note "Not Preferred"
--     This method is not the best method to use for its purpose. If possible, consider using StatusIsValidInstance, unless the status being
--     passed in did not have to be assembled from an instance, in which case this method is the fastest option.
local function StatusIsValid(status: StatusEffect): boolean
	if status.UsesDuration then
		local correctStart = status.StartedAt <= tick() -- Can't start in the future.
		local legalDuration = status.Duration > 0 and GetRemainingTimeOnStatusEffect(status) > 0
		return correctStart and legalDuration
	else
		return status.Level > 0
	end
end

-- Returns whether or not the status is valid as a trilean value.
-- True: This effect is valid and live
-- False: This effect is invalid, and also needs to be zero'd
-- Nil: This effect is already zero'd
--
-- Of the three validity test methods, this is a GENERALLY FAST method.
-- Average time for full attribute query method: 0.09582257270813 seconds
-- (3 trials, 100,000 objects, where 20,000 objects were status effects with 0 level and duration, and the remaining 80,000 were random)
-- Notable performance losses occur at approximately 8697 calls per frame (at 60 fps, where "performance losses" start at taking >0.5 frames)
-- !!! note "Not Preferred"
--     This method is not the best method to use for its purpose. Consider using StatusIsValidInstance, unless ALL attributes of the object
--     are required for other parts of the caller's code.
local function StatusIsValidRaw(useDuration: boolean, level: number, duration: number, startedAt: number, isPaused: boolean, pausedAt: number): trilean
	if level == 0 and duration == 0 then
		-- n.b. it'd be technically best to check all values, but for speed, the minimum is tested.
		return NEUTRAL -- Zero'd effect.
	end

	if level == 0 and not useDuration then
		return FALSE
	elseif useDuration then
		if GetRemainingTimeOnStatusEffectRaw(startedAt, duration, isPaused, pausedAt) == 0 then
			-- Timed out.
			return FALSE
		end
	end

	return TRUE
end

-- Returns whether or not the status is valid as a trilean value, only checking the bare minimum attributes.
-- True: This effect is valid and live
-- False: This effect is invalid, and also needs to be zero'd
-- Nil: This effect is already zero'd
--
-- Of the three validity test methods, this is the FASTEST method.
-- Average time for only necessary attribute query method: 0.077622254689535 seconds
-- (3 trials, 100,000 objects, where 20,000 objects were status effects with 0 level and duration, and the remaining 80,000 were random)
-- Notable performance losses occur at approximately 10736 calls per frame (at 60 fps, where "performance losses" start at taking >0.5 frames)
local function StatusIsValidInstance(containerInstance: Instance): trilean
	local level: number = containerInstance:GetAttribute("Level")
	local duration: number = containerInstance:GetAttribute("Duration")
	if level == 0 and duration == 0 then
		return NEUTRAL
	end

	local useDuration = containerInstance:GetAttribute("UsesDuration")
	if level == 0 and not useDuration then
		return FALSE
	elseif useDuration then
		if GetRemainingTimeOnStatusEffectRaw(containerInstance:GetAttribute("StartedAt") :: number, duration, containerInstance:GetAttribute("Paused") :: boolean, containerInstance:GetAttribute("PausedAt") :: number) == 0 then
			return FALSE
		end
	end

	return TRUE
end

-- Creates a status effect from an object.
-- This is a generally slow method ("slow" being that it can only be called about 4.5k times per frame before the lag gets bad :c so sad)
local function CreateStatusFromObject(object: Instance): NamedStatusEffect
	return table.freeze({
		Name = object.Name;
		Level = object:GetAttribute("Level")::number;
		StartedAt = object:GetAttribute("StartedAt")::number;
		Duration = object:GetAttribute("Duration")::number;
		UsesDuration = object:GetAttribute("UsesDuration")::boolean;
		PausedAt = object:GetAttribute("PausedAt")::number;
		Paused = object:GetAttribute("Paused")::boolean;
		SubAilment = object:GetAttribute("SubAilment")::string;
	}::any)::any
end

-- Returns the existing cache of, or creates a new cache of, every instance representing a status effect in this character.
-- This can be used to make lookups orders of magnitude faster when querying staus effects, albeit
-- at the cost of longer build time on the first call.
local function GetOrCreateEffectInstanceCache(self: CharacterInfo): {Array: {Instance}, Dictionary: {[string]: Instance}}
	-- Start by caching the lookup of every instance.
	local allEffectInstances = self.ArbCache[SonariaConstants.QuickCacheKeys.AllStatusEffects]
	if not allEffectInstances then
		local objects: {Instance} = self.DataContainerObject.Runtime.StatusEffects:GetChildren()
		allEffectInstances = {
			Array = objects;
			Dictionary = {};
		}
		for i = 1, #objects do
			local effectInstance = objects[i]
			local fxName = effectInstance.Name
			allEffectInstances.Dictionary[fxName] = effectInstance
		end
		self.ArbCache[SonariaConstants.QuickCacheKeys.AllStatusEffects] = allEffectInstances
	end

	return allEffectInstances
end

-- An alias to quickly return the named status effect container instance from the cache.
local function GetStatusEffectContainer(self: CharacterInfo, name: string): Instance
	return GetOrCreateEffectInstanceCache(self).Dictionary[name]
end

-- Sets all properties to default for the given status object or name.
local function ZeroStatus(self: CharacterInfo, nameOrContainer: string | Instance): ()
	local container: Instance;
	if typeof(nameOrContainer) == "string" then
		container = GetStatusEffectContainer(self, nameOrContainer)
	else
		container = nameOrContainer::any
	end
	container:SetAttribute("UsesDuration", false)
	container:SetAttribute("Level", 0)
	container:SetAttribute("StartedAt", 0)
	container:SetAttribute("Duration", 0)
	container:SetAttribute("PausedAt", 0)
	container:SetAttribute("Paused", false)
	container:SetAttribute("SubAilment", "")
end


-- Returns whether or not the character has the given status effect.
-- Raises an error if the name is not a valid effect, or if the character data struct is malformed
-- and needs to be fixed because the status effect container flat out doesn't exist, both of which are caused by the
-- effect not being defined in StatusEffectRegistry.Effects.

-- If the effect was valid prior to calling, but is now invalid, it will be zero'd before false is returned.

-- The name can be a plain effect name, or a joined name like Poison$Radioactive.
-- If just a plain name is put in, then only the main effect is tested; any subailment is OK.
-- If a joined name is put in, that effect is only returned if the subailment is the same as well.
-- If true, explicitlyNoSubAilment mandates that the subailment MUST be an empty string (no subailment).
-- explicitlyNoSubAilment=true will also override the subailment of a joined name.
function CharacterStats:HasStatusEffect(name: string, explicitlyNoSubAilment: boolean?): boolean
	local self: CharacterInfo = self::any

	local name, withSubAilment = SplitSubAilment(name, explicitlyNoSubAilment)
	local container = GetStatusEffectContainer(self, name)
	local state: trilean = StatusIsValidInstance(container)
	if state == NEUTRAL then
		return false
	elseif state == FALSE then
		ZeroStatus(self, container)
		return false
	end
	if withSubAilment ~= nil then
		return container:GetAttribute("SubAilment") == withSubAilment
	end
	return TRUE
end

-- Returns the given status effect if it is currently affecting this character. Returns nil if it is not.
-- The returned object is readonly - attempting to modify it will throw an error. 
-- It is also a named status effect, which adds an extra .Name property.

-- Raises an error if the name is not a valid effect, or if the character data struct is malformed
-- and needs to be fixed because the status effect container flat out doesn't exist.

-- If the effect was valid prior to calling, but is now invalid, it will be zero'd before nil is returned.

-- The name can be a plain effect name, or a joined name like Poison$Radioactive.
-- If just a plain name is put in, then only the main effect is tested; any subailment is OK.
-- If a joined name is put in, that effect is only returned if the subailment is the same as well.
-- If true, explicitlyNoSubAilment mandates that the subailment MUST be an empty string (no subailment).
-- explicitlyNoSubAilment=true will also override the subailment of a joined name.
function CharacterStats:GetStatusEffect(name: string, explicitlyNoSubAilment: boolean?): NamedStatusEffect?
	local self: CharacterInfo = self::any

	local name, withSubAilment = SplitSubAilment(name, explicitlyNoSubAilment)
	local container = GetStatusEffectContainer(self, name)

	local state: trilean = StatusIsValidInstance(container)
	if state == NEUTRAL then
		return nil
	elseif state == FALSE then
		ZeroStatus(self, container)
		return nil
	end

	if withSubAilment and container:GetAttribute("SubAilment") ~= withSubAilment then
		return nil
	end
	return CreateStatusFromObject(container)
end

-- Returns the names of all inflicted + live status effects on this character.
-- This is an optimized method, and is safe to call every frame if needed. The cost is having no access to the effect data.
-- The returned table is immutable.
function CharacterStats:GetAllStatusEffects(): {string}
	local self: CharacterInfo = self::any
	local allEffectInstances = GetOrCreateEffectInstanceCache(self).Array
	local result = table.create(#allEffectInstances)
	for i = 1, #allEffectInstances do
		local effectInstance = allEffectInstances[i]
		
		-- Trilean, TRUE/FALSE/NEUTRAL are valid.
		if StatusIsValidInstance(effectInstance) == TRUE then
			table.insert(result, effectInstance.Name)
		end
	end
	return table.freeze(result)
end

-- The counterpart to GetAllStatusEffects, this returns an array of NamedStatusEffect instances with addressable data.
-- This method is not as high performance as its counterpart, but should be safe for frequent calls.
-- The returned table is immutable.
function CharacterStats:GetAllStatusEffectObjects(): {NamedStatusEffect}
	local self: CharacterInfo = self::any
	local allEffectInstances = GetOrCreateEffectInstanceCache(self).Array
	local result = table.create(#allEffectInstances)
	for i = 1, #allEffectInstances do
		local effectInstance = allEffectInstances[i]
		
		-- Trilean, TRUE/FALSE/NEUTRAL are valid.
		if StatusIsValidInstance(effectInstance) == TRUE then
			table.insert(result, CreateStatusFromObject(effectInstance))
		end
	end
	return table.freeze(result)
end

-- Directly sets the data on the given named status effect container to the given data. Does not verify any data.
-- This DOES mandate that the container exists (because it causes an error either way if it doesn't)
local function InternalInflictStatus(self: CharacterInfo, name: string, statusData: StatusEffect)
	local container = GetStatusEffectContainer(self, name)
	container:SetAttribute("UsesDuration", statusData.UsesDuration)
	container:SetAttribute("Level", statusData.Level)
	container:SetAttribute("StartedAt", statusData.StartedAt)
	container:SetAttribute("Duration", statusData.Duration)
	container:SetAttribute("PausedAt", statusData.PausedAt)
	container:SetAttribute("Paused", statusData.Paused)
	container:SetAttribute("SubAilment", statusData.SubAilment)
end

-- An alternative to math.clamp that emulates the behavior of the soft maximum system
local function ClampBySoftMax(value: number, add: number, min: number, max: number): number
	local maxInEffect = max ~= 0 -- If the maximum is 0 for status effects, then that means that there is no limit (the maximum is "disabled").
	
	if value >= max and maxInEffect then
		-- The base value before anything is added to it is already greater than the maximum
		-- Let it stay as it is and don't do anything to it. This is what "soft maximum" means
		-- Namely, do NOT reduce it to the maximum!
		return value
	end

	local result = value + add
	if result <= min then
		-- The result value is less than the minimum, so raise it up to match the minimum.
		return min
	end
	if maxInEffect and result >= max then
		-- If the maximum applies in the first place, and the result is larger than the maximum, then clamp it to the maximum.
		return max
	end
	return result
end

-- A method of inflicting a status effect on a character. The numbers and operations put on them apply in the given order:
-- 
-- name is the name of the effect either as a standalone name (StatusEffectRegistry.Effects) or a joined name
-- (StatusEffectRegistry.EffectsWithSub). If a joined name is input, it will override the current subailment if the
-- effect is already live. Inputting a standalone name will not tamper with the subailment in any capacity.
-- 
-- explicitlyNoSubAilment forces that the subailment is removed if the effect is already live.
--
-- skipResistanceModification will prevent the system from reducing the input level and duration by the creature's resistances.
-- ^ NOTE: You will want to set this to true if you are subtracting from the effect with this method. If you don't, the creature's
--		 	resistances will actually apply to the reduction too, so the reduction will be stunted.
--
-- addDontSet will cause the system to add the given level/duration onto an existing effect, if applicable.
-- 			-> Generally speaking, this is only useful when reducing the effect or increasing it by some delta value.
-- This has some strict behavioral limits
-- 1)	If the effect already exists as a duration-based effect, and the result duration after adding is <= 0:
--			-> The effect is terminated regardless of level.
--
-- 2)	If the effect already exists as a level-based effect (has no duration), and...
-- 2a)		...the resulting *duration* after adding is greater than 0:
--				->  The effect will transform into a duration-based effect, and the level change
--					will be applied (even if it makes the level 0, because duration effects don't care about levels).
--					If the result level is less than 0, it will be clamped to 0.
--
-- 2b)		...the resulting level is less than or equal to 0:
--				->	The effect will be terminated.
--
-- 3)	If the effect does not already exist:
--			=> It is created with the input values.
--
-- The limit values apply as per status effect data on creatures, with a slight difference:
-- 1)	Single-number values (not NumberRange) serve as the equivalent of a NumberRange where min is 0 and max is the input value.
-- 2)	NumberRanges serve the purpose of ensuring the effect's (level/duration) *is at least equal* to min, but *not added to or set
--		if it is already greater than* max (this preserves higher level effects).
-- 3)	The behavior of setting min or max to 0 to disable the corresponding limit still applies.
-- The behavior of these applications do not change based on add/set. It works the same both ways.
--
-- skipGameLimits will allow level and duration to be greater than the global maximums (e.g. effects with levels higher than 30.)
--
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:InflictStatusEffect(name: string, level: number, duration: number, addDontSet: boolean?, levelLimit: (number | NumberRange | Vector2)?, durationLimit: (number | NumberRange | Vector2)?, explicitlyNoSubAilment: boolean?, skipResistanceModification: boolean?, skipGameLimits: boolean?)
	AssertIsServer()
	local self: CharacterInfo = self::any

	local orgJoinedAilment = name
	local name, withSubAilment = SplitSubAilment(name, explicitlyNoSubAilment)
	local existing: NamedStatusEffect? = self:GetStatusEffect(name) -- This does the erroring part too.

	if not existing and level <= 0 and duration <= 0 and addDontSet then
		-- Shortcut: Trying to reduce the level of the effect if this is happening
		-- In this case, we can't, the effect isn't live. Abort early.
		return
	end
	
	local subAilment: string;
	local existingSubAilment = if existing then existing.SubAilment else string.Empty;
	if withSubAilment == nil then
		subAilment = existingSubAilment;
	else
		subAilment = withSubAilment;
	end

	if not skipResistanceModification then
		local levelMul, durationMul = self:GetRawStatusEffectSubtractionFactor(orgJoinedAilment)
		if level then
			level -= level * levelMul
		end
		duration -= duration * durationMul

		level = math.max(level, 0)
		duration = math.max(duration, 0)
	end

	local resultLevel = if existing then existing.Level else 0;
	local resultDuration = if existing then existing.Duration else 0;

	if addDontSet then
		resultLevel += level;
		resultDuration += duration;

		resultLevel = math.max(resultLevel, 0)
		resultDuration = math.max(resultDuration, 0)
	end

	local terminate;
	if existing then
		terminate = if existing.UsesDuration then resultDuration == 0 else resultLevel == 0;
	else
		terminate = resultLevel == 0 and resultDuration == 0
	end

	if terminate then
		ZeroStatus(self, name)
		local isPersistent = StatusEffectRegistry.GetStatusEffectInfo(name).Persistent -- This works due to KV similarity mandate
		if isPersistent then
			(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"PersistentStatusEffects", name}, nil, true)
		end
		return
	end

	local minLevel = 0
	local maxLevel = math.huge
	local minTime = 0
	local maxTime = math.huge
	if typeof(levelLimit) == "number" then
		maxLevel = levelLimit
	elseif typeof(levelLimit) == "NumberRange" then
		minLevel = levelLimit.Min
		maxLevel = levelLimit.Max
	elseif typeof(levelLimit) == "Vector2" then
		minLevel = levelLimit.X
		maxLevel = levelLimit.Y
	end

	if typeof(durationLimit) == "number" then
		maxTime = durationLimit
	elseif typeof(durationLimit) == "NumberRange" then
		minTime = durationLimit.Min
		maxTime = durationLimit.Max
	elseif typeof(durationLimit) == "Vector2" then
		minTime = durationLimit.X
		maxTime = durationLimit.Y
	end
	if existing then
		-- Effect is already applying to this person. Use that as the current value
		resultLevel = ClampBySoftMax(existing.Level, level, minLevel, maxLevel)
		resultDuration = ClampBySoftMax(existing.Duration, duration, minTime, maxTime)
	else
		-- Effect is being added for the first time.
		resultLevel = math.clamp(resultLevel, minLevel, maxLevel)
		resultDuration = math.clamp(resultLevel, minTime, maxTime)
	end

	-- It's important that limits are down here. The limit is concerned only about "Is the current level they have now less than limit"
	-- Incoming values mean absolutely nothing in this context. Output is what counts.
	if not skipGameLimits then
		resultLevel = math.min(resultLevel, SonariaSettings.Get(SonariaConstants.Settings.MaximumStatusEffectLevel))
		resultDuration = math.min(resultDuration, SonariaSettings.Get(SonariaConstants.Settings.MaximumStatusEffectDuration))
	end

	local newEffect = {
		UsesDuration = resultDuration > 0,
		Level = resultLevel,
		StartedAt = tick(),
		Duration = resultDuration,
		Paused = false,
		PausedAt = 0,
		SubAilment = subAilment
	}

	if not existing then
		local namedEffect: NamedStatusEffect = table.shallowCopy(newEffect)::any
		namedEffect.Name = name
		if not _OnStatusEffectAddedRoutine(self, namedEffect) then return end
	end
	
	InternalInflictStatus(self, name, newEffect)

	local isPersistent = StatusEffectRegistry.GetStatusEffectInfo(name).Persistent
	if isPersistent then
		(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"PersistentStatusEffects", name}, newEffect, true)
	end
end

-- An alias method to reduce a status effect's duration or level. This is identical to passing in negative level/duration, setting addDontSet=true, and setting ignoreResistances=true. For compliance's sake, this will not accept negative values.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:ReduceStatusEffect(name: string, levelReduction: number, durationReduction: number, levelLimit: (number | NumberRange | Vector2)?, durationLimit: (number | NumberRange | Vector2)?, explicitlyNoSubAilment: boolean?)
	local self: CharacterInfo = self::any
	assert(levelReduction >= 0, "Cannot call ReduceStatusEffect with negative values! Call InflictStatusEffect instead.")
	assert(durationReduction >= 0, "Cannot call ReduceStatusEffect with negative values! Call InflictStatusEffect instead.")
	self:InflictStatusEffect(name, -levelReduction, -durationReduction, true, levelLimit, durationLimit, explicitlyNoSubAilment, true)
end

-- Provides a means of swapping out a status effect's subailment extremely quickly without re-evaluating the whole effect.
-- Unlike typical subailment behavior, an input value of nil will behave identically to an empty string, that is, it will REMOVE it rather than preserve it.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:SwapSubAilment(name: string, sub: string?)
	AssertIsServer()
	local self: CharacterInfo = self::any
	local container = GetStatusEffectContainer(self, name)
	
	-- Trilean, TRUE/FALSE/NEUTRAL are valid.
	if StatusIsValidInstance(container) == TRUE then
		container:SetAttribute("SubAilment", sub or string.Empty)
	end
end

-- Attempts to pause the given status effect. 
-- If the effect does not apply at this time, is not duration-based, or is already paused, then this function does nothing.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:PauseStatusEffect(name: string): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	-- It's possible to really optimize this function by doing a direct modification.
	-- This abuses the fact that pause values (among a couple other values) are nonimportant to what determines a zero'd effect.
	-- Simply put, these attributes can be modified, and if the effect is zero'd, it'll still be considered zero'd even with these
	-- set to nonzero values. Same idea applies in Resume
	local container = GetStatusEffectContainer(self, name)

	if container:GetAttribute("Paused") then return end
	container:SetAttribute("Paused", true)
	local pausedAt = tick()
	container:SetAttribute("PausedAt", pausedAt)

	local isPersistent = StatusEffectRegistry.GetStatusEffectInfo(name).Persistent
	if isPersistent then
		local existing = self:GetSlot().PersistentStatusEffects[name]
		if existing then
			(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"PersistentStatusEffects", name, "Paused"}, true, true);
			(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"PersistentStatusEffects", name, "PausedAt"}, pausedAt, true);
		end
	end
end

-- Attempts to resume the given status effect. 
-- If the effect does not apply at this time, is not duration-based, or is already live, then this function does nothing.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:ResumeStatusEffect(name: string): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local container = GetStatusEffectContainer(self, name)
	if not container:GetAttribute("Paused") then return end
	local spentTime: number = container:GetAttribute("PausedAt") - container:GetAttribute("StartedAt")
	local startedAt = tick() - spentTime
	container:SetAttribute("StartedAt", startedAt)
	container:SetAttribute("Paused", false)

	local isPersistent = StatusEffectRegistry.GetStatusEffectInfo(name).Persistent
	if isPersistent then
		local existing = self:GetSlot().PersistentStatusEffects[name]
		if existing then
			-- If it doesn't exist, chances are pause was called on an effect that doesn't exist.
			(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"PersistentStatusEffects", name, "Paused"}, false, true);
			(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"PersistentStatusEffects", name, "StartedAt"}, startedAt, true);
		end
	end
end

-- Removes the given status effect by setting all values to their defaults (0/false).
-- Raises an exception if the effect is not registered.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:CureStatusEffect(name: string): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	ZeroStatus(self, name)

	local isPersistent = StatusEffectRegistry.GetStatusEffectInfo(name).Persistent
	if isPersistent then
		(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"PersistentStatusEffects", name}, nil, true)
	end
end

-- Removes all status effects. Optionally only removes effects of a given type (SonariaConstants.StatusEffectAlignment)
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:CureAllStatusEffects(effectClass: number?): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local allEffectInstances = GetOrCreateEffectInstanceCache(self).Array
	if effectClass then
		for i = 1, #allEffectInstances do
			local ctr = allEffectInstances[i]
			local data = StatusEffectRegistry.GetStatusEffectInfo(ctr.Name)
			if bit32.btest(data.Type, effectClass) then
				
				-- Trilean, TRUE/FALSE/NEUTRAL are valid.
				if StatusIsValidInstance(ctr) ~= TRUE then continue end
				if data.Persistent then
					(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"PersistentStatusEffects", ctr.Name}, nil, true)
				end
				ZeroStatus(self, ctr)
			end
		end
	else
		for i = 1, #allEffectInstances do
			local ctr = allEffectInstances[i]
			
			-- Trilean, TRUE/FALSE/NEUTRAL are valid.
			if StatusIsValidInstance(ctr) ~= TRUE then continue end
			if StatusEffectRegistry.GetStatusEffectInfo(ctr.Name).Persistent then
				(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"PersistentStatusEffects", ctr.Name}, nil, true)
			end
			ZeroStatus(self, ctr)
		end
	end
end

-- Inflicts a status effect constructed from an offensive status effect information packet.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
local function InflictStatusEffectFromOffensive(onCreature: CharacterInfo, name: string, data: CreatureOffensiveAilmentStats, ignoreResistances: boolean?)
	AssertIsServer()

	local shouldStack = true
	local name, sub = SplitSubAilment(name, false)
	local existing: NamedStatusEffect? = onCreature:GetStatusEffect(name)

	local appliedSubEffect: string? = nil
	local existingSubEffect: string? = if existing then existing.SubAilment else nil::any
	if data.AlwaysOverrideSubAilment then
		if string.isNilOrEmpty(sub) then
			appliedSubEffect = string.Empty;
		else
			appliedSubEffect = sub;
		end
	else
		if string.isNilOrEmpty(sub) then
			-- nil or empty when always override is false basically means do nothing
			appliedSubEffect = nil
		else
			-- But if the sub effect to apply does exist, then it can only be set if the current is not defined
			if string.isNilOrEmpty(existingSubEffect) then
				appliedSubEffect = sub
			else
				appliedSubEffect = existingSubEffect
			end
		end
	end

	if not data.AllowStacking then
		if existing and existingSubEffect ~= appliedSubEffect then
			-- In this case, only the subailment of the existing effect should be swapped, but no numbers changed or anything like that.
			onCreature:SwapSubAilment(name, appliedSubEffect)
		end
		return
	end


	onCreature:InflictStatusEffect(
		JoinSubAilment(name, appliedSubEffect),
		data.Level,
		data.Duration,
		true, -- This would normally be data.AllowStacking, but the block above returns if its false, so it will always be true here anyway
		data.StackLevelLimits,
		data.StackDurationLimits,
		nil,
		ignoreResistances
	)
end

-- Inflicts a status effect constructed from a defensive ailment information packet.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
local function InflictStatusEffectFromDefensive(onCreature: CharacterInfo, name: string, data: CreatureDefensiveAilmentStats, ignoreResistances: boolean?)
	-- Currently, the behavior if this method is identical to offensive effects.
	-- While defensive ailments do have more data, all of this data is checked beforehand, leaving only the common data between
	-- defensive and offensive effects behind.
	-- Very convenient!
	InflictStatusEffectFromOffensive(onCreature, name, data :: any, ignoreResistances)
end

-- Inflicts a status effect from the given Area of Effect source at the given range.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
local function InflictStatusEffectFromAoE(onCreature: CharacterInfo, name: string, range: number, data: CreatureAreaAilmentStats)
	AssertIsServer()

end


------------------------------------------------------------------
----------------------- COMBAT AND VITALITY ----------------------
------------------------------------------------------------------

-- Given the weight of the attacker, the weight of the victim, and a damage value, this returns the value scaled
-- based on the weight difference between the two.
local function ScaleDamageByWeight(attackerWeight: number, victimWeight: number, amount: number)
	local weightFactor = math.clamp(attackerWeight / victimWeight, 0, 3)
	return math.lerp(amount * weightFactor, amount, 0.5)
end

-- Returns a new melee damage source using this creature's damage output scaled to the given victim. The victim can be nil to return unscaled damage.
function CharacterStats:NewMeleeDamageOrHealthSource(victim: CharacterInfo?): AbstractSource
	local self: CharacterInfo = self::any
	if not victim then
		return DamageSource.newPvPDamage(self:GetMaxDamage(), false, self, SonariaConstants.PlayerDamageType.Melee, nil, false, false)
	end
	local victim = victim :: CharacterInfo

	local amount = self:GetMaxDamage()
	if amount <= 0 then 
		return HealingSource.newPlayerHealth(math.abs(amount), false, self, SonariaConstants.PlayerDamageType.Melee, nil) 
	end

	if APPLY_WEIGHT_BEFORE_STATUS then
		amount = self:ModifyDamageValue(ScaleDamageByWeight(self:GetWeight(), victim:GetWeight(), amount))
	else
		amount = self:ModifyDamageValue(amount) -- No weight here, theres more status effects to apply first.
	end

	if PackMarshaller.DoPlayersSharePack(self.Player, victim.Player) then
		amount *= SonariaSettings.Get(SonariaConstants.Settings.PackMemberPVPDamageMultiplier)
		if amount <= 0 then 
			return DamageSource.newPvPDamage(amount, false, self, SonariaConstants.PlayerDamageType.Melee, nil, true) 
		end
	end

	if self:HasStatusEffect(StatusEffectRegistry.Effects.Berserk) then
		local curse = victim:GetStatusEffect(StatusEffectRegistry.Effects.WispsCurse)
		if curse then
			local boost = math.clamp(curse.Level, 1, 10) * 0.05
			amount *= 1 + boost
		end
	end

	if not APPLY_WEIGHT_BEFORE_STATUS then
		-- If this is false, apply weight now, as all status effects are complete.
		amount = ScaleDamageByWeight(self:GetWeight(), victim:GetWeight(), amount)
	end

	-- n.b. pet boost can safely be here regardless, as people expect this to apply visually.
	-- That is, if they see 100 damage normally, menu and add a 2.5% damage boost, and respawn, they expect to see 102.5 damage.
	-- Putting this last allows for this to occur. Otherwise people will probably report it as a bug that it is not applying the right value.
	local amount = self:ApplyPetMod(SonariaConstants.PetModifiedStats.Damage, amount)

	return DamageSource.newPvPDamage(amount, false, self, SonariaConstants.PlayerDamageType.Melee, nil, true) 
end

-- Returns a new breath damage source using this creature's breath. The return value is unscaled and must be scaled by the caller.
function CharacterStats:NewBreathDamageSource(): DamageSource
	local self: CharacterInfo = self::any
	return BreathRegistry.CreateUnscaledDamageSourceForBreath(self, self:GetBreathType())
end

-- Returns a new ability damage source using this creature's damage output. The return value is unscaled and must be scaled by the caller.
function CharacterStats:NewAbilityDamageSource(): DamageSource
	local self: CharacterInfo = self::any
	error("This function has not yet been implemented.")
end

-- Returns the damage boost percentage applied by Warden's Rage, assuming this creature has the effect.
function CharacterStats:GetWardensRageDamageBonus(): number
	local self: CharacterInfo = self::any
	local invHealthPercent = 1 - self:GetHealthPercentage()
	local halfHealthRatio = math.clamp01(invHealthPercent * 2)
	return (halfHealthRatio + 1) * 6.00
end

-- Receives an arbitrary damage value and modifies it based on the status effects of this character.
function CharacterStats:ModifyDamageValue(damage: number): number
	local self: CharacterInfo = self::any
	if damage < 0 then
		return damage -- Healers instantly return 
		-- TODO: Should status effects reduce the amount healed on melee?
	end

	if self:HasStatusEffect(StatusEffectRegistry.Effects.WardensRage) then
		return damage * self:GetWardensRageDamageBonus()
	end

	if self:HasStatusEffect(StatusEffectRegistry.Effects.Guilty) then
		damage *= 0.50
	end
	if self:HasStatusEffect(StatusEffectRegistry.EffectsWithSub.Hungry_Starving) then
		damage *= 0.88
	end
	if self:HasStatusEffect(StatusEffectRegistry.Effects.Fear) then
		damage *= 0.50
	end
	if self:HasStatusEffect(StatusEffectRegistry.Effects.Earthquake) then
		damage *= 0.50
	end
	if self:HasStatusEffect(StatusEffectRegistry.Effects.HellionFearBuff) then
		damage *= 2.00
	end

	return damage
end


------------------------------------------------------------------
---------------------- COMBAT STATE AND UTILS --------------------
------------------------------------------------------------------

-- Removes all in-combat data from self against the given target.
-- IMPORTANT: This does NOT set the data for the other person! Only the self param!
local function ClearCombatInfo(self: CharacterInfo, target: CharacterInfo | number): ()
	local cInfo = self.DataContainerObject.Runtime.CombatInfo
	local id = if typeof(target) == "number" then target else target.Player.UserId
	cInfo:SetAttribute("AttackedFirst_" .. id, nil)
	cInfo:SetAttribute("CombatEndsAt_" .. id, nil)
	cInfo:SetAttribute("TargetGUID_" .. id, nil)
end

-- Returns the combat info in the eyes of self about the given target. The combat info is described with a trilean value
-- for the attack direction (nil means not in combat, false means target attacked self first, true means self attacked target first)
-- as well as the tick() that the combat tag expires/expired on (will be 0 if no combat data was registered.)
-- If the GUID of the current target is not equal to the stored value, then it will act like combat ended.
-- If the skipDisposalOfInvalidData parameter is false, and if the GUID is mismatched or the timer has run out, ClearCombatInfo is called.
local function GetCombatInfo(self: CharacterInfo, target: CharacterInfo, skipDisposalOfInvalidData: boolean?): (boolean?, number)
	local cInfo = self.DataContainerObject.Runtime.CombatInfo
	local id = target.Player.UserId
	local attackedFirst: boolean? = cInfo:GetAttribute("IStartedAttackOn_" .. id)
	if attackedFirst == nil then
		return nil, 0
	end

	local endsAt: number = cInfo:GetAttribute("CombatEndsAt_" .. id) or 0
	local guid: string = cInfo:GetAttribute("TargetGUID_" .. id) or string.Empty
	local now = tick()
	if now >= endsAt then
		if skipDisposalOfInvalidData then
			attackedFirst = nil
		else
			ClearCombatInfo(self, target)
			ClearCombatInfo(target, self)
			return nil, 0
		end
	end
	if guid ~= target.CurrentCharacterGUID then
		if skipDisposalOfInvalidData then
			attackedFirst = nil
		else
			ClearCombatInfo(self, target)
			ClearCombatInfo(target, self)
			return nil, 0
		end
	end

	return attackedFirst, endsAt
end

-- Sets the combat information on the given character controller, namely whether or not self attacked the other target first,
-- and how long the combat tag against them is expected to last.
-- IMPORTANT: This does NOT set the data for the other person! Only the self param!
local function SetCombatInfo(self: CharacterInfo, target: CharacterInfo, selfAttackedFirst: boolean, duration: number)
	local endsAt = tick() + duration
	local cInfo = self.DataContainerObject.Runtime.CombatInfo
	local id = target.Player.UserId
	cInfo:SetAttribute("IStartedAttackOn_" .. id, selfAttackedFirst)
	cInfo:SetAttribute("CombatEndsAt_" .. id, endsAt)
	cInfo:SetAttribute("TargetGUID_" .. id, target.CurrentCharacterGUID)
end

-- Returns true if both self and other have eachother registered in combat.
-- This function assumes both players are present.
local function IsInMutualCombat(self: CharacterInfo, other: CharacterInfo): boolean
	local selfInCombat = GetCombatInfo(self, other)
	local otherInCombat = GetCombatInfo(other, self)
	return selfInCombat == true and otherInCombat == true
end

-- Causes this player to enter combat with the other player for the given amount of time.
-- This registers the data for both players. The player that this is called on is classified as the attacker.
-- The default duration is 30 seconds, however if defined, the duration can be overridden.
-- If the input override time is less than or equal to 0, this calls ExitCombat for both self and other.
-- Returns whether or not this character is responsible for the initial attack against the target.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:EngageInCombatWith(who: CharacterInfo, overrideDuration: number?): boolean
	AssertIsServer()
	local self: CharacterInfo = self::any
	local duration = overrideDuration or 30
	if duration <= 0 then
		ClearCombatInfo(self, who)
		ClearCombatInfo(who, self)
		return false
	end
	local alreadyInCombat = IsInMutualCombat(self, who)
	SetCombatInfo(self, who, true, duration)
	SetCombatInfo(who, self, false, duration)
	return not alreadyInCombat
end

-- Causes this player to immediately leave combat with everyone. 
-- NOTE: This is expensive to call as it searches for all other characters and
-- tells their data to dispose of this controller as a combatant if it is registered.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
-- !!! warn "Expensive Method"
--     This method has a high associated cost and so it should not be called in tight loops or per frame.
function CharacterStats:ExitAllCombat(): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local cInfo = self.DataContainerObject.Runtime.CombatInfo
	local attrs = cInfo:GetAttributes()
	for key, value in pairs(attrs) do
		local startsWith, otherPlayerId = string.StartsWithGetAfter(key, "TargetGUID_")
		if startsWith then
			local id = tonumber(otherPlayerId)
			local otherPlayer = Players:GetPlayerByUserId(id)
			if otherPlayer and otherPlayer.Character then
				local otherController = CharacterStats.TryGet(otherPlayer.Character, true)
				if otherController then
					ClearCombatInfo(otherController, self)
				end
			end
		end
		cInfo:SetAttribute(key, nil) -- This is identical to clearing combat info for this player.
	end
end

-- Returns whether or not the player is currently in combat with the given other player.
function CharacterStats:IsInCombatWith(withWho: CharacterInfo): boolean
	local self: CharacterInfo = self::any
	return IsInMutualCombat(self, withWho)
end

-- Returns whether or not the player is currently in combat with *anyone*.
-- This will also do a cleanup task to remove garbage data (e.g. players that left the game or returned to menu)
-- This task can be skipped by explicitly inputing a value of true for the function parameter.
-- !!! warn "Expensive Method"
--     This method has a high associated cost and so it should not be called in tight loops or per frame.
function CharacterStats:IsInAnyCombat(skipCleanup: boolean?): boolean
	local self: CharacterInfo = self::any
	local cInfo = self.DataContainerObject.Runtime.CombatInfo
	local attrs = cInfo:GetAttributes()
	local inCombat = false
	for key, value in pairs(attrs) do
		local startsWith, otherPlayerId = string.StartsWithGetAfter(key, "TargetGUID_")
		if startsWith then
			local id = tonumber(otherPlayerId)
			local otherPlayer = Players:GetPlayerByUserId(id)
			if otherPlayer and otherPlayer.Character then
				local otherController = CharacterStats.TryGet(otherPlayer.Character, true)
				if otherController then
					if IsInMutualCombat(self, otherController) then
						if skipCleanup then
							return true
						else
							inCombat = true
							continue -- next iteration here
						end
					end
				end
			end
			ClearCombatInfo(self, id::number) 
			-- If iteration was not skipped or terminated above, then that means this was lingering
			-- data that needs to be cleaned up
		end
	end
	return inCombat
end

-- Damages the Humanoid associated with this character. This does not scale the source (even if it needs to be), hence the "Absolute" in the name.
-- Returns true if the player died as a result.
local function TakeAbsoluteDamageAndLog(victim: CharacterInfo, source: DamageSource): boolean
	local humanoid = victim:GetCharacter().Humanoid
	local isKill = source.Amount >= victim:GetHealth() -- This will clamp the health down if needed.
	if isKill then
		AnalyticsLogKill(victim, source)
	end
	humanoid:TakeDamage(source.Amount)
	return isKill
end

-- Directly heals the Humanoid associated with this character. This does not scale the source (even if it needs to be), hence the "Absolute" in the name.
local function HealAbsoluteHealth(victim: CharacterInfo, source: HealingSource): ()
	local humanoid = victim:GetCharacter().Humanoid
	humanoid.Health = math.clamp(humanoid.Health + source.Amount, 0, victim:GetMaxHealth())
end

-- Internal predicate for use in table.where, returns status effects whose ApplyTo value qualifies them for use in affecting a victim
local function _PredicateGetVictimOrBothEffects(effect)
	return effect.ApplyTo == SonariaConstants.OffensiveEffectApplicationTarget.Victim or effect.ApplyTo == SonariaConstants.OffensiveEffectApplicationTarget.Both
end

-- Damages or heals this character using the given source. This will dispose of the damage source, which may be modified.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:ReceiveDamageOrHealing(source: AbstractSource)
	AssertIsServer()

	local self: CharacterInfo = self::any
	local attacker: CharacterInfo? = source:GetSourceCharacter()

	if attacker and not attacker:IsValid() then
		warnstack(tostring(self) .. " was attacked or healed by invalid Character " .. tostring(attacker))
		source:Dispose()
		return
	end

	if not source.IsAlreadyScaled and source.IsAmountPercentage then
		source:ScaleAmount(self:GetMaxHealth())
	end
	
	if source.SourceType == SonariaConstants.PlayerDamageType.Breath then
		local breathName = source.BreathTypeOrAbilityName::string
		source = BreathRegistry.InvokeModificationCallback(breathName, self, source)
		if source == nil then
			return -- Damage was canceled by the breath.
		end
	end

	if attacker then
		-- PvP
		local doStatusEffectsToVictim = true
		if source:IsIndeterminate() then
			-- n.b. check this condition FIRST
			-- indeterminate effects may have IsHealing or IsDamage set to true.

			if self:HasStatusEffect(StatusEffectRegistry.Effects.ReflectAttacks) then
				source:Dispose()
				return
				-- Indeterminate sources don't actually do anything so just disposing of it is fine
			end

			doStatusEffectsToVictim = true
		elseif source:IsHealing() then
			local source:HealingSource = source :: any
			local humanoid = self:GetCharacter().Humanoid
			--self:AddHealth(source.Amount)
			HealAbsoluteHealth(self, source)
		elseif source:IsDamage() then
			local source:DamageSource = source :: any
			if self:HasStatusEffect(StatusEffectRegistry.Effects.ReflectAttacks) then
				if source.DamageIsReflected then
					-- We don't want to reflect a reflection (at risk of an infinite loop). 
					-- Play a sound or something here, some feedback, then STOP.
					source:Dispose()
					return
				end

				-- If it is not already reflected, hit em with the no u card
				local source = source:CloneWhereReflectedBy(self, false)
				attacker:ReceiveDamageOrHealing(source)
				return
			end

			doStatusEffectsToVictim = not TakeAbsoluteDamageAndLog(self, source)

		else
			error("An unhandled health modification source was applied to " .. tostring(self))
		end
		
		
		for index, effect in pairs(source.StatusEffects) do
			local isBoth = effect.ApplyTo == SonariaConstants.OffensiveEffectApplicationTarget.Both
			local isVictim = effect.ApplyTo == SonariaConstants.OffensiveEffectApplicationTarget.Victim
			local isSrc = effect.ApplyTo == SonariaConstants.OffensiveEffectApplicationTarget.Self
			if (isBoth or isVictim) and doStatusEffectsToVictim then
				InflictStatusEffectFromOffensive(self, effect.Name, effect::any)
			end
			if isBoth or isSrc then
				InflictStatusEffectFromOffensive(attacker, effect.Name, effect::any)
			end
		end
	else
		-- PvE or scripted
		local doStatusEffectsToVictim = true
		if source:IsDamage() or source:IsIndeterminate() then
			-- n.b. check this condition FIRST
			-- indeterminate effects may have IsHealing or IsDamage set to true.
			
			local source:DamageSource = source :: any
			if self:HasStatusEffect(StatusEffectRegistry.Effects.ReflectAttacks) then
				if SonariaSettings.Get(SonariaConstants.Settings.ReflectAttacksBypassesEnvDamage) then
					source:Dispose()
					return
				end
			end

			doStatusEffectsToVictim = if source:IsIndeterminate() then true else (not TakeAbsoluteDamageAndLog(self, source))
			
		elseif source:IsHealing() then
			local source:HealingSource = source :: any
			local humanoid = self:GetCharacter().Humanoid
			HealAbsoluteHealth(self, source)
		else
			error("An unhandled damage source was given to a player.")
		end
		
		if doStatusEffectsToVictim then
			local victimEffects = table.where(source.StatusEffects, _PredicateGetVictimOrBothEffects)
			for i = 1, #victimEffects do
				local effect = victimEffects[i] :: SourceAilment
				-- Note that due to how damage works, its actually possible for more than one of the same effect to exist. They are just applied in order.
				InflictStatusEffectFromOffensive(self, effect.Name, effect::any)
			end
		end
		
		-- Can't do any effects to the source because the source is environmental.
	end

	source:Dispose() -- Get rid of the damage source, don't need it anymore, it has been used for its purpose.
end

------------------------------------------------------------------
------------------------------ MISC ------------------------------
------------------------------------------------------------------

local function PlayCallSound(self: CharacterInfo, soundType: string)
	if IS_CLIENT and SoundService.RespectFilteringEnabled then
		-- The client can't play this sound on their own, FE is enforced for sounds. They need to ask the server to do it for them.
		ReplicateCharacterInfoEvent:FireServer(
			SonariaConstants.NetworkCalls.TryPlayCallSoundAsync, 
			soundType
		);
	else
		-- Either the client can play the sound, or the server is doing it.
		-- Regardless, just quickly fact-check the data coming in.
		if typeof(soundType) ~= "string" then return end
		if not SonariaConstants.CreatureCallType[soundType] then return end
		local head: BasePart = self.Character:FindFirstChild("Head") :: any
		if not head then return end

		local soundTarget = head:FindFirstChild(soundType .. "Call") :: any
		if not soundTarget or not soundTarget:IsA("Sound") then return end

		local lastPlayedAt: number = soundTarget:GetAttribute("LastPlayedAt") or 0
		if (tick() - lastPlayedAt) < soundTarget.TimeLength * 0.7 then return end
		soundTarget:SetAttribute("LastPlayedAt", tick())
		soundTarget.PlaybackSpeed = RNG:NextNumber(0.6, 1.4)
		soundTarget:Play()
	end
end

-- Plays the sound associated with this creature's broadcast call.
function CharacterStats:PlayBroadcastCallSound()
	local self: CharacterInfo = self::any
	PlayCallSound(self, SonariaConstants.CreatureCallType.Broadcast)
end

-- Plays the sound associated with this creature's friendly call.
function CharacterStats:PlayFriendlyCallSound()
	local self: CharacterInfo = self::any
	PlayCallSound(self, SonariaConstants.CreatureCallType.Friendly)
end

-- Plays the sound associated with this creature's aggressive call.
function CharacterStats:PlayAggressiveCallSound()
	local self: CharacterInfo = self::any
	PlayCallSound(self, SonariaConstants.CreatureCallType.Aggressive)
end

-- Plays the sound associated with this creature's speech call.
function CharacterStats:PlaySpeakCallSound()
	local self: CharacterInfo = self::any
	PlayCallSound(self, SonariaConstants.CreatureCallType.Speak)
end


------------------------------------------------------------------
------------------------- CHARACTER STATE ------------------------
------------------------------------------------------------------

-- Frees this object and removes all internal references, preparing it for full removal by GC.
-- This will not delete the data folder, only detatch from it. Ensure that Destroy is called on the data folder externally!
-- Attempting to index any methods of this object after calling this will error because they are nil.
-- Note that this SHOULD be callable from both sides, because it can be used on remote clients to dispose of a character they don't
-- need a reference to anymore.
function CharacterStats:Dispose(): ()
	local self: any = self::any
	if table.isfrozen(self) then return end -- Already disposed.
	if self.Character then 
		Cache:Remove(self.Character)
		ByGUID:Remove(self.Character)
	end -- Save some work for IsValid
	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self) -- Make immutable so it *can't* be used anymore
end


-- Calls Dispose on the character, but also informs all clients in the game that the character is no longer valid.
-- This will also destroy the character model, and set the associated player's character to nil.
-- !!! warn "Server Only"
--     This method only exists for the server. Attempting to call it on the client will raise an exception.
function CharacterStats:Destroy(sendReturnToMenu: boolean?): ()
	AssertIsServer()
	local self: CharacterInfo = self::any
	local orgCharacter = self.Character
	local player = self.Player
	self:Dispose()
	local self: Void = nil
	if orgCharacter then
		ReplicateCharacterInfoEvent:FireAllClients(SonariaConstants.NetworkCalls.TellCharacterIsInvalidAsync, orgCharacter)
		orgCharacter:Destroy()
	end
	if player then
		player.Character = nil
		if sendReturnToMenu then
			ReplicateCharacterInfoEvent:FireClient(player, SonariaConstants.NetworkCalls.TellReturnToMenuAsync)
		end
	end
end

-- "Migrates" the data container here to the new character model. 
-- This is strictly for use when the player grows, and this data needs to be moved from child => teen or teen => adult
-- Or, to be more specific on the limit, the species and slot reference MUST be the same. The only change is the character ref.
-- Note that this should be called AFTER the Player's character has been set AND has been replicated (is in the world), 
-- as the client calls this at the same time that the server does.
-- This can be called with no argument to automatically read Player.Character and move to that.
-- Returns whether or not migration was successful as a boolean.
-- If it was not, a warning will be logged and you MUST create new data for this character.
-- ^ Naturally, this MUST be called *before* deleting the old character model. 
-- ^ Attempting to call this afterwards will result in a corrupt object.
-- Optionally, this method can clean up the original character model after a successful migration.
function CharacterStats:Migrate(newCharacter: Model?, disposeOfOldCharacter: boolean?): boolean
	local self: CharacterInfo = self::any
	local orgCharacter = self.Character
	local success = pcall(function ()
		local target = newCharacter or self.Player.Character
		if not target then 
			error("Nil destination for new character.")
		else
			if not orgCharacter then
				error("No pre-existing character?")
			end
			table.clear(self.ArbCache)
			Cache:Remove(orgCharacter)
			ByGUID:Remove(orgCharacter)
			self.Character = target::any
			Cache:Put(target, self)
			ByGUID:Put(target, self.CurrentCharacterGUID)
			self.DataContainerObject.Parent = target::any
			local humanoid = self.Character.Humanoid
			humanoid.HealthChanged:Connect(function (health: number)
				(self.ReplicatedPlayer::any):ChangeValueInCurrentSlot({"Health"}, health)
			end)
			humanoid.Died:Connect(function() 
				self:SetDead(true)
				self:Destroy(true)
			end)

			if IS_SERVER then
				ReplicateCharacterInfoEvent:FireClient(self:GetPlayer(), SonariaConstants.NetworkCalls.TryMigrateCharacterAsync, newCharacter)
				ReplicateCharacterInfoEvent:FireAllClients(SonariaConstants.NetworkCalls.TellCharacterIsInvalidAsync, orgCharacter)
			end

			if disposeOfOldCharacter then
				orgCharacter:Destroy()
			end
		end
	end)
	if IS_SERVER then
		if not success then
			ReplicateCharacterInfoEvent:FireAllClients(SonariaConstants.NetworkCalls.TellCharacterIsInvalidAsync, orgCharacter)
			warn("Failed to migrate character data! Offender: " .. tostring(self))
			warnstack("This has been DISPOSED to prevent usage of a corrupt object. Please discard it, and acquire a new reference with .For(). All other clients have been told that the character object is invalid.")
			self:Dispose()
		end
	else
		if not success then
			warn("Failed to migrate character data! Offender: " .. tostring(self))
			warnstack("This has been DISPOSED to prevent usage of a corrupt object. Please discard it, and acquire a new reference with .For().")
			self:Dispose()
		end
	end
	return success
end

-- Sends all changed values from the client to the server. A value's original is stored before its first non-replicated change,
-- so if the value eventually changes back to its original before this is called, it will not be replicated.
-- This can also be called from the server to the client for data correction.
function CharacterStats:Replicate(): ()
	local self: CharacterInfo = self::any
	if IS_SERVER then
		local player = self.Player
		if not player or player:GetAttribute(SonariaConstants.System.ExitingGame) then return end
		ReplicateCharacterInfoEvent:FireClient(player, SonariaConstants.NetworkCalls.SendPendingChangesAsync, self.PendingChanges)
		table.clear(self.PendingChanges)
	else
		if not self:ShouldReplicate() then
			error("Cannot replicate. Do not manually call Replicate unless replication is allowed!", 2)
		end
		ClientAwaitingChangeConfirmation = true
		ReplicateCharacterInfoEvent:FireServer(SonariaConstants.NetworkCalls.SendPendingChangesAsync, ClientPendingChanges)
		table.clear(ClientPendingChanges)
	end
end

-- Automatically checks for replication availablity and does so.
-- !!! warn "Client Only"
--     This method only exists for the client. Attempting to call it on the server will raise an exception.
function CharacterStats:SafeReplicate(): ()
	local self: CharacterInfo = self::any
	AssertIsClient()
	if not self:ShouldReplicate() then
		return
	end
	ClientAwaitingChangeConfirmation = true
	ReplicateCharacterInfoEvent:FireServer(SonariaConstants.NetworkCalls.SendPendingChangesAsync, ClientPendingChanges)
	table.clear(ClientPendingChanges)
end

-- Returns whether or not the current character stats should be replicated to the opposite side.
-- Automatically checks for replication availablity and does so.
-- !!! warn "Client Only"
--     This method only exists for the client. Attempting to call it on the server will raise an exception.
function CharacterStats:ShouldReplicate(): boolean
	AssertIsClient()
	if ClientAwaitingChangeConfirmation then return false end
	if #ClientPendingChanges == 0 then return false end
	return true
end

-- A quick function to get the method associated with changing an attribute that is part of a pending change.
-- This will still check for registry, so that developer error (forgetting to register something as editable)
-- can be mitigated.
local function GetMethodForAttribute(self: CharacterInfo, change: PendingFieldChange): string?
	-- It's in this character, good.
	-- n.b. this checks if it's the right player too, since this CharacterStats object was acquired via the invoker.
	-- So at this point, the container is in a legit place as far as the hierarchy is concerned, and it's for the right person.

	-- What about its path, is it a known replicatable object?
	local relativePath = InstanceHierarchy.GetFullNameRelativeTo(change.Object, self.DataContainerObject)
	-- Create an intersection of both full names. An example might be like so:

	-- CharacterFolderHere.Aolenus.Data
	-- CharacterFolderHere.Aolenus.Data.Runtime.State
	-- Intersection: Runtime.State

	local stats = ReplicatedStats[relativePath]
	if not stats then
		error("There is no ReplicatedStats entry for an object in this local path: " .. relativePath)
		return nil 
	end
	local retn = stats[change.Attribute]
	if not retn then
		error("There is no ReplicatedStats entry for \"" .. change.Attribute .. "\" in local path: " .. relativePath)
	end
	return retn
end

-- Intended for use on the server only, where the client may send completely bogus data.
-- Every last bit of this data MUST be checked to see if it's legit and follows the expected form.
-- Expect people to have malformed data.
-- Expect people to try to reference other objects that aren't expected, like other players' characters
-- Expect people to try to set values to whatever they want.
-- Allow none of this.
-- This returns whether or not the change is valid + safe, and if it is valid + safe, then it also returns
-- the method that needs to be called on the character controller to change it. Otherwise it returns false and nil.
local function IsPendingChangeValid(self: CharacterInfo, change: PendingFieldChange): (boolean, string?)
	local object: any = change.Object
	local attribute: any = change.Attribute
	local initValue: any = change.InitializedValue
	local newValue: any = change.NewValue

	-- All are non-nullable. If something is nil, it's invalid.
	if object == nil or attribute == nil or initValue == nil or newValue == nil then return false, nil end

	-- First, check if the initial value and current value are different. If they are equal, discard it, that's not even a change.
	-- This can be checked before types, and saves a lot of work.
	if initValue == newValue then return false, nil end
	if typeof(initValue) ~= typeof(newValue) then return false, nil end -- The real type check is done later down there.
	-- This is just a lazy one against old/new in case they tried something like that. Saves some work, but will probably not
	-- be a very popularly attempted exploit vector.

	-- Type checks for object and attribute first, those are easy
	if typeof(object) ~= "Instance" then return false, nil end 			-- If the object that holds this attribute isn't an object, throw it away.
	if not Attributes.IsNameValid(attribute) then return false, nil end -- If the attribute name isn't usable, throw it away.

	local method: string;
	local cutFullName: string;

	-----------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------
	-- NOTE: Do not call GetMethodForAttribute here, as that is rigged to cause an error
	-- with the intent that it's from server => client (and therefore we are checking for developer error
	-- (forgetting registry items) rather than malformed data). Because it's dev error, it needs a 
	-- console error so that it's *fixed*. This just needs to report that the data is malformed so that
	-- whatever is using that data purposely skips it. Very big difference.
	-----------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------
	-- Resolve the object and make sure it's in the right place (this character). Not anyone else's character!
	if object:IsDescendantOf(self.DataContainerObject) then
		-- It's in this character, good.
		-- n.b. this checks if it's the right player too, since this CharacterStats object was acquired via the invoker.
		-- So at this point, the container is in a legit place as far as the hierarchy is concerned, and it's for the right person.

		-- What about its path, is it a known replicatable object?
		local relativePath = InstanceHierarchy.GetFullNameRelativeTo(object, self.DataContainerObject)
		-- Create an intersection of both full names. An example might be like so:

		-- CharacterFolderHere.Aolenus.Data
		-- CharacterFolderHere.Aolenus.Data.Runtime.State
		-- Intersection: Runtime.State

		cutFullName = relativePath
		local stats = ReplicatedStats[relativePath]
		if not stats then return false, nil end -- The object isn't registered as something in the stats that can be replicated. Discard.
		method = stats[attribute]
		if not method then return false, nil end -- Attribute isn't editable or is not bound to a method (dev error). Discard.
		-- n.b. method existence is checked on module init, if there's no error for a missing method in that init loop, then it definitely exists.
	else
		return false, nil -- Not our own object, discard.
	end

	-- At this point, the object and attribute are *definitely* correct, with the exception of the value itself
	-- The only remaining abusable data is the initial value and new value.

	-- Now check the types of both init *and* new against the type of the attribute.
	local currentSidedValue = object:GetAttribute(attribute)
	local attrType = typeof(currentSidedValue)
	if attrType ~= typeof(initValue) or attrType ~= typeof(newValue) then return false, nil end -- Someone swapped out the types. No good.

	-- Now what about the actual content of the values?
	if currentSidedValue == newValue then
		-- The opposite side sent the current value that we already have as their supposed "new value". 
		-- Throw this one out, because changing it is literally worse than useless.
		-- This doubles as a performance boost, because we don't need to tell the client to change it to that: they already did.
		-- * or, they are *reporting* they did. Who knows, maybe they set it to something else and then swapped out the data.
		-- The moral of the story: Send the replacement data anyway lol
		return false, nil
	end

	if currentSidedValue ~= initValue then
		-- This case means there was some sort of desynchronization. The value they are changing *from* is different than the value
		-- that this side believes is changing from. This should ideally be the same.
		-- Example:
		-- Client wants to change a value from 5 to 6
		-- Server thinks the value is 4, not 5, so it would change from 4 to 6

		-- TODO: Can I handle network lag such that this case is impossible?
		-- If I send a ticket back to the client that basically says "The changes are done", and prevent the client from sending anything more
		-- until it receives that, then that *should* do it.
		warn(string.csFormat(
			"Desynchronization detected: Initial values are not identical! The client wanted to change {0}[{1}] from {2} to {3}, but the server believes the change is going to be from {4} to {3}.",
			cutFullName,
			attribute,
			initValue,
			newValue,
			currentSidedValue
		));

		-- For now, treat it as legit, what matters is the value is being updated to the same end goal.
	end

	return true, method
end

-- Called on both sides when the opposite side sends in data that needs to update this creature instance.
function CharacterStats:FilterAndParseReplicationData(replicationData: {PendingFieldChange}): ()
	-- Reply Pending Changes are server only.
	-- This set should mimic the proper data in the eyes of the server. The client will receive this
	-- and not only validate their own data, but also use it to know that it's safe to send again,
	-- as well as what changes they registered locally that were just a result of the server updating.
	-- If the client locks until it receives the OK, then desyncs automatically level out.

	-- Scenario: I tap the sprint key really fast and turn it on and immediately back off.
	-- By the time I've let go of the button, the server tells me that it received my request to turn it on and has done so.
	-- My client will already have had it off, but when the server got it, the server will have actually turned it back on.
	-- The thing is, the client was yielding to send the off request, so it'll send the off request to the server afterwards.

	for index = 1, #replicationData do
		local change = replicationData[index]
		if IS_SERVER then
			if typeof(change) ~= "table" then continue end -- Skip if the client tried to send crap that wasn't a table.
			local isValid: boolean, method: string? = IsPendingChangeValid(self, change)
			if isValid and method then
				-- Now rather than changing the attribute, call the method. A good chunk of methods have validators in them that will do
				-- further cleanup on the value.
				CharacterStats[method](self, change.NewValue)
				-- Everyone who made Luau is now rolling in their graves. Or will be.
				-- None of them are dead (I hope)
			end
		else
			-- The client should trust what the server sends, so we don't need to waste time verifying something that is
			-- handmade by a developer.
			local method = GetMethodForAttribute(self, change)
			if method then
				CharacterStats[method](self, change.NewValue)
			else
				error("No method associated with changing attribute \"" .. change.Attribute .. "\" on " .. change.Object:GetFullName())
			end
		end
	end

	if IS_CLIENT then
		self.AwaitingChangeConfirmation = false -- Reset this now.
	else
		-- On the server, all of those changes will have been registered.
		-- Fire the client, which they use to update the values (see the loop just above) and then reset
		-- the awaiting status (see literally right above)
		self:Replicate()
	end
end

type CapsuleCollider = Model & {
	PrimaryPart: BasePart & {
		CreatureVelocity: LinearVelocity;
		CreatureRotation: AlignOrientation;
		KeepUpright: AlignOrientation;
		
		KeepUprightAttachment: Attachment;
		YawControllerAttachment: Attachment;
		VelocityControllerAttachment: Attachment;
	},
}

function CharacterStats:GetCapsuleCollider(): CapsuleCollider
	local self: CharacterInfo = self::any;
	return (self.Character::any).CapsuleCollider;
end

-- Returns a reference to the LinearVelocity that controls this character's motion.
function CharacterStats:GetVelocityController(): LinearVelocity
	local self: CharacterInfo = self::any;
	local capsule = self:GetCapsuleCollider();
	local obj = capsule.PrimaryPart.CreatureVelocity;
	return obj
end

-- Returns a reference to the AlignOrientation that dictates this character's rotation about the Y axis.
function CharacterStats:GetRotationController(): AlignOrientation
	local self: CharacterInfo = self::any
	local capsule = self:GetCapsuleCollider();
	local obj = capsule.PrimaryPart.CreatureRotation;
	return obj
end

-- TODO: Make obsolete.
function CharacterStats:UpdatePhysics()
	local self: CharacterInfo = self::any
	local capsule = self:GetCapsuleCollider();
	local vel = capsule.PrimaryPart.CreatureVelocity;
	vel.Attachment0 = capsule.PrimaryPart.VelocityControllerAttachment;
	
end

-- A utility method that listens to a container's elements being modified, as well as elements being added or removed.
-- When these actions are detected, the container's cached values are cleared, requiring systems to repopulate them.
-- This can only occur under scenarios where some external change has occurred, likely from developer tampering during runtime.
-- Yeah I did this again wyd
local function ListenForRuntimeTestChanges(self: CharacterInfo, container: Instance, cacheKey: string)
	local cache: {[any]: any} = self.ArbCache
	container.ChildAdded:Connect(function (obj)
		cache[cacheKey] = nil
		obj.AttributeChanged:Connect(function ()
			cache[cacheKey] = nil
		end)
	end)
	container.ChildRemoved:Connect(function ()
		cache[cacheKey] = nil
	end)

	for index, object in pairs(container:GetChildren()) do
		object.AttributeChanged:Connect(function ()
			cache[cacheKey] = nil
		end)
	end
end

-- Creates a new or cached instance of character stats for the given player's character 
-- Requires a reference to the player, the slot object that the character exists from, and the character itself.
-- Clients can use this method to access information about someone else.
-- To spawn a new character for the given player, use the server-only method SpawnNewCharacter
function CharacterStats.For(player: Player, slot: Slot, character: Model): CharacterInfo
	local cached = Cache:Get(character)
	if cached then
		if cached:IsValid() then
			return cached
		else
			cached:Dispose()
			Cache:Remove(character)
			ByGUID:Remove(character)
		end
	end
	local baseInfo = SpeciesInfoProvider.For(character.Name) :: Species;
	
	
	local specsClone;
	local createdNewSpecs = false;
	if RunService:IsClient() then
		specsClone = character:FindFirstChild("Data")
	else
		local theseSpecifications = table.deepishCopy(Specifications)
		table.mergeValuesIntoTemplate(baseInfo.RawData.Specifications, theseSpecifications, true)
		specsClone = TableToAttributes.Convert(theseSpecifications)
		specsClone.Name = "Data"
		createdNewSpecs = true
	end
	
	local cinfo: any = {
		Player = player,
		Character = character,
		OccupiedSlot = slot,
		BaseInfo = baseInfo,
		DataContainerObject = specsClone,
		PendingChanges = {},
		ArbCache = {},
		AwaitingChangeConfirmation = false,
		ReplicatedPlayer = PlayerReplicator.For(player), -- n.b. data arg not needed here because the server will create it before calling
		-- the .For method here (so it can grab it out of cache here). The client uses neither the player argument nor the data argument, so
		-- that works too.
		CurrentCharacterGUID = GUID.new()
	}

	local out_ObjectAndAttrs = {}
	for key, attributes in pairs(ReplicatedStats) do
		local attributeContainer = InstanceHierarchy.NavigatePath(cinfo.DataContainerObject, string.split(key, "."), true)
		for attrName in pairs(attributes) do
			table.insert(out_ObjectAndAttrs, {attributeContainer::any, attrName})
		end
	end
	LateInitStatusEffects()
	cinfo.DataContainerObject.Name = "Data"
	cinfo.DataContainerObject.Parent = character::any

	if IS_SERVER or (IS_CLIENT and player == Players.LocalPlayer) then
		-- Client needs to store the attributes for replication, but only if the person in question is themselves.
		-- Server stores it for everyone, uses it for replying to changes.
		for index = 1, #out_ObjectAndAttrs do
			local object: Instance, attrName: string = unpack(out_ObjectAndAttrs[index]::any);
			local connection: RBXScriptConnection;
			local oldValue = object:GetAttribute(attrName)
			connection = object:GetAttributeChangedSignal(attrName):Connect(function ()
				-- Yes, this will fire when the server changes it too.
				-- The server will send a comprehensive list of all changes it made, so when that's received, we can filter
				-- out the changes that will be registered by this callback.

				-- It's probably worth it to note that Changed won't fire if the value didn't, you know, change.
				-- So if I send a desired value to the server and it sets it to that desired value, then this does nothing
				-- on the client because my value is already what I want. The server does see a change though, which it uses
				-- to send the confirmation ticket to the client.

				if table.isfrozen(cinfo) then
					-- Object disposed. Disconnect the listener for this attribute changing, and abort the function.
					connection:Disconnect()
					return
				end

				if cinfo.AwaitingChangeConfirmation then
					-- This is probably just the server updating it. If this actually gets caught, it means there was a
					-- desync between the client and server. In this case, the server is the all-seeing-eye and dominant force
					-- So just use what the server gives.
					return
				end

				-- When the attribute is changed, it needs to go into pending changes.
				local pChangesArray: {PendingFieldChange} = if IS_CLIENT then ClientPendingChanges else cinfo.PendingChanges
				local existingChange: PendingFieldChange? = table.first(pChangesArray::{PendingFieldChange}, function (change: PendingFieldChange)
					if change.Object == object and change.Attribute == attrName then
						return true
					end
					return false
				end)
				local current = object:GetAttribute(attrName)
				if existingChange then
					existingChange.NewValue = current
				else
					local existingChange = {
						Object = object,
						Attribute = attrName,
						InitializedValue = oldValue,
						NewValue = current
					}
					table.insert(pChangesArray, existingChange)
				end
				oldValue = current
			end)
		end
	end

	setmetatable(cinfo, CharacterStats)
	
	local allFX = slot.PersistentStatusEffects
	for effectName: string, fx: StatusEffect in pairs(allFX) do
		local name = effectName
		if fx.SubAilment then
			name = name .. "$" .. fx.SubAilment
		end
		(cinfo::CharacterInfo):InflictStatusEffect(name, fx.Level, fx.Duration, false, nil, nil, nil, true, true)
		if (fx.Paused) then
			(cinfo::CharacterInfo):Pause(effectName)
		end
	end

	local head: BasePart? = character:FindFirstChild("Head") :: any
	if head then
		if createdNewSpecs then
			-- New specs not created means this is the client making a character, do not need to make the new sounds, server already did. 
			cinfo.BaseInfo:NewBroadcastSoundInstance().Parent = head
			cinfo.BaseInfo:NewFriendlySoundInstance().Parent = head
			cinfo.BaseInfo:NewAggressiveSoundInstance().Parent = head
			cinfo.BaseInfo:NewSpeakSoundInstance().Parent = head
		end
	else
		AnalyticsErrorFromInstance(
			cinfo, SonariaConstants.Analytics.Exceptions.MalformedDataException, 
			"Character " .. tostring(character) .. " (" .. character:GetFullName() .. ", " .. player.Name .. ") was missing its head when attempting to create the call sounds. Either the model was not made properly, a severe desynchronization occurred (if this is on the client), or something deleted it."
		)
	end

	Cache:Put(character, cinfo)
	ByGUID:Put(character, cinfo.CurrentCharacterGUID)

	ListenForRuntimeTestChanges(cinfo, cinfo.DataContainerObject.MainInfo.Stats.MeleeAilments, SonariaConstants.QuickCacheKeys.OffensiveAilments)
	ListenForRuntimeTestChanges(cinfo, cinfo.DataContainerObject.MainInfo.Stats.DefensiveAilments, SonariaConstants.QuickCacheKeys.DefensiveAilments)
	ListenForRuntimeTestChanges(cinfo, cinfo.DataContainerObject.MainInfo.Stats.AreaAilments, SonariaConstants.QuickCacheKeys.AoEAilments)

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid and humanoid:IsA("Humanoid") then
		if createdNewSpecs then
			humanoid.HealthChanged:Connect(function (health: number)
				cinfo.ReplicatedPlayer:ChangeValueInCurrentSlot({"Health"}, health)
			end)
			humanoid.Died:Connect(function() 
				cinfo:SetDead(true)
				cinfo:Destroy(true)
			end)
		end
	else
		AnalyticsErrorFromInstance(
			cinfo, SonariaConstants.Analytics.Exceptions.MalformedDataException, 
			"Character " .. tostring(character) .. " (" .. character:GetFullName() .. ", " .. player.Name .. ") was missing its Humanoid when attempting to listen to character changes. A severe desynchronization occurred (if this is on the client), or something deleted it."
		)
	end
	
	cinfo.PhysicsController = CharacterPhysicsMarshaller.new(cinfo)
	
	return (cinfo :: any) :: CharacterInfo
end

-- Attempts to find an existing data folder in the given character, and if it can, it will wrap it.
-- This character MUST be a player's character. Attempting to use this on an NPC will throw an error.
-- Also errors if the character does not have a data folder.
-- Setting noExceptions to true will cause this to return nil instead of erroring out. If noExceptions is false, then the return is never nil.
function CharacterStats.TryGet(character: Model, noExceptions: boolean?): CharacterInfo?
	local cached = Cache:Get(character)
	if cached then
		if cached:IsValid() then
			return cached
		else
			cached:Dispose()
			Cache:Remove(character)
			ByGUID:Remove(character)
		end
	end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		if noExceptions then return nil end
		error("Invalid character given (no player associated with this model).", 2)
	end

	local dataFolder = character:FindFirstChild("Data")
	if not dataFolder then
		if noExceptions then return nil end
		error("Invalid character given (missing Data folder).", 2)
	end

	local replicator: Replicator & typeof(PlayerReplicator) = PlayerReplicator.For(player)::any -- no data arg needed, uses cache
	local slot = replicator:GetCurrentSlot()
	if not slot then
		if noExceptions then return nil end
		error("Invalid character given (player's slot is not set to a save slot representing character in the world)", 2)
	end	
	return CharacterStats.For(player, slot::Slot, character) :: CharacterInfo
end

-- Returns a pre-existing character controller associated with the given ID, or nil if no such association exists or is invalid.
function CharacterStats.FromGUID(guid: string): CharacterInfo?
	local character = ByGUID:GetByValue(guid)
	if character then
		return CharacterStats.TryGet(character :: Model, true)
	end
	return nil
end

-- Returns an immutable snapshot of all valid character controllers at this time.
function CharacterStats.GetAll(): {CharacterInfo}
	local result = table.create(Players.MaxPlayers)
	for character: Instance, info: any in pairs(Cache.Storage) do
		if info:IsValid() then
			table.insert(result, info)
		end
	end
	return table.freeze(result)::any
end

function CharacterStats.Exists(player: Player): boolean
	if not player.Character then return false end

	local character = player.Character :: Model
	local cached = Cache:Get(character)
	if cached then
		if cached:IsValid() and not cached:IsDead() then
			return true
		else
			cached:Dispose()
			Cache:Remove(character)
			ByGUID:Remove(character)
		end
	end
	return false
end

type Slot = CreatureTypeDefs.Slot
type PlayerData = CreatureTypeDefs.PlayerData
export type PendingFieldChange = {
	Object: Instance,
	Attribute: string,
	InitializedValue: any,
	NewValue: any
}

export type CharacterStats = typeof(CharacterStats)
export type CharacterInstance = {
	Player: Player,
	Character: CoSDataCharacter,
	OccupiedSlot: Slot,
	BaseInfo: any,
	DataContainerObject: Specifications,
	PendingChanges: {PendingFieldChange},
	ArbCache: {[any]: any},
	AwaitingChangeConfirmation: boolean,
	ReplicatedPlayer: Replicator,
	
	PhysicsController: any; -- Must be any due to cyclic require usage.

	CurrentCharacterGUID: string,
}
--export type CharacterInfo = CharacterInstance & CharacterStats
export type CharacterInfo = any
-- ^ temp: cast to any to reduce this insane editor lag

export type Delegate = (...any) -> (...any)

if IS_SERVER then
	local function ApplyPendingChanges(player: Player, pendingChangeArray: {PendingFieldChange})
		if not player.Character then
			return -- Abort, this player has no character.
		end

		if typeof(pendingChangeArray) ~= "table" then
			return -- Invalid type.
		end

		local controller: CharacterInfo? = CharacterStats.TryGet(player.Character::any, true)
		if controller then
			controller:FilterAndParseReplicationData(pendingChangeArray)
		else
			warnstack("Failed to acquire a character upon a player's request to update their data. (player: @" .. player.Name .. " (" .. player.UserId .. "))")
		end
	end

	local function PlaySound(player: Player, soundType: string)
		if not player.Character then
			return -- Abort, this player has no character.
		end

		if typeof(soundType) ~= "string" then
			return -- Invalid type.
		end

		local controller: CharacterInfo? = CharacterStats.TryGet(player.Character::any, true)
		if controller then
			PlayCallSound(controller, soundType)
		else
			warnstack("Failed to acquire a character upon a player's request to play a call sound. (player: @" .. player.Name .. " (" .. player.UserId .. "))")
		end
	end

	ReplicateCharacterInfoEvent.OnServerEvent:Connect(function (player: Player, evtType: string, ...)
		if evtType == SonariaConstants.NetworkCalls.SendPendingChangesAsync then
			ApplyPendingChanges(player, ...) -- This function does the validation.
		elseif evtType == SonariaConstants.NetworkCalls.TryPlayCallSoundAsync then
			PlaySound(player, ...)
		end
	end)

	-- Spawns the player in the world at the given location as the given species.
	-- Does NOT check for species ownership nor slot validity. All this does is create a character
	-- at the CFrame and sets player.Character.
	function CharacterStats.SpawnReplacementCharacter(player: Player, species: string, ageName: string, location: CFrame): CharacterInfo
		local character = player.Character
		if character and character.Parent ~= WorldInfoProvider.CharacterFolder then
			error("Invalid character state! The character is not a member of the world character container?! (player: @" .. player.Name .. " (" .. player.UserId .. "))")
		end
		
		local speciesData = SpeciesInfoProvider.For(species)
		local newCharacter = SpeciesInfoProvider.CreateCreatureForSpawn(speciesData, ageName)
		newCharacter:PivotTo(location)
		newCharacter.Name = species
		newCharacter.Parent = WorldInfoProvider.CharacterFolder

		if character then
			local cached = Cache:Get(character)
			if cached then
				if cached:IsValid() then
					local migrationSuccessful = cached:Migrate(newCharacter, true)
					if not migrationSuccessful then
						-- very bad, need to manually recreate
						warn("Migration failed whilst trying to spawn replacement character for " .. tostring(cached) .. " (player: @" .. player.Name .. " (" .. player.UserId .. "))")
						cached:Destroy()
						local characterObject = CharacterStats.For(player, cached.ReplicatedPlayer:GetCurrentSlot(), newCharacter)
						characterObject:UpdatePhysics()
						return characterObject
					end
					return cached
				else
					character:Destroy()
					cached:Dispose()
				end
			end
		else
			player.Character = newCharacter
		end

		local pdata = PlayerReplicator.For(player) :: any
		local characterObject = CharacterStats.For(player, pdata:GetCurrentSlot(), newCharacter)
		characterObject:GetCharacter().Humanoid.MaxHealth = speciesData:GetMaxHealth() * characterObject:GetClampedAgeMultiplier()
		characterObject:UpdatePhysics()
		return characterObject
	end

elseif IS_CLIENT then
	local function ApplyPendingChanges(pendingChangeArray)
		local player = Players.LocalPlayer
		local currentCharacter = player.Character
		if not currentCharacter then
			return -- Abort, I have no character.
		end

		local controller = CharacterStats.TryGet(currentCharacter, true)
		if controller then
			controller:FilterAndParseReplicationData(pendingChangeArray)
		else
			warnstack("Failed to acquire this character.")
		end
	end

	local function MigrateCharacter(newCharacter)
		local player = Players.LocalPlayer
		local currentCharacter = player.Character
		if not currentCharacter then
			return -- Abort, I have no character.
		end

		local controller = CharacterStats.TryGet(currentCharacter, true)
		if controller then
			if not controller:Migrate(newCharacter, true) then
				warnstack("Failed to migrate data, creating new controller.")
				currentCharacter:Destroy()
				CharacterStats.For(player, controller.ReplicatedPlayer:GetCurrentSlot() :: Slot, newCharacter::Model)
			end
		else
			warnstack("Failed to acquire this character.")
		end
	end

	local function InvalidateCharacter(character: Model)
		if character then
			local cached = Cache:Get(character)
			if cached then
				if cached:IsValid() then
					cached:Dispose()
				end
				Cache:Remove(character)
				ByGUID:Remove(character)
				character:Destroy()
			end
		end
	end

	ReplicateCharacterInfoEvent.OnClientEvent:Connect(function (evtType, ...)
		if evtType == SonariaConstants.NetworkCalls.SendPendingChangesAsync then
			ApplyPendingChanges(...)
		elseif evtType == SonariaConstants.NetworkCalls.TryMigrateCharacterAsync then
			MigrateCharacter(...)
		elseif evtType == SonariaConstants.NetworkCalls.TellCharacterIsInvalidAsync then
			InvalidateCharacter(...)
		end
	end)
else
	print("The game will now have an existential crisis. If it's not a client, and it's not a server, then what is it? Is it even real? WHAT AM I!?!")
end

-- Verify all methods, and prevent the module from loading if something invalid is entered up above.
for path: string, ctr: {[string]: string} in pairs(ReplicatedStats) do
	for attr: string, method: string in pairs(ctr) do
		if CharacterStats[method] == nil then
			AnalyticsErrorFromInstance(
				nil, SonariaConstants.Analytics.Exceptions.MalformedDataException,
				"ReplicatedStats attempted to define " .. (path .. "[" .. attr .. "]") .. " using method CharacterStats::" .. method .. "(...), but no such method exists!" 
			)
		end
	end
end

table.freeze(CharacterStats :: any)
return CharacterStats