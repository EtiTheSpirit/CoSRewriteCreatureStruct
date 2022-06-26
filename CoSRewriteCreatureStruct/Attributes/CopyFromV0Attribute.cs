using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.Attributes {

	/// <summary>
	/// Represents the value to copy from creature V0, which is the live game before rewrite releases.
	/// If defined, the translator portion of the plugin will attempt to find and copy the value into the field this is attached to.<para/>
	/// This searches the root of the creature first, then the data folder.
	/// </summary>
	[AttributeUsage(AttributeTargets.Property)]
	public class CopyFromV0Attribute : Attribute {

		/// <summary>
		/// The name of the value object to search for. May be null if this exclusively uses custom code.
		/// </summary>
		public string? ValueName { get; }

		/// <summary>
		/// If true, then this should be on a boolean property, from which true/false will be set based on whether or not the object exists.
		/// </summary>
		public bool ByPresence { get; }

		/// <summary>
		/// The special behavior for copying the data over, used for specific one-off cases.
		/// </summary>
		public CopyBehavior CustomConversionCallback { get; set; } = CopyBehavior.None;

		/// <summary>
		/// How this value, as a percentage, should be handled.
		/// </summary>
		public PercentType Percentage { get; set; } = PercentType.NotPercentage;

		/// <summary>
		/// The container to search for the object in. Can be an empty string to only search the root, or null to search everywhere.
		/// </summary>
		public string? Container { get; set; }

		/// <param name="valueName">The name of the value object to search for. May be null if this exclusively uses custom code.</param>
		/// <param name="byPresence">If true, then this should be on a boolean property, from which true/false will be set based on whether or not the object exists.</param>
		public CopyFromV0Attribute(string? valueName, bool byPresence = false) {
			ValueName = valueName;
			ByPresence = byPresence;
		}

		public void AppendToLuaTable(StringKeyTable tbl) {
			tbl.Add("OldName", ValueName);
			tbl.Add("ByPresence", ByPresence);
			if (Container != null) {
				tbl.Add("ContainerName", Container);
			}
			if (CustomConversionCallback != CopyBehavior.None) {
				tbl.Add("CustomConverter", CustomConversionCallback.ToString());
			}
		}

	}
}
