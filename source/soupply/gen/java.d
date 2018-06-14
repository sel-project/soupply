/*
 * Copyright (c) 2016-2018 sel-project
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */
module soupply.gen.java;

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

import soupply.data;
import soupply.generator;
import soupply.gen.code;
import soupply.util;

class JavaGenerator : CodeGenerator {

	static this() {
		Generator.register!JavaGenerator("Java", "java", "src/main/java/" ~ SOFTWARE);
	}

	public this() {
		
		CodeMaker.Settings settings;
		settings.inlineBraces = false;
		settings.moduleSeparator = ".";
		settings.standardLibrary = "std";
		
		settings.moduleStat = "package %s";
		settings.importStat = "import %s";
		settings.classStat = "class %s";
		settings.constStat = "enum %s = %d";
		
		super(settings, "java");
		
	}

	import std.stdio : writeln;

	protected override void generateImpl(Data data) {

		super.generateImpl(data);

		//TODO generate maven files

		//TODO generate latest modules (software instead of software123)

	}

	protected override void generateGame(string game, Info info) {

		// generate packet class
		with(make(game, "Packet")) {

			clear(); // remove pre-generated package declaration
			stat("package soupply." ~ game).nl;
			block("class Packet extends soupply.util.Packet").nl;
			stat("public abstract " ~ convertType(info.protocol.id) ~ " getId()").nl;

			// encode
			line("@Override");
			block("public byte[] encode()");
			stat("Buffer buffer = new Buffer()");
			stat("buffer.write" ~ capitalize(info.protocol.id) ~ "(this.getId())");
			if(info.protocol.padding) stat("buffer.writeBytes(new byte[" ~ info.protocol.padding.to!string ~ ")");
			stat("this.encodeBody(buffer)");
			endBlock().nl;

			// decode
			line("@Override");
			block("public void decode(byte[] _buffer)");
			stat("Buffer buffer = new Buffer(_buffer)");
			stat("buffer.read" ~ capitalize(info.protocol.id) ~ "()");
			if(info.protocol.padding) stat("buffer.readBytes(" ~ info.protocol.padding.to!string ~ ")");
			stat("this.decodeBody(buffer)");
			endBlock().nl;

			endBlock();
			save();
			
		}
		
		/+mkdirRecurse("../src/java/sul/utils");
		
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
							data ~= space ~ "public static final " ~ convert(field.type) ~ " " ~ toUpper(constant.name) ~ " = " ~ (field.type == "string" ? JSONValue(constant.value).toString() : "(" ~ convert(field.type) ~ ")" ~ constant.value) ~ ";\n";
						}
						data ~= "\n";
					}
				}
				// fields
				foreach(i, field; fields) {
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
				data ~= "public class " ~ toPascalCase(type.name) ~ " extends Stream {\n\n";
				writeFields(data, "\t", toPascalCase(type.name), type.fields, -1, false, false, type.length);
				createToString(data, "\t", toPascalCase(type.name), type.fields);
				data ~= "\n}";
				write("../src/java/sul/protocol/" ~ game ~ "/types/" ~ toPascalCase(type.name) ~ ".java", data, "protocol/" ~ game);
			}
			string sections = "package sul.protocol." ~ game ~ ";\n\n";
			sections ~= "import java.util.Collections;\nimport java.util.Map;\nimport java.util.HashMap;\n\n";
			sections ~= "import sul.utils.Packet;\n\n";
			sections ~= "public final class Packets {\n\n";
			sections ~= "\tprivate Packets() {}\n\n";
			foreach(section ; prs.data.sections) {
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
		write("../src/java/sul/utils/Tuples.java", tp ~ "}");+/
		
	}

	// type conversion
	
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
		"varshort": "short",
		"varushort": "short",
		"varint": "int",
		"varuint": "int",
		"varlong": "long",
		"varulong": "long"
	];
	
	protected override string convertType(string game, string type) {
		auto end = min(cast(size_t)type.indexOf("["), cast(size_t)type.lastIndexOf("<"), type.length);
		auto t = type[0..end];
		auto e = type[end..$].replaceAll(ctRegex!`\[[0-9]{1,}\]`, "[]");
		auto a = t in defaultAliases;
		if(a) return convertType(game, *a ~ e);
		if(e.length && e[0] == '<') return "Tuples." ~ toPascalCase(t) ~ toUpper(e[1..e.indexOf(">")]) ~ e[e.indexOf(">")+1..$];
		else if(defaultTypes.canFind(t)) return t ~ e;
		else if(t == "metadata") return "soupply." ~ game ~ ".Metadata." ~ e;
		else return "soupply." ~ game ~ ".types." ~ toPascalCase(t) ~ e;
	}

}
