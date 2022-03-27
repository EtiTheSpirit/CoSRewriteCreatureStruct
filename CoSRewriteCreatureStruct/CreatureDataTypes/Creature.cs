using CoSRewriteCreatureStruct.Attributes;
using CoSRewriteCreatureStruct.CreatureDataTypes;
using CoSRewriteCreatureStruct.PluginMenuTypes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct {
	public class Creature : LuauRepresentable {

		[LuauField(RuntimeOnly = true)]
		public string Name { get; set; } = string.Empty;

		[LuauField, PluginStringLimit(AllowEmpty = false), Documentation("The description of this creature, usually provided by its creator to briefly give insight into its backstory.")]
		public string Description { get; set; } = string.Empty;

		[LuauField, PluginStringLimit(AllowEmpty = false), Documentation("The individual or people that worked on this creature in some capacity.")]
		public string Artists { get; set; } = string.Empty;

		[LuauField, PluginStringLimit(AllowEmpty = false), Documentation("What the plural of this creature's name is.")]
		public string PluralName { get; set; } = string.Empty;

		[LuauField, PluginNumericLimit(0, true), Documentation("The ID of a published asset where the thumbnail camera is pointing at this creature's head. This is used for its icon.")]
		public double ThumbnailModelID { get; set; } = 0;

		[LuauField, PluginNumericLimit(1, true), Documentation("The version of this creature's data. This should not be manually tampered with unless an upgrade is performed.")]
		public double DataVersion { get; set; } = 1;

		[LuauField]
		public CreatureSpecifications Specifications { get; set; } = new CreatureSpecifications();

		[LuauField]
		public CreatureVisuals CreatureVisuals { get; set; } = new CreatureVisuals();

		public string ToLuaObject() {
			StringBuilder sb = new StringBuilder();
			sb.AppendLine("local CreatureObjectTemplate = {");
			foreach (ExportableField field in GetExportableFields()) {
				field.AppendToCodeTable(sb, 1);
			}
			sb.AppendLine("}");
			return sb.ToString();
		}

		public string ToPluginObject() {
			StringBuilder sb = new StringBuilder();
			sb.AppendLine("local CreatureObjectPluginData = {");
			foreach (ExportableField field in GetExportableFields()) {
				field.AppendToPluginData(sb, 1);
			}
			sb.AppendLine("}");
			return sb.ToString();
		}

		public string ToType() {
			StringBuilder sb = new StringBuilder();
			sb.AppendLine("export type CreatureData = {");
			foreach (ExportableField field in GetExportableFields()) {
				field.AppendToType(sb, 1);
			}
			sb.AppendLine("}");
			return sb.ToString();
		}

	}
}
