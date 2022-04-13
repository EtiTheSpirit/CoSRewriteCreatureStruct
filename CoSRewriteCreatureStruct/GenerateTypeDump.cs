using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct {
	public class GenerateTypeDump {

		/// <summary>
		/// Generates a type dump of all the methods in the file that are a member of the given table where
		/// the text format is table:Method(...): return
		/// </summary>
		/// <param name="file"></param>
		/// <param name="table"></param>
		public static void Generate(FileInfo file, string table, string? typeName = null) {
			typeName ??= table;
			string funcStart = "function " + table + ":";
			StringBuilder typeDef = new StringBuilder("export type " + typeName + " = {\n");
			string[] lines = File.ReadAllLines(file.FullName);
			foreach (string line in lines) {
				if (line.StartsWith(funcStart)) {
					string fNameAndDef = line[funcStart.Length..];
					int openParen = fNameAndDef.IndexOf('(');
					int closeParen = fNameAndDef.IndexOf(')');
					string name;
					string args;
					string retn;
					if (openParen > 0 && closeParen > 0) {
						name = fNameAndDef[..openParen];
						args = fNameAndDef[openParen..closeParen];
						if (fNameAndDef.Length > closeParen + 3) {
							retn = fNameAndDef[(closeParen + 3)..];
						} else {
							retn = "()";
						}
					} else {
						Debug.WriteLine(line);
						Debug.WriteLine(fNameAndDef);
						throw new InvalidOperationException();
					}
					typeDef.Append('\t');
					typeDef.Append(name);
					typeDef.Append(": (self: ");
					typeDef.Append(typeName);
					MatchCollection matches = Regex.Matches(args, @"(\w+|\.{3})\s?(?::?\s?(\w+\s?(?:\||\&)?\s?\w*\??))?");
					foreach (Match match in matches) {
						typeDef.Append(", ");
						string arg = match.Groups[1].Value;
						string type = match.Groups[2].Success ? match.Groups[2].Value : "any";
						if (arg == "...") {
							typeDef.Append("...");
							typeDef.Append(type);
						} else {
							typeDef.Append(arg + ": " + type);
						}
					}
					typeDef.Append(") -> ");
					typeDef.Append(retn);
					typeDef.Append(";\n");
				}
			}
			typeDef.Append("};");
			File.WriteAllText("./TYPEDBG.lua", typeDef.ToString());
		}

	}
}
