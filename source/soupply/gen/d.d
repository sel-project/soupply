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
import soupply.util;

class DGenerator : Generator {

	static this() {
		Generator.register!DGenerator("d", "src/" ~ SOFTWARE, ["/*", " *", " */"]);
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

		size_t lengthOf(string type) {
			switch(type) {
				case "bool": return 1;
				case "byte": return 1;
				case "short": return 2;
				case "int": return 4;
				case "long": return 8;
				case "float": return 4;
				case "double": return 8;
				default: return 0;
			}
		}

		// io utils
		auto io = new DSource("util/buffer");
		io.line("module " ~ SOFTWARE ~ ".util.buffer;").nl.line("import std.bitmanip;").line("import std.system : Endian;").nl;
		io.line("class Buffer").ob.nl;
		io.line("public ubyte[] _buffer;");
		io.line("public size_t _index;").nl;
		io.line("public pure nothrow @property @safe @nogc Buffer bufferInstance()").ob.line("return this;").cb.nl;
		io.line("public pure nothrow @safe void writeBytes(ubyte[] bytes)").ob;
		io.line("this._buffer ~= bytes;").cb.nl;
		io.line("public pure nothrow @trusted void writeString(string str)").ob.line("this.writeBytes(cast(ubyte[])str);").cb.nl;
		io.line("public pure nothrow @safe ubyte[] readBytes(size_t length)").ob;
		io.line("immutable end = this._index + length;");
		io.line("if (this._buffer.length < end) return (ubyte[]).init;");
		io.line("auto ret = this._buffer[this._index..end].dup;");
		io.line("this._index = end;");
		io.line("return ret;").cb.nl;
		io.line("public pure nothrow @trusted string readString(size_t length)").ob.line("return cast(string) this.readBytes(length);").cb.nl;
		foreach(type ; [tuple("bool", 1, "bool"), tuple("byte", 1, "byte"), tuple("short", 2, "short"), tuple("triad", 3, "int"), tuple("int", 4, "int"), tuple("long", 8, "long"), tuple("float", 4, "float"), tuple("double", 8, "double")]) {
			immutable l = lengthOf(type[2]);
			string[] types = [""];
			if(["byte", "short", "int", "long"].canFind(type[0])) types ~= "u";
			foreach(p ; types) {
				foreach(e ; ["BigEndian", "LittleEndian"]) {
					// write
					io.line("public pure nothrow @safe void write" ~ e ~ capitalize(p ~ type[0]) ~ "(" ~ p ~ type[2] ~ " a)").ob;
					if(type[1] == 1) io.line("this._buffer ~= a;");
					else if(e == "BigEndian") io.line("this._buffer ~= nativeTo" ~ e ~ "!" ~ p ~ type[2] ~ "(a)" ~ (l == type[1] ? "" : "[$-" ~ to!string(type[1]) ~ "..$]") ~ ";");
					else io.line("this._buffer ~= nativeTo" ~ e ~ "!" ~ p ~ type[2] ~ "(a)" ~ (l == type[1] ? "" : "[0..$-" ~ to!string(l - type[1]) ~ "]") ~ ";");
					io.cb.nl;
					// read
					io.line("public pure nothrow @safe " ~ p ~ type[2] ~ " read" ~ e ~ capitalize(p ~ type[0]) ~ "()").ob;
					io.line("immutable end = this._index + " ~ to!string(type[1]) ~ ";");
					io.line("if (this._buffer.length < end) return " ~ type[2] ~ ".init;");
					io.inline("ubyte[" ~ to!string(l) ~ "] bytes = ");
					if(type[1] == l) io.put("this._buffer[this._index..end];");
					else if(e == "BigEndian") io.put("new ubyte[" ~ to!string(l - type[1]) ~ "] ~ this._buffer[this._index..end];");
					else io.put("this._buffer[this._index..end] ~ new ubyte[" ~ to!string(l - type[1]) ~ "];");
					io.nl.line("this._index = end;");
					if(type[1] == 1) io.line("return " ~ (type[2] == "ubyte" ? "" : ("cast(" ~ type[2] ~ ") ")) ~ "bytes[0];");
					else io.line("return " ~ toLower(e[0..1]) ~ e[1..$] ~ "ToNative!" ~ type[2] ~ "(bytes);");
					io.cb.nl;
				}
			}
		}
		io.cb;
		write(io);

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
					/*string tt = convertType(type[0..vector]);
					t = "Tuple!(";
					foreach(char c ; type[vector+1..type.indexOf(">")]) {
						t ~= tt ~ `, "` ~ c ~ `", `;
					}
					ret = t[0..$-2] ~ ")";*/
					ret = "Tuple!(" ~ convertType(type[0..vector]) ~ ",\"" ~ type[vector+1..type.indexOf(">")] ~ "\")";
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
				if(ret == "") ret = "soupply.protocol." ~ game ~ ".types." ~ toPascalCase(t);
				return ret ~ (array >= 0 ? type[array..$] : "");
			}
			
			@property string convertName(string name) {
				if(name == "version") return "vers";
				//else if(name == "body") return "body_";
				else if(name == "default") return "default_";
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

			void createEncoding(Source source, string type, string name, string e="") {
				auto conv = type in prts.data.arrays ? prts.data.arrays[type].base ~ "[]" : type;
				auto lo = conv.lastIndexOf("[");
				if(lo > 0) {
					// array
					string ret = "";
					auto lc = conv.lastIndexOf("]");
					string nt = conv[0..lo];
					if(lo == lc - 1) {
						auto ca = type in prts.data.arrays;
						if(ca) {
							auto c = *ca;
							createEncoding(source, c.length, "cast(" ~ convertType(c.length) ~ ") " ~ name ~ ".length", c.endianness);
						} else {
							createEncoding(source, prts.data.arrayLength, "cast(" ~ arrayLength ~ ") " ~ name ~ ".length");
						}
						ret ~= " ";
					}
					if(nt == "ubyte") source.line("writeBytes(" ~ name ~ ");");
					else {
						// complex array that cannot be encoded with a single function
						source.line("foreach (" ~ hash(name) ~ " ; " ~ name ~ ")").ob;
						createEncoding(source, nt, hash(name));
						source.cb;
					}
				} else {
					auto ts = conv.lastIndexOf("<");
					if(ts > 0) {
						// tuple
						//TODO this can be optimised by calling an `encode` method on the tuple or encoding it as it was an array
						auto te = conv.lastIndexOf(">");
						string nt = conv[0..ts];
						foreach(i ; conv[ts+1..te]) {
							createEncoding(source, nt, name ~ "." ~ i);
						}
					} else {
						type = conv;
						if(type.startsWith("var")) source.line("writeBytes(" ~ type ~ ".encode(" ~ name ~ "));");
						else if(type == "string"){ createEncoding(source, prts.data.arrayLength, "cast(" ~ arrayLength ~")" ~ name ~ ".length"); source.line("writeString(" ~ name ~ ");"); }
						else if(type == "uuid") source.line("writeBytes(" ~ name ~ ".data);");
						else if(type == "bytes") source.line("writeBytes(" ~ name ~ ");");
						else if(defaultTypes.canFind(type) || type == "triad") source.line("write" ~ endiannessOf(type, e) ~ capitalize(type) ~ "(" ~ name ~ ");");
						else source.line(name ~ ".encode(bufferInstance);");
					}
				}
			}

			void createDecoding(Source source, string type, string name, string e="") {
				auto conv = type in prts.data.arrays ? prts.data.arrays[type].base ~ "[]" : type;
				auto lo = conv.lastIndexOf("[");
				if(lo > 0) {
					string ret = "";
					auto lc = conv.lastIndexOf("]");
					if(lo == lc - 1) {
						auto ca = type in prts.data.arrays;
						if(ca) {
							auto c = *ca;
							createDecoding(source, c.length, name ~ ".length", c.endianness);
						} else {
							createDecoding(source, prts.data.arrayLength, name ~ ".length");
						}
					}
					string nt = conv[0..lo];
					if(nt == "ubyte") {
						source.line("if (_buffer.length >= _index+" ~ name ~ ".length)").ob;
						source.line(name ~ " = _buffer[_index .. _index+" ~ name ~ ".length].dup;");
						source.line("_index += " ~ name ~ ".length;").cb;
					} else {
						source.line("foreach (ref " ~ hash(name) ~ " ; " ~ name ~ ")").ob;
						createDecoding(source, nt, hash(name));
						source.cb;
					}
				} else {
					auto ts = conv.lastIndexOf("<");
					if(ts > 0) {
						//TODO optimise encoding it as array
						auto te = conv.lastIndexOf(">");
						string nt = conv[0..ts];
						foreach(i ; conv[ts+1..te]) {
							createDecoding(source, nt, name ~ "." ~ i);
						}
					} else {
						//TODO optmise uuid and bytes moving it to buffer
						type = conv;
						if(type.startsWith("var")) source.line(name ~ " = " ~ type ~ ".decode(_buffer, &_index);");
						else if(type == "string"){ createDecoding(source, prts.data.arrayLength, arrayLength ~ " " ~ hash(name)); source.line(name ~ " = readString(" ~ hash(name) ~ ");"); }
						else if(type == "uuid") source.line("if (_buffer.length >= _index + 16)").ob.line("ubyte[16] " ~ hash(name) ~ " = _buffer[_index .. _index+16].dup;").line("_index += 16;").line(name ~ " = UUID(" ~ hash(name) ~ ");").cb;
						else if(type == "bytes") source.line(name ~ " = _buffer[_index .. $].dup;").line("_index = _buffer.length;");
						else if(defaultTypes.canFind(type) || type == "triad") source.line(name ~ " = read" ~ endiannessOf(type, e) ~ capitalize(type) ~ "();");
						else if(type == "metadata") source.line(name ~ " = Metadata.decode(bufferInstance);");
						else source.line(name ~ ".decode(bufferInstance);");
					}
				}
			}
			
			void createEncodings(Source source, Protocol.Field[] fields) {
				foreach(i, field; fields) {
					bool c = field.condition.length != 0;
					if(c) source.line("if (" ~ toCamelCase(field.condition) ~ ")").ob;
					createEncoding(source, field.type, field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.endianness);
					if(c) source.cb;
				}
			}
			
			void createDecodings(Source source, Protocol.Field[] fields) {
				foreach(i, field; fields) {
					bool c = field.condition.length != 0;
					if(c) source.line("if(" ~ toCamelCase(field.condition) ~ ")").ob;
					createDecoding(source, field.type, field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.endianness);
					if(c) source.cb;
				}
			}

			void writeFields(Source source, Protocol.Field[] fields, bool isClass) {
				// constants
				foreach(field ; fields) {
					if(field.constants.length) {
						source.line("// " ~ field.name.replace("_", " "));
						foreach(constant ; field.constants) {
							source.line("public enum " ~ convertType(field.type) ~ " " ~ toUpper(constant.name) ~ " = " ~ (field.type == "string" ? JSONValue(constant.value).toString() : constant.value) ~ ";");
						}
						source.nl;
					}
				}
				// fields' names
				string[] fn;
				foreach(i, field; fields) fn ~= field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
				source.line("public enum string[] FIELDS = " ~ to!string(fn) ~ ";").nl;
				// fields
				foreach(i, field; fields) {
					source.line("public " ~ convertType(field.type) ~ " " ~ (field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name)) ~ (field.default_.length ? " = " ~ constOf(field.default_) : "") ~ ";");
					if(i == fields.length - 1) source.nl;
				}
				// constructors
				if(isClass && fields.length) {
					source.line("public pure nothrow @safe @nogc this() {}").nl;
					string[] args;
					foreach(i, field; fields) {
						immutable type = convertType(field.type);
						immutable p = type.canFind('[');
						args ~= type ~ " " ~ (field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name)) ~ (i ? "=" ~ (field.default_.length ? constOf(field.default_) : (p ? "(" : "") ~ type ~ (p ? ")" : "") ~ ".init") : "");
					}
					source.line("public pure nothrow @safe @nogc this(" ~ args.join(", ") ~ ")").ob;
					foreach(i, field; fields) {
						immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
						source.line("this." ~ name ~ " = " ~ name ~ ";");
					}
					source.cb.nl;
				}
			}

			void createToString(Source source, string name, Protocol.Field[] fields, bool override_=true) {
				source.line("public " ~ (override_ ? "override ": "") ~ "string toString()").ob;
				string[] f;
				foreach(i, field; fields) {
					immutable n = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
					f ~= n ~ ": \" ~ std.conv.to!string(this." ~ n ~ ")";
				}
				source.line("return \"" ~ name ~ "(" ~ (f.length ? (f.join(" ~ \", ") ~ " ~ \"") : "") ~ ")\";");
				source.cb.nl;
			}

			// types
			auto t = new DSource("protocol/" ~ game ~ "/types");
			t.line("module soupply.protocol." ~ game ~ ".types;").nl;
			t.line("import std.bitmanip : write, peek;").line("static import std.conv;").line("import std.system : Endian;").line("import std.uuid : UUID;").nl;
			t.line("import soupply.util.buffer;").line("import soupply.util.tuple : Tuple;").line("import soupply.util.var;").nl;
			t.line("static if (__traits(compiles, { import soupply.metadata." ~ game ~ "; })) import soupply.metadata." ~ game ~ ";").nl;
			foreach(type ; prts.data.types) {
				immutable has_length = type.length.length != 0;
				// declaration
				t.line("struct " ~ toPascalCase(type.name)).ob.nl;
				writeFields(t, type.fields, false);
				// encoding
				t.line("public pure nothrow @safe void encode(Buffer " ~ (has_length ? "o_" : "") ~ "buffer)").ob;
				if(has_length) t.line("Buffer buffer = new Buffer();");
				t.line("with(buffer)").ob;
				createEncodings(t, type.fields);
				t.cb;
				if(type.length.length) {
					t.line("with(o_buffer)").ob;
					createEncoding(t, type.length, "cast(" ~ convertType(type.length) ~ ") buffer._buffer.length");
					t.cb;
					t.line("o_buffer.writeBytes(buffer._buffer);");
				}
				t.cb.nl;
				// decoding
				t.line("public pure nothrow @safe void decode(Buffer " ~ (has_length ? "o_" : "") ~ "buffer)").ob;
				if(has_length) {
					t.line("Buffer buffer = new Buffer();");
					t.line("with(o_buffer)").ob;
					createDecoding(t, type.length, "immutable _length");
					t.line("buffer._buffer = readBytes(_length);");
					t.cb.nl;
				}
				t.line("with(buffer)").ob;
				createDecodings(t, type.fields);
				t.cb.cb.nl;
				createToString(t, toPascalCase(type.name), type.fields, false);
				t.cb.nl;
			}
			write(t, "protocol/" ~ game);

			// sections
			auto s = new DSource("protocol/" ~ game ~ "/package");
			s.line("module soupply.protocol." ~ game ~ ";").nl.line("public import soupply.protocol." ~ game ~ ".types;").nl;
			foreach(section ; prts.data.sections) {
				s.line("public import soupply.protocol." ~ game ~ "." ~ section.name ~ ";");
				auto data = new DSource("protocol/" ~ game ~ "/" ~ section.name);
				data.line("module soupply.protocol." ~ game ~ "." ~ section.name ~ ";").nl;
				data.line("import std.bitmanip : write, peek;").line("static import std.conv;").line("import std.system : Endian;")
					.line("import std.typetuple : TypeTuple;").line("import std.uuid : UUID;").nl;
				data.line("import soupply.util.buffer;").line("import soupply.util.tuple : Tuple;").line("import soupply.util.var;").nl.line("static import soupply.protocol." ~ game ~ ".types;").nl;
				data.line("static if(__traits(compiles, { import soupply.metadata." ~ game ~ "; })) import soupply.metadata." ~ game ~ ";").nl;
				string[] names;
				foreach(packet ; section.packets) names ~= toPascalCase(packet.name);
				data.line("alias Packets = TypeTuple!(" ~ names.join(", ") ~ ");").nl;
				foreach(packet ; section.packets) {
					data.line("class " ~ toPascalCase(packet.name) ~ " : Buffer").ob.nl;
					data.line("public enum " ~ id ~ " ID = " ~ to!string(packet.id) ~ ";").nl;
					data.line("public enum bool CLIENTBOUND = " ~ to!string(packet.clientbound) ~ ";");
					data.line("public enum bool SERVERBOUND = " ~ to!string(packet.serverbound) ~ ";").nl;
					writeFields(data, packet.fields, true);
					// encoding
					data.line("public pure nothrow @safe ubyte[] encode(bool writeId=true)()").ob;
					data.line("_buffer.length = 0;");
					data.line("static if (writeId)").ob;
					createEncoding(data, prts.data.id, "ID");
					data.cb;
					createEncodings(data, packet.fields);
					data.line("return _buffer;");
					data.cb.nl;
					// decoding
					data.line("public pure nothrow @safe void decode(bool readId=true)()").ob;
					data.line("static if(readId)").ob.line(id ~ " _id;");
					createDecoding(data, prts.data.id, "_id");
					data.cb;
					createDecodings(data, packet.fields);
					data.cb.nl;
					// static decoding
					data.line("public static pure nothrow @safe " ~ toPascalCase(packet.name) ~ " fromBuffer(bool readId=true)(ubyte[] buffer)").ob;
					data.line(toPascalCase(packet.name) ~ " ret = new " ~ toPascalCase(packet.name) ~ "();");
					data.line("ret._buffer = buffer;");
					data.line("ret.decode!readId();");
					data.line("return ret;");
					data.cb.nl;
					createToString(data, toPascalCase(packet.name), packet.fields);
					// variants
					if(packet.variants.length) {
						data.line("alias _encode = encode;").nl;
						data.line("enum string variantField = \"" ~ convertName(packet.variantField) ~ "\";").nl;
						string[] v;
						foreach(variant ; packet.variants) {
							v ~= toPascalCase(variant.name);
						}
						data.line("alias Variants = TypeTuple!(" ~ v.join(", ") ~ ");").nl;
						foreach(variant ; packet.variants) {
							data.line("public class " ~ toPascalCase(variant.name)).ob.nl;
							data.line("public enum typeof(" ~ convertName(packet.variantField) ~ ") " ~ toUpper(packet.variantField) ~ " = " ~ variant.value ~ ";").nl;
							writeFields(data, variant.fields, true);
							// encode
							data.line("public pure nothrow @safe ubyte[] encode(bool writeId=true)()").ob;
							data.line(convertName(packet.variantField) ~ " = " ~ variant.value ~ ";");
							data.line("_encode!writeId();");
							createEncodings(data, variant.fields);
							data.line("return _buffer;");
							data.cb.nl;
							// decode
							data.line("public pure nothrow @safe void decode()").ob.nl;
							createDecodings(data, variant.fields);
							data.cb.nl;
							// toString
							createToString(data, toPascalCase(packet.name) ~ "." ~ toPascalCase(variant.name), variant.fields);
							data.cb.nl;
						}
					}
					data.cb.nl;
				}
				write(data, "protocol/" ~ game);
			}
			write(s, "protocol/" ~ game);

			// metadata
			/+auto m = game in data.metadatas;
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
			}+/

		}
	}

	private @property Generator generator() {
		return this;
	}

	class DSource : Source {

		public this(string path) {
			super(generator, path, "d");
		}

	}

}
