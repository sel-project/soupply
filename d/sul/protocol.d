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
import std.string : join;
import std.typecons : Tuple;

import sul.conversion;
import sul.json;
import sul.types.special;

// default types
// bool, byte, ubyte, short, ushort, int, uint, long, ulong, float, double, char, wchar, dchar
// var..., special..., triad, uuid

template createId(T) {
	static if(is(T == class)) {
		T createId(size_t id){ return new T(id); }
	} else static if(is(T == struct)) {
		T createId(size_t id){ return T(id); }
	} else {
		T createId(size_t id){ return cast(T)id; }
	}
}

enum SoftwareType {

	client,
	server

}

template Packets(string game, size_t protocol, SoftwareType software_type, E...) {

	static assert(0, packetsEnum(cast(JSONObject)UtilsJSON!("protocol", game, protocol), software_type == SoftwareType.client));

}

private @property string packetsEnum(JSONObject json, bool is_client) {

	string ret = "const structs Protocol{";

	bool little_endian = false;
	string[] change_endianness;
	string id_type = "uint";
	string array_length = "uint";
	string[string] aliases; // { "entity_id": "varint" }
	Tuple!(string, bool)[string] arrays;

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
			foreach(string index, const(JSON) type; cast(JSONObject)encoding["types"]) {
				if(type.type == JsonType.string) {
					aliases[index] = cast(JSONString)type;
				} else if(type.type == JsonType.object) {
					auto typeo = cast(JSONObject)type;
					if("type" in typeo) {
						switch((cast(JSONString)typeo["type"]).value) {
							case "struct":
								ret ~= "const struct " ~ toPascalCase(index) ~ "{}";
								break;
							case "array":
								arrays[index] = Tuple!(string, bool)(cast(JSONString)typeo["base"], cast(JSONBoolean)typeo["length"]);
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

	string buffer = "static class Buffer : sul.buffers.Buffer!(Endian." ~ (little_endian ? "little" : "big") ~ "Endian){";

	if("packets" in json && json["packets"].type == JsonType.object) {
		foreach(string group_name, const(JSON) group; cast(JSONObject)json["packets"]) {
			if(group.type == JsonType.object) {
				ret ~= "static const struct " ~ toPascalCase(group_name) ~ "{";
				foreach(string packet_name, const(JSON) packet; cast(JSONObject)group) {
					if(packet !is null && packet.type == JsonType.object) {
						JSONObject o = cast(JSONObject)packet;
						string encode = "public ubyte[] encode(){ubyte[] payload;";
						ret ~= "const struct " ~ toPascalCase(packet_name) ~ "{enum packetId=createId!" ~ id_type ~ "(" ~ to!string((cast(JSONInteger)o["id"]).value) ~ ");";
						//ret ~= to!string((cast(JSONBoolean)o["clientbound"]) && !is_client) ~ "," ~ to!string((cast(JSONBoolean)o["serverbound"]) && is_client) ~ "," ~ array_length; 
						if("fields" in o && o["fields"].type == JsonType.array) {
							foreach(const(JSON) field ; cast(JSONArray)o["fields"]) {
								if(field.type == JsonType.object) {
									JSONObject fo = cast(JSONObject)field;
									if("name" in fo && fo["name"].type == JsonType.string && "type" in fo && fo["type"].type == JsonType.string) {
										string name = toCamelCase((cast(JSONString)fo["name"]).value);
										string type = cast(JSONString)fo["type"];
										//TODO allow custom types from here
										ret ~= type ~ " " ~ name ~ ";";

										encode ~= "Buffer.instance.write(this." ~ name ~ ", payload);";
									}
								}
							}
						}
						ret ~= encode ~ "return payload;}" ~ "}";
					}
				}
				ret ~= "}";
			}
		}
	}

	return ret ~ buffer ~ "}}";

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
