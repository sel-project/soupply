module java;

import std.ascii : newline;
import std.conv : to;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.path : dirSeparator;
import std.string;

import all;

void java(Attributes[string] attributes, JSONValue[string] jsons) {

	mkdirRecurse("../src/java/sul/utils");

	enum string[string] defaultAliases = [
		"ubyte": "short",
		"ushort": "int",
		"uint": "long",
		"ulong": "long",
		"string": "String",
		"uuid": "UUID",
		"remaining_bytes": "byte[]",
		"triad": "int",
		"varshort": "short",
		"varushort": "int",
		"varint": "int",
		"varuint": "long",
		"varlong": "long",
		"varulong": "long"
	];

	// attributes
	foreach(string game, Attributes attrs; attributes) {
		game = toPascalCase(game);
		string data = "package sul.attributes;\n\npublic enum " ~ game ~ " {\n\n";
		foreach(attr ; attrs.data) {
			//TODO convert to snake case
			data ~= "\t" ~ toUpper(toSnakeCase(attr.id)) ~ "(\"" ~ attr.name ~ "\", " ~ attr.min.to!string ~ ", " ~ attr.max.to!string ~ ", " ~ attr.def.to!string ~ ");\n\n";
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
	foreach(string game, JSONValue constants; jsons["constants"]) {
		string data = `package sul.constants;` ~ newline ~ newline ~
			`final class ` ~ toPascalCase(game) ~ ` {` ~ newline ~ newline ~
			`	private ` ~ toPascalCase(game) ~ `() {}` ~ newline ~ newline;
		foreach(string name, JSONValue value; constants) {
			JSONValue[] fields = null; // from protocol's
			foreach(JSONValue category ; jsons["protocol"].object[game].object["packets"].object) {
				foreach(string packet_name, JSONValue packet; category.object) {
					if(packet_name == name) {
						fields = packet.object["fields"].array;
						break;
					}
				}
			}
			data ~= `	public final static class ` ~ toPascalCase(name) ~ ` {` ~ newline ~ newline;
			foreach(string field, JSONValue v; value.object) {
				data ~= `		public final static class ` ~ toCamelCase(field) ~ ` {` ~ newline ~ newline;
				string type = "int";
				if(fields !is null) {
					foreach(packet_field ; fields) {
						auto obj = packet_field.object;
						if(obj["name"].str == field) {
							type = obj["type"].str;
							auto conv = type in defaultAliases;
							if(conv) type = *conv;
							break;
						}
					}
				}
				foreach(string var, JSONValue content; v) {
					data ~= `			public final static ` ~ type ~ ` ` ~ toUpper(var) ~ ` = ` ~ content.toString() ~ `;` ~ newline;
				}
				data ~= newline ~ `		}` ~ newline ~ newline;
			}
			data ~= `	}` ~ newline ~ newline;
		}
		if(!exists("../src/java/sul/constants")) mkdir("../src/java/sul/constants");
		write("../src/java/sul/constants/" ~ toPascalCase(game) ~ ".java", data ~ "}" ~ newline);
	}

}
