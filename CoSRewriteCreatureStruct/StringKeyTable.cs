using CoSRewriteCreatureStruct.CreatureDataTypes;
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
		public bool Empty => InternalData.Count == 0 && SubTables.Count == 0;

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
		/// Calls the <see langword="string"/>, <see langword="double"/>, <see langword="bool"/>, or <see cref="StringKeyTable"/> Add method based on the input. Supports <see langword="null"/>.
		/// </summary>
		/// <param name="key"></param>
		/// <param name="value"></param>
		/// <param name="explicitlyAddNil">If true, and if the value is null, a nil index will be added. This has no difference to not defining the value, with the exception of Luau types.</param>
		/// <param name="lazySkip">If true, instead of raising <see cref="NotSupportedException"/> when an incompatible value is passed in, the call will just do nothing.</param>
		/// <exception cref="NotSupportedException"></exception>
		public void Add(string key, object? value, bool explicitlyAddNil = false, bool lazySkip = false) {
			if (value is null) {
				if (explicitlyAddNil) AddLiteral(key, "nil");
			} else if (value is string text) {
				Add(key, text);
			} else if (value is double number) {
				Add(key, number);
			} else if (value is bool boolean) {
				Add(key, boolean);
			} else if (value is StringKeyTable table) {
				Add(key, table);
			} else if (value is DumbColorSequence || value is StatLimit || value is Color3) {
				AddLiteral(key, value.ToString()!);
			} else {
				if (!lazySkip) throw new NotSupportedException($"The given value type ({value.GetType().FullName}) cannot be added to a Lua table.");
			}
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
