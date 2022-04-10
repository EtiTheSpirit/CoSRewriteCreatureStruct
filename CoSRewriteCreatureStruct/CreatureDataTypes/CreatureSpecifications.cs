using CoSRewriteCreatureStruct.Attributes;
using CoSRewriteCreatureStruct.PluginMenuTypes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.CreatureDataTypes {
	public class CreatureSpecifications : LuauRepresentable {

		public const string LIMIT_DESC = @"

When stacking, the effect will have this value brought up to be <i>at least</i> equal to the left value. Additionally, this creature cannot stack it higher than the right value. If it is already higher, then this does nothing. The maximum can be set to 0 to use the game's global max.";

		[LuauField]
		public AttributesInfo Attributes { get; set; } = new AttributesInfo();

		[LuauField, RepresentedByInstance]
		public MobilityInfo Mobility { get; set; } = new MobilityInfo();

		[LuauField, RepresentedByInstance]
		public MainInfoCtr MainInfo { get; set; } = new MainInfoCtr();

		[LuauField(RuntimeOnly = true), RepresentedByInstance]
		public RuntimeInfo Runtime { get; set; } = new RuntimeInfo();

		#region Class Defs
		public class AttributesInfo : LuauRepresentable {

			[LuauField]
			public ForShowInfo ForShow { get; set; } = new ForShowInfo();

			[LuauField]
			public ForFunctionInfo ForFunction { get; set; } = new ForFunctionInfo();

			#region Class Defs

			public class ForShowInfo : LuauRepresentable {

				[LuauField, CopyFromV0("Badge", true), Documentation("If enabled, this creature is classified as a reward for Beta Testers. Currently only Aolenus and Keruku should have this enabled.", "Menu Card Display")]
				public bool BetaTesterReward { get; set; }

				[LuauField, CopyFromV0("DevSupporter", true), Documentation("If enabled, this creature is one representing a developer. This does not care about their hired status, so it should be enabled even for retired developers.", "Menu Card Display")]
				public bool DevCreature { get; set; }

				[LuauField, CopyFromV0("NowUnobtainable", true), Documentation($"If enabled, this creature is currently (as in \"right now at this exact moment in time\") unable to be acquired. Unless trading is disabled, this means the only way to get it is via trading. <b>THIS DOES NOT APPLY ANY LIMITS.</b> To actually enforce this, other settings (such as those in the {nameof(ForFunction)} container) should be changed.", "Menu Card Display")]
				public bool NowUnobtainable { get; set; }

				[LuauField, CopyFromV0("Mission"), Documentation("If enabled, this creature classifies as a reward for a mission or quest.", "Menu Card Display")]
				public bool MissionReward { get; set; }

				[LuauField, PluginCustomEnum(ReferencesSonariaConstants = true, Key = "Holidays", AllowNone = true), Documentation("The holiday this creature is associated with. <b>THIS DOES NOT CONTROL WHETHER OR NOT IT APPEARS IN ANY SHOPS.</b> This is strictly for its themed card in the menu.", "Menu Card Display")]
				public string Holiday { get; set; } = string.Empty;

			}

			public class ForFunctionInfo : LuauRepresentable {
				
				[LuauField, Documentation("If true, this species cannot be traded. Stored instances can still be traded however.", "Ownership")]
				public bool Untradeable { get; set; }

				[LuauField, CopyFromV0("ForceHideGlimmerComingSoon", true), Documentation("If true, this species will not receive glimmer. This can be used to hide the \"Glimmer Coming Soon!\" display tag.", "Limitations")]
				public bool WillNeverGetGlimmer { get; set; }

				[LuauField, CopyFromV0("DevOnly", true), Documentation("If true, this species is only usable by developers. Attempting to spawn as this species without being a developer will result in the spawn attempt being rejected.", "Ownership")]
				public bool DeveloperUseOnly { get; set; }

				[LuauField, CopyFromV0("Limited", true), Documentation("If true, this species goes in the limited gacha. Overrides ForcedGachaList.", "Gachas")]
				public bool InLimitedGacha { get; set; }

				[LuauField, CopyFromV0("GamepassCreature", true), Documentation("If true, the game enforces that players who do not own this species are male, increases the cost in the Shoom shop by 50%, prevents trading stored versions unless the species is owned, and prevents it from showing in gachas.", "Limitations")]
				public bool HasPaidContentLimits { get; set; }

				[LuauField, Documentation("If true, this creature is not allowed to use any plushies that change its breath.", "Limitations")]
				public bool PreventPlushieBreathSwaps { get; set; }

				[LuauField, Documentation("If defined, this will override the gacha this creature appears in (overrides its default gacha). If this creature has paid content limits, this will override it and cause it to show in this gacha anyway.", "Gachas")]
				public string ForcedGachaList { get; set; } = string.Empty;

				[LuauField, PluginNumericLimit(1, 100), Documentation("If the gacha this is being placed into supports weighted selections, this is the chance that this, <b>as an individual item</b>, will be selected. <b>100 should be used if this is not randomized.</b>", "Gachas")]
				public double WeightedGachaChance { get; set; } = 100;

				[LuauField, PluginStringLimit(true, false, true), Documentation("If defined, this is a list of ranks (or ranges of ranks) that that are allowed to trade this group. Entries are separated by semicolons (;). To include many ranks at once, a range can be used. An example: <font color=\"#88ffff\">2;127-192;254;255</font> allows rank 2, all ranks 127 through 192, rank 254, and rank 255 to trade this creature.", "Ownership")]
				public string LimitTradingToGroupRanks { get; set; } = string.Empty;

			}

			#endregion

		}

		public class MainInfoCtr : LuauRepresentable {

			[LuauField, RepresentedByInstance]
			public DietInfo Diet { get; set; } = new DietInfo();

			[LuauField, RepresentedByInstance]
			public SizeInfo Size { get; set; } = new SizeInfo();

			[LuauField, RepresentedByInstance]
			public StatsInfo Stats { get; set; } = new StatsInfo();

			[LuauField, RepresentedByInstance]
			public CapabilitiesInfo Capabilities { get; set; } = new CapabilitiesInfo();


			#region Class Defs

			public class DietInfo : LuauRepresentable {

				[LuauField, Documentation("Whether or not this creature is able to eat meat.", "Dietary Capabilities")]
				public bool CanEatMeat { get; set; } = true;

				[LuauField, Documentation("Whether or not this creature is able to eat plants.", "Dietary Capabilities")]
				public bool CanEatPlants { get; set; } = true;

				[LuauField, Documentation("Whether or not this creature is able to drink water.", "Dietary Capabilities")]
				public bool CanDrinkWater { get; set; } = true;

				[LuauField, CopyFromV0("Appetite"), PluginNumericLimit(1, AdvisedMinimum = 15), Documentation("The maximum amount of food this creature is able to eat.", "Resource Management")]
				public double Appetite { get; set; }

				// Yes, use appetite here
				[LuauField, CopyFromV0("Appetite"), PluginNumericLimit(1, AdvisedMinimum = 15), Documentation($"The maximum amount of water this creature is able to drink. Generally it is a good idea to have the same value as {nameof(Appetite)}.", "Resource Management")]
				public double ThirstAppetite { get; set; }

			}

			public class SizeInfo : LuauRepresentable {

				[LuauField, CopyFromV0("Weight"), PluginNumericLimit(1, AdvisedMaximum = 225000), Documentation("Creature weight determines damage scaling mechanics, the lower and uper extremes being 50% and 200%.", "Mechanics")]
				public double Weight { get; set; }

				[LuauField, CopyFromV0("Weight"), PluginNumericLimit(1, AdvisedMaximum = 225000), Documentation("Creature pickup weight determines which creatures it can carry vs. be carried by. Creatures with larger pickup weights can pick up those with equal or smaller weights.", "Mechanics")]
				public double PickupWeight { get; set; }

				[LuauField, CopyFromV0("Tier"), PluginNumericLimit(1, 5, true), Documentation("Tier is a general descriptor of creature size. It has no mechanical functions minus shop price, and mostly exists for the players.", "Classification")]
				public double Tier { get; set; }

				[LuauField, CopyFromV0("GrowthRate", CustomConversionCallback = CopyBehavior.CalcTimeToGrow), PluginNumericLimit(1, AdvisedMaximum = 120), Documentation("The amount of minutes it takes to get from age 1 to age 100.", "Classification")]
				public double MinutesToGrow { get; set; }

			}

			public class StatsInfo : LuauRepresentable {

				[LuauField, CopyFromV0("Health"), PluginNumericLimit(1, AdvisedMinimum = 100, AdvisedMaximum = 75000), Documentation("The amount of health this creature has at age 100. It is scaled uniformly as they age up, starting at 15% of this value at age 1.", "Vitality")]
				public double Health { get; set; } = 100;

				[LuauField, CopyFromV0("HealPercent", CustomConversionCallback = CopyBehavior.ConvHealRate, Percentage = PercentType.Scale0To100), PluginNumericLimit(0.01, 100, AdvisedMaximum = 12), Documentation("How much health this creature regains in a second. <b>PROGRAMMER NOTE: This is a percentage in the range of 0 to 100, but will tend to have values &lt;1!</b>", "Vitality")]
				public double HealPercentPerSecond { get; set; } = 10;

				[LuauField, CopyFromV0("AmbushMultiplier", Percentage = PercentType.Scale0To1), PluginNumericLimit(100, 1000, IsPercent = true, AdvisedMaximum = 200), Documentation("If this value is over 100%, this creature can ambush, which causes it to run in a straight line at this % of its normal speed.", "Capabilities")]
				public double AmbushSpeedMultiplier { get; set; } = 100;

				[LuauField, CopyFromV0("Nightvision"), PluginNumericLimit(1, 4), Documentation("Nightvision is a measure of how visible the game is at night. It controls how close a blinding fog is to the camera. Nightvision 4 represents being a nightstalker, which removes all limits of the night and improves its brightness.", "Capabilities")]
				public double Nightvision { get; set; } = 1;

				[LuauField, RepresentedByInstance]
				public AttackInfo Attack { get; set; } = new AttackInfo();

				
				[LuauField("CreatureAreaAilmentStats"), RepresentedByInstance, PluginIsSpecialAilmentTemplate]
				public AoEAilmentsInfo[] AreaAilments { get; set; } = Util.One<AoEAilmentsInfo>();

				[LuauField("CreatureOffensiveAilmentStats"), RepresentedByInstance, PluginIsSpecialAilmentTemplate]
				public OffensiveAilmentsInfo[] MeleeAilments { get; set; } = Util.One<OffensiveAilmentsInfo>();

				[LuauField("CreatureDefensiveAilmentStats"), RepresentedByInstance, PluginIsSpecialAilmentTemplate]
				public DefensiveAilmentsInfo[] DefensiveAilments { get; set; } = Util.One<DefensiveAilmentsInfo>();

				[LuauField("CreatureResistanceStats"), RepresentedByInstance, PluginIsSpecialAilmentTemplate]
				public AilmentResistancesInfo[] AilmentResistances { get; set; } = Util.One<AilmentResistancesInfo>();
				

				/*
				[LuauField("CreatureAoEAilmentStats"), RepresentedByInstance]
				public AoEAilmentsInfo AreaAilments { get; set; } = new AoEAilmentsInfo();

				[LuauField("CreatureOffensiveAilmentStats"), RepresentedByInstance]
				public OffensiveAilmentsInfo MeleeAilments { get; set; } = new OffensiveAilmentsInfo();

				[LuauField("CreatureDefensiveAilmentStats"), RepresentedByInstance]
				public DefensiveAilmentsInfo DefensiveAilments { get; set; } = new DefensiveAilmentsInfo();

				[LuauField("CreatureResistanceStats"), RepresentedByInstance]
				public AilmentResistancesInfo AilmentResistances { get; set; } = new AilmentResistancesInfo();
				*/

				[LuauField, RepresentedByInstance]
				public UniversalResistancesInfo UniversalAttackTypeResistances { get; set; } = new UniversalResistancesInfo();

				#region Class Defs
				public class AttackInfo : LuauRepresentable {

					[LuauField, CopyFromV0("Damage"), PluginNumericLimit(double.NegativeInfinity, double.PositiveInfinity), Documentation("The amount of unscaled damage this creature does when it attacks another. This can be set to a negative value for melee medics. The real amount of damage dealt depends on many factors decided on the fly.", "Capabilities")]
					public double Damage { get; set; } = 10;

					[LuauField, CopyFromV0("Breath", CustomConversionCallback = CopyBehavior.GetBreathIfString), PluginCustomEnum(ReferencesSonariaConstants = false, Key = "BreathRegistry", AllowNone = true), Documentation("The type of breath this creature has, if applicable.", "Capabilities")]
					public string BreathType { get; set; } = string.Empty;

					[LuauField, PluginNumericLimit(0, AdvisedMaximum = 15), Documentation("If this value is <b>not zero</b>, it will override the fuel (in seconds) that the creature has when using a breath. Inputting 0 will use the breath's default.", "Breath Overrides")]
					public double BreathFuelOverride { get; set; } = 0;

					[LuauField, PluginNumericLimit(0, AdvisedMaximum = 15), Documentation("If this value is <b>not zero</b>, it will override the time (in seconds) that the creature has to wait without firing until their fuel will start to regenerate. Inputting 0 will use the breath's default.", "Breath Overrides")]
					public double BreathRegenDelayOverride { get; set; } = 0;

					[LuauField, PluginNumericLimit(0, AdvisedMaximum = 15), Documentation("If this value is <b>not zero</b>, it will override the rate (in fuel per second) that the breath will regenerate fuel after not firing for the amount of time of the regen delay. Inputting 0 will use the breath's default.", "Breath Overrides")]
					public double BreathRegenRateOverride { get; set; } = 0;

					[LuauField, PluginNumericLimit(0.05, AdvisedMinimum = 0.2, AdvisedMaximum = 2.4), Documentation("The amount of time that must be waited between melee attacks from this species. Lower values means faster attacks. It is measured in seconds.", "Capabilities")]
					public double AttackDelaySeconds { get; set; } = 0.8;

				}

				public class StatusEffectBase : LuauRepresentable {

					[LuauField(PluginOnly = true, PluginReflectToProperty = "Name"), PluginCustomEnum(AllowNone = false, IsRobloxEnum = false, Key = "StatusEffectRegistry", ReferencesSonariaConstants = false), Documentation("The status effect that this represents.", "Attributes")]
					public string Effect { get; set; } = string.Empty;

				}

				public class AoEAilmentsInfo : StatusEffectBase {


					[LuauField, PluginNumericLimit(1, AdvisedMinimum = 20, AdvisedMaximum = 175), Documentation("The maximum reach of this effect.", "Behavior")]
					public double Range { get; set; } = 0;

					[LuauField, Documentation("The level stack limits when a victim is at the exact closest possible range of this AoE. Should generally have high values." + LIMIT_DESC, "Behavior")]
					public StatLimit StackLevelsAtClosest { get; set; } = new StatLimit(0, 0);

					[LuauField, Documentation("The level stack limits when a victim is at the exact furthest possible range of this AoE. Should generally have low values." + LIMIT_DESC, "Behavior")]
					public StatLimit StackLevelsAtFurthest { get; set; } = new StatLimit(0, 0);

					[LuauField, Documentation("The duration stack limits when a victim is at the exact closest possible range of this AoE. Should generally have high values." + LIMIT_DESC, "Behavior")]
					public StatLimit StackDurationAtClosest { get; set; } = new StatLimit(0, 0);

					[LuauField, Documentation("The duration stack limits when a victim is at the exact furthest possible range of this AoE. Should generally have low values." + LIMIT_DESC, "Behavior")]
					public StatLimit StackDurationAtFurthest { get; set; } = new StatLimit(0, 0);

					[LuauField, PluginCustomEnum(ReferencesSonariaConstants = false, Key = "StatusEffectRegistry", AllowNone = false), Documentation("The effect that this creature must have in order for this AoE to activate. This is usually a status effect for the state of the ability.", "Behavior")]
					public string RequiredSelfEffect { get; set; } = string.Empty;

					[LuauField, Documentation("Whether or not this AoE effect applies to the user as well as nearby players.", "Behavior")]
					public bool AffectSelf { get; set; } = false;

				}

				public class OffensiveAilmentsInfo : StatusEffectBase {

					[LuauField, Documentation("If true, this effect will stack within the limits. If false, it will directly set the values of level and duration if they are within limits.", "Behavior")]
					public bool AllowStacking { get; set; } = false;

					[LuauField, Documentation("If true, this effect always overrides the subeffect of any pre-existing instance of this effect. <b>This strictly operates if the effect on a given character <i>already has</i> a subeffect. If there is no subeffect, then this will always change the subeffect.</b>", "Behavior")]
					public bool AlwaysOverrideSubAilment { get; set; } = false;

					[LuauField, PluginNumericLimit(0, AdvisedMaximum = 10), Documentation("If stacking is enabled, this is the amount added per occurrence. If it is disabled, this is what the value is set to.", "Limits")]
					public double Level { get; set; } = 0;

					[LuauField, PluginNumericLimit(0, AdvisedMaximum = 30), Documentation("If stacking is enabled, this is the amount added per occurrence. If it is disabled, this is what the value is set to.", "Limits")]
					public double Duration { get; set; } = 0;

					[LuauField, Documentation("The stacking limits for the level." + LIMIT_DESC, "Limits")]
					public StatLimit StackLevelLimits { get; set; } = new StatLimit();

					[LuauField, Documentation("The stacking limits for the duration." + LIMIT_DESC, "Limits")]
					public StatLimit StackDurationLimits { get; set; } = new StatLimit();

					[LuauField, PluginNumericLimit(0, 100), Documentation("The chance that this has to apply, or 0 or 100 to always apply.", "Behavior")]
					public double RandomChance { get; set; } = 0;
					
				}

				// Inherit offensive!
				public class DefensiveAilmentsInfo : OffensiveAilmentsInfo {

					// This adds...

					[LuauField, PluginCustomEnum(ReferencesSonariaConstants = true, Key = "DefensiveEffectApplicationTarget", AllowNone = false), Documentation("Who, when triggered, this defensive effect applies to. This can be used to create unique behaviors, such as creatures suseptible to effects like bonebreak even when they are not bitten by a creature that can do that.", "Methodology")]
					public string ApplyTo { get; set; } = "Attacker";

					[LuauField, Documentation("If true, this effect will apply when this creature is hurt by melee.", "Methodology")]
					public bool ApplyWhenDamagedByMelee { get; set; } = true;

					[LuauField, Documentation("If true, this effect will apply when this creature is hurt by a breath.", "Methodology")]
					public bool ApplyWhenDamagedByBreath { get; set; } = false;

					[LuauField, Documentation("If true, this effect will apply when this creature is hurt by an ability.", "Methodology")]
					public bool ApplyWhenDamagedByAbility { get; set; } = false;

				}

				public class AilmentResistancesInfo : StatusEffectBase {
					public AilmentResistancesInfo() { }

					[LuauField, PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("The resistance to incoming levels, by percentage. A value of -1 doubles the level, a value of 0 does nothing, and a value of 1 completely reduces it to 0.", "Resistance")]
					public double LevelResistance { get; set; } = 0;

					[LuauField, PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("The resistance to incoming duration, by percentage. A value of -1 doubles the duration, a value of 0 does nothing, and a value of 1 completely reduces it to 0.", "Resistance")]
					public double DurationResistance { get; set; } = 0;

					[LuauField, Documentation("If true, this resistance scales from 0 to its given value as the creature ages to 100. If false, the given value applies at all ages.", "Methodology")]
					public bool ScaleWithAge { get; set; } = false;

					[LuauField, Documentation("If true, and if ScaleWithAge is true, then the resistance starts at the given value at age 0, and slowly goes away as the creature ages to 100. This is good for weaknesses where the weakness is reduced as age goes up.", "Methodology")]
					public bool InverseScale { get; set; } = false;

				}

				public class UniversalResistancesInfo : LuauRepresentable {

					[LuauField(KeyAsLiteral = "[SonariaConstants.PlayerDamageType.Melee]"), PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("All damage from melee is reduced by this amount no matter the context. Negative values introduce weakness (additional damage).", "Core Overrides")]
					public double Melee { get; set; } = 0;

					[LuauField(KeyAsLiteral = "[SonariaConstants.PlayerDamageType.Breath]"), PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("All damage from breaths is reduced by this amount no matter the context. Negative values introduce weakness (addiitonal damage).", "Core Overrides")]
					public double Breath { get; set; } = 0;

					[LuauField(KeyAsLiteral = "[SonariaConstants.PlayerDamageType.Ability]"), PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("All damage from abilities is reduced by this amount no matter the context. Negative values introduce weakness (addiitonal damage).", "Core Overrides")]
					public double Ability { get; set; } = 0;

				}
				#endregion

			}

			public class CapabilitiesInfo : LuauRepresentable {

				[LuauField, RepresentedByInstance]
				public AbilityInfo Abilities { get; set; } = new AbilityInfo();

				[LuauField, RepresentedByInstance]
				public PassiveInfo Passive { get; set; } = new PassiveInfo();

				#region Class Defs
				public class AbilityInfo : LuauRepresentable {

					[LuauField, PluginCustomEnum(ReferencesSonariaConstants = false, Key = "AbilityRegistry", AllowNone = true), Documentation("The name of the ability this creature has. It should be one of the registered abilities.", "Ability Information")]
					public string AbilityName { get; set; } = string.Empty;

					[LuauField, CopyFromV0("DefensiveParalyze", Percentage = PercentType.Scale0To100), PluginNumericLimit(0, 100, IsPercent = true), Documentation("If this ability makes use of RNG, it will index this value to determine the chance to apply in whichever way it sees appropriate.", "Ability Information")]
					public double ChanceIfApplicable { get; set; }

					[LuauField, PluginNumericLimit(0, 100, IsPercent = true), Documentation("If this ability is an area of effect, this is its range.", "Ability Information")]
					public double RangeIfApplicable { get; set; }

				}

				public class PassiveInfo : LuauRepresentable {

					[LuauField(ValueAsLiteral = "SonariaConstants.AquaAffinity.Terrestrial"), CopyFromV0(null, CustomConversionCallback = CopyBehavior.GetAquaAffinity), PluginCustomEnum(ReferencesSonariaConstants = true, Key = "AquaAffinity", AllowNone = false), Documentation("The affinity to water that this creature has, which determines where it can live.", "Capabilities")]
					public string AquaAffinity { get; set; } = "Terrestrial";

					[LuauField, CopyFromV0("Glider", true), Documentation("If true, then this creature is is only capable of gliding, not powered flight. Does nothing if the creature is not a flier.", "Capabilities")]
					public bool OnlyGlide { get; set; } = false;

					[LuauField, Documentation("If greater than zero, this creature is a passive healer.", "Passive Healing")]
					public double PassiveHealingRange { get; set; } = 0;

					[LuauField, Documentation("This is the percentage of nearby players' health that increases per second.", "Passive Healing")]
					public double PassiveHealingPerSecond { get; set; } = 0;

					[LuauField, Documentation("If true, the passive healing will only work if this creature is resting. If false, it works always (where allowed).", "Passive Healing")]
					public bool PassiveHealWhenSelfRest { get; set; } = true;

					[LuauField, Documentation("If true, the passive healing will only work if the person being healed is resting. If false, it works always (where allowed).", "Passive Healing")]
					public bool PassiveHealWhenOthersRest { get; set; } = true;

					[LuauField, Documentation("If true, the passive healing only applies to packmates.", "Passive Healing")]
					public bool PassiveHealingPackOnly { get; set; } = true;

					[LuauField, CopyFromV0("KeenObserver", true), Documentation("If true, players using this species can see a healthbar over other creatures at all times, as well as some status effects.", "Capabilities")]
					public bool SeeHealth { get; set; } = false;
					

				}
				#endregion

			}

			#endregion
		}

		public class MobilityInfo : LuauRepresentable {

			[LuauField, RepresentedByInstance]
			public AgilityInfo Agility { get; set; } = new AgilityInfo();

			[LuauField, RepresentedByInstance]
			public EnduranceInfo Endurance { get; set; } = new EnduranceInfo();
			
			#region Class Defs
			public class AgilityInfo : LuauRepresentable {

				[LuauField, CopyFromV0("Speed", CustomConversionCallback = CopyBehavior.GetDegradedSpeedForClass), PluginNumericLimit(0, AdvisedMaximum = 60), Documentation("The speed, measured in studs per second, that this creature moves at whilst walking.", "Land Speed")]
				public double WalkSpeed { get; set; } = 10;

				[LuauField, CopyFromV0("SprintSpeed", CustomConversionCallback = CopyBehavior.GetDegradedSpeedForClass), PluginNumericLimit(0, AdvisedMaximum = 150), Documentation("The speed, measured in studs per second, that this creature moves at whilst sprinting.", "Land Speed")]
				public double SprintSpeed { get; set; } = 20;

				[LuauField, CopyFromV0("FlySpeed", CustomConversionCallback = CopyBehavior.ConvFlySpeed), PluginNumericLimit(0, AdvisedMaximum = 325), Documentation("The speed, measured in studs per second, that this creature can achieve at maximum flight speed.", "Misc. Speed")]
				public double FlySpeed { get; set; } = 0;

				[LuauField, CopyFromV0("Speed", CustomConversionCallback = CopyBehavior.GetDegradedSpeedForClass), PluginNumericLimit(0, AdvisedMaximum = 50), Documentation("The speed, measured in studs per second, at which this creature swims.", "Swimming Speed")]
				public double SwimSpeed { get; set; } = 10;

				[LuauField, CopyFromV0("SprintSpeed", CustomConversionCallback = CopyBehavior.GetDegradedSpeedForClass), PluginNumericLimit(0, AdvisedMaximum = 100), Documentation("The speed, measured in studs per second, at which this creature swims whilst sprinting in water.", "Swimming Speed")]
				public double SwimFastSpeed { get; set; } = 20;

				[LuauField, CopyFromV0("TurnRadius", CustomConversionCallback = CopyBehavior.GetStudTurnRadius), PluginNumericLimit(0, 250, AdvisedMaximum = 200), Documentation("A value representing the turn radius of this creature measured in studs. The old largest seen turn radius (9, an elder Lmako is a good example) had a stud radius of approximately 230.", "Misc. Speed")]
				public double StudTurnRadius { get; set; } = 7;

				[LuauField, PluginNumericLimit(0, 1000), Documentation("The upward velocity applied when this creature jumps. This determines its jump height.", "Misc. Speed")]
				public double JumpImpulsePower { get; set; } = 50;

			}

			public class EnduranceInfo : LuauRepresentable {

				[LuauField, CopyFromV0("Stamina"), PluginNumericLimit(1, AdvisedMaximum = 450), Documentation("This creature's stamina, which is used whilst running or speed-swimming, and in flight.", "Stamina")]
				public double Stamina { get; set; } = 50;

				[LuauField, CopyFromV0("StaminaRegen"), PluginNumericLimit(1, AdvisedMaximum = 100), Documentation("The <b>ABSOLUTE AMOUNT</b> of stamina that this creature regains per second.", "Stamina")]
				public double StaminaRegenPerSecond { get; set; } = 3;

				[LuauField, CopyFromV0("Stamina"), PluginNumericLimit(1, 1200, AdvisedMinimum = 15, AdvisedMaximum = 240), Documentation("The number of seconds that this creature can stay underwater before they begin to drown.", "Breath")]
				public double Air { get; set; } = 100;

				[LuauField, CopyFromV0("StaminaRegen"), PluginNumericLimit(1, AdvisedMaximum = 5), Documentation("The <b>ABSOLUTE AMOUNT</b> of seconds this user regains whilst above water.", "Breath")]
				public double AirRegenPerSecond { get; set; } = 1;

			}
			#endregion
		}

		public class RuntimeInfo : LuauRepresentable {

			[LuauField, RepresentedByInstance]
			public LuauRepresentable State { get; set; } = ANONYMOUS;

			[LuauField, RepresentedByInstance]
			public AbilityInfoObject AbilityInfo { get; set; } = new AbilityInfoObject();

			[LuauField, RepresentedByInstance]
			public LuauRepresentable CombatInfo { get; set; } = ANONYMOUS;

			[LuauField, RepresentedByInstance]
			public LuauRepresentable StatusEffects { get; set; } = ANONYMOUS;

			[LuauField, RepresentedByInstance]
			public LuauRepresentable CustomData { get; set; } = ANONYMOUS;


			#region Class Defs

			public class AbilityInfoObject : LuauRepresentable {

				[LuauField, RepresentedByInstance]
				public LuauRepresentable ExtraData { get; set; } = ANONYMOUS;

			}

			#endregion

		}

		#endregion

	}
}
