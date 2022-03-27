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


		// This serves as a means to create the template (as the plugin data and default values for use in the game)
		// as well as the Luau type definition
		// You should share this with your peers

		public static void Main(string[] args) {
			Creature creature = new Creature {};

			string asLuaObject = creature.ToLuaObject();
			string asPluginObject = creature.ToPluginObject();
			string asType = creature.ToType();

			StringBuilder result = new StringBuilder();
			result.AppendLine(BASE_INFO);
			result.AppendLine(asLuaObject);
			result.AppendLine(asPluginObject);
			result.AppendLine(asType);
			result.Append("return {CreatureObjectTemplate::any; CreatureObjectPluginData::any}");

			File.WriteAllText("./ProcGen.lua", result.ToString());

			File.WriteAllText("./testobject.lua", asLuaObject);
			File.WriteAllText("./testplugin.lua", asPluginObject);
			File.WriteAllText("./testtypedef.lua", asType);
		}
	}
}