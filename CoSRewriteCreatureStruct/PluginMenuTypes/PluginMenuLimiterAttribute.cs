using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.PluginMenuTypes {

	[AttributeUsage(AttributeTargets.Property, AllowMultiple = false, Inherited = true)]
	public abstract class PluginMenuLimiterAttribute : Attribute {

		/// <summary>
		/// Verifies that the information of this validator is correct. This should return an error message if the data is incorrect,
		/// or <see langword="null"/> if it is acceptable.
		/// </summary>
		public abstract string? ValidateData();

		/// <summary>
		/// Converts this to a lua table as a string.
		/// </summary>
		/// <param name="premadeDefault">The default value already formatted as string to put into the table.</param>
		/// <returns></returns>
		public abstract StringKeyTable ToLuaTable();

	}
}
