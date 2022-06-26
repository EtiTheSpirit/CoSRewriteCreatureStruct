using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.Attributes {

	[AttributeUsage(AttributeTargets.Field | AttributeTargets.Property, AllowMultiple = false, Inherited = true)]
	public class DocumentationAttribute : Attribute {

		/// <summary>
		/// The documentation used for this element in the plugin.
		/// </summary>
		public string Documentation { get; }

		/// <summary>
		/// The category of this property. This is overridden by <see cref="IntrinsicAttribute"/>, if said attribute is present, such that it is always <c>"Intrinsic"</c>.
		/// </summary>
		public string? Category { get; }

		/// <summary>
		/// Create a new attribute storing documentation for this element in the plugin. Supports roblox's rich text.
		/// </summary>
		/// <param name="documentation"></param>
		public DocumentationAttribute(string documentation, string? category = null) {
			Documentation = documentation;
			Category = category;
		}

	}
}
