﻿--!strict
-- Designed for the CoS Rewrite. This script has been procedurally generated by C# code.
-- See https://github.com/EtiTheSpirit/CoSRewriteCreatureStruct for more information.
-- This should be a child of ReplicatedStorage.CoreData.TypeDefs.CreatureTypeDefs and be named ProcGen

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SonariaConstants = require(ReplicatedStorage.CoreData.SonariaConstants)
local EtiLibs = ReplicatedStorage.EtiLibs
local table = require(EtiLibs.Extension.Table)
local string = require(EtiLibs.Extension.String)

local BLACK_SEQUENCE = ColorSequence.new(Color3.new())
local DEFAULT_PALETTE = {
	Index = 1;
	Enabled = true;
	UnlockRequirement = "";
	NumberOfColorsToUse = 12;
	Colors = {
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
	};
}
local DEFAULT_SOUND = {
	ID = "rbxassetid://0";
	Volume = 0.5;
	Range = 600;
	Pitch = 1;
};