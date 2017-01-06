module java;

import std.algorithm : canFind, min;
import std.ascii : newline;
import std.conv : to;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.path : dirSeparator;
import std.string;

import all;

void java(Attributes[string] attributes, Protocols[string] protocols, JSONValue[string] jsons) {

	mkdirRecurse("../src/java/sul/utils");

	enum defaultTypes = ["boolean", "byte", "short", "int", "long", "float", "double", "String", "UUID"];

	enum string[string] defaultAliases = [
		"bool": "boolean",
		"ubyte": "byte",
		"ushort": "short",
		"uint": "int",
		"ulong": "long",
		"string": "String",
		"uuid": "UUID",
		"bytes": "byte[]",
		"triad": "int",
		"varshort": "short",
		"varushort": "short",
		"varint": "int",
		"varuint": "int",
		"varlong": "long",
		"varulong": "long"
	];

	// attributes
	foreach(string game, Attributes attrs; attributes) {
		game = toPascalCase(game);
		string data = "package sul.attributes;\n\npublic enum " ~ game ~ " {\n\n";
		foreach(attr ; attrs.data) {
			data ~= "\t" ~ toUpper(attr.id) ~ "(\"" ~ attr.name ~ "\", " ~ attr.min.to!string ~ ", " ~ attr.max.to!string ~ ", " ~ attr.def.to!string ~ ");\n\n";
		}
		data ~= "\tpublic final String name;\n\tpublic final float min, max, def;\n\n";
		data ~= "\t" ~ game ~ "(String name, float min, float max, float def) {\n";
		data ~= "\t\tthis.name = name;\n";
		data ~= "\t\tthis.min = min;\n";
		data ~= "\t\tthis.max = max;\n";
		data ~= "\t\tthis.def = def;\n";
		data ~= "\t}\n\n}\n";
		if(!exists("../src/java/sul/attributes")) mkdir("../src/java/sul/attributes");
		write("../src/java/sul/attributes/" ~ game ~ ".java", data, "attributes/" ~ game);
	}

	write("../src/java/sul/utils/Packet.java", q{
package sul.utils;

abstract class Packet {

	abstract byte[] encode();

	abstract void decode(byte[] buffer);

}
	});

	// protocols
	foreach(string game, Protocols prs; protocols) {
		mkdirRecurse("../src/java/sul/protocol/" ~ game ~ "/types");
		@property string convert(string type) {
			auto end = min(cast(size_t)type.lastIndexOf("["), cast(size_t)type.lastIndexOf("<"), type.length);
			auto t = type[0..end];
			auto a = t in defaultAliases;
			if(a) t = *a;
			if(!defaultTypes.canFind(t)) t = toPascalCase(t);
			return t ~ type[end..$];
		}
		immutable id = convert(prs.data.id);
		foreach(type ; prs.data.types) {
			string data = "package sul.protocol." ~ game ~ ".types;\n\nimport java.util.UUID;\n\n";
			if(type.description.length) data ~= javadoc("", type.description);
			data ~= "final class " ~ toPascalCase(type.name) ~ " {\n\n";
			foreach(i, field; type.fields) {
				if(field.description.length) {
					if(i != 0) data ~= "\n";
					data ~= javadoc("\t", field.description);
				}
				data ~= "\tpublic " ~ convert(field.type) ~ " " ~ toCamelCase(field.name) ~ ";\n";
			}
			data ~= "\n}";
			write("../src/java/sul/protocol/" ~ game ~ "/types/" ~ toPascalCase(type.name) ~ ".java", data, "protocol/" ~ game);
		}
		foreach(section ; prs.data.sections) {
			immutable sectionName = section.name.replace("_", "");
			mkdirRecurse("../src/java/sul/protocol/" ~ game ~ "/" ~ sectionName);
			foreach(packet ; section.packets) {
				string data = "package sul.protocol." ~ game ~ "." ~ sectionName ~ ";\n\nimport java.util.UUID;\n\nimport sul.protocol." ~ game ~ ".types.*;\nimport sul.utils.Packet;\n\n";
				if(packet.description.length) {
					data ~= javadoc("", packet.description);
				}
				data ~= "class " ~ toPascalCase(packet.name) ~ " extends Packet {\n\n";
				data ~= "\tpublic final static " ~ id ~ " ID = (" ~ id ~ ")" ~ to!string(packet.id) ~ ";\n\n";
				data ~= "\tpublic final static boolean CLIENTBOUND = " ~ to!string(packet.clientbound) ~ ";\n";
				data ~= "\tpublic final static boolean SERVERBOUND = " ~ to!string(packet.serverbound) ~ ";\n\n";
				foreach(field ; packet.fields) {
					if(field.constants.length) {
						immutable fieldType = convert(field.type);
						data ~= "\t// " ~ field.name.replace("_", " ") ~ "\n";
						foreach(constant ; field.constants) {
							data ~= "\tpublic final static " ~ fieldType ~ " " ~ toUpper(constant.name) ~ " = (" ~ fieldType ~ ")" ~ constant.value ~ ";\n";
						}
						data ~= "\n";
					}
				}
				foreach(i, field; packet.fields) {
					if(field.description.length) {
						if(i != 0) data ~= "\n";
						data ~= javadoc("\t", field.description);
					}
					data ~= "\tpublic " ~ convert(field.type) ~ " " ~ toCamelCase(field.name) ~ ";\n";
				}
				data ~= "\n\t@Override\n\tpublic byte[] encode() {\n";

				data ~= "\t}\n";
				data ~= "\n\t@Override\n\tpublic void decode(byte[] buffer) {\n";

				data ~= "\t}\n";
				if(packet.variants.length) {
					data ~= "\n";
					foreach(j, variant; packet.variants) {
						if(variant.description.length) data ~= javadoc("\t", variant.description);
						data ~= "\tpublic static class " ~ toPascalCase(variant.name) ~ " extends " ~ toPascalCase(packet.name) ~ " {\n\n";

						data ~= "\t}\n\n";
					}
				} else {
					data ~= "\n";
				}
				data ~= "}";
				write("../src/java/sul/protocol/" ~ game ~ "/" ~ sectionName ~ "/" ~ toPascalCase(packet.name) ~ ".java", data, "protocol/" ~ game);
			}
		}
	}

}

string javadoc(string space, string description) {
	return space ~ "/**\n" ~ javadocImpl(space, description.split(" ")) ~ space ~ " */\n";
}

string javadocImpl(string space, string[] words) {
	size_t length;
	string[] ret;
	while(length < 80 && words.length) {
		ret ~= words[0];
		length += words[0].length + 1;
		words = words[1..$];
	}
	return space ~ " * " ~ ret.join(" ") ~ "\n" ~ (words.length ? javadocImpl(space, words) : "");
}
