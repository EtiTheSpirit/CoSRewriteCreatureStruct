using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.Attributes {

	public enum CopyBehavior {

		None,

		CloneObject,

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
	/// Unique display behaviors for plugin values. This can be used to disable some properties that stop being applicable when others are set.
	/// </summary>
	public enum SpecialDisplayBehavior {



	}

	public enum PercentType {

		NotPercentage,

		Scale0To100,

		Scale0To1,

	}

}
