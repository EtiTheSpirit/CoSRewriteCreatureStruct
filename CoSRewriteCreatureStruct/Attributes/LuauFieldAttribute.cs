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
		/// Whether or not this field (in Luau) only gets defined during runtime. 
		/// If true, this will <em>not</em> be included in the template data for the plugin,
		/// but will be included in the type definition.
		/// </summary>
		public bool RuntimeOnly { get; set; } = false;

		/// <summary>
		/// The opposite of <see cref="RuntimeOnly"/>. If true, this is only visible to the plugin and not the game.
		/// </summary>
		public bool PluginOnly { get; set; } = false;

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
		/// A temporary solution that only applies when <see cref="PluginOnly"/> is <see langword="true"/>. If this is set, the field in question
		/// will reflect to a property of the object with this name. While for the forseeable future the objects will only have the Name property,
		/// this is being left open ended.
		/// </summary>
		public string? PluginReflectToProperty { get; set; }

		/// <summary>
		/// If defined, this will override the validator of this field such that it uses custom lua code.
		/// It <strong>is</strong> possible for a built in validator (like <see cref="PluginNumericLimit"/>) to still be defined.
		/// If this is the case, then the message returned by the validator will only be used if the validator's error level is
		/// greater than to the error level of the built in limit. If it is equal, the validator's message will be appended to the
		/// end of the default limit's message.
		/// </summary>
		public ValidatorBehavior CustomValidationBehavior { get; set; } = ValidatorBehavior.None;

		/// <summary>
		/// Create a new packet of information for a Luau field.
		/// </summary>
		/// <param name="explicitCastToType"></param>
		public LuauFieldAttribute(string? explicitCastToType = null) {
			LuauType = explicitCastToType;
		}

	}
}
