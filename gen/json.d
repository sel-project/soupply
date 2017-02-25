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
module json;

import std.conv : to;
import std.file : mkdirRecurse, _write = write;
import std.json;

import all;

void json(Attributes[string] attributes, Protocols[string] protocols, Metadatas[string] metadatas, Creative[string] creative, Block[] blocks) {

	// attributes
	mkdirRecurse("../json/attributes");
	foreach(string game, Attributes attrs; attributes) {
		string data = "{\n\n\t\"__software\": " ~ JSONValue(attrs.software).toString() ~ ",\n\t\"__protocol\": " ~ attrs.protocol.to!string ~ ",\n\t\"__website\": \"https://github.com/sel-project/sel-utils\",\n\n\t\"attributes\": {\n\n";
		foreach(i, attr; attrs.data) {
			data ~= "\t\t\"" ~ toSnakeCase(attr.id) ~ "\": {\n\n";
			data ~= "\t\t\t\"name\": \"" ~ attr.name ~ "\",\n";
			data ~= "\t\t\t\"min\": " ~ attr.min.to!string ~ ",\n";
			data ~= "\t\t\t\"max\": " ~ attr.max.to!string ~ ",\n";
			data ~= "\t\t\t\"default\": " ~ attr.def.to!string ~ "\n";
			data ~= "\n\t\t}";
			if(i != attrs.data.length - 1) data ~= ",";
			data ~= "\n\n";
		}
		data ~= "\t}\n\n}\n";
		_write("../json/attributes/" ~ game ~ ".json", data);
	}

	// creative items
	mkdirRecurse("../json/creative");
	foreach(string game, Creative c; creative) {
		string data = "{\n\n\t\"__software\": " ~ JSONValue(c.software).toString() ~ ",\n\t\"__protocol\": " ~ c.protocol.to!string ~ ",\n\t\"__website\": \"https://github.com/sel-project/sel-utils\",\n\n\t\"items\": [\n\n";
		foreach(i, item; c.data) {
			data ~= "\t\t{\n";
			data ~= "\t\t\t\"name\": " ~ JSONValue(item.name).toString() ~ ",\n";
			data ~= "\t\t\t\"id\": " ~ to!string(item.id);
			if(item.meta != 0) data ~= ",\n\t\t\t\"meta\": " ~ to!string(item.meta);
			if(item.enchantments.length) {
				data ~= ",\n\t\t\t\"enchantments\": [\n";
				foreach(j, enchantment; item.enchantments) {
					data ~= "\t\t\t\t{\n";
					data ~= "\t\t\t\t\t\"id\": " ~ to!string(enchantment.id) ~ ",\n";
					data ~= "\t\t\t\t\t\"level\": " ~ to!string(enchantment.level) ~ "\n";
					data ~= "\t\t\t\t}";
					if(j < item.enchantments.length - 1) data ~= ",";
					data ~= "\n";
				}
				data ~= "\t\t\t]";
			}
			data ~= "\n\t\t}";
			if(i != c.data.length - 1) data ~= ",\n";
			else data ~= "\n\n";
		}
		data ~= "\t]\n\n}\n";
		_write("../json/creative/" ~ game ~ ".json", data);
	}

	// metadata
	mkdirRecurse("../json/metadata");
	foreach(string game, Metadatas m; metadatas) {
		string data = "{\n\n\t\"__software\": " ~ JSONValue(m.software).toString() ~ ",\n\t\"__protocol\": " ~ m.protocol.to!string ~ ",\n\t\"__website\": \"https://github.com/sel-project/sel-utils\",\n\n";
		data ~= "\t\"encoding\": {\n\n";
		if(m.data.prefix.length) data ~= "\t\t\"prefix\": " ~ m.data.prefix ~ ",\n\n";
		if(m.data.length.length) data ~= "\t\t\"length\": " ~ JSONValue(m.data.length).toString() ~ ",\n\n";
		if(m.data.suffix.length) data ~= "\t\t\"suffix\": " ~ m.data.suffix ~ ",\n\n";
		data ~= "\t\t\"types\": " ~ JSONValue(m.data.type).toString() ~ ",\n\n";
		data ~= "\t\t\"ids\": " ~ JSONValue(m.data.id).toString() ~ "\n\n";
		data ~= "\t},\n\n";
		data ~= "\t\"types\": {\n\n";
		foreach(i, type; m.data.types) {
			data ~= "\t\t" ~ JSONValue(type.name).toString() ~ ": {\n";
			data ~= "\t\t\t\"type\": " ~ JSONValue(type.type).toString() ~ ",\n";
			data ~= "\t\t\t\"id\": " ~ to!string(type.id) ~ (type.endianness.length ? "," : "") ~ "\n";
			if(type.endianness.length) data ~= "\t\t\t\"endianness\": \"" ~ type.endianness ~ "\"\n";
			data ~= "\t\t}" ~ (i != m.data.types.length - 1 ? "," : "") ~ "\n\n";
		}
		data ~= "\t},\n\n";
		data ~= "\t\"metadata\": {\n\n";
		foreach(i, metadata; m.data.data) {
			data ~= "\t\t" ~ JSONValue(metadata.name).toString() ~ ": {\n";
			data ~= "\t\t\t\"type\": " ~ JSONValue(metadata.type).toString() ~ ",\n";
			data ~= "\t\t\t\"id\": " ~ to!string(metadata.id) ~ ",\n";
			data ~= "\t\t\t\"required\": " ~ to!string(metadata.required) ~ (metadata.def.length || metadata.flags.length ? "," : "") ~ "\n";
			if(metadata.def.length) data ~= "\t\t\t\"default\": " ~ metadata.def ~ (metadata.flags.length ? "," : "") ~ "\n";
			if(metadata.flags.length) {
				data ~= "\t\t\t\"flags\": {\n";
				foreach(j, flag; metadata.flags) {
					data ~= "\t\t\t\t" ~ JSONValue(flag.name).toString() ~ ": " ~ to!string(flag.bit) ~ (j != metadata.flags.length - 1 ? "," : "") ~ "\n";
				}
				data ~= "\t\t\t}\n";
			}
			data ~= "\t\t}" ~ (i != m.data.data.length - 1 ? "," : "") ~ "\n\n";
		}
		data ~= "\t}\n\n";
		data ~= "}\n";
		_write("../json/metadata/" ~ game ~ ".json", data);
	}

	// protocol
	mkdirRecurse("../json/protocol");
	foreach(string game, Protocols p; protocols) {
		string data = "{\n\n\t\"__software\": " ~ JSONValue(p.software).toString() ~ ",\n\t\"__protocol\": " ~ p.protocol.to!string ~ ",\n\t\"__website\": \"https://github.com/sel-project/sel-utils\",\n\n";
		void writeFields(string space, Field[] fields) {
			foreach(i, field; fields) {
				data ~= space ~ "{\n";
				data ~= space ~ "\t\"name\": " ~ JSONValue(field.name).toString() ~ ",\n";
				data ~= space ~ "\t\"type\": " ~ JSONValue(field.type).toString() ~ (field.condition.length || field.endianness.length || field.constants.length ? "," : "") ~ "\n";
				if(field.condition.length) data ~= space ~ "\t\"when\": " ~ JSONValue(field.condition).toString() ~ (field.endianness.length || field.constants.length ? "," : "") ~ "\n";
				if(field.endianness.length) data ~= space ~ "\t\"endianness\": \"" ~ field.endianness ~ "\"" ~ (field.constants.length ? "," : "") ~ "\n";
				if(field.constants.length) {
					data ~= space ~ "\t\"constants\": {\n";
					foreach(j, constant; field.constants) {
						string value = JSONValue(constant.value).toString();
						try {
							value = JSONValue(to!size_t(constant.value)).toString();
						} catch(Exception) {}
						data ~= space ~ "\t\t" ~ JSONValue(constant.name).toString() ~ ": " ~ value ~ (j != field.constants.length - 1 ? "," : "") ~ "\n";
					}
					data ~= space ~ "\t}\n";
				}
				data ~= space ~ "}" ~ (i != fields.length - 1 ? "," : "") ~ "\n";
			}
		}
		// encoding
		data ~= "\t\"encoding\": {\n\n";
		if(p.data.endianness.length) {
			data ~= "\t\t\"endianness\": {\n";
			foreach(string e, string value; p.data.endianness) {
				data ~= "\t\t\t\"" ~ e ~ "\": \"" ~ value ~ "\",\n";
			}
			data = data[0..$-2] ~ "\n"; // remove last comma
			data ~= "\t\t},\n\n";
		}
		data ~= "\t\t\"id\": \"" ~ p.data.id ~ "\",\n\n";
		data ~= "\t\t\"array_length\": \"" ~ p.data.arrayLength ~ "\"" ~ (p.data.types.length || p.data.types.length ? "," : "") ~ "\n\n";
		if(p.data.types.length) {
			data ~= "\t\t\"types\": {\n\n";
			foreach(i, type; p.data.types) {
				data ~= "\t\t\t\"" ~ type.name ~ "\": [\n";
				writeFields("\t\t\t\t", type.fields);
				data ~= "\t\t\t]" ~ (i != p.data.types.length - 1 ? "," : "") ~ "\n\n";
			}
			data ~= "\t\t}" ~ (p.data.arrays.length ? "," : "") ~ "\n\n";
		}
		if(p.data.arrays.length) {
			data ~= "\t\t\"arrays\": {\n\n";
			foreach(string name, array; p.data.arrays) {
				data ~= "\t\t\t\"" ~ name ~ "\": {\n";
				data ~= "\t\t\t\t\"base\": " ~ JSONValue(array.base).toString() ~ ",\n";
				data ~= "\t\t\t\t\"length\": " ~ JSONValue(array.length).toString() ~ (array.endianness.length ? "," : "") ~ "\n";
				if(array.endianness.length) data ~= "\t\t\t\t\"endianness\": \"" ~ array.endianness ~ "\"\n";
				data ~= "\t\t\t},\n\n";
			}
			data = data[0..$-3] ~ "\n\n";
			data ~= "\t\t}\n\n";
		}
		data ~= "\t},\n\n";
		// packets
		data ~= "\t\"packets\": {\n\n";
		foreach(i, section; p.data.sections) {
			data ~= "\t\t" ~ JSONValue(section.name).toString() ~ ": {\n\n";
			foreach(j, packet; section.packets) {
				data ~= "\t\t\t" ~ JSONValue(packet.name).toString() ~ ": {\n";
				data ~= "\t\t\t\t\"id\": " ~ to!string(packet.id) ~ ",\n";
				data ~= "\t\t\t\t\"clientbound\": " ~ to!string(packet.clientbound) ~ ",\n";
				data ~= "\t\t\t\t\"serverbound\": " ~ to!string(packet.serverbound) ~ ",\n";
				if(packet.fields.length) {
					data ~= "\t\t\t\t\"fields\": [\n";
					writeFields("\t\t\t\t\t", packet.fields);
					data ~= "\t\t\t\t]\n";
				} else {
					data ~= "\t\t\t\t\"fields\": []\n";
				}
				if(packet.variantField.length) {
					data = data[0..$-1] ~ ",\n";
					data ~= "\t\t\t\t\"variants\": {\n";
					data ~= "\t\t\t\t\t\"field\": " ~ JSONValue(packet.variantField).toString() ~ ",\n";
					data ~= "\t\t\t\t\t\"values\": {\n";
					foreach(k, variant; packet.variants) {
						data ~= "\t\t\t\t\t\t" ~ JSONValue(variant.name).toString() ~ ": {\n";
						data ~= "\t\t\t\t\t\t\t\"value\": " ~ variant.value ~ ",\n";
						if(variant.fields.length) {
							data ~= "\t\t\t\t\t\t\t\"fields\": [\n";
							writeFields("\t\t\t\t\t\t\t\t", variant.fields);
							data ~= "\t\t\t\t\t\t\t]\n";
						} else {
							data ~= "\t\t\t\t\t\t\t\"fields\": []\n";
						}
						data ~= "\t\t\t\t\t\t}" ~ (k != packet.variants.length - 1 ? "," : "") ~ "\n";
					}
					data ~= "\t\t\t\t\t}\n";
					data ~= "\t\t\t\t}\n";
				}
				data ~= "\t\t\t}" ~ (j != section.packets.length - 1 ? "," : "") ~ "\n\n";
			}
			data ~= "\t\t}" ~ (i != p.data.sections.length - 1 ? "," : "") ~ "\n\n";
		}
		data ~= "\t}\n\n";
		data ~= "}\n";
		_write("../json/protocol/" ~ game ~ ".json", data);
	}

	// blocks
	{
		string data = "{\n\n\t\"__website\": \"https://github.com/sel-project/sel-utils\",\n\n";
		data ~= "\t\"blocks\": {\n\n";
		void writeBlockData(string type, BlockData blockdata) {
			if(blockdata.id >= 0) {
				data ~= "\t\t\t\"" ~ type ~ "\": ";
				if(blockdata.meta >= 0) {
					data ~= "{\n";
					data ~= "\t\t\t\t\"id\": " ~ to!string(blockdata.id) ~ ",\n";
					data ~= "\t\t\t\t\"meta\": " ~ to!string(blockdata.meta) ~ "\n";
					data ~= "\t\t\t}";
				} else {
					data ~= to!string(blockdata.id);
				}
				data ~= ",\n";
			}
		}
		foreach(i, block; blocks) {
			data ~= "\t\t\"" ~ block.name ~ "\": {\n";
			data ~= "\t\t\t\"id\": " ~ block.id.to!string ~ ",\n";
			writeBlockData("minecraft", block.minecraft);
			writeBlockData("pocket", block.pocket);
			data ~= "\t\t\t\"solid\": " ~ block.solid.to!string ~ ",\n";
			if(block.solid) {
				data ~= "\t\t\t\"hardness\": " ~ block.hardness.to!string ~ ",\n";
				data ~= "\t\t\t\"blast_resistance\": " ~ block.blastResistance.to!string ~ ",\n";
			}
			data = data[0..$-2] ~ "\n";
			data ~= "\t\t}" ~ (i != blocks.length -1 ? "," : "") ~ "\n\n";
		}
		data ~= "\t}\n\n";
		data ~= "}\n";
		_write("../json/blocks.json", data);
	}

}
