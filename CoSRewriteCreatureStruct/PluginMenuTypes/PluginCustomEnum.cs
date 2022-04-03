#pragma warning disable CS8618
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.PluginMenuTypes {


	[AttributeUsage(AttributeTargets.Property, AllowMultiple = true, Inherited = true)]
	public class PluginCustomEnum : PluginMenuLimiterAttribute {

		/// <summary>
		/// If <see langword="true"/>, this enum will sample from a list of elements in some SonariaConstants value. If <see langword="false"/>, it samples from a registry.
		/// </summary>
		public bool ReferencesSonariaConstants { get; set; }

		/// <summary>
		/// If <see langword="true"/>, this enum is a representation of a Roblox enum. The key should be the enum key, such that Enum[key] can be resolved.
		/// </summary>
		public bool IsRobloxEnum { get; set; }

		/// <summary>
		/// The key for this dropdown menu. If <see cref="ReferencesSonariaConstants"/> is <see langword="true"/>, this is the key in <c>SonariaConstants</c> (may include dots).
		/// If <see cref="ReferencesSonariaConstants"/> is <see langword="false"/>, this is the name of a registry, from which <c>ReplicatedStorage.CoreData.Registries</c> will be searched.
		/// </summary>
		public string Key { get; set; }

		/// <summary>
		/// If true, a "None" option is included in the dropdown menu.
		/// </summary>
		public bool AllowNone { get; set; }

		public PluginCustomEnum(bool consts, string key, bool allowNone) {
			ReferencesSonariaConstants = consts;
			Key = key;
			AllowNone = allowNone;
		}

		public PluginCustomEnum() { }

		public override string? ValidateData() => null;

		public override StringKeyTable ToLuaTable() {
			StringKeyTable tbl = new StringKeyTable();
			tbl.Add("LimitType", "CustomEnum");
			tbl.Add("IsSonariaConstant", ReferencesSonariaConstants);
			tbl.Add("IsRobloxEnum", IsRobloxEnum);
			tbl.Add("AllowNone", AllowNone);
			tbl.Add("Key", Key);
			return tbl;
			/*
			if (includeDocsLiteral == null) {
				return $"{{LimitType=\"CustomEnum\"; IsSonariaConstant={ReferencesSonariaConstants.ToString().ToLower()}; IsRobloxEnum={IsRobloxEnum.ToString().ToLower()}; AllowNone={AllowNone.ToString().ToLower()}; Key=\"{Key}\"}}";
			} else {
				return $"{{LimitType=\"CustomEnum\"; IsSonariaConstant={ReferencesSonariaConstants.ToString().ToLower()}; IsRobloxEnum={IsRobloxEnum.ToString().ToLower()}; AllowNone={AllowNone.ToString().ToLower()}; Key=\"{Key}\"; Documentation = {includeDocsLiteral}}}";
			}
			*/
		}
	}
}
