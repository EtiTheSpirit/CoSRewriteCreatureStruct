using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Diagnostics;

namespace CoSRewriteCreatureStruct {
	public static class Util {

		public static T[] One<T>() where T : new() {
			return new T[] {
				new T()
			};
		}

		public static string EscapeString(string str) {
			return str.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "\\r").Replace("\t", "\\t");
		}

		public static string? StringToLuaEscapedString(string? str) {
			if (str == null) return null;
			return "\"" + EscapeString(str.ToString()) + "\"";
		}

		/// <summary>
		/// Converts this string array to a lua table on one line. This should be used in the <see cref="StringKeyTable.AddLiteral(string, string)"/> method.
		/// </summary>
		/// <param name="array"></param>
		/// <returns></returns>
		public static string ToLuaTable(this string[] array) {
			StringBuilder result = new StringBuilder("{");
			bool appendComma = false;
			foreach (string element in array) {
				if (appendComma) result.Append(", ");
				result.Append('\"');
				result.Append(EscapeString(element));
				result.Append('\"');
				appendComma = true;
			}
			result.Append('}');
			return result.ToString();
		}

		[DllImport("Shlwapi.dll", CharSet = CharSet.Unicode)]
		private static extern uint AssocQueryString(int flags, int str, string pszAssoc, string? pszExtra, [Out] StringBuilder? pszOut, ref uint pcchOut);

		public static string GetExeToOpen(string extension) {
			uint length = 0;
			uint result = AssocQueryString(0, 2, extension, null, null, ref length);

			if (result != 1) {
				throw new InvalidOperationException("Unable to find default program for file. Error code: " + result.ToString());
			}

			StringBuilder info = new StringBuilder((int)length);

			result = AssocQueryString(0, 2, extension, null, info, ref length);
			if (result != 0) {
				throw new InvalidOperationException("Unable to find default program for file. Error code: " + result.ToString());
			}

			return info.ToString();
		}

		/// <summary>
		/// Opens the default program for the given file, if one exists.
		/// </summary>
		/// <param name="file"></param>
		/// <exception cref="InvalidOperationException">If no association exists for this file.</exception>
		public static void OpenDefaultEditor(FileInfo file) {
			Process.Start(GetExeToOpen(file.Extension), $"\"{file.FullName}\"");
		}
	}
}
