using CoSRewriteCreatureStruct.PluginMenuTypes;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct {

	/// <summary>
	/// A lazy way to add elements to a lua table.
	/// </summary>
	public sealed class StringKeyTable {

		private readonly Dictionary<string, string> InternalData = new Dictionary<string, string>();

		private readonly Dictionary<string, StringKeyTable> SubTables = new Dictionary<string, StringKeyTable>();

		/// <summary>
		/// Whether or not this table has no entries
		/// </summary>
		public bool Empty => InternalData.Count == 0;

		/// <summary>
		/// Whether or not to pretty print this table, which extends it out onto different lines.
		/// </summary>
		public bool PrettyPrint { get; set; } = true;

		/// <summary>
		/// Adds the given string to this lookup.
		/// </summary>
		/// <param name="key"></param>
		/// <param name="text"></param>
		public void Add(string key, string? text, bool forceExplicitNil = false) {
			if (text != null || forceExplicitNil) {
				InternalData.Add(key, Util.StringToLuaEscapedString(text) ?? "nil");
			}
		}

		/// <summary>
		/// Adds the given double value to this lookup.
		/// </summary>
		/// <param name="key"></param>
		/// <param name="number"></param>
		public void Add(string key, double number) => InternalData.Add(key, PluginNumericLimit.DoubleToString(number));

		/// <summary>
		/// Adds the given boolean value to this lookup.
		/// </summary>
		/// <param name="key"></param>
		/// <param name="boolean"></param>
		public void Add(string key, bool boolean) => InternalData.Add(key, boolean.ToString().ToLower());

		/// <summary>
		/// Adds the given table to this one.
		/// </summary>
		/// <param name="key"></param>
		/// <param name="table"></param>
		public void Add(string key, StringKeyTable table) {
			SubTables.Add(key, table);
		}

		/// <summary>
		/// Adds the given string literal to this lookup.
		/// </summary>
		/// <param name="key"></param>
		/// <param name="literal"></param>
		public void AddLiteral(string key, string literal) {
			InternalData.Add(key, literal);
		}

		/// <summary>
		/// Attempts to find a subtable with the given string key, and returns that subtable.
		/// </summary>
		/// <param name="key"></param>
		/// <returns></returns>
		public StringKeyTable? GetTable(string key) {
			return SubTables.GetValueOrDefault(key);
		}

		/// <summary>
		/// Attempts to find a subtable with the given string key, and returns that subtable.
		/// </summary>
		/// <param name="key"></param>
		/// <returns></returns>
		public StringKeyTable GetOrCreateTable(string key) {
			if (SubTables.TryGetValue(key, out StringKeyTable? table)) {
				return table!;
			} else {
				table = new StringKeyTable();
				SubTables.Add(key, table);
				return table;
			}
		}

		public void AppendToBuilder(StringBuilder sb, int indents = 1) {
			string prefix = string.Empty;
			if (PrettyPrint && indents > 0) {
				prefix = new string('\t', indents);
			}

			sb.Append('{');
			if (PrettyPrint) {
				sb.AppendLine();
			} else {
				sb.Append(' ');
			}
			foreach (KeyValuePair<string, string> kvp in InternalData) {
				if (PrettyPrint) {
					sb.Append(prefix);
					sb.Append('\t');
				}
				sb.Append(kvp.Key);
				sb.Append(" = ");
				sb.Append(kvp.Value);
				sb.Append(';');
				if (PrettyPrint) {
					sb.AppendLine();
				} else {
					sb.Append(' ');
				}
			}
			foreach (KeyValuePair<string, StringKeyTable> subTable in SubTables) {
				if (PrettyPrint) {
					sb.Append(prefix);
					sb.Append('\t');
				}
				sb.Append(subTable.Key);
				sb.Append(" = ");
				subTable.Value.AppendToBuilder(sb, indents + 1);
				sb.Append(';');
				if (PrettyPrint) {
					sb.AppendLine();
				} else {
					sb.Append(' ');
				}
			}
			if (PrettyPrint) {
				sb.Append(prefix);
			}
			sb.Append('}');
		}
	}
}
