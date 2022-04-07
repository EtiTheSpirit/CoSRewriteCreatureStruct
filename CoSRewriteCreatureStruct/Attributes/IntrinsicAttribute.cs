using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.Attributes {

	/// <summary>
	/// Signifies that the given field is an intrinsic property. This can be used to display default values that come as the result
	/// of some game code rather than as a literal value of the creature.
	/// </summary>
	[AttributeUsage(AttributeTargets.Property, AllowMultiple = false, Inherited = true)]
	public class IntrinsicAttribute : Attribute {

		// TODO: Figure out how to include code. Should it be by some named reference, or by including it in another data package?

	}
}
