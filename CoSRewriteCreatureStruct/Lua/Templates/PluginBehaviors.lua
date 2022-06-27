﻿--!strict
-- Designed for the CoS Rewrite. This script has been procedurally generated by C# code.
-- See https://github.com/EtiTheSpirit/CoSRewriteCreatureStruct for more information.

-- TARGET: plugin.Main.UpgradeBehaviors (ModuleScript)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SonariaConstants = require(ReplicatedStorage.CoreData.SonariaConstants);
local EtiLibs = script.Parent.Parent.EtiLibs
local table = require(EtiLibs.Extension.Table)
local string = require(EtiLibs.Extension.String)
local math = require(EtiLibs.Extension.Math)

local AgnosticCopyBehaviors = table.freeze({
%%CS_AGNOSTIC_COPY%%
})
local HardCodedCopyBehaviors = table.freeze({
%%CS_HARDCODE_COPY%%
})
local IntrinsicProperties = table.freeze({
%%CS_INTRINSIC_COPY%%
})
local ValidationBehaviors = table.freeze({
%%CS_VALIDATION_COPY%%
})

return table.freeze({
	Agnostic = AgnosticCopyBehaviors;
	HardCoded = HardCodedCopyBehaviors;
	Intrinsic = IntrinsicProperties;
	Validators = ValidationBehaviors;
})