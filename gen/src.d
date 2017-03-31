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

import std.algorithm : max;
import std.conv : to, ConvException;
static import std.file;
import std.json;
import std.math : isNaN;
import std.path : dirSeparator;
import std.string;
import std.typetuple : TypeTuple;

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

Data[string] global;

void src(Attributes[string] attributes, Protocols[string] protocols, Metadatas[string] metadatas, Creative[string] creative, Block[] blocks, Item[] items, Entity[] entities, Enchantment[] enchantments, Effect[] effects) {

	string[] languages;

	// read templates
	foreach(string file ; std.file.dirEntries("templates", std.file.SpanMode.breadth)) {
		if(std.file.isDir(file)) {
			languages ~= file[file.indexOf(dirSeparator)+1..$];
		}
	}

	global["WEBSITE"] = "https://github.com/sel-project/sel-utils";
	global["VERSION"] = to!string(sulVersion);

	foreach(lang ; languages) {

		JSONValue[string] options;

		if(std.file.exists("templates/" ~ lang ~ "/options.json")) {
			options = parseJSON(cast(string)std.file.read("templates/" ~ lang ~ "/options.json")).object;
		}

		immutable bool allt = templateExists(lang, "all");

		Data[string] values;
		if(allt) values["all"] = (Data[string]).init;

		// utils
		if(templateExists(lang, "utils")) {
			values["utils"] = Data([Data(["": Data.init])]);
		}

		foreach(immutable type ; TypeTuple!("attributes", "creative", "protocols", "metadatas", "blocks", "items", "entities", "enchantments", "effects")) {
			if(templateExists(lang, type)) {
				Data[] data = mixin("create" ~ capitalize(type) ~ "(" ~ type ~ ", options)");
				values[type] = data;
				if(allt) values["all"].object[type] = data;
			}
		}

		foreach(type, data; values) {
			addLast(data.array);
			auto temp = parseTemplate(lang, type, options);
			auto ptr = type in temp;
			foreach(d ; data.array) {
				(*ptr).parse(d.object, temp);
			}
		}

	}

}

// add last to every array that contains an object
void addLast(ref Data[] data) {
	foreach(i, ref d; data) {
		if(d.type == Data.Type.array) {
			addLast(d.array);
		} else if(d.type == Data.Type.object) {
			d.object["LAST"] = to!string(i == data.length - 1);
			addLastObject(d.object);
		}
	}
}

// ditto
void addLastObject(ref Data[string] data) {
	foreach(ref d ; data) {
		if(d.type == Data.Type.array) addLast(d.array);
		else if(d.type == Data.Type.object) addLastObject(d.object);
	}
}

Data[] createAttributes(Attributes[string] attributes, JSONValue[string] options) {
	Data[] ret;
	foreach(game, a; attributes) {
		Data[string] g;
		g["GENERATOR"] = "attributes/" ~ game;
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
		g["GENERATOR"] = "creative/" ~ game;
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
				values["ENCHANTMENTS"].array ~= Data(e);
			}
			g["ITEMS"].array ~= Data(values);
		}
		ret ~= Data(g);
	}
	return ret;
}

Data[] createProtocols(Protocols[string] protocols, JSONValue[string] options) {
	return (Data[]).init;
}

Data[] createMetadatas(Metadatas[string] metadatas, JSONValue[string] options) {
	return (Data[]).init;
}

Data[] createBlocks(Block[] blocks, JSONValue[string] options) {
	Data[] ret;
	foreach(i, block; blocks) {
		Data[string] values;
		values["NAME"] = block.name;
		values["MINECRAFT"] = to!string(block.minecraft.hash >= 0);
		values["MINECRAFT_ID"] = max(0, block.minecraft.id).to!string;
		values["HAS_MINECRAFT_META"] = to!string(block.minecraft.meta >= 0);
		values["MINECRAFT_META"] = max(0, block.minecraft.meta).to!string;
		values["POCKET"] = to!string(block.pocket.hash >= 0);
		values["POCKET_ID"] = max(0, block.pocket.id).to!string;
		values["HAS_POCKET_META"] = to!string(block.pocket.meta >= 0);
		values["POCKET_META"] = max(0, block.pocket.meta).to!string;
		values["SOLID"] = block.solid.to!string;
		values["HARDNESS"] = block.hardness.to!string;
		values["BLAST_RESISTANCE"] = block.blastResistance.to!string;
		values["OPACITY"] = block.opacity.to!string;
		values["LUMINANCE"] = block.luminance.to!string;
		values["ENCOURAGEMENT"] = block.encouragement.to!string;
		values["FLAMMABILITY"] = block.flammability.to!string;
		values["REPLACEABLE"] = block.replaceable.to!string;
		values["HAS_BOUNDING_BOX"] = to!string(block.boundingBox != BoundingBox.init);
		values["BB_MIN_X"] = block.boundingBox.min.x.to!string;
		values["BB_MIN_Y"] = block.boundingBox.min.y.to!string;
		values["BB_MIN_Z"] = block.boundingBox.min.z.to!string;
		values["BB_MAX_X"] = block.boundingBox.max.x.to!string;
		values["BB_MAX_Y"] = block.boundingBox.max.y.to!string;
		values["BB_MAX_Z"] = block.boundingBox.max.z.to!string;
		ret ~= Data(values);
	}
	return [Data(["BLOCKS": Data(ret), "GENERATOR": Data("blocks")])];
}

Data[] createItems(Item[] items, JSONValue[string] options) {
	Data[] ret;
	foreach(i, item; items) {
		Data[string] values;
		values["NAME"] = item.name;
		values["MINECRAFT"] = item.minecraft.exists.to!string;
		values["MINECRAFT_ID"] = item.minecraft.id.to!string;
		values["MINECRAFT_META"] = max(0, item.minecraft.meta).to!string;
		values["HAS_MINECRAFT_META"] = to!string(item.minecraft.meta >= 0);
		values["POCKET"] = item.pocket.exists.to!string;
		values["POCKET_ID"] = item.pocket.id.to!string;
		values["POCKET_META"] = max(0, item.pocket.meta).to!string;
		values["HAS_POCKET_META"] = to!string(item.pocket.meta >= 0);
		values["STACK"] = item.stack.to!string;
		ret ~= Data(values);
	}
	return [Data(["ITEMS": Data(ret), "GENERATOR": Data("items")])];
}

Data[] createEntities(Entity[] entities, JSONValue[string] options) {
	Data[] ret;
	foreach(i, entity; entities) {
		Data[string] values;
		values["NAME"] = entity.name;
		values["OBJECT"] = entity.object.to!string;
		values["MINECRAFT"] = to!string(entity.minecraft != 0);
		values["MINECRAFT_ID"] = entity.minecraft.to!string;
		values["POCKET"] = to!string(entity.pocket != 0);
		values["POCKET_ID"] = entity.pocket.to!string;
		values["HAS_SIZE"] = to!string(!entity.width.isNaN);
		values["WIDTH"] = entity.width.to!string;
		values["HEIGHT"] = entity.height.to!string;
		ret ~= Data(values);
	}
	return [Data(["ENTITIES": Data(ret), "GENERATOR": Data("entities")])];
}

Data[] createEnchantments(Enchantment[] enchantments, JSONValue[string] options) {
	Data[] ret;
	foreach(i, enchantment; enchantments) {
		Data[string] values;
		values["NAME"] = enchantment.name;
		values["MINECRAFT"] = to!string(enchantment.minecraft >= 0);
		values["MINECRAFT_ID"] = max(0, enchantment.minecraft).to!string;
		values["POCKET"] = to!string(enchantment.pocket >= 0);
		values["POCKET_ID"] = max(0, enchantment.pocket).to!string;
		values["MAX"] = enchantment.max.to!string;
		ret ~= Data(values);
	}
	return [Data(["ENCHANTMENTS": Data(ret), "GENERATOR": Data("enchantments")])];
}

Data[] createEffects(Effect[] effects, JSONValue[string] options) {
	Data[] ret;
	foreach(i, effect; effects) {
		Data[string] values;
		values["NAME"] = effect.name;
		values["ID"] = effect.id.to!string;
		values["COLOR"] = effect.particles.to!string;
		values["COLOR_16"] = (effect.particles.to!string(16) ~ "000000")[0..6];
		ret ~= Data(values);
	}
	return [Data(["EFFECTS": Data(ret), "GENERATOR": Data("effects")])];
}

// stuff about template parsing

@property bool templateExists(string lang, string t) {
	return std.file.exists("templates/" ~ lang ~ "/" ~ t ~ ".template");
}

class Template {

	JSONValue[string] options;

	private string lang, location, content;

	private bool write_header = true;
	private string header_open = "/*";
	private string header_line = " * ";
	private string header_close = " */";

	private string new_line = "\n";
	private string tab = "\t";

	private this() {}

	public this(JSONValue[string] options, string lang, string location, string content) {
		this.options = options;
		this.lang = lang;
		this.location = location;
		this.content = content;
		auto header = "header" in options;
		if(header) {
			if((*header).type == JSON_TYPE.FALSE) {
				this.write_header = false;
			} else if((*header).type == JSON_TYPE.OBJECT) {
				auto open = "open" in *header;
				auto line = "line" in *header;
				auto close = "close" in *header;
				if(open && (*open).type == JSON_TYPE.STRING) this.header_open = (*open).str;
				if(line && (*line).type == JSON_TYPE.STRING) this.header_line = (*line).str;
				if(close && (*close).type == JSON_TYPE.STRING) this.header_close = (*close).str;
			}
		}
		auto indentation = "indentation" in options;
		if(indentation && (*indentation).type == JSON_TYPE.STRING) {
			if((*indentation).str == "spaces") {
				this.tab = "    ";
				this.content = this.content.replace("\t", "    ");
			}
		}
		auto new_line = "new_line" in options;
		if(new_line) {
			if((*new_line).type == JSON_TYPE.STRING) this.new_line = (*new_line).str;
			else if((*new_line).type == JSON_TYPE.FALSE) this.new_line = "";
		}
	}

	public string parse(Data[string] values, Template[string] templates) {
		string ret = parseValue(this.content, values, templates);
		if(this.location.length) {
			ret = ret.strip;
			immutable location = "../src/" ~ this.lang ~ "/sul/" ~ parseValue(this.location, values, templates);
			std.file.mkdirRecurse(location[0..location.lastIndexOf("/")]);
			if(this.write_header) {
				auto gen = "GENERATOR" in values;
				write(location, ret ~ this.new_line, gen ? (*gen).str : "", this.header_open, this.header_line, this.header_close);
			} else {
				std.file.write(location, ret ~ this.new_line);
			}
		}
		return ret;
	}

	public Template addTabulation(size_t amount) {
		Template ret = new Template();
		foreach(m ; __traits(allMembers, Template)) {
			static if(is(typeof(__traits(getMember, ret, t)))) mixin("ret." ~ m ~ " = this." ~ m ~ ";");
		}
		string space;
		foreach(i ; 0..amount) space ~= ret.tab;
		string[] lines = ret.content.split("\n");
		foreach(ref line ; lines) line = space ~ line;
		ret.content = lines.join("\n");
		return ret;
	}

}

Template[string] parseTemplate(string lang, string t, JSONValue[string] options) {
	auto sel = "strip_empty_lines" in options;
	immutable emptyLines = sel is null || (*sel).type != JSON_TYPE.FALSE;
	Template[string] ret;
	string data = cast(string)std.file.read("templates/" ~ lang ~ "/" ~ t ~ ".template");
	// cannot use regex because they eat memory
	foreach(match ; data.replace("\r\n", "\n").split("--- start ")) {
		auto m = match.strip.split("---");
		if(m.length >= 3) {
			string[] header = m[0].strip.split(" ");
			string content = m[1..$-2].join("---")[1..$-1];
			if(emptyLines) {
				string[] lines = content.split("\n");
				foreach(ref line ; lines) {
					if(line.strip.length == 0) line = "";
				}
				content = lines.join("\n");
			}
			ret[header[0]] = new Template(options, lang, header.length > 1 ? header[1..$].join(" ") : "", content);
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
		if(value[i] == '\\' && open != 0 && i != l && (value[i+1] == '{' || value[i+1] == '}')) {
			if(open == 1) {
				value = value[0..i] ~ value[i+1..$];
			}
		} else if(value[i] == '{' && i != l && value[i+1] == '{') {
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
	Data* getValue(string name) {
		auto ptr = name in values; //TODO check if the value has a point (ITEM.NAME)
		return ptr ? ptr : name in global;
	}
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
		auto ptr = getValue(value);
		if((((ptr && (*ptr).type == Data.Type.string) ? (*ptr).str : "") == expected) == check) {
			return parseValue(result, values, templates);
		} else {
			return "";
		}
	}
	auto format = value.indexOf(":");
	if(format >= 0) {
		auto ptr = getValue(value[0..format]);
		if(ptr && (*ptr).type == Data.Type.string) {
			string str = (*ptr).str;
			final switch(value[format+1..$]) {
				case "snake_case": return str; // every string is saved as snake case
				case "camel_case": return toCamelCase(str);
				case "pascal_case": return toPascalCase(str);
				case "uppercase": return toUpper(str);
				case "lowercase": return replace(str, "_", "");
				case "spaced": return replace(str, "_", " ");
				case "dashed": return replace(str, "_", "-");
			}
		} else {
			return "";
		}
	}
	auto at = value.indexOf("@");
	if(at >= 0) {
		string tmpn = value[0..at];
		ptrdiff_t tabs = -1;
		auto comma = tmpn.indexOf(",");
		if(comma >= 0) {
			try {
				tabs = to!size_t(tmpn[0..comma]);
				tmpn = tmpn[comma+1..$];
			} catch(ConvException) {}
		}
		auto tmp = tmpn in templates;
		if(tmp) {
			Template getTemplate() {
				if(tabs >= 0) {
					return (*tmp).addTabulation(tabs);
				} else {
					return *tmp;
				}
			}
			auto v = getValue(value[at+1..$]);
			if(v && (*v).type == Data.Type.array) {
				auto t = getTemplate();
				string[] ret;
				foreach(d ; (*v).array) {
					ret ~= t.parse(d.object, templates);
				}
				return ret.join("\n");
			} else if(tabs >= 0) {
				return getTemplate().parse(values, templates);
			}
		}
	}
	auto ptr = getValue(value);
	if(ptr && (*ptr).type == Data.Type.string) {
		return (*ptr).str;
	} else {
		auto tmp = value in templates;
		if(tmp) {
			return (*tmp).parse(values, templates);
		}
	}
	return "";
}
