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
					result.Add(new ExportableField(fi, this, attr, fi.GetCustomAttribute<PluginMenuLimiterAttribute>()));
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
			if (!noHeader) sb.AppendLine(
@"	Runtime: Instance & {
		State: Instance;
		StatusEffects: {[string]: Instance};
	};"
			);
			sb.AppendLine("}");
			return sb.ToString();
		}

		public class ExportableField {

			public string Name { get; }

			public object? DefaultValue { get; }

			public LuauFieldAttribute FieldInfo { get; }

			public PluginMenuLimiterAttribute? Limit { get; }

			public string? Documentation { get; }

			public bool IsSpecialPluginStatus { get; }

			public bool IsInstanceObject { get; }

			public CopyFromV0Attribute? CopyFromV0 { get; }

			private static string GetLuauTypeOf(object? value) {
				if (value == null) return "nil";
				if (value.GetType() == typeof(double)) return "number";
				if (value.GetType() == typeof(string)) return "string";
				if (value.GetType() == typeof(bool)) return "boolean";
				if (value.GetType() == typeof(StatLimit)) return "Vector2";
				if (value.GetType() == typeof(Color3)) return "Color3";
				return "any";
			}

			public ExportableField(PropertyInfo prop, object ofObject, LuauFieldAttribute attr, PluginMenuLimiterAttribute? limiter) {
				Name = prop.Name;
				DefaultValue = prop.GetValue(ofObject);
				FieldInfo = attr;
				Limit = limiter;

				string? msg = Limit?.ValidateData();
				if (msg != null) {
					throw new InvalidOperationException($"Failed to create field \"{Name}\" in an object of type {ofObject.GetType().FullName} because its limit is not valid: {msg}");
				}

				IsSpecialPluginStatus = prop.GetCustomAttribute<PluginIsSpecialAilmentTemplate>() != null;
				Documentation = prop.GetCustomAttribute<DocumentationAttribute>()?.Documentation;
				IsInstanceObject = prop.GetCustomAttribute<RepresentedByInstanceAttribute>() != null;
				CopyFromV0 = prop.GetCustomAttribute<CopyFromV0Attribute>();
			}

			public void AppendToCodeTable(StringBuilder builder, int indents = 1) {
				if (FieldInfo.RuntimeOnly) return;

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
						builder.Append($"Vector2.new({limit.Min}, {limit.Max})");

					} else if (DefaultValue is Instance) {
						builder.Append("nil");

					} else if (DefaultValue is Array array) {
						builder.Append("{}");

					} else if (DefaultValue is Color3 color) {
						builder.Append(color);

					} else {
						throw new InvalidOperationException("The given object type cannot be converted into a Luau table entry.");
					}
				}

				if (!string.IsNullOrEmpty(FieldInfo.LuauType)) {
					builder.Append("::");
					builder.Append(FieldInfo.LuauType);
				}
				builder.AppendLine(";");
			}

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
				if (Limit is null) {
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
						if (CopyFromV0 != null) CopyFromV0.AppendToLuaTable(data.GetOrCreateTable("DataUpgradeInfo"));
						if (Documentation != null) data.GetOrCreateTable("PluginInfo").Add("Documentation", Documentation);
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
					if (Limit is PluginCustomEnum || Limit is PluginStringLimit) {
						data.Add("PluginInfo", Limit.ToLuaTable());
						if (CopyFromV0 != null) 
							CopyFromV0.AppendToLuaTable(data.GetOrCreateTable("DataUpgradeInfo"));
						if (Documentation != null) data.GetOrCreateTable("PluginInfo").Add("Documentation", Documentation);
						data.AppendToBuilder(builder, indents);

					} else {
						throw new InvalidOperationException($"Attempt to apply invalid {Limit.GetType().Name} to string value.");
					}
				} else if (DefaultValue is double) {
					if (Limit is PluginNumericLimit) {
						data.Add("PluginInfo", Limit.ToLuaTable());
						if (CopyFromV0 != null) CopyFromV0.AppendToLuaTable(data.GetOrCreateTable("DataUpgradeInfo"));
						if (Documentation != null) data.GetOrCreateTable("PluginInfo").Add("Documentation", Documentation);
						data.AppendToBuilder(builder, indents);

					} else {
						throw new InvalidOperationException($"Attempt to apply invalid {Limit.GetType().Name} to number value.");
					}

				} else if (DefaultValue is Array array) {
					if (IsSpecialPluginStatus) {
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
					throw new InvalidOperationException($"Attempt to apply invalid {Limit.GetType().Name} to a non-numeric, non-string value.");
				}

				builder.AppendLine(";");
			}

			public void AppendToType(StringBuilder builder, int indents = 1) {
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


	}
}
