using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.Attributes {

	/// <summary>
	/// Predefined behaviors to copy from old creature data to new creature data.
	/// </summary>
	public enum CopyBehavior {

		None,

		CopyPalette,

		CreateSound,

		CalcTimeToGrow,

		ConvHealRate, // 15s

		GetBreathIfString, // some (very very old) creatures have "Breath" as a mockup for the air stat.

		GetAnimationID,

		CopyCharacterModel,

		GetAquaAffinity,

		GetStudTurnRadius,

		ConvFlySpeed,

		GetDegradedSpeedForClass,

		GetHealRadiusValuesForSpecies
	}

	/// <summary>
	/// Behavior for when a field is validated or displayed, which can be used to implement custom limits or toggle settings on and off
	/// with context of other settings (such as graying out settings that are not applicable due to another being a given value)
	/// </summary>
	public enum ValidatorBehavior {

		None,

		ManageGachaAttributes,

		ManageAquaAffinity,

		HealRadiusValues,

		GroupRankSelector,

		HolidayCurrency,

		UniversalResistances,

		StatusEffect,

		BoneBreakLigamentTear,

		DefensiveEffectApplyExtension

	}

	/// <summary>
	/// The way a percentage is represented.
	/// </summary>
	public enum PercentType {

		/// <summary>
		/// This value is not a percentage.
		/// </summary>
		NotPercentage,

		/// <summary>
		/// This value should translated from a scale of 0 to 100.
		/// </summary>
		Scale0To100,

		/// <summary>
		/// This value should be translated from a scale of 0 to 1.
		/// </summary>
		Scale0To1,

	}

	/// <summary>
	/// The method in which an intrinsic property gets its value
	/// </summary>
	public enum IntrinsicCallback {

		Gacha,

		IsFlier,

		IsWarden,

		OverridesWardensRage,

		MobilityClass

	}

}
