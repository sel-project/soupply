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

import std.algorithm : canFind, max, sort;
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
import soupply.gen.code;
import soupply.util;

import transforms : snakeCase, camelCaseLower, camelCaseUpper;

class DGenerator : CodeGenerator {

	static this() {
		Generator.register!DGenerator("d", "", ["/*", " *", " */"]);
	}

	private Protocol.Array[string] arrays;

	public this() {

		CodeMaker.Settings settings;
		settings.inlineBraces = false;
		settings.moduleSeparator = ".";
		settings.standardLibrary = "std";

		settings.moduleStat = "module %s";
		settings.importStat = "import %s";
		settings.classStat = "class %s";
		settings.constStat = "enum %s = %d";

		super(settings, "d");

	}

	protected override CodeMaker make(string[] module_...) {
		auto ret = super.make([module_[0], "src", SOFTWARE] ~ module_);
		ret.clear();
		if(module_[$-1] == "package") module_ = module_[0..$-1];
		ret.stat("module " ~ join([SOFTWARE] ~ module_, ".")).nl;
		return ret;
	}

	protected override string convertModule(string name) {
		return name.replace("_", "");
	}

	protected override void generateImpl(Data d) {

		super.generateImpl(d);

		string[] tests;

		// create latest modules
		foreach(game, info; d.info) {
			if(info.latest) {

				// dub.sdl
				with(new Maker(this, info.game ~ "/dub", "sdl")) {
					line(`name "` ~ info.game ~ `"`);
					line(`description "Libraries for the latest ` ~ info.software ~ ` protocol"`);
					line(`targetType "library"`);
					line(`dependency "` ~ SOFTWARE ~ `:` ~ game ~ `" version="*"`);
					save();
				}

				// src
				Maker m(string[] mod...) {
					auto ret = new Maker(this, join([info.game, "src", SOFTWARE, info.game] ~ mod, "/"), "d");
					if(mod[$-1] == "package") mod = mod[0..$-1];
					ret.line("module " ~ join([SOFTWARE, info.game] ~ mod, ".") ~ ";").nl;
					ret.line("public import " ~ join([SOFTWARE, game] ~ mod, ".") ~ ";").nl;
					return ret;
				}

				m("packet").line("alias " ~ camelCaseUpper(info.game) ~ "Packet = " ~ camelCaseUpper(game) ~ "Packet;").save();
				m("types").save();
				foreach(section ; info.protocol.sections) m("protocol", section.name).save();
				m("metadata").save();

				m("package").save();
				m("protocol", "package").save();

			}
			if(info.game == "test") tests ~= game;
		}

		// create test.sh
		sort(tests);
		with(new Maker(this, "test", "sh")) {
			line("#!/bin/bash").nl;
			foreach(test ; tests) line("dub test :" ~ test ~ " --compiler=$DC --build=$CONFIG");
			save();
		}
		with(new Maker(this, "test/src/soupply/test", "d")) {
			line("module soupply.test;");
			foreach(test ; tests) line("import soupply." ~ test ~ ";");
			save();
		}
		
		string[] all = data.info.keys;
		all ~= "util";
		sort(all);

		// src
		with(new Maker(this, "src/" ~ SOFTWARE ~ "/package", "d")) {
			line("module " ~ SOFTWARE ~ ";").nl;
			foreach(imp ; all) {
				if(!imp.startsWith("test")) line("public import " ~ SOFTWARE ~ "." ~ imp ~ ";");
			}
			save();
		}

		foreach(info ; data.info) {
			if(info.latest) all ~= info.game;
		}
		sort(all);
		
		// create main dub.sdl
		with(new Maker(this, "dub", "sdl")) {
			void add(string dep) {
				line(`subPackage "` ~ dep ~ `"`);
				line(`dependency "` ~ SOFTWARE ~ `:` ~ dep ~ `" version="*"`);
			}
			line(`name "` ~ SOFTWARE ~ `"`);
			line(`description "` ~ d.description ~ `"`);
			line(`license "` ~ d.license ~ `"`);
			line(`targetType "library"`);
			nl();
			foreach(pkg ; all) {
				line(`subPackage "` ~ pkg ~ `"`);
			}
			nl();
			foreach(dep ; all) {
				if(!dep.startsWith("test")) line(`dependency "` ~ SOFTWARE ~ `:` ~ dep ~ `" version="*"`);
			}
			save();
		}

	}

	protected override void generateGame(string game, Info info) {

		// create dub.sdl for current game
		with(new Maker(this, game ~ "/dub", "sdl")) {
			line(`name "` ~ game ~ `"`);
			line(`description "Libraries for ` ~ info.software ~ ` protocol ` ~ info.version_.to!string ~ `"`);
			line(`targetType "library"`);
			line(`dependency "` ~ SOFTWARE ~ `:util" version="*"`);
			save();
		}

		this.arrays = info.protocol.arrays;

		immutable base = camelCaseUpper(game) ~ "Packet";
		
		string endiannessOf(string type, string over="") {
			if(over.length) return camelCaseLower(over);
			auto e = type in info.protocol.endianness;
			if(e) return camelCaseLower(*e);
			else return endiannessOf("*");
		}

		immutable defaultEndianness = endiannessOf("*");

		with(make(game, "packet")) {

			immutable extends = "PacketImpl!(Endian." ~ defaultEndianness ~ ", " ~ info.protocol.id ~ ", " ~ info.protocol.arrayLength ~ ")";

			addImport("packetmaker").nl;
			if(info.protocol.padding) {
				addImportLib("util", "Pad").nl;
				stat("alias " ~ base ~ " = Pad!(" ~ info.protocol.padding.to!string ~ ", " ~ extends ~ ")");
			} else {
				stat("alias " ~ base ~ " = " ~ extends);
			}
			save();

		}

		string convertEndian(string type) {
			if(type.startsWith("var")) return "EndianType.var, " ~ type[3..$];
			else return "Endian." ~ defaultEndianness ~ ", " ~ type;
		}

		string[] attributes(Protocol.Field field) {

			string[] ret;

			// check condition
			if(field.condition.length) ret ~= `@Condition("` ~ camelCaseLower(field.condition) ~ `")`;

			// endianness
			if(field.endianness.length) ret ~= "@" ~ camelCaseUpper(field.endianness);

			// var
			if(field.type.startsWith("var")) {
				immutable type = field.type[3..$];
				foreach(var ; ["short", "int", "long"]) {
					if(type.startsWith(var) || type.startsWith("u" ~ var)) {
						ret ~= "@Var";
						break;
					}
				}
			}

			// custom array
			auto array = field.type in info.protocol.arrays;
			if(array) {
				if(array.endianness.length) ret ~= "@EndianLength!" ~ array.length ~ "(Endian." ~ camelCaseLower(array.endianness) ~ ")";
				else ret ~= "@Length!" ~ array.length;
			}

			// bytes
			if(field.type == "bytes") ret ~= "@Bytes";

			ret ~= "";

			return ret;

		}

		string[] attributes2(string type, string endianness="") {

			return attributes(Protocol.Field("", type, "", endianness))[0..$-1];

		}

		void writeFields(CodeMaker source, Protocol.Field[] fields, bool isClass) {
			// constants
			foreach(field ; fields) {
				if(field.constants.length) {
					source.line("// " ~ field.name.replace("_", " "));
					foreach(constant ; field.constants) {
						source.stat("enum " ~ source.convertType(field.type) ~ " " ~ toUpper(constant.name) ~ " = " ~ (field.type == "string" ? JSONValue(constant.value).toString() : constant.value));
					}
					source.nl;
				}
			}
			// fields' names
			string[] fn;
			foreach(i, field; fields) fn ~= field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
			source.stat("enum string[] __fields = " ~ to!string(fn)).nl;
			// fields
			foreach(i, field; fields) {
				//TODO add attributes
				source.stat(join(attributes(field), " ") ~ source.convertType(field.type) ~ " " ~ (field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name)) ~ (field.default_.length ? " = " ~ constOf(field.default_) : ""));
				if(i == fields.length - 1) source.nl;
			}
			// constructors
			if(isClass && fields.length) {
				source.line("this() pure nothrow @safe @nogc {}").nl;
				string[] args;
				foreach(i, field; fields) {
					immutable type = source.convertType(field.type);
					immutable p = type.canFind('[');
					args ~= type ~ " " ~ (field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name)) ~ (i ? "=" ~ (field.default_.length ? constOf(field.default_) : (p ? "(" : "") ~ type ~ (p ? ")" : "") ~ ".init") : "");
				}
				source.block("this(" ~ args.join(", ") ~ ") pure nothrow @safe @nogc");
				foreach(i, field; fields) {
					immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
					source.stat("this." ~ name ~ " = " ~ name);
				}
				source.endBlock().nl;
			}
		}

		void createToString(CodeMaker source, string name, Protocol.Field[] fields, bool override_=true) {
			source.block((override_ ? "override ": "") ~ "string toString()");
			string[] f;
			foreach(i, field; fields) {
				immutable n = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
				f ~= n ~ ": \" ~ std.conv.to!string(this." ~ n ~ ")";
			}
			source.stat("return \"" ~ name ~ "(" ~ (f.length ? (f.join(" ~ \", ") ~ " ~ \"") : "") ~ ")\"");
			source.endBlock().nl;
		}

		// types
		auto types = make(game, "types");
		with(types) {
			stat("static import std.conv");
			addImport("packetmaker");
			addImport("packetmaker.maker", "EndianType", "writeLength", "readLength").nl;
			addImportLib("util", "Vector", "UUID");
			addImportLib(game ~ ".metadata").nl;
			foreach(type ; info.protocol.types) {
				immutable hasLength = type.length.length != 0;
				// declaration
				block("struct " ~ camelCaseUpper(type.name)).nl;
				if(hasLength) {
					// create a container struct
					block("private struct Container").nl;
				}
				writeFields(types, type.fields, false);
				if(hasLength) {
					stat("mixin Make!(Endian." ~ defaultEndianness ~ ", " ~ info.protocol.id ~ ")").nl;
					endBlock().nl;
					stat("enum string[] __fields = Container.__fields").nl;
					stat("Container _container").nl;
					stat("alias _container this").nl;
					// encoding
					block("void encodeBody(InputBuffer buffer)");
					stat("InputBuffer _buffer = new InputBuffer()");
					stat("_container.encodeBody(_buffer)");
					stat("writeLength!(" ~ convertEndian(info.protocol.arrayLength) ~ ")(buffer, _buffer.data.length)");
					stat("buffer.writeBytes(_buffer.data)");
					endBlock().nl;
					// decoding
					block("void decodeBody(OutputBuffer buffer)");
					stat("_container.decodeBody(new OutputBuffer(buffer.readBytes(readLength!(" ~ convertEndian(info.protocol.arrayLength) ~ ")(buffer))))");
					endBlock().nl;
				} else {
					stat("mixin Make!(Endian." ~ defaultEndianness ~ ", " ~ info.protocol.id ~ ")").nl;
				}
				createToString(types, camelCaseUpper(type.name), type.fields, false);
				endBlock();
				nl;
			}
			save(info.file);
		}

		// sections
		string[] sections;
		foreach(section ; info.protocol.sections) {
			sections ~= section.name;
			auto s = make(game, "protocol", section.name);
			with(s) {
				stat("static import std.conv");
				addImportStd("typetuple", "TypeTuple");
				addImport("packetmaker").nl;
				addImportLib("util", "Vector", "UUID");
				addImportLib(game ~ ".metadata", "Metadata");
				addImportLib(game ~ ".packet", base).nl;
				stat("static import " ~ SOFTWARE ~ "." ~ game ~ ".types").nl;
				string[] names;
				foreach(packet ; section.packets) names ~= camelCaseUpper(packet.name);
				stat("alias Packets = TypeTuple!(" ~ names.join(", ") ~ ")").nl;
				foreach(packet ; section.packets) {
					addClass(camelCaseUpper(packet.name) ~ " : " ~ base).nl;
					stat("enum " ~ convertType(info.protocol.id) ~ " ID = " ~ to!string(packet.id)).nl;
					stat("enum bool CLIENTBOUND = " ~ to!string(packet.clientbound));
					stat("enum bool SERVERBOUND = " ~ to!string(packet.serverbound)).nl;
					writeFields(s, packet.fields, true);
					stat("mixin Make").nl;
					// static decoding
					block("public static typeof(this) fromBuffer(ubyte[] buffer)");
					stat(camelCaseUpper(packet.name) ~ " ret = new " ~ camelCaseUpper(packet.name) ~ "()");
					stat("ret.decode(buffer)");
					stat("return ret");
					endBlock().nl;
					// to string
					createToString(s, camelCaseUpper(packet.name), packet.fields);
					// variants
					if(packet.variants.length) {
						stat("enum string variantField = \"" ~ convertName(packet.variantField) ~ "\"").nl;
						string[] v;
						foreach(variant ; packet.variants) {
							v ~= camelCaseUpper(variant.name);
						}
						stat("alias Variants = TypeTuple!(" ~ v.join(", ") ~ ")").nl;
						foreach(variant ; packet.variants) {
							addClass(camelCaseUpper(variant.name) ~ " : " ~ base).nl;
							stat("enum typeof(" ~ convertName(packet.variantField) ~ ") " ~ toUpper(packet.variantField) ~ " = " ~ variant.value).nl;
							writeFields(s, variant.fields, true);
							stat("mixin Make").nl;
							// to string
							createToString(s, camelCaseUpper(packet.name) ~ "." ~ camelCaseUpper(variant.name), variant.fields);
							endBlock().nl;
						}
					}
					foreach(test ; packet.tests) {
						immutable loc = game ~ "." ~ section.name ~ "." ~ packet.name.replace("_", "-");
						immutable result = test["result"].toString().replace(",", ", ");
						block("unittest").nl;
						addImportStd("conv", "to").nl;
						stat(camelCaseUpper(packet.name) ~ " packet = new " ~ camelCaseUpper(packet.name) ~ "()").nl;
						foreach(field, value; test["fields"].object) {
							stat("packet." ~ convertName(field) ~ " = " ~ value.toString());
						}
						stat("auto result = packet.autoEncode()");
						stat("assert(result == " ~ result ~ ", \"" ~ loc ~ " expected " ~ result ~ " but got \" ~ result.to!string)").nl;
						stat("packet.decode(" ~ result ~ ")"); //TODO replace with autoDecode
						foreach(field, value; test["fields"].object) {
							stat("assert(packet." ~ convertName(field) ~ " == " ~ value.toString() ~ ", \"" ~ loc ~ "." ~ field.replace("_", "-") ~ " expected " ~ value.toString() ~ " but got \" ~ packet." ~ convertName(field) ~ ".to!string)");
						}
						nl;
						endBlock().nl;
					}
					endBlock().nl;
				}
				save(info.file);
			}
		}
		sort(sections);
		with(make(game, "protocol", "package")) {
			foreach(section ; sections) stat("public import " ~ SOFTWARE ~ "." ~ game ~ ".protocol." ~ section);
			save();
		}

		// metadata
		auto metadata = make(game, "metadata");
		with(metadata) {

			addImport("packetmaker").addImport("packetmaker.maker", "EndianType", "writeLength").nl;
			addImportLib("util", "Vector").nl;
			addImportLib(game ~ ".packet", base);
			stat("static import " ~ SOFTWARE ~ "." ~ game ~ ".types").nl;

			// types
			block("enum MetadataType : " ~ convertType(info.metadata.type));
			string[string] ctable, etable;
			ubyte[string] idtable;
			foreach(type ; info.metadata.types) {
				ctable[type.name] = type.type;
				etable[type.name] = type.endianness;
				idtable[type.name] = type.id;
				line(toUpper(type.name) ~ " = " ~ type.id.to!string ~ ",");
			}
			endBlock().nl;

			// ids
			/+block("struct MetadataId");
			foreach(d ; info.metadata.data) {
				immutable tp = convertType(ctable[d.type]);
				if(d.flags.length) {
					block("enum " ~ toUpper(d.name) ~ " : " ~ id);
					foreach(flag ; d.flags) {
						line(toUpper(flag.name) ~ " = " ~ flag.bit.to!string ~ ",");
					}
					endBlock();
				} else {
					stat("enum " ~ id ~ " " ~ toUpper(d.name) ~ " = " ~ d.id.to!string);
				}
			}
			endBlock().nl;+/

			// metadata value
			block("class MetadataValue : " ~ base).nl;
			immutable _id = convertType(info.metadata.id);
			immutable _type = convertType(info.metadata.type);
			stat(join(attributes2(info.metadata.id) ~ _id, " ") ~ " id");
			stat(join(attributes2(info.metadata.type) ~ _type, " ") ~ " type").nl;
			block("this(" ~ _id ~ " id, " ~ _type ~ " type) pure nothrow @safe @nogc");
			stat("this.id = id");
			stat("this.type = type");
			endBlock().nl;
			stat("mixin Make").nl;
			endBlock().nl;

			// value of
			foreach(type ; info.metadata.types) {
				immutable _value = convertType(type.type);
				block("class MetadataValue" ~ type.id.to!string ~ " : MetadataValue").nl;
				stat(join(attributes2(type.type, type.endianness) ~ _value, " ") ~ " value").nl;
				block("this(" ~ _id ~ " id, " ~ _value ~ " value) pure nothrow @safe @nogc");
				stat("super(id, " ~ type.id.to!string ~ ")");
				stat("this.value = value");
				endBlock().nl;
				stat("mixin Make").nl;
				endBlock().nl;
			}

			// metadata
			immutable _length = info.metadata.length != "";
			immutable _length_e = info.metadata.length.startsWith("var") ? "var" : defaultEndianness;
			block("struct Metadata").nl;
			stat("private MetadataValue[" ~ _id ~ "] _store");
			stat("private bool _cached = false");
			stat("private ubyte[] _cache").nl;

			// get and set
			//TODO

			// encode
			block("void encodeBody(InputBuffer buffer)");
			block("if(!_cached)");
			stat("InputBuffer _buffer = new InputBuffer()");
			if(_length) stat("writeLength!(EndianType." ~ _length_e ~ ", " ~ convertType(info.metadata.length) ~ ")(_buffer, _store.length)");
			stat("foreach(value ; _store) value.encodeBody(_buffer)");
			if(info.metadata.suffix.length) stat("_buffer.writeUnsignedByte(ubyte(" ~ info.metadata.suffix ~ "))");
			stat("_cached = true");
			stat("_cache = _buffer.data");
			endBlock();
			stat("buffer.writeBytes(_cache)");
			endBlock().nl;

			// decode
			block("void decodeBody(OutputBuffer buffer)");
			stat("assert(0, `Cannot decode Metadata`)");
			endBlock().nl;

			endBlock().nl;

			save(game);

		}

			
			
			/+data ~= "\tpublic pure nothrow @safe this() {\n";
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
				data ~= "\t\t\t\t\t\tmetadata.decoded ~= DecodedMetadata.from" ~ camelCaseUpper(type.name) ~ "(id, _" ~ type.id.to!string ~ ");\n";
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
				data ~= "\tpublic static pure nothrow @trusted DecodedMetadata from" ~ camelCaseUpper(type.name) ~ "(" ~ convertType(m.data.id) ~ " id, " ~ convertType(type.type) ~ " value) {\n";
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

		// package to import everything
		with(make(game, "package")) {
			foreach(mod ; ["packet", "types", "protocol", "metadata"]) {
				stat("public import " ~ SOFTWARE ~ "." ~ game ~ "." ~ mod);
			}
			save();
		}

	}

	// name conversion
	
	enum keywords = ["body", "default", "version"];
	
	protected override string convertName(string name) {
		return keywords.canFind(name) ? name ~ "_" : name.camelCaseLower;
	}

	// type conversion
	
	enum defaultTypes = ["bool", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "char", "string", "varint", "varuint", "varlong", "varulong", "UUID", "size_t", "ptrdiff_t"];
	
	enum string[string] defaultAliases = [
		"uuid": "UUID",
		"bytes": "ubyte[]",
		"varshort": "short",
		"varushort": "ushort",
		"varint": "int",
		"varuint": "uint",
		"varlong": "long",
		"varulong": "ulong"
	];
	
	protected override string convertType(string game, string type) {
		string ret, t = type;
		auto array = type.indexOf("[");
		if(array >= 0) {
			t = type[0..array];
		}
		auto vector = type.indexOf("<");
		if(vector >= 0) {
			ret = "Vector!(" ~ convertType(game, type[0..vector]) ~ ", \"" ~ type[vector+1..type.indexOf(">")] ~ "\")";
		} else if(t in defaultAliases) {
			return convertType(game, defaultAliases[t] ~ (array >= 0 ? type[array..$] : ""));
		} else if(defaultTypes.canFind(t)) {
			ret = t;
		} else if(t == "metadata") {
			ret = "Metadata";
		} else {
			auto a = t in this.arrays;
			if(a) return convertType(game, (*a).base ~ "[]" ~ (array >= 0 ? type[array..$] : ""));
		}
		if(ret == "") ret = SOFTWARE ~ "." ~ game ~ ".types." ~ t.camelCaseUpper;
		return ret ~ (array >= 0 ? type[array..$] : "");
	}

}
