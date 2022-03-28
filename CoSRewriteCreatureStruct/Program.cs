﻿using CoSRewriteCreatureStruct.CreatureDataTypes;
using System;
using System.Text;

namespace CoSRewriteCreatureStruct {

	

	public static class Program {

		public const string BASE_INFO =
@"--!strict
-- Designed for the CoS Rewrite. This script has been procedurally generated by C# code.
-- See https://github.com/EtiTheSpirit/CoSRewriteCreatureStruct for more information.

local ReplicatedStorage = game:GetService(""ReplicatedStorage"")
local SonariaConstants = require(ReplicatedStorage.CoreData.SonariaConstants)
local EtiLibs = ReplicatedStorage.EtiLibs
local table = require(EtiLibs.Extension.Table)
local string = require(EtiLibs.Extension.String)

local function NULL(objType: string): any
	local obj = Instance.new(objType)
	obj.Archivable = false;
	obj.Name = ""NULL"";
	return obj
end
local BLACK_SEQUENCE = ColorSequence.new(Color3.new())
local DEFAULT_PALETTE = {
	Index = 1;
	Enabled = true;
	NumberOfColorsToUse = 12;
	Color01 = BLACK_SEQUENCE;
	Color02 = BLACK_SEQUENCE;
	Color03 = BLACK_SEQUENCE;
	Color04 = BLACK_SEQUENCE;
	Color05 = BLACK_SEQUENCE;
	Color06 = BLACK_SEQUENCE;
	Color07 = BLACK_SEQUENCE;
	Color08 = BLACK_SEQUENCE;
	Color09 = BLACK_SEQUENCE;
	Color10 = BLACK_SEQUENCE;
	Color11 = BLACK_SEQUENCE;
	Color12 = BLACK_SEQUENCE;
}
local DEFAULT_SOUND = {
	ID = ""rbxassetid://0"";
	Volume = 0.5;
	Range = 600;
};
";

		public const string CLOSING_STRING =
@"export type Flags = typeof(CreatureObjectTemplate.Specifications.Attributes)
export type SoundInfo = typeof(DEFAULT_SOUND)
export type AnimationConfiguration = typeof(CreatureObjectTemplate.CreatureVisuals.Animations.Settings)
export type LandAnimations = typeof(CreatureObjectTemplate.CreatureVisuals.Animations.Land)
export type AerialAnimations = typeof(CreatureObjectTemplate.CreatureVisuals.Animations.Aerial)
export type AquaticAnimations = typeof(CreatureObjectTemplate.CreatureVisuals.Animations.Aquatic)
export type ActionAnimations = typeof(CreatureObjectTemplate.CreatureVisuals.Animations.Actions)
export type CreaturePalette = typeof(DEFAULT_PALETTE)
export type CreatureOffensiveAilmentStats = typeof(CreatureObjectPluginData.Specifications.MainInfo.Stats.MeleeAilments.__CDV2_PLUGIN_TEMPLATE)
export type CreatureDefensiveAilmentStats = typeof(CreatureObjectPluginData.Specifications.MainInfo.Stats.DefensiveAilments.__CDV2_PLUGIN_TEMPLATE)
export type CreatureResistanceStats = typeof(CreatureObjectPluginData.Specifications.MainInfo.Stats.AilmentResistances.__CDV2_PLUGIN_TEMPLATE)
export type CreatureAreaAilmentStats = typeof(CreatureObjectPluginData.Specifications.MainInfo.Stats.AreaAilments.__CDV2_PLUGIN_TEMPLATE)
export type CreatureSpecs = typeof(CreatureObjectTemplate.Specifications)
";


		public const string PROXY_STRING = "local ProcGen = require(script.ProcGen)\n";

		public const string PROXY_LOADER =
@"local IsolatedSpecifications = table.deepishCopy(CreatureObjectTemplate.Specifications) do
	IsolatedSpecifications.Attributes = nil::any;
	IsolatedSpecifications.MainInfo.Size.Tier = nil::any;
	IsolatedSpecifications.MainInfo.Size.MinutesToGrow = nil::any;
end";


		// This serves as a means to create the template (as the plugin data and default values for use in the game)
		// as well as the Luau type definition
		// You should share this with your peers

		public static void Main(string[] args) {
			Creature creature = new();

			string asLuaObject = creature.ToLuaObject();
			string asPluginObject = creature.ToPluginObject();
			string asType = creature.ToType();

			StringBuilder result = new StringBuilder();
			result.AppendLine(BASE_INFO);
			result.AppendLine(asLuaObject);
			result.AppendLine(asPluginObject);
			result.AppendLine(asType);
			result.AppendLine(PROXY_LOADER);
			result.AppendLine(CLOSING_STRING);
			result.Append("return {CreatureObjectTemplate::any; CreatureObjectPluginData::any; IsolatedSpecifications::any;}");

			File.WriteAllText("./ProcGen.lua", result.ToString());

			StringBuilder alt = new StringBuilder(PROXY_STRING);
			string[] lines = CLOSING_STRING.Split("\r\n");
			for (int i = 0; i < lines.Length - 1; i += 1) {
				string line = lines[i];
				string[] type = line.Split(" = ");
				string part = type[0];
				alt.Append(part);
				alt.Append(" = ProcGen.");
				alt.AppendLine(part.Replace("export type ", ""));
			}
			alt.AppendLine("export type CreatureData = ProcGen.CreatureData");

			File.WriteAllText("./ProcGenProxy.lua", alt.ToString());

			File.WriteAllText("./testobject.lua", asLuaObject);
			File.WriteAllText("./testplugin.lua", asPluginObject);
			File.WriteAllText("./testtypedef.lua", asType);
		}
	}
}