using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.PluginMenuTypes {
	public class PluginStringLimit : PluginMenuLimiterAttribute {

		/// <summary>
		/// Whether or not an empty string is considered valid input.
		/// </summary>
		public bool AllowEmpty { get; set; }

		/// <summary>
		/// Whether or not this string represents a roblox asset ID.
		/// </summary>
		public bool IsRobloxAsset { get; set; }
		
		public PluginStringLimit(bool allowEmpty = false, bool isRobloxAsset = false) {
			AllowEmpty = allowEmpty;
			IsRobloxAsset = isRobloxAsset;
		}

		public override string? ValidateData() => null;

		public override string ToLuaTable() {
			return $"{{LimitType=\"StringLimit\"; IsRobloxAsset={IsRobloxAsset.ToString().ToLower()}; AllowEmpty={AllowEmpty.ToString().ToLower()}}}";
		}
	}
}
