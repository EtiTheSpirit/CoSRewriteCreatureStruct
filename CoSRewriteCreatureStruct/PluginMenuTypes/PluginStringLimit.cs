using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.PluginMenuTypes {


	[AttributeUsage(AttributeTargets.Property, AllowMultiple = true, Inherited = true)]
	public class PluginStringLimit : PluginMenuLimiterAttribute {

		/// <summary>
		/// Whether or not an empty string is considered valid input.
		/// </summary>
		public bool AllowEmpty { get; set; }

		/// <summary>
		/// Whether or not this string represents a roblox asset ID.
		/// </summary>
		public bool IsRobloxAsset { get; set; }

		/// <summary>
		/// Whether or not this classifies as a list. If this is true, it will enable the plugin to separate entries with the semicolon.
		/// Semicolons can be escaped with backslashes.
		/// </summary>
		public bool IsList { get; set; }
		
		public PluginStringLimit(bool allowEmpty = false, bool isRobloxAsset = false, bool isList = false) {
			AllowEmpty = allowEmpty;
			IsRobloxAsset = isRobloxAsset;
			IsList = isList;
		}

		public override string? ValidateData() => null;

		public override StringKeyTable ToLuaTable() {
			StringKeyTable tbl = new StringKeyTable();
			tbl.Add("LimitType", "StringLimit");
			tbl.Add("IsRobloxAsset", IsRobloxAsset);
			tbl.Add("AllowEmpty", AllowEmpty);
			tbl.Add("IsList", IsList);
			return tbl;
			/*
			if (includeDocsLiteral == null) {
				return $"{{LimitType=\"StringLimit\"; IsRobloxAsset={IsRobloxAsset.ToString().ToLower()}; AllowEmpty={AllowEmpty.ToString().ToLower()}}}";
			} else {
				return $"{{LimitType=\"StringLimit\"; IsRobloxAsset={IsRobloxAsset.ToString().ToLower()}; AllowEmpty={AllowEmpty.ToString().ToLower()}; Documentation = {includeDocsLiteral}}}";
			}
			*/
		}
	}
}
