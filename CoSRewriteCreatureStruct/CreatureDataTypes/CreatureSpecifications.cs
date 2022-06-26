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

When stacking, the effect will have this value brought up to be <i>at least</i> equal to the left value. Additionally, this creature cannot stack it higher than the right value. If it is already higher, then this does nothing. The maximum can be set to 0 to use the game's global max.
<b>IMPORTANT:</b> When <i>not</i> stacking, then this will attempt to directly set the level or duration to the given value. If the creature already has the effect, and its level or duration is less than the minimum value here, <b>this does NOTHING instead of being ""bumped up"" like it does when stacking.</b> This can be used to skip adding an effect if someone already has it below a certain level.";

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

				[LuauField, PluginCustomEnum(ReferencesSonariaConstants = true, Key = "Holidays", AllowNone = true), Documentation($"The holiday this creature is associated with. <b>THIS DOES NOT CONTROL WHETHER OR NOT IT APPEARS IN ANY SHOPS.</b> This is strictly for its themed card in the menu. To control its appearance in the shop, open the {nameof(ForFunction)} container.", "Menu Card Display")]
				public string Holiday { get; set; } = string.Empty;

			}

			public class ForFunctionInfo : LuauRepresentable {

				/*
				[LuauField, Documentation("If true, this species cannot be traded to other players <b>AT ALL</b>. To limit who can trade it, consider changing LimitTradingToGroupRanks.", "Ownership")]
				public bool SpeciesNotTradeable { get; set; }

				[LuauField, Documentation("If true, stored creatures of this species cannot be traded to other players.", "Ownership")]
				public bool StoredNotTradeable { get; set; }
				*/

				// TODO: Better solution for limiting which group ranks can trade what creature!
				// The string list with ; separating elements works best for scripts, but is terrible for people who do not get code.
				// 1;2;4-192;254;255 makes perfect sense to me, but not to average joe.

				// A list of checkboxes with the names of group ranks could work, but that is not future proof (what if we add new ranks?
				// what if we change the names of ranks?)

				// CONSIDERATION: A hybrid system - the plugin keeps track of the semicolon-separated list (0;1;2;...) internally,
				// but the plugin makes the menu have checkboxes for each rank, so that what normal people see is names, but the
				// code still sees the unchanging values.

				/*
				[LuauField, PluginStringLimit(true, false, true), Documentation("If defined, this is a list of ranks (or ranges of ranks) in the group that that are allowed to trade this creature. Entries are separated by semicolons (;). To include many ranks at once, a range can be used. An example: <font color=\"#88ffff\">2;127-192;254;255</font> allows rank 2, all ranks 127 through 192, rank 254, and rank 255 to trade this creature.", "Ownership")]
				public string LimitTradingToGroupRanks { get; set; } = string.Empty;
				*/

				[LuauField, CopyFromV0("ForceHideGlimmerComingSoon", true), Documentation("If true, this species will not receive glimmer. This can be used to hide the \"Glimmer Coming Soon!\" display tag.", "Limitations")]
				public bool WillNeverGetGlimmer { get; set; }

				[LuauField(CustomValidationBehavior = ValidatorBehavior.ManageGachaAttributes), CopyFromV0("DevOnly", true), Documentation("If true, this species is only usable by developers. Attempting to spawn as this species without being a developer will result in the spawn attempt being rejected.", "Ownership")]
				public bool DeveloperUseOnly { get; set; }

				[LuauField(CustomValidationBehavior = ValidatorBehavior.ManageGachaAttributes), CopyFromV0("Limited", true), Documentation("If true, this species goes in the limited gacha. Overrides ForcedGachaList.", "Gachas")]
				public bool InLimitedGacha { get; set; }

				[LuauField(CustomValidationBehavior = ValidatorBehavior.ManageGachaAttributes), CopyFromV0("GamepassCreature", true), Documentation("If true, the game enforces that players who do not own this species are male, increases the cost in the Shoom shop by 50%, prevents trading stored versions unless the species is owned, and prevents it from showing in gachas.", "Limitations")]
				public bool HasPaidContentLimits { get; set; }

				[LuauField, Documentation("If true, this creature is not allowed to use any plushies that change its breath.", "Limitations")]
				public bool PreventPlushieBreathSwaps { get; set; }

				[LuauField(CustomValidationBehavior = ValidatorBehavior.ManageGachaAttributes), Documentation("If defined, this will override the gacha this creature appears in (overrides its default gacha). If this creature has paid content limits, this will override it and cause it to show in this gacha anyway.", "Gachas")]
				public string ForcedGachaList { get; set; } = string.Empty;

				[LuauField, PluginNumericLimit(1, 100), Documentation("If the gacha this is being placed into supports weighted selections, this is the chance that this, <b>as an individual item</b>, will be selected (not as a % relative to the amount of other items!). <b>100 should be used if the chances of all items in the gacha are equal.</b>", "Gachas")]
				public double WeightedGachaChance { get; set; } = 100;

				[LuauField(CustomValidationBehavior = ValidatorBehavior.HolidayCurrency), PluginNumericLimit(0), Documentation($"If the Holiday is set (see {nameof(ForShow)}), this is the price that the creature costs in that holiday's shop. The actual currency correlations are elsewhere in a registry. <b>Set this to 0 to DISABLE purchasing this creature in the shop.</b>")]
				public double HolidayCurrencyAmount { get; set; } = 0;

				// n.b. this has its own "None", do NOT set AllowNone = true.
				[LuauField(ValueAsLiteral = "SonariaConstants.ObjectRarity.None"), PluginCustomEnum(Key = "ObjectRarity", ReferencesSonariaConstants = true), Documentation("A value representing the rarity of this creature in the Limited shop. If this is not set to \"None\", then the creature will display that it has this rarity.")]
				public string Rarity { get; set; } = string.Empty;

				#region Group Info

				public class GroupRanks : LuauRepresentable {

					private const ValidatorBehavior VALIDATOR = ValidatorBehavior.GroupRankSelector;
					private const string DOCS = "If true, this rank can trade this creature. If false, they cannot. Whether or not \"this creature\" means species vs. stored depends on whatever you have selected right now.";

					// TO FUTURE ME: GroupRankSelector.lua in VSProject/Lua/ValidationBehaviors

					[LuauField(CustomValidationBehavior = VALIDATOR), PluginStringLimit(true, false, true), Documentation("A composite value used by the game which is a list of rank values that are allowed to trade this creature. This is automatically generated as ranks below are set on or off. Entries are separated by semicolons (;).", "Composite Value")]
					public string GroupRankArray { get; set; } = string.Empty;

					[LuauField(PluginOnly = true, CustomValidationBehavior = VALIDATOR), Documentation(DOCS, "Ranks")]
					public bool NonMember { get; set; } = true;

					[LuauField(PluginOnly = true, CustomValidationBehavior = VALIDATOR), Documentation(DOCS, "Ranks")]
					public bool Player { get; set; } = true;

					[LuauField(PluginOnly = true, CustomValidationBehavior = VALIDATOR), Documentation(DOCS, "Ranks")]
					public bool Tester { get; set; } = true;

					[LuauField(PluginOnly = true, CustomValidationBehavior = VALIDATOR), Documentation(DOCS, "Ranks")]
					public bool ContentCreator { get; set; } = true;

					[LuauField(PluginOnly = true, CustomValidationBehavior = VALIDATOR), Documentation(DOCS, "Ranks")]
					public bool FriendsAndFamily { get; set; } = true;

					[LuauField(PluginOnly = true, CustomValidationBehavior = VALIDATOR), Documentation(DOCS, "Ranks")]
					public bool Contributor { get; set; } = true;

					[LuauField(PluginOnly = true, CustomValidationBehavior = VALIDATOR), Documentation(DOCS, "Ranks")]
					public bool Staff { get; set; } = true;

					[LuauField(PluginOnly = true, CustomValidationBehavior = VALIDATOR), Documentation(DOCS, "Ranks")]
					public bool Testing { get; set; } = true;

					[LuauField(PluginOnly = true, CustomValidationBehavior = VALIDATOR), Documentation(DOCS, "Ranks")]
					public bool Administrator { get; set; } = true;

					[LuauField(PluginOnly = true, CustomValidationBehavior = VALIDATOR), Documentation(DOCS, "Ranks")]
					public bool OtherDeveloper { get; set; } = true;

					[LuauField(PluginOnly = true, CustomValidationBehavior = VALIDATOR), Documentation(DOCS, "Ranks")]
					public bool SonarDeveloper { get; set; } = true;

					[LuauField(PluginOnly = true, CustomValidationBehavior = VALIDATOR), Documentation(DOCS, "Ranks")]
					public bool CoOwner { get; set; } = true;

					[LuauField(PluginOnly = true, CustomValidationBehavior = VALIDATOR), Documentation(DOCS, "Ranks")]
					public bool Owner { get; set; } = true;

				}

				#endregion

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

				[LuauField, Documentation("Whether or not this creature is able to eat rotten food without the negative side effects.", "Dietary Extras")]
				public bool CanEatRotten { get; set; } = false;

				[LuauField, PluginNumericLimit(1, AdvisedMinimum = 1, AdvisedMaximum = 5), Documentation("The amount of food this creature loses every minute.", "Resource Management")]
				public double HungerDrain { get; set; }

				[LuauField, PluginNumericLimit(1, AdvisedMinimum = 1, AdvisedMaximum = 5), Documentation("The amount of water this creature loses every minute.", "Resource Management")]
				public double ThirstDrain { get; set; }

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

					[LuauField, PluginNumericLimit(-200, 200, AdvisedMinimum = -10, AdvisedMaximum = 10), Documentation("If this value is <b>not zero</b>, it will override the % DPS that this breath does. Inputting 0 will use the breath's default", "Breath Overrides")]
					public double BreathDamageOverride { get; set; } = 0;
					
					[LuauField, PluginNumericLimit(0, AdvisedMaximum = 15), Documentation("If this value is <b>not zero</b>, it will override the cooldown that the creature has when using a breath. This only applies to auto-firing breaths. Inputting 0 will use the breath's default.", "Breath Overrides")]
					public double BreathCooldownOverride { get; set; } = 0;

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

					[LuauField, PluginNumericLimit(0, AdvisedMaximum = 1.5), Documentation("The level that is added per second by this AoE.")]
					public double LevelPerSecond { get; set; } = 0;

					[LuauField, PluginNumericLimit(0, AdvisedMaximum = 2.5), Documentation("The duration that is added per second by this AoE.")]
					public double DurationPerSecond { get; set; } = 0;

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

					[LuauField, Documentation("Whether or not this AoE effect applies to the user.", "Behavior")]
					public bool AffectSelf { get; set; } = false;

					[LuauField, PluginCustomEnum(Key = "AoERemotePlayerTarget", ReferencesSonariaConstants = true, AllowNone = true), Documentation("Whether or not this AoE effect applies to nearby players.", "Behavior")]
					public string AffectOthersType { get; set; } = string.Empty;

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

					[LuauField, Documentation($"If true, this effect will apply when this creature is hurt by environmental or scripted damage. Of course, this does nothing if {nameof(ApplyTo)} is not Self.", "Methodology")]
					public bool ApplyWhenDamagedByEnvironment { get; set; } = false;

				}

				public class AilmentResistancesInfo : StatusEffectBase {
					public AilmentResistancesInfo() { }

					[LuauField, PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("The resistance to incoming levels, by percentage, at the start of this creature's life. A value of -1 doubles the level, a value of 0 does nothing, and a value of 1 completely reduces it to 0.", "Resistance")]
					public double InitialLevelResistance { get; set; } = 0;

					[LuauField, PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("The resistance to incoming duration, by percentage, at the start of this creature's life. A value of -1 doubles the duration, a value of 0 does nothing, and a value of 1 completely reduces it to 0.", "Resistance")]
					public double InitialDurationResistance { get; set; } = 0;

					[LuauField, PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("The resistance to incoming levels, by percentage, at the end of this creature's life. A value of -1 doubles the level, a value of 0 does nothing, and a value of 1 completely reduces it to 0.", "Resistance")]
					public double EndLevelResistance { get; set; } = 0;

					[LuauField, PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("The resistance to incoming duration, by percentage, at the end of this creature's life. A value of -1 doubles the duration, a value of 0 does nothing, and a value of 1 completely reduces it to 0.", "Resistance")]
					public double EndDurationResistance { get; set; } = 0;

				}

				public class UniversalResistancesInfo : LuauRepresentable {

					[LuauField(KeyAsLiteral = "[SonariaConstants.PlayerDamageType.Melee]"), PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("All damage from melee is reduced by this amount no matter the context. Negative values introduce weakness (additional damage).", "Core Overrides")]
					public double Melee { get; set; } = 0;

					[LuauField(KeyAsLiteral = "[SonariaConstants.PlayerDamageType.Breath]"), PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("All damage from breaths is reduced by this amount no matter the context. Negative values introduce weakness (additional damage).", "Core Overrides")]
					public double Breath { get; set; } = 0;

					[LuauField(KeyAsLiteral = "[SonariaConstants.PlayerDamageType.Ability]"), PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("All damage from abilities is reduced by this amount no matter the context. Negative values introduce weakness (additional damage).", "Core Overrides")]
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

					[LuauField, CopyFromV0("DefensiveParalyze", Percentage = PercentType.Scale0To100), PluginNumericLimit(0, 100, IsPercent = true), Documentation("If this ability makes use of RNG, it will index this value to determine the chance to apply in whichever way it sees appropriate. Naturally, this varies between abilities.", "Ability Overrides")]
					public double ChanceIfApplicable { get; set; }

					[LuauField, PluginNumericLimit(0, 100, IsPercent = true), Documentation("If this ability is an area of effect, this is its range. The way the ability uses this range value may change based on the ability.", "Ability Overrides")]
					public double RangeIfApplicable { get; set; }

					[LuauField, PluginNumericLimit(0, AdvisedMaximum = 180), Documentation("If this value is not 0, this will override the cooldown time (in seconds) for this species specifically when it uses this ability. Set to 0 to use the default as defined by the ability itself.", "Ability Overrides")]
					public double CooldownOverride { get; set; }

					[LuauField, Documentation("If this ability does damage, then this value is used to determine the damage. Whether or not this damage is absolute or percentage based, let alone even used in the first place, depends on the ability this exists for and how it chooses to use this value.", "Ability Overrides")]
					public double DamageIfApplicable { get; set; }

				}

				public class PassiveInfo : LuauRepresentable {

					[LuauField(ValueAsLiteral = "SonariaConstants.AquaAffinity.Terrestrial", CustomValidationBehavior = ValidatorBehavior.ManageAquaAffinity), CopyFromV0(null, CustomConversionCallback = CopyBehavior.GetAquaAffinity), PluginCustomEnum(ReferencesSonariaConstants = true, Key = "AquaAffinity", AllowNone = false, HideKeys = new[] {"AllTerrain"}), Documentation("The affinity to water that this creature has, which determines where it can live.", "Capabilities")]
					public string AquaAffinity { get; set; } = "Terrestrial";

					[LuauField, CopyFromV0("Glider", true), Documentation("If true, then this creature is is only capable of gliding, not powered flight. Does nothing if the creature is not a flier.", "Capabilities")]
					public bool OnlyGlide { get; set; } = false;

					[LuauField(CustomValidationBehavior = ValidatorBehavior.HealRadiusValues), Documentation("The range of this species's passive healing (that heals other, nearby creatures). <b>Set this to 0 to disable the passive heal ability.</b>", "Passive Healing")]
					public double PassiveHealingRange { get; set; } = 0;

					[LuauField(CustomValidationBehavior = ValidatorBehavior.HealRadiusValues), PluginNumericLimit(0, AdvisedMaximum = 100, IsPercent = true), Documentation("This is the percentage of nearby players' health that increases per second.", "Passive Healing")]
					public double PassiveHealingPerSecond { get; set; } = 0;

					[LuauField(CustomValidationBehavior = ValidatorBehavior.HealRadiusValues), Documentation("If true, the passive healing will only work if this creature is resting. If false, it works always (where allowed).", "Passive Healing")]
					public bool PassiveHealWhenSelfRest { get; set; } = true;

					[LuauField(CustomValidationBehavior = ValidatorBehavior.HealRadiusValues), Documentation("If true, the passive healing will only work if the person being healed is resting. If false, it works always (where allowed).", "Passive Healing")]
					public bool PassiveHealWhenOthersRest { get; set; } = true;

					[LuauField(CustomValidationBehavior = ValidatorBehavior.HealRadiusValues), Documentation("If true, the passive healing only applies to packmates.", "Passive Healing")]
					public bool PassiveHealingPackOnly { get; set; } = true;

					[LuauField, CopyFromV0("KeenObserver", true), Documentation("If true, players using this species can see a healthbar over other creatures at all times, as well as some status effects.", "Capabilities")]
					public bool SeeHealth { get; set; } = false;

					[LuauField, PluginNumericLimit(0, AdvisedMaximum = 30), Documentation("If this value is not zero, this is the duration of Guilty that this creature applies, granted the person who bit this creature was not provoked.", "Capabilities")]
					public double CauseGuiltDuration { get; set; } = 0;

					[LuauField, Documentation("Whether or not this creature causes bone break or ligament tear based on its Damage Weight in melee attacks.", "Bone Break and Ligament Tear")]
					public bool BoneBreaker { get; set; } = false;

					[LuauField, PluginNumericLimit(0, 100, AdvisedMaximum = 90, IsPercent = true), Documentation("If this creature bites a creature whose weight is greater than or equal to this % of this creature's weight, then they cannot be broken by this creature.", "Bone Break and Ligament Tear")]
					public double MaxBreakOrTearWeight { get; set; } = 0;

					[LuauField, PluginNumericLimit(0, 100, AdvisedMaximum = 65, IsPercent = true), Documentation("If this creature bites a creature whose weight is less than this % of this creature's weight, they will receive a bone break, otherwise they will receive a ligament tear.", "Bone Break and Ligament Tear")]
					public double BoneBreakLessThanWeight { get; set; } = 0;

					[LuauField, Documentation("The minimum and maximum duration (in seconds) of a bone break or a ligament tear, granted this creature causes either of the two. Weights very close to their limits will be less severe than a huge weight difference.", "Bone Break and Ligament Tear")]
					public StatLimit BreakMinMaxDuration { get; set; } = new StatLimit(10, 60);

					[LuauField, PluginNumericLimit(0, 100, AdvisedMaximum = 65, IsPercent = true), Documentation("Whenever this creature would normally be inflicted with a ligament tear, this value is the percent chance that it will upgrade into a bone break.", "Bone Break and Ligament Tear")]
					public double BoneBreakSusceptibility { get; set; } = 0;

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

				[LuauField, PluginNumericLimit(0), Documentation("The <b>ABSOLUTE</b> stamina drain per second when flying.", "Flight")]
				public double FlightStaminaReductionRate { get; set; } = 0;

				[LuauField, PluginNumericLimit(0), Documentation("The <b>ABSOLUTE</b> stamina drain per second when gliding.", "Flight")]
				public double GlideStaminaReductionRate { get; set; } = 0;

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
