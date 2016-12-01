/*
 * Copyright (c) 2016 SEL
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
module sul.protocol;

import std.conv : to;
import std.string;
import std.system : Endian;
import std.typecons : Tuple;
import std.typetuple : TypeTuple;

import sul.conversion;
import sul.json;

// default types
// bool, byte, ubyte, short, ushort, int, uint, long, ulong, float, double, char, wchar, dchar
// var..., special..., triad, uuid

enum SoftwareType {

	client,
	server

}

enum defaultTypes = ["bool", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "char", "string", "varint", "varuint", "varlong", "varulong", "UUID", "RemainingBytes", "Triad"];

template Protocol(string game, size_t protocol, SoftwareType software_type, E...) {

	import std.uuid : UUID;

	import sul.buffers;
	import sul.types.var;

	mixin(packetsEnum(cast(JSONObject)UtilsJSON!("protocol", game, protocol), software_type == SoftwareType.client));

}

private @property string packetsEnum(JSONObject json, bool is_client) {

	string ret = "struct Protocol{@disable this();";

	bool little_endian = false;
	string[] change_endianness;
	string id_type = "uint";
	string array_length = "uint";
	string[string] aliases = ["uuid": "UUID", "remaining_bytes": "RemainingBytes", "triad": "Triad"]; // { "entity_id": "varint" }
	Tuple!(string, string)[][string] types; // types["Address"] = [(type, condition), (type, condition)]
	Tuple!(string, string)[string] arrays; // arrays["ShortString"] = ("ubyte", "ushort")

	if("encoding" in json && json["encoding"].type == JsonType.object) {
		auto encoding = cast(JSONObject)json["encoding"];
		if("endianness" in encoding && json["encoding"].type == JsonType.object) {
			foreach(string var, const(JSON) endianness; cast(JSONObject)encoding["endianness"]) {
				if(endianness.type == JsonType.string) {
					bool le = (cast(JSONString)endianness).value == "little-endian";
					if(var == "*") {
						little_endian = le;
					} else if(little_endian ^ le) {
						change_endianness ~= var;
					}
				}
			}
		}
		if("id" in encoding && encoding["id"].type == JsonType.string) {
			id_type = cast(JSONString)encoding["id"];
		}
		if("array_length" in encoding && encoding["array_length"].type == JsonType.string) {
			array_length = cast(JSONString)encoding["array_length"];
		}
		if("types" in encoding && encoding["types"].type == JsonType.object) {
			ret ~= "const struct Types{";
			ret ~= "static struct Ubyte{ubyte b;alias b this;}"; // what's this
			foreach(string index, const(JSON) type; cast(JSONObject)encoding["types"]) {
				if(type.type == JsonType.string) {
					aliases[index] = cast(JSONString)type;
				} else if(type.type == JsonType.object) {
					auto typeo = cast(JSONObject)type;
					if("type" in typeo) {
						switch((cast(JSONString)typeo["type"]).value) {
							case "struct":
								string pc = toPascalCase(index);
								ret ~= "static struct " ~ pc ~ "{";
								types[pc] = [];
								foreach(const(JSON) field ; cast(JSONArray)typeo["fields"]) {
									auto fieldo = cast(JSONObject)field;
									string field_type = convertType(aliases, cast(JSONString)fieldo["type"]);
									string field_name = parseName(toCamelCase(cast(JSONString)fieldo["name"]));
									ret ~= field_type ~ " " ~ field_name ~ ";";
									auto tup = Tuple!(string, string)(field_name, "");
									if("when" in fieldo) {
										tup[1] = cast(JSONString)fieldo["when"];
									}
									types[pc] ~= tup;
								}
								ret ~= "}";
								break;
							case "array":
								string name = toPascalCase(index);
								auto tuple = Tuple!(string, string)(convertType(aliases, toCamelCase(cast(JSONString)typeo["base"])), cast(JSONString)typeo["length"]);
								arrays[name] = tuple;
								ret ~= "static struct " ~ name ~ "{public " ~ tuple[0] ~ "[] array;alias array this;}";
								break;
							default:
								break;
						}
					}
				}
			}
			ret ~= "}";
		}
	}

	string buffer = "static class Buffer{mixin Instance;mixin BufferMethods!(Endian." ~ (little_endian ? "little" : "big") ~ "Endian, " ~ array_length ~ ");";

	if("packets" in json && json["packets"].type == JsonType.object) {
		foreach(string group_name, const(JSON) group; cast(JSONObject)json["packets"]) {
			if(group.type == JsonType.object) {
				ret ~= "static struct " ~ toPascalCase(group_name) ~ "{";
				foreach(string packet_name, const(JSON) packet; cast(JSONObject)group) {
					if(packet !is null && packet.type == JsonType.object) {
						JSONObject o = cast(JSONObject)packet;
						string encode = "public ubyte[] encode(bool write_id=true)(){ubyte[] payload;static if(write_id){Buffer.instance.write(packetId, payload);}";
						string decode = "public typeof(this) decode(bool read_id=true)(ubyte[] payload){static if(read_id){Buffer.instance.read!(" ~ id_type ~ ")(payload);}";
						Tuple!(string, string)[] order;
						ret ~= "static struct " ~ toPascalCase(packet_name) ~ "{enum " ~ id_type ~ " packetId=" ~ to!string((cast(JSONInteger)o["id"]).value) ~ ";";
						bool clientbound = cast(JSONBoolean)o["clientbound"];
						bool serverbound = cast(JSONBoolean)o["serverbound"];
						bool can_encode = clientbound && !is_client || serverbound && is_client;
						bool can_decode = clientbound && is_client || serverbound && !is_client;
						if("fields" in o && o["fields"].type == JsonType.array) {
							foreach(const(JSON) field ; cast(JSONArray)o["fields"]) {
								if(field.type == JsonType.object) {
									JSONObject fo = cast(JSONObject)field;
									if("name" in fo && fo["name"].type == JsonType.string && "type" in fo && fo["type"].type == JsonType.string) {
										string name = parseName(toCamelCase((cast(JSONString)fo["name"]).value));
										string type = convertType(aliases, cast(JSONString)fo["type"]);
										order ~= Tuple!(string, string)(name, type);
										ret ~= type ~ " " ~ name ~ ";";

										encode ~= "Buffer.instance.write(this." ~ name ~ ", payload);";
										decode ~= "this." ~ name ~ "=Buffer.instance.read!(" ~ type ~ ")(payload);";
									}
								}
							}
						}
						if(can_encode) ret ~= encode ~ "return payload;}";
						if(can_decode) ret ~= decode ~ "return this;}";
						if("variants" in o) {
							auto variants = cast(JSONObject)o["variants"];
							if("field" in variants && "values" in variants) {
								string field = parseName(toCamelCase(cast(JSONString)variants["field"]));
								foreach(string variant_name, const(JSON) variant; cast(JSONObject)variants["values"]) {
									auto vo = cast(JSONObject)variant;
									auto corder = order.dup;
									encode = "";
									decode = "";
									ret ~= "static struct " ~ toPascalCase(variant_name) ~ "{";
									ret ~= toPascalCase(packet_name) ~ " sup;alias sup this;";
									// fields
									foreach(const(JSON) f ; cast(JSONArray)vo["fields"]) {
										JSONObject fo = cast(JSONObject)f;
										if("name" in fo && fo["name"].type == JsonType.string && "type" in fo && fo["type"].type == JsonType.string) {
											string name = parseName(toCamelCase((cast(JSONString)fo["name"]).value));
											string type = convertType(aliases, cast(JSONString)fo["type"]);
											corder ~= Tuple!(string, string)(name, type);
											ret ~= type ~ " " ~ name ~ ";";
											
											encode ~= "Buffer.instance.write(this." ~ name ~ ", payload);";
											decode ~= "this." ~ name ~ "=Buffer.instance.read!(" ~ type ~ ")(payload);";
										}
									}
									// constructor
									string[] ctor;
									foreach(tup ; corder) {
										if(tup[0] != field) {
											ctor ~= tup[1] ~ " " ~ tup[0];
										}
									}
									if(ctor.length) {
										ret ~= "public this(" ~ ctor.join(",") ~ "){";
										foreach(tup ; corder) {
											if(tup[0] == field) {
												ret ~= "this." ~ field ~ "=" ~ to!string((cast(JSONInteger)vo["value"]).value) ~ ";";
											} else {
												ret ~= "this." ~ tup[0] ~ "=" ~ tup[0] ~ ";";
											}
										}
										ret ~= "}";
									}
									// enc/dec
									if(can_encode) ret ~= "public ubyte[] encode(bool write_id=true)(){ubyte[] payload=this.sup.encode!write_id();" ~ encode ~ "return payload;}";
									if(can_decode) ret ~= "public typeof(this) decode(bool read_id=true)(ubyte[] payload){this.sup.decode!read_id(payload);" ~ decode ~ "return this;}";
									ret ~= "}";
								}
							}
						}
						ret ~= "}";
					}
				}
				ret ~= "}";
			}
		}
	}

	string w, r;
	foreach(string type, Tuple!(string, string)[] about; types) {
		w ~= "public void write" ~ type ~ "(Types." ~ type ~ " value__, ref ubyte[] buffer){";
		r ~= "public Types." ~ type ~ " read" ~ type ~ "(ref ubyte[] buffer){Types." ~ type ~ " value__;";
		foreach(data ; about) {
			string write = "this.write(value__." ~ data[0] ~ ", buffer);";
			string read = "value__." ~ data[0] ~ "=this.read!(typeof(Types." ~ type ~ "." ~ data[0] ~ "))(buffer);";
			if(data[1] == "") {
				w ~= write;
				r ~= read;
			} else {
				w ~= "with(value__) if(" ~ toCamelCase(data[1]) ~ "){" ~ write ~ "}";
				r ~= "with(value__) if(" ~ toCamelCase(data[1]) ~ "){" ~ read ~ "}";
			}
		}
		w ~= "}";
		r ~= "return value__;}";
	}
	foreach(string type, Tuple!(string, string) array; arrays) {
		w ~= "public void write" ~ type ~ "(Types." ~ type ~ " value, ref ubyte[] buffer){";
		w ~= "this.write(cast(" ~ array[1] ~ ")value.array.length, buffer);";
		w ~= "foreach(v ; value.array){this.write(v, buffer);}";
		w ~= "}";
		r ~= "public Types." ~ type ~ " read" ~ type ~ "(ref ubyte[] buffer){Types." ~ type ~ " value;";
		r ~= "value.array.length=this.read!(" ~ array[1] ~ ")(buffer);";
		r ~= "foreach(ref " ~ array[0] ~ " v ; value.array){v=this.read!(" ~ array[0] ~ ")(buffer);}";
		r ~= "return value;}";
	}
	buffer ~= w ~ r;

	return ret ~ buffer ~ "}}";

}

// type
// type[]
// type[][]
// type[44]
// type<xyz>
// type<xyz>[]
string convertType(string[string] aliases, string type) {
	string ret, t = type;
	auto array = type.indexOf("[");
	if(array >= 0) {
		t = type[0..array];
	}
	auto vector = type.indexOf("<");
	if(vector >= 0) {
		t = type[0..vector];
	}
	if(t in aliases) {
		return convertType(aliases, aliases[t] ~ (array >= 0 ? type[array..$] : ""));
	}
	foreach(string dt ; defaultTypes) {
		if(dt == t) {
			ret = dt;
			break;
		}
	}
	if(ret == "") ret = "Types." ~ toPascalCase(t);
	return ret ~ (array >= 0 ? type[array..$] : "");
}

string parseName(string name) {
	if(name == "version") return "vers";
	else if(name == "body") return "body_";
	else return name;
}

/*

const struct Protocol {

	const static struct Types {

		static struct Plugin {
			string name;
			string vers;
		}

		static struct Address {
			bool is_ipv6;
			ubyte[16] ipv6;
			ubyte[4] ipv4;
			ushort port;
		}

		static struct Skin {
			bool is_empty;
			string name;
			ubyte[] data;
		}

		/+static struct LoggedMessage {
			ulong timestamp;
			string logger;
			string message;
		}+/

		alias LoggedMessage = SelLoggedMessage;

	}

	const static class Buffer : Buffer!(Endian.bigEndian) {

		public override void writeLength(size_t length, ref ubyte[] buffer) {
			this.write(varuint(to!uint(length)), buffer);
		}

		public writePlugin(Types.Plugin plugin, ref ubyte[] buffer) {
			this.write(plugin.name, buffer);
			this.write(plugin.vers, buffer);
		}

		public writeAddress(Types.Address address, ref ubyte[] buffer) {
			this.write(address.isIpv6, buffer);
			if(address.isIpv6) this.write(address.ipv6, buffer);
			if(!address.isIpv6) this.write(address.ipv4, buffer);
			this.write(address.port, buffer);
		}

	}

	const static struct Status {

		static struct Ping {
	
			enum packetId = cast(ubyte)1;

			public Tuple!(long, "time") tuple;

			public void decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id) {
					Encoding.read!ubyte(buffer);
				}
				this.time = Encoding.read!long(buffer);
			}

			alias tuple this;

		}

		static struct Pong {
	
			enum packetId = cast(ubyte)28;

			public Tuple!(long, "time") tuple;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id) {
					Encoding.write!ubyte(packetId, buffer);
				}
				Encoding.write!long(this.time, buffer);
				return buffer;
			}

			alias tuple this;

		}

	}

	const static struct Play {
	
		static struct Login {
	
			enum packetId = cast(ubyte)1;

			public Tuple!(uint, "protocol", uybte, "gameVersion", string, "body");

			public void decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id) {
					Encoding.read!ubyte(buffer);
				}
				this.protocol = Encoding.read!uint(buffer);
				this.gameVersion = Encoding.read!ubyte(buffer);
				this.body = Encoding.read!string(buffer);
			}

			alias tuple this;

		}

	}

}

Packets.Status.Pong(21);

Packets.Play.Login().decode([1, 0, 0, 0, 91]);

*/
