module d;

import std.algorithm : canFind;
import std.ascii : newline;
import std.conv : to;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.path : dirSeparator;
import std.string;
import std.typecons;

import all;

void d(Attributes[string] attributes, Protocols[string] protocols, Metadatas[string] metadatas, Creative[string] creative) {

	mkdirRecurse("../src/d/sul/attributes");
	mkdirRecurse("../src/d/sul/metadata");
	mkdirRecurse("../src/d/sul/utils");

	// write varints
	write("../src/d/sul/utils/var.d", q{
module sul.utils.var;

import std.traits : isNumeric, isIntegral, isSigned, isUnsigned, Unsigned;

struct var(T) if(isNumeric!T && isIntegral!T && T.sizeof > 1) {
	
	alias U = Unsigned!T;
	
	public static immutable U MASK = U.max - 0x7F;
	public static immutable size_t MAX_BYTES = T.sizeof * 8 / 7 + (T.sizeof * 8 % 7 == 0 ? 0 : 1);
	public static immutable size_t RIGHT_SHIFT = (T.sizeof * 8) - 1;
	
	public static pure nothrow @safe ubyte[] encode(T value) {
		ubyte[] buffer;
		static if(isUnsigned!T) {
			U unsigned = value;
		} else {
			U unsigned;
			if(value >= 0) {
				unsigned = cast(U)(value << 1);
			} else if(value < 0) {
				unsigned = cast(U)((-value << 1) - 1);
			}
		}
		while((unsigned & MASK) != 0) {
			buffer ~= unsigned & 0x7F | 0x80;
			unsigned >>>= 7;
		}
		buffer ~= unsigned & 0xFF;
		return buffer;
	}

	public static pure nothrow @trusted T decode(ubyte[] buffer, size_t index=0) {
		return decode(buffer, &index);
	}
	
	public static pure nothrow @safe T decode(ubyte[] buffer, size_t* index) {
		if(buffer.length <= *index) return T.init;
		U unsigned = 0;
		size_t j, k;
		do {
			k = buffer[*index];
			unsigned |= (k & 0x7F) << (j++ * 7);
		} while(++*index < buffer.length && j < MAX_BYTES && (k & 0x80) != 0);
		static if(isUnsigned!T) {
			return unsigned;
		} else {
			T value = unsigned >> 1;
			if(unsigned & 1) {
				value++;
				return -value;
			} else {
				return value;
			}
		}
	}

	public static pure nothrow @trusted T fromBuffer(ref ubyte[] buffer) {
		size_t index = 0;
		auto ret = decode(buffer, &index);
		buffer = buffer[index..$];
		return ret;
	}
	
	public enum stringof = "var" ~ T.stringof;
	
}

alias varshort = var!short;

alias varushort = var!ushort;

alias varint = var!int;

alias varuint = var!uint;

alias varlong = var!long;

alias varulong = var!ulong;
	});

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
	
	// attributes
	foreach(string game, Attributes attrs; attributes) {
		string data = "module sul.attributes." ~ game ~ ";\n\nimport std.typecons : Tuple;\n\n" ~
			"alias Attribute = Tuple!(string, \"name\", float, \"min\", float, \"max\", float, \"def\");\n\n" ~ 
				"struct Attributes {\n\n\t@disable this();\n\n";
		foreach(attr; attrs.data) {
			data ~= "\tenum " ~ toCamelCase(attr.id) ~ " = Attribute(\"" ~ attr.name ~ "\", " ~ attr.min.to!string ~ ", " ~ attr.max.to!string ~ ", " ~ attr.def.to!string ~ ");\n\n";
		}
		write("../src/d/sul/attributes/" ~ game ~ ".d", data ~ "}", "attributes/" ~ game);
	}
	
	//TODO creative inventory

	// protocol
	foreach(string game, Protocols prts; protocols) {

		mkdirRecurse("../src/d/sul/protocol/" ~ game);
		
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

		immutable defaultEndianness = "Endian." ~ toCamelCase(prts.data.endianness["*"]);

		string endiannessOf(string type, string over="") {
			if(over.length) return "Endian." ~ toCamelCase(over);
			auto e = type in prts.data.endianness;
			if(e) return "Endian." ~ toCamelCase(*e);
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
						ret ~= createEncoding(c.length, name ~ ".length.to!" ~ convertType(c.length), c.endianness);
					} else {
						ret ~= createEncoding(prts.data.arrayLength, name ~ ".length.to!" ~ arrayLength);
					}
					ret ~= " ";
				}
				if(nt == "ubyte") return ret ~= "_buffer~=" ~ name ~ ";";
				else return ret ~ "foreach(" ~ hash(name) ~ ";" ~ name ~ "){ " ~ createEncoding(type[0..lo], hash(name)) ~ " }";
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
			if(type.startsWith("var")) return "_buffer~=" ~ type ~ ".encode(" ~ name ~ ");";
			else if(type == "string") return "ubyte[] " ~ hash(name) ~ "=cast(ubyte[])" ~ name ~ "; " ~ createEncoding("ubyte[]", hash(name));
			else if(type == "uuid") return "_buffer~=" ~ name ~ ".data;";
			else if(type == "bytes" || type == "ubyte") return "_buffer~=" ~ name ~ ";";
			else if(type == "triad") return "_buffer.length+=3; " ~ (endiannessOf("triad", e) == "bigEndian" ? ("_buffer[$-1]=" ~ name ~ "&255; _buffer[$-2]=(" ~ name ~ ">>8)&255; _buffer[$-3]=(" ~ name ~ ">>16)&255"): ("_buffer[$-3]=" ~ name ~ "&255; _buffer[$-2]=(" ~ name ~ ">>8)&255; _buffer[$-1]=(" ~ name ~ ">>16)&255")) ~ ";";
			else if(defaultTypes.canFind(type)) return "_buffer.length+=" ~ type ~ ".sizeof; write!(" ~ type ~ ", " ~ endiannessOf(type, e) ~ ")(_buffer, " ~ name ~ ", _buffer.length-" ~ type ~ ".sizeof);";
			else return name ~ ".encode(_buffer);";
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
				if(nt == "ubyte") return ret ~= "if(_buffer.length>=*_index+" ~ name ~ ".length){ " ~ name ~ "=_buffer[*_index..*_index+" ~ name ~ ".length].dup; *_index+=" ~ name ~ ".length; }";
				else return ret ~ "foreach(ref " ~ hash(name) ~ ";" ~ name ~ "){ " ~ createDecoding(type[0..lo], hash(name)) ~ " }";
			}
			auto ts = conv.lastIndexOf("<");
			if(ts > 0) {
				auto te = conv.lastIndexOf(">");
				string nt = conv[0..ts];
				string ret;
				foreach(i ; conv[ts+1..te]) {
					ret ~= createDecoding(nt, name ~ "." ~ i);
				}
				return ret;
			}
			type = conv;
			if(type.startsWith("var")) return name ~ "=" ~ type ~ ".decode(_buffer, *_index);";
			else if(type == "string") return "ubyte[] " ~ hash(name) ~ "; " ~ createDecoding("ubyte[]", hash(name)) ~ "; " ~ name ~ "=cast(string)" ~ hash(name) ~ ";";
			else if(type == "uuid") return "if(_buffer.length>=*_index+16){ ubyte[16] " ~ hash(name) ~ "=buffer[*_index..*_index+16].dup; *_index+=16; " ~ name ~ "=UUID(" ~ hash(name) ~ "); }";
			else if(type == "bytes") return name ~ "=_buffer[*_index..$].dup; *_index=buffer.length;";
			else if(type == "triad") return "if(_buffer.length>=*_index+3){ " ~ name ~ "=" ~ (endiannessOf(e) == "bigEndian" ? "_buffer[_*index+2]|(buffer[*_index+1]<<8)|(buffer[*_index]<<16)" : "buffer[*_index]|(buffer[*_index+1]<<8)|(buffer[*_index+2]<<16)") ~ "; *_index+=3; }";
			else if(defaultTypes.canFind(type)) return "if(_buffer.length>=*_index+" ~ type ~ ".sizeof){ " ~ name ~ "=peek!(" ~ type ~ ", " ~ endiannessOf(type, e) ~ ")(_buffer, _index); }";
			else return name ~ ".decode(_buffer, _index);";
		}

		void writeFields(ref string data, string space, Field[] fields, bool hasId) { // hasId is true when fields belong to a packet, false when a type
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
			// fields
			foreach(i, field; fields) {
				if(field.description.length) {
					if(i != 0) data ~= "\n";
					data ~= ddoc(space, field.description);
				}
				data ~= space ~ "public " ~ convertType(field.type) ~ " " ~ (field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name)) ~ ";\n";
				if(i == fields.length - 1) data ~= "\n";
			}
			// encoding
			if(hasId) {
				data ~= space ~ "public ubyte[] encode(bool writeId=true)() {\n";
				data ~= space ~ "\tubyte[] _buffer;\n";
				data ~= space ~ "\tstatic if(writeId){ " ~ createEncoding(prts.data.id, "ID") ~ " }\n";
			} else {
				data ~= space ~ "public ubyte[] encode() {\n" ~ space ~ "\tubyte[] _buffer;\n";
				data ~= space ~ "\tthis.encode(_buffer);\n";
				data ~= space ~ "\treturn _buffer;\n" ~ space ~ "}\n\n";
				data ~= space ~ "public ubyte[] encode(ref ubyte[] _buffer) {\n";
			}
			foreach(i, field; fields) {
				bool c = field.condition.length != 0;
				data ~= space ~ "\t" ~ (c ? "if(" ~ field.condition ~ "){ " : "") ~ createEncoding(field.type, field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.endianness) ~ (c ? " }" : "") ~ "\n";
			}
			data ~= space ~ "\treturn _buffer;\n" ~ space ~ "}\n\n";
			// decoding
			if(hasId) {
				data ~= space ~ "public typeof(this) decode(bool readId=true)(ubyte[] _buffer, size_t _index=0) {\n" ~ space ~ "\treturn this.decode!readId(_buffer, &_index);\n" ~ space ~ "}\n\n";
				data ~= space ~ "public typeof(this) decode(bool readId=true)(ubyte[] _buffer, size_t* _index) {\n";
				data ~= space ~ "\tstatic if(readId){ typeof(ID) _id; " ~ createDecoding(prts.data.id, "_id") ~ " }\n";
			} else {
				data ~= space ~ "public typeof(this) decode(ubyte[] _buffer, size_t* _index) {\n";
			}
			foreach(i, field; fields) {
				bool c = field.condition.length != 0;
				data ~= space ~ "\t" ~ (c ? "if(" ~ field.condition ~ "){ " : "") ~ createDecoding(field.type, field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.endianness) ~ (c ? " }" : "") ~ "\n";
			}
			data ~= space ~ "\treturn this;\n" ~ space ~ "}\n\n";
		}

		// types
		string t = "module sul.protocol." ~ game ~ ".types;\n\n";
		t ~= "import std.bitmanip : write, peek;\nimport std.conv : to;\nimport std.system : Endian;\nimport std.typecons : Tuple;\nimport std.uuid : UUID;\n\nimport sul.utils.var;\n\n";
		foreach(type ; prts.data.types) {
			if(type.description.length) t ~= ddoc("", type.description);
			t ~= "struct " ~ toPascalCase(type.name) ~ " {\n\n";
			writeFields(t, "\t", type.fields, false);
			t ~= "}\n\n";
		}
		write("../src/d/sul/protocol/" ~ game ~ "/types.d", t, "protocol/" ~ game);

		// sections
		string s = "module sul.protocol." ~ game ~ ";\n\npublic import sul.protocol." ~ game ~ ".types;\n\n";
		foreach(section ; prts.data.sections) {
			s ~= "public import sul.protocol." ~ game ~ "." ~ section.name ~ ";\n";
			string data = "module sul.protocol." ~ game ~ "." ~ section.name ~ ";\n\n";
			data ~= "import std.bitmanip : write, peek;\nimport std.conv : to;\nimport std.system : Endian;\nimport std.typetuple : TypeTuple;\nimport std.typecons : Tuple;\nimport std.uuid : UUID;\n\n";
			data ~= "import sul.utils.var;\n\nimport types = sul.protocol." ~ game ~ ".types;\n\n";
			string[] names;
			foreach(packet ; section.packets) names ~= toPascalCase(packet.name);
			data ~= "alias Packets = TypeTuple!(" ~ names.join(", ") ~ ");\n\n";
			foreach(packet ; section.packets) {
				if(packet.description.length) data ~= ddoc("", packet.description);
				data ~= "struct " ~ toPascalCase(packet.name) ~ " {\n\n";
				data ~= "\tpublic enum " ~ id ~ " ID = " ~ to!string(packet.id) ~ ";\n\n";
				data ~= "\tpublic enum bool CLIENTBOUND = " ~ to!string(packet.clientbound) ~ ";\n";
				data ~= "\tpublic enum bool SERVERBOUND = " ~ to!string(packet.serverbound) ~ ";\n\n";
				writeFields(data, "\t", packet.fields, true);
				foreach(variant ; packet.variants) {
					if(variant.description.length) data ~= ddoc("\t\t", variant.description);
					data ~= "\tpublic struct " ~ toPascalCase(variant.name) ~ " {\n\n";
					data ~= "\t\tpublic enum typeof(" ~ convertName(packet.variantField) ~ ") " ~ toUpper(packet.variantField) ~ " = " ~ variant.value ~ ";\n\n";
					writeFields(data, "\t\t", variant.fields, false);
					data ~= "\t}\n\n";
				}
				data ~= "}\n\n";
			}
			write("../src/d/sul/protocol/" ~ game ~ "/" ~ section.name ~ ".d", data, "protocol/" ~ game);
		}
		write("../src/d/sul/protocol/" ~ game ~ "/package.d", s, "protocol/" ~ game);

	}

	// metadata
	foreach(string game, Metadatas m; metadatas) {

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
			}
			if(ret == "") ret = "sul.protocol." ~ game ~ ".types." ~ toPascalCase(t);
			return ret ~ (array >= 0 ? type[array..$] : "");
		}

		string data = "module sul.metadata." ~ game ~ ";\n\n";
		data ~= "static import sul.protocol." ~ game ~ ".types;";
		//TODO types
		//TODO encoding
		data ~= "struct Metadata {\n\n";
		foreach(type ; m.data.metadatas) {
			if(type.flags.length) {

			} else {
				data ~= "\tpublic " ~ convertType(type.type) ~ " " ~ toCamelCase(type.name) ~ (type.def.length ? " = " ~ type.def : "") ~ ";\n\n";
			}
		}
		data ~= "}";
		write("../src/d/sul/metadata/" ~ game ~ ".d", data, "metadata/" ~ game);
	}

}


string ddoc(string space, string description) {
	import std.regex : matchFirst, ctRegex;
	bool search = true;
	while(search) {
		auto m = matchFirst(description, ctRegex!`\[[a-zA-Z0-9 \.]{2,30}\]\([a-zA-Z0-9\#:\/-]{2,64}\)`);
		if(m) {
			description = m.pre ~ m.hit[1..m.hit.indexOf("]")] ~ m.post;
		} else {
			search = false;
		}
	}
	return space ~ "/**\n" ~ ddocImpl(space, description.split(" ")) ~ space ~ " */\n";
}

string ddocImpl(string space, string[] words) {
	size_t length;
	string[] ret;
	while(length < 80 && words.length) {
		ret ~= words[0];
		length += words[0].length + 1;
		words = words[1..$];
	}
	return space ~ " * " ~ ret.join(" ") ~ "\n" ~ (words.length ? ddocImpl(space, words) : "");
}
