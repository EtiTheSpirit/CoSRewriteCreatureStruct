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

		[LuauField]
		public SoundsInfo Sounds { get; set; } = new SoundsInfo();

		#region Class Defs

		public class ModelsInfo : LuauRepresentable {

			[LuauField("Model", RuntimeOnly = true), CopyFromV0("Child", CustomConversionCallback = CopyBehavior.CopyCharacterModel)]
			public Instance? Child { get; set; }

			[LuauField("Model", RuntimeOnly = true), CopyFromV0("Teen", CustomConversionCallback = CopyBehavior.CopyCharacterModel)]
			public Instance? Teen { get; set; }

			[LuauField("Model", RuntimeOnly = true), CopyFromV0("Adult", CustomConversionCallback = CopyBehavior.CopyCharacterModel)]
			public Instance? Adult { get; set; }

			[LuauField("Model", RuntimeOnly = true), CopyFromV0("AdultCustomizer", CustomConversionCallback = CopyBehavior.CopyCharacterModel)]
			public Instance? AdultCustomizer { get; set; }

		}

		public class PalettesInfo : LuauRepresentable {


			[LuauField("typeof(DEFAULT_PALETTE)", ValueAsLiteral = "table.shallowCopy(DEFAULT_PALETTE)"), CopyFromV0("Palette1", CustomConversionCallback = CopyBehavior.CopyPalette)]
			public Instance? Palette1 { get; set; }

			[LuauField("typeof(DEFAULT_PALETTE)", ValueAsLiteral = "table.shallowCopy(DEFAULT_PALETTE)"), CopyFromV0("Palette2", CustomConversionCallback = CopyBehavior.CopyPalette)]
			public Instance? Palette2 { get; set; }

		}

		public class BloodDisplayInfo : LuauRepresentable {

			[LuauField, Documentation("<b>NOT TO BE USED FOR PLAYER POLICY.</b> Whether or not this creature has a visual blood effect when damaged.")]
			public bool HasBlood { get; set; } = true;

			[LuauField, CopyFromV0("BloodColor"), Documentation("The color of this creature's blood. This affects the blood when they are damaged as well as the color of their carcass.")]
			public Color3 BloodColor { get; set; } = new Color3(117, 0, 0);

			[LuauField, CopyFromV0("BloodColor"), Documentation("The color of this creature's blood droplets. This should usually be the same as the blood color, but in some cases benefits from being a different brightness.")]
			public Color3 BloodDropColor { get; set; } = new Color3(86, 36, 36);

			[LuauField("Enum.Material", ValueAsLiteral = "Enum.Material.Plastic"), PluginCustomEnum(IsRobloxEnum = true, Key = "Material"), CopyFromV0("BloodMaterial"), Documentation("The Roblox material that the blood renders as.")]
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

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Bite", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string Bite { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Aggression", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string Aggression { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Cower", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string Cower { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Lay", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string Lay { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Sit", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string Sit { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Eat", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string Eat { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Drink", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string Drink { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Mud", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string MudRoll { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("WallGrab", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string WallGrab { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("CustomizePose", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string CustomizationPose { get; set; } = string.Empty;

			}

			public class AerialInfo : LuauRepresentable {

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Dive", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string Dive { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Flap", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string Flap { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("FlyForward", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string FlyForward { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("FlyIdle", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string FlyIdle { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Glide", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string Glide { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true)]
				public string Takeoff { get; set; } = string.Empty;

			}

			public class AquaticInfo : LuauRepresentable {

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Swim", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string Swim { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("SwimFast", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string SwimFast { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("SwimIdle", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string SwimIdle { get; set; } = string.Empty;

			}

			public class LandInfo : LuauRepresentable {

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Idle", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string Idle { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Walk", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string Walk { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Run", CustomConversionCallback = CopyBehavior.GetAnimationID)]
				public string Run { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true)]
				public string Jump { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true)]
				public string Fall { get; set; } = string.Empty;

			}

			public class SettingsInfo : LuauRepresentable {

				[LuauField, PluginNumericLimit(0, AdvisedMaximum = 3), CopyFromV0("WalkAnimationSpeed")]
				public double WalkAnimationSpeed { get; set; } = 1;

				[LuauField, PluginNumericLimit(0, AdvisedMaximum = 3), CopyFromV0("RunAnimationSpeed")]
				public double RunAnimationSpeed { get; set; } = 1;

			}

			#endregion

		}

		public class SoundsInfo : LuauRepresentable {

			[LuauField("typeof(DEFAULT_SOUND)", ValueAsLiteral = "table.shallowCopy(DEFAULT_SOUND)"), CopyFromV0("1", Container = "Sounds", CustomConversionCallback = CopyBehavior.CreateSound)]
			public Instance? Broadcast { get; set; }

			[LuauField("typeof(DEFAULT_SOUND)", ValueAsLiteral = "table.shallowCopy(DEFAULT_SOUND)"), CopyFromV0("2", Container = "Sounds", CustomConversionCallback = CopyBehavior.CreateSound)]
			public Instance? Friendly { get; set; }

			[LuauField("typeof(DEFAULT_SOUND)", ValueAsLiteral = "table.shallowCopy(DEFAULT_SOUND)"), CopyFromV0("3", Container = "Sounds", CustomConversionCallback = CopyBehavior.CreateSound)]
			public Instance? Aggressive { get; set; }

			[LuauField("typeof(DEFAULT_SOUND)", ValueAsLiteral = "table.shallowCopy(DEFAULT_SOUND)"), CopyFromV0("4", Container = "Sounds", CustomConversionCallback = CopyBehavior.CreateSound)]
			public Instance? Speak { get; set; }

		}

		#endregion

	}
}
