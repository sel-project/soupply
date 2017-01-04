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
module sul.attributes;

import std.conv : to;

import sul.conversion;
import sul.json;
import sul.types.attribute;

template Attributes(string game, size_t protocol) {

	mixin(attributesEnum(cast(JSONObject)utilsJSON!("attributes", game, protocol)));

}

string attributesEnum(JSONObject json) {

	string ret = "struct Attributes{@disable this();";

	auto attributes = "attributes" in json;
	if(attributes && (*attributes).type == JsonType.object) {
		foreach(string attr_name, const(JSON) values; cast(JSONObject)*attributes) {
			if(values.type == JsonType.object) {
				auto object = cast(JSONObject)values;
				auto name = "name" in object;
				auto min = "min" in object;
				auto max = "max" in object;
				auto def = "default" in object;
				if(name && min && max && def) {
					ret ~= "static const " ~ toCamelCase(attr_name) ~ "=Attribute(`" ~ (cast(JSONString)*name).value ~ "`," ~ conv(*min) ~ "," ~ conv(*max) ~ "," ~ conv(*def) ~ ");";
				}
			}
		}
	}

	return ret ~ "}";

}

private string conv(const(JSON) json) {
	if(json.type == JsonType.floating) {
		return (cast(JSONFloating)json).raw;
	} else if(json.type == JsonType.integer) {
		return (cast(JSONInteger)json).raw;
	} else {
		return "0";
	}
}
