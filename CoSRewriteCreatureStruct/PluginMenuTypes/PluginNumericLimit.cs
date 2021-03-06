using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.PluginMenuTypes {


	[AttributeUsage(AttributeTargets.Property, AllowMultiple = true, Inherited = true)]
	public class PluginNumericLimit : PluginMenuLimiterAttribute {

		/// <summary>
		/// The minimum value that can be put in before the plugin raises an error.
		/// </summary>
		public double AbsoluteMinimum { get; set; } = double.NegativeInfinity;

		/// <summary>
		/// The maximum value that can be put in before the plugin raises an error.
		/// </summary>
		public double AbsoluteMaximum { get; set; } = double.PositiveInfinity;

		/// <summary>
		/// The minimum value that can be put in before the plugin raises an advisory claiming the value may be incorrect.
		/// </summary>
		public double AdvisedMinimum { get; set; }

		/// <summary>
		/// The maximum value that can be put in before the plugin raises an advisory claiming the value may be incorrect.
		/// </summary>
		public double AdvisedMaximum { get; set; }

		/// <summary>
		/// Whether or not to require this value to be an integer.
		/// </summary>
		public bool IsInteger { get; set; }

		/// <summary>
		/// Whether or not this value is a percentage, which for ease of access to non-programmers, is in the range of 0 to 100
		/// instead of 0 to 1. Inputting a value between 0 and 1 will raise a warning to remind any programmers of this change.
		/// </summary>
		public bool IsPercent { get; set; }

		/// <summary>
		/// If <see langword="true"/>, then the minimum value is inclusive, so a value equal to the minimum is acceptible.<br/>
		/// If this is <see langword="false"/>, then the minimum value is exclusive, and a value equal to the minimum will result in an error.
		/// </summary>
		public bool IncludeMinimum { get; set; } = false;

		/// <summary>
		/// If <see langword="true"/>, then the maximum value is inclusive, so a value equal to the maximum is acceptible.<br/>
		/// If this is <see langword="false"/>, then the maximum value is exclusive, and a value equal to the maximum will result in an error.
		/// </summary>
		public bool IncludeMaximum { get; set; } = false;

		public PluginNumericLimit(double min, double max, bool @int = false) {
			AbsoluteMaximum = max;
			AdvisedMaximum = AbsoluteMaximum;

			AbsoluteMinimum = min;
			AdvisedMinimum = AbsoluteMinimum;

			IsInteger = @int;
		}

		public PluginNumericLimit(double min, bool @int = false) {
			AbsoluteMaximum = double.PositiveInfinity;
			AdvisedMaximum = AbsoluteMaximum;

			AbsoluteMinimum = min;
			AdvisedMinimum = AbsoluteMinimum;

			IsInteger = @int;
		}

		public override string? ValidateData() {
			// advised have more magnitude than absolute tests
			if (AbsoluteMinimum > AdvisedMinimum) {
				return "Invalid minimum: The advised minimum (warning) is lower than the strict minimum (error). It should always be greater or equal to the strict minimum.";
			}
			if (AbsoluteMaximum < AdvisedMaximum) {
				return "Invalid maximum: The advised maximum (warning) is higher than the strict maximum (error). It should always be less or equal to the strict maximum.";
			}

			// min>max tests
			if (AdvisedMinimum > AdvisedMaximum) {
				return "Advised minimum value is larger than the advised maximum.";
			}
			if (AbsoluteMinimum > AbsoluteMaximum) {
				return "Absolute minimum value is larger than the absolute maximum.";
			}

			return null;
		}

		public override StringKeyTable ToLuaTable() {
			StringKeyTable tbl = new StringKeyTable();
			tbl.Add("LimitType", "NumericLimit");
			tbl.AddLiteral("GeneralLimit", Vector2(AdvisedMinimum, AdvisedMaximum));
			tbl.AddLiteral("AbsoluteLimit", Vector2(AbsoluteMinimum, AbsoluteMaximum));
			tbl.Add("IsInt", IsInteger);
			tbl.Add("IsPercentage", IsPercent);
			tbl.Add("IncludeMinimum", IncludeMinimum);
			tbl.Add("IncludeMaximum", IncludeMaximum);
			return tbl;
		}

		public void AddToLuaTable(StringKeyTable tbl) {
			tbl.Add("IsNumberList", true);
			// tbl.AddLiteral("GeneralLimit", Vector2(AdvisedMinimum, AdvisedMaximum));
			tbl.AddLiteral("AbsoluteLimit", Vector2(AbsoluteMinimum, AbsoluteMaximum));
			tbl.Add("IsInt", IsInteger);
		}

		private static string Vector2(double x, double y) {
			return $"Vector2.new({DoubleToString(x)}, {DoubleToString(y)})";
		}

		public static string DoubleToString(double value) {
			if (double.IsInfinity(value)) {
				if (double.IsNegative(value)) {
					return "-math.huge";
				} else {
					return "math.huge";
				}
			}
			return value.ToString();
		}

	}
}
