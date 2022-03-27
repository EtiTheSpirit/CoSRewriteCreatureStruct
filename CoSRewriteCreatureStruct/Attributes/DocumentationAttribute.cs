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
		/// Create a new attribute storing documentation for this element in the plugin. Supports roblox's rich text.
		/// </summary>
		/// <param name="documentation"></param>
		public DocumentationAttribute(string documentation) {
			Documentation = documentation;
		}

	}
}
