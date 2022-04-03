using CoSRewriteCreatureStruct.PluginMenuTypes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.Attributes {

	[AttributeUsage(AttributeTargets.Property, AllowMultiple = false, Inherited = true)]
	public class LuauFieldAttribute : Attribute {

		/// <summary>
		/// If this is a Luau primitive or Roblox type, this is the type. Should be <see langword="null"/> otherwise.
		/// </summary>
		public string? LuauType { get; } = null;
		
		/// <summary>
		/// Whether or not this field is defined during runtime. If true, this will not be included in the template data for the plugin,
		/// but will be included in the type definition.
		/// </summary>
		public bool RuntimeOnly { get; set; } = false;

		/// <summary>
		/// If defined, the value of this field will be discarded and instead this string will be pasted as a Lua literal.
		/// This makes it possible to reference tables or other variables in the generated script.
		/// </summary>
		public string? ValueAsLiteral { get; set; }

		/// <summary>
		/// If defined, the name of this field will be discarded and instead this string will be pasted as a Lua literal for the lvalue.
		/// This makes it possible to reference tables or other variables in the generated script.
		/// </summary>
		public string? KeyAsLiteral { get; set; }

		/// <summary>
		/// The category that this field is a part of in the custom properties browser. Null for default category.
		/// </summary>
		public string? Category { get; set; }

		/// <summary>
		/// Create a new packet of information for a Luau field.
		/// </summary>
		/// <param name="explicitCastToType"></param>
		public LuauFieldAttribute(string? explicitCastToType = null) {
			LuauType = explicitCastToType;
		}

	}
}
