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

	enum defaultTypes = ["bool", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "string", "varshort", "varushort", "varint", "varuint", "varlong", "varulong", "uuid", "bytes"];

	@property string convert(string type) {
		auto end = min(cast(size_t)type.lastIndexOf("["), cast(size_t)type.lastIndexOf("<"), type.length);
		immutable t = type[0..end];
		if(defaultTypes.canFind(t)) return type;
		else return "[" ~ t ~ "](#" ~ toSnakeCase(t).replace("-", "_") ~ ")" ~ type[end..$];
	}

	// protocol
	foreach(string game, Protocols ptrs; protocols) {
		string data = "# " ~ ptrs.software ~ " " ~ ptrs.protocol.to!string ~ "\n\n";
		if(ptrs.data.description.length) data ~= ptrs.data.description ~ "\n\n";
		// fields (generic)
		void writeFields(Field[] fields) {
			if(fields.length) {
				bool condition, endianness, description;
				foreach(field ; fields) {
					condition |= field.condition.length != 0;
					endianness |= field.endianness.length != 0;
					description |= field.description.length != 0;
				}
				data ~= "Field | Type" ~ (condition ? " | Condition" : "") ~ (endianness ? " | Endianness" : "") ~ (description ? " | Description" : "") ~ "\n";
				data ~= "---|---" ~ (condition ? "|---" : "") ~ (endianness ? "|---" : "") ~ (description ? "|---" : "") ~ "\n";
				foreach(field ; fields) {
					data ~= toCamelCase(field.name) ~ " | " ~ convert(toCamelCase(field.type)) ~ (condition ? " | " ~ toCamelCase(field.condition) : "") ~ (endianness ? field.endianness.replace("-", " ") : "") ~ (description ? " | " ~ field.description : "") ~ "\n";
				}
				data ~= "\n";
			}
		}
		//TODO encoding
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
				data ~= "#### " ~ pretty(toCamelCase(packet.name)) ~ "\n\n";
				if(packet.description.length) data ~= packet.description ~ "\n\n";
				writeFields(packet.fields);
			}
		}
		// types
		if(ptrs.data.types.length) {
			data ~= "--------\n\n";
			data ~= "### Types\n\n";
			foreach(type ; ptrs.data.types) {
				data ~= "#### " ~ pretty(toCamelCase(type.name)) ~ "\n\n";
				if(type.description.length) data ~= type.description ~ "\n\n";
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
