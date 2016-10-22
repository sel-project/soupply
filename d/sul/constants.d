module sul.constants;

import std.conv : to;

import sul.conversion;
import sul.json;

template Constants(string type, size_t protocol) {

	mixin(constantsEnum(cast(JSONObject)UtilsJSON!("constants", type, protocol)));

}

// Constants.PacketName.fieldName.fieldValue
private @property string constantsEnum(JSONObject json) {
	string ret = "const struct Constants {";
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
