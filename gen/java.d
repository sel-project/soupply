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

import std.algorithm : canFind, min, max, reverse, count;
import std.array : replicate;
import std.ascii : newline;
import std.conv : to;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.math : isNaN;
import std.path : dirSeparator;
import std.regex : ctRegex, replaceAll, matchFirst;
import std.string;
import std.typecons : tuple;
import std.typetuple : TypeTuple;

import all;

void java(Attributes[string] attributes, Protocols[string] protocols, Metadatas[string] metadatas, Creative[string] creative, Block[] blocks, Item[] items, Entity[] entities, Enchantment[] enchantments, Effect[] effects) {
	
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

	// about
	write("../src/java/sul/utils/About.java", q{
package sul.utils;

public final class About {

	private About() {}

	public static final int VERSION = _;

}
	}.replace("_", to!string(sulVersion)));
	
	string io = "package sul.utils;\n\nimport java.util.Arrays;\n\n";
	io ~= "public class Buffer {\n\n";
	io ~= "\tpublic byte[] _buffer;\n\n";
	io ~= "\tpublic int _index;\n\n";
	io ~= "\tpublic byte[] getBuffer() {\n";
	io ~= "\t\treturn Arrays.copyOfRange(this._buffer, 0, this._index);\n";
	io ~= "\t}\n\n";
	io ~= "\tpublic void writeBytes(byte[] a) {\n";
	io ~= "\t\tfor(byte b : a) this._buffer[this._index++] = b;\n";
	io ~= "\t}\n\n";
	io ~= "\tpublic byte[] readBytes(int a) {\n";
	io ~= "\t\tbyte[] _ret = new byte[a];\n";
	io ~= "\t\tfor(int i=0; i<a && this._index<this._buffer.length; i++) _ret[i] = this._buffer[this._index++];\n";
	io ~= "\t\treturn _ret;\n";
	io ~= "\t}\n\n";
	io ~= "\tpublic void writeBool(boolean a) {\n";
	io ~= "\t\tthis._buffer[this._index++] = (byte)(a ? 1 : 0);\n";
	io ~= "\t}\n\n";
	io ~= "\tpublic boolean readBool() {\n";
	io ~= "\t\treturn this._index < this._buffer.length && this._buffer[this._index++] != 0;\n";
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
			io ~= "\tpublic void writeVar" ~ sign ~ varint[0] ~ "(long a) {\n";
			if(sign.length) {
				io ~= "\t\twhile(a > 127) {\n";
				io ~= "\t\t\tthis._buffer[this._index++] = (byte)(a & 127 | 128);\n";
				io ~= "\t\t\ta >>>= 7;\n";
				io ~= "\t\t}\n";
				io ~= "\t\tthis._buffer[this._index++] = (byte)(a & 255);\n";
			} else {
				io ~= "\t\tthis.writeVaru" ~ varint[0] ~ "(a >= 0 ? a * 2  : a * -2 - 1);\n";
			}
			io ~= "\t}\n\n";
			// read
			io ~= "\tpublic " ~ varint[0] ~ " readVar" ~ sign ~ varint[0] ~ "() {\n";
			if(sign.length) {
				io ~= "\t\tint limit = 0;\n";
				io ~= "\t\t" ~ varint[0] ~ " ret = 0;\n";
				io ~= "\t\tdo {\n";
				io ~= "\t\t\tret |= (" ~ varint[0] ~ ")(this._buffer[this._index] & 127) << (limit * 7);\n";
				io ~= "\t\t} while(this._buffer[this._index++] < 0 && ++limit < " ~ to!string(varint[1]) ~ " && this._index < this._buffer.length);\n";
				io ~= "\t\treturn ret;\n";
			} else {
				io ~= "\t\t" ~ varint[0] ~ " ret = this.readVaru" ~ varint[0] ~ "();\n";;
				io ~= "\t\treturn (" ~ varint[0] ~ ")((ret & 1) == 0 ? ret / 2 : (-ret - 1) / 2);\n";
			}
			io ~= "\t}\n\n";
			// length
			io ~= "\tpublic static int var" ~ sign ~ varint[0] ~ "Length(" ~ varint[0] ~ " a) {\n";
			io ~= "\t\tint length = 1;\n";
			io ~= "\t\twhile((a & 128) != 0 && length < " ~ to!string(varint[1]) ~ ") {\n";
			io ~= "\t\t\tlength++;\n";
			io ~= "\t\t\ta >>>= 7;\n";
			io ~= "\t\t}\n";
			io ~= "\t\treturn length;\n";
			io ~= "\t}\n\n";
		}
	}
	io ~= "\tpublic boolean eof() {\n";
	io ~= "\t\treturn this._index >= this._buffer.length;\n";
	io ~= "\t}\n\n";
	io ~= "}";
	write("../src/java/sul/utils/Buffer.java", io);

	write("../src/java/sul/utils/Stream.java", q{
package sul.utils;

public abstract class Stream extends Buffer {

	public final void reset() {
		this._buffer = new byte[0];
		this._index = 0;
	}
	
	public abstract int length();
	
	public abstract byte[] encode();
	
	public abstract void decode(byte[] buffer);

}
	});
	
	write("../src/java/sul/utils/Packet.java", q{
package sul.utils;

public abstract class Packet extends Stream {

	public abstract int getId();

}
	});
	
	write("../src/java/sul/utils/Item.java", q{
package sul.utils;

public class Item {

	public final String name;
	public final int id, meta;
	public final Enchantment[] enchantments;

	public Item(String name, int id, int meta, Enchantment[] enchantments) {
		this.name = name;
		this.id = id;
		this.meta = meta;
		this.enchantments = enchantments;
	}

}
	});
	
	write("../src/java/sul/utils/Enchantment.java", q{
package sul.utils;

public class Enchantment {

	public final byte id;
	public final short level;

	public Enchantment(byte id, short level) {
		this.id = id;
		this.level = level;
	}

}
	});

	write("../src/java/sul/utils/MetadataException.java", q{
package sul.utils;

public class MetadataException extends RuntimeException {

	private static final long serialVersionUID = 0x5EL;

	public MetadataException(String reason) {
		super(reason);
	}

}
	});
	
	// attributes
	foreach(string game, Attributes attrs; attributes) {
		string data = "package sul.attributes;\n\npublic enum " ~ toPascalCase(game) ~ " {\n\n";
		foreach(i, attr; attrs.data) {
			data ~= "\t" ~ toUpper(attr.id) ~ "(\"" ~ attr.name ~ "\", " ~ attr.min.to!string ~ "f, " ~ attr.max.to!string ~ "f, " ~ attr.def.to!string ~ "f)" ~ (i == attrs.data.length - 1 ? ";" : ",") ~ "\n\n";
		}
		data ~= "\tpublic final String name;\n\tpublic final float min, max, def;\n\n";
		data ~= "\t" ~ toPascalCase(game) ~ "(String name, float min, float max, float def) {\n";
		data ~= "\t\tthis.name = name;\n";
		data ~= "\t\tthis.min = min;\n";
		data ~= "\t\tthis.max = max;\n";
		data ~= "\t\tthis.def = def;\n";
		data ~= "\t}\n\n}";
		mkdirRecurse("../src/java/sul/attributes");
		write("../src/java/sul/attributes/" ~ toPascalCase(game) ~ ".java", data, "attributes/" ~ game);
	}
	
	// creative
	foreach(string game, Creative c; creative) {
		string data = "package sul.creative;\n\nimport sul.utils.*;\n\npublic final class " ~ toPascalCase(game) ~ " {\n\n";
		data ~= "\tprivate " ~ toPascalCase(game) ~ "() {}\n\n";
		data ~= "\tpublic static final Item[] ITEMS = new Item[]{\n";
		foreach(i, item; c.data) {
			data ~= "\t\tnew Item(" ~ JSONValue(item.name).toString() ~ ", " ~ item.id.to!string ~ ", " ~ item.meta.to!string ~ ", new Enchantment[]{";
			if(item.enchantments.length) {
				string[] e;
				foreach(ench ; item.enchantments) e ~= "new Enchantment((byte)" ~ ench.id.to!string ~ ", (short)" ~ ench.level.to!string ~ ")";
				data ~= e.join(", ");
			}
			data ~= "})" ~ (i != c.data.length - 1 ? "," : "") ~ "\n";
		}
		data ~= "\t};\n\n}";
		mkdirRecurse("../src/java/sul/creative");
		write("../src/java/sul/creative/" ~ toPascalCase(game) ~ ".java", data, "creative/" ~ game);
	}
	
	// protocols
	string[] tuples;
	foreach(string game, Protocols prs; protocols) {
		
		mkdirRecurse("../src/java/sul/protocol/" ~ game ~ "/types");

		bool usesMetadata;
		
		@property string convert(string type) {
			auto end = min(cast(size_t)type.indexOf("["), cast(size_t)type.lastIndexOf("<"), type.length);
			auto t = type[0..end];
			auto e = type[end..$].replaceAll(ctRegex!`\[[0-9]{1,}\]`, "[]");
			auto a = t in defaultAliases;
			if(a) return convert(*a ~ e);
			auto b = t in prs.data.arrays;
			if(b) return convert((*b).base ~ "[]" ~ e);
			if(e.length && e[0] == '<') return "Tuples." ~ toPascalCase(t) ~ toUpper(e[1..e.indexOf(">")]) ~ e[e.indexOf(">")+1..$];
			else if(defaultTypes.canFind(t)) return t ~ e;
			else if(t == "metadata") { usesMetadata = true; return "sul.metadata." ~ capitalize(game) ~ e; }
			else return "sul.protocol." ~ game ~ ".types." ~ toPascalCase(t) ~ e;
		}
		
		@property string convertName(string name) {
			if(name == "default") return "def";
			else return toCamelCase(name);
		}
		
		immutable id = convert(prs.data.id);
		immutable arrayLength = convert(prs.data.arrayLength);
		
		void fieldsLengthImpl(string name, string type, ref size_t fixed, ref string[] exps, ref string[] seps) {
			auto at = type in prs.data.arrays;
			if(at) {
				type = at.base ~ "[]";
			}
			auto array = type.lastIndexOf("[");
			auto tup = type.indexOf("<");
			if(array != -1) {
				if(type.indexOf("]") == array + 1) fieldsLengthImpl(name ~ ".length", at ? at.length : prs.data.arrayLength, fixed, exps, seps);
				size_t new_fixed = 0;
				string[] new_exps;
				fieldsLengthImpl(hash(name), type[0..array], new_fixed, new_exps, seps);
				if(new_fixed != 0) {
					if(type.indexOf("]") == array + 1) exps ~= name ~ ".length" ~ (new_fixed > 1 ? "*" ~ to!string(new_fixed) : "");
					else fixed += to!size_t(type[array+1..type.indexOf("]")]) * new_fixed;
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
		
		string fieldsLength(Field[] fields, string id_type="", ptrdiff_t id=-1, string length="") {
			size_t fixed = 0;
			string[] exps, seps;
			if(id_type.length) {
				if(id_type.startsWith("var")) {
					if(id_type[3] == 'u') id *= 2; // only positive ids
					while(id & 0x80) {
						fixed++;
						id >>>= 7;
					}
					fixed++;
				} else {
					fieldsLengthImpl("ID", id_type, fixed, exps, seps);
				}
			}
			if(length.length) {
				if(length.startsWith("var")) fixed += length.endsWith("short") ? 3 : (length.endsWith("int") ? 5 : 10);
				else fieldsLengthImpl("", length, fixed, exps, seps);
			}
			foreach(i, field; fields) {
				fieldsLengthImpl(field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.type, fixed, exps, seps);
			}
			if(seps.length) {
				if(fixed > 0 || exps.length == 0) exps ~= to!string(fixed);
				return "int length=" ~ join(exps, " + ") ~ "; " ~ seps.join(";") ~ " return length";
			} else {
				if(fixed > 0 || exps.length == 0) exps ~= to!string(fixed);
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
			else if(type == "bool") return "this.writeBool(" ~ name ~ ");";
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
				immutable newexp = cnt.indexOf("[") >= 0 ? (cnt[0..cnt.indexOf("[")] ~ "[" ~ hash("l" ~ name) ~ "][]") : (cnt ~ "[" ~ hash("l" ~ name) ~ "]");
				if(cnt == "byte") return ret ~ name ~ "=this.readBytes(" ~ hash("l" ~ name) ~ ");";
				else return ret ~ name ~ "=new " ~ newexp ~ "; for(int " ~ hash(name) ~ "=0;" ~ hash(name) ~ "<" ~ name ~ ".length;" ~ hash(name) ~ "++){ " ~ createDecoding(nt, name ~ "[" ~ hash(name) ~ "]") ~ " }";
			}
			auto ts = conv.lastIndexOf("<");
			if(ts > 0) {
				auto te = conv.lastIndexOf(">");
				string nt = conv[0..ts];
				string[] ret;
				foreach(i ; conv[ts+1..te]) {
					ret ~= createDecoding(nt, name ~ "." ~ i);
				}
				return name ~ "=new " ~ convert(conv) ~ "(); " ~ ret.join(" ");
			}
			type = conv;
			if(type.startsWith("var")) return name ~ "=this.read" ~ capitalize(type) ~ "();";
			else if(type == "string") return createDecoding(prs.data.arrayLength, arrayLength ~ " " ~ hash("len" ~ name)) ~ " " ~ name ~ "=new String(this.readBytes(" ~ hash("len" ~ name) ~ "), StandardCharsets.UTF_8);";
			else if(type == "uuid") return createDecoding("long", "long " ~ hash("\x00" ~ name)) ~ " " ~ createDecoding("long", "long " ~ hash("\xF0" ~ name)) ~ " " ~ name ~ "=new UUID(" ~ hash("\x00" ~ name) ~ "," ~ hash("\xF0" ~ name) ~ ");";
			else if(type == "bytes") return name ~ "=this.readBytes(this._buffer.length-this._index);";
			else if(type == "bool") return name ~ "=this.readBool();";
			else if(defaultTypes.canFind(type) || type == "triad") return name ~ "=read" ~ endiannessOf(type, e) ~ capitalize(type) ~ "();";
			else return name ~ "=new " ~ convert(type) ~ "(); " ~ name ~ "._index=this._index; " ~ name ~ ".decode(this._buffer); this._index=" ~ name ~ "._index;";
		}
		
		// write generic fields
		void writeFields(ref string data, string space, string className, Field[] fields, ptrdiff_t id=-1, bool hasVariants=false, bool isVariant=false, string length="") { // hasId is true when fields belong to a packet, false when a type
			// constants
			foreach(field ; fields) {
				if(field.constants.length) {
					data ~= space ~ "// " ~ field.name.replace("_", " ") ~ "\n";
					foreach(constant ; field.constants) {
						data ~= space ~ "public static final " ~ convert(field.type) ~ " " ~ toUpper(constant.name) ~ " = " ~ (field.type == "string" ? JSONValue(constant.value).toString() : constant.value) ~ ";\n";
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
				//if(c.indexOf("[") != -1) data ~= " = new " ~ c[0..c.indexOf("[")] ~ "[" ~ (ca == -1 || ca == oa + 1 ? "0" : field.type[oa+1..ca]) ~ "]";
				if(c.indexOf("[") != -1) data ~= " = new " ~ c[0..c.indexOf("[")] ~ (oa == -1 ? "[0]" : field.type[oa..$].replace("[]", "[0]"));
				else if(field.def.length) data ~= " = " ~ constOf(field.def);
				else if(field.type == "bytes") data ~= " = new byte[0]";
				else if(c.startsWith("Tuples.")) data ~= " = new " ~ c ~ "()";
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
			data ~= space ~ "\t" ~ fieldsLength(fields, id >= 0 ? prs.data.id : "", id, length) ~ ";\n";
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
			if(id >= 0) {
				data ~= space ~ "\t" ~ createEncoding(prs.data.id, "ID") ~ "\n";
			}
			foreach(i, field; fields) {
				bool c = field.condition.length != 0;
				data ~= space ~ "\t" ~ (c ? "if(" ~ toCamelCase(field.condition) ~ "){ " : "") ~ createEncoding(field.type, field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.endianness) ~ (c ? " }" : "") ~ "\n";
			}
			if(length.length) {
				data ~= space ~ "\tbyte[] _this = this.getBuffer();\n";
				data ~= space ~ "\tthis._buffer = new byte[10 + _this.length];\n"; // longest length of a length type
				data ~= space ~ "\tthis._index = 0;\n";
				data ~= space ~ "\t" ~ createEncoding(length, "_this.length") ~ "\n";
				data ~= space ~ "\tthis.writeBytes(_this);\n";
			}
			data ~= space ~ "\treturn this.getBuffer();\n";
			data ~= space ~ "}\n\n";
			// decoding
			data ~= space ~ "@Override\n";
			data ~= space ~ "public void decode(byte[] buffer) {\n";
			data ~= space ~ "\tthis._buffer = buffer;\n";
			if(length.length) {
				data ~= space ~ "\t" ~ createDecoding(length, "final int _length") ~ "\n";
				data ~= space ~ "\tfinal int _length_index = this._index;\n";
				data ~= space ~ "\tthis._buffer = this.readBytes(_length);\n";
				data ~= space ~ "\tthis._index = 0;\n";
			}
			if(id >= 0) {
				data ~= space ~ "\t" ~ createDecoding(prs.data.id, "").split("=")[1..$].join("=") ~ "\n";
			}
			foreach(i, field; fields) {
				bool c = field.condition.length != 0;
				data ~= space ~ "\t" ~ (c ? "if(" ~ toCamelCase(field.condition) ~ "){ " : "") ~ createDecoding(field.type, field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.endianness) ~ (c ? " }" : "") ~ "\n";
			}
			if(length.length) {
				data ~= space ~ "\tthis._index += _length_index;\n";
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

		void createToString(ref string data, string space, string className, Field[] fields) {
			data ~= space ~ "@Override\n";
			data ~= space ~ "public String toString() {\n";
			string[] f;
			foreach(i, field; fields) {
				immutable c = convert(field.type);
				immutable n = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
				string dec = n ~ ": \" + ";
				if(c.endsWith("[]")) {
					bool deep = true;
					foreach(simple ; ["boolean", "byte", "short", "int", "long", "float", "double"]) {
						if(c.startsWith(simple)) {
							deep = false;
							break;
						}
					}
					if(deep) dec ~= "Arrays.deepToString(this." ~ n ~ ")";
					else dec ~= "Arrays.toString(this." ~ n ~ ")";
				} else {
					if(["boolean", "byte", "short", "int", "long", "float", "double", "String"].canFind(c)) dec ~= "this." ~ n;
					else dec ~= "this." ~ n ~ ".toString()";
				}
				f ~= dec;
			}
			data ~= space ~ "\treturn \"" ~ className ~ "(" ~ (f.length ? (f.join(" + \", ") ~ " + \"") : "") ~ ")\";\n";
			data ~= space ~ "}\n\n";
		}
		
		@property string imports(Field[] fields) {
			bool str, arrays, uuid;
			foreach(field ; fields) {
				auto conv = convert(field.type);
				if(conv.endsWith("[]")) arrays = true;
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
			if(arrays) ret ~= "import java.util.Arrays;\n";
			if(uuid) ret ~= "import java.util.UUID;\n";
			if(str || arrays || uuid) ret ~= "\n";
			return ret;
		}
		
		foreach(type ; prs.data.types) {
			string data = "package sul.protocol." ~ game ~ ".types;\n\n" ~ imports(type.fields) ~ "import sul.utils.*;\n\n";
			if(type.description.length) data ~= javadoc("", type.description);
			data ~= "public class " ~ toPascalCase(type.name) ~ " extends Stream {\n\n";
			writeFields(data, "\t", toPascalCase(type.name), type.fields, -1, false, false, type.length);
			createToString(data, "\t", toPascalCase(type.name), type.fields);
			data ~= "\n}";
			write("../src/java/sul/protocol/" ~ game ~ "/types/" ~ toPascalCase(type.name) ~ ".java", data, "protocol/" ~ game);
		}
		string sections = "package sul.protocol." ~ game ~ ";\n\n";
		sections ~= "import java.util.Collections;\nimport java.util.Map;\nimport java.util.HashMap;\n\n";
		sections ~= "import sul.utils.Packet;\n\n";
		if(prs.data.description.length) {
			sections ~= javadoc("", prs.data.description);
		}
		sections ~= "public final class Packets {\n\n";
		sections ~= "\tprivate Packets() {}\n\n";
		foreach(section ; prs.data.sections) {
			if(section.description.length) {
				sections ~= javadoc("\t", section.description);
			}
			sections ~= "\tpublic static final Map<Integer, Class<? extends Packet>> " ~ section.name.toUpper ~ ";\n\n";
		}
		sections ~= "\tstatic {\n\n";
		foreach(section ; prs.data.sections) {
			immutable sectionName = section.name.replace("_", "");
			sections ~= "\t\tHashMap<Integer, Class<? extends Packet>> " ~ sectionName ~ " = new HashMap<Integer, Class<? extends Packet>>();\n";
			mkdirRecurse("../src/java/sul/protocol/" ~ game ~ "/" ~ sectionName);
			foreach(packet ; section.packets) {
				sections ~= "\t\t" ~ sectionName ~ ".put(" ~ packet.id.to!string ~ ", sul.protocol." ~ game ~ "." ~ sectionName ~ "." ~ toPascalCase(packet.name) ~ ".class);\n";
				string data = "package sul.protocol." ~ game ~ "." ~ sectionName ~ ";\n\n" ~ imports(packet.fields ~ (){ Field[] fields;foreach(v;packet.variants){fields~=v.fields;}return fields;}()) ~ "import sul.utils.*;\n\n";
				if(packet.description.length) {
					data ~= javadoc("", packet.description);
				}
				data ~= "public class " ~ toPascalCase(packet.name) ~ " extends Packet {\n\n";
				data ~= "\tpublic static final " ~ id ~ " ID = (" ~ id ~ ")" ~ to!string(packet.id) ~ ";\n\n";
				data ~= "\tpublic static final boolean CLIENTBOUND = " ~ to!string(packet.clientbound) ~ ";\n";
				data ~= "\tpublic static final boolean SERVERBOUND = " ~ to!string(packet.serverbound) ~ ";\n\n";
				data ~= "\t@Override\n";
				data ~= "\tpublic int getId() {\n";
				data ~= "\t\treturn ID;\n";
				data ~= "\t}\n\n";
				writeFields(data, "\t", toPascalCase(packet.name), packet.fields, packet.id, packet.variants.length != 0, false);
				data ~= "\tpublic static " ~ toPascalCase(packet.name) ~ " fromBuffer(byte[] buffer) {\n";
				data ~= "\t\t" ~ toPascalCase(packet.name) ~ " ret = new " ~ toPascalCase(packet.name) ~ "();\n";
				data ~= "\t\tret.decode(buffer);\n";
				data ~= "\t\treturn ret;\n";
				data ~= "\t}\n\n";
				createToString(data, "\t", toPascalCase(packet.name), packet.fields);
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
						data ~= "\t\tpublic static final " ~ vt ~ " " ~ toUpper(packet.variantField) ~ " = (" ~ vt ~ ")" ~ variant.value ~ ";\n\n";
						data ~= "\t\t@Override\n";
						data ~= "\t\tpublic int getId() {\n";
						data ~= "\t\t\treturn ID;\n";
						data ~= "\t\t}\n\n";
						writeFields(data, "\t\t", toPascalCase(variant.name), variant.fields, -1, false, true);
						createToString(data, "\t\t", toPascalCase(packet.name) ~ "." ~ toPascalCase(variant.name), variant.fields);
						data ~= "\t}\n\n";
					}
				}
				data ~= "}";
				write("../src/java/sul/protocol/" ~ game ~ "/" ~ sectionName ~ "/" ~ toPascalCase(packet.name) ~ ".java", data, "protocol/" ~ game);
			}
			sections ~= "\t\t" ~ section.name.toUpper ~ " = Collections.unmodifiableMap(" ~ sectionName ~ ");\n\n";
		}
		sections ~= "\t}\n\n}";
		write("../src/java/sul/protocol/" ~ game ~ "/Packets.java", sections);

		// metadata
		auto m = game in metadatas;
		string data = "package sul.metadata;\n\nimport java.nio.charset.StandardCharsets;\n\nimport sul.utils.*;\n\n";
		data ~= "@SuppressWarnings(\"unused\")\n";
		data ~= "public class " ~ toPascalCase(game) ~ " extends Stream {\n\n";
		if(m) {
			//TODO variables
			//TODO length
			data ~= "\t@Override\n\tpublic int length() {\n";
			data ~= "\t\treturn 1;\n"; // just the length or the suffix
			data ~= "\t}\n\n";
			//TODO encode
			data ~= "\t@Override\n\tpublic byte[] encode() {\n";
			// only encoding as empty
			if(m.data.length.length) data ~= "\t\t" ~ createEncoding(m.data.length, "0") ~ "\n";
			else if(m.data.suffix.length) data ~= "\t\t" ~ createEncoding("ubyte", "(byte)" ~ m.data.suffix) ~ "\n";
			data ~= "\t\treturn this.getBuffer();\n";
			data ~= "\t}\n\n";
			//TODO decode
			data ~= "\t@Override\n\tpublic void decode(byte[] buffer) {\n";
			// decoding but not saving
			data ~= "\t\tbyte metadata;\n";
			if(m.data.length.length) {
				data ~= "\t\t" ~ createDecoding(m.data.length, "int length") ~ "\n";
				data ~= "\t\twhile(length-- > 0) {\n";
				data ~= "\t\t\t" ~ createDecoding("byte", "metadata") ~ "\n";
			} else if(m.data.suffix.length) {
				data ~= "\t\twhile(!this.eof() && (" ~ createDecoding("byte", "metadata")[0..$-1] ~ ") != (byte)" ~ m.data.suffix ~ ") {\n";
			}
			data ~= "\t\t\tswitch(" ~ createDecoding("byte", "")[1..$-1] ~ ") {\n";
			foreach(type ; m.data.types) {
				data ~= "\t\t\t\tcase " ~ type.id.to!string ~ ":\n";
				data ~= "\t\t\t\t\t" ~ convert(type.type) ~ " _" ~ type.id.to!string ~ ";\n";
				data ~= "\t\t\t\t\t" ~ createDecoding(type.type, "_" ~ type.id.to!string, type.endianness) ~ "\n";
				data ~= "\t\t\t\t\tbreak;\n";
			}
			data ~= "\t\t\t\tdefault: break;\n";
			data ~= "\t\t\t}\n";
			data ~= "\t\t}\n";
			data ~= "\t}\n\n";
		} else {
			// dummy class
			data ~= "\t@Override\n\tpublic int length() {\n\t\treturn 0;\n\t}\n\n";
			data ~= "\t@Override\n\tpublic byte[] encode() {\n\t\tthrow new MetadataException(\"Metadata for " ~ game ~ " is not supported\");\n\t}\n\n";
			data ~= "\t@Override\n\tpublic void decode(byte[] buffer) {\n\t\tthrow new MetadataException(\"Metadata for " ~ game ~ " is not supported\");\n\t}\n\n";
		}
		data ~= "}";
		mkdirRecurse("../src/java/sul/metadata");
		if(usesMetadata) write("../src/java/sul/metadata/" ~ toPascalCase(game) ~ ".java", data, m ? "metadata/" ~ game : "");

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
		tp ~= "\t\t@Override\n";
		tp ~= "\t\tpublic String toString() {\n";
		tp ~= "\t\t\treturn \"" ~ capitalize(spl[0]) ~ spl[1].toUpper() ~ "(";
		foreach(i, c; spl[1].split("")) {
			tp ~= c ~ ": \" + " ~ c ~ " + \"" ~ (i != spl[1].length - 1 ? ", " : "");
		}
		tp ~= ")\";\n";
		tp ~= "\t\t}\n\n";
		tp ~= "\t}\n\n";
	}
	write("../src/java/sul/utils/Tuples.java", tp ~ "}");

	// blocks
	{
		string data = "package sul;\n\n";
		data ~= "import java.util.*;\n\n";
		data ~= "public final class Blocks {\n\n";
		data ~= "\tpublic final String name;\n";
		data ~= "\tpublic final short id;\n";
		data ~= "\tpublic final BlockData minecraft, pocket;\n";
		data ~= "\tpublic final boolean solid;\n";
		data ~= "\tpublic final double hardness, blastResistance;\n";
		data ~= "\tpublic final byte opacity, luminance;\n";
		data ~= "\tpublic final boolean replaceable;\n\n";
		data ~= "\tprivate Blocks(String name, short id, BlockData minecraft, BlockData pocket, boolean solid, double hardness, double blastResistance, byte opacity, byte luminance, boolean replaceable) {\n";
		data ~= "\t\tthis.name = name;\n";
		data ~= "\t\tthis.id = id;\n";
		data ~= "\t\tthis.minecraft = minecraft;\n";
		data ~= "\t\tthis.pocket = pocket;\n";
		data ~= "\t\tthis.solid = solid;\n";
		data ~= "\t\tthis.hardness = hardness;\n";
		data ~= "\t\tthis.blastResistance = blastResistance;\n";
		data ~= "\t\tthis.opacity = opacity;\n";
		data ~= "\t\tthis.luminance = luminance;\n";
		data ~= "\t\tthis.replaceable = replaceable;\n";
		data ~= "\t}\n\n";
		data ~= "\tprivate static class BlockData {\n\n";
		data ~= "\t\tpublic final int id, meta;\n\n";
		data ~= "\t\tpublic BlockData(int id, int meta) {\n";
		data ~= "\t\t\tthis.id = id;\n";
		data ~= "\t\t\tthis.meta = meta;\n";
		data ~= "\t\t}\n\n";
		data ~= "\t}\n\n";
		data ~= "\tprivate static Map<Short, Blocks> selBlocks;\n";
		data ~= "\tprivate static Map<Integer, Map<Integer, Blocks>> minecraftBlocks, pocketBlocks;\n\n";
		data ~= "\tstatic {\n\n";
		data ~= "\t\tselBlocks = new HashMap<Short, Blocks>();\n\n";
		data ~= "\t\tminecraftBlocks = new HashMap<Integer, Map<Integer, Blocks>>();\n";
		data ~= "\t\tpocketBlocks = new HashMap<Integer, Map<Integer, Blocks>>();\n\n";
		foreach(block ; blocks) {
			data ~= "\t\tadd(new Blocks(";
			data ~= "\"" ~ block.name.replace("_" , " ") ~ "\", ";
			data ~= "(short)" ~ block.id.to!string ~ ", ";
			data ~= (block.minecraft.id >= 0 ? ("new BlockData(" ~ block.minecraft.id.to!string ~ ", " ~ (block.minecraft.meta < 0 ? "0" : block.minecraft.meta.to!string) ~ ")") : "null") ~ ", ";
			data ~= (block.pocket.id >= 0 ? ("new BlockData(" ~ block.pocket.id.to!string ~ ", " ~ (block.pocket.meta < 0 ? "0" : block.pocket.meta.to!string) ~ ")") : "null") ~ ", ";
			data ~= block.solid.to!string ~ ", ";
			data ~= "(double)" ~ block.hardness.to!string ~ ", ";
			data ~= "(double)" ~ block.blastResistance.to!string ~ ", ";
			data ~= "(byte)" ~ block.opacity.to!string ~ ", ";
			data ~= "(byte)" ~ block.luminance.to!string ~ ", ";
			data ~= block.replaceable.to!string;
			data ~= "));\n";
		}
		data ~= "\n\t}\n\n";
		data ~= "\tprivate static void add(Blocks block) {\n";
		data ~= "\t\tselBlocks.put(block.id, block);\n";
		data ~= "\t\tif(block.minecraft != null) {\n";
		data ~= "\t\t\tif(!minecraftBlocks.containsKey(block.minecraft.id)) minecraftBlocks.put(block.minecraft.id, new HashMap<Integer, Blocks>());\n";
		data ~= "\t\t\tminecraftBlocks.get(block.minecraft.id).put(block.minecraft.meta, block);\n";
		data ~= "\t\t}\n";
		data ~= "\t\tif(block.pocket != null) {\n";
		data ~= "\t\t\tif(!pocketBlocks.containsKey(block.pocket.id)) pocketBlocks.put(block.pocket.id, new HashMap<Integer, Blocks>());\n";
		data ~= "\t\t\tpocketBlocks.get(block.pocket.id).put(block.pocket.meta, block);\n";
		data ~= "\t\t}\n";
		data ~= "\t}\n\n";
		// get methods
		data ~= "\tpublic static Blocks getSelBlock(short id) {\n";
		data ~= "\t\treturn selBlocks.get(id);\n";
		data ~= "\t}\n\n";
		foreach(type ; TypeTuple!("minecraft", "pocket")) {
			data ~= "\tpublic static Blocks get" ~ capitalize(type) ~ "Block(int id, int meta) {\n";
			data ~= "\t\tMap<Integer, Blocks> b = " ~ type ~ "Blocks.get(id);\n";
			data ~= "\t\treturn b != null ? b.get(meta) : null;\n";
			data ~= "\t}\n\n";
		}
		data ~= "}";
		write("../src/java/sul/Blocks.java", data, "blocks");
	}

	// items
	{
		string data = "package sul;\n\n";
		data ~= "import java.util.*;\n\n";
		data ~= "public final class Items {\n\n";
		data ~= "\tpublic final String name;\n";
		data ~= "\tpublic final ItemData minecraft, pocket;\n";
		data ~= "\tpublic final byte stack;\n\n";
		data ~= "\tprivate Items(String name, ItemData minecraft, ItemData pocket, byte stack) {\n";
		data ~= "\t\tthis.name = name;\n";
		data ~= "\t\tthis.minecraft = minecraft;\n";
		data ~= "\t\tthis.pocket = pocket;\n";
		data ~= "\t\tthis.stack = stack;\n";
		data ~= "\t}\n\n";
		data ~= "\tprivate static class ItemData {\n\n";
		data ~= "\t\tpublic final int id, meta;\n\n";
		data ~= "\t\tpublic ItemData(int id, int meta) {\n";
		data ~= "\t\t\tthis.id = id;\n";
		data ~= "\t\t\tthis.meta = meta;\n";
		data ~= "\t\t}\n\n";
		data ~= "\t}\n\n";
		data ~= "\tprivate static Map<Integer, Map<Integer, Items>> minecraftItems, pocketItems;\n\n";
		data ~= "\tstatic {\n\n";
		data ~= "\t\tminecraftItems = new HashMap<Integer, Map<Integer, Items>>();\n";
		data ~= "\t\tpocketItems = new HashMap<Integer, Map<Integer, Items>>();\n\n";
		foreach(item ; items) {
			data ~= "\t\tadd(new Items(";
			data ~= "\"" ~ item.name.replace("_" , " ") ~ "\", ";
			data ~= (item.minecraft.exists ? ("new ItemData(" ~ item.minecraft.id.to!string ~ ", " ~ to!string(max(0, item.minecraft.meta)) ~ ")") : "null") ~ ", ";
			data ~= (item.pocket.exists ? ("new ItemData(" ~ item.pocket.id.to!string ~ ", " ~ to!string(max(0, item.pocket.meta)) ~ ")") : "null") ~ ", ";
			data ~= "(byte)" ~ item.stack.to!string;
			data ~= "));\n";
		}
		data ~= "\n\t}\n\n";
		data ~= "\tprivate static void add(Items item) {\n";
		data ~= "\t\tif(item.minecraft != null) {\n";
		data ~= "\t\t\tif(!minecraftItems.containsKey(item.minecraft.id)) minecraftItems.put(item.minecraft.id, new HashMap<Integer, Items>());\n";
		data ~= "\t\t\tminecraftItems.get(item.minecraft.id).put(item.minecraft.meta, item);\n";
		data ~= "\t\t}\n";
		data ~= "\t\tif(item.pocket != null) {\n";
		data ~= "\t\t\tif(!pocketItems.containsKey(item.pocket.id)) pocketItems.put(item.pocket.id, new HashMap<Integer, Items>());\n";
		data ~= "\t\t\tpocketItems.get(item.pocket.id).put(item.pocket.meta, item);\n";
		data ~= "\t\t}\n";
		data ~= "\t}\n\n";
		// get methods
		foreach(type ; TypeTuple!("minecraft", "pocket")) {
			data ~= "\tpublic static Items get" ~ capitalize(type) ~ "Item(int id, int meta) {\n";
			data ~= "\t\tMap<Integer, Items> b = " ~ type ~ "Items.get(id);\n";
			data ~= "\t\tif(b != null) {\n";
			data ~= "\t\t\tItems ret = b.get(meta);\n";
			data ~= "\t\t\tif(ret != null) return ret;\n";
			data ~= "\t\t\telse if(meta != 0) return b.get(0);\n";
			data ~= "\t\t}\n";
			data ~= "\t\treturn null;\n";
			data ~= "\t}\n\n";
		}
		data ~= "}";
		write("../src/java/sul/Items.java", data, "items");
	}
	
	// entities
	{
		string data = "package sul;\n\n";
		data ~= "import java.util.*;\n\n";
		data ~= "public final class Entities {\n\n";
		data ~= "\tpublic final String name;\n";
		data ~= "\tpublic final boolean object;\n";
		data ~= "\tpublic final int minecraft, pocket;\n";
		data ~= "\tpublic final double width, height;\n\n";
		data ~= "\tprivate Entities(String name, boolean object, int minecraft, int pocket, double width, double height) {\n";
		data ~= "\t\tthis.name = name;\n";
		data ~= "\t\tthis.object = object;\n";
		data ~= "\t\tthis.minecraft = minecraft;\n";
		data ~= "\t\tthis.pocket = pocket;\n";
		data ~= "\t\tthis.width = width;\n";
		data ~= "\t\tthis.height = height;\n";
		data ~= "\t}\n\n";
		foreach(entity ; entities) {
			data ~= "\tpublic static final Entities " ~ entity.name.toUpper ~ " = new Entities(";
			data ~= "\"" ~ entity.name.replace("_", " ") ~ "\", ";
			data ~= entity.object.to!string ~ ", ";
			data ~= (entity.minecraft ? entity.minecraft.to!string : "-1") ~ ", ";
			data ~= (entity.pocket ? entity.pocket.to!string : "-1") ~ ", ";
			data ~= (entity.width.isNaN ? "Double.NaN" : entity.width.to!string) ~ ", ";
			data ~= (entity.height.isNaN ? "Double.NaN" : entity.height.to!string);
			data ~= ");\n";
		}
		data ~= "\n";
		data ~= "\tprivate static Map<Integer, Entities> minecraftEntities, minecraftObjects, pocketEntities, pocketObjects;\n\n";
		data ~= "\tstatic {\n\n";
		data ~= "\t\tminecraftEntities = new HashMap<Integer, Entities>();\n";
		data ~= "\t\tminecraftObjects = new HashMap<Integer, Entities>();\n";
		data ~= "\t\tpocketEntities = new HashMap<Integer, Entities>();\n";
		data ~= "\t\tpocketObjects = new HashMap<Integer, Entities>();\n\n";
		foreach(entity ; entities) {
			data ~= "\t\tadd(" ~ entity.name.toUpper ~ ");\n";
		}
		data ~= "\n\t}\n\n";
		data ~= "\tprivate static void add(Entities entity) {\n";
		foreach(type ; TypeTuple!("minecraft", "pocket")) {
			data ~= "\t\tif(entity." ~ type ~ " != -1) {\n";
			data ~= "\t\t\tif(entity.object) " ~ type ~ "Objects.put(entity." ~ type ~ ", entity);\n";
			data ~= "\t\t\tif(!entity.object || !" ~ type ~ "Entities.containsKey(entity." ~ type ~ ")) " ~ type ~ "Entities.put(entity." ~ type ~ ", entity);\n";
			data ~= "\t\t}\n";
		}
		data ~= "\t}\n\n";
		foreach(type ; TypeTuple!("minecraft", "pocket")) {
			data ~= "\tpublic static Entities get" ~ capitalize(type) ~ "Entity(int id, boolean object) {\n";
			data ~= "\t\tif(object && " ~ type ~ "Objects.containsKey(id)) return " ~ type ~ "Objects.get(id);\n";
			data ~= "\t\telse return " ~ type ~ "Entities.get(id);\n";
			data ~= "\t}\n\n";
			data ~= "\tpublic static Entities get" ~ capitalize(type) ~ "Entity(int id) {\n";
			data ~= "\t\treturn get" ~ capitalize(type) ~ "Entity(id, false);\n";
			data ~= "\t}\n\n";
			data ~= "\tpublic static Entities get" ~ capitalize(type) ~ "Object(int id) {\n";
			data ~= "\t\treturn get" ~ capitalize(type) ~ "Entity(id, true);\n";
			data ~= "\t}\n\n";
		}
		data ~= "}";
		write("../src/java/sul/Entities.java", data, "entities");
	}
	
	// enchantments
	{
		string data = "package sul;\n\n";
		data ~= "import java.util.*;\n\n";
		data ~= "public final class Enchantments {\n\n";
		data ~= "\tpublic final String name;\n";
		data ~= "\tpublic final byte minecraft, pocket;\n";
		data ~= "\tpublic final byte max;\n\n";
		data ~= "\tprivate Enchantments(String name, byte minecraft, byte pocket, byte max) {\n";
		data ~= "\t\tthis.name = name;\n";
		data ~= "\t\tthis.minecraft = minecraft;\n";
		data ~= "\t\tthis.pocket = pocket;\n";
		data ~= "\t\tthis.max = max;\n";
		data ~= "\t}\n\n";
		foreach(e ; enchantments) {
			data ~= "\tpublic static final Enchantments " ~ e.name.toUpper ~ " = new Enchantments(";
			data ~= "\"" ~ e.name.replace("_", " ") ~ "\", ";
			data ~= "(byte)" ~ (e.minecraft >= 0 ? e.minecraft.to!string : "-1") ~ ", ";
			data ~= "(byte)" ~ (e.pocket >= 0 ? e.pocket.to!string : "-1") ~ ", ";
			data ~= "(byte)" ~ e.max.to!string;
			data ~= ");\n";
		}
		data ~= "\n";
		data ~= "\tprivate static Map<Integer, Enchantments> minecraftEnchantments, pocketEnchantments;\n\n";
		data ~= "\tstatic {\n\n";
		data ~= "\t\tminecraftEnchantments = new HashMap<Integer, Enchantments>();\n";
		data ~= "\t\tpocketEnchantments = new HashMap<Integer, Enchantments>();\n\n";
		foreach(e ; enchantments) {
			data ~= "\t\tadd(" ~ e.name.toUpper ~ ");\n";
		}
		data ~= "\n\t}\n\n";
		data ~= "\tprivate static void add(Enchantments e) {\n";
		foreach(type ; TypeTuple!("minecraft", "pocket")) {
			data ~= "\t\tif(e." ~ type ~ " != -1) " ~ type ~ "Enchantments.put((int)e." ~ type ~ ", e);\n";
		}
		data ~= "\t}\n\n";
		foreach(type ; TypeTuple!("minecraft", "pocket")) {
			data ~= "\tpublic static Enchantments get" ~ capitalize(type) ~ "Enchantment(int id) {\n";
			data ~= "\t\treturn " ~ type ~ "Enchantments.get(id);\n";
			data ~= "\t}\n\n";
		}
		data ~= "}";
		write("../src/java/sul/Enchantments.java", data, "enchantments");
	}
	
}

string javadoc(string space, string description) {
	bool search = true;
	while(search) {
		auto m = matchFirst(description, ctRegex!`\[[a-zA-Z0-9 \.]{2,30}\]\([a-zA-Z0-9_\#\.:\/-]{2,64}\)`);
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
