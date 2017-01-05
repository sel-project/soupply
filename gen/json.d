module json;

import std.conv : to;
import std.file : mkdirRecurse, _write = write;
import std.json;

import all;

void json(Attributes[string] attributes) {

	// attributes
	mkdirRecurse("../json/attributes");
	foreach(string game, Attributes attrs; attributes) {
		string data = "{\n\n\t\"__game\": " ~ JSONValue(attrs.software).toString() ~ ",\n\t\"__protocol\": " ~ attrs.protocol.to!string ~ ",\n\t\"__website\": \"https://github.com/sel-project/sel-utils\",\n\n\t\"attributes\": {\n\n";
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

}
