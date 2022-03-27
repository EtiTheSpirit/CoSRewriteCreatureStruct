using CoSRewriteCreatureStruct.CreatureDataTypes;
using System;
using System.Text;

namespace CoSRewriteCreatureStruct {
	public static class Program {

		// This serves as a means to create the template (as the plugin data and default values for use in the game)
		// as well as the Luau type definition
		// You should share this with your peers

		public static void Main(string[] args) {
			Creature creature = new Creature {};

			string asLuaObject = creature.ToLuaObject();
			string asPluginObject = creature.ToPluginObject();
			string asType = creature.ToType();

			StringBuilder result = new StringBuilder();
			result.AppendLine("--!strict");
			result.AppendLine(asLuaObject);
			result.AppendLine(asPluginObject);
			result.AppendLine(asType);
			result.Append("return {CreatureObjectTemplate, CreatureObjectPluginData}");

			File.WriteAllText("./ProcGen.lua", result.ToString());

			File.WriteAllText("./testobject.lua", asLuaObject);
			File.WriteAllText("./testplugin.lua", asPluginObject);
			File.WriteAllText("./testtypedef.lua", asType);
		}
	}
}