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
module sul.constants;

import std.conv : to;

import sul.conversion;
import sul.json;

//TODO
alias varint = int;
alias varuint = uint;
alias varlong = long;

template Constants(string game, size_t protocol) {

	static if(__traits(compiles, UtilsJSON!("protocol", game, protocol))) {
		mixin(constantsEnum(cast(JSONObject)UtilsJSON!("constants", game, protocol), cast(JSONObject)UtilsJSON!("protocol", game, protocol)));
	} else {
		mixin(constantsEnum(cast(JSONObject)UtilsJSON!("constants", game, protocol), null));
	}

}

// Constants.PacketName.fieldName.fieldValue
private @property string constantsEnum(JSONObject json, JSONObject protocol) {

	// try to get a conversion table if defined by the protocol's encoding
	// example:
	// {
	//    "entity_id": "varlong"
	// }
	string[string] type_table;
	if(protocol !is null) {
		if("encoding" in protocol && protocol["encoding"].type == JsonType.object) {
			auto encoding = cast(JSONObject)protocol["encoding"];
			if("types" in encoding && encoding["types"].type == JsonType.object) {
				foreach(string index, const(JSON) type; cast(JSONObject)encoding["types"]) {
					if(type.type == JsonType.string) {
						type_table[index] = cast(JSONString)type;
					}
				}
			}
		}
	}

	JSONObject packets = protocol is null ? null : cast(JSONObject)protocol["packets"];

	string ret = "const struct Constants{";
	if("constants" in json && json["constants"].type == JsonType.object) {
		foreach(string packet_name, const(JSON) value; cast(JSONObject)json["constants"]) {
			if(value.type == JsonType.object) {
				ret ~= "static const struct " ~ toPascalCase(packet_name) ~ " {";
				foreach(string field_name, const(JSON) field; cast(JSONObject)value) {
					if(field.type == JsonType.object) {
						string type = "size_t";
						// try to get the right value from the protocol field
						if(packets !is null) {
							foreach(string a, const(JSON) packet_pool; packets) {
								foreach(string packet_name_match, const(JSON) packet; cast(JSONObject)packet_pool) {
									if(packet_name == packet_name_match) {
										foreach(const(JSON) packet_field ; cast(JSONArray)((cast(JSONObject)packet)["fields"])) {
											if(packet_field.type == JsonType.object) {
												auto obj = cast(JSONObject)packet_field;
												if((cast(JSONString)obj["name"]).value == field_name && obj["type"].type == JsonType.string) {
													type = cast(JSONString)obj["type"];
													if(type in type_table) {
														type = type_table[type];
													}
													break;
												}
											}
										}
									}
								}
							}
						}
						ret ~= "static const struct " ~ toCamelCase(field_name) ~ " {";
						foreach(string var_name, const(JSON) var; cast(JSONObject)field) {
							if(var.type == JsonType.integer) {
								ret ~= "static const " ~ type ~ " " ~ toCamelCase(var_name) ~ "=" ~ to!string((cast(JSONInteger)var).value) ~ ";";
							}
						}
						ret ~= "}";
					}
				}
				ret ~= "}";
			}
		}
	}
	return ret ~ "}";

}
