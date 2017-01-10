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
module java;

import std.algorithm : canFind, min;
import std.ascii : newline;
import std.conv : to;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.path : dirSeparator;
import std.string;
import std.typecons : tuple;

import all;

void java(Attributes[string] attributes, Protocols[string] protocols, Creative[string] creative) {

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

	string buffer = "package sul.utils;\n\n";
	buffer ~= "class Buffer {\n\n";
	buffer ~= "\tprotected byte[] buffer;\n\tprotected int index;\n\n";
	foreach(type ; [tuple("byte", 1, "byte"), tuple("short", 2, "short"), tuple("triad", 3, "int"), tuple("int", 4, "int"), tuple("long", 8, "long")]) {
		// type = (type, bytes, return type)
		buffer ~= "\tprotected final " ~ type[2] ~ " write" ~ capitalize(type[0]) ~ "B(" ~ type[2] ~ " a) {\n";
		foreach_reverse(i ; 0..type[1]) {
			buffer ~= "\t\tthis.buffer[this.index++] = (byte)(a >>> " ~ to!string(i * 8) ~ ");\n";
		}
		buffer ~= "\t}\n\n";
		buffer ~= "\tprotected final " ~ type[2] ~ " read" ~ capitalize(type[0]) ~ "B() {\n";
		buffer ~= "\t\tif(this.buffer.length < this.index + " ~ to!string(type[1]) ~ ") return (" ~ type[2] ~ ")0;\n";

		buffer ~= "\t}\n\n";
		buffer ~= "\tprotected final " ~ type[2] ~ " write" ~ capitalize(type[0]) ~ "L(" ~ type[2] ~ " a) {\n";
		foreach(i ; 0..type[1]) {
			buffer ~= "\t\tthis.buffer[this.index++] = (byte)(a >>> " ~ to!string(i * 8) ~ ");\n";
		}
		buffer ~= "\t}\n\n";
	}
	buffer ~= "}";
	write("../src/java/sul/utils/Buffer.java", buffer);

	write("../src/java/sul/utils/Packet.java", q{
package sul.utils;

import sul.utils.Buffer;

abstract class Packet extends Buffer {

	abstract int length();

	abstract byte[] encode();

	abstract void decode(byte[] buffer);

}
	});
	
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

	// protocols
	string[] tuples;
	foreach(string game, Protocols prs; protocols) {

		mkdirRecurse("../src/java/sul/protocol/" ~ game ~ "/types");

		@property string convert(string type) {
			auto end = min(cast(size_t)type.lastIndexOf("["), cast(size_t)type.lastIndexOf("<"), type.length);
			auto t = type[0..end];
			auto e = type[end..$];
			auto a = t in defaultAliases;
			if(a) return convert(*a ~ e);
			if(e.length && e[0] == '<') {
				if(!tuples.canFind(t ~ e)) tuples ~= (t ~ e);
				return "Tuples." ~ toPascalCase(t) ~ toUpper(e[1..$-1]);
			} else if(defaultTypes.canFind(t)) return t ~ e;
			else return toPascalCase(t) ~ e;
		}

		immutable id = convert(prs.data.id);
		immutable arrayLength = convert(prs.data.arrayLength);
		
		void fieldsLengthImpl(string name, string type, ref size_t fixed, ref string[] exps) {
			//TODO special arrays
			auto array = type.lastIndexOf("[");
			if(array != -1) {
				fieldsLengthImpl(name ~ ".length", prs.data.arrayLength, fixed, exps);

			}
			switch(type) {
				case "bool":
				case "byte":
				case "ubyte":
					fixed += 1;
					break;
				case "short":
				case "ushort":
					fixed += 2;
					break;
				case "triad":
					fixed += 3;
					break;
				case "int":
				case "uint":
				case "float":
					fixed += 4;
					break;
				case "long":
				case "ulong":
				case "double":
					fixed += 8;
					break;
				case "uuid":
					fixed += 16;
					break;
				case "string":
					fieldsLengthImpl(name ~ ".getBytes(StandardCharset.UTF_8).length", prs.data.arrayLength, fixed, exps);
					exps ~= name ~ ".getBytes(StandardCharset.UTF_8).length";
					break;
				case "bytes":
					exps ~= name ~ ".length";
					break;
				case "varshort":
				case "varushort":
				case "varint":
				case "varuint":
				case "varlong":
				case "varulong":
					exps ~= "Var." ~ toPascalCase(type[3..$]) ~ ".length(" ~ name ~ ")";
					break;
				default:
					exps ~= name ~ ".length()";
					break;
			}
		}
		
		string fieldsLength(Field[] fields) {
			size_t fixed = 0;
			string[] exps;
			foreach(field ; fields) {
				fieldsLengthImpl(toCamelCase(field.name), field.type, fixed, exps);
			}
			if(fixed != 0 || exps.length == 0) exps ~= to!string(fixed);
			return exps.join(" + ");
		}

		// returns the endianness for a type(B for big endian and L for little endian)
		string endiannessOf(string type, string over="") {
			if(over.length == 0) {
				auto e = type in prs.data.endianness;
				if(e) return over = *e;
				else over = prs.data.endianness["*"];
			}
			return over == "big_endian" ? "B" : "L";
		}

		// encoding expression
		string createEncoding(string type, string name, string e="") {
			if(type[0] == 'u' && defaultTypes.canFind(type[1..$])) type = type[1..$];
			auto conv = type in prs.data.arrays ? prs.data.arrays[type].base ~ "[]" : type;
			auto lo = conv.lastIndexOf("[");
			if(lo > 0) {
				string ret = "";
				auto lc = conv.lastIndexOf("]");
				string nt = conv[0..lo];
				if(lo == lc - 1) {
					auto ca = type in prs.data.arrays;
					if(ca) {
						auto c = *ca;
						ret ~= createEncoding(c.length, "(" ~ convert(c.length) ~ ")" ~ name ~ ".length", c.endianness);
					} else {
						ret ~= createEncoding(prs.data.arrayLength, "(" ~ arrayLength ~ ")" ~ name ~ ".length");
					}
					ret ~= " ";
				}
				if(nt == "byte") return ret ~= "this.writeBytes(" ~ name ~ ");";
				else return ret ~ "for(" ~ nt ~ " " ~ hash(name) ~ ":" ~ name ~ "){ " ~ createEncoding(type[0..lo], hash(name)) ~ " }";
			}
			auto ts = conv.lastIndexOf("<");
			if(ts > 0) {
				auto te = conv.lastIndexOf(">");
				string nt = conv[0..ts];
				string ret;
				foreach(i ; conv[ts+1..te]) {
					ret ~= createEncoding(nt, name ~ "." ~ i);
				}
				return ret;
			}
			type = conv;
			if(type.startsWith("var")) return "this.write" ~ capitalize(type) ~ "(" ~ name ~ ");";
			else if(type == "string") return "byte[] " ~ hash(name) ~ "=" ~ name ~ ".getBytes(\"UTF-8\"); " ~ createEncoding("byte[]", hash(name));
			else if(type == "uuid") return "this.writeLongB(" ~ name ~ ".getLeastSignificantBits()); this.writeLongB(" ~ name ~ ".getMostSignificantBits());";
			else if(type == "bytes") return "this.writeBytes(" ~ name ~ ");";
			else if(type == "bool" || type == "triad" || defaultTypes.canFind(type)) return "this.write" ~ capitalize(type) ~ endiannessOf(type, e) ~ "(" ~ name ~ ");";
			else return "this.writeBytes(" ~ name ~ ".encode());";
		}

		// write generic fields
		void writeFields(ref string data, string space, Field[] fields, bool hasId) { // hasId is true when fields belong to a packet, false when a type
			// constants
			foreach(field ; fields) {
				if(field.constants.length) {
					data ~= space ~ "// " ~ field.name.replace("_", " ") ~ "\n";
					foreach(constant ; field.constants) {
						data ~= space ~ "public static immutable " ~ convert(field.type) ~ " " ~ toUpper(constant.name) ~ " = " ~ (field.type == "string" ? JSONValue(constant.value).toString() : constant.value) ~ ";\n";
					}
					data ~= "\n";
				}
			}
			// fields
			foreach(i, field; fields) {
				if(field.description.length) {
					if(i != 0) data ~= "\n";
					data ~= javadoc(space, field.description);
				}
				data ~= space ~ "public " ~ convert(field.type) ~ " " ~ (field.name == "?" ? "unknown" ~ to!string(i) : toCamelCase(field.name)) ~ ";\n";
				if(i == fields.length - 1) data ~= "\n";
			}
			//TODO length
			data ~= space ~ "@Override\n";
			data ~= space ~ "public int length() {\n";

			data ~= space ~ "}\n\n";
			// encoding
			data ~= space ~ "@Override\n";
			data ~= space ~ "public byte[] encode() {\n";
			data ~= space ~ "\tthis.buffer = new byte[this.length()];\n";
			data ~= space ~ "\tthis.index = 0;\n";
			if(hasId) {
				data ~= space ~ "\t" ~ createEncoding(prs.data.id, "ID") ~ "\n";
			}
			foreach(i, field; fields) {
				bool c = field.condition.length != 0;
				data ~= space ~ "\t" ~ (c ? "if(" ~ field.condition ~ "){ " : "") ~ createEncoding(field.type, field.name == "?" ? "unknown" ~ to!string(i) : toCamelCase(field.name), field.endianness) ~ (c ? " }" : "") ~ "\n";
			}
			data ~= space ~ "\treturn this.buffer;\n" ~ space ~ "}\n\n";
			//TODO decoding
			data ~= space ~ "@Override\n";
			data ~= space ~ "public void decode(byte[] buffer) {\n";
			data ~= space ~ "\tthis.buffer = buffer;\n";
			data ~= space ~ "\tthis.index = 0;\n";
			if(hasId) {
				//data ~= space ~ "\t" ~ id ~ " _id; " ~ createDecoding(prs.data.id, "_id") ~ "\n";
			}
			/*foreach(i, field; fields) {
				bool c = field.condition.length != 0;
				data ~= space ~ "\t" ~ (c ? "if(" ~ field.condition ~ "){ " : "") ~ createDecoding(field.type, field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.endianness) ~ (c ? " }" : "") ~ "\n";
			}*/
			data ~= space ~ "}\n\n";
		}

		foreach(type ; prs.data.types) {
			string data = "package sul.protocol." ~ game ~ ".types;\n\nimport java.util.UUID;\n\nimport sul.utils.*;\n\n";
			if(type.description.length) data ~= javadoc("", type.description);
			data ~= "final class " ~ toPascalCase(type.name) ~ " {\n\n";
			foreach(field ; type.fields) {
				if(field.constants.length) {
					immutable fieldType = convert(field.type);
					data ~= "\t// " ~ field.name.replace("_", " ") ~ "\n";
					foreach(constant ; field.constants) {
						data ~= "\tpublic final static " ~ fieldType ~ " " ~ toUpper(constant.name) ~ " = (" ~ fieldType ~ ")" ~ constant.value ~ ";\n";
					}
					data ~= "\n";
				}
			}
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
				string data = "package sul.protocol." ~ game ~ "." ~ sectionName ~ ";\n\nimport java.util.UUID;\n\nimport sul.protocol." ~ game ~ ".types.*;\nimport sul.utils.*;\n\n";
				if(packet.description.length) {
					data ~= javadoc("", packet.description);
				}
				data ~= "class " ~ toPascalCase(packet.name) ~ " extends Packet {\n\n";
				data ~= "\tpublic final static " ~ id ~ " ID = (" ~ id ~ ")" ~ to!string(packet.id) ~ ";\n\n";
				data ~= "\tpublic final static boolean CLIENTBOUND = " ~ to!string(packet.clientbound) ~ ";\n";
				data ~= "\tpublic final static boolean SERVERBOUND = " ~ to!string(packet.serverbound) ~ ";\n\n";
				writeFields(data, "\t", packet.fields, true);
				if(packet.variants.length) {
					foreach(j, variant; packet.variants) {
						if(variant.description.length) data ~= javadoc("\t", variant.description);
						data ~= "\tpublic static class " ~ toPascalCase(variant.name) ~ " extends " ~ toPascalCase(packet.name) ~ " {\n\n";

						data ~= "\t}\n\n";
					}
				}
				data ~= "}";
				write("../src/java/sul/protocol/" ~ game ~ "/" ~ sectionName ~ "/" ~ toPascalCase(packet.name) ~ ".java", data, "protocol/" ~ game);
			}
		}
	}

}

string javadoc(string space, string description) {
	import std.regex : matchFirst, ctRegex;
	bool search = true;
	while(search) {
		auto m = matchFirst(description, ctRegex!`\[[a-zA-Z0-9 \.]{2,30}\]\([a-zA-Z0-9\#\.:\/-]{2,64}\)`);
		if(m) {
			description = m.pre ~ m.hit[1..m.hit.indexOf("]")] ~ m.post;
		} else {
			search = false;
		}
	}
	string ret;
	foreach(s ; description.split("\n")) ret ~= javadocImpl(space, s.split(" "));
	return space ~ "/**\n" ~ ret ~ space ~ " */\n";
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
