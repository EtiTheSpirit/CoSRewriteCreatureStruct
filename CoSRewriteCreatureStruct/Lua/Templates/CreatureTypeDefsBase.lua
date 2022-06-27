﻿--!strict
-- Designed for the CoS Rewrite. This script has been procedurally generated by C# code.
-- See https://github.com/EtiTheSpirit/CoSRewriteCreatureStruct for more information.

--[[
local CreatureTypeDefs = require(ReplicatedStorage.CoreData.CreatureTypeDefs)
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
type CreatureData = CreatureTypeDefs.CreatureData
type CreatureAilmentStats = CreatureTypeDefs.CreatureAilmentStats
type CreatureResistanceStats = CreatureTypeDefs.CreatureResistanceStats
type CreatureAreaAilmentStats = CreatureTypeDefs.CreatureAreaAilmentStats
type Slot = CreatureTypeDefs.Slot
type PlayerData = CreatureTypeDefs.PlayerData
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SonariaConstants = require(ReplicatedStorage.CoreData.SonariaConstants)
local EtiLibs = ReplicatedStorage.EtiLibs
local table = require(EtiLibs.Extension.Table)

-- Properties that are intrinsic to a creature and cannot be set directly, they instead rely on other values.
export type IntrinsicProperties = {
	Sort: {Set: boolean, Value: string?},
	Gacha: {Set: boolean, Value: string?},
	IsFlier: {Set: boolean, Value: boolean?},
	IsGlider: {Set: boolean, Value: boolean?},
	CanEmitRadiation: {Set: boolean, Value: boolean?},
	CanDefensivelyParalyze: {Set: boolean, Value: boolean?},
	CanAmbush: {Set: boolean, Value: boolean?},
	IsNightstalker: {Set: boolean, Value: boolean?},
	IsWarden: {Set: boolean, Value: boolean?},
	IsUnbreakable: {Set: boolean, Value: boolean?}
}

export type StatusEffect = {
	UsesDuration: boolean;
	Level: number;
	StartedAt: number;
	Duration: number;
	SubAilment: string;
	Paused: boolean;
	PausedAt: number;
}
export type NamedStatusEffect = StatusEffect & {Name: string}

type Lookup<T> = {[string]: T};
export type CustomizationData = {
	Name: string;
	Colors: Lookup<{Color3|Enum.Material}>;
};
export type SpeciesUnlock = {
	CustomizationPresets: {CustomizationData};
	Amount: number;
	Palettes: number; -- int flags (bit32 library)
};
export type SaveDataStats = {
	StatusEffectsInflicted: {[string]: number};
	StatusEffectsReceived: {[string]: number};
	DamageDealt: number,
	DamageReceived: number,
	Deaths: number,
	HealingDealt: number,
	HealingReceived: number,
	Kills: number,
	RevivesUsed: number,
	TimePlayed: number,
	TimesTraded: number
}
export type Slot = {
	ArbJson: Lookup<any>;
	Vouchers: Lookup<any>;
	Customization: Lookup<{Color3|Enum.Material}>;
	PersistentStatusEffects: Lookup<StatusEffect>;
	Pets: {string};
	Age: number;
	Flags: number; -- bit32
	Food: number;
	GUID: string;
	Health: number;
	SpecialPalette: string;
	Species: string;
	Water: number;
	Stats: SaveDataStats;
}
export type PlayerData = {
	-- No data version field necessary here.
	ArbJson: Lookup<any>;
	Vouchers: Lookup<any>;
	Items: Lookup<Lookup<number>>;
	Login: Lookup<number>;
	Misc: {
		Event: {
			Christmas: Lookup<boolean>;
			Metaverse: Lookup<boolean>;
			Poppy: Lookup<boolean>;
			TOP: Lookup<boolean>;
		};
		GachaMissions: Lookup<Lookup<any>>;
		Gameplay: Lookup<any>;
		QuestUnlocks: Lookup<boolean>;
	};
	Money: {
		PartialTikits: number,
		Shooms: number,
		Tikits: number,
		TimePoints: number,
		Wisps: number
	};
	RNG: {
		SpinTokenIteration: number;
		StoredCreatureIteration: number;
	};
	Species: Lookup<SpeciesUnlock>;
	StoredCreatures: {
		MainSlots: {Slot};
		StoredSlots: {Slot};
		StorageSize: number;
	};
	Timing: {
		LastLogin: number;
		LastMissionAssign: number;
		LastYTCreatureGiven: number;
		StorageLockAppliedAt: number;
	};
	Stats: SaveDataStats;
}

-- The Roblox Player type coupled with information universal across Sonaria players.
export type CoSDataCharacter = Model & {Humanoid: Humanoid}

-- Proxy Section
local ProcGen = require(script.ProcGen)
export type CreatureOffensiveAilmentStats = ProcGen.CreatureOffensiveAilmentStats
export type CreatureDefensiveAilmentStats = ProcGen.CreatureDefensiveAilmentStats
export type CreatureResistanceStats = ProcGen.CreatureResistanceStats
export type CreatureAreaAilmentStats = ProcGen.CreatureAreaAilmentStats

-- Specifications => Instance Type