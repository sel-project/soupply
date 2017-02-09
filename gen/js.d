/*
 * Copyright (c) 2016-2017 SEL
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 * 
 */
module js;

import std.algorithm : canFind, min;
import std.ascii : newline;
import std.conv : to;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.path : dirSeparator;
import std.regex : ctRegex, replaceAll, matchFirst;
import std.string;

import all;
import java : javadoc;

void js(Attributes[string] attributes, Protocols[string] protocols, Creative[string] creative) {
	
	mkdirRecurse("../src/js/sul");
	
	// attributes
	foreach(string game, Attributes attrs; attributes) {
		string data = "const Attributes = {\n\n";
		foreach(attr ; attrs.data) {
			data ~= "\t" ~ toUpper(attr.id) ~ ": {name: " ~ JSONValue(attr.name).toString() ~ ", min: " ~ attr.min.to!string ~ ", max: " ~ attr.max.to!string ~ ", default: " ~ attr.def.to!string ~ "},\n\n";
		}
		mkdirRecurse("../src/js/sul/attributes");
		write("../src/js/sul/attributes/" ~ game ~ ".js", data ~ "}", "attributes/" ~ game);
	}

	// creative
	foreach(string game, Creative c; creative) {
		string data = "const Creative = [\n\n";
		foreach(i, item; c.data) {
			data ~= "\t{name: " ~ JSONValue(item.name).toString() ~ ", id: " ~ item.id.to!string;
			if(item.meta != 0) data ~= ", meta: " ~ item.meta.to!string;
			if(item.enchantments.length) {
				string[] e;
				foreach(ench ; item.enchantments) {
					e ~= "{id: " ~ ench.id.to!string ~ ", level: " ~ ench.level.to!string ~ "}";
				}
				data ~= ", enchantments: [" ~ e.join(", ") ~ "]";
			}
			data ~= "}" ~ (i != c.data.length - 1 ? "," : "") ~ "\n";
		}
		mkdirRecurse("../src/js/sul/creative");
		write("../src/js/sul/creative/" ~ game ~ ".js", data ~ "\n]", "creative/" ~ game);
	}

	enum defaultTypes = ["byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double"];

	// protocol
	foreach(string game, Protocols prs; protocols) {
		mkdirRecurse("../src/js/sul/protocol/" ~ game);

		@property string convert(string type) {
			auto end = min(cast(size_t)type.lastIndexOf("["), cast(size_t)type.lastIndexOf("<"), type.length);
			auto t = type[0..end];
			auto e = type[end..$].replaceAll(ctRegex!`\[[0-9]{1,3}\]`, "[]");
			/*auto a = t in defaultAliases;
			if(a) return convert(*a ~ e);*/
			auto b = t in prs.data.arrays;
			if(b) return convert((*b).base ~ "[]" ~ e);
			if(e.length && e[0] == '<') return ""; //TODO
			else if(defaultTypes.canFind(t)) return t ~ e;
			else if(t == "metadata") return "Metadata";
			else return "Types." ~ toPascalCase(t) ~ e;
		}
		
		immutable id = convert(prs.data.id);
		immutable arrayLength = convert(prs.data.arrayLength);

		// returns the endianness for a type
		string endiannessOf(string type, string over="") {
			if(!over.length) {
				auto e = type in prs.data.endianness;
				if(e) over = *e;
				else over = prs.data.endianness["*"];
			}
			return toPascalCase(over);
		}

		// encoding expression
		string createEncoding(string type, string name, string e="") {
			if(type[0] == 'u' && defaultTypes.canFind(type[1..$])) type = type[1..$];
			auto conv = type in prs.data.arrays ? prs.data.arrays[type].base ~ "[]" : type;
			auto lo = conv.lastIndexOf("[");
			if(lo > 0) {
				string ret = "";
				auto lc = conv.lastIndexOf("]");
				immutable nt = conv[0..lo];
				immutable cnt = convert(nt);
				if(lo == lc - 1) {
					auto ca = type in prs.data.arrays;
					if(ca) {
						auto c = *ca;
						ret ~= createEncoding(c.length, name ~ ".length", c.endianness);
					} else {
						ret ~= createEncoding(prs.data.arrayLength, name ~ ".length");
					}
					ret ~= " ";
				}
				if(cnt == "byte") return ret ~ "this.writeBytes(" ~ name ~ ");";
				else return ret ~ "for(" ~ hash(name) ~ " in " ~ name ~ "){ " ~ createEncoding(nt, name ~ "[" ~ hash(name) ~ "]") ~ " }";
			}
			auto ts = conv.lastIndexOf("<");
			if(ts > 0) {
				auto te = conv.lastIndexOf(">");
				string nt = conv[0..ts];
				string[] ret;
				foreach(i ; conv[ts+1..te]) {
					ret ~= createEncoding(nt, name ~ "." ~ i);
				}
				return ret.join(" ");
			}
			type = conv;
			if(type.startsWith("var")) return "this.write" ~ capitalize(type) ~ "(" ~ name ~ ");";
			else if(type == "string") return "this.writeString(" ~ name ~ ");";
			else if(type == "uuid") return "this.writeBigEndianLong(" ~ name ~ ".getLeastSignificantBits()); this.writeBigEndianLong(" ~ name ~ ".getMostSignificantBits());";
			else if(type == "bytes") return "this.writeBytes(" ~ name ~ ");";
			else if(type == "bool") return "this.writeBool(" ~ name ~ ");";
			else if(type == "byte" || type == "ubyte") return "this.writeByte(" ~ name ~ ");";
			else if(type == "triad" || defaultTypes.canFind(type)) return "this.write" ~ endiannessOf(type, e) ~ capitalize(type) ~ "(" ~ name ~ ");";
			else return "this.writeBytes(" ~ name ~ ".encode());";
		}

		void writeFields(ref string data, string space, string className, Field[] fields, string cont="") {
			// constants
			foreach(field ; fields) {
				if(field.constants.length) {
					data ~= space ~ "// " ~ field.name.replace("_", " ") ~ "\n";
					foreach(con ; field.constants) {
						data ~= space ~ "static get " ~ con.name.toUpper() ~ "(){ return " ~ con.value ~ "; }\n";
					}
					data ~= "\n";
				}
			}
			string[] f;
			bool desc = false;
			foreach(i, field; fields) {
				immutable name = field.name == "?" ? "unknown" ~ to!string(i) : toCamelCase(field.name);
				f ~= name ~ "=" ~ defaultValue(field.type);
				desc |= field.description.length != 0;
			}
			if(desc) {
				data ~= space ~ "/**\n";
				foreach(field ; fields) {
					if(field.description.length) {
						data ~= space ~ " * @param " ~ toCamelCase(field.name) ~ "\n";
						foreach(d ; paramDoc(field.description)) {
							data ~= space ~ " *        " ~ d ~ "\n";
						}
					}
				}
				data ~= space ~ " */\n";
			}
			data ~= space ~ "constructor(" ~ f.join(", ") ~ ") {\n";
			foreach(i, field; fields) {
				immutable name = field.name == "?" ? "unknown" ~ to!string(i) : toCamelCase(field.name);
				data ~= space ~ "\tthis." ~ name ~ " = " ~ name ~ ";\n";
			}
			data ~= space ~ "}\n\n";
			// encode
			{
				data ~= space ~ "/** @return {Uint8Array} */\n";
				data ~= space ~ "encode() {\n";
				if(cont.length) data ~= space ~ "\t" ~ createEncoding(prs.data.id, "this.ID") ~ "\n";
				foreach(i, field; fields) {
					immutable name = field.name == "?" ? "unknown" ~ to!string(i) : toCamelCase(field.name);
					data ~= space ~ "\t" ~ createEncoding(field.type, name, field.endianness) ~ "\n";
				}
				data ~= space ~ "}\n\n";
			}
			// decode
			{
				data ~= space ~ "/** @param {Uint8Array} buffer */\n";
				data ~= space ~ "decode(buffer) {\n";
				data ~= space ~ "\tif(!(buffer instanceof Uint8Array)) throw new TypeError('buffer is not a Uint8Array');\n";
				//TODO
				data ~= space ~ "\treturn this;\n";
				data ~= space ~ "}\n\n";
				// from buffer
				if(cont.length) {
					data ~= space ~ "static fromBuffer(buffer) {\n";
					data ~= space ~ "\treturn new " ~ cont ~ "." ~ className ~ "().decode(buffer);\n";
					data ~= space ~ "}\n\n";
				}
			}
			{
				data ~= space ~ "/** @return {string} */\n";
				data ~= space ~ "toString() {\n";
				string[] s;
				foreach(i, field; fields) {
					immutable name = field.name == "?" ? "unknown" ~ to!string(i) : toCamelCase(field.name);
					s ~= name ~ ": \" + this." ~ name;
				}
				data ~= space ~ "\treturn \"" ~ className ~ "(" ~ (fields.length ? s.join(" + \", ") ~ " + \"" : "") ~ ")\";\n";
				data ~= space ~ "}\n\n";
			}
		}

		// types
		{
			string data = "/** @module sul/protocol/" ~ game ~ "/types */\n\n";
			data ~= "const Types = {\n\n";
			foreach(i, type; prs.data.types) {
				if(type.description.length) {

				}
				data ~= "\t" ~ toPascalCase(type.name) ~ ": class {\n\n";
				writeFields(data, "\t\t", toPascalCase(type.name), type.fields);
				data ~= "\t}" ~ (i != prs.data.types.length - 1 ? "," : "") ~ "\n\n";
			}
			data ~= "}\n\n";
			data ~= "export { Types }";
			write("../src/js/sul/protocol/" ~ game ~ "/types.js", data, "protocol/" ~ game);
		}
		// sections
		foreach(section ; prs.data.sections) {
			string data = "/** @module sul/protocol/" ~ game ~ "/" ~ section.name ~ " */\n\n";
			data ~= "//import Types from 'types';\n\n";
			if(section.description.length) {
				data ~= javadoc("", section.description);
			}
			data ~= "const " ~ toPascalCase(section.name) ~ " = {\n\n";
			foreach(i, packet; section.packets) {
				if(packet.description.length) {
					data ~= javadoc("\t", packet.description);
				}
				data ~= "\t" ~ toPascalCase(packet.name) ~ ": class {\n\n";
				data ~= "\t\tstatic get ID(){ return " ~ packet.id.to!string ~ "; }\n\n";
				data ~= "\t\tstatic get CLIENTBOUND(){ return " ~ packet.clientbound.to!string ~ "; }\n";
				data ~= "\t\tstatic get SERVERBOUND(){ return " ~ packet.serverbound.to!string ~ "; }\n\n";
				writeFields(data, "\t\t", toPascalCase(packet.name), packet.fields, toPascalCase(section.name));
				data ~= "\t}" ~ (i != section.packets.length ? "," : "") ~ "\n\n";
			}
			data ~= "}\n\n";
			data ~= "//export { " ~ toPascalCase(section.name) ~ " };";
			write("../src/js/sul/protocol/" ~ game ~ "/" ~ section.name ~ ".js", data, "protocol/" ~ game);
		}
	}
	
}

string defaultValue(string type) {
	if(["byte", "ubyte", "short", "ushort", "triad", "int", "uint", "long", "ulong"].canFind(type) || type.startsWith("var")) return "0";
	else if(type == "float" || type == "double") return ".0";
	else if(type == "bool") return "false";
	else if(type == "string") return `""`;
	else if(type == "uuid") return "new Uint8Array(16)";
	else if(type.endsWith("]")) return "[]";
	else if(type.indexOf("<") != -1) return "{" ~ type.matchFirst(ctRegex!`<[a-z]+>`).hit[1..$-1].split("").join(":0,") ~ ":0}";
	else return "null";
}

string[] paramDoc(string desc) {
	size_t length = 0;
	string[] next;
	string[] data;
	void add() {
		data ~= next.join(" ");
		next.length = 0;
		length = 0;
	}
	foreach(s ; desc.replaceAll(ctRegex!`\[([a-zA-Z0-9\.]+)\]\([a-zA-Z0-9_\-\#\.\:]+\)`, "$1").replaceAll(ctRegex!`[\r\n\t]+`, "").split(" ")) {
		s = s.strip;
		length += s.length;
		next ~= s;
		if(length >= 80) add();
	}
	if(next.length) add();
	return data;
}
