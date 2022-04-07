using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.CreatureDataTypes {
	public class StatLimit {

		/// <summary>
		/// The amount that this requires the effect to at least be equal to when applying.<para/>
		/// A value of 0 means to not use a minimum.
		/// </summary>
		public double Min { get; set; }

		/// <summary>
		/// The amount that this can cause the effect to stack up to. If the effect has a higher stack, then this effect will do nothing.<para/>
		/// A value of 0 means to not use a maximum.
		/// </summary>
		public double Max { get; set; }

		/// <summary>
		/// Create a new stat limit. A value of 0 can go in either slot (even if max &gt; min) which denotes to not use that limit.
		/// </summary>
		/// <param name="min">The amount of the effect to at least apply, or 0 to disable this side of the limit.</param>
		/// <param name="max">The amount of the effect that this can get the stack up to, or 0 to disable this side of the limit.</param>
		public StatLimit(double min = 0, double max = 0) {
			Min = min;
			Max = max;
		}

		public override string ToString() {
			return $"Vector2.new({Min}, {Max})";
		}

	}
}
