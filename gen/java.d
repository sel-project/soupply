module java;

import std.ascii : newline;
import std.file;
import std.json;
import std.path : dirSeparator;
import std.string;

import all;

void java(JSONValue[string] jsons) {

	mkdirRecurse("../src/java/sul");

	// attributes
	foreach(string game, JSONValue attributes; jsons["attributes"].object) {
		game = toPascalCase(game);
		string data = "package sul.attributes;" ~ newline ~ newline ~
			"public enum " ~ game ~ " {" ~ newline ~ newline;
		foreach(string name, JSONValue value; attributes.object) {
			auto obj = value.object;
			data ~= `	` ~ toUpper(name) ~ `("` ~ obj["name"].str ~ `", ` ~ obj["min"].toString() ~ `, ` ~ obj["max"].toString() ~ `, ` ~ obj["default"].toString() ~ `);` ~ newline ~ newline;
		}
		data ~= `	public final String name;` ~ newline ~ `	public final float min, max, def;` ~ newline ~ newline;
		data ~= `	` ~ game ~ `(String name, float min, float max, float def) {` ~ newline;
		data ~= `		this.name = name;` ~ newline;
		data ~= `		this.min = min;` ~ newline;
		data ~= `		this.max = max;` ~ newline;
		data ~= `		this.def = def;` ~ newline;
		data ~= `	}` ~ newline ~ newline ~ `}` ~ newline;
		if(!exists("../src/java/sul/attributes")) mkdir("../src/java/sul/attributes");
		write("../src/java/sul/attributes/" ~ game ~ ".java", data);
	}

	// constants
	foreach(string game, JSONValue constants; jsons["constants"].object) {
		game = toPascalCase(game);
		string data = `package sul.constants;` ~ newline ~ newline ~
			`final class ` ~ game ~ ` {` ~ newline ~ newline ~
			`	private ` ~ game ~ `() {}` ~ newline ~ newline;
		foreach(string name, JSONValue value; constants.object) {
			data ~= `	public final static class ` ~ toPascalCase(name) ~ ` {` ~ newline ~ newline;
			foreach(string field, JSONValue v; value.object) {
				data ~= `		public final static class ` ~ toCamelCase(field) ~ ` {` ~ newline ~ newline;
				//TODO get right type from protocol
				foreach(string var, JSONValue content; v.object) {
					data ~= `			public final static int ` ~ toUpper(var) ~ ` = ` ~ content.toString() ~ `;` ~ newline;
				}
				data ~= newline ~ `		}` ~ newline ~ newline;
			}
			data ~= `	}` ~ newline ~ newline;
		}
		if(!exists("../src/java/sul/constants")) mkdir("../src/java/sul/constants");
		write("../src/java/sul/constants/" ~ game ~ ".java", data ~ "}" ~ newline);
	}

	// creative
	/*foreach(string game, JSONValue creative; jsons["creative"].object) {
		game = toPascalCase(game);
		string data = `package sul.creative;` ~ newline ~ newline ~
			`public enum ` ~ game ~ ` {` ~ newline ~ newline;
		foreach(JSONValue item ; creative.array) {
			auto obj = item.object;
			auto name = "name" in obj;
			auto id = "id" in obj;
			auto meta = "meta" in obj;
			auto ench = "enchantment" in obj;
			if(name && id) {
				data ~= `	Item(` ~ name.toString() ~ `, ` ~ id.toString() ~ `, ` ~ (meta ? meta.toString() : "0") ~ (ench ? `, Enchantment(` ~ ench.object["type"].toString() ~ `, ` ~ ench.object["level"].toString() ~ `)` : "") ~ `),` ~ newline;
			}
		}
		if(!exists("../src/java/sul/creative")) mkdir("../src/java/sul/creative");
		write("../src/java/sul/creative/" ~ game ~ ".java", data ~ newline ~ "}" ~ newline);
	}*/

}
