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

	public enum PercentType {

		NotPercentage,

		Scale0To100,

		Scale0To1,

	}

}
