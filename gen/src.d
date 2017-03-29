/*
 * Copyright (c) 2016-2017 SEL
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
module src;

import std.stdio : writeln;

import std.conv : to;
static import std.file;
import std.json;
import std.math : isNaN;
import std.path : dirSeparator;
//import std.regex : ctRegex, matchAll;
import std.string;

import all;

struct Data {
	
	enum Type {
		
		string,
		object,
		array
		
	}
	
	string str;
	Data[string] object;
	Data[] array;
	
	public Type type;
	
	public this(T)(T value) {
		this.opAssign(value);
	}
	
	public void opAssign(string str) {
		this.type = Type.string;
		this.str = str;
	}
	
	public void opAssign(Data[string] object) {
		this.type = Type.object;
		this.object = object;
	}
	
	public void opAssign(Data[] array) {
		this.type = Type.array;
		this.array = array;
	}
	
	public string toString() {
		final switch(this.type) {
			case Type.string: return this.str;
			case Type.object: return "{" ~ this.object.to!string[1..$-1] ~ "}";
			case Type.array: return this.array.to!string;
		}
	}
	
}

void src(Attributes[string] attributes, Protocols[string] protocols, Metadatas[string] metadatas, Creative[string] creative, Block[] blocks, Item[] items, Entity[] entities, Enchantment[] enchantments, Effect[] effects) {

	string[] languages;

	// read templates
	foreach(string file ; std.file.dirEntries("templates", std.file.SpanMode.breadth)) {
		if(std.file.isDir(file)) {
			languages ~= file[file.indexOf(dirSeparator)+1..$];
		}
	}

	Data[string] v;
	v["WEBSITE"] = "https://github.com/sel-project/sel-utils";
	v["VERSION"] = to!string(sulVersion);
	//TODO other stuff

	foreach(lang ; languages) {

		JSONValue[string] options;

		if(std.file.exists("templates/" ~ lang ~ "/info.json")) {
			//TODO parse options
		}

		Data[string] values;

		// utils
		if(templateExists(lang, "utils")) {

		}

		// attributes
		if(templateExists(lang, "attributes")) {
			values["attributes"] = Data(createAttributes(attributes, options));
		}

		// creative
		if(templateExists(lang, "creative")) {
			values["creative"] = Data(createCreative(creative, options));
		}

		// protocol

		// blocks

		// items

		// entities
		if(templateExists(lang, "entities")) {
			values["entities"] = Data(createEntities(entities, options));
		}

		// enchantments

		// effects

		foreach(type, data; values) {
			auto temp = parseTemplate(lang, type);
			auto ptr = type in temp;
			foreach(d ; data.array) {
				(*ptr).parse(d.object, temp);
			}
		}

	}

}

Data[] createAttributes(Attributes[string] attributes, JSONValue[string] options) {
	Data[] ret;
	foreach(game, a; attributes) {
		Data[string] g;
		g["GAME"] = game;
		g["SOFTWARE"] = a.software;
		g["PROTOCOL"] = a.protocol.to!string;
		g["ATTRIBUTES"] = new Data[0];
		foreach(i, attribute; a.data) {
			Data[string] values;
			values["ID"] = attribute.id;
			values["NAME"] = attribute.name;
			values["MIN"] = attribute.min.to!string;
			values["MAX"] = attribute.max.to!string;
			values["DEFAULT"] = attribute.def.to!string;
			values["LAST"] = to!string(i == a.data.length - 1);
			g["ATTRIBUTES"].array ~= Data(values);
		}
		ret ~= Data(g);
	}
	return ret;
}

Data[] createCreative(Creative[string] creative, JSONValue[string] options) {
	Data[] ret;
	foreach(game, c; creative) {
		Data[string] g;
		g["GAME"] = game;
		g["SOFTWARE"] = c.software;
		g["PROTOCOL"] = c.protocol.to!string;
		g["ITEMS"] = new Data[0];
		foreach(i, item; c.data) {
			Data[string] values;
			values["NAME"] = item.name;
			values["ID"] = item.id.to!string;
			values["META"] = item.meta.to!string;
			values["HAS_ENCHANTMENTS"] = to!string(item.enchantments.length != 0);
			values["ENCHANTMENTS"] = new Data[0];
			foreach(j, ench; item.enchantments) {
				Data[string] e;
				e["ID"] = ench.id.to!string;
				e["LEVEL"] = ench.level.to!string;
				e["LAST"] = to!string(j == item.enchantments.length - 1);
				values["ENCHANTMENTS"].array ~= Data(e);
			}
			values["LAST"] = to!string(i == c.data.length - 1);
			g["ITEMS"].array ~= Data(values);
		}
		ret ~= Data(g);
	}
	return ret;
}

Data[] createEntities(Entity[] entities, JSONValue[string] options) {
	Data[] ret;
	foreach(i, entity; entities) {
		Data[string] values;
		values["NAME"] = entity.name;
		values["MINECRAFT"] = entity.minecraft.to!string;
		values["POCKET"] = entity.pocket.to!string;
		values["HAS_SIZE"] = to!string(!entity.width.isNaN);
		values["WIDTH"] = entity.width.to!string;
		values["HEIGHT"] = entity.height.to!string;
		values["LAST"] = to!string(i == entities.length - 1);
		ret ~= Data(values);
	}
	return [Data(["ENTITIES": Data(ret)])];
}

@property bool templateExists(string lang, string t) {
	return std.file.exists("templates/" ~ lang ~ "/" ~ t ~ ".template");
}

//alias Template = Tuple!(string, "location", string, "content");

struct Template {

	string lang, location, content;

	string parse(Data[string] values, Template[string] templates) {
		string ret = parseValue(this.content, values, templates);
		if(this.location.length) {
			immutable location = "../src/" ~ this.lang ~ "/" ~ parseValue(this.location, values, templates);
			std.file.mkdirRecurse(location[0..location.lastIndexOf("/")]);
			std.file.write(location, ret);
		}
		return ret;
	}

}

Template[string] parseTemplate(string lang, string t) {
	Template[string] ret;
	string data = cast(string)std.file.read("templates/" ~ lang ~ "/" ~ t ~ ".template");
	// cannot use regex because they eat memory
	foreach(match ; data.replace("\r\n", "\n").split("--- start ")) {
		auto m = match.strip.split("---");
		if(m.length >= 3) {
			string[] header = m[0].strip.split(" ");
			ret[header[0]] = Template(lang, header.length > 1 ? header[1..$].join(" ") : "", m[1..$-2].join("---")[1..$-1]);
		}
	}
	return ret;
}

/**
 * Replaces a generic string with its values marked as {{VALUE}}
 */
string parseValue(string value, Data[string] values, Template[string] templates) {
	// TODO use regex
	immutable l = value.length - 1;
	string ret = "";
	size_t open = 0;
	size_t open_at;
	size_t i;
	for(i=0; i<value.length; i++) {
		/*if(value[i] == '\\' && open != 0 && i != l && value[i+1] == '}') {
			value = value[0..i] ~ value[i+1..$];
			i++;
		} else */if(value[i] == '{' && i != l && value[i+1] == '{') {
			if(++open == 1) {
				i++;
				open_at = i+1;
				continue;
			} else {
				i++;
				if(open == 0) ret ~= '{';
			}
		} else if(value[i] == '}' && i != l && value[i+1] == '}') {
			if(--open == 0) {
				ret ~= parseValueImpl(value[open_at..i], values, templates);
				i++;
				continue;
			} else {
				i++;
				if(open == 0) ret ~= '}';
			}
		}
		if(open == 0) ret ~= value[i];
	}
	return ret;
}

/**
 * Parses a value that was originally in the form {{VALUE}}.
 * Valid formats are {{VALUE:format}} and {{VALUE==cmp?result}}, where
 * result can be another templated value.
 * Example:
 * ---
 * {{GAME==minecraft?{{PROTOCOL==210?minecraft210! {{template_minecraft_210}}}}}}
 * ---
 */
string parseValueImpl(string value, Data[string] values, Template[string] templates) {
	auto condition = value.indexOf("?");
	if(condition >= 0) {
		string result = value[condition+1..$];
		value = value[0..condition];
		condition = value.indexOf("==");
		bool check = true;
		if(condition == -1) {
			condition = value.indexOf("!=");
			check = false;
		}
		string expected = value[condition+2..$];
		value = value[0..condition];
		auto ptr = value in values;
		if(ptr && (*ptr).type == Data.Type.string && ((*ptr).str == expected) == check) {
			/*if(result.startsWith("{{" && result.endsWith("}}"))) return parseValue(result[2..$-2], values, templates);
			else return result;*/
			return parseValue(result, values, templates);
		} else {
			return "";
		}
	}
	auto format = value.indexOf(":");
	if(format >= 0) {
		auto ptr = value[0..format] in values;
		if(ptr && (*ptr).type == Data.Type.string) {
			string str = (*ptr).str;
			final switch(value[format+1..$]) {
				case "snake_case": return str; // every string is saved as snake case
				case "camel_case": return toCamelCase(str);
				case "pascal_case": return toPascalCase(str);
				case "uppercase": return toUpper(str);
				case "spaced": return replace(str, "_", " ");
				case "dashed": return replace(str, "_", "-");
			}
		} else {
			return "";
		}
	}
	auto at = value.indexOf("@");
	if(at >= 0) {
		auto tmp = value[0..at] in templates;
		auto v = value[at+1..$] in values;
		if(tmp && v && (*v).type == Data.Type.array) {
			string[] ret;
			foreach(d ; (*v).array) {
				ret ~= (*tmp).parse(d.object, templates);
			}
			return ret.join("\n");
		}
	}
	auto ptr = value in values;
	if(ptr && (*ptr).type == Data.Type.string) {
		return (*ptr).str;
	} else {
		auto tmp = value in templates;
		if(tmp) {
			return parseValue((*tmp).content, values, templates);
		}
	}
	return "";
}
