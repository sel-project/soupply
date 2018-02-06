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
module soupply.gen.d;

import std.algorithm : canFind, max;
import std.array : Appender;
import std.ascii : newline;
import std.conv : to;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.math : isNaN;
import std.path : dirSeparator;
import std.regex : ctRegex, replaceAll, matchFirst;
import std.string;
import std.typecons;
import std.typetuple;

import soupply.data;
import soupply.generator;

Source source() { return Source("\t"); }

class DGenerator : Generator {

	static this() {
		Generator.register!DGenerator("d", "src/" ~ SOFTWARE);
	}

	protected override void generateImpl(Data data) {

		enum defaultTypes = ["bool", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "char", "string", "varint", "varuint", "varlong", "varulong", "UUID"];
		
		enum string[string] defaultAliases = [
			"uuid": "UUID",
			"bytes": "ubyte[]",
			"triad": "int",
			"varshort": "short",
			"varushort": "ushort",
			"varint": "int",
			"varuint": "uint",
			"varlong": "long",
			"varulong": "ulong"
		];

		// io utils
		auto io = source(); //TODO move to generator and read from public/name/.editorconfig
		io.line("module " ~ SOFTWARE ~ ".util.buffer;").br.line("import std.bitmanip;").line("import std.system : Endian;").br;
		io.line("class Buffer {").br.i;
		io.line("public ubyte[] _buffer;");
		io.line("public size_t _index;").br;
		io.line("public pure nothrow @property @safe @nogc Buffer bufferInstance() {").i.line("return this;").d.line("}").br;
		io.line("public pure nothrow @safe void writeBytes(ubyte[] bytes) {").i;
		io.line("this._buffer ~= bytes;").d;
		io.line("}").br;
		io ~= "\tpublic pure nothrow @trusted void writeString(string str) {\n\t\tthis.writeBytes(cast(ubyte[])str);\n\t}\n\n";
		io ~= "\tpublic pure nothrow @safe ubyte[] readBytes(size_t length) {\n";
		io ~= "\t\timmutable end = this._index + length;\n";
		io ~= "\t\tif(this._buffer.length < end) return (ubyte[]).init;\n";
		io ~= "\t\tauto ret = this._buffer[this._index..end].dup;\n";
		io ~= "\t\tthis._index = end;\n";
		io ~= "\t\treturn ret;\n";
		io ~= "\t}\n\n";
		io ~= "\tpublic pure nothrow @trusted string readString(size_t length) {\n\t\treturn cast(string)this.readBytes(length);\n\t}\n\n";
		foreach(type ; [tuple("bool", 1, "bool"), tuple("byte", 1, "byte"), tuple("short", 2, "short"), tuple("triad", 3, "int"), tuple("int", 4, "int"), tuple("long", 8, "long"), tuple("float", 4, "float"), tuple("double", 8, "double")]) {
			immutable l = lengthOf(type[2]);
			string[] types = [""];
			if(["byte", "short", "int", "long"].canFind(type[0])) types ~= "u";
			foreach(p ; types) {
				foreach(e ; ["BigEndian", "LittleEndian"]) {
					// write
					io ~= "\tpublic pure nothrow @safe void write" ~ e ~ capitalize(p ~ type[0]) ~ "(" ~ p ~ type[2] ~ " a) {\n";
					if(type[1] == 1) io ~= "\t\tthis._buffer ~= a;\n";
					else if(e == "BigEndian") io ~= "\t\tthis._buffer ~= nativeTo" ~ e ~ "!" ~ p ~ type[2] ~ "(a)" ~ (l == type[1] ? "" : "[$-" ~ to!string(type[1]) ~ "..$]") ~ ";\n";
					else io ~= "\t\tthis._buffer ~= nativeTo" ~ e ~ "!" ~ p ~ type[2] ~ "(a)" ~ (l == type[1] ? "" : "[0..$-" ~ to!string(l - type[1]) ~ "]") ~ ";\n";
					io ~= "\t}\n\n";
					// read
					io ~= "\tpublic pure nothrow @safe " ~ p ~ type[2] ~ " read" ~ e ~ capitalize(p ~ type[0]) ~ "() {\n";
					io ~= "\t\timmutable end = this._index + " ~ to!string(type[1]) ~ ";\n";
					io ~= "\t\tif(this._buffer.length < end) return " ~ type[2] ~ ".init;\n";
					io ~= "\t\tubyte[" ~ to!string(l) ~ "] bytes = ";
					if(type[1] == l) io ~= "this._buffer[this._index..end];\n";
					else if(e == "BigEndian") io ~= "new ubyte[" ~ to!string(l - type[1]) ~ "] ~ this._buffer[this._index..end];\n";
					else io ~= "this._buffer[this._index..end] ~ new ubyte[" ~ to!string(l - type[1]) ~ "];\n";
					io ~= "\t\tthis._index = end;\n";
					if(type[1] == 1) io ~= "\t\treturn " ~ (type[2] == "ubyte" ? "" : ("cast(" ~ type[2] ~ ")")) ~ "bytes[0];\n";
					else io ~= "\t\treturn " ~ toLower(e[0..1]) ~ e[1..$] ~ "ToNative!" ~ type[2] ~ "(bytes);\n";
					io ~= "\t}\n\n";
				}
			}
		}
		io ~= "}";
		write("util/buffer.d", io);

		// protocol
		foreach(string game, Protocols prts; data.protocols) {

			bool usesMetadata = false;
			
			@property string convertType(string type) {
				string ret, t = type;
				auto array = type.indexOf("[");
				if(array >= 0) {
					t = type[0..array];
				}
				auto vector = type.indexOf("<");
				if(vector >= 0) {
					string tt = convertType(type[0..vector]);
					t = "Tuple!(";
					foreach(char c ; type[vector+1..type.indexOf(">")]) {
						t ~= tt ~ `, "` ~ c ~ `", `;
					}
					ret = t[0..$-2] ~ ")";
				} else if(t in defaultAliases) {
					return convertType(defaultAliases[t] ~ (array >= 0 ? type[array..$] : ""));
				} else if(defaultTypes.canFind(t)) {
					ret = t;
				} else if(t == "metadata") {
					usesMetadata = true;
					ret = "Metadata";
				} else {
					auto a = t in prts.data.arrays;
					if(a) return convertType(a.base ~ "[]" ~ (array >= 0 ? type[array..$] : ""));
				}
				if(ret == "") ret = "sul.protocol." ~ game ~ ".types." ~ toPascalCase(t);
				return ret ~ (array >= 0 ? type[array..$] : "");
			}
			
			@property string convertName(string name) {
				if(name == "version") return "vers";
				else if(name == "body") return "body_";
				else if(name == "default") return "def";
				else return toCamelCase(name);
			}

			immutable id = convertType(prts.data.id);
			immutable arrayLength = convertType(prts.data.arrayLength);

			immutable defaultEndianness = toPascalCase(prts.data.endianness["*"]);

			string endiannessOf(string type, string over="") {
				if(over.length) return toPascalCase(over);
				auto e = type in prts.data.endianness;
				if(e) return toPascalCase(*e);
				else return defaultEndianness;
			}

			string createEncoding(string type, string name, string e="") {
				auto conv = type in prts.data.arrays ? prts.data.arrays[type].base ~ "[]" : type;
				auto lo = conv.lastIndexOf("[");
				if(lo > 0) {
					string ret = "";
					auto lc = conv.lastIndexOf("]");
					string nt = conv[0..lo];
					if(lo == lc - 1) {
						auto ca = type in prts.data.arrays;
						if(ca) {
							auto c = *ca;
							ret ~= createEncoding(c.length, "cast(" ~ convertType(c.length) ~ ")" ~ name ~ ".length", c.endianness);
						} else {
							ret ~= createEncoding(prts.data.arrayLength, "cast(" ~ arrayLength ~ ")" ~ name ~ ".length");
						}
						ret ~= " ";
					}
					if(nt == "ubyte") return ret ~= "writeBytes(" ~ name ~ ");";
					else return ret ~ "foreach(" ~ hash(name) ~ ";" ~ name ~ "){ " ~ createEncoding(nt, hash(name)) ~ " }";
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
				if(type.startsWith("var")) return "writeBytes(" ~ type ~ ".encode(" ~ name ~ "));";
				else if(type == "string") return createEncoding(prts.data.arrayLength, "cast(" ~ arrayLength ~")" ~ name ~ ".length") ~ " writeString(" ~ name ~ ");";
				else if(type == "uuid") return "writeBytes(" ~ name ~ ".data);";
				else if(type == "bytes") return "writeBytes(" ~ name ~ ");";
				else if(defaultTypes.canFind(type) || type == "triad") return "write" ~ endiannessOf(type, e) ~ capitalize(type) ~ "(" ~ name ~ ");";
				else return name ~ ".encode(bufferInstance);";
			}

			string createDecoding(string type, string name, string e="") {
				auto conv = type in prts.data.arrays ? prts.data.arrays[type].base ~ "[]" : type;
				auto lo = conv.lastIndexOf("[");
				if(lo > 0) {
					string ret = "";
					auto lc = conv.lastIndexOf("]");
					if(lo == lc - 1) {
						auto ca = type in prts.data.arrays;
						if(ca) {
							auto c = *ca;
							ret ~= createDecoding(c.length, name ~ ".length", c.endianness);
						} else {
							ret ~= createDecoding(prts.data.arrayLength, name ~ ".length");
						}
						ret ~= " ";
					}
					string nt = conv[0..lo];
					if(nt == "ubyte") return ret ~= "if(_buffer.length>=_index+" ~ name ~ ".length){ " ~ name ~ "=_buffer[_index.._index+" ~ name ~ ".length].dup; _index+=" ~ name ~ ".length; }";
					else return ret ~ "foreach(ref " ~ hash(name) ~ ";" ~ name ~ "){ " ~ createDecoding(nt, hash(name)) ~ " }";
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
				if(type.startsWith("var")) return name ~ "=" ~ type ~ ".decode(_buffer, &_index);";
				else if(type == "string") return createDecoding(prts.data.arrayLength, arrayLength ~ " " ~ hash(name)) ~ " " ~ name ~ "=readString(" ~ hash(name) ~ ");";
				else if(type == "uuid") return "if(_buffer.length>=_index+16){ ubyte[16] " ~ hash(name) ~ "=_buffer[_index.._index+16].dup; _index+=16; " ~ name ~ "=UUID(" ~ hash(name) ~ "); }";
				else if(type == "bytes") return name ~ "=_buffer[_index..$].dup; _index=_buffer.length;";
				else if(defaultTypes.canFind(type) || type == "triad") return name ~ "=read" ~ endiannessOf(type, e) ~ capitalize(type) ~ "();";
				else if(type == "metadata") return name ~ "=Metadata.decode(bufferInstance);";
				else return name ~ ".decode(bufferInstance);";
			}
			
			void createEncodings(string space, ref string data, Field[] fields) {
				foreach(i, field; fields) {
					bool c = field.condition.length != 0;
					data ~= space ~ (c ? "if(" ~ toCamelCase(field.condition) ~ "){ " : "") ~ createEncoding(field.type, field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.endianness) ~ (c ? " }" : "") ~ "\n";
				}
			}
			
			void createDecodings(string space, ref string data, Field[] fields) {
				foreach(i, field; fields) {
					bool c = field.condition.length != 0;
					data ~= space ~ (c ? "if(" ~ toCamelCase(field.condition) ~ "){ " : "") ~ createDecoding(field.type, field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.endianness) ~ (c ? " }" : "") ~ "\n";
				}
			}

			void writeFields(ref string data, string space, Field[] fields, bool isClass) {
				// constants
				foreach(field ; fields) {
					if(field.constants.length) {
						data ~= space ~ "// " ~ field.name.replace("_", " ") ~ "\n";
						foreach(constant ; field.constants) {
							data ~= space ~ "public enum " ~ convertType(field.type) ~ " " ~ toUpper(constant.name) ~ " = " ~ (field.type == "string" ? JSONValue(constant.value).toString() : constant.value) ~ ";\n";
						}
						data ~= "\n";
					}
				}
				// fields' names
				string[] fn;
				foreach(i, field; fields) fn ~= field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
				data ~= space ~ "public enum string[] FIELDS = " ~ to!string(fn) ~ ";\n\n";
				// fields
				foreach(i, field; fields) {
					data ~= space ~ "public " ~ convertType(field.type) ~ " " ~ (field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name)) ~ (field.def.length ? " = " ~ constOf(field.def) : "") ~ ";\n";
					if(i == fields.length - 1) data ~= "\n";
				}
				// constructors
				if(isClass && fields.length) {
					data ~= space ~ "public pure nothrow @safe @nogc this() {}\n\n";
					string[] args;
					foreach(i, field; fields) {
						immutable type = convertType(field.type);
						immutable p = type.canFind('[');
						args ~= type ~ " " ~ (field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name)) ~ (i ? "=" ~ (field.def.length ? constOf(field.def) : (p ? "(" : "") ~ type ~ (p ? ")" : "") ~ ".init") : "");
					}
					data ~= space ~ "public pure nothrow @safe @nogc this(" ~ args.join(", ") ~ ") {\n";
					foreach(i, field; fields) {
						immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
						data ~= space ~ "\tthis." ~ name ~ " = " ~ name ~ ";\n";
					}
					data ~= space ~ "}\n\n";
				}
			}

			void createToString(ref string data, string space, string name, Field[] fields, bool over=true) {
				data ~= space ~ "public " ~ (over ? "override ": "") ~ "string toString() {\n";
				string[] f;
				foreach(i, field; fields) {
					immutable n = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
					f ~= n ~ ": \" ~ std.conv.to!string(this." ~ n ~ ")";
				}
				data ~= space ~ "\treturn \"" ~ name ~ "(" ~ (f.length ? (f.join(" ~ \", ") ~ " ~ \"") : "") ~ ")\";\n";
				data ~= space ~ "}\n\n";
			}

			// types
			string t = "module sul.protocol." ~ game ~ ".types;\n\n";
			t ~= "import std.bitmanip : write, peek;\nstatic import std.conv;\nimport std.system : Endian;\nimport std.typecons : Tuple;\nimport std.uuid : UUID;\n\nimport sul.utils.buffer;\nimport sul.utils.var;\n\n";
			t ~= "static if(__traits(compiles, { import sul.metadata." ~ game ~ "; })) import sul.metadata." ~ game ~ ";\n\n";
			foreach(type ; prts.data.types) {
				immutable has_length = type.length.length != 0;
				t ~= "struct " ~ toPascalCase(type.name) ~ " {\n\n";
				writeFields(t, "\t", type.fields, false);
				// encoding
				t ~= "\tpublic pure nothrow @safe void encode(Buffer " ~ (has_length ? "o_" : "") ~ "buffer) {\n";
				if(has_length) t ~= "\t\tBuffer buffer = new Buffer();\n";
				t ~= "\t\twith(buffer) {\n";
				createEncodings("\t\t\t", t, type.fields);
				t ~= "\t\t}\n";
				if(type.length.length) {
					t ~= "\t\twith(o_buffer){ " ~ createEncoding(type.length, "cast(" ~ convertType(type.length) ~ ")buffer._buffer.length") ~ " }\n";
					t ~= "\t\to_buffer.writeBytes(buffer._buffer);\n";
				}
				t ~= "\t}\n\n";
				// decoding
				t ~= "\tpublic pure nothrow @safe void decode(Buffer " ~ (has_length ? "o_" : "") ~ "buffer) {\n";
				if(has_length) {
					t ~= "\t\tBuffer buffer = new Buffer();\n";
					t ~= "\t\twith(o_buffer) {\n";
					t ~= "\t\t\t" ~ createDecoding(type.length, "immutable _length") ~ "\n";
					t ~= "\t\t\tbuffer._buffer = readBytes(_length);\n";
					t ~= "\t\t}\n";
				}
				t ~= "\t\twith(buffer) {\n";
				createDecodings("\t\t\t", t, type.fields);
				t ~= "\t\t}\n\t}\n\n";
				createToString(t, "\t", toPascalCase(type.name), type.fields, false);
				t ~= "}\n\n";
			}
			write("../src/d/sul/protocol/" ~ game ~ "/types.d", t, "protocol/" ~ game);

			// sections
			string s;
			s ~= "module sul.protocol." ~ game ~ ";\n\npublic import sul.protocol." ~ game ~ ".types;\n\n";
			foreach(section ; prts.data.sections) {
				s ~= "public import sul.protocol." ~ game ~ "." ~ section.name ~ ";\n";
				string data;
				data ~= "module sul.protocol." ~ game ~ "." ~ section.name ~ ";\n\n";
				data ~= "import std.bitmanip : write, peek;\nstatic import std.conv;\nimport std.system : Endian;\nimport std.typetuple : TypeTuple;\nimport std.typecons : Tuple;\nimport std.uuid : UUID;\n\n";
				data ~= "import sul.utils.buffer;\nimport sul.utils.var;\n\nstatic import sul.protocol." ~ game ~ ".types;\n\n";
				data ~= "static if(__traits(compiles, { import sul.metadata." ~ game ~ "; })) import sul.metadata." ~ game ~ ";\n\n";
				string[] names;
				foreach(packet ; section.packets) names ~= toPascalCase(packet.name);
				data ~= "alias Packets = TypeTuple!(" ~ names.join(", ") ~ ");\n\n";
				foreach(packet ; section.packets) {
					data ~= "class " ~ toPascalCase(packet.name) ~ " : Buffer {\n\n";
					data ~= "\tpublic enum " ~ id ~ " ID = " ~ to!string(packet.id) ~ ";\n\n";
					data ~= "\tpublic enum bool CLIENTBOUND = " ~ to!string(packet.clientbound) ~ ";\n";
					data ~= "\tpublic enum bool SERVERBOUND = " ~ to!string(packet.serverbound) ~ ";\n\n";
					writeFields(data, "\t", packet.fields, true);
					// encoding
					data ~= "\tpublic pure nothrow @safe ubyte[] encode(bool writeId=true)() {\n";
					data ~= "\t\t_buffer.length = 0;\n";
					data ~= "\t\tstatic if(writeId){ " ~ createEncoding(prts.data.id, "ID") ~ " }\n";
					createEncodings("\t\t", data, packet.fields);
					data ~= "\t\treturn _buffer;\n";
					data ~= "\t}\n\n";
					// decoding
					data ~= "\tpublic pure nothrow @safe void decode(bool readId=true)() {\n";
					data ~= "\t\tstatic if(readId){ " ~ id ~ " _id; " ~ createDecoding(prts.data.id, "_id") ~ " }\n";
					createDecodings("\t\t", data, packet.fields);
					data ~= "\t}\n\n";
					// static decoding
					data ~= "\tpublic static pure nothrow @safe " ~ toPascalCase(packet.name) ~ " fromBuffer(bool readId=true)(ubyte[] buffer) {\n";
					data ~= "\t\t" ~ toPascalCase(packet.name) ~ " ret = new " ~ toPascalCase(packet.name) ~ "();\n";
					data ~= "\t\tret._buffer = buffer;\n";
					data ~= "\t\tret.decode!readId();\n";
					data ~= "\t\treturn ret;\n";
					data ~= "\t}\n\n";
					createToString(data, "\t", toPascalCase(packet.name), packet.fields);
					// variants
					if(packet.variants.length) {
						data ~= "\talias _encode = encode;\n\n";
						data ~= "\tenum string variantField = \"" ~ convertName(packet.variantField) ~ "\";\n\n";
						string[] v;
						foreach(variant ; packet.variants) {
							v ~= toPascalCase(variant.name);
						}
						data ~= "\talias Variants = TypeTuple!(" ~ v.join(", ") ~ ");\n\n";
						foreach(variant ; packet.variants) {
							data ~= "\tpublic class " ~ toPascalCase(variant.name) ~ " {\n\n";
							data ~= "\t\tpublic enum typeof(" ~ convertName(packet.variantField) ~ ") " ~ toUpper(packet.variantField) ~ " = " ~ variant.value ~ ";\n\n";
							writeFields(data, "\t\t", variant.fields, true);
							// encode
							data ~= "\t\tpublic pure nothrow @safe ubyte[] encode(bool writeId=true)() {\n";
							data ~= "\t\t\t" ~ convertName(packet.variantField) ~ " = " ~ variant.value ~ ";\n\t\t\t_encode!writeId();\n";
							createEncodings("\t\t\t", data, variant.fields);
							data ~= "\t\t\treturn _buffer;\n\t\t}\n\n";
							// decode
							data ~= "\t\tpublic pure nothrow @safe void decode() {\n";
							createDecodings("\t\t\t", data, variant.fields);
							data ~= "\t\t}\n\n";
							createToString(data, "\t\t", toPascalCase(packet.name) ~ "." ~ toPascalCase(variant.name), variant.fields);
							data ~= "\t}\n\n";
						}
					}
					data ~= "}\n\n";
				}
				write("protocol/" ~ game ~ "/" ~ section.name ~ ".d", data, "protocol/" ~ game);
			}
			write("protocol/" ~ game ~ "/package.d", s, "protocol/" ~ game);

			// metadata
			auto m = game in metadatas;
			if(m) {
				string data = "module sul.metadata." ~ game ~ ";\n\n";
				data ~= "import std.typecons : Tuple, tuple;\n\n";
				data ~= "import sul.utils.buffer : Buffer;\nimport sul.utils.metadataflags;\nimport sul.utils.var;\n\n";
				data ~= "static import sul.protocol." ~ game ~ ".types;\n\n";
				data ~= "alias Changed(T) = Tuple!(T, \"value\", bool, \"changed\");\n\n";
				// types
				data ~= "enum MetadataType : " ~ convertType(m.data.type) ~ " {\n\n";
				string[string] ctable, etable;
				ubyte[string] idtable;
				foreach(type ; m.data.types) {
					ctable[type.name] = type.type;
					etable[type.name] = type.endianness;
					idtable[type.name] = type.id;
					data ~= "\t" ~ toUpper(type.name) ~ " = " ~ type.id.to!string ~ ",\n";
				}
				data ~= "}\n\n";
				// metadata
				data ~= "class Metadata {\n\n";
				foreach(d ; m.data.data) {
					immutable tp = convertType(ctable[d.type]);
					if(d.flags.length) {
						data ~= "\tpublic enum " ~ toUpper(d.name) ~ " : size_t {\n";
						foreach(flag ; d.flags) {
							data ~= "\t\t" ~ toUpper(flag.name) ~ " = " ~ flag.bit.to!string ~ ",\n";
						}
						data ~= "\t}\n";
					} else {
						data ~= "\tpublic enum " ~ convertType(m.data.id) ~ " " ~ toUpper(d.name) ~ " = " ~ d.id.to!string ~ ";\n";
					}
				}
				data ~= "\n";
				data ~= "\tpublic DecodedMetadata[] decoded;\n\n";
				data ~= "\tprivate bool _cached = false;\n";
				data ~= "\tprivate ubyte[] _cache;\n\n";
				data ~= "\tprivate void delegate(Buffer) pure nothrow @safe[] _changed;\n\n";
				foreach(d ; m.data.data) {
					immutable tp = convertType(ctable[d.type]);
					immutable ctp = d.flags.length ? "MetadataFlags!(" ~ tp ~ ")" : tp;
					if(d.required) data ~= "\tprivate " ~ ctp ~ " _" ~ convertName(d.name) ~ (d.def.length ? " = cast(" ~ ctp ~ ")" ~ d.def : "") ~ ";\n";
					else data ~= "\tprivate Changed!(" ~ ctp ~ ") _" ~ convertName(d.name) ~ (d.def.length ? " = tuple(cast(" ~ ctp ~ ")" ~ d.def ~ ", false)" : "") ~ ";\n";
				}
				data ~= "\n";
				data ~= "\tpublic pure nothrow @safe this() {\n";
				data ~= "\t\tthis.reset();\n";
				data ~= "\t}\n\n";
				data ~= "\tpublic pure nothrow @safe void reset() {\n";
				data ~= "\t\tthis._changed = [\n";
				foreach(d ; m.data.data) {
					if(d.required) {
						immutable name = convertName(d.name);
						immutable tp = convertType(ctable[d.type]);
						data ~= "\t\t\t&this.encode" ~ name[0..1].toUpper ~ name[1..$] ~ ",\n";
					}
				}
				data ~= "\t\t];\n";
				data ~= "\t}\n\n";
				/*data ~= "\tprivate pure nothrow @safe void setImpl(void delegate(Buffer) pure nothrow @safe del) {\n";
				data ~= "\t\tthis._cached = false;\n";
				data ~= "\t\tthis._changed ~= del;\n";
				data ~= "\t}\n\n";
				// can be used for custom metadata
				string[] defined;
				foreach(d ; m.data.types) {
					immutable type = convertType(d.type);
					if(!defined.canFind(type)) {
						defined ~= type;
						data ~= "\tpublic void opIndexAssign(" ~ convertType(m.data.id) ~ " id, " ~ convertType(m.data.type) ~ " type, " ~ type ~ " value) {\n";
						data ~= "\t\tthis.setImpl(delegate(Buffer buffer){\n";
						data ~= "\t\t\twith(buffer) {\n";
						data ~= "\t\t\t\t" ~ createEncoding(m.data.id, "id") ~ "\n";
						data ~= "\t\t\t\t" ~ createEncoding(m.data.type, "type") ~ "\n";
						data ~= "\t\t\t\t" ~ createEncoding(d.type, "value") ~ "\n";
						data ~= "\t\t\t}\n";
						data ~= "\t\t});\n";
						data ~= "\t}\n\n";
					}
				}*/
				foreach(d ; m.data.data) {
					immutable name = convertName(d.name);
					immutable tp = convertType(ctable[d.type]);
					immutable value = "_" ~ name ~ (d.required ? "" : ".value");
					// get
					data ~= "\tpublic pure nothrow @property @safe @nogc " ~ tp ~ " " ~ name ~ "() {\n\t\treturn " ~ value ~ ";\n\t}\n\n";
					// set
					data ~= "\tpublic pure nothrow @property @safe " ~ tp ~ " " ~ name ~ "(" ~ tp ~ " value) {\n";
					data ~= "\t\tthis._cached = false;\n";
					data ~= "\t\tthis." ~ value ~ " = value;\n";
					if(!d.required) {
						data ~= "\t\tif(!this._" ~ name ~ ".changed) {\n";
						data ~= "\t\t\tthis._" ~ name ~ ".changed = true;\n";
						data ~= "\t\t\tthis._changed ~= &this.encode" ~ name[0..1].toUpper ~ name[1..$] ~ ";\n";
						data ~= "\t\t}\n";
					}
					data ~= "\t\treturn value;\n";
					data ~= "\t}\n\n";
					// encode
					data ~= "\tpublic pure nothrow @safe encode" ~ name[0..1].toUpper ~ name[1..$] ~ "(Buffer buffer) {\n";
					data ~= "\t\twith(buffer) {\n";
					data ~= "\t\t\t" ~ createEncoding(m.data.id, d.id.to!string) ~ "\n";
					data ~= "\t\t\t" ~ createEncoding(m.data.type, idtable[d.type].to!string) ~ "\n";
					data ~= "\t\t\t" ~ createEncoding(ctable[d.type], "this." ~ value, etable[d.type]) ~ "\n";
					data ~= "\t\t}\n";
					data ~= "\t}\n\n";
					foreach(flag ; d.flags) {
						immutable fname = convertName(flag.name);
						data ~= "\tpublic pure nothrow @property @safe bool " ~ fname ~ "() {\n";
						//data ~= "\t\treturn (" ~ value ~ " >>> " ~ to!string(flag.bit) ~ ") & 1;\n";
						data ~= "\t\treturn " ~ value ~ "._" ~ to!string(flag.bit) ~ ";\n";
						data ~= "\t}\n\n";
						data ~= "\tpublic pure nothrow @property @safe bool " ~ fname ~ "(bool value) {\n";
						//data ~= "\t\tif(value) " ~ name ~ " = cast(" ~ tp ~ ")(" ~ value ~ " | (1Lu << " ~ to!string(flag.bit) ~ "));\n";
						//data ~= "\t\telse " ~ name ~ " = cast(" ~ tp ~ ")(" ~ value ~ " & (ulong.max ^ (1Lu << " ~ to!string(flag.bit) ~ ")));\n";
						data ~= "\t\t" ~ value ~ "._" ~ to!string(flag.bit) ~ " = value;\n";
						data ~= "\t\treturn value;\n";
						data ~= "\t}\n\n";
					}
				}
				// encode function
				data ~= "\tpublic pure nothrow @safe encode(Buffer buffer) {\n";
				data ~= "\t\twith(buffer) {\n";
				data ~= "\t\t\tif(this._cached) {\n";
				data ~= "\t\t\t\tbuffer.writeBytes(this._cache);\n";
				data ~= "\t\t\t} else {\n";
				data ~= "\t\t\t\timmutable start = buffer._buffer.length;\n";
				if(m.data.prefix.length) data ~= "\t\t\t\t" ~ createEncoding("ubyte", m.data.prefix) ~ "\n";
				if(m.data.length.length) data ~= "\t\t\t\t" ~ createEncoding(m.data.length, "cast(" ~ convertType(m.data.length) ~ ")this._changed.length") ~ "\n";
				data ~= "\t\t\t\tforeach(del ; this._changed) del(buffer);\n";
				if(m.data.suffix.length) data ~= "\t\t\t\t" ~ createEncoding("ubyte", m.data.suffix) ~ "\n";
				data ~= "\t\t\t\tthis._cached = true;\n";
				data ~= "\t\t\t\tthis._cache = buffer._buffer[start..$];\n";
				data ~= "\t\t\t}\n";
				data ~= "\t\t}\n";
				data ~= "\t}\n\n";
				// decode function
				data ~= "\tpublic static pure nothrow @safe Metadata decode(Buffer buffer) {\n";
				data ~= "\t\tauto metadata = new Metadata();\n";
				data ~= "\t\twith(buffer) {\n";
				data ~= "\t\t\t" ~ convertType(m.data.id) ~ " id;\n";
				if(m.data.length.length) {
					data ~= "\t\t\t" ~ createDecoding(m.data.length, "size_t length") ~ "\n";
					data ~= "\t\t\twhile(length-- > 0) {\n";
					data ~= "\t\t\t\t" ~ createDecoding(m.data.id, "id") ~ "\n";
				} else if(m.data.suffix.length) {
					data ~= "\t\t\twhile(_index < _buffer.length && (" ~ createDecoding(m.data.id, "id")[0..$-1] ~ ") != " ~ m.data.suffix ~ ") {\n";
				}
				data ~= "\t\t\t\tswitch(" ~ createDecoding(m.data.type, "")[1..$-1] ~ ") {\n";
				foreach(type ; m.data.types) {
					data ~= "\t\t\t\t\tcase " ~ type.id.to!string ~ ":\n";
					data ~= "\t\t\t\t\t\t" ~ convertType(type.type) ~ " _" ~ type.id.to!string ~ ";\n";
					data ~= "\t\t\t\t\t\t" ~ createDecoding(type.type, "_" ~ type.id.to!string, type.endianness) ~ "\n";
					data ~= "\t\t\t\t\t\tmetadata.decoded ~= DecodedMetadata.from" ~ toPascalCase(type.name) ~ "(id, _" ~ type.id.to!string ~ ");\n";
					data ~= "\t\t\t\t\t\tbreak;\n";
				}
				data ~= "\t\t\t\t\tdefault:\n";
				data ~= "\t\t\t\t\t\tbreak;\n";
				data ~= "\t\t\t\t}\n";
				data ~= "\t\t\t}\n";
				data ~= "\t\t}\n";
				data ~= "\t\treturn metadata;\n";
				data ~= "\t}\n\n";
				data ~= "}\n\n";
				// decoded data
				string convertDecoded(string name) {
					if(["bool", "byte", "ubyte", "short", "uhsort", "int", "uint", "long", "ulong", "float", "double", "string"].canFind(name)) {
						return name ~ "_";
					} else {
						return name.replace("<", "_").replace(">", "");
					}
				}
				data ~= "class DecodedMetadata {\n\n";
				data ~= "\tpublic immutable " ~ convertType(m.data.id) ~ " id;\n";
				data ~= "\tpublic immutable " ~ convertType(m.data.type) ~ " type;\n\n";
				data ~= "\tunion {\n";
				foreach(type ; m.data.types) {
					data ~= "\t\t" ~ convertType(type.type) ~ " " ~ convertDecoded(type.name) ~ ";\n";
				}
				data ~= "\t}\n\n";
				data ~= "\tprivate pure nothrow @safe @nogc this(" ~ convertType(m.data.id) ~ " id, " ~ convertType(m.data.type) ~ " type) {\n";
				data ~= "\t\tthis.id = id;\n";
				data ~= "\t\tthis.type = type;\n";
				data ~= "\t}\n\n";
				// constructors
				foreach(type ; m.data.types) {
					data ~= "\tpublic static pure nothrow @trusted DecodedMetadata from" ~ toPascalCase(type.name) ~ "(" ~ convertType(m.data.id) ~ " id, " ~ convertType(type.type) ~ " value) {\n";
					data ~= "\t\tauto ret = new DecodedMetadata(id, " ~ type.id.to!string ~ ");\n";
					data ~= "\t\tret." ~ convertDecoded(type.name) ~ " = value;\n";
					data ~= "\t\treturn ret;\n";
					data ~= "\t}\n\n";
				}
				data ~= "}";
				write("../src/d/sul/metadata/" ~ game ~ ".d", data, "metadata/" ~ game);
			} else if(usesMetadata) {
				// dummy
				string data = "module sul.metadata." ~ game ~ ";\n\nimport sul.utils.buffer : Buffer;\n\n";
				data ~= "class Metadata {\n\n";
				data ~= "\tpublic pure nothrow @safe @nogc ubyte[] encode() {\n\t\treturn (ubyte[]).init;\n\t}\n\n";
				data ~= "\tpublic static pure nothrow @safe Metadata decode(Buffer buffer) {\n\t\treturn new Metadata();\n\t}\n\n";
				data ~= "}";
				write("../src/d/sul/metadata/" ~ game ~ ".d", data);
			}

		}
	}

}
