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
module all;

import std.algorithm : canFind, min, sort;
import std.base64 : Base64URL;
import std.conv : to;
import std.file : dirEntries, SpanMode, read, isFile, _write = write, exists;
import std.json;
import std.path : dirSeparator;
import std.regex : ctRegex, replaceAll;
import std.string;
import std.typecons : Tuple, tuple;
import std.xml;

static import d;
static import java;
static import js;

static import src;

static import diff;
static import docs;


alias File(T) = Tuple!(string, "software", size_t, "protocol", T, "data");


alias Attribute = Tuple!(string, "name", string, "id", float, "min", float, "max", float, "def", string, "description");

alias Attributes = File!(Attribute[]);


alias EnchantmentC = Tuple!(ubyte, "id", ubyte, "level");

alias ItemC = Tuple!(string, "name", ushort, "id", ushort, "meta", EnchantmentC[], "enchantments");

alias Creative = File!(ItemC[]);


alias MetadataType = Tuple!(string, "name", string, "type", ubyte, "id", string, "endianness");

alias MetadataFlag = Tuple!(string, "name", string, "description", size_t, "bit");

alias MetadataData = Tuple!(string, "name", string, "description", string, "type", ubyte, "id", string, "def", bool, "required", MetadataFlag[], "flags");

alias Metadata = Tuple!(string, "prefix", string, "length", string, "suffix", string, "type", string, "id", MetadataType[], "types", MetadataData[], "data");

alias Metadatas = File!Metadata;


alias Constant = Tuple!(string, "name", string, "description", string, "value");

alias Field = Tuple!(string, "name", string, "type", string, "condition", string, "endianness", string, "def", string, "description", Constant[], "constants");

alias Variant = Tuple!(string, "name", string, "value", string, "description", Field[], "fields");

alias Packet = Tuple!(string, "name", size_t, "id", bool, "clientbound", bool, "serverbound", string, "description", Field[], "fields", string, "variantField", Variant[], "variants");

alias Type = Tuple!(string, "name", string, "description", Field[], "fields", string, "length");

alias Section = Tuple!(string, "name", string, "description", Packet[], "packets");

alias Array = Tuple!(string, "base", string, "length", string, "endianness");

alias Protocol = Tuple!(string, "released", string, "from", string, "to", string, "description", string, "id", string, "arrayLength", string[string], "endianness", Section[], "sections", Type[], "types", Array[string], "arrays");

alias Protocols = File!Protocol;


alias BlockData = Tuple!(int, "id", int, "meta", int, "hash");

alias Point = Tuple!(ubyte, "x", ubyte, "y", ubyte, "z");

alias BoundingBox = Tuple!(Point, "min", Point, "max");

alias Block = Tuple!(string, "name", ushort, "id", BlockData, "minecraft", BlockData, "pocket", bool, "solid", double, "hardness", double, "blastResistance", ubyte, "opacity", ubyte, "luminance", ubyte, "encouragement", ubyte, "flammability", bool, "replaceable", BoundingBox, "boundingBox");


alias ItemData = Tuple!(bool, "exists", ushort, "id", int, "meta");

alias Item = Tuple!(string, "name", ItemData, "minecraft", ItemData, "pocket", ubyte, "stack");


alias Entity = Tuple!(string, "name", ubyte, "minecraft", ubyte, "pocket", bool, "object", double, "width", double, "height");


alias Enchantment = Tuple!(string, "name", byte, "minecraft", byte, "pocket", ubyte, "max");


alias Effect = Tuple!(string, "name", ubyte, "id", uint, "particles");


private uint n_version;

public @property uint sulVersion() {
	return n_version;
}


void main(string[] args) {

	// update generation version
	if(exists(".version")) {
		n_version = to!uint(split(cast(string)read(".version"), ".")[2]);
	}
	if(!args.canFind("-no-update")) n_version++;
	_write(".version", "1.0." ~ to!string(n_version));

	bool wd = args.canFind("d");
	bool wjava = args.canFind("java");
	bool wjs = args.canFind("js");
	bool wsrc = args.canFind("src");
	bool wdiff = args.canFind("diff");
	bool wdocs = args.canFind("docs");
	bool wall = !wd && !wjava && !wjs && !wsrc && !wdiff && !wdocs;

	// attributes
	Attributes[string] attributes;
	foreach(string file ; dirEntries("../xml/attributes", SpanMode.breadth)) {
		if(file.isFile && file.endsWith(".xml")) {
			Attributes curr;
			foreach(element ; new Document(cast(string)read(file)).elements) {
				switch(element.tag.name) {
					case "software":
						curr.software = element.text.strip;
						break;
					case "protocol":
						curr.protocol = element.text.strip.to!size_t;
						break;
					case "attribute":
						with(element.tag) curr.data ~= Attribute(attr["name"].replace("-", "_"), attr["id"], attr["min"].to!float, attr["max"].to!float, attr["default"].to!float, text(element));
						break;
					default:
						break;
				}
			}
			attributes[file.name!"xml"] = curr;
		}
	}

	// creative items
	Creative[string] creative;
	foreach(string file ; dirEntries("../xml/creative", SpanMode.breadth)) {
		if(file.isFile && file.endsWith(".xml")) {
			Creative c;
			foreach(element ; new Document(cast(string)read(file)).elements) {
				switch(element.tag.name) {
					case "software":
						c.software = element.text.strip;
						break;
					case "protocol":
						c.protocol = element.text.strip.to!size_t;
						break;
					case "category":
						foreach(i ; element.elements) {
							if(i.tag.name == "item") {
								ItemC item;
								item.name = i.tag.attr["name"];
								item.id = i.tag.attr["id"].to!ushort;
								if("meta" in i.tag.attr) item.meta = i.tag.attr["meta"].to!ushort;
								foreach(e ; i.elements) {
									if(e.tag.name == "enchantment") {
										with(e.tag) item.enchantments ~= EnchantmentC(attr["id"].to!ubyte, attr["level"].to!ubyte);
									}
								}
								c.data ~= item;
							}
						}
						break;
					default:
						break;
				}
			}
			creative[file.name!"xml"] = c;
		}
	}

	// metadata
	Metadatas[string] metadata;
	foreach(string file ; dirEntries("../xml/metadata", SpanMode.breadth)) {
		if(file.isFile && file.endsWith(".xml")) {
			Metadatas m;
			foreach(element ; new Document(cast(string)read(file)).elements) {
				switch(element.tag.name) {
					case "software":
						m.software = element.text.strip;
						break;
					case "protocol":
						m.protocol = element.text.strip.to!size_t;
						break;
					case "encoding":
						if("prefix" in element.tag.attr) m.data.prefix = element.tag.attr["prefix"];
						if("length" in element.tag.attr) m.data.length = element.tag.attr["length"];
						if("suffix" in element.tag.attr) m.data.suffix = element.tag.attr["suffix"];
						m.data.type = element.tag.attr["types"];
						m.data.id = element.tag.attr["ids"];
						foreach(t ; element.elements) {
							if(t.tag.name == "type") {
								auto e = "endianness" in t.tag.attr;
								m.data.types ~= MetadataType(t.tag.attr["name"].replace("-", "_"), t.tag.attr["type"].replace("-", "_"), t.tag.attr["id"].to!ubyte, e ? replace(*e, "-", "_") : "");
							}
						}
						break;
					case "metadatas":
						foreach(md ; element.elements) {
							if(md.tag.name == "type") {
								MetadataData data;
								data.name = md.tag.attr["name"].replace("-", "_");
								data.description = text(md);
								data.type = md.tag.attr["type"].replace("-", "_");
								data.id = md.tag.attr["id"].to!ubyte;
								if("default" in md.tag.attr) data.def = md.tag.attr["default"];
								if("required" in md.tag.attr) data.required = md.tag.attr["required"].to!bool;
								foreach(f ; md.elements) {
									if(f.tag.name == "flag") {
										data.flags ~= MetadataFlag(f.tag.attr["name"].replace("-", "_"), text(f), to!size_t(f.tag.attr["bit"]));

									}
								}
								m.data.data ~= data;
							}
						}
						break;
					default:
						break;
				}
			}
			metadata[file.name!"xml"] = m;
		}
	}

	// protocol
	Protocols[string] protocols;
	foreach(string file ; dirEntries("../xml/protocol", SpanMode.breadth)) {
		if(file.isFile && file.endsWith(".xml")) {
			Protocols protocol;
			string[string] aliases;
			@property string convert(string type) {
				auto end = min(cast(size_t)type.lastIndexOf("["), cast(size_t)type.lastIndexOf("<"), type.length);
				auto t = type[0..end];
				auto a = t in aliases;
				if(a) t = *a;
				return t ~ type[end..$];
			}
			foreach(element ; new Document(cast(string)read(file)).elements) {
				switch(element.tag.name) {
					case "software":
						protocol.software = text(element);
						break;
					case "protocol":
						protocol.protocol = to!size_t(text(element));
						break;
					case "released":
						protocol.data.released = text(element);
						break;
					case "from":
						protocol.data.from = text(element);
						break;
					case "to":
						protocol.data.to = text(element);
						break;
					case "description":
						protocol.data.description = text(element);
						break;
					case "encoding":
						protocol.data.id = element.tag.attr["id"];
						protocol.data.arrayLength = element.tag.attr["arraylength"];
						foreach(e ; element.elements) {
							switch(e.tag.name) {
								case "endianness":
									with(e.tag) protocol.data.endianness[attr["type"].replace("-", "_")] = attr["value"].replace("-", "_");
									break;
								case "alias":
									with(e.tag) aliases[attr["name"].replace("-", "_")] = attr["type"].replace("-", "_");
									break;
								case "type":
									Type type;
									type.name = e.tag.attr["name"].replace("-", "_");
									type.description = text(e);
									if("length" in e.tag.attr) type.length = e.tag.attr["length"].length ? convert(e.tag.attr["length"].replace("-", "_")) : protocol.data.arrayLength;
									foreach(f ; e.elements) {
										if(f.tag.name == "field") {
											Field field;
											with(f.tag) {
												field.name = attr["name"].replace("-", "_");
												field.type = convert(attr["type"].replace("-", "_"));
												field.description = text(f);
												if("endianness" in attr) field.endianness = attr["endianness"].replace("-", "_");
												if("when" in attr) field.condition = attr["when"].replace("-", "_");
												if("default" in attr) field.def = attr["default"];
											}
											foreach(c ; f.elements) {
												if(c.tag.name == "constant") {
													field.constants ~= Constant(c.tag.attr["name"].replace("-", "_"), text(c), c.tag.attr["value"]);
												}
											}
											type.fields ~= field;
										}
									}
									protocol.data.types ~= type;
									break;
								case "array":
									with(e.tag) protocol.data.arrays[attr["name"].replace("-", "_")] = Array(convert(attr["base"].replace("-", "_")), convert(attr["length"].replace("-", "_")), ("endianness" in attr ? attr["endianness"].replace("-", "_") : ""));
									break;
								default:
									break;
							}
						}
						break;
					case "packets":
						foreach(s ; element.elements) {
							if(s.tag.name == "section") {
								Section section;
								section.name = s.tag.attr["name"].replace("-", "_");
								section.description = text(s);
								foreach(pk ; s.elements) {
									if(pk.tag.name == "packet") {
										Packet packet;
										packet.name = pk.tag.attr["name"].replace("-", "_");
										packet.id = pk.tag.attr["id"].to!size_t;
										packet.clientbound = pk.tag.attr["clientbound"].to!bool;
										packet.serverbound = pk.tag.attr["serverbound"].to!bool;
										packet.description = text(pk);
										foreach(fv ; pk.elements) {
											if(fv.tag.name == "field") {
												Field field;
												field.name = fv.tag.attr["name"].replace("-", "_");
												field.type = convert(fv.tag.attr["type"].replace("-", "_"));
												field.description = text(fv);
												if("endianness" in fv.tag.attr) field.endianness = fv.tag.attr["endianness"].replace("-", "_");
												if("when" in fv.tag.attr) field.condition = fv.tag.attr["when"].replace("-", "_");
												if("default" in fv.tag.attr) field.def = fv.tag.attr["default"];
												foreach(c ; fv.elements) {
													if(c.tag.name == "constant") {
														field.constants ~= Constant(c.tag.attr["name"].replace("-", "_"), text(c), c.tag.attr["value"]);
													}
												}
												packet.fields ~= field;
											} else if(fv.tag.name == "variants") {
												packet.variantField = fv.tag.attr["field"].replace("-", "_");
												foreach(v ; fv.elements) {
													if(v.tag.name == "variant") {
														Variant variant;
														variant.name = v.tag.attr["name"].replace("-", "_");
														variant.value = v.tag.attr["value"].replace("-", "_");
														variant.description = text(v);
														foreach(f ; v.elements) {
															if(f.tag.name == "field") {
																Field field;
																field.name = f.tag.attr["name"].replace("-", "_");
																field.type = convert(f.tag.attr["type"].replace("-", "_"));
																field.description = text(f);
																if("endianness" in f.tag.attr) field.endianness = f.tag.attr["endianness"].replace("-", "_");
																if("when" in f.tag.attr) field.condition = f.tag.attr["when"].replace("-", "_");
																if("default" in f.tag.attr) field.def = f.tag.attr["default"];
																foreach(c ; f.elements) {
																	if(c.tag.name == "constant") {
																		field.constants ~= Constant(c.tag.attr["name"].replace("-", "_"), text(c), c.tag.attr["value"]);
																	}
																}
																variant.fields ~= field;
															}
														}
														packet.variants ~= variant;
													}
												}
											}
										}
										section.packets ~= packet;
									}
								}
								protocol.data.sections ~= section;
							}
						}
						break;
					default:
						break;
				}
			}
			protocols[file.name!"xml"] = protocol;
		}
	}

	// blocks
	Block[] blocks;
	{
		BlockData blockData(string data) {
			auto ret = BlockData(0, -1, -1);
			auto spl = data.split(":");
			ret.id = to!ubyte(spl[0]);
			ret.hash = ret.id << 4;
			if(spl.length == 2) {
				ret.meta = to!ubyte(spl[1]);
				ret.hash |= ret.meta;
			}
			return ret;
		}
		BoundingBox boundingBox(string data) {
			if(data == "none") return BoundingBox.init;
			Point point(string data) {
				auto xyz = data.split(",");
				return Point(to!ubyte(xyz[0]), to!ubyte(xyz[1]), to!ubyte(xyz[2]));
			}
			auto spl = data.split("-");
			return BoundingBox(point(spl[0]), point(spl[1]));
		}
		Block createBlock(Block block, Element element) {
			auto name = "name" in element.tag.attr;
			auto id = "id" in element.tag.attr;
			auto minecraft = "minecraft" in element.tag.attr;
			auto pocket = "pocket" in element.tag.attr;
			auto solid = "solid" in element.tag.attr;
			auto hardness = "hardness" in element.tag.attr;
			auto blastResistance = "blastresistance" in element.tag.attr;
			auto opacity = "opacity" in element.tag.attr;
			auto luminance = "luminance" in element.tag.attr;
			auto encouragement = "encouragement" in element.tag.attr;
			auto flammability = "flammability" in element.tag.attr;
			auto replaceable = "replaceable" in element.tag.attr;
			auto bb = "boundingbox" in element.tag.attr;
			if(name) block.name = replace(*name, "-", "_");
			if(id) block.id = to!ushort(*id);
			if(minecraft) block.minecraft = blockData(*minecraft);
			if(pocket) block.pocket = blockData(*pocket);
			if(solid) block.solid = to!bool(*solid);
			if(hardness) block.hardness = to!double(*hardness);
			if(blastResistance) block.blastResistance = to!double(*blastResistance);
			if(opacity) block.opacity = to!ubyte(*opacity) & 15;
			if(luminance) block.luminance = to!ubyte(*luminance) & 15;
			if(encouragement) block.encouragement = to!ubyte(*encouragement);
			if(flammability) block.flammability = to!ubyte(*flammability);
			if(replaceable) block.replaceable = to!bool(*replaceable);
			if(bb) block.boundingBox = boundingBox(*bb);
			return block;
		}
		void group(Block current, Element[] elements) {
			foreach(element ; elements) {
				switch(element.tag.name) {
					case "block":
						blocks ~= createBlock(current, element);
						break;
					case "group":
						group(createBlock(current, element), element.elements);
						break;
					default:
						break;
				}
			}
		}
		group(Block("", 0, BlockData(0, 0, -1), BlockData(0, 0, -1), true, 0, 0, 15, 0, 0, 0, false, BoundingBox(Point(0,0,0), Point(16,16,16))), new Document(cast(string)read("../xml/blocks.xml")).elements);
	}
	sort!"a.id < b.id"(blocks);

	foreach(i, block; blocks) assert(i == block.id, to!string(i));

	// items
	Item[] items;
	foreach(element ; new Document(cast(string)read("../xml/items.xml")).elements) {
		with(element.tag) {
			if(name == "item") {
				Item item;
				item.name = attr["name"].replace("-", "_");
				void setData(ref ItemData id, string str) {
					auto s = str.split(":");
					if(s.length == 1 || s.length == 2) {
						id.exists = true;
						id.id = to!ushort(s[0]);
						if(s.length == 2) id.meta = to!ushort(s[1]);
						else id.meta = -1;
					}
				}
				auto data = "data" in attr;
				auto minecraft = "minecraft" in attr;
				auto pocket = "pocket" in attr;
				auto stack = "stack" in attr;
				if(data) {
					setData(item.minecraft, *data);
					setData(item.pocket, *data);
				} else {
					if(minecraft) setData(item.minecraft, *minecraft);
					if(pocket) setData(item.pocket, *pocket);
				}
				item.stack = stack ? to!ubyte(*stack) : 64;
				items ~= item;
			}
		}
	}

	// entities
	Entity[] entities;
	foreach(element ; new Document(cast(string)read("../xml/entities.xml")).elements) {
		with(element.tag) {
			if(name == "object" || name == "entity") {
				Entity entity;
				entity.name = attr["name"].replace("-", "_");
				entity.object = name == "object";
				auto minecraft = "minecraft" in attr;
				auto pocket = "pocket" in attr;
				auto width = "width" in attr;
				auto height = "height" in attr;
				if(minecraft) entity.minecraft = to!ubyte(*minecraft);
				if(pocket) entity.pocket = to!ubyte(*pocket);
				if(width) entity.width = to!double(*width);
				if(height) entity.height = to!double(*height);
				entities ~= entity;
			}
		}
	}

	// enchantments
	Enchantment[] enchantments;
	foreach(element ; new Document(cast(string)read("../xml/enchantments.xml")).elements) {
		with(element.tag) {
			if(name == "enchantment") {
				auto minecraft = "minecraft" in attr;
				auto pocket = "pocket" in attr;
				enchantments ~= Enchantment(attr["name"].replace("-", "_"), minecraft ? to!ubyte(*minecraft) : -1, pocket ? to!ubyte(*pocket) : -1, to!ubyte(attr["max"]));
			}
		}
	}

	// effects
	Effect[] effects;
	foreach(element ; new Document(cast(string)read("../xml/effects.xml")).elements) {
		with(element.tag) {
			if(name == "effect") {
				effects ~= Effect(attr["name"].replace("-", "_"), to!ubyte(attr["id"]), to!uint(attr["particles"], 16));
			}
		}
	}

	if(wall || wd) d.d(attributes, protocols, metadata, creative, blocks, items, entities, enchantments, effects);
	if(wall || wjava) java.java(attributes, protocols, metadata, creative, blocks, items, entities, enchantments, effects);
	if(wall || wjs) js.js(attributes, protocols, metadata, creative, blocks, items, entities);

	if(wall || wsrc) src.src(attributes, protocols, metadata, creative, blocks, items, entities, enchantments, effects);

	//if(wall || wdiff) diff.diff(attributes, protocols, metadata);
	if(wall || wdocs) docs.docs(attributes, protocols, metadata);

	// minify json
	if(wall || wsrc) {
		foreach(string file ; dirEntries("../src/json", SpanMode.breadth)) {
			if(file.isFile && !file.endsWith(".min.json")) {
				// ` +(?=[^"]*(?:"[^"]*"[^"]*)*$)` // <-- this causes an infinite loop in the program
				bool inString = false;
				string min = "";
				foreach(char c ; (cast(string)read(file)).replaceAll(ctRegex!`"__[a-z0-9_]*": ["]{0,1}[a-zA-Z0-9 :\/\-.]*["]{0,1}\,|\t|\n`, "")) {
					if(c == '"') {
						// there are no escaped characters
						inString ^= true;
					}
					if(c != ' ' || inString) {
						min ~= c;
					}
				}
				_write(file[0..$-4] ~ "min.json", min);
			}
		}
	}

}

@property string name(string ext)(string file) {
	return file[file.lastIndexOf(dirSeparator)+1..$-ext.length-1];
}

@property string text(Element element) {
	auto ret = split(strip((){
		if(element.texts.length) {
			return element.texts[0].to!string;
		} else {
			try {
				return element.text;
			} catch(DecodeException) {
				return "";
			}
		}
	}()), "\n");
	foreach(ref str ; ret) str = decode(str.replaceAll(ctRegex!"[\r\t]", ""));
	return ret.join("\n");
}

@property string toCamelCase(string str) {
	string ret = "";
	bool next_up = false;
	foreach(c ; str.dup) {
		if(c == '_' || c == '-') {
			next_up = true;
		} else if(next_up) {
			ret ~= toUpper(c);
			next_up = false;
		} else {
			ret ~= c;
		}
	}
	return ret;
}

@property string toPascalCase(string str) {
	string camel = toCamelCase(str);
	return camel.length > 0 ? toUpper(camel[0..1]) ~ camel[1..$] : "";
}

@property string toSnakeCase(string str) {
	string snaked;
	foreach(c ; str.dup) {
		if(c >= 'A' && c <= 'Z') snaked ~= '_';
		snaked ~= c;
	}
	return snaked.toLower;
}

string hash(string name) {
	string ret;
	foreach(i, c; Base64URL.encode(cast(ubyte[])name).toLower.replaceAll(ctRegex!`[_\-=]`, "")) {
		if((i & 1) == 0) ret ~= c;
	}
	while("0123456789".canFind(ret[0])) ret = ret[1..$];
	return ret.toLower[0..min($, 8)];
}

string constOf(string value) {
	if(value == "true" || value == "false") return value;
	try {
		to!real(value);
		return value;
	} catch(Exception) {
		return JSONValue(value).toString();
	}
}

void write(string file, string data, string from="", string open="/*", string line=" * ", string close=" */") {
	_write(file, open ~ "\n" ~
		line ~ "This file was automatically generated by sel-utils and\n" ~
		line ~ "released under the GNU General Public License version 3.\n" ~
		line ~ "\n" ~
		line ~ "License: https://github.com/sel-project/sel-utils/blob/master/LICENSE\n" ~
		line ~ "Repository: https://github.com/sel-project/sel-utils\n" ~
		(from.length ? line ~ "Generated from https://github.com/sel-project/sel-utils/blob/master/xml/" ~ from ~ ".xml\n" : "") ~
		close ~ "\n" ~ data);
}
