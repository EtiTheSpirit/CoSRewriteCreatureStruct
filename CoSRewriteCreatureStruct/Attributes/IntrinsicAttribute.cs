using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.Attributes {

	/// <summary>
	/// Signifies that the given field is an intrinsic property. This can be used to display default values that come as the result
	/// of some game code rather than as a literal value of the creature.
	/// </summary>
	[AttributeUsage(AttributeTargets.Property, AllowMultiple = false, Inherited = true)]
	public class IntrinsicAttribute : Attribute {

		/// <summary>
		/// The function this uses to determine this field's displayed value.
		/// </summary>
		public IntrinsicCallback Callback { get; }

		/// <summary>
		/// What affects this intrinsic property? This is for humans to read and is not used by code.
		/// </summary>
		public string[]? AffectedBy { get; set; }

		public IntrinsicAttribute(IntrinsicCallback callback) {
			Callback = callback;
		}

	}
}
