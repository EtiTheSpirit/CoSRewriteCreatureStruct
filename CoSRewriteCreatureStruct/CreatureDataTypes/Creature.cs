using CoSRewriteCreatureStruct.Attributes;
using CoSRewriteCreatureStruct.CreatureDataTypes;
using CoSRewriteCreatureStruct.PluginMenuTypes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct {
	public class Creature : LuauRepresentable {

		#region Creature Fields

		[LuauField(PluginReflectToProperty = "Name")]
		public string Name { get; set; } = string.Empty;

		[LuauField, CopyFromV0("Description"), PluginStringLimit(AllowEmpty = false), Documentation("The description of this creature, usually provided by its creator to briefly give insight into its backstory.")]
		public string Description { get; set; } = string.Empty;

		[LuauField, CopyFromV0("Concept"), PluginStringLimit(AllowEmpty = false), Documentation("The individual or individuals that worked on this creature in some capacity.")]
		public string Artists { get; set; } = string.Empty;

		[LuauField, PluginStringLimit(AllowEmpty = false), Documentation("What the plural of this creature's name is.")]
		public string PluralName { get; set; } = string.Empty;

		[LuauField, CopyFromV0("ModelID"), PluginNumericLimit(0, true), Documentation("The ID of a published asset where the thumbnail camera is pointing at this creature's head. This is used for its icon.")]
		public double ThumbnailModelID { get; set; } = 0;

		[LuauField, PluginNumericLimit(1, true), Documentation("The version of this creature's data. This should not be manually tampered with unless an upgrade is being performed.")]
		public double DataVersion { get; set; } = 1;

		#endregion

		#region Intrinsic Properties

		[LuauField, Intrinsic(IntrinsicCallback.IsWarden, AffectedBy = new[] { "<b>Creature:</b> Name (must end with \" Warden\")" }), Documentation("Whether or not this creature classifies as a Warden. If this is true, the creature automatically receives the \"Warden's Rage\" effect when it takes damage from any player-caused source.")]
		public bool IsWarden { get; set; } = false;

		[LuauField, Intrinsic(IntrinsicCallback.Gacha, AffectedBy = new[] { "<b>Creature:</b> Specifications.Attributes.ForFunction.ForcedGachaList", "<b>Creature:</b> Specifications.Attributes.ForFunction.InLimitedGacha", "<b>Creature:</b> Specifications.Attributes.ForFunction.HasPaidContentLimits", "<b>Creature:</b> Specifications.Attributes.ForFunction.DeveloperUseOnly", "<b>Intrinsic:</b> MobilityClass" }), Documentation("The gacha this creature is a part of when the game is published.")]
		public string Gacha { get; set; } = string.Empty;

		[LuauField, Intrinsic(IntrinsicCallback.IsFlier, AffectedBy = new[] { "<b>Creature:</b> Presence of CreatureVisuals.Animations.Aerial.FlyIdle", "<b>Creature:</b> Presence of CreatureVisuals.Animations.Aerial.Glide", "<b>Creature:</b> Specifications.MainInfo.Mobility.Agility.FlySpeed &gt; 0" }), Documentation("Whether or not this creature defines all of the data needed to allow it to fly.")]
		public bool IsFlier { get; set; } = false;

		[LuauField, Intrinsic(IntrinsicCallback.OverridesWardensRage, AffectedBy = new[] { "<b>Creature:</b> Presence of Specifications.MainInfo.Stats.DefensiveAilments => WardensRage" }), Documentation("If this is true, this creature - which may not even be a warden - manually defines a Warden's Rage defensive effect. If this creature <i>is</i> a warden, this will override the settings of the effect, such as its duration.")]
		public bool OverridesWardensRage { get; set; } = false;

		[LuauField, Intrinsic(IntrinsicCallback.MobilityClass, AffectedBy = new[] { "<b>Creature:</b> Specifications.MainInfo.Capabilities.Passive.AquaAffinity", "<b>Intrinsic:</b> IsFlier" })]
		public string MobilityClass { get; set; } = string.Empty;

		#endregion

		#region Child Objects

		[LuauField]
		public CreatureSpecifications Specifications { get; set; } = new CreatureSpecifications();

		[LuauField]
		public CreatureVisuals CreatureVisuals { get; set; } = new CreatureVisuals();

		#endregion

	}
}
