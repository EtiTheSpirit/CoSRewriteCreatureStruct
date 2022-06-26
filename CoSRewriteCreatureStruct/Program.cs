using CoSRewriteCreatureStruct.CreatureDataTypes;
using System;
using System.Diagnostics;
using System.Text;

namespace CoSRewriteCreatureStruct {

	

	public static class Program {

		// Type Defs Base
		public static readonly string TYPE_DEFS = File.ReadAllText("./Lua/Templates/CreatureTypeDefsBase.lua");

		// Procedural Generator
		public static readonly string BASE_INFO = File.ReadAllText("./Lua/Templates/ProcGenBase.lua");
		public static readonly string PROXY_STRING = File.ReadAllText("./Lua/Templates/ProcGenCloser.lua");

		// Plugin Converter
		public static readonly string PLUGIN_BEHAVIOR_BASE = File.ReadAllText("./Lua/Templates/PluginBehaviors.lua");

		// This serves as a means to create the template (as the plugin data and default values for use in the game)
		// as well as the Luau type definition
		// You should share this with your peers

		public static string GetProcGen(Creature creature) {
			Console.WriteLine("Converting to Luau template object...");
			string asLuaObject = creature.ToLuaObject();

			Console.WriteLine("Converting to plugin template object...");
			string asPluginObject = creature.ToPluginObject();

			Console.WriteLine("Generating Luau type definition...");
			string asType = creature.ToType();

			Console.WriteLine("Finalizing ProcGen module generation...");
			StringBuilder result = new StringBuilder();
			result.AppendLine(BASE_INFO);
			result.AppendLine(asLuaObject);
			result.AppendLine(asPluginObject);
			result.AppendLine(asType);
			result.AppendLine(PROXY_STRING);
			result.AppendLine("export type CreatureAreaAilmentStats = {");
			result.Append(creature.Specifications.MainInfo.Stats.AreaAilments[0].ToType(noHeader: true));
			result.AppendLine("}");
			result.AppendLine("export type CreatureOffensiveAilmentStats = {");
			result.Append(creature.Specifications.MainInfo.Stats.MeleeAilments[0].ToType(noHeader: true));
			result.AppendLine("}");
			result.AppendLine("export type CreatureDefensiveAilmentStats = {");
			result.Append(creature.Specifications.MainInfo.Stats.DefensiveAilments[0].ToType(noHeader: true));
			result.AppendLine("}");
			result.AppendLine("export type CreatureResistanceStats = {");
			result.Append(creature.Specifications.MainInfo.Stats.AilmentResistances[0].ToType(noHeader: true));
			result.AppendLine("}");
			result.AppendLine();
			result.Append(@"return table.deepFreeze({
	CreatureObjectTemplate = CreatureObjectTemplate; 
	IsolatedSpecifications = IsolatedSpecifications;
	PluginTemplate = CreatureObjectPluginData; 
})");
			return result.ToString();
		}

		public static string GetTypeDefs(Creature creature) {
			Console.WriteLine("Generating runtime structure for player characters...");
			string asInstanceType = creature.Specifications.ToInstanceType();

			StringBuilder alt = new StringBuilder();
			string[] lines = PROXY_STRING.Split("\n");
			for (int i = 0; i < lines.Length - 1; i += 1) {
				if (lines[i].StartsWith("export type ")) {
					// Get the type exports from procgen, split it by the = sign (export type TypeName )
					// Then strip away "export type", and use it to access the type from procgen
					// export type TypeName = ProcGen.TypeName
					string line = lines[i];
					string[] type = line.Split(" = ");
					string part = type[0];
					alt.Append(part);
					alt.Append(" = ProcGen.");
					alt.AppendLine(part.Replace("export type ", ""));
				}
			}
			alt.AppendLine("export type CreatureData = ProcGen.CreatureData");

			StringBuilder typeDefsModule = new StringBuilder(TYPE_DEFS);
			typeDefsModule.AppendLine(asInstanceType);
			typeDefsModule.AppendLine(alt.ToString());
			typeDefsModule.AppendLine(@"local retData = table.deepFreeze({
	CreatureObjectTemplate = ProcGen.CreatureObjectTemplate;
	IsolatedSpecifications = ProcGen.IsolatedSpecifications;
	PluginTemplate = ProcGen.PluginTemplate
})");
			typeDefsModule.AppendLine("return retData");
			return typeDefsModule.ToString();
		}

		private static void AppendLua(FileInfo lua, StringBuilder builder) {
			string[] data = File.ReadAllLines(lua.FullName);
			if (!data[^1].EndsWith(";")) {
				data[^1] = data[^1] + ";";
			}

			foreach (string line in data) {
				builder.Append('\t');
				builder.AppendLine(line);
			}
		}

		public static string GetPluginBehaviors(Creature creature) {
			StringBuilder copyBehaviors = new StringBuilder();
			StringBuilder hardCodedBehaviors = new StringBuilder();
			StringBuilder intrinsicProperties = new StringBuilder();
			StringBuilder validators = new StringBuilder();

			DirectoryInfo copy = new DirectoryInfo("./Lua/CopyBehaviors");
			DirectoryInfo hard = new DirectoryInfo("./Lua/HardCodedCopyBehaviors");
			DirectoryInfo intrinsicProps = new DirectoryInfo("./Lua/IntrinsicProperties");
			DirectoryInfo validationBehaviors = new DirectoryInfo("./Lua/ValidationBehaviors");

			Console.WriteLine("Generating agnostic upgrade information...");
			foreach (FileInfo copyBehavior in copy.GetFiles()) {
				if (copyBehavior.Extension.ToLower() != ".lua") continue;
				/*
				string[] data = File.ReadAllLines(copyBehavior.FullName);
				if (!data[^1].EndsWith(";")) {
					data[^1] = data[^1] + ";";
				}

				foreach (string line in data) {
					copyBehaviors.Append('\t');
					copyBehaviors.AppendLine(line);
				}*/
				AppendLua(copyBehavior, copyBehaviors);
			}

			Console.WriteLine("Generating hard-coded upgrade information...");
			foreach (FileInfo hardcopyBehavior in hard.GetFiles()) {
				if (hardcopyBehavior.Extension.ToLower() != ".lua") continue;
				/*
				string[] data = File.ReadAllLines(hardcopyBehavior.FullName);
				if (!data[^1].EndsWith(";")) {
					data[^1] = data[^1] + ";";
				}

				foreach (string line in data) {
					hardCodedBehaviors.Append('\t');
					hardCodedBehaviors.AppendLine(line);
				}
				*/
				AppendLua(hardcopyBehavior, hardCodedBehaviors);
			}

			Console.WriteLine("Generating intrinsic properties...");
			foreach (FileInfo intrinsic in intrinsicProps.GetFiles()) {
				if (intrinsic.Extension.ToLower() != ".lua") continue;
				AppendLua(intrinsic, intrinsicProperties);
			}

			Console.WriteLine("Generating validation behaviors...");
			foreach (FileInfo validator in validationBehaviors.GetFiles()) {
				if (validator.Extension.ToLower() != ".lua") continue;
				AppendLua(validator, validators);
			}


			return PLUGIN_BEHAVIOR_BASE
				.Replace("%%CS_AGNOSTIC_COPY%%", copyBehaviors.ToString())
				.Replace("%%CS_HARDCODE_COPY%%", hardCodedBehaviors.ToString())
				.Replace("%%CS_INTRINSIC_COPY%%", intrinsicProperties.ToString())
				.Replace("%%CS_VALIDATION_COPY%%", validators.ToString());
		}

		public static void Main() {

			// GenerateTypeDump.Generate(new FileInfo("./Lua/TypeGenerators/Resources/SpeciesInfoProvider.lua"), "SpeciesInfoProvider", "Species");

			Console.ForegroundColor = ConsoleColor.Green;
			Console.WriteLine("Generating creature struct...");

			Console.ForegroundColor = ConsoleColor.DarkGreen;
			Creature creature = new();
			string procgenStr = GetProcGen(creature);
			string typedefsStr = GetTypeDefs(creature);
			string upgraderStr = GetPluginBehaviors(creature);

			Console.WriteLine("Writing files...");
			File.WriteAllText("./ProcGen.lua", procgenStr);
			File.WriteAllText("./CreatureTypeDefs.lua", typedefsStr);
			File.WriteAllText("./UpgradeBehaviors.lua", upgraderStr);

			Console.ForegroundColor = ConsoleColor.Green;
			Console.Write("Done! Would you like to open the files? [Y/N] > ");
			FileInfo procgen = new FileInfo("./ProcGen.lua");
			FileInfo ctd = new FileInfo("./CreatureTypeDefs.lua");
			FileInfo upgrader = new FileInfo("./UpgradeBehaviors.lua");
			while (true) {
				ConsoleKeyInfo key = Console.ReadKey(true);
				if (key.Key == ConsoleKey.Y) {
					//Process.Start("notepad++", procgen.FullName);
					//Process.Start("notepad++", ctd.FullName);
					Util.OpenDefaultEditor(procgen);
					Util.OpenDefaultEditor(ctd);
					Util.OpenDefaultEditor(upgrader);
					break;
				} else if (key.Key == ConsoleKey.N) {
					break;
				} else {
					Console.Beep(); // no
				}
			}
			/*
			Console.Write("Done! Press any key to quit...");
			Console.ReadKey(true);
			*/
			Environment.Exit(0);
		}
	}
}