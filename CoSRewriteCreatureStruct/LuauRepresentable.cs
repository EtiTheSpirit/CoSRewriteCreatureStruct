using CoSRewriteCreatureStruct.Attributes;
using CoSRewriteCreatureStruct.CreatureDataTypes;
using CoSRewriteCreatureStruct.PluginMenuTypes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using static CoSRewriteCreatureStruct.Util;

namespace CoSRewriteCreatureStruct {

	/// <summary>
	/// Marks a class as one that represents a Luau object.
	/// </summary>
	public abstract class LuauRepresentable {

		/// <summary>
		/// A singleton anonymous luau-representable object.
		/// </summary>
		public static readonly LuauRepresentable ANONYMOUS = new @Anonymous();

		/// <summary>
		/// Returns an array of all exportable Luau fields this object contains via the <see cref="LuauFieldAttribute"/> attribute.
		/// </summary>
		/// <returns></returns>
		public ExportableField[] GetExportableFields() {
			Type selfType = GetType();
			PropertyInfo[] props = selfType.GetProperties(BindingFlags.Public | BindingFlags.Instance | BindingFlags.FlattenHierarchy);
			List<ExportableField> result = new List<ExportableField>(props.Length);
			foreach (PropertyInfo fi in props) {
				LuauFieldAttribute? attr = fi.GetCustomAttribute<LuauFieldAttribute>();
				if (attr != null) {
					IEnumerable<PluginMenuLimiterAttribute> limiters = fi.GetCustomAttributes<PluginMenuLimiterAttribute>();
					PluginMenuLimiterAttribute? first = null;
					PluginMenuLimiterAttribute? second = null;

					foreach (PluginMenuLimiterAttribute limiter in limiters) {
						if (first == null) {
							first = limiter;
						} else if (second == null) {
							second = limiter;
						} else {
							throw new InvalidOperationException("Cannot have more than two limits!");
						}
					}

					if (second != null) {
						if (first is PluginNumericLimit && second is PluginStringLimit) {
							(first, second) = (second, first);
						}
					}

					result.Add(new ExportableField(fi, this, attr, first, second));
				}
			}
			return result.ToArray();
		}

		public string ToLuaObject(int indents = 1, bool noHeader = false) {
			StringBuilder sb = new StringBuilder();
			if (!noHeader) sb.AppendLine("local CreatureObjectTemplate = {");
			foreach (ExportableField field in GetExportableFields()) {
				field.AppendToCodeTable(sb, indents);
			}
			if (!noHeader) sb.AppendLine("}");
			return sb.ToString();
		}

		public string ToPluginObject(int indents = 1, bool noHeader = false) {
			StringBuilder sb = new StringBuilder();
			if (!noHeader) sb.AppendLine("local CreatureObjectPluginData = {");
			foreach (ExportableField field in GetExportableFields()) {
				field.AppendToPluginData(sb, indents);
			}
			if (!noHeader) sb.AppendLine("}");
			return sb.ToString();
		}

		public string ToType(int indents = 1, bool noHeader = false) {
			StringBuilder sb = new StringBuilder();
			if (!noHeader) sb.AppendLine("export type CreatureData = {");
			foreach (ExportableField field in GetExportableFields()) {
				field.AppendToType(sb, indents);
			}
			if (!noHeader) sb.AppendLine("}");
			return sb.ToString();
		}

		public string ToInstanceType(int indents = 1, bool noHeader = false) {
			StringBuilder sb = new StringBuilder();
			if (!noHeader) sb.AppendLine("export type SpecificationsInstance = Instance & {");
			foreach (ExportableField field in GetExportableFields()) {
				field.AppendToInstanceType(sb, indents);
			}
			sb.AppendLine("}");
			return sb.ToString();
		}

		public class ExportableField {

			/// <summary>
			/// The name of this field.
			/// </summary>
			public string Name { get; }

			/// <summary>
			/// The default value of this field, which is what new creature objects will use.
			/// </summary>
			public object? DefaultValue { get; }

			/// <summary>
			/// Information about the field itself as a Luau type.
			/// </summary>
			public LuauFieldAttribute FieldInfo { get; }

			/// <summary>
			/// Whether or not this property is intrinsic.
			/// </summary>
			public bool IsIntrinsic => Intrinsic != null;

			/// <summary>
			/// The intrinsic attribute, if it exists.
			/// </summary>
			public IntrinsicAttribute? Intrinsic { get; }

			/// <summary>
			/// The primary applying limit to this field, which can be used to manage its value in the editor plugin.
			/// </summary>
			public PluginMenuLimiterAttribute? PrimaryLimit { get; }

			/// <summary>
			/// An auxilary limit to this field, which is only applicable in some cases (such as a numeric limit on a list string).
			/// </summary>
			public PluginMenuLimiterAttribute? SecondaryLimit { get; }

			/// <summary>
			/// The documentation describing this field.
			/// </summary>
			public string? Documentation { get; }

			/// <summary>
			/// If this is true, this object will generate as an Instance for the runtime character controller.
			/// </summary>
			public bool IsInstanceObject { get; }

			/// <summary>
			/// If defined, this is behavior on how to upgrade legacy creature data to CDV2 creature data.
			/// </summary>
			public CopyFromV0Attribute? CopyFromV0 { get; }

			/// <summary>
			/// If not None, this is the validation behavior of this field, which operates after default limits.
			/// It is used to do contextual validation to a specific value that has more nuanced edge cases.
			/// It can also be used to enable or disable fields (readonly vs. editable)
			/// </summary>
			public ValidatorBehavior CustomValidationBehavior { get; }

			/// <summary>
			/// If defined, this is the category of the property in the plugin. 
			/// If not defined, the plugin's default will be used, which is just "Properties".
			/// </summary>
			public string? Category { get; }

			/// <summary>
			/// If this is true, special behavior for status effects is applied.
			/// </summary>
			public bool IsSpecialEffectContainer { get; }

			/// <summary>
			/// Whether or not this member should be considered plugin only, either due to explicitly setting as true, or due
			/// to the presence of the intrinsic attribute.
			/// </summary>
			public bool IsPluginOnly => FieldInfo.PluginOnly || IsIntrinsic;

			/// <summary>
			/// Returns the closest Luau type available for the given class, or <c>any</c> if the class is not recognized.
			/// </summary>
			/// <param name="value"></param>
			/// <returns></returns>
			private static string GetLuauTypeOf(object? value) {
				if (value == null) return "nil";
				if (value.GetType() == typeof(double)) return "number";
				if (value.GetType() == typeof(string)) return "string";
				if (value.GetType() == typeof(bool)) return "boolean";
				if (value.GetType() == typeof(StatLimit)) return "Vector2";
				if (value.GetType() == typeof(Color3)) return "Color3";
				if (value.GetType() == typeof(DumbColorSequence)) return "ColorSequence";
				if (value.GetType() == typeof(Instance)) return "Instance";
				return "any";
			}

			public ExportableField(PropertyInfo prop, object ofObject, LuauFieldAttribute attr, PluginMenuLimiterAttribute? limiter, PluginMenuLimiterAttribute? secondLimiter) {
				Name = prop.Name;
				DefaultValue = prop.GetValue(ofObject);
				FieldInfo = attr;
				PrimaryLimit = limiter;
				SecondaryLimit = secondLimiter;
				CustomValidationBehavior = attr.CustomValidationBehavior;

				string? msg = PrimaryLimit?.ValidateData();
				if (msg != null) {
					throw new InvalidOperationException($"Failed to create field \"{Name}\" in an object of type {ofObject.GetType().FullName} because its limit is not valid: {msg}");
				}

				DocumentationAttribute? doc = prop.GetCustomAttribute<DocumentationAttribute>();
				Documentation = doc?.Documentation;
				IsInstanceObject = prop.GetCustomAttribute<RepresentedByInstanceAttribute>() != null;
				CopyFromV0 = prop.GetCustomAttribute<CopyFromV0Attribute>();
				Intrinsic = prop.GetCustomAttribute<IntrinsicAttribute>();
				Category = IsIntrinsic ? "<font color=\"#aaffff\">Intrinsic Properties</font>" : doc?.Category;
				IsSpecialEffectContainer = prop.GetCustomAttribute<PluginIsSpecialAilmentTemplate>() != null;

				if (attr.PluginOnly && IsIntrinsic) {
					ConsoleColor old = Console.ForegroundColor;
					Console.ForegroundColor = ConsoleColor.Yellow;
					Console.WriteLine($"Notice: Property {Name} is explicitly set to PluginOnly=true, but also has the Intrinsic attribute. Intrinsic implicitly makes the field plugin only.");
					Console.ForegroundColor = old;
				}

				if (doc?.Category != null && IsIntrinsic) {
					ConsoleColor old = Console.ForegroundColor;
					Console.ForegroundColor = ConsoleColor.Yellow;
					Console.WriteLine($"Notice: Property {Name} defined category {doc?.Category} in its Documentation attribute, but this category is discarded because the property is intrinsic (its category is always \"Intrinsic\")!");
					Console.ForegroundColor = old;
				}

				if (attr.RuntimeOnly && IsPluginOnly) {
					throw new InvalidOperationException("The LuauField attribute on " + prop.Name + " mandates both Runtime Only and Plugin Only, which contradict eachother. Ensure that at most only one of the two are enabled.");
				}
			}

			/// <summary>
			/// Appends this field to the table of code that defines a template creature.
			/// </summary>
			/// <param name="builder"></param>
			/// <param name="indents"></param>
			/// <exception cref="InvalidOperationException"></exception>
			public void AppendToCodeTable(StringBuilder builder, int indents = 1) {
				if (FieldInfo.RuntimeOnly) return;
				if (IsPluginOnly) return;

				string prefix = string.Empty;
				if (indents > 0) {
					prefix = new string('\t', indents);
				}

				builder.Append(prefix);
				builder.Append(FieldInfo.KeyAsLiteral ?? Name);
				builder.Append(" = ");

				if (FieldInfo.ValueAsLiteral != null) {
					builder.Append(FieldInfo.ValueAsLiteral);
				} else {
					if (DefaultValue == null) {
						builder.Append("nil");
					} else if (DefaultValue is LuauRepresentable luauObject) {
						builder.AppendLine("{");
						foreach (ExportableField subField in luauObject.GetExportableFields()) {
							if (subField.FieldInfo.RuntimeOnly) continue;
							subField.AppendToCodeTable(builder, indents + 1);
						}
						builder.Append(prefix);
						builder.Append('}');
					} else if (DefaultValue is string text) {
						builder.Append($"\"{EscapeString(text)}\"");
					} else if (DefaultValue is double number) {
						if (double.IsInfinity(number)) {
							if (double.IsNegative(number)) builder.Append('-');
							builder.Append("math.huge");
						} else {
							builder.Append(number);
						}
					} else if (DefaultValue is bool boolean) {
						builder.Append(boolean.ToString().ToLower());
					} else if (DefaultValue is StatLimit limit) {
						builder.Append(limit);

					} else if (DefaultValue is Instance) {
						builder.Append("nil");

					} else if (DefaultValue is Array) {
						builder.Append("{}");

					} else if (DefaultValue is Color3 color) {
						builder.Append(color);

					} else {
						throw new InvalidOperationException("The given object type cannot be converted into a Luau table entry.");
					}
				}

				if (!string.IsNullOrEmpty(FieldInfo.LuauType) && !IsSpecialEffectContainer) {
					builder.Append("::");
					builder.Append(FieldInfo.LuauType);
				}
				builder.AppendLine(";");
			}

			/// <summary>
			/// Appends this field as data readable to the plugin's menu.
			/// </summary>
			/// <param name="builder"></param>
			/// <param name="indents"></param>
			/// <exception cref="InvalidOperationException"></exception>
			public void AppendToPluginData(StringBuilder builder, int indents = 1) {
				if (FieldInfo.RuntimeOnly) return;

				string prefix = string.Empty;
				if (indents > 0) {
					prefix = new string('\t', indents);
				}

				builder.Append(prefix);
				builder.Append(FieldInfo.KeyAsLiteral ?? Name);
				builder.Append(" = ");

				StringKeyTable data = new StringKeyTable();
				data.Add("Type", GetLuauTypeOf(DefaultValue));
				if (!IsIntrinsic) data.Add("DefaultValue", DefaultValue, lazySkip: true);
				if (FieldInfo.PluginReflectToProperty != null) {
					data.Add("ReflectTo", FieldInfo.PluginReflectToProperty);
				}

				if (PrimaryLimit is null) {
					if (DefaultValue is LuauRepresentable luauObject) {
						builder.AppendLine("{");
						foreach (ExportableField subField in luauObject.GetExportableFields()) {
							if (subField.FieldInfo.RuntimeOnly) continue;
							subField.AppendToPluginData(builder, indents + 1);
						}
						builder.Append(prefix);
						builder.AppendLine("};");
						return;
					} else {
						if (DefaultValue is StatLimit) data.GetOrCreateTable("PluginInfo").Add("LimitType", "StatLimit");
						if (CopyFromV0 != null) CopyFromV0.AppendToLuaTable(data.GetOrCreateTable("DataUpgradeInfo"));
						if (Documentation != null) data.GetOrCreateTable("PluginInfo").Add("Documentation", Documentation);
						if (Category != null) data.GetOrCreateTable("PluginInfo").Add("Category", Category);
						if (IsSpecialEffectContainer) data.GetOrCreateTable("PluginInfo").Add("IsStatusContainer", true);
						if (CustomValidationBehavior != ValidatorBehavior.None) data.GetOrCreateTable("PluginInfo").Add("CustomValidationBehavior", CustomValidationBehavior.ToString());
						if (IsIntrinsic) {
							data.GetOrCreateTable("Intrinsic").Add("Callback", Intrinsic!.Callback.ToString());
							data.GetOrCreateTable("Intrinsic").AddLiteral("AffectedBy", Intrinsic!.AffectedBy?.ToLuaTable() ?? "{}");
						}
						
						if (!data.Empty) {
							data.AppendToBuilder(builder, indents);
							builder.AppendLine(";");
						} else {
							builder.AppendLine("nil;");
						}
						return;
					}
				}

				if (DefaultValue is string) {
					if (PrimaryLimit is PluginCustomEnum || PrimaryLimit is PluginStringLimit) {
						data.Add("PluginInfo", PrimaryLimit.ToLuaTable());
						if (CopyFromV0 != null) CopyFromV0.AppendToLuaTable(data.GetOrCreateTable("DataUpgradeInfo"));
						if (Documentation != null) data.GetOrCreateTable("PluginInfo").Add("Documentation", Documentation);
						if (Category != null) data.GetOrCreateTable("PluginInfo").Add("Category", Category);
						if (IsSpecialEffectContainer) data.GetOrCreateTable("PluginInfo").Add("IsStatusContainer", true);
						if (CustomValidationBehavior != ValidatorBehavior.None) data.GetOrCreateTable("PluginInfo").Add("CustomValidationBehavior", CustomValidationBehavior.ToString());
						if (IsIntrinsic) {
							data.GetOrCreateTable("Intrinsic").Add("Callback", Intrinsic!.Callback.ToString());
							data.GetOrCreateTable("Intrinsic").AddLiteral("AffectedBy", Intrinsic!.AffectedBy?.ToLuaTable() ?? "{}");
						}

						if (PrimaryLimit is PluginStringLimit strLim && strLim.IsList) {
							if (SecondaryLimit is PluginNumericLimit numLimit) {
								numLimit.AddToLuaTable(data.GetOrCreateTable("PluginInfo"));
							} else {
								data.GetOrCreateTable("PluginInfo").Add("IsNumberList", false);
							}
						}

						data.AppendToBuilder(builder, indents);

					} else {
						throw new InvalidOperationException($"Attempt to apply invalid {PrimaryLimit.GetType().Name} to string value.");
					}
				} else if (DefaultValue is double) {
					if (PrimaryLimit is PluginNumericLimit) {
						data.Add("PluginInfo", PrimaryLimit.ToLuaTable());
						if (CopyFromV0 != null) CopyFromV0.AppendToLuaTable(data.GetOrCreateTable("DataUpgradeInfo"));
						if (Documentation != null) data.GetOrCreateTable("PluginInfo").Add("Documentation", Documentation);
						if (Category != null) data.GetOrCreateTable("PluginInfo").Add("Category", Category);
						if (IsSpecialEffectContainer) data.GetOrCreateTable("PluginInfo").Add("IsStatusContainer", true);
						if (CustomValidationBehavior != ValidatorBehavior.None) data.GetOrCreateTable("PluginInfo").Add("CustomValidationBehavior", CustomValidationBehavior.ToString());
						if (IsIntrinsic) {
							data.GetOrCreateTable("Intrinsic").Add("Callback", Intrinsic!.Callback.ToString());
							data.GetOrCreateTable("Intrinsic").AddLiteral("AffectedBy", Intrinsic!.AffectedBy?.ToLuaTable() ?? "{}");
						}
						data.AppendToBuilder(builder, indents);

					} else {
						throw new InvalidOperationException($"Attempt to apply invalid {PrimaryLimit.GetType().Name} to number value.");
					}

				} else if (DefaultValue is Array array) {
					if (IsSpecialEffectContainer) {
						builder.AppendLine("{");
						builder.Append(prefix + "\t");
						builder.AppendLine("__CDV2_PLUGIN_TEMPLATE = {");
						foreach (ExportableField subField in ((LuauRepresentable)array.GetValue(0)!).GetExportableFields()) {
							subField.AppendToPluginData(builder, indents + 2);
						}
						builder.Append(prefix + "\t");
						builder.AppendLine("};");
						builder.Append(prefix);
						builder.Append('}');
					} else {
						builder.Append("{}");
					}

				} else {
					throw new InvalidOperationException($"Attempt to apply invalid {PrimaryLimit.GetType().Name} to a non-numeric, non-string value.");
				}

				builder.AppendLine(";");
			}

			/// <summary>
			/// Appends this field as a type for Roblox Studio when developing for Sonaria.
			/// </summary>
			/// <param name="builder"></param>
			/// <param name="indents"></param>
			public void AppendToType(StringBuilder builder, int indents = 1) {
				if (IsPluginOnly) return;

				string prefix = string.Empty;
				if (indents > 0) {
					prefix = new string('\t', indents);
				}

				builder.Append(prefix);
				builder.Append(Name);
				builder.Append(": ");

				string type = FieldInfo.LuauType ?? GetLuauTypeOf(DefaultValue);

				if (type != null && DefaultValue is not LuauRepresentable && DefaultValue is not Array) {
					builder.Append(type);
					builder.AppendLine(";");
				} else {
					if (DefaultValue is LuauRepresentable luauObject) {
						builder.AppendLine("{");
						foreach (ExportableField field in luauObject.GetExportableFields()) {
							field.AppendToType(builder, indents + 1);
						}
						builder.Append(prefix);
						builder.AppendLine("};");
					} else if (DefaultValue is StatLimit) {
						builder.AppendLine("Vector2;");
					} else if (DefaultValue is Array array) {
						builder.Append("{[string]: ");
						object? value = array.GetValue(0);
						if (value is LuauRepresentable luauObj) {
							if (type == null) {
								builder.AppendLine("{");
								foreach (ExportableField field in luauObj.GetExportableFields()) {
									field.AppendToType(builder, indents + 1);
								}
								builder.Append(prefix);
								builder.Append('}');
							} else {
								builder.Append(type);
							}
						}
						builder.AppendLine("};");
					} else if (DefaultValue is Color3) {
						builder.AppendLine("Color3;");
					}
				}
			}

			public void AppendToInstanceType(StringBuilder builder, int indents = 1) {
				if (IsPluginOnly) return;

				LuauRepresentable? luauObject = DefaultValue as LuauRepresentable;
				if ((DefaultValue is Array || luauObject != null) && IsInstanceObject) {
					string prefix = string.Empty;
					if (indents > 0) {
						prefix = new string('\t', indents);
					}

					builder.Append(prefix);
					builder.Append(Name);
					builder.Append(": ");
					builder.Append("Instance");
					StringBuilder sub = new StringBuilder();
					if (luauObject != null) {
						foreach (ExportableField field in luauObject.GetExportableFields()) {
							field.AppendToInstanceType(sub, indents + 1);
						}
					}
					if (sub.Length > 0) {
						builder.AppendLine(" & {");
						builder.Append(sub);
						builder.Append(prefix);
						builder.AppendLine("};");
					} else {
						builder.AppendLine(";");
					}
				}
				
			}

		}


		private class @Anonymous : LuauRepresentable { }

	}
}
