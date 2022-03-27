using CoSRewriteCreatureStruct.Attributes;
using CoSRewriteCreatureStruct.PluginMenuTypes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.CreatureDataTypes {
	public class CreatureSpecifications : LuauRepresentable {

		[LuauField(AllowInCharacterCopy = false)]
		public AttributesInfo Attributes { get; set; } = new AttributesInfo();

		[LuauField]
		public MobilityInfo Mobility { get; set; } = new MobilityInfo();

		[LuauField]
		public MainInfoCtr MainInfo { get; set; } = new MainInfoCtr();

		#region Class Defs
		public class AttributesInfo : LuauRepresentable {

			[LuauField]
			public ForShowInfo ForShow { get; set; } = new ForShowInfo();

			[LuauField]
			public ForFunctionInfo ForFunction { get; set; } = new ForFunctionInfo();

			#region Class Defs

			public class ForShowInfo : LuauRepresentable {

				[LuauField]
				public bool BetaTesterReward { get; set; }

				[LuauField]
				public bool DevCreature { get; set; }

				[LuauField]
				public bool NowUnobtainable { get; set; }

				[LuauField]
				public bool MissionReward { get; set; }

				[LuauField]
				public string Holiday { get; set; } = string.Empty;

			}

			public class ForFunctionInfo : LuauRepresentable {
				
				[LuauField]
				public bool Untradeable { get; set; }

				[LuauField]
				public bool WillNeverGetGlimmer { get; set; }

				[LuauField]
				public bool DeveloperUseOnly { get; set; }

				[LuauField]
				public bool InLimitedGacha { get; set; }

				[LuauField]
				public bool HasPaidContentLimits { get; set; }

				[LuauField]
				public bool PreventPlushieBreathSwaps { get; set; }

				[LuauField]
				public string ForcedGachaList { get; set; } = string.Empty;

				// TODO: Limit for this
				[LuauField]
				public string LimitTradingToGroupRanks { get; set; } = string.Empty;

			}

			#endregion

		}

		public class MainInfoCtr : LuauRepresentable {

			[LuauField]
			public DietInfo Diet { get; set; } = new DietInfo();

			[LuauField]
			public SizeInfo Size { get; set; } = new SizeInfo();

			[LuauField]
			public StatsInfo Stats { get; set; } = new StatsInfo();

			[LuauField]
			public CapabilitiesInfo Capabilities { get; set; } = new CapabilitiesInfo();

			#region Class Defs
			public class DietInfo : LuauRepresentable {

				[LuauField, Documentation("Whether or not this creature is able to eat meat.")]
				public bool CanEatMeat { get; set; } = true;

				[LuauField, Documentation("Whether or not this creature is able to eat plants.")]
				public bool CanEatPlants { get; set; } = true;

				[LuauField, Documentation("Whether or not this creature is able to drink water.")]
				public bool CanDrinkWater { get; set; } = true;

				[LuauField, PluginNumericLimit(1, AdvisedMinimum = 15), Documentation("The maximum amount of food this creature is able to eat.")]
				public double Appetite { get; set; }

				[LuauField, PluginNumericLimit(1, AdvisedMinimum = 15), Documentation("The maximum amount of water this creature is able to drink. Generally it is a good idea to have the same value as Appetite.")]
				public double ThirstAppetite { get; set; }

			}

			public class SizeInfo : LuauRepresentable {

				[LuauField, PluginNumericLimit(1, AdvisedMaximum = 225000), Documentation("Creature weight determines some damage scaling mechanics.")]
				public double Weight { get; set; }

				[LuauField(AllowInCharacterCopy = false), PluginNumericLimit(1, 5, true), Documentation("Tier is a general descriptor of creature size. It has no mechanical functions minus shop price, and mostly exists for the players.")]
				public double Tier { get; set; }

				[LuauField(AllowInCharacterCopy = false), PluginNumericLimit(1, AdvisedMaximum = 120), Documentation("The amount of minutes it takes to get from age 1 to age 100.")]
				public double MinutesToGrow { get; set; }

			}

			public class StatsInfo : LuauRepresentable {

				[LuauField, PluginNumericLimit(1, AdvisedMinimum = 100, AdvisedMaximum = 75000)]
				public double Health { get; set; } = 100;

				[LuauField, PluginNumericLimit(1, 100, IsPercent = true, AdvisedMaximum = 12)]
				public double HealPercentPerLongTick { get; set; } = 10;

				[LuauField, PluginNumericLimit(100, 1000, IsPercent = true, AdvisedMaximum = 200)]
				public double AmbushSpeedMultiplier { get; set; } = 100;

				[LuauField, PluginNumericLimit(1, 4)]
				public double Nightvision { get; set; } = 1;

				public AttackInfo Attack { get; set; } = new AttackInfo();

				[LuauField, PluginIsSpecialAilmentTemplate]
				public AoEAilmentsInfo[] AreaAilments { get; set; } = Util.One<AoEAilmentsInfo>();

				[LuauField, PluginIsSpecialAilmentTemplate]
				public OffensiveAilmentsInfo[] MeleeAilments { get; set; } = Util.One<OffensiveAilmentsInfo>();

				[LuauField, PluginIsSpecialAilmentTemplate]
				public DefensiveAilmentsInfo[] DefensiveAilments { get; set; } = Util.One<DefensiveAilmentsInfo>();

				[LuauField, PluginIsSpecialAilmentTemplate]
				public AilmentResistancesInfo[] AilmentResistances { get; set; } = Util.One<AilmentResistancesInfo>();

				[LuauField]
				public UniversalResistancesInfo UniversalAttackTypeResistances { get; set; } = new UniversalResistancesInfo();

				#region Class Defs
				public class AttackInfo : LuauRepresentable {

					[LuauField, PluginNumericLimit(double.NegativeInfinity, double.PositiveInfinity), Documentation("The amount of unscaled damage this creature does when it attacks another. This can be set to a negative value for melee medics.")]
					public double Damage { get; set; } = 10;

					[LuauField, PluginCustomEnum(ReferencesSonariaConstants = false, Key = "BreathRegistry", AllowNone = true), Documentation("The type of breath this creature has, if applicable.")]
					public string BreathType { get; set; } = string.Empty;

					[LuauField, PluginNumericLimit(0.05, AdvisedMinimum = 0.2, AdvisedMaximum = 2.4), Documentation("The amount of time that must be waited between melee attacks from this species. Lower values means faster attacks. It is measured in seconds.")]
					public double AttackDelaySeconds { get; set; } = 0.8;

				}

				public class AoEAilmentsInfo : LuauRepresentable {

					[LuauField, PluginNumericLimit(1, AdvisedMinimum = 20, AdvisedMaximum = 175)]
					public double Range { get; set; } = 0;

					[LuauField, Documentation("The level stack limits when a victim is at the exact closest possible range of this AoE. Should generally have high values.")]
					public StatLimit StackLevelsAtClosest { get; set; } = new StatLimit(0, 0);

					[LuauField, Documentation("The level stack limits when a victim is at the exact furthest possible range of this AoE. Should generally have low values.")]
					public StatLimit StackLevelsAtFurthest { get; set; } = new StatLimit(0, 0);

					[LuauField, Documentation("The duration stack limits when a victim is at the exact closest possible range of this AoE. Should generally have high values.")]
					public StatLimit StackDurationAtClosest { get; set; } = new StatLimit(0, 0);

					[LuauField, Documentation("The duration stack limits when a victim is at the exact furthest possible range of this AoE. Should generally have low values.")]
					public StatLimit StackDurationAtFurthest { get; set; } = new StatLimit(0, 0);

					[LuauField, PluginCustomEnum(ReferencesSonariaConstants = false, Key = "StatusEffectRegistry", AllowNone = false), Documentation("The effect that this creature must have in order for this AoE to activate. This is usually a status effect for the state of the ability.")]
					public string RequiredSelfEffect { get; set; } = string.Empty;

					[LuauField, Documentation("Whether or not this AoE effect applies to the user as well as nearby players.")]
					public bool AffectSelf { get; set; } = false;

				}

				public class OffensiveAilmentsInfo : LuauRepresentable {

					[LuauField, Documentation("If true, this effect will stack within the limits. If false, it will directly set the values of level and duration if they are within limits.")]
					public bool AllowStacking { get; set; } = false;

					[LuauField, Documentation("If true, this effect always overrides the subeffect of any pre-existing instance of this effect. <b>This strictly operates if the effect on a given character <i>already has</i> a subeffect. If there is no subeffect, then this will always change the subeffect.</b>")]
					public bool AlwaysOverrideSubAilment { get; set; } = false;

					[LuauField, PluginNumericLimit(0, AdvisedMaximum = 10), Documentation("If stacking is enabled, this is the amount added per occurrence. If it is disabled, this is what the value is set to.")]
					public double Level { get; set; } = 0;

					[LuauField, PluginNumericLimit(0, AdvisedMaximum = 30), Documentation("If stacking is enabled, this is the amount added per occurrence. If it is disabled, this is what the value is set to.")]
					public double Duration { get; set; } = 0;

					[LuauField, Documentation("The stacking limits for the level. The left value, if not zero, denotes the required minimum (this will raise the effect to that level if it is not there already). The right value, if not zero, is the highest this creature can stack the effect. It cannot cause the stack to go higher.")]
					public StatLimit StackLevelLimits { get; set; } = new StatLimit();

					[LuauField, Documentation("The stacking limits for the duration. The left value, if not zero, denotes the required minimum (this will raise the effect to that duration if it is not there already). The right value, if not zero, is the highest this creature can stack the effect. It cannot cause the stack to go higher.")]
					public StatLimit StackDurationLimits { get; set; } = new StatLimit();

					[LuauField, PluginNumericLimit(0, 100), Documentation("The chance that this has to apply, or 0 or 100 to always apply.")]
					public double RandomChance { get; set; } = 0;
					
				}

				// Inherit offensive!
				public class DefensiveAilmentsInfo : OffensiveAilmentsInfo {

					// This adds...

					[LuauField, PluginCustomEnum(ReferencesSonariaConstants = true, Key = "DefensiveEffectApplicationTarget", AllowNone = false)]
					public string ApplyTo { get; set; } = "Attacker";

					[LuauField, Documentation("If true, this effect will apply when this creature is hurt by melee.")]
					public bool ApplyWhenDamagedByMelee { get; set; } = true;

					[LuauField, Documentation("If true, this effect will apply when this creature is hurt by a breath.")]
					public bool ApplyWhenDamagedByBreath { get; set; } = false;

					[LuauField, Documentation("If true, this effect will apply when this creature is hurt by an ability.")]
					public bool ApplyWhenDamagedByAbility { get; set; } = false;

				}

				public class AilmentResistancesInfo : LuauRepresentable {
					public AilmentResistancesInfo() { }

					[LuauField, PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("The resistance to incoming levels, by percentage. A value of -1 doubles the level, a value of 0 does nothing, and a value of 1 completely reduces it to 0.")]
					public double LevelResistance { get; set; } = 0;

					[LuauField, PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("The resistance to incoming duration, by percentage. A value of -1 doubles the duration, a value of 0 does nothing, and a value of 1 completely reduces it to 0.")]
					public double DurationResistance { get; set; } = 0;

					[LuauField, Documentation("If true, this resistance scales from 0 to its given value as the creature ages to 100. If false, the given value applies at all ages.")]
					public bool ScaleWithAge { get; set; } = false;

					[LuauField, Documentation("If true, and if ScaleWithAge is true, then the resistance starts at the given value at age 0, and slowly goes away as the creature ages to 100. This is good for weaknesses where the weakness is reduced as age goes up.")]
					public bool InverseScale { get; set; } = false;

				}

				public class UniversalResistancesInfo : LuauRepresentable {

					// TODO: Literal keys or field names, do not use the field name as defined here, allow it to reference SonariaConstants

					[LuauField(KeyAsLiteral = "[SonariaConstants.PlayerDamageType.Melee]"), PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("All damage from melee is reduced by this amount no matter the context. Negative values introduce weakness (additional damage).")]
					public double Melee { get; set; } = 0;

					[LuauField(KeyAsLiteral = "[SonariaConstants.PlayerDamageType.Breath]"), PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("All damage from breaths is reduced by this amount no matter the context. Negative values introduce weakness (addiitonal damage).")]
					public double Breath { get; set; } = 0;

					[LuauField(KeyAsLiteral = "[SonariaConstants.PlayerDamageType.Ability]"), PluginNumericLimit(-1000, 100, IsPercent = true), Documentation("All damage from abilities is reduced by this amount no matter the context. Negative values introduce weakness (addiitonal damage).")]
					public double Ability { get; set; } = 0;

				}
				#endregion

			}

			public class CapabilitiesInfo : LuauRepresentable {

				[LuauField]
				public AbilityInfo Abilities { get; set; } = new AbilityInfo();

				[LuauField]
				public PassiveInfo Passive { get; set; } = new PassiveInfo();

				#region Class Defs
				public class AbilityInfo : LuauRepresentable {

					[LuauField, PluginCustomEnum(ReferencesSonariaConstants = false, Key = "AbilityRegistry", AllowNone = true), Documentation("The name of the ability this creature has. It should be one of the registered abilities.")]
					public string AbilityName { get; set; } = string.Empty;

					[LuauField, PluginNumericLimit(0, 100, IsPercent = true), Documentation("If this ability makes use of RNG, it will index this value to determine the chance to apply in whichever way it sees appropriate.")]
					public double ChanceIfApplicable { get; set; }

					[LuauField, PluginNumericLimit(0, 100, IsPercent = true), Documentation("If this ability is an area of effect, this is its range.")]
					public double RangeIfApplicable { get; set; }

				}

				public class PassiveInfo : LuauRepresentable {

					[LuauField(ValueAsLiteral = "SonariaConstants.AquaAffinity.Terrestrial"), PluginCustomEnum(ReferencesSonariaConstants = true, Key = "AquaAffinity", AllowNone = false), Documentation("The affinity to water that this creature has, which determines where it can live.")]
					public string AquaAffinity { get; set; } = "Terrestrial";

					[LuauField, Documentation("If true, then this creature is is only capable of gliding, not powered flight. Does nothing if the creature is not a flier.")]
					public bool OnlyGlide { get; set; } = false;

					[LuauField, Documentation("If greater than zero, this creature is a passive healer.")]
					public double PassiveHealingRange { get; set; } = 0;

					[LuauField, Documentation("This is the percentage of nearby players' health that increases per second.")]
					public double PassiveHealingPerSecond { get; set; } = 0;

					[LuauField, Documentation("If true, players nearby will only heal if this creature is resting.")]
					public bool PassiveHealWhenRestingOnly { get; set; } = true;

					[LuauField, Documentation("If true, the passive healing only applies to packmates.")]
					public bool IsPassiveHealingPackOnly { get; set; } = true;

					[LuauField, Documentation("If true, players using this species can see a healthbar over other creatures.")]
					public bool SeeHealth { get; set; } = false;
					

				}
				#endregion

			}

			#endregion
		}

		public class MobilityInfo : LuauRepresentable {

			[LuauField]
			public AgilityInfo Agility { get; set; } = new AgilityInfo();

			[LuauField]
			public EnduranceInfo Endurance { get; set; } = new EnduranceInfo();
			
			#region Class Defs
			public class AgilityInfo : LuauRepresentable {

				[LuauField, PluginNumericLimit(0, AdvisedMaximum = 60), Documentation("The speed, measured in studs per second, that this creature moves at whilst walking.")]
				public double WalkSpeed { get; set; } = 10;

				[LuauField, PluginNumericLimit(0, AdvisedMaximum = 150), Documentation("The speed, measured in studs per second, that this creature moves at whilst sprinting.")]
				public double SprintSpeed { get; set; } = 20;

				[LuauField, PluginNumericLimit(0, AdvisedMaximum = 325), Documentation("The speed, measured in studs per second, that this creature can achieve at maximum flight speed.")]
				public double FlySpeed { get; set; } = 0;

				[LuauField, PluginNumericLimit(0, AdvisedMaximum = 50), Documentation("The speed, measured in studs per second, at which this creature swims.")]
				public double SwimSpeed { get; set; } = 10;

				[LuauField, PluginNumericLimit(0, AdvisedMaximum = 100), Documentation("The speed, measured in studs per second, at which this creature swims whilst sprinting in water.")]
				public double SwimFastSpeed { get; set; } = 20;

				[LuauField, PluginNumericLimit(0, 7), Documentation("An arbitrary value representing a predefined turn radius. A radius of 0 provides zero point turning, whereas a radius of 7 provides about a 120 stud wide circle (very large).")]
				public double TurnRadius { get; set; } = 1;
			}

			public class EnduranceInfo : LuauRepresentable {

				[LuauField, PluginNumericLimit(1, AdvisedMaximum = 450), Documentation("This creature's stamina, which is used whilst running or speed-swimming, and in flight.")]
				public double Stamina { get; set; } = 50;

				[LuauField, PluginNumericLimit(1, 1200, AdvisedMinimum = 15, AdvisedMaximum = 240), Documentation("The number of seconds that this creature can stay underwater before they begin to drown.")]
				public double Air { get; set; } = 100;

				[LuauField, PluginNumericLimit(1, AdvisedMaximum = 5), Documentation("The <b>ABSOLUTE AMOUNT</b> of seconds this user regains whilst above water.")]
				public double AirRegenPerSecond { get; set; }

				[LuauField, PluginNumericLimit(1, AdvisedMaximum = 100), Documentation("The <b>ABSOLUTE AMOUNT</b> of stamina that this creature regains per second.")]
				public double StaminaRegenPerSecond { get; set; } = 3;

			}
			#endregion
		}
		#endregion

	}
}
