module java;

import std.ascii : newline;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.path : dirSeparator;
import std.string;

import all;

void java(JSONValue[string] jsons) {

	mkdirRecurse("../src/java/sul/utils");

	write("../src/java/sul/utils/Item.java", q{
package sul.utils;

import sul.utils.Enchantment;

class Item {

	public final String name;
	public final int id, meta;
	public final Enchantment enchantment;

	public Item(String name, int id, int meta, Enchantment enchantment) {
		this.name = name;
		this.id = id;
		this.meta = meta;
		this.enchantment = enchantment;
	}

}
	});

	write("../src/java/sul/utils/Enchantment.java", q{
package sul.utils;

class Enchantment {

	public final int type, level;

	public Enchantment(int type, int level) {
		this.type = type;
		this.level = level;
	}

}
		});

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

	// creative
	foreach(string game, JSONValue creative; jsons["creative"].object) {
		game = toPascalCase(game);
		string data = `package sul.creative;` ~ newline ~ newline ~
			`import sul.utils.Item;` ~ newline ~
			`import sul.utils.Enchantment;` ~ newline ~ newline ~
			`public final class ` ~ game ~ ` {` ~ newline ~ newline ~
			`	public final Item[] ITEMS = new Item[]{` ~ newline ~ newline;
		foreach(JSONValue item ; creative.array) {
			auto obj = item.object;
			auto name = "name" in obj;
			auto id = "id" in obj;
			auto meta = "meta" in obj;
			auto ench = "enchantment" in obj;
			if(name && id) {
				data ~= `		new Item(` ~ name.toString() ~ `, ` ~ id.toString() ~ `, ` ~ (meta ? meta.toString() : "0") ~ `, ` ~ (ench ? `new Enchantment(` ~ ench.object["type"].toString() ~ `, ` ~ ench.object["level"].toString() ~ `)` : `null`) ~ `),` ~ newline;
			}
		}
		data ~= newline ~ `	}` ~ newline ~ newline ~ `}`;
		if(!exists("../src/java/sul/creative")) mkdir("../src/java/sul/creative");
		write("../src/java/sul/creative/" ~ game ~ ".java", data);
	}

}
