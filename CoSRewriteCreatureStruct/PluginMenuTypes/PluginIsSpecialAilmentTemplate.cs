using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.PluginMenuTypes {
	public class PluginIsSpecialAilmentTemplate : PluginMenuLimiterAttribute {
		public override string? ValidateData() => null;

		public override StringKeyTable ToLuaTable() {
			throw new NotImplementedException();
		}
	}
}
