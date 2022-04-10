using CoSRewriteCreatureStruct.Attributes;
using CoSRewriteCreatureStruct.PluginMenuTypes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.CreatureDataTypes {

	public class Palette : LuauRepresentable {

		[LuauField(RuntimeOnly = true)]
		public double Index { get; set; }

		[LuauField, Documentation("Whether or not this palette shows in the customizer if it is unlocked.", "Palette Usage")]
		public bool Enabled { get; set; } = false;

		[LuauField, Documentation("If not empty, this contains the instructions on how to unlock this palette.", "Palette Usage")]
		public string UnlockRequirement { get; set; } = string.Empty;

		[LuauField, PluginNumericLimit(1, 12, true), Documentation("The amount of colors in this palette that are used.", "Palette Usage")]
		public double NumberOfColorsToUse { get; set; } = 12;

		[LuauField]
		public ColorsInfo Colors { get; set; } = new ColorsInfo();


		public class ColorsInfo : LuauRepresentable {

			[LuauField]
			public DumbColorSequence Color01 { get; set; } = new DumbColorSequence();

			[LuauField]
			public DumbColorSequence Color02 { get; set; } = new DumbColorSequence();

			[LuauField]
			public DumbColorSequence Color03 { get; set; } = new DumbColorSequence();

			[LuauField]
			public DumbColorSequence Color04 { get; set; } = new DumbColorSequence();

			[LuauField]
			public DumbColorSequence Color05 { get; set; } = new DumbColorSequence();

			[LuauField]
			public DumbColorSequence Color06 { get; set; } = new DumbColorSequence();

			[LuauField]
			public DumbColorSequence Color07 { get; set; } = new DumbColorSequence();

			[LuauField]
			public DumbColorSequence Color08 { get; set; } = new DumbColorSequence();

			[LuauField]
			public DumbColorSequence Color09 { get; set; } = new DumbColorSequence();

			[LuauField]
			public DumbColorSequence Color10 { get; set; } = new DumbColorSequence();

			[LuauField]
			public DumbColorSequence Color11 { get; set; } = new DumbColorSequence();

			[LuauField]
			public DumbColorSequence Color12 { get; set; } = new DumbColorSequence();

		}

	}
}
