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
		
	}
}
