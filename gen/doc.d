module doc;

import std.algorithm : min, canFind, sort;
import std.conv : to;
import std.datetime : Date;
static import std.file;
import std.xml;
import std.path : dirSeparator;
import std.string;
import std.typecons : Tuple, tuple;

import std.stdio : writeln;

import all;

void doc(Attributes[string] attributes, Protocols[string] protocols) {

	std.file.mkdirRecurse("../doc");

	enum defaultTypes = ["bool", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "string", "varshort", "varushort", "varint", "varuint", "varlong", "varulong", "triad", "uuid", "bytes", "metadata"];

	@property string convert(string type) {
		auto end = min(cast(size_t)type.lastIndexOf("["), cast(size_t)type.lastIndexOf("<"), type.length);
		immutable t = type[0..end];
		immutable e = type[end..$].replace(`<`, `\<`).replace(`>`, `\>`);
		if(defaultTypes.canFind(t)) return t ~ e;
		else return "[" ~ t ~ "](#" ~ toSnakeCase(t).replace("_", "-") ~ ")" ~ e;
	}

	foreach(string game, Protocols ptrs; protocols) {
		auto attributes = game in attributes;
		string data = "# " ~ ptrs.software ~ " " ~ ptrs.protocol.to!string ~ "\n\n";
		string[] jumps = ["[Endianness](#endianness)", "[Packets](#packets)"];
		if(ptrs.data.types.length) jumps ~= "[Types](#types)";
		if(attributes) jumps ~= "[Attributes](#attributes)";
		data ~= "**Jump to**: " ~ jumps.join(", ") ~ "\n\n";
		if(ptrs.data.released.length) {
			auto spl = ptrs.data.released.split("/");
			if(spl.length == 3) {
				immutable day = spl[2] ~ (){
					auto ret = spl[2];
					if(spl[2].length >= 2 && spl[0][$-2] != '1') {
						if(spl[2][$-1] == '1') return "st";
						else if(spl[2][$-1] == '2') return "nd";
						else if(spl[2][$-1] == '3') return "rd";
					}
					return "th";
				}();
				immutable month = (){
					final switch(to!size_t(spl[1])) {
						case 1: return "January";
						case 2: return "February";
						case 3: return "March";
						case 4: return "April";
						case 5: return "May";
						case 6: return "June";
						case 7: return "July";
						case 8: return "August";
						case 9: return "September";
						case 10: return "October";
						case 11: return "November";
						case 12: return "December";
					}
				}();
				auto date = Date(to!int(spl[0]), to!int(spl[1]), to!int(spl[2]));
				data ~= "**Released**: " ~ month ~ " " ~ day ~ ", " ~ spl[0] ~ "\n\n";
			}
		}
		if(ptrs.data.from.length) {
			if(ptrs.data.to.length) {
				if(ptrs.data.from == ptrs.data.to) data ~= "Used in version **" ~ ptrs.data.from ~ "**";
				else data ~= "Used from version **" ~ ptrs.data.from ~ "** to **" ~ ptrs.data.to ~ "**";
			} else {
				data ~= "In use since version **" ~ ptrs.data.from ~ "**";
			}
			data ~= "\n\n";
		}
		if(ptrs.data.description.length) data ~= ptrs.data.description ~ "\n\n";
		data ~= "--------\n\n";
		// field (generic)
		void writeFields(string namespace, Field[] fields, size_t spaces=1, string fieldDesc="Fields") {
			string space;
			foreach(i ; 0..spaces) space ~= "\t";
			if(fields.length) {
				data ~= space ~ "**" ~fieldDesc ~ "**:\n\n";
				bool endianness, condition;
				foreach(field ; fields) {
					endianness |= field.endianness.length != 0;
					condition |= field.condition.length != 0;
				}
				data ~= space ~ "Name | Type" ~ (endianness ? " | Endianness" : "") ~ (condition ? " | When" : "") ~ "\n";
				data ~= space ~ "---|---" ~ (endianness ? "|:---:" : "") ~ (condition ? "|:---:" : "") ~ "\n";
				foreach(field ; fields) {
					data ~= space;
					if(field.description.length || field.constants.length) data ~= "[" ~ toCamelCase(field.name) ~ "](#" ~ link(namespace, field.name) ~ ")";
					else data ~= toCamelCase(field.name);
					data ~= " | " ~ convert(toCamelCase(field.type)) ~ (endianness ? " | " ~ field.endianness.replace("_", " ") : "") ~ (condition ? " | " ~ toCamelCase(field.condition) : "") ~ "\n";
				}
				data ~= "\n";
				foreach(field ; fields) {
					if(field.description.length || field.constants.length) {
						data ~= space ~ "* <a name=\"" ~ link(namespace, field.name) ~ "\"></a>**" ~ toCamelCase(field.name) ~ "**\n\n";
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
				}
				data ~= "\n";
			}
		}
		// endianness
		data ~= "## Endianness\n\n";
		if("*" in ptrs.data.endianness) data ~= "every type: " ~ ptrs.data.endianness["*"].replace("_", " ") ~ "\n\n";
		foreach(string type, string end; ptrs.data.endianness) {
			if(type != "*") data ~= convert(type) ~ ": " ~ end.replace("_", " ") ~ "\n\n";
		}
		data ~= "--------\n\n";
		// packets
		data ~= "## Packets\n\nSection | Packets\n---|:---:\n";
		foreach(section ; ptrs.data.sections) {
			data ~= "[" ~ pretty(toCamelCase(section.name)) ~ "](#" ~ section.name.replace("_", "-") ~ ") | " ~ to!string(section.packets.length) ~ "\n";
		}
		data ~= "\n";
		foreach(section ; ptrs.data.sections) {
			//data ~= "<a name=\"" ~ link(section.name) ~ "\"></a>\n";
			data ~= "### " ~ pretty(toCamelCase(section.name)) ~ "\n\n";
			data ~= "Packet | DEC | HEX | Clientbound | Serverbound\n---|:---:|:---:|:---:|:---:\n";
			foreach(packet ; section.packets) {
				data ~= "[" ~ pretty(toCamelCase(packet.name)) ~ "](#" ~ link(section.name, packet.name) ~ ") | " ~ packet.id.to!string ~ " | " ~ packet.id.to!string(16) ~ " | " ~ (packet.clientbound ? "✓" : "") ~ " | " ~ (packet.serverbound ? "✓" : "") ~ "\n";
			}
			data ~= "\n";
			foreach(packet ; section.packets) {
				data ~= "<a name=\"" ~ link(section.name, packet.name) ~ "\"></a>\n";
				data ~= "* ### " ~ pretty(toCamelCase(packet.name)) ~ "\n\n";
				data ~= "\t**ID**: " ~ to!string(packet.id) ~ "\n\n";
				data ~= "\t**Clientbound**: " ~ (packet.clientbound ? "yes" : "no") ~ "\n\n";
				data ~= "\t**Serverbound**: " ~ (packet.serverbound ? "yes" : "no") ~ "\n\n";
				if(packet.description.length) data ~= "\t" ~ packet.description ~ "\n\n";
				writeFields(link(section.name, packet.name), packet.fields);
				if(packet.variants.length) {
					data ~= "\t**Variants**:\n\n";
					data ~= "\tVariant | Field | Value\n\t---|---|:---:\n";
					foreach(variant ; packet.variants) {
						data ~= "\t[" ~ pretty(toCamelCase(variant.name)) ~ "](#" ~ link(section.name, packet.name, variant.name) ~ ") | " ~ toCamelCase(packet.variantField) ~ " | " ~ variant.value ~ "\n";
					}
					data ~= "\n";
					foreach(variant ; packet.variants) {
						data ~= "\t* <a name=\"" ~ link(section.name, packet.name, variant.name) ~ "\"></a>**" ~ pretty(toCamelCase(variant.name)) ~ "**\n\n";
						writeFields(link(section.name, packet.name, variant.name), variant.fields, 2, "Additional Fields");
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
				writeFields(type.name, type.fields);
			}
		}
		// attributes
		if(attributes) {
			data ~= "--------\n\n";
			data ~= "## Attributes\n\n";
			data ~= "Name | Key | Min | Max | Default\n---|---|:---:|:---:|:---:\n";
			foreach(attribute ; (*attributes).data) {
				data ~= pretty(toCamelCase(attribute.id)) ~ " | " ~ attribute.name ~ " | " ~ to!string(attribute.min) ~ " | " ~ to!string(attribute.max) ~ " | " ~ to!string(attribute.def) ~ "\n";
			}
			data ~= "\n";
		}
		immutable ps = ptrs.protocol.to!string;
		std.file.mkdirRecurse("../doc/" ~ game[0..$-ps.length]);
		std.file.write("../doc/" ~ game[0..$-ps.length] ~ "/" ~ ps ~ ".md", data);
	}

	// index
	Tuple!(Protocol, string)[size_t][string] p;
	foreach(game, prts; protocols) {
		p[prts.software][prts.protocol] = tuple(prts.data, game);
	}
	string data;
	foreach(string name ; sort(p.keys).release()) {
		auto sorted = sort(p[name].keys).release();
		bool _released, _from, _to;
		foreach(protocols ; p[name]) {
			_released |= protocols[0].released.length != 0;
			_from |= protocols[0].from.length != 0;
			_to |= protocols[0].to.length != 0;
		}
		data ~= "## " ~ name ~ "\n\n";
		data ~= "Protocol | Packets" ~ (_released ? " | Released" : "") ~ (_from ? " | From" : "") ~ (_to ? " | To" : "") ~ "\n";
		data ~= ":---:|:---:" ~ (_released ? "|:---:" : "") ~ (_from ? "|:---:" : "") ~ (_to ? "|:---:" : "") ~ "\n";
		foreach(size_t protocol ; sort(p[name].keys).release()) {
			immutable ps = to!string(protocol);
			auto cp = p[name][protocol];
			size_t packets = 0;
			foreach(section ; cp[0].sections) packets += section.packets.length;
			data ~= "[" ~ ps ~ "](https://github.com/sel-project/sel-utils/tree/master/doc/" ~ cp[1][0..$-ps.length] ~ "/" ~ ps ~ ".md) | " ~ to!string(packets) ~ (_released ? " | " ~ cp[0].released : "") ~ (_from ? " | " ~ cp[0].from : "") ~ (_to ? " | " ~ cp[0].to : "") ~ "\n";
		}
		data ~= "\n";
	}
	std.file.write("../doc/index.md", data);

}

@property string pretty(string name) {
	string ret;
	foreach(c ; name) {
		if(c >= 'A' && c <= 'Z' || c >= '0' && c <= '9') ret ~= ' ';
		ret ~= c;
	}
	if(!ret.length) return ret;
	else return (toUpper(ret[0..1]) ~ ret[1..$]).replace(" And ", " and ").replace(" Of ", " of ").replace(" In ", " in ");
}

string link(string[] pieces...) {
	return pieces.join(".").replace("_", "-");
}
