module soupply.gen.csharp;

import soupply.data;
import soupply.generator;
import soupply.util;

class CSharpGenerator : Generator {

	static this() {
		Generator.register!CSharpGenerator("C#", "csharp", "src/" ~ SOFTWARE, ["/*", "*", "*/"]);
	}

	override void generateImpl(Data data) {}

}
