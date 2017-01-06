module doc;

import std.algorithm : min, canFind;
import std.conv : to;
static import std.file;
import std.xml;
import std.path : dirSeparator;
import std.string;

import std.stdio : writeln;

import all;

void doc(Protocols[string] protocols) {

	std.file.mkdirRecurse("../doc");

	enum defaultTypes = ["bool", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "string", "varshort", "varushort", "varint", "varuint", "varlong", "varulong", "triad", "uuid", "bytes"];

	@property string convert(string type) {
		auto end = min(cast(size_t)type.lastIndexOf("["), cast(size_t)type.lastIndexOf("<"), type.length);
		immutable t = type[0..end];
		immutable e = type[end..$].replace(`<`, `\<`).replace(`>`, `\>`);
		if(defaultTypes.canFind(t)) return t ~ e;
		else return "[" ~ t ~ "](#" ~ toSnakeCase(t).replace("_", "-") ~ ")" ~ e;
	}

	foreach(string game, Protocols ptrs; protocols) {
		string data = "# " ~ ptrs.software ~ " " ~ ptrs.protocol.to!string ~ "\n\n";
		if(ptrs.data.description.length) data ~= ptrs.data.description ~ "\n\n";
		// fields (generic)
		void writeFields(Field[] fields, size_t spaces=1, string fieldDesc="Fields") {
			string space;
			foreach(i ; 0..spaces) space ~= "\t";
			if(fields.length) {
				data ~= space ~ "**" ~fieldDesc ~ "**:\n\n";
				foreach(field ; fields) {
					data ~= space ~ "* " ~ toCamelCase(field.name) ~ "\n\n";
					data ~= space ~ "\t**Type**: " ~ convert(toCamelCase(field.type)) ~ "\n\n";
					if(field.condition.length) data ~= space ~"\t**When**: " ~ toCamelCase(field.condition) ~ "\n\n";
					if(field.endianness.length) data ~= space ~ "\t**Endianness**: " ~ pretty(toCamelCase(field.endianness)) ~ "\n\n";
					if(field.description.length) data ~= space ~ "\t" ~ field.description ~ "\n\n";
					if(field.constants.length) {
						data ~= space ~ "\t**Constants**:\n\n";
						data ~= space ~ "\tName | Value\n" ~ space ~ "\t---|:---:\n";
						foreach(constant ; field.constants) {
							data ~= space ~ "\t" ~ toCamelCase(constant.name) ~ " | " ~ constant.value ~ "\n";
						}
						data ~= "\n";
					}
				}
				data ~= "\n";
			}
		}
		// endianness
		data ~= "## Endianness\n\n";
		if("*" in ptrs.data.endianness) data ~= "all: " ~ pretty(toCamelCase(ptrs.data.endianness["*"])) ~ "\n\n";
		foreach(string type, string end; ptrs.data.endianness) {
			if(type != "*") data ~= convert(type) ~ ": " ~ pretty(toCamelCase(end)) ~ "\n\n";
		}
		data ~= "--------\n\n";
		// packets
		data ~= "## Packets\n\nSection | Packets\n---|:---:\n";
		foreach(section ; ptrs.data.sections) {
			data ~= "[" ~ pretty(toCamelCase(section.name)) ~ "](#" ~ section.name.replace("_", "-") ~ ") | " ~ to!string(section.packets.length) ~ "\n";
		}
		data ~= "\n";
		foreach(section ; ptrs.data.sections) {
			data ~= "### " ~ pretty(toCamelCase(section.name)) ~ "\n\n";
			data ~= "Packet | DEC | HEX | Clientbound | Serverbound\n---|:---:|:---:|:---:|:---:\n";
			foreach(packet ; section.packets) {
				data ~= "[" ~ pretty(toCamelCase(packet.name)) ~ "](#" ~ packet.name.replace("_", "-") ~ ") | " ~ packet.id.to!string ~ " | " ~ packet.id.to!string(16) ~ " | " ~ (packet.clientbound ? "✓" : "") ~ " | " ~ (packet.serverbound ? "✓" : "") ~ "\n";
			}
			data ~= "\n";
			foreach(packet ; section.packets) {
				data ~= "* ### " ~ pretty(toCamelCase(packet.name)) ~ "\n\n";
				data ~= "\t**ID**: " ~ to!string(packet.id) ~ "\n\n";
				data ~= "\t**Clientbound**: " ~ (packet.clientbound ? "yes" : "no") ~ "\n\n";
				data ~= "\t**Serverbound**: " ~ (packet.serverbound ? "yes" : "no") ~ "\n\n";
				if(packet.description.length) data ~= "\t" ~ packet.description ~ "\n\n";
				writeFields(packet.fields);
				if(packet.variants.length) {
					data ~= "\t**Variants**:\n\n\t**Field**: " ~ toCamelCase(packet.variantField) ~ "\n\n";
					foreach(variant ; packet.variants) {
						data ~= "\t* " ~ pretty(toCamelCase(variant.name)) ~ "\n\n\t\t**Field's value**: " ~ variant.value ~ "\n\n";
						writeFields(variant.fields, 2, "Additional Fields");
					}
				}
			}
		}
		// types
		if(ptrs.data.types.length) {
			data ~= "--------\n\n";
			data ~= "## Types\n\n";
			foreach(type ; ptrs.data.types) {
				data ~= "* ### " ~ pretty(toCamelCase(type.name)) ~ "\n\n";
				if(type.description.length) data ~= "\t" ~ type.description ~ "\n\n";
				writeFields(type.fields);
			}
		}
		std.file.write("../doc/" ~ game ~ ".md", data);
	}

}

@property string pretty(string name) {
	string ret;
	foreach(c ; name) {
		if(c >= 'A' && c <= 'Z' || c >= '0' && c <= '9') ret ~= ' ';
		ret ~= c;
	}
	if(!ret.length) return ret;
	else return toUpper(ret[0..1]) ~ ret[1..$];
}
