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

import std.algorithm : canFind, min, reverse;
import std.ascii : newline;
import std.conv : to;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.path : dirSeparator;
import std.regex : ctRegex, replaceAll, matchFirst;
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

	string io = "package sul.utils;\n\n";
	io ~= "public class Buffer {\n\n";
	io ~= "\tpublic byte[] _buffer;\n\n";
	io ~= "\tpublic int _index;\n\n";
	io ~= "\tpublic void writeBytes(byte[] a) {\n";
	io ~= "\t\tfor(byte b : a) this._buffer[this._index++] = b;\n";
	io ~= "\t}\n\n";
	io ~= "\tpublic byte[] readBytes(int a) {\n";
	io ~= "\t\tbyte[] _ret = new byte[a];\n";
	io ~= "\t\tfor(int i=0; i<a && this._index<this._buffer.length; i++) _ret[i] = this._buffer[this._index++];\n";
	io ~= "\t\treturn _ret;\n";
	io ~= "\t}\n\n";
	foreach(type ; [tuple("byte", 1, "byte"), tuple("short", 2, "short"), tuple("triad", 3, "int"), tuple("int", 4, "int"), tuple("long", 8, "long")]) {
		foreach(e ; ["BigEndian", "LittleEndian"]) {
			// write
			io ~= "\tpublic void write" ~ e ~ capitalize(type[0]) ~ "(" ~ type[2] ~ " a) {\n";
			if(type[1] == 1) io ~= "\t\tthis._buffer[this._index++] = (byte)a;\n";
			else {
				int[] shift;
				foreach(i ; 0..type[1]) shift ~= i * 8;
				if(e == "BigEndian") reverse(shift);
				foreach(i ; shift) {
					io ~= "\t\tthis._buffer[this._index++] = (byte)(a" ~ (i != 0 ? " >>> " ~ to!string(i) : "") ~ ");\n";
				}
			}
			io ~= "\t}\n\n";
			// read
			io ~= "\tpublic " ~ type[2] ~ " read" ~ e ~ capitalize(type[0]) ~ "() {\n";
			io ~= "\t\tif(this._buffer.length < this._index + " ~ to!string(type[1]) ~ ") return (" ~ type[2] ~ ")0;\n";
			if(type[1] == 1) io ~= "\t\treturn (" ~ type[2] ~ ")this._buffer[this._index++];\n";
			else {
				io ~= "\t\t" ~ type[2] ~ " _ret = 0;\n";
				int[] shift;
				foreach(i ; 0..type[1]) shift ~= i * 8;
				if(e == "BigEndian") reverse(shift);
				foreach(i ; shift) {
					io ~= "\t\t_ret |= (" ~ type[2] ~ ")this._buffer[this._index++]" ~ (i != 0 ? " << " ~ to!string(i) : "") ~ ";\n";
				}
				io ~= "\t\treturn _ret;\n";
			}
			io ~= "\t}\n\n";
		}
	}
	foreach(type ; [tuple("float", "int"), tuple("double", "long")]) {
		foreach(e ; ["BigEndian", "LittleEndian"]) {
			io ~= "\tpublic void write" ~ e ~ capitalize(type[0]) ~ "(" ~ type[0] ~ " a) {\n";
			io ~= "\t\tthis.write" ~ e ~ capitalize(type[1]) ~ "(" ~ capitalize(type[0]) ~ "." ~ type[0] ~ "To" ~ capitalize(type[1]) ~ "Bits(a));\n";
			io ~= "\t}\n\n";
			io ~= "\tpublic " ~ type[0] ~ " read" ~ e ~ capitalize(type[0]) ~ "() {\n";
			io ~= "\t\treturn " ~ capitalize(type[0]) ~ "." ~ type[1] ~ "BitsTo" ~ capitalize(type[0]) ~ "(this.read" ~ e ~ capitalize(type[1]) ~ "());\n";
			io ~= "\t}\n\n";
		}
	}
	foreach(varint ; [tuple("short", 3, 15), tuple("int", 5, 31), tuple("long", 10, 63)]) {
		foreach(sign ; ["", "u"]) {
			// write
			io ~= "\tpublic void writeVar" ~ sign ~ varint[0] ~ "(" ~ varint[0] ~ " a) {\n";
			if(sign.length) {
				io ~= "\t\tthis._buffer[this._index++] = (byte)(a & 0x7F);\n";
				io ~= "\t\twhile((a & 0x80) != 0) {\n";
				io ~= "\t\t\ta >>>= 7;\n";
				io ~= "\t\t\tthis._buffer[this._index++] = (byte)(a & 0x7F);\n";
				io ~= "\t\t}\n";
			} else {
				io ~= "\t\tthis.writeVaru" ~ varint[0] ~ "((" ~ varint[0] ~ ")((a >> 1) | (a << " ~ to!string(varint[2]) ~ ")));\n";
			}
			io ~= "\t}\n\n";
			// read
			io ~= "\tpublic " ~ varint[0] ~ " readVar" ~ sign ~ varint[0] ~ "() {\n";
			if(sign.length) {
				io ~= "\t\tint limit = 0;\n";
				io ~= "\t\t" ~ varint[0] ~ " ret = 0;\n";
				io ~= "\t\tdo {\n";
				io ~= "\t\t\tret |= (this._buffer[this._index] & 0x7F) << (limit * 7);\n";
				io ~= "\t\t} while((this._buffer[this._index++] & 0x80) != 0 && ++limit < " ~ to!string(varint[1]) ~ ");\n";
				io ~= "\t\treturn ret;\n";
			} else {
				io ~= "\t\t" ~ varint[0] ~ " ret = this.readVaru" ~ varint[0] ~ "();\n";;
				io ~= "\t\treturn (" ~ varint[0] ~ ")((ret << 1) | (ret >> " ~ to!string(varint[2]) ~ "));\n";
			}
			io ~= "\t}\n\n";
			// length
			io ~= "\tpublic static int var" ~ sign ~ varint[0] ~ "Length(" ~ varint[0] ~ " a) {\n";
			io ~= "\t\tint length = 1;\n";
			io ~= "\t\twhile((a & 0x80) != 0 && length < " ~ to!string(varint[1]) ~ ") {\n";
			io ~= "\t\t\tlength++;\n";
			io ~= "\t\t\ta >>>= 7;\n";
			io ~= "\t\t}\n";
			io ~= "\t\treturn length;\n";
			io ~= "\t}\n\n";
		}
	}
	io ~= "}";
	write("../src/java/sul/utils/Buffer.java", io);

	write("../src/java/sul/utils/Packet.java", q{
package sul.utils;

import sul.utils.Buffer;

public abstract class Packet extends Buffer {

	public final void reset() {
		this._buffer = new byte[0];
		this._index = 0;
	}

	public abstract int length();

	public abstract byte[] encode();

	public abstract void decode(byte[] buffer);

}
	});
	
	// attributes
	foreach(string game, Attributes attrs; attributes) {
		game = toPascalCase(game);
		string data = "package sul.attributes;\n\npublic enum " ~ game ~ " {\n\n";
		foreach(i, attr; attrs.data) {
			data ~= "\t" ~ toUpper(attr.id) ~ "(\"" ~ attr.name ~ "\", " ~ attr.min.to!string ~ "f, " ~ attr.max.to!string ~ "f, " ~ attr.def.to!string ~ "f)" ~ (i == attrs.data.length - 1 ? ";" : ",") ~ "\n\n";
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
			auto e = type[end..$].replaceAll(ctRegex!`\[[0-9]{1,3}\]`, "[]");
			auto a = t in defaultAliases;
			if(a) return convert(*a ~ e);
			auto b = t in prs.data.arrays;
			if(b) return convert((*b).base ~ "[]" ~ e);
			if(e.length && e[0] == '<') return "Tuples." ~ toPascalCase(t) ~ toUpper(e[1..e.indexOf(">")]) ~ e[e.indexOf(">")+1..$];
			else if(defaultTypes.canFind(t)) return t ~ e;
			else if(t == "metadata") return "Metadata" ~ e;
			else return "sul.protocol." ~ game ~ ".types." ~ toPascalCase(t) ~ e;
		}

		@property string convertName(string name) {
			if(name == "default") return "def";
			else return toCamelCase(name);
		}

		immutable id = convert(prs.data.id);
		immutable arrayLength = convert(prs.data.arrayLength);
		
		void fieldsLengthImpl(string name, string type, ref size_t fixed, ref string[] exps, ref string[] seps) {
			//TODO special arrays
			auto array = type.lastIndexOf("[");
			auto tup = type.indexOf("<");
			if(array != -1) {
				if(type.indexOf("]") == array + 1) fieldsLengthImpl(name ~ ".length", prs.data.arrayLength, fixed, exps, seps);
				size_t new_fixed = 0;
				string[] new_exps;
				fieldsLengthImpl(hash(name), type[0..array], new_fixed, new_exps, seps);
				if(new_fixed != 0) {
					exps ~= name ~ ".length" ~ (new_fixed > 1 ? "*" ~ to!string(new_fixed) : "");
				}
				if(new_exps.length) {
					seps ~= "for(" ~ convert(type[0..array]) ~ " " ~ hash(name) ~ ":" ~ name ~ "){ length+=" ~ new_exps.join("+") ~ "; }";
				}
			} else if(tup != -1) {
				immutable vars = type[tup+1..type.indexOf(">")];
				size_t new_fixed = 0;
				string[] new_exps;
				fieldsLengthImpl(hash(name), type[0..tup], new_fixed, new_exps, seps);
				if(new_fixed != 0) {
					fixed += new_fixed * vars.length;
				} else {
					foreach(c ; vars) {
						fieldsLengthImpl(name ~ "." ~ c, type[0..tup], fixed, exps, seps);
					}
				}
			} else {
				auto a = type in prs.data.arrays;
				if(a) {
					fieldsLengthImpl(name ~ ".length", (*a).length, fixed, exps, seps);
					fieldsLengthImpl(name, (*a).base ~ "[0]", fixed, exps, seps);
				} else {
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
							fieldsLengthImpl(name ~ ".getBytes(StandardCharsets.UTF_8).length", prs.data.arrayLength, fixed, exps, seps);
							exps ~= name ~ ".getBytes(StandardCharsets.UTF_8).length";
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
							exps ~= "Buffer." ~ type ~ "Length(" ~ name ~ ")";
							break;
						default:
							exps ~= name ~ ".length()";
							break;
					}
				}
			}
		}
		
		string fieldsLength(Field[] fields, string id="") {
			size_t fixed = 0;
			string[] exps, seps;
			if(id.length) fieldsLengthImpl("ID", id, fixed, exps, seps); //TODO calculate at runtime if it's a varint
			foreach(i, field; fields) {
				fieldsLengthImpl(field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.type, fixed, exps, seps);
			}
			if(seps.length) {
				return "int length=" ~ join(exps ~ to!string(fixed), " + ") ~ "; " ~ seps.join(";") ~ " return length";
			} else {
				if(fixed != 0 || exps.length == 0) exps ~= to!string(fixed);
				return "return " ~ exps.join(" + ");
			}
		}

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
						ret ~= createEncoding(c.length, "(" ~ convert(c.length) ~ ")" ~ name ~ ".length", c.endianness);
					} else {
						ret ~= createEncoding(prs.data.arrayLength, "(" ~ arrayLength ~ ")" ~ name ~ ".length");
					}
					ret ~= " ";
				}
				if(cnt == "byte") return ret ~ "this.writeBytes(" ~ name ~ ");";
				else return ret ~ "for(" ~ cnt ~ " " ~ hash(name) ~ ":" ~ name ~ "){ " ~ createEncoding(nt, hash(name)) ~ " }";
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
			else if(type == "string") return "byte[] " ~ hash(name) ~ "=" ~ name ~ ".getBytes(StandardCharsets.UTF_8); " ~ createEncoding("byte[]", hash(name));
			else if(type == "uuid") return "this.writeBigEndianLong(" ~ name ~ ".getLeastSignificantBits()); this.writeBigEndianLong(" ~ name ~ ".getMostSignificantBits());";
			else if(type == "bytes") return "this.writeBytes(" ~ name ~ ");";
			else if(type == "bool") return "this._buffer[this._index++]=(byte)(" ~ name ~ "?1:0);";
			else if(type == "triad" || defaultTypes.canFind(type)) return "this.write" ~ endiannessOf(type, e) ~ capitalize(type) ~ "(" ~ name ~ ");";
			else return "this.writeBytes(" ~ name ~ ".encode());";
		}

		// decoding expressions
		string createDecoding(string type, string name, string e="") {
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
						ret ~= createDecoding(c.length, "int " ~ hash("l" ~ name), c.endianness);
					} else {
						ret ~= createDecoding(prs.data.arrayLength, "int " ~ hash("l" ~ name));
					}
					ret ~= " ";
				} else {
					ret ~= "final int " ~ hash("l" ~ name) ~ "=" ~ conv[lo+1..lc] ~ "; ";
				}
				ret ~= name ~ "=new " ~ cnt ~ "[" ~ hash("l" ~ name) ~ "]; ";
				if(cnt == "byte") return ret ~ name ~ "=this.readBytes(" ~ hash("l" ~ name) ~ ");";
				else return ret ~ "for(int " ~ hash(name) ~ "=0;" ~ hash(name) ~ "<" ~ name ~ ".length;" ~ hash(name) ~ "++){ " ~ createDecoding(nt, name ~ "[" ~ hash(name) ~ "]") ~ " }";
			}
			auto ts = conv.lastIndexOf("<");
			if(ts > 0) {
				auto te = conv.lastIndexOf(">");
				string nt = conv[0..ts];
				string[] ret;
				foreach(i ; conv[ts+1..te]) {
					ret ~= createDecoding(nt, name ~ "." ~ i);
				}
				return ret.join(" ");
			}
			type = conv;
			if(type.startsWith("var")) return name ~ "=this.read" ~ capitalize(type) ~ "();";
			else if(type == "string") return createDecoding(prs.data.arrayLength, arrayLength ~ " " ~ hash("len" ~ name)) ~ " " ~ name ~ "=new String(this.readBytes(" ~ hash("len" ~ name) ~ "), StandardCharsets.UTF_8);";
			else if(type == "uuid") return createDecoding("long", "long " ~ hash("m" ~ name)) ~ " " ~ createDecoding("long", "long " ~ hash("l" ~ name)) ~ " " ~ name ~ "=new UUID(" ~ hash("m" ~ name) ~ "," ~ hash("l" ~ name) ~ ");";
			else if(type == "bytes") return name ~ "=this.readBytes(this._buffer.length-this._index);";
			else if(type == "bool") return name ~ "=this._index<this._buffer.length&&this._buffer[this._index++]!=0;";
			else if(defaultTypes.canFind(type) || type == "triad") return name ~ "=read" ~ endiannessOf(type, e) ~ capitalize(type) ~ "();";
			else return name ~ "=new " ~ convert(type) ~ "(); " ~ name ~ "._index=this._index; " ~ name ~ ".decode(this._buffer); this._index=" ~ name ~ "._index;";
		}

		// write generic fields
		void writeFields(ref string data, string space, string className, Field[] fields, bool hasId, bool hasVariants=false, bool isVariant=false) { // hasId is true when fields belong to a packet, false when a type
			// constants
			foreach(field ; fields) {
				if(field.constants.length) {
					data ~= space ~ "// " ~ field.name.replace("_", " ") ~ "\n";
					foreach(constant ; field.constants) {
						data ~= space ~ "public final static " ~ convert(field.type) ~ " " ~ toUpper(constant.name) ~ " = " ~ (field.type == "string" ? JSONValue(constant.value).toString() : constant.value) ~ ";\n";
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
				immutable c = convert(field.type);
				immutable oa = field.type.indexOf("[");
				immutable ca = field.type.indexOf("]");
				data ~= space ~ "public " ~ c ~ " " ~ (field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name));
				if(oa != -1 && ca != oa + 1) data ~= " = new " ~ c[0..$-2] ~ "[" ~ field.type[oa+1..ca] ~ "]";
				data ~= ";\n";
				if(i == fields.length - 1) data ~= "\n";
			}
			// constructors
			if(fields.length) {
				data ~= space ~ "public " ~ className ~ "() {}\n\n";
				data ~= space ~ "public " ~ className ~ "(";
				foreach(i, field; fields) {
					data ~= convert(field.type) ~ " " ~ (field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name)) ~ (i != fields.length - 1 ? ", " : "");
				}
				data ~= ") {\n";
				foreach(i, field; fields) {
					immutable n = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
					data ~= space ~ "\tthis." ~ n ~ " = "~ n ~ ";\n";
				}
				data ~= space ~ "}\n\n";
			}
			// length
			data ~= space ~ "@Override\n";
			data ~= space ~ "public int length() {\n";
			data ~= space ~ "\t" ~ fieldsLength(fields, hasId ? prs.data.id : "") ~ ";\n";
			data ~= space ~ "}\n\n";
			// encoding
			data ~= space ~ "@Override\n";
			data ~= space ~ "public byte[] encode() {\n";
			if(hasVariants) {
				data ~= space ~ "\treturn this.encodeImpl();\n";
				data ~= space ~ "}\n\n";
				data ~= space ~ "private byte[] encodeImpl() {\n";
				data ~= space ~ "\tthis._buffer = new byte[this.length()];\n";
			} else if(isVariant) {
				data ~= space ~ "\tbyte[] _encode = encodeImpl();\n";
				data ~= space ~ "\tthis._buffer = new byte[_encode.length + this.length()];\n";
				data ~= space ~ "\tthis.writeBytes(_encode);\n";
			} else {
				data ~= space ~ "\tthis._buffer = new byte[this.length()];\n";
			}
			if(hasId) {
				data ~= space ~ "\t" ~ createEncoding(prs.data.id, "ID") ~ "\n";
			}
			foreach(i, field; fields) {
				bool c = field.condition.length != 0;
				data ~= space ~ "\t" ~ (c ? "if(" ~ toCamelCase(field.condition) ~ "){ " : "") ~ createEncoding(field.type, field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.endianness) ~ (c ? " }" : "") ~ "\n";
			}
			data ~= space ~ "\treturn this._buffer;\n";
			data ~= space ~ "}\n\n";
			// decoding
			data ~= space ~ "@Override\n";
			data ~= space ~ "public void decode(byte[] buffer) {\n";
			data ~= space ~ "\tthis._buffer = buffer;\n";
			if(hasId) {
				data ~= space ~ "\t" ~ createDecoding(prs.data.id, id ~ "").split("=")[1..$].join("=") ~ "\n";
			}
			foreach(i, field; fields) {
				bool c = field.condition.length != 0;
				data ~= space ~ "\t" ~ (c ? "if(" ~ toCamelCase(field.condition) ~ "){ " : "") ~ createDecoding(field.type, field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.endianness) ~ (c ? " }" : "") ~ "\n";
			}
			data ~= space ~ "}\n\n";
			if(isVariant) {
				data ~= space ~ "public void decode() {\n";
				data ~= space ~ "\tthis.decode(remainingBuffer());\n";
				data ~= space ~ "}\n\n";
			}
			if(hasVariants) {
				data ~= space ~ "private byte[] remainingBuffer() {\n";
				data ~= space ~ "\treturn java.util.Arrays.copyOfRange(this._buffer, this._index, this._buffer.length);\n";
				data ~= space ~ "}\n\n";
			}
		}

		@property string imports(Field[] fields) {
			bool str, uuid;
			foreach(field ; fields) {
				auto conv = convert(field.type);
				immutable t = conv.split("[")[0].split("<")[0];
				if(t == "String") str = true;
				else if(t == "UUID") uuid = true;
				else if(field.type.indexOf("<") != -1) {
					immutable a = convert(field.type.split("<")[0]) ~ "|" ~ field.type.split("<")[1].split(">")[0];
					if(!tuples.canFind(a)) tuples ~= a;
				}
			}
			string ret = "";
			if(str) ret ~= "import java.nio.charset.StandardCharsets;\n";
			if(uuid) ret ~= "import java.util.UUID;\n";
			if(str || uuid) ret ~= "\n";
			return ret;
		}

		foreach(type ; prs.data.types) {
			string data = "package sul.protocol." ~ game ~ ".types;\n\n" ~ imports(type.fields) ~ "import sul.utils.*;\n\n";
			if(type.description.length) data ~= javadoc("", type.description);
			data ~= "public class " ~ toPascalCase(type.name) ~ " extends Packet {\n\n";
			writeFields(data, "\t", toPascalCase(type.name), type.fields, false);
			data ~= "\n}";
			write("../src/java/sul/protocol/" ~ game ~ "/types/" ~ toPascalCase(type.name) ~ ".java", data, "protocol/" ~ game);
		}
		foreach(section ; prs.data.sections) {
			immutable sectionName = section.name.replace("_", "");
			mkdirRecurse("../src/java/sul/protocol/" ~ game ~ "/" ~ sectionName);
			foreach(packet ; section.packets) {
				string data = "package sul.protocol." ~ game ~ "." ~ sectionName ~ ";\n\n" ~ imports(packet.fields ~ (){ Field[] fields;foreach(v;packet.variants){fields~=v.fields;}return fields;}()) ~ "import sul.utils.*;\n\n";
				if(packet.description.length) {
					data ~= javadoc("", packet.description);
				}
				data ~= "public class " ~ toPascalCase(packet.name) ~ " extends Packet {\n\n";
				data ~= "\tpublic final static " ~ id ~ " ID = (" ~ id ~ ")" ~ to!string(packet.id) ~ ";\n\n";
				data ~= "\tpublic final static boolean CLIENTBOUND = " ~ to!string(packet.clientbound) ~ ";\n";
				data ~= "\tpublic final static boolean SERVERBOUND = " ~ to!string(packet.serverbound) ~ ";\n\n";
				writeFields(data, "\t", toPascalCase(packet.name), packet.fields, true, packet.variants.length != 0, false);
				data ~= "\tpublic static " ~ toPascalCase(packet.name) ~ " fromBuffer(byte[] buffer) {\n";
				data ~= "\t\t" ~ toPascalCase(packet.name) ~ " ret = new " ~ toPascalCase(packet.name) ~ "();\n";
				data ~= "\t\tret.decode(buffer);\n";
				data ~= "\t\treturn ret;\n";
				data ~= "\t}\n\n";
				if(packet.variantField.length) {
					string vt = "";
					foreach(field ; packet.fields) {
						if(field.name == packet.variantField) {
							vt = convert(field.type);
							break;
						}
					}
					foreach(variant ; packet.variants) {
						if(variant.description.length) data ~= javadoc("\t", variant.description);
						data ~= "\tpublic class " ~ toPascalCase(variant.name) ~ " extends Packet {\n\n";
						data ~= "\t\tpublic final static " ~ vt ~ " " ~ toUpper(packet.variantField) ~ " = (" ~ vt ~ ")" ~ variant.value ~ ";\n\n";
						writeFields(data, "\t\t", toPascalCase(variant.name), variant.fields, false, false, true);
						data ~= "\t}\n\n";
					}
				}
				data ~= "}";
				write("../src/java/sul/protocol/" ~ game ~ "/" ~ sectionName ~ "/" ~ toPascalCase(packet.name) ~ ".java", data, "protocol/" ~ game);
			}
		}
	}

	// tuples
	string tp = "package sul.utils;\n\npublic final class Tuples {\n\n\tprivate Tuples() {}\n\n";
	foreach(t ; tuples) {
		auto spl = t.split("|");
		immutable name = capitalize(spl[0]) ~ spl[1].toUpper();
		tp ~= "\tpublic static class " ~ name ~ " {\n\n";
		tp ~= "\t\tpublic " ~ spl[0] ~ " " ~ spl[1].split("").join(", ") ~ ";\n\n";
		tp ~= "\t\tpublic " ~ name ~ "() {}\n\n";
		tp ~= "\t\tpublic " ~ name ~ "(" ~ spl[0] ~ " " ~ spl[1].split("").join(", " ~ spl[0] ~ " ") ~ ") {\n";
		foreach(c ; spl[1].split("")) {
			tp ~= "\t\t\tthis." ~ c ~ " = " ~ c ~ ";\n";
		}
		tp ~= "\t\t}\n\n";
		tp ~= "\t}\n\n";
	}
	write("../src/java/sul/utils/Tuples.java", tp ~ "}");

}

string javadoc(string space, string description) {
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
	foreach(s ; description.split("\n")) {
		string h = "######";
		while((h = h[1..$]).length) {
			if(s.startsWith(h)) {
				ret ~= space ~ " * <h" ~ to!string(h.length) ~ ">" ~ s[h.length..$].strip ~ "</h" ~ to!string(h.length) ~ ">\n";
				break;
			}
		}
		if(!h.length) ret ~= javadocImpl(space, s.split(" "));
	}
	return space ~ "/**\n" ~ ret ~ space ~ " */\n";
}

string javadocImpl(string space, string[] words) {
	size_t length;
	string[] ret;
	while(length < 80 && words.length) {
		ret ~= words[0].replaceAll(ctRegex!"```[a-z]{1,16}", "<code>").replaceAll(ctRegex!"```", "</code>");
		length += words[0].length + 1;
		words = words[1..$];
	}
	return space ~ " * " ~ ret.join(" ") ~ "\n" ~ (words.length ? javadocImpl(space, words) : "");
}
