using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CoSRewriteCreatureStruct.CreatureDataTypes {
	public class Color3 {

		public readonly byte R, G, B;

		public Color3(byte r, byte g, byte b) {
			R = r;
			G = g;
			B = b;
		}

		public Color3(int r, int g, int b) {
			R = (byte)r;
			G = (byte)g;
			B = (byte)b;
		}

		public override string ToString() {
			return $"Color3.fromRGB({R}, {G}, {B})";
		}

	}
}
