using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.Attributes {

	/// <summary>
	/// If applied to a property, it denotes it as represented by an instance. This is used for the type created by the character controller
	/// which uses this type to determine where data is located and in what attributes.<br/>
	/// <br/>
	/// <strong>This MUST go on a property whose type extends <see cref="LuauRepresentable"/>.</strong>
	/// </summary>
	[AttributeUsage(AttributeTargets.Property)]
	public class RepresentedByInstanceAttribute : Attribute { }
}
