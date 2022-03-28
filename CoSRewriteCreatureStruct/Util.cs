using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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


	}
}
