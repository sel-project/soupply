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

import std.algorithm : canFind, min, reverse;
import std.ascii : newline;
import std.conv : to;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.path : dirSeparator;
import std.regex : ctRegex, replaceAll, matchFirst;
import std.string;
import std.typecons;

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

	// utils
	string utils = "";
	utils ~= "class Buffer {\n\n";
	utils ~= "\tconstructor() {\n";
	utils ~= "\t\tthis._buffer = [];\n";
	utils ~= "\t}\n\n";
	utils ~= "\twriteBytes(a) {\n";
	//utils ~= "\t\tthis._buffer.concat(a);\n"; // doesn't work
	utils ~= "\t\tfor(var i in a) {\n";
	utils ~= "\t\t\tthis._buffer.push(a[i]);\n";
	utils ~= "\t\t}\n";
	utils ~= "\t}\n\n";
	utils ~= "\treadBytes(a) {\n";
	utils ~= "\t\tvar ret = this._buffer.slice(0, a);\n";
	utils ~= "\t\tthis._buffer = this._buffer.slice(a, this._buffer.length);\n";
	utils ~= "\t\twhile(ret.length < a) ret.push(0)\n";
	utils ~= "\t\treturn ret;\n";
	utils ~= "\t}\n\n";
	foreach(type ; [tuple("byte", 1, "byte"), tuple("short", 2, "short"), tuple("triad", 3, "int"), tuple("int", 4, "int"), tuple("long", 8, "long")]) {
		foreach(e ; ["BigEndian", "LittleEndian"]) {
			// write
			utils ~= "\twrite" ~ e ~ capitalize(type[0]) ~ "(a) {\n";
			if(type[1] == 1) utils ~= "\t\tthis._buffer.push(a);\n";
			else {
				int[] shift;
				foreach(i ; 0..type[1]) shift ~= i * 8;
				if(e == "BigEndian") reverse(shift);
				foreach(i ; shift) {
					utils ~= "\t\tthis._buffer.push((a" ~ (i != 0 ? " >>> " ~ to!string(i) : "") ~ ") & 255);\n";
				}
			}
			utils ~= "\t}\n\n";
			// read
			utils ~= "\tread" ~ e ~ capitalize(type[0]) ~ "(a) {\n";
			if(type[1] == 1) utils ~= "\t\treturn this._buffer.shift();\n";
			else {
				utils ~= "\t\tvar _ret = 0;\n";
				int[] shift;
				foreach(i ; 0..type[1]) shift ~= i * 8;
				if(e == "BigEndian") reverse(shift);
				foreach(i ; shift) {
					utils ~= "\t\t_ret |= this._buffer.shift()" ~ (i != 0 ? " << " ~ to!string(i) : "") ~ ";\n";
				}
				utils ~= "\t\treturn _ret;\n";
			}
			utils ~= "\t}\n\n";
		}
	}
	foreach(type ; [tuple("float", 4), tuple("double", 8)]) {
		foreach(e ; ["BigEndian", "LittleEndian"]) {
			utils ~= "\twrite" ~ e ~ capitalize(type[0]) ~ "(a) {\n";
			utils ~= "\t\tthis.writeBytes(new Uint8Array(new Float" ~ to!string(type[1] * 8) ~ "Array([a]).buffer));\n";
			utils ~= "\t}\n\n";
			utils ~= "\tread" ~ e ~ capitalize(type[0]) ~ "() {\n";
			utils ~= "\t\treturn new Float" ~ to!string(type[1] * 8) ~ "Array(new Uint8Array(this.readBytes(" ~ to!string(type[1]) ~ ")).buffer, 0, 1)[0];\n";
			utils ~= "\t}\n\n";
		}
	}
	foreach(varint ; [tuple("short", 3, 15), tuple("int", 5, 31), tuple("long", 10, 63)]) {
		foreach(sign ; ["", "u"]) {
			// write
			utils ~= "\twriteVar" ~ sign ~ varint[0] ~ "(a) {\n";
			if(sign.length) {
				utils ~= "\t\twhile(a > 127) {\n";
				utils ~= "\t\t\tthis._buffer.push(a & 127 | 128);\n";
				utils ~= "\t\t\ta >>>= 7;\n";
				utils ~= "\t\t}\n";
				utils ~= "\t\tthis._buffer.push(a & 255);\n";
			} else {
				utils ~= "\t\tthis.writeVaru" ~ varint[0] ~ "(a >= 0 ? a * 2 : a * -2 - 1);\n";
			}
			utils ~= "\t}\n\n";
			// read
			utils ~= "\treadVar" ~ sign ~ varint[0] ~ "() {\n";
			if(sign.length) {
				utils ~= "\t\tvar limit = 0;\n";
				utils ~= "\t\tvar ret = 0;\n";
				utils ~= "\t\tdo {\n";
				utils ~= "\t\t\tret |= (this._buffer[0] & 127) << (limit * 7);\n";
				utils ~= "\t\t} while(this._buffer.shift() > 127 && ++limit < " ~ to!string(varint[1]) ~ ");\n";
				utils ~= "\t\treturn ret;\n";
			} else {
				utils ~= "\t\tvar ret = this.readVaru" ~ varint[0] ~ "();\n";;
				utils ~= "\t\treturn (ret & 1) == 0 ? ret / 2 : (-ret - 1) / 2;\n";
			}
			utils ~= "\t}\n\n";
		}
	}
	utils ~= "\tencodeString(string) {\n";
	utils ~= "\t\tvar conv = unescape(encodeURIComponent(string));\n";
	utils ~= "\t\tvar ret = [];\n";
	utils ~= "\t\tfor(var i in conv) ret.push(conv.charCodeAt(i));\n";
	utils ~= "\t\treturn ret;\n";
	utils ~= "\t}\n\n";
	utils ~= "\tdecodeString(array) {\n";
	utils ~= "\t\treturn decodeURIComponent(escape(String.fromCharCode.apply(null, array)));\n";
	utils ~= "\t}\n\n";
	utils ~= "}";
	mkdirRecurse("../src/js/sul/utils");
	write("../src/js/sul/utils/buffer.js", utils);

	// about
	write("../src/js/sul/utils/about.js", "const __sul = " ~ to!string(sulVersion) ~ ";");

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

		@property string convertName(string name) {
			if(name == "default") return "def";
			else return toCamelCase(name);
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
				if(cnt == "ubyte") return ret ~ "this.writeBytes(" ~ name ~ ");";
				else return ret ~ "for(var " ~ hash(name) ~ " in " ~ name ~ "){ " ~ createEncoding(nt, name ~ "[" ~ hash(name) ~ "]") ~ " }";
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
			else if(type == "string") return "var " ~ hash(name) ~"=this.encodeString(" ~ name ~"); " ~ createEncoding(prs.data.arrayLength, hash(name) ~ ".length") ~ " this.writeBytes(" ~ hash(name) ~ ");";
			else if(type == "uuid") return "this.writeBytes(" ~ name ~ ");";
			else if(type == "bytes") return "this.writeBytes(" ~ name ~ ");";
			else if(type == "bool") return "this.writeBigEndianByte(" ~ name ~ "?1:0);";
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
						ret ~= createDecoding(c.length, "var " ~ hash("\0" ~ name), c.endianness);
					} else {
						ret ~= createDecoding(prs.data.arrayLength, "var " ~ hash("\0" ~ name));
					}
					ret ~= " ";
				} else {
					ret ~= "var " ~ hash("\0" ~ name) ~ "=" ~ conv[lo+1..lc] ~ "; ";
				}
				if(cnt == "ubyte") return ret ~ name ~ "=this.readBytes(" ~ hash("\0" ~ name) ~ ");";
				else return ret ~ name ~ "=[]; for(var " ~ hash(name) ~ "=0;" ~ hash(name) ~ "<" ~ hash("\0" ~ name) ~ ";" ~ hash(name) ~ "++){ " ~ createDecoding(nt, name ~ "[" ~ hash(name) ~ "]") ~ " }";
			}
			auto ts = conv.lastIndexOf("<");
			if(ts > 0) {
				auto te = conv.lastIndexOf(">");
				string nt = conv[0..ts];
				string[] ret = [name ~ "={};"];
				foreach(i ; conv[ts+1..te]) {
					ret ~= createDecoding(nt, name ~ "." ~ i);
				}
				return ret.join(" ");
			}
			type = conv;
			if(type.startsWith("var")) return name ~ "=this.read" ~ capitalize(type) ~ "();";
			else if(type == "string") return name ~ "=this.decodeString(this.readBytes(" ~ createDecoding(prs.data.arrayLength, "")[1..$-1] ~ "));";
			else if(type == "uuid") return name ~ "=this.readBytes(16);";
			else if(type == "bytes") return name ~ "=Array.from(this._buffer); this._buffer=[];";
			else if(type == "bool") return name ~ "=this.readBigEndianByte()!==0;";
			else if(defaultTypes.canFind(type) || type == "triad") return name ~ "=this.read" ~ endiannessOf(type, e) ~ capitalize(type) ~ "();";
			else return name ~ "=" ~ convert(type) ~ ".fromBuffer(this._buffer); this._buffer=" ~ name ~ "._buffer;";
		}

		void writeFields(ref string data, string space, string className, Field[] fields, string cont, ptrdiff_t id=-1, string variantField="", Variant[] variants=[], string length="") {
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
			// variant's values
			if(variantField.length) {
				data ~= space ~ "// " ~ variantField.replace("_", " ") ~ " (variant)\n";
				foreach(variant ; variants) {
					data ~= space ~ "static get " ~ variant.name.toUpper() ~ "(){ return " ~ variant.value ~ "; }\n";
				}
				data ~= "\n";
			}
			string[] f;
			bool desc = false;
			foreach(i, field; fields) {
				immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
				f ~= name ~ "=" ~ (field.def.length ? constOf(field.def) : defaultValue(field.type));
				desc |= field.description.length != 0;
			}
			if(desc) {
				data ~= space ~ "/**\n";
				foreach(field ; fields) {
					if(field.description.length) {
						data ~= space ~ " * @param " ~ convertName(field.name) ~ "\n";
						foreach(d ; paramDoc(field.description)) {
							data ~= space ~ " *        " ~ d ~ "\n";
						}
					}
				}
				data ~= space ~ " */\n";
			}
			data ~= space ~ "constructor(" ~ f.join(", ") ~ ") {\n";
			data ~= space ~ "\tsuper();\n";
			foreach(i, field; fields) {
				immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
				data ~= space ~ "\tthis." ~ name ~ " = " ~ name ~ ";\n";
			}
			data ~= space ~ "}\n\n";
			if(variantField.length) {
				// constructor for variants

			}
			// encode
			{
				data ~= space ~ "/** @return {Uint8Array} */\n";
				data ~= space ~ "encode() {\n";
				data ~= space ~ "\tthis._buffer = [];\n";
				if(id >= 0) data ~= space ~ "\t" ~ createEncoding(prs.data.id, to!string(id)) ~ "\n";
				foreach(i, field; fields) {
					bool c = field.condition != "";
					immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
					data ~= space ~ "\t" ~ (c ? "if(" ~ toCamelCase(field.condition) ~ "){ " : "") ~ createEncoding(field.type, "this." ~ name, field.endianness) ~ (c ? " }" : "") ~ "\n";
				}
				if(variantField.length) {
					data ~= "\tswitch(this." ~ toCamelCase(variantField) ~ ") {\n";
					foreach(variant ; variants) {
						data ~= "\t\tcase " ~ variant.value ~ ":\n";
						foreach(i, field; fields) {
							bool c = field.condition != "";
							immutable name = field.name == "?" ? "unknown" ~ to!string(i + fields.length) : convertName(field.name);
							data ~= space ~ "\t" ~ (c ? "if(" ~ toCamelCase(field.condition) ~ "){ " : "") ~ createEncoding(field.type, "this." ~ name, field.endianness) ~ (c ? " }" : "") ~ "\n";
						}
						data ~= "\t\t\tbreak;\n";
					}
					data ~= "\t\tdefault: break;\n";
					data ~= "\t}\n";
				}
				if(length.length) {
					data ~= space ~ "\tvar _length = this._buffer.length;\n";
					data ~= space ~ "\t" ~ createEncoding(length, "_length") ~ "\n";
					data ~= space ~ "\tvar _length_array = [];\n";
					data ~= space ~ "\twhile(this._buffer.length > _length) _length_array.push(this._buffer.pop());\n";
					data ~= space ~ "\twhile(_length_array.length > 0) this._buffer.unshift(_length_array.shift());\n";
				}
				data ~= space ~ "\treturn new Uint8Array(this._buffer);\n";
				data ~= space ~ "}\n\n";
			}
			// decode
			{
				data ~= space ~ "/** @param {(Uint8Array|Array)} buffer */\n";
				data ~= space ~ "decode(_buffer) {\n";
				data ~= space ~ "\tthis._buffer = Array.from(_buffer);\n";
				if(length.length) {
					data ~= space ~ "\t" ~ createDecoding(length, "var _length") ~ "\n";
					data ~= space ~ "\t_buffer = this._buffer.slice(_length);\n";
					data ~= space ~ "\tif(this._buffer.length > _length) this._buffer.length = _length;\n";
				}
				if(id >= 0) data ~= space ~ "\t" ~ createDecoding(prs.data.id, "var _id") ~ "\n";
				foreach(i, field; fields) {
					bool c = field.condition != "";
					immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
					data ~= space ~ "\t" ~ (c ? "if(" ~ toCamelCase(field.condition) ~ "){ " : "") ~ createDecoding(field.type, "this." ~ name, field.endianness) ~ (c ? " }" : "") ~ "\n";
				}
				if(variantField.length) {
					data ~= space ~ "\tswitch(this." ~ toCamelCase(variantField) ~ ") {\n";
					foreach(variant ; variants) {
						data ~= space ~ "\t\tcase " ~ variant.value ~ ":\n";
						foreach(i, field; variant.fields) {
							bool c = field.condition != "";
							immutable name = field.name == "?" ? "unknown" ~ to!string(i + fields.length) : convertName(field.name);
							data ~= space ~ "\t\t\t" ~ (c ? "if(" ~ toCamelCase(field.condition) ~ "){ " : "") ~ createDecoding(field.type, "this." ~ name, field.endianness) ~ (c ? " }" : "") ~ "\n";
						}
						data ~= space ~ "\t\t\tbreak;\n";
					}
					data ~= space ~ "\t\tdefault: break;\n";
					data ~= space ~ "\t}\n";
				}
				if(length.length) {
					data ~= space ~ "\tthis._buffer = _buffer;\n";
				}
				data ~= space ~ "\treturn this;\n";
				data ~= space ~ "}\n\n";
				// from buffer
				data ~= space ~ "/** @param {(Uint8Array|Array)} buffer */\n";
				data ~= space ~ "static fromBuffer(buffer) {\n";
				data ~= space ~ "\treturn new " ~ cont ~ "." ~ className ~ "().decode(buffer);\n";
				data ~= space ~ "}\n\n";
			}
			{
				data ~= space ~ "/** @return {string} */\n";
				data ~= space ~ "toString() {\n";
				string[] s;
				foreach(i, field; fields) {
					immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
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
				data ~= "\t" ~ toPascalCase(type.name) ~ ": class extends Buffer {\n\n";
				writeFields(data, "\t\t", toPascalCase(type.name), type.fields, "Types", -1, "", [], type.length);
				data ~= "\t}" ~ (i != prs.data.types.length - 1 ? "," : "") ~ "\n\n";
			}
			data ~= "}\n\n";
			data ~= "//export { Types }";
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
				data ~= "\t" ~ toPascalCase(packet.name) ~ ": class extends Buffer {\n\n";
				data ~= "\t\tstatic get ID(){ return " ~ packet.id.to!string ~ "; }\n\n";
				data ~= "\t\tstatic get CLIENTBOUND(){ return " ~ packet.clientbound.to!string ~ "; }\n";
				data ~= "\t\tstatic get SERVERBOUND(){ return " ~ packet.serverbound.to!string ~ "; }\n\n";
				writeFields(data, "\t\t", toPascalCase(packet.name), packet.fields, toPascalCase(section.name), packet.id, packet.variantField, packet.variants);
				data ~= "\t}" ~ (i != section.packets.length ? "," : "") ~ "\n\n";
			}
			data ~= "}\n\n";
			data ~= "//export { " ~ toPascalCase(section.name) ~ " };";
			write("../src/js/sul/protocol/" ~ game ~ "/" ~ section.name ~ ".js", data, "protocol/" ~ game);
		}
	}
	
}

string defaultValue(string type) {
	if(type == "float" || type == "double") return ".0";
	else if(type == "bool") return "false";
	else if(type == "string") return "\"\"";
	else if(type == "uuid") return "new Uint8Array(16)";
	else if(type.endsWith("]")) {
		if(type[$-2] == '[') return "[]";
		else {
			immutable size = type[type.lastIndexOf("[")+1..$-1];
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
		}
	} else if(type.indexOf("<") != -1) return "{" ~ type.matchFirst(ctRegex!`<[a-z]+>`).hit[1..$-1].split("").join(":0,") ~ ":0}";
	else if(["byte", "ubyte", "short", "ushort", "triad", "int", "uint", "long", "ulong"].canFind(type) || type.startsWith("var")) return "0";
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
	bool empty = false;
	foreach(s ; desc.replaceAll(ctRegex!`\[([a-zA-Z0-9\.]+)\]\([a-zA-Z0-9_\-\#\.\:]+\)`, "{$1}").matchFirst(ctRegex!"[\\r]{0,1}\\n(\\r|\\n|\\#|\\`)").pre.replaceAll(ctRegex!`\n|\r\n`, "  ").split(" ")) {
		s = s.strip;
		if(s.length) {
			empty = false;
			length += s.length;
			next ~= s;
			if(length >= 80) add();
		} else if(!empty) {
			empty = true;
			add();
		}
	}
	if(next.length) add();
	return data;
}
