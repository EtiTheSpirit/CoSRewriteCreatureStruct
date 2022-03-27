using CoSRewriteCreatureStruct.Attributes;
using CoSRewriteCreatureStruct.PluginMenuTypes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.CreatureDataTypes {
	public class CreatureVisuals : LuauRepresentable {

		[LuauField]
		public ModelsInfo Models { get; set; } = new ModelsInfo();

		[LuauField]
		public PalettesInfo Palettes { get; set; } = new PalettesInfo();

		[LuauField]
		public BloodDisplayInfo BloodDisplay { get; set; } = new BloodDisplayInfo();

		[LuauField]
		public AnimationsInfo Animations { get; set; } = new AnimationsInfo();

		#region Class Defs

		public class ModelsInfo : LuauRepresentable {

			[LuauField("Model?", RuntimeOnly = true, ValueAsLiteral = "NULL(\"Model\")")]
			public Instance? Child { get; set; }

			[LuauField("Model?", RuntimeOnly = true, ValueAsLiteral = "NULL(\"Model\")")]
			public Instance? Teen { get; set; }

			[LuauField("Model?", RuntimeOnly = true, ValueAsLiteral = "NULL(\"Model\")")]
			public Instance? Adult { get; set; }

			[LuauField("Model?", RuntimeOnly = true, ValueAsLiteral = "NULL(\"Model\")")]
			public Instance? AdultCustomizer { get; set; }

		}

		public class PalettesInfo : LuauRepresentable {


			[LuauField("typeof(DEFAULT_PALETTE)", ValueAsLiteral = "table.shallowCopy(DEFAULT_PALETTE)")]
			public Instance? Palette1 { get; set; }

			[LuauField("typeof(DEFAULT_PALETTE)", ValueAsLiteral = "table.shallowCopy(DEFAULT_PALETTE)")]
			public Instance? Palette2 { get; set; }

		}

		public class BloodDisplayInfo : LuauRepresentable {

			[LuauField]
			public bool HasBlood { get; set; } = true;

			[LuauField]
			public Color3 BloodColor { get; set; } = new Color3(117, 0, 0);

			[LuauField]
			public Color3 BloodDropColor { get; set; } = new Color3(86, 36, 36);

			[LuauField("Enum.Material", ValueAsLiteral = "Enum.Material.Plastic"), PluginCustomEnum(IsRobloxEnum = true, Key = "Material")]
			public string BloodMaterial { get; set; } = "Plastic";

		}

		public class AnimationsInfo : LuauRepresentable {

			[LuauField]
			public ActionsInfo Actions { get; set; } = new ActionsInfo();

			[LuauField]
			public AerialInfo Aerial { get; set; } = new AerialInfo();

			[LuauField]
			public AquaticInfo Aquatic { get; set; } = new AquaticInfo();

			[LuauField]
			public LandInfo Land { get; set; } = new LandInfo();

			[LuauField]
			public SettingsInfo Settings { get; set; } = new SettingsInfo();

			#region Class Defs

			public class ActionsInfo : LuauRepresentable {

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Bite { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Aggression { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Cower { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Lay { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Sit { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Eat { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Drink { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string MudRoll { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string WallGrab { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string CustomizationPose { get; set; } = string.Empty;

			}

			public class AerialInfo : LuauRepresentable {

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Dive { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Flap { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string FlyForward { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string FlyIdle { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Glide { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Takeoff { get; set; } = string.Empty;

			}

			public class AquaticInfo : LuauRepresentable {

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Swim { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string SwimFast { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string SwimIdle { get; set; } = string.Empty;

			}

			public class LandInfo : LuauRepresentable {

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Idle { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Walk { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Run { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Jump { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "NULL(\"Animation\")"), PluginStringLimit(true, true)]
				public string Fall { get; set; } = string.Empty;

			}

			public class SettingsInfo : LuauRepresentable {

				[LuauField, PluginNumericLimit(0, AdvisedMaximum = 3)]
				public double WalkAnimationSpeed { get; set; } = 1;

				[LuauField, PluginNumericLimit(0, AdvisedMaximum = 3)]
				public double RunAnimationSpeed { get; set; } = 1;

			}

			#endregion

		}

		#endregion

	}
}
