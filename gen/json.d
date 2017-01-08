module json;

import std.conv : to;
import std.file : mkdirRecurse, _write = write;
import std.json;

import all;

void json(Attributes[string] attributes, Protocols[string] protocols, Creative[string] creative) {

	// attributes
	mkdirRecurse("../json/attributes");
	foreach(string game, Attributes attrs; attributes) {
		string data = "{\n\n\t\"__software\": " ~ JSONValue(attrs.software).toString() ~ ",\n\t\"__protocol\": " ~ attrs.protocol.to!string ~ ",\n\t\"__website\": \"https://github.com/sel-project/sel-utils\",\n\n\t\"attributes\": {\n\n";
		foreach(i, attr; attrs.data) {
			data ~= "\t\t\"" ~ toSnakeCase(attr.id) ~ "\": {\n\n";
			data ~= "\t\t\t\"name\": \"" ~ attr.name ~ "\",\n";
			data ~= "\t\t\t\"min\": " ~ attr.min.to!string ~ ",\n";
			data ~= "\t\t\t\"max\": " ~ attr.max.to!string ~ ",\n";
			data ~= "\t\t\t\"default\": " ~ attr.def.to!string ~ "\n";
			data ~= "\n\t\t}";
			if(i != attrs.data.length - 1) data ~= ",";
			data ~= "\n\n";
		}
		data ~= "\t}\n\n}\n";
		_write("../json/attributes/" ~ game ~ ".json", data);
	}

	// creative items
	mkdirRecurse("../json/creative");
	foreach(string game, Creative c; creative) {
		string data = "{\n\n\t\"__software\": " ~ JSONValue(c.software).toString() ~ ",\n\t\"__protocol\": " ~ c.protocol.to!string ~ ",\n\t\"__website\": \"https://github.com/sel-project/sel-utils\",\n\n\t\"items\": [\n\n";
		foreach(i, item; c.data) {
			data ~= "\t\t{\n";
			data ~= "\t\t\t\"name\": " ~ JSONValue(item.name).toString() ~ ",\n";
			data ~= "\t\t\t\"id\": " ~ to!string(item.id);
			if(item.meta != 0) data ~= ",\n\t\t\t\"meta\": " ~ to!string(item.meta);
			if(item.enchantments.length) {
				data ~= ",\n\t\t\t\"enchantments\": [\n";
				foreach(j, enchantment; item.enchantments) {
					data ~= "\t\t\t\t{\n";
					data ~= "\t\t\t\t\t\"id\": " ~ to!string(enchantment.id) ~ ",\n";
					data ~= "\t\t\t\t\t\"level\": " ~ to!string(enchantment.level) ~ "\n";
					data ~= "\t\t\t\t}";
					if(j < item.enchantments.length - 1) data ~= ",";
					data ~= "\n";
				}
				data ~= "\t\t\t]";
			}
			data ~= "\n\t\t}";
			if(i != c.data.length - 1) data ~= ",\n";
			else data ~= "\n\n";
		}
		data ~= "\t]\n\n}\n";
		_write("../json/creative/" ~ game ~ ".json", data);
	}

}
