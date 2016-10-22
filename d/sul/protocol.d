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

// default types
// bool, byte, ubyte, short, ushort, int, uint, long, ulong, float, double, char, wchar, dchar
// triad, uuid

struct Packet(T, size_t pid, bool can_encode, bool can_decode, L, E...) {

	static if(is(T == class)) {
		enum packetId = new T(pid);
	} else static if(is(T == struct)) {
		enum packetId = T(pid);
	} else {
		enum packetId = cast(T)pid;
	}

	public Tuple!E tuple;

	public this(A...)(A args) {
		this.tuple = Tuple!E(args);
	}

	alias tuple this;

	static if(can_encode) {
		public ubyte[] encode(bool write_id=true)() {
			ubyte[] buffer;
			static if(write_id) {

			}
			return buffer;
		}
	}

	static if(can_decode) {
		public void decode(bool read_id=true)(ubyte[] buffer) {
			static if(read_id) {

			}
		}
	}

}

enum SoftwareType {

	client,
	server

}

template Packets(string game, size_t protocol, SoftwareType software_type) {

	mixin(packetsEnum(cast(JSONObject)UtilsJSON!("protocol", game, protocol), software_type == SoftwareType.client));

}

private @property string packetsEnum(JSONObject json, bool is_client) {
	string id_type = "uint";
	string array_length = "uint";
	if("encoding" in json && json["encoding"].type == JsonType.object) {
		auto encoding = cast(JSONObject)json["encoding"];
		if("id" in encoding && encoding["id"].type == JsonType.string) {
			id_type = cast(JSONString)encoding["id"];
		}
		if("array_length" in json && json["array_length"].type == JsonType.string) {
			array_length = cast(JSONString)json["array_length"];
		}
	}
	string ret = "const struct Packets{";
	if("packets" in json && json["packets"].type == JsonType.object) {
		foreach(string group_name, const(JSON) group; cast(JSONObject)json["packets"]) {
			if(group.type == JsonType.object) {
				ret ~= "static const struct " ~ toPascalCase(group_name) ~ "{";
				foreach(string packet_name, const(JSON) packet; cast(JSONObject)group) {
					if(packet.type == JsonType.object) {
						JSONObject o = cast(JSONObject)packet;
						ret ~= "alias " ~ toPascalCase(packet_name) ~ "=Packet!(" ~ id_type ~ "," ~ to!string((cast(JSONInteger)o["id"]).value) ~ ",";
						ret ~= to!string((cast(JSONBoolean)o["clientbound"]) && !is_client) ~ "," ~ to!string((cast(JSONBoolean)o["serverbound"]) && is_client) ~ "," ~ array_length; 
						if("fields" in o && o["fields"].type == JsonType.array) {
							string[] f;
							foreach(const(JSON) field ; cast(JSONArray)o["fields"]) {
								if(field.type == JsonType.object) {
									JSONObject fo = cast(JSONObject)field;
									if("name" in fo && fo["name"].type == JsonType.string && "type" in fo && fo["type"].type == JsonType.string) {
										//TODO allow custom types from here
										f ~= cast(JSONString)fo["type"];
										f ~= "\"" ~ cast(JSONString)fo["name"] ~ "\"";
									}
								}
							}
							ret ~= "," ~ f.join(",");
						}
						ret ~= ");";
					}
				}
				ret ~= "}";
			}
		}
	}
	return ret ~ "}";
}
