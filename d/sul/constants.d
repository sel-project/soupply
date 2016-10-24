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

template Constants(string game, size_t protocol) {

	mixin(constantsEnum(cast(JSONObject)UtilsJSON!("constants", game, protocol)));

}

// Constants.PacketName.fieldName.fieldValue
private @property string constantsEnum(JSONObject json) {
	string ret = "const struct Constants{";
	if("constants" in json && json["constants"].type == JsonType.object) {
		foreach(string packet_name, const(JSON) value; cast(JSONObject)json["constants"]) {
			if(value.type == JsonType.object) {
				ret ~= "static const struct " ~ toPascalCase(packet_name) ~ " {";
				foreach(string field_name, const(JSON) field; cast(JSONObject)value) {
					if(field.type == JsonType.object) {
						string type = "size_t";
						ret ~= "static const struct " ~ toCamelCase(field_name) ~ " {"; //TODO read value type from protocol/{type}{protocol}.json
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
