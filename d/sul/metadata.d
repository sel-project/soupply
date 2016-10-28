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
module sul.metadata;

import sul.conversion;
import sul.json;

mixin template Metadata(size_t[][string] games) {
	mixin((){

			import std.conv : to;

			import sul.conversion;
			import sul.json;

			mixin((){
				string ret = "JSONObject[string] objects=[";
				foreach(string game, size_t[] protocols; games) {
					foreach(size_t protocol ; protocols) {
						ret ~= "\"" ~ game ~ to!string(protocol) ~ "\": cast(JSONObject)UtilsJSON!(\"metadata\", \"" ~ game ~ "\", " ~ to!string(protocol) ~ "),";
					}
				}
				return ret ~ "];";
			}());

			// types["minecraft210"]["float{xyz}"] = 10
			size_t[string][string] types;
			foreach(string game, JSONObject object; objects) {
				foreach(string type, const(JSON) value; cast(JSONObject)object["types"]) {
					types[game][type] = cast(JSONInteger)value;
				}
			}

			// structs["air"] = ["short": ["pocket91", "pocket92"], "varint": ["minecraft210"]]
			string[][string][string] structs;
			// defaults[game ~ metadata] = ""
			string[string] defaults;
			bool[string] always;
			string[] metadatas;
			foreach(string game, JSONObject object; objects) {
				foreach(string meta, const(JSON) value; cast(JSONObject)object["metadata"]) {

					void add(string var, string type) {
						var = toCamelCase(var);
						structs[var][type] ~= game;
						foreach(string mt ; metadatas) {
							if(mt == var) return;
						}
						metadatas ~= var;
					}

					auto info = cast(JSONObject)value;

					if("flags" in info) {

						foreach(string flag, const(JSON) flag_value; cast(JSONObject)info["flags"]) {
							add(flag, "bool");
						}

					} else {
						add(meta, cast(JSONString)info["type"]);
						if("default" in info) {
							string idf = game ~ toCamelCase(meta);
							auto def = info["default"];
							if(def.type == JsonType.string) defaults[idf] = "\"" ~ (cast(JSONString)def).value ~ "\"";
							else if(def.type == JsonType.integer) defaults[idf] = (cast(JSONInteger)def).value.to!string;
							else if(def.type == JsonType.floating) defaults[idf] = (cast(JSONFloating)def).value.to!string;
						}
					}
				}
			}

			string structs_data = "struct Metadata{";
			foreach(string metadata, string[][string] values; structs) {
				string first = "";
				structs_data ~= "struct s_" ~ metadata ~ "{";
				foreach(string type, string[] v; values) {
					if(first == "") first = v[0];
					string idf = v[0] ~ metadata;
					structs_data ~= type ~ " " ~ v[0] ~ (idf in defaults ? "=" ~ defaults[idf] : "") ~ ";";
					if(v.length > 1) {
						foreach(string vv ; v[1..$]) {
							structs_data ~= "alias " ~ vv ~ "=" ~ v[0] ~ ";";
						}
					}
				}
				structs_data ~= "void opAssign(T)(T value){";
				foreach(string var, string[] games; values) {
					structs_data ~= "this." ~ games[0] ~ "=value;";
				}
				structs_data ~= "}";
				structs_data ~= "T get(T)(){return this." ~ first ~ ";}";
				structs_data ~= "}s_" ~ metadata ~ " " ~ metadata ~ ";";
			}
			structs_data ~= "bool set(string metadata, T)(T value){static if(is(typeof(mixin(\"this.\"~metadata)))){mixin(\"this.\"~metadata~\"=value;\");return true;}else{return false;}}";
			structs_data ~= "T get(string metadata, T)(){static if(is(typeof(mixin(\"this.\"~metadata)))){mixin(\"return this.\"~metadata~\".get!T;\");}else{return T.init;}}";
			structs_data ~= "}";

			return structs_data;

	}());
}

/*

// sel
enum Metadatas {
	
	onFire,
	sneaking,
	...

}

// in an entity
struct Metadata {

	private struct StructOnFire {

		bool pocket91;
		alias pocket92 = pocket91;
		alias minecraft210 = pocket91;

	}

	private struct StructOldOne {

		varint pocket91;
		alias pocket92 = pocket91;
		int minecraft210;

	}
	
	private StructOnFire onFire;
	private StructOldOne oldOne;

}

void trySetMetadata(Metadatas meta, T)(T value) {
	immutable name = meta.to!string;
	static if(is(typeof(mixin("Metadata." ~ name))) {
		// set every member
		@.pocket91 = value; // only if casts
		@.pocket92 = value; // only if casts
		@.minecraft210 = value;	// only if casts
	}
}

void convertMetadata(ref MetadataStream stream, void* metadata) {
	
}

struct Metadata {
	
	onFire = 0

}

*/
