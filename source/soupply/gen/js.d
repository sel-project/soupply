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
module soupply.gen.js;

import std.algorithm : canFind, min, reverse;
import std.ascii : newline;
import std.conv : to;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.path : dirSeparator;
import std.regex : ctRegex, replaceAll, matchFirst;
import std.string;
import std.typecons;

import soupply.data;
import soupply.generator;
import soupply.gen.code;
import soupply.util;

import transforms : snakeCase, camelCaseLower, camelCaseUpper;

class JavascriptGenerator : CodeGenerator {

	immutable bool node;

	public this(bool node, string extension) {

		this.node = node;

		CodeMaker.Settings settings;
		settings.inlineBraces = true;
		settings.spaceAfterBlock = node;

		settings.moduleStat = "const %s =";
		settings.importStat = "import %s from '%s'";
		settings.classStat = "%s: class extends Buffer";
		settings.constStat = node ? "static get %s(){ return %s; }" : "static get %s(){return %s;}";

		super(settings, extension);

	}

	protected override void generateGame(string game, Info info) {

		enum defaultTypes = ["byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double"];

		@property string convert(string type) {
			auto end = min(cast(size_t)type.lastIndexOf("["), cast(size_t)type.lastIndexOf("<"), type.length);
			auto t = type[0..end];
			auto e = type[end..$].replaceAll(ctRegex!`\[[0-9]{1,3}\]`, "[]");
			if(e.length && e[0] == '<') return ""; //TODO
			else if(defaultTypes.canFind(t)) return t ~ e;
			else if(t == "metadata") return "Metadata";
			else return "Types." ~ camelCaseUpper(t) ~ e;
		}

		immutable id = convert(info.protocol.id);
		immutable arrayLength = convert(info.protocol.arrayLength);

		// returns the endianness for a type
		string endiannessOf(string type, string over="") {
			return camelCaseUpper(over.length ? over : info.protocol.endianness);
		}

		// encoding expression
		void createEncoding(CodeMaker maker, string type, string name, string e="", string length="", string lengthEndianness="") {
			if(type[0] == 'u' && defaultTypes.canFind(type[1..$])) type = type[1..$];
			auto lo = type.lastIndexOf("[");
			if(lo > 0) {
				auto lc = type.lastIndexOf("]");
				immutable nt = type[0..lo];
				immutable cnt = convert(nt);
				if(lo == lc - 1) {
					if(length.length) {
						createEncoding(maker, length, name ~ ".length", lengthEndianness);
					} else {
						createEncoding(maker, info.protocol.arrayLength, name ~ ".length");
					}
				}
				if(cnt == "ubyte") {
					maker.stat("this.writeBytes(" ~ name ~ ")");
				} else {
					maker.block("for(var " ~ hash(name) ~ " in " ~ name ~ ")");
					createEncoding(maker, nt, name ~ "[" ~ hash(name) ~ "]");
					maker.endBlock();
				}
			} else {
				auto ts = type.lastIndexOf("<");
				if(ts > 0) {
					auto te = type.lastIndexOf(">");
					string nt = type[0..ts];
					foreach(i ; type[ts+1..te]) {
						createEncoding(maker, nt, name ~ "." ~ i);
					}
				} else {
					if(type.startsWith("var")) maker.stat("this.write" ~ capitalize(type) ~ "(" ~ name ~ ")");
					else if(type == "string"){ maker.stat("var " ~ hash(name) ~"=this.encodeString(" ~ name ~")"); createEncoding(maker, info.protocol.arrayLength, hash(name) ~ ".length"); maker.stat("this.writeBytes(" ~ hash(name) ~ ")"); }
					else if(type == "uuid" || type == "bytes") maker.stat("this.writeBytes(" ~ name ~ ")");
					else if(type == "bytes") maker.stat("this.writeBytes(" ~ name ~ ")");
					else if(type == "bool") maker.stat("this.writeBool(" ~ name ~ ")");
					else if(type == "byte" || type == "ubyte") maker.stat("this.writeByte(" ~ name ~ ")");
					else if(defaultTypes.canFind(type)) maker.stat("this.write" ~ endiannessOf(type, e) ~ capitalize(type) ~ "(" ~ name ~ ")");
					else maker.stat("this.writeBytes(" ~ name ~ ".encodeBody(true))");
				}
			}
		}

		// decoding expressions
		void createDecoding(CodeMaker maker, string type, string name, string e="", string length="", string lengthEndianness="") {
			if(type[0] == 'u' && defaultTypes.canFind(type[1..$])) type = type[1..$];
			auto lo = type.lastIndexOf("[");
			if(lo > 0) {
				auto lc = type.lastIndexOf("]");
				immutable nt = type[0..lo];
				immutable cnt = convert(nt);
				if(lo == lc - 1) {
					if(length.length) {
						createDecoding(maker, length, "var " ~ hash("\0" ~ name), lengthEndianness);
					} else {
						createDecoding(maker, info.protocol.arrayLength, "var " ~ hash("\0" ~ name));
					}
				} else {
					maker.stat("var " ~ hash("\0" ~ name) ~ "=" ~ type[lo+1..lc]);
				}
				if(cnt == "ubyte") {
					maker.stat(name ~ "=this.readBytes(" ~ hash("\0" ~ name) ~ ")");
				} else {
					maker.stat(name ~ "=[]");
					maker.block("for(var " ~ hash(name) ~ "=0;" ~ hash(name) ~ "<" ~ hash("\0" ~ name) ~ ";" ~ hash(name) ~ "++)");
					createDecoding(maker, nt, name ~ "[" ~ hash(name) ~ "]");
					maker.endBlock();
				}
			} else {
				auto ts = type.lastIndexOf("<");
				if(ts > 0) {
					auto te = type.lastIndexOf(">");
					string nt = type[0..ts];
					maker.stat(name ~ "={}");
					foreach(i ; type[ts+1..te]) {
						createDecoding(maker, nt, name ~ "." ~ i);
					}
				} else {
					if(type.startsWith("var")) maker.stat(name ~ "=this.read" ~ capitalize(type) ~ "()");
					else if(type == "string"){ createDecoding(maker, info.protocol.arrayLength, "var " ~ hash(name)); maker.stat(name ~ "=this.decodeString(this.readBytes(" ~ hash(name) ~ "))"); }
					else if(type == "uuid") maker.stat(name ~ "=this.readBytes(16)");
					else if(type == "bytes") maker.stat(name ~ "=Array.from(this._buffer)").stat("this._buffer=[]");
					else if(type == "bool") maker.stat(name ~ "=this.readBool()");
					else if(type == "byte" || type == "ubyte") maker.stat(name ~ "=this.readByte()");
					else if(defaultTypes.canFind(type)) maker.stat(name ~ "=this.read" ~ endiannessOf(type, e) ~ capitalize(type) ~ "()");
					else maker.stat(name ~ "=new " ~ convert(type) ~ "().decodeBody(this._buffer)").stat("this._buffer=" ~ name ~ "._buffer");
				}
			}
		}

		void writeFields(CodeMaker maker, string className, Protocol.Field[] fields, string cont, ptrdiff_t id=-1, string variantField="", Protocol.Variant[] variants=[], string length="") {
			// constants
			if(node) {
				foreach(field ; fields) {
					if(field.constants.length) {
						if(node) maker.line("// " ~ field.name.replace("_", " "));
						foreach(con ; field.constants) {
							maker.addConst(con.name.toUpper(), con.value); //FIXME string constants
						}
						maker.nl;
					}
				}
			}
			// variant's values
			if(variantField.length) {
				if(node) maker.line("// " ~ variantField.replace("_", " ") ~ " (variant)");
				foreach(variant ; variants) {
					maker.addConst(variant.name.toUpper(), variant.value);
				}
				maker.nl;
			}
			string[] f;
			foreach(i, field; fields) {
				immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
				f ~= name ~ "=" ~ (field.default_.length ? constOf(field.default_) : defaultValue(field.type));
			}
			maker.block("constructor(" ~ f.join(node ? ", " : ",") ~ ")");
			maker.stat("super()");
			foreach(i, field; fields) {
				immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
				maker.stat("this." ~ name ~ " = " ~ name);
			}
			maker.endBlock().nl;
			if(variantField.length) {
				//TODO constructor for variants

			}
			// encode
			with(maker) {
				if(node) line("/** @return {Uint8Array} */");
				block("encodeBody(reset)");
				block("if(reset)").stat("this.reset()").endBlock();
				//stat("encodeReset()");
				foreach(i, field; fields) {
					bool c = field.condition != "";
					immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
					if(c) block("if(" ~ camelCaseLower(field.condition) ~ ")");
					//stat("encodeState(this, '" ~ name ~ "')");
					createEncoding(maker, field.type, "this." ~ name, field.endianness, field.length, field.lengthEndianness);
					if(c) endBlock();
				}
				if(variantField.length) {
					block("switch(this." ~ convertName(variantField) ~ ")");
					foreach(variant ; variants) {
						line("case " ~ variant.value ~ ":").add_indent();
						foreach(i, field; fields) {
							bool c = field.condition != "";
							immutable name = field.name == "?" ? "unknown" ~ to!string(i + fields.length) : convertName(field.name);
							if(c) block("if(" ~ camelCaseLower(field.condition) ~ ")");
							createEncoding(maker, field.type, "this." ~ name, field.endianness, field.length, field.lengthEndianness);
							if(c) endBlock();
						}
						stat("break").remove_indent();
					}
					stat("default: break");
					endBlock();
				}
				if(length.length) {
					stat("var _buffer=this._buffer");
					stat("this.reset()");
					createEncoding(maker, length, "_buffer.length");
					stat("this.writeBytes(_buffer)");
				}
				stat("return new Uint8Array(this._buffer)");
				endBlock().nl;
			}
			// decode
			with(maker) {
				if(node) line("/** @param {(Uint8Array|Array)} buffer */");
				block("decodeBody(_buffer)");
				stat("this._buffer=Array.from(_buffer)");
				stat("initDecode(this)");
				if(length.length) {
					createDecoding(maker, length, "var _length");
					stat("_buffer=this._buffer.slice(_length)");
					block("if(this._buffer.length>_length)").stat("this._buffer.length=_length").endBlock();
				}
				foreach(i, field; fields) {
					bool c = field.condition != "";
					immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
					if(c) block("if(" ~ camelCaseLower(field.condition) ~ ")");
					createDecoding(maker, field.type, "this." ~ name, field.endianness, field.length, field.lengthEndianness);
					stat("traceDecode('" ~ name ~ "')");
					if(c) endBlock();
				}
				if(variantField.length) {
					block("switch(this." ~ camelCaseLower(variantField) ~ ")");
					foreach(variant ; variants) {
						line("case " ~ variant.value ~ ":").add_indent();
						foreach(i, field; variant.fields) {
							bool c = field.condition != "";
							immutable name = field.name == "?" ? "unknown" ~ to!string(i + fields.length) : convertName(field.name);
							if(c) block("if(" ~ camelCaseLower(field.condition) ~ ")");
							createDecoding(maker, field.type, "this." ~ name, field.endianness, field.length, field.lengthEndianness);
							if(c) endBlock();
						}
						stat("break").remove_indent();
					}
					stat("default: break");
					endBlock();
				}
				if(length.length) {
					stat("this._buffer=_buffer");
				}
				stat("return this");
				endBlock().nl;
				// from buffer
				/+if(node) line("/** @param {(Uint8Array|Array)} buffer */");
				block("static fromBuffer(buffer)");
				stat("return new " ~ cont ~ "." ~ className ~ "().decode(buffer)");
				endBlock().nl;+/
			}
			if(node) with(maker) {
				line("/** @return {string} */");
				block("toString()");
				string[] s;
				foreach(i, field; fields) {
					immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
					s ~= name ~ ": \" + this." ~ name;
				}
				stat("return \"" ~ className ~ "(" ~ (fields.length ? s.join(" + \", ") ~ " + \"" : "") ~ ")\"");
				endBlock().nl;
			}
		}

		// packet
		auto pk = make(game, "packet");
		pk.clear();
		with(pk) {
			block("class Packet extends Buffer").nl;
			block("encode()");
			stat("this.reset()");
			stat("this.encodeId()");
			if(info.protocol.padding) stat("this.writeBytes(new Uint8Array(" ~ info.protocol.padding.to!string ~ "))");
			stat("this.encodeBody(false)");
			stat("return this._buffer");
			endBlock().nl;
			block("encodeId()");
			createEncoding(pk, info.protocol.id, "this.getId()");
			endBlock().nl;
			block("decode(buffer)");
			stat("this._buffer = Array.from(buffer)");
			stat("this.decodeId()");
			if(info.protocol.padding) stat("this.readBytes(" ~ info.protocol.padding.to!string ~ ")");
			stat("this.decodeBody()");
			endBlock().nl;
			block("decodeId()");
			createDecoding(pk, info.protocol.id, "var id");
			endBlock().nl;
			endBlock();
			save();
		}

		// types
		auto types = make(game, "types");
		types.clear();
		with(types) {
			block("const Types =").nl;
			foreach(i, type; info.protocol.types) {
				block(camelCaseUpper(type.name) ~ ": class extends Buffer").nl;
				writeFields(types, camelCaseUpper(type.name), type.fields, "Types", -1, "", [], type.length);
				endBlock();
				if(i != info.protocol.types.length - 1) line(",");
				nl;
			}
			endBlock().nl;
			if(node) line("export { Types }");
			save(info.file);
		}

		// sections
		foreach(section ; info.protocol.sections) {
			auto mod = make(game, section.name);
			mod.clear();
			with(mod) {
				if(node) stat("import Packet from 'packet'").stat("import Types from 'types'").nl;
				block("const " ~ camelCaseUpper(section.name) ~ " =").nl;
				foreach(i, packet; section.packets) {
					block(camelCaseUpper(packet.name) ~ ": class extends Packet").nl;
					addConst("ID", packet.id.to!string).nl;
					addConst("CLIENTBOUND", packet.clientbound.to!string);
					addConst("SERVERBOUND", packet.serverbound.to!string).nl;
					block("getId()").stat("return " ~ packet.id.to!string).endBlock().nl;
					writeFields(mod, camelCaseUpper(packet.name), packet.fields, camelCaseUpper(section.name), packet.id, packet.variantField, packet.variants);
					endBlock();
					if(i != section.packets.length - 1) line(",");
					nl;
				}
				endBlock().nl;
				if(node) stat("module.export = " ~ camelCaseUpper(section.name));
				save(info.file);
			}
		}

		// metadata
		/+auto m = game in metadatas;
		if(m) {
			mkdirRecurse("../src/js/sul/metadata");
			string data = "/** @module sul/metadata/" ~ game ~ " */\n\n";
			data ~= "class Metadata extends Buffer {\n\n";
			data ~= "\tconstructor() {\n\t\tsuper();\n";
			string[string] ctable, etable;
			ubyte[string] idtable;
			foreach(type ; m.data.types) {
				ctable[type.name] = type.type;
				etable[type.name] = type.endianness;
				idtable[type.name] = type.id;
			}
			foreach(d ; m.data.data) {
				data ~= "\t\tthis._" ~ convertName(d.name) ~ " = " ~ (d.required ? (d.def.length ? d.def : defaultValue(ctable[d.type])) : "undefined") ~ ";\n";
			}
			data ~= "\t}\n\n";
			size_t req = 0;
			foreach(d ; m.data.data) {
				if(d.required) req++;
				immutable name = convertName(d.name);
				// get
				data ~= "\tget " ~ name ~ "() {\n\t\treturn this._" ~ name ~ ";\n\t}\n\n";
				// set
				data ~= "\tset " ~ name ~ "(value) {\n";
				data ~= "\t\treturn this._" ~ name ~ " = value;\n";
				data ~= "\t}\n\n";
				// encode
				/*data ~= "\tpublic pure nothrow @safe encode" ~ name[0..1].toUpper ~ name[1..$] ~ "(Buffer buffer) {\n";
				data ~= "\t\twith(buffer) {\n";
				data ~= "\t\t\t" ~ createEncoding(m.data.id, d.id.to!string) ~ "\n";
				data ~= "\t\t\t" ~ createEncoding(m.data.type, idtable[d.type].to!string) ~ "\n";
				data ~= "\t\t\t" ~ createEncoding(ctable[d.type], "this." ~ value, etable[d.type]) ~ "\n";
				data ~= "\t\t}\n";
				data ~= "\t}\n\n";*/
				foreach(flag ; d.flags) {
					immutable fname = convertName(flag.name);
					data ~= "\tget " ~ fname ~ "() {\n";
					data ~= "\t\treturn ((this." ~ name ~ " >>> " ~ to!string(flag.bit) ~ ") & 1) === 1;\n";
					data ~= "\t}\n\n";
					data ~= "\tset " ~ fname ~ "(value) {\n";
					data ~= "\t\tif(value) this._" ~ name ~ " |= true << " ~ to!string(flag.bit) ~ ";\n";
					data ~= "\t\telse this._" ~ name ~ " &= ~(true << " ~ to!string(flag.bit) ~ ");\n";
					data ~= "\t\treturn value;\n";
					data ~= "\t}\n\n";
				}
			}
			// encode function
			data ~= "\tencode() {\n";
			data ~= "\t\tthis._buffer = [];\n";
			if(m.data.prefix.length) data ~= "\t\t" ~ createEncoding("ubyte", m.data.prefix) ~ "\n";
			if(m.data.length.length) data ~= "\t\tvar length = " ~ to!string(req) ~ ";\n";
			foreach(d ; m.data.data) {
				immutable name = convertName(d.name);
				if(!d.required) data ~= "\t\tif(this._" ~ name ~ " !== undefined) {\n";
				else data ~= "\t\t{\n";
				if(!d.required && m.data.length.length) data ~= "\t\t\tlength++;\n";
				data ~= "\t\t\t" ~ createEncoding(m.data.id, d.id.to!string) ~ "\n";
				data ~= "\t\t\t" ~ createEncoding(m.data.type, idtable[d.type].to!string) ~ "\n";
				data ~= "\t\t\t" ~ createEncoding(ctable[d.type], "this._" ~ name, etable[d.type]) ~ "\n";
				data ~= "\t\t}\n";
			}
			if(m.data.suffix.length) data ~= "\t\t" ~ createEncoding("ubyte", m.data.suffix) ~ "\n";
			if(m.data.length.length) {
				data ~= "\t\tvar buffer = this._buffer;\n";
				data ~= "\t\tthis._buffer = [];\n";
				data ~= "\t\t" ~ createEncoding(m.data.length, "length") ~ "\n";
				data ~= "\t\tthis.writeBytes(buffer);\n";
			}
			data ~= "\t\treturn new Uint8Array(this._buffer);\n";
			data ~= "\t}\n\n";
			//TODO decode function
			data ~= "\tdecode(buffer) {\n";
			data ~= "\t\tthis._buffer = Array.from(buffer);\n";
			data ~= "\t\tvar result = [];\n";
			data ~= "\t\tvar metadata;\n";
			if(m.data.length.length) {
				data ~= "\t\t" ~ createDecoding(m.data.length, "var length") ~ "\n";
				data ~= "\t\twhile(length-- > 0) {\n";
				data ~= "\t\t\t" ~ createDecoding("ubyte", "metadata") ~ "\n";
			} else if(m.data.suffix.length) {
				data ~= "\t\twhile(this._buffer.length > 0 && (" ~ createDecoding("ubyte", "metadata")[0..$-1] ~ ") != " ~ m.data.suffix ~ ") {\n";
			}
			data ~= "\t\t\tswitch(" ~ createDecoding("ubyte", "")[1..$-1] ~ ") {\n";
			foreach(type ; m.data.types) {
				data ~= "\t\t\t\tcase " ~ type.id.to!string ~ ":\n";
				data ~= "\t\t\t\t\tvar _" ~ type.id.to!string ~ ";\n";
				data ~= "\t\t\t\t\t" ~ createDecoding(type.type, "_" ~ type.id.to!string, type.endianness) ~ "\n";
				data ~= "\t\t\t\t\tresult.push({id:" ~ type.id.to!string ~ ",value:_" ~ type.id.to!string ~ "});\n";
				data ~= "\t\t\t\t\tbreak;\n";
			}
			data ~= "\t\t\t\tdefault: break;\n";
			data ~= "\t\t\t}\n";
			data ~= "\t\t}\n";
			data ~= "\t\tthis.decodeResult = result;\n";
			data ~= "\t\treturn this;\n";
			data ~= "\t}\n\n";
			// from buffer
			data ~= "\tstatic fromBuffer(buffer) {\n";
			data ~= "\t\treturn new Metadata().decode(buffer);\n";
			data ~= "\t}\n";
			data ~= "}";
			write("../src/js/sul/metadata/" ~ game ~ ".js", data, "metadata/" ~ game);
		}+/
		
	}

	override @property string convertName(string name) {
		if(name == "default") return "default_";
		else return camelCaseLower(name);
	}
	
	string defaultValue(string type) {
		if(type == "float" || type == "double") return ".0";
		else if(type == "bool") return "false";
		else if(type == "string") return `""`;
		else if(type == "uuid") return "new Uint8Array(16)";
		else if(type == "metadata") return "new Metadata()";
		else if(type.endsWith("]")) {
			string size = "0";
			if(type[$-2] != '[') size = type[type.lastIndexOf("[")+1..$-1];
			type = type[0..type.lastIndexOf("[")];
			if(type == "byte") return "new Int8Array(" ~ size ~ ")";
			else if(type == "ubyte") return "new Uint8Array(" ~ size ~ ")";
			else if(type == "short" || type == "varshort") return "new Int16Array(" ~ size ~ ")";
			else if(type == "ushort" || type == "varushort") return "new Uint16Array(" ~ size ~ ")";
			else if(type == "int" || type == "varint" || type == "triad") return "new Int32Array(" ~ size ~ ")";
			else if(type == "uint" || type == "varuint") return "new Uint32Array(" ~ size ~ ")";
			else if(type == "float") return "new Float32Array(" ~ size ~ ")";
			else if(type == "double") return "new Float64Array(" ~ size ~ ")";
			else return "[]";
		} else if(type.indexOf("<") != -1) return "{" ~ type.matchFirst(ctRegex!`<[a-z]+>`).hit[1..$-1].split("").join(":0,") ~ ":0}";
		else if(["byte", "ubyte", "short", "ushort", "triad", "int", "uint", "long", "ulong"].canFind(type) || type.startsWith("var")) return "0";
		else return "new Types." ~ camelCaseUpper(type) ~ "()";
		//else return "null";
	}

}

class SandboxGenerator : JavascriptGenerator {
	
	static this() {
		Generator.register!SandboxGenerator("JavaScript", "soupply.github.io", "sandbox/src");
	}

	this() {
		super(false, "js");
	}

}

class NodeJSGenerator : JavascriptGenerator {

	static this() {
		Generator.register!NodeJSGenerator("Node JS", "node-js", "src/" ~ SOFTWARE, ["/*", " *", " */"]);
	}

	this() {
		super(true, "js");
	}

}
