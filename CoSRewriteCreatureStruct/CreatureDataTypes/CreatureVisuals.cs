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


			[LuauField("typeof(DEFAULT_PALETTE)", ValueAsLiteral = "table.deepishCopy(DEFAULT_PALETTE)"), CopyFromV0("Palette1", CustomConversionCallback = CopyBehavior.CopyPalette)]
			public Palette Palette1 { get; set; } = new Palette();

			[LuauField("typeof(DEFAULT_PALETTE)", ValueAsLiteral = "table.deepishCopy(DEFAULT_PALETTE)"), CopyFromV0("Palette2", CustomConversionCallback = CopyBehavior.CopyPalette)]
			public Palette Palette2 { get; set; } = new Palette();

		}

		public class BloodDisplayInfo : LuauRepresentable {

			[LuauField, Documentation("<b>NOT TO BE USED FOR PLAYER POLICY.</b> Whether or not this creature has a visual blood effect when damaged.", "Blood Display")]
			public bool HasBlood { get; set; } = true;

			[LuauField, CopyFromV0("BloodColor"), Documentation("The color of this creature's blood. This affects the blood when they are damaged as well as the color of their carcass.", "Blood Display")]
			public Color3 BloodColor { get; set; } = new Color3(117, 0, 0);

			[LuauField, CopyFromV0("BloodColor"), Documentation("The color of this creature's blood droplets. This should usually be the same as the blood color, but in some cases benefits from being a different brightness.", "Blood Display")]
			public Color3 BloodDropColor { get; set; } = new Color3(86, 36, 36);

			[LuauField("Enum.Material", ValueAsLiteral = "Enum.Material.Plastic"), PluginCustomEnum(IsRobloxEnum = true, Key = "Material"), CopyFromV0("BloodMaterial"), Documentation("The Roblox material that the blood renders as.", "Blood Display")]
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

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Bite", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature when doing their main melee action.", "Action Animations")]
				public string Bite { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Aggression", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature when showing off their aggression.", "Action Animations")]
				public string Aggression { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Cower", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature when showing off their fear.", "Action Animations")]
				public string Cower { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Lay", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature laying on the ground.", "Action Animations")]
				public string Lay { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Sit", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature sitting on the ground.", "Action Animations")]
				public string Sit { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Eat", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature eating.", "Action Animations")]
				public string Eat { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Drink", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature drinking.", "Action Animations")]
				public string Drink { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Mud", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature rolling around in mud to cover themselves.", "Action Animations")]
				public string MudRoll { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("WallGrab", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature grabbing onto a wall. This is intended for fliers that can grab on to surfaces.", "Action Animations")]
				public string WallGrab { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("CustomizePose", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature for its preview card and in the customizer.", "Action Animations")]
				public string CustomizationPose { get; set; } = string.Empty;

			}

			public class AerialInfo : LuauRepresentable {

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Dive", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature when they are in an aerial dive.", "Aerial Animations")]
				public string Dive { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Flap", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature when they do a single flap of their wings, intended for gliders.", "Aerial Animations")]
				public string Flap { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("FlyForward", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature when manually applying force to fly forward.", "Aerial Animations")]
				public string FlyForward { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("FlyIdle", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature when flying in place.", "Aerial Animations")]
				public string FlyIdle { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Glide", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature when gliding.", "Aerial Animations")]
				public string Glide { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), Documentation("The animation of this creature when it takes off from the ground.", "Aerial Animations")]
				public string Takeoff { get; set; } = string.Empty;

			}

			public class AquaticInfo : LuauRepresentable {

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Swim", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature when casually swimming through water. This should probably still be defined for land creatures.", "Aquatic Animations")]
				public string Swim { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("SwimFast", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature when quickly swimming through water. This should probably still be defined for land creatures.", "Aquatic Animations")]
				public string SwimFast { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("SwimIdle", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature when not moving and suspended in water. This should probably still be defined for land creatures.", "Aquatic Animations")]
				public string SwimIdle { get; set; } = string.Empty;

			}

			public class LandInfo : LuauRepresentable {

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Idle", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature when they are not moving.", "Land Animations")]
				public string Idle { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Walk", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature when they are walking on land. <b>This does not function for swimming, but should probably still be defined for sea creatures.</b>", "Land Animations")]
				public string Walk { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), CopyFromV0("Run", CustomConversionCallback = CopyBehavior.GetAnimationID), Documentation("The animation of this creature when they are sprinting on land. <b>This does not function for swimming fast, but should probably still be defined for sea creatures.</b>", "Land Animations")]
				public string Run { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), Documentation("The animation of this creature when they jump.", "Land Animations")]
				public string Jump { get; set; } = string.Empty;

				[LuauField("Animation?", ValueAsLiteral = "(string.Empty::any)"), PluginStringLimit(true, true), Documentation("The animation of this creature when they are falling.", "Land Animations")]
				public string Fall { get; set; } = string.Empty;

			}

			public class SettingsInfo : LuauRepresentable {

				[LuauField, PluginNumericLimit(0, AdvisedMaximum = 3), CopyFromV0("WalkAnimationSpeed"), Documentation("The base speed multiplier for the walk animation, which can be used to sync it with the world.", "Animation Settings")]
				public double WalkAnimationSpeed { get; set; } = 1;

				[LuauField, PluginNumericLimit(0, AdvisedMaximum = 3), CopyFromV0("RunAnimationSpeed"), Documentation("The base speed multiplier for the run animation, which can be used to sync it with the world.", "Animation Settings")]
				public double RunAnimationSpeed { get; set; } = 1;

			}

			#endregion

		}

		public class SoundsInfo : LuauRepresentable {

			[LuauField("typeof(DEFAULT_SOUND)", ValueAsLiteral = "table.shallowCopy(DEFAULT_SOUND)"), CopyFromV0("1", Container = "Sounds", CustomConversionCallback = CopyBehavior.CreateSound)]
			public SoundInstance Broadcast { get; set; } = new SoundInstance();

			[LuauField("typeof(DEFAULT_SOUND)", ValueAsLiteral = "table.shallowCopy(DEFAULT_SOUND)"), CopyFromV0("2", Container = "Sounds", CustomConversionCallback = CopyBehavior.CreateSound)]
			public SoundInstance Friendly { get; set; } = new SoundInstance();

			[LuauField("typeof(DEFAULT_SOUND)", ValueAsLiteral = "table.shallowCopy(DEFAULT_SOUND)"), CopyFromV0("3", Container = "Sounds", CustomConversionCallback = CopyBehavior.CreateSound)]
			public SoundInstance Aggressive { get; set; } = new SoundInstance();

			[LuauField("typeof(DEFAULT_SOUND)", ValueAsLiteral = "table.shallowCopy(DEFAULT_SOUND)"), CopyFromV0("4", Container = "Sounds", CustomConversionCallback = CopyBehavior.CreateSound)]
			public SoundInstance Speak { get; set; } = new SoundInstance();


			public class SoundInstance : LuauRepresentable {

				[LuauField, PluginStringLimit(false, true, false), Documentation("The ID of this sound. Ensure this ID is owned by the group.", "Sound")]
				public string ID { get; set; } = string.Empty;

				[LuauField, PluginNumericLimit(1, 10000, false, AdvisedMinimum = 50, AdvisedMaximum = 700), Documentation("The distance this sound can travel. It should generally be a high number (above 200) even for small creatures.", "Sound")]
				public double Range { get; set; }

				[LuauField, PluginNumericLimit(0.01, 10, false, AdvisedMaximum = 2), Documentation("The volume of this sound. <b>Volumes larger than 1 will attenuate other sounds (make them quieter) rather than making this louder.</b>", "Sound")]
				public double Volume { get; set; }

				[LuauField, PluginNumericLimit(0.05, 30, false, AdvisedMinimum = 0.2, AdvisedMaximum = 7), Documentation("The base pitch of this sound.", "Sound")]
				public double Pitch { get; set; }

			}
		}
		#endregion

	}
}
