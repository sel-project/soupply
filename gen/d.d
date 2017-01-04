module d;

import std.algorithm : canFind, min;
import std.ascii : newline;
import std.base64 : Base64URL;
import std.file;
import std.json;
import std.path : dirSeparator;
import std.string;
import std.typecons;

import all;

string hash(string name) {
	return Base64URL.encode(cast(ubyte[])name).replace("-", "_").replace("=", "")[0..min($, 16)];
}

void d(JSONValue[string] jsons) {

	mkdirRecurse("../src/d/sul/types");

	// write varints
	write("../src/d/sul/types/var.d", q{
module sul.types.var;

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
			//U unsigned = cast(U)((value << 1) ^ (value >> RIGHT_SHIFT));
			U unsigned = cast(U)(value << 1);
			if(value < 0) {
				unsigned |= 1;
				unsigned = -unsigned;
			}
		}
		while((unsigned & MASK) != 0) {
			buffer ~= unsigned & 0x7F | 0x80;
			unsigned >>>= 7;
		}
		buffer ~= unsigned & 0xFF;
		return buffer;
	}
	
	public static pure nothrow @safe T fromBuffer(ref ubyte[] buffer) {
		if(buffer.length == 0) return T.init;
		U unsigned = 0;
		size_t j, k;
		do {
			k = buffer[0];
			buffer = buffer[1..$];
			unsigned |= (k & 0x7F) << (j++ * 7);
		} while(buffer.length != 0 && j < MAX_BYTES && (k & 0x80) != 0);
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
	
	public enum stringof = "var" ~ T.stringof;
	
}

alias varshort = var!short;

alias varushort = var!ushort;

alias varint = var!int;

alias varuint = var!uint;

alias varlong = var!long;

alias varulong = var!ulong;
	});
	
	enum string[string] defaultAliases = [
		"uuid": "UUID",
		"remaining_bytes": "ubyte[]",
		"triad": "int",
		"varshort": "short",
		"varushort": "ushort",
		"varint": "int",
		"varuint": "uint",
		"varlong": "long",
		"varulong": "ulong"
	];

	// attributes
	foreach(string game, JSONValue attributes; jsons["attributes"].object) {
		string data = `module sul.attributes.` ~ game ~ `;` ~ newline ~ newline ~
			`import std.typecons : Tuple;` ~ newline ~ newline ~
			`alias Attribute = Tuple!(string, "name", float, "min", float, "max", float, "def");` ~ newline ~ newline ~
			`struct Attributes {` ~ newline ~ newline ~ `	@disable this();` ~ newline ~ newline;
		foreach(string name, JSONValue value; attributes.object) {
			auto obj = value.object;
			data ~= `	enum ` ~ toCamelCase(name) ~ ` = Attribute("` ~ obj["name"].str ~ `", ` ~ obj["min"].toString() ~ `, ` ~ obj["max"].toString() ~ `, ` ~ obj["default"].toString() ~ `);` ~ newline ~ newline;
		}
		if(!exists("../src/d/sul/attributes")) mkdir("../src/d/sul/attributes");
		write("../src/d/sul/attributes/" ~ game ~ ".d", data ~ "}" ~ newline);
	}

	// constants
	foreach(string game, JSONValue constants; jsons["constants"].object) {
		string data = `module sul.constants.` ~ game ~ `;` ~ newline ~ newline ~
			`import sul.types.var;` ~ newline ~ newline ~
			`static struct Constants {` ~ newline ~ newline;
		foreach(string name, JSONValue value; constants.object) {
			JSONValue[] fields = null; // from protocol's
			foreach(JSONValue category ; jsons["protocol"].object[game].object["packets"].object) {
				foreach(string packet_name, JSONValue packet; category.object) {
					if(packet_name == name) {
						fields = packet.object["fields"].array;
						break;
					}
				}
			}
			data ~= `	static struct ` ~ toPascalCase(name) ~ ` {` ~ newline ~ newline;
			foreach(string field, JSONValue v; value.object) {
				data ~= `		static struct ` ~ toCamelCase(field) ~ ` {` ~ newline ~ newline;
				string type = "";
				if(fields !is null) {
					foreach(packet_field ; fields) {
						auto obj = packet_field.object;
						if(obj["name"].str == field) {
							type = obj["type"].str;
							auto conv = type in defaultAliases;
							if(conv) type = *conv;
							type ~= " ";
							break;
						}
					}
				}
				foreach(string var, JSONValue content; v.object) {
					data ~= `			enum ` ~ type ~ toCamelCase(var) ~ ` = ` ~ content.toString() ~ `;` ~ newline;
				}
				data ~= newline ~ `		}` ~ newline ~ newline;
			}
			data ~= `	}` ~ newline ~ newline;
		}
		if(!exists("../src/d/sul/constants")) mkdir("../src/d/sul/constants");
		write("../src/d/sul/constants/" ~ game ~ ".d", data ~ "}" ~ newline);
	}

	// creative
	foreach(string game, JSONValue creative; jsons["creative"].object) {
		string data = `module sul.creative.` ~ game ~ `;` ~ newline ~ newline ~
			`import std.typecons : Tuple;` ~ newline ~ newline ~
			`alias Enchantment = Tuple!(ubyte, "type", ubyte, "level");` ~ newline ~
			`alias Item = Tuple!(string, "name", ushort, "id", ushort, "meta", Enchantment, "enchantment");` ~ newline ~ newline ~
			`enum Item[] Creative = [` ~ newline ~ newline;
		foreach(JSONValue item ; creative.array) {
			auto obj = item.object;
			auto name = "name" in obj;
			auto id = "id" in obj;
			auto meta = "meta" in obj;
			auto ench = "enchantment" in obj;
			if(name && id) {
				data ~= `	Item(` ~ name.toString() ~ `, ` ~ id.toString() ~ `, ` ~ (meta ? meta.toString() : "0") ~ (ench ? `, Enchantment(` ~ ench.object["type"].toString() ~ `, ` ~ ench.object["level"].toString() ~ `)` : "") ~ `),` ~ newline;
			}
		}
		if(!exists("../src/d/sul/creative")) mkdir("../src/d/sul/creative");
		write("../src/d/sul/creative/" ~ game ~ ".d", data ~ newline ~ "}" ~ newline);
	}

	// protocol
	{
		enum defaultTypes = ["bool", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "char", "string", "varint", "varuint", "varlong", "varulong", "UUID"];

		foreach(string game, JSONValue protocol; jsons["protocol"].object) {

			string data = `module sul.protocol.` ~ game ~ `;` ~ newline ~ newline ~
				`import std.bitmanip : read, write;` ~ newline ~
				`import std.conv : to;` ~ newline ~
				`import std.uuid : UUID;` ~ newline ~
				`import std.system : Endian;` ~ newline ~
				`import std.typecons : Tuple, tuple;` ~ newline ~ newline ~
				`import sul.types.var;` ~ newline ~ newline;

			string[string] aliases;

			Tuple!(string, string)[string] custom_arrays; // "name" = {"length_type", "length_endianness"}

			string endianness = "bigEndian";
			string[] changed;

			@property string convertAliases(string type) {
				auto a = type in aliases;
				return a ? *a : type;
			}

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
				} else if(t in aliases) {
					return convertType(aliases[t] ~ (array >= 0 ? type[array..$] : ""));
				} else if(defaultTypes.canFind(t)) {
					ret = t;
				}
				if(ret == "") ret = "Types." ~ toPascalCase(t);
				return ret ~ (array >= 0 ? type[array..$] : "");
			}

			@property string convertName(string name) {
				if(name == "version") return "vers";
				else if(name == "body") return "body_";
				else if(name == "default") return "def";
				else return toCamelCase(name);
			}

			auto encoding = protocol["encoding"].object;

			immutable array_length = encoding["array_length"].str;
			immutable array_length_c = convertType(array_length);

			// endianness
			auto end = "endianness" in encoding;
			if(end) {
				if(end.type == JSON_TYPE.STRING) {
					endianness = toCamelCase(end.str.replace("-", "_"));
				} else if(end.type == JSON_TYPE.OBJECT) {
					auto eo = end.object;
					auto def = "*" in eo;
					if(def) endianness = toCamelCase(def.str.replace("-", "_"));
					foreach(string type, JSONValue value; eo) {
						if(type != "*") {
							auto e = toCamelCase(value.str);
							if(e != endianness) changed ~= type;
						}
					}
				}
			}
			string not_endian = endianness == "bigEndian" ? "littleEndian" : "bigEndian";

			string endiannessOf(string type, string over="") {
				if(over.length) return "Endian." ~ toCamelCase(over);
				if(changed.canFind(type)) return "Endian." ~ not_endian;
				else return "Endian." ~ endianness;
			}

			string createEncoding(string type, string name, string e="") {
				auto conv = convertAliases(type); // only user-defined aliases
				auto lo = conv.lastIndexOf("[");
				if(lo > 0) {
					string ret = "";
					auto lc = conv.lastIndexOf("]");
					string nt = conv[0..lo];
					if(lo == lc - 1) {
						auto ca = type in custom_arrays;
						if(ca) {
							auto c = *ca;
							ret ~= createEncoding(c[0], name ~ ".length.to!" ~ convertType(c[0]), c[1]);
						} else {
							ret ~= createEncoding(array_length, name ~ ".length.to!" ~ array_length_c);
						}
					}
					if(nt == "ubyte") return ret ~= " buffer~=" ~ name ~ ";";
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
				if(type.startsWith("var")) return "buffer~=" ~ type ~ ".encode(" ~ name ~ ");";
				else if(type == "string") return "ubyte[] " ~ hash(name) ~ "=cast(ubyte[])" ~ name ~ "; " ~ createEncoding("ubyte[]", hash(name));
				else if(type == "uuid") return "buffer~=" ~ name ~ ".data;";
				else if(type == "remaining_bytes") return "buffer~=" ~ name ~ ";";
				else if(type == "triad") return "buffer.length+=3; " ~ (endiannessOf("triad", e) == "bigEndian" ? ("buffer[$-1]=" ~ name ~ "&255; buffer[$-2]=(" ~ name ~ ">>8)&255; buffer[$-3]=(" ~ name ~ ">>16)&255"): ("buffer[$-3]=" ~ name ~ "&255; buffer[$-2]=(" ~ name ~ ">>8)&255; buffer[$-1]=(" ~ name ~ ">>16)&255")) ~ ";";
				else if(defaultTypes.canFind(type)) return "buffer.length+=" ~ type ~ ".sizeof; write!(" ~ type ~ ", " ~ endiannessOf(type, e) ~ ")(buffer, " ~ name ~ ", buffer.length-" ~ type ~ ".sizeof);";
				else return name ~ ".encode(buffer);";
			}

			string createDecoding(string type, string name, string e="") {
				auto conv = convertAliases(type);
				auto lo = conv.lastIndexOf("[");
				if(lo > 0) {
					string ret = "";
					auto lc = conv.lastIndexOf("]");
					if(lo == lc - 1) {
						auto ca = type in custom_arrays;
						if(ca) {
							auto c = *ca;
							ret ~= createDecoding(c[0], name ~ ".length", c[1]);
						} else {
							ret ~= createDecoding(array_length, name ~ ".length");
						}
					}
					string nt = conv[0..lo];
					if(nt == "ubyte") return ret ~= "if(buffer.length>=" ~ name ~ ".length){ " ~ name ~ "=buffer[0.." ~ name ~ ".length]; buffer=buffer[" ~ name ~ ".length..$]; }";
					else return ret ~ "foreach(ref " ~ hash(name) ~ ";" ~ name ~ "){ " ~ createDecoding(type[0..lo], hash(name)) ~ "}";
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
				if(type.startsWith("var")) return name ~ "=" ~ type ~ ".fromBuffer(buffer);";
				else if(type == "string") return "ubyte[] " ~ hash(name) ~ "; " ~ createDecoding("ubyte[]", hash(name)) ~ "; " ~ name ~ "=cast(string)" ~ hash(name) ~ ";";
				else if(type == "uuid") return "if(buffer.length>=16){ ubyte[16] " ~ hash(name) ~ "=buffer[0..16]; buffer=buffer[16..$]; " ~ name ~ "=UUID(" ~ hash(name) ~ "); }";
				else if(type == "remaining_bytes") return name ~ "=buffer.dup; buffer.length=0;";
				else if(type == "triad") return "if(buffer.length>=3){ " ~ name ~ "=" ~ (endiannessOf(e) == "bigEndian" ? "buffer[2]|(buffer[1]<<8)|(buffer[0]<<16)" : "buffer[0]|(buffer[1]<<8)|(buffer[2]<<16)") ~ "; buffer=buffer[3..$]; }";
				else if(defaultTypes.canFind(type)) return "if(buffer.length>=" ~ type ~ ".sizeof){ " ~ name ~ "=read!(" ~ type ~ ", " ~ endiannessOf(type, e) ~ ")(buffer); }";
				else return name ~ ".decode(buffer);";
			}

			// types
			data ~= `static struct Types {` ~ newline ~ newline;
			auto types = "types" in protocol["encoding"].object;
			if(types) {
				foreach(string type_name, JSONValue type; types.object) {
					if(type.type == JSON_TYPE.STRING) {
						aliases[type_name] = type.str;
					}
				}
				foreach(string type_name, JSONValue type; types.object) {
					if(type.type == JSON_TYPE.OBJECT) {
						auto type_obj = type.object;
						if(type_obj["type"].str == "struct") {
							type_name = toPascalCase(type_name);
							string encode, decode;
							data ~= `	static struct ` ~ type_name ~ ` {` ~ newline ~ newline;
							foreach(JSONValue field ; type_obj["fields"].array) {
								auto obj = field.object;
								string t = obj["type"].str;
								string n = convertName(obj["name"].str);
								auto e = "endianness" in obj;
								auto cond = "when" in obj;
								data ~= `		public ` ~ convertType(t) ~ ` ` ~ n ~ `;` ~ newline;
								encode ~= `			` ~ (cond ? `if(` ~ toCamelCase(cond.str) ~ `){ ` : "") ~ createEncoding(t, n, e ? e.str : "") ~ (cond ? " }" : "") ~ newline;
								decode ~= `			` ~ (cond ? `if(` ~ toCamelCase(cond.str) ~ `){ ` : "") ~ createDecoding(t, n, e ? e.str : "") ~ (cond ? " }" : "") ~ newline;
							}
							data ~= newline ~ `		public void encode(ref ubyte[] buffer) {` ~ newline ~ encode ~ `		}` ~ newline;
							data ~= newline ~ `		public void decode(ref ubyte[] buffer) {` ~ newline ~ decode ~ `		}` ~ newline;
							data ~= newline ~ `	}` ~ newline ~ newline;
						} else if(type_obj["type"].str == "array") {
							aliases[type_name] = type_obj["base"].str ~ "[]";
							auto e = "endianness" in type_obj;
							custom_arrays[type_name] = tuple(type_obj["length"].str, e ? e.str.replace("-", "_") : "");
						}
					}
				}
			}
			data ~= `}` ~ newline ~ newline;
			
			immutable id = encoding["id"].str;
			immutable id_c = convertType(id);

			// packets
			data ~= `static struct Packets {` ~ newline ~ newline;
			foreach(string category, JSONValue cat_json; protocol["packets"].object) {
				data ~= `	static struct ` ~ toPascalCase(category) ~ ` {` ~ newline ~ newline;
				foreach(string packet_name, JSONValue packet; cat_json.object) {
					if(packet.type == JSON_TYPE.OBJECT) {
						auto packet_obj = packet.object;
						string[] encode, decode;
						data ~= `		static struct ` ~ toPascalCase(packet_name) ~ ` {` ~ newline ~ newline;
						data ~= `			public enum ` ~ id_c ~ ` packetId = ` ~ packet_obj["id"].toString() ~ `;` ~ newline ~ newline;
						data ~= `			public enum bool clientbound = ` ~ packet_obj["clientbound"].toString() ~ `;` ~ newline;
						data ~= `			public enum bool serverbound = ` ~ packet_obj["serverbound"].toString() ~ `;` ~ newline ~ newline;
						Tuple!(string, string)[] fields;
						foreach(JSONValue field ; packet_obj["fields"].array) {
							auto field_obj = field.object;
							string t = field_obj["type"].str;
							auto tup = tuple(convertType(t), convertName(field_obj["name"].str));
							fields ~= tup;
							data ~= `			public ` ~ tup[0] ~ ` ` ~ tup[1] ~ `;` ~ newline;
							encode ~= createEncoding(t, tup[1]);
							decode ~= createDecoding(t, tup[1]);
						}
						data ~= newline;
						data ~= `			public ubyte[] encode(bool write_id=true)() {` ~ newline ~
							`				ubyte[] buffer;` ~ newline ~
							`				static if(write_id){ ` ~ createEncoding(id, "packetId") ~ ` }` ~ newline;
						foreach(string e ; encode) data ~= `				` ~ e ~ newline;
						data ~= `				return buffer;` ~ newline ~ `			}` ~ newline ~ newline;
						data ~= `			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {` ~ newline ~
							`				static if(read_id){ ` ~ id_c ~ ` _packet_id; ` ~ createDecoding(id, "_packet_id") ~ ` }` ~ newline;
						foreach(string d ; decode) data ~= `				` ~ d ~ newline;
						data ~= `				return this;` ~ newline ~ `			}` ~ newline ~ newline;
						auto variants = "variants" in packet_obj;
						if(variants) {
							auto v_obj = variants.object;
							string variant_field = convertName(v_obj["field"].str);
							foreach(string variant_name, JSONValue variant; v_obj["values"].object) {
								auto encode_v = encode.dup;
								auto decode_v = decode.dup;
								auto variant_obj = variant.object;
								data ~= `			static struct ` ~ toPascalCase(variant_name) ~ ` {` ~ newline ~ newline;
								foreach(f ; fields) {
									if(f[1] == variant_field) {
										data ~= `				public enum ` ~ f[0] ~ ` ` ~ f[1] ~ ` = ` ~ variant_obj["value"].toString() ~ `;` ~ newline;
									} else {
										data ~= `				public ` ~ f[0] ~ ` ` ~ f[1] ~ `;` ~ newline;
									}
								}
								foreach(JSONValue field ; variant_obj["fields"].array) {
									auto field_obj = field.object;
									string t = field_obj["type"].str;
									string n = convertName(field_obj["name"].str);
									data ~= `				public ` ~ convertType(field_obj["type"].str) ~ ` ` ~ convertName(field_obj["name"].str) ~ `;` ~ newline;
									encode_v ~= createEncoding(t, n);
									decode_v ~= createDecoding(t, n);
								}
								data ~= newline;
								data ~= `				public ubyte[] encode(bool write_id=true)() {` ~ newline ~
									`					ubyte[] buffer;` ~ newline ~
										`					static if(write_id){ ` ~ createEncoding(id, "packetId") ~ ` }` ~ newline;
								foreach(e ; encode_v) data ~= `					` ~ e ~ newline;
								data ~= `					return buffer;` ~ newline ~ `				}` ~ newline ~ newline;
								data ~= `				public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {` ~ newline ~
									`					static if(read_id){ ` ~ id_c ~ ` _packet_id; ` ~ createDecoding(id, "_packet_id") ~ ` }` ~ newline;
								foreach(i, string d; decode_v) {
									if(i < fields.length && fields[i][1] == variant_field) {
										string v = fields[i][0];
										data ~= `					` ~ v ~ " __field_value; " ~ createDecoding(fields[i][0], "__field_value") ~ newline;
									} else {
										data ~= `					` ~ d ~ newline;
									}
								}
								data ~= `					return this;` ~ newline ~ `				}` ~ newline ~ newline;
								data ~= `			}` ~ newline ~ newline;
							}
						}
						data ~= `		}` ~ newline ~ newline;
					}
				}
				data ~= `	}` ~ newline ~ newline;
			}

			data ~= `}` ~ newline;

			if(!exists("../src/d/sul/protocol")) mkdir("../src/d/sul/protocol");
			write("../src/d/sul/protocol/" ~ game ~ ".d", data);
		}

	}

}
