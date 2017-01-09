module all;

import std.algorithm : min;
import std.base64 : Base64URL;
import std.conv : to;
import std.file : dirEntries, SpanMode, read, isFile, _write = write;
import std.json;
import std.path : dirSeparator;
import std.string;
import std.typecons : Tuple, tuple;
import std.xml;

static import d;
static import java;
static import js;

static import doc;
static import json;


alias File(T) = Tuple!(string, "software", size_t, "protocol", T, "data");


alias Attribute = Tuple!(string, "id", string, "name", float, "min", float, "max", float, "def");

alias Attributes = File!(Attribute[]);


alias Enchantment = Tuple!(ubyte, "id", ubyte, "level");

alias Item = Tuple!(string, "name", ushort, "id", ushort, "meta", Enchantment[], "enchantments");

alias Creative = File!(Item[]);


alias MetadataFlag = Tuple!(string, "name", string, "description", size_t, "bit");

alias MetadataType = Tuple!(string, "name", string, "description", string, "type", ubyte, "id", string, "def", bool, "required", MetadataFlag[], "flags");

alias Metadata = Tuple!(ubyte[string], "types", MetadataType[], "metadatas");

alias Metadatas = File!Metadata;


alias Constant = Tuple!(string, "name", string, "value");

alias Field = Tuple!(string, "name", string, "type", string, "condition", string, "endianness", string, "description", Constant[], "constants");

alias Variant = Tuple!(string, "name", string, "value", string, "description", Field[], "fields");

alias Packet = Tuple!(string, "name", size_t, "id", bool, "clientbound", bool, "serverbound", string, "description", Field[], "fields", string, "variantField", Variant[], "variants");

alias Type = Tuple!(string, "name", string, "description", Field[], "fields");

alias Section = Tuple!(string, "name", Packet[], "packets");

alias Array = Tuple!(string, "base", string, "length", string, "endianness");

alias Protocol = Tuple!(string, "released", string, "from", string, "to", string, "description", string, "id", string, "arrayLength", string[string], "endianness", Section[], "sections", Type[], "types", Array[string], "arrays");

alias Protocols = File!Protocol;


void main(string[] args) {

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
						with(element.tag) curr.data ~= Attribute(attr["id"].replace("-", "_"), attr["name"], attr["min"].to!float, attr["max"].to!float, attr["default"].to!float);
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
								Item item;
								item.name = i.tag.attr["name"];
								item.id = i.tag.attr["id"].to!ushort;
								if("meta" in i.tag.attr) item.meta = i.tag.attr["meta"].to!ushort;
								foreach(e ; i.elements) {
									if(e.tag.name == "enchantment") {
										with(e.tag) item.enchantments ~= Enchantment(attr["id"].to!ubyte, attr["level"].to!ubyte);
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
					case "types":
						foreach(t ; element.elements) {
							if(t.tag.name == "type") {

							}
						}
						break;
					case "metadatas":
						foreach(md ; element.elements) {
							if(md.tag.name == "type") {
								MetadataType type;
								type.name = md.tag.attr["name"].replace("-", "_");
								type.description = text(md);
								type.type = md.tag.attr["type"].replace("-", "_");
								type.id = md.tag.attr["id"].to!ubyte;
								if("default" in md.tag.attr) type.def = md.tag.attr["default"];
								if("required" in md.tag.attr) type.required = md.tag.attr["required"].to!bool;
								foreach(f ; md.elements) {
									if(f.tag.name == "flag") {
										type.flags ~= MetadataFlag(f.tag.attr["name"].replace("-", "_"), text(f), to!size_t(f.tag.attr["bit"]));

									}
								}
								m.data.metadatas ~= type;
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
									foreach(f ; e.elements) {
										if(f.tag.name == "field") {
											Field field;
											with(f.tag) {
												field.name = attr["name"].replace("-", "_");
												field.type = convert(attr["type"].replace("-", "_"));
												field.description = text(f);
												if("endianness" in attr) field.endianness = attr["endianness"].replace("-", "_");
												if("when" in attr) field.condition = attr["when"].replace("-", "_");
											}
											foreach(c ; f.elements) {
												if(c.tag.name == "constant") {
													field.constants ~= Constant(c.tag.attr["name"].replace("-", "_"), c.tag.attr["value"]);
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
												foreach(c ; fv.elements) {
													if(c.tag.name == "constant") {
														field.constants ~= Constant(c.tag.attr["name"].replace("-", "_"), c.tag.attr["value"]);
													}
												}
												packet.fields ~= field;
											} else if(fv.tag.name == "variants") {
												packet.variantField = fv.tag.attr["field"];
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
																foreach(c ; f.elements) {
																	if(c.tag.name == "constant") {
																		field.constants ~= Constant(c.tag.attr["name"].replace("-", "_"), c.tag.attr["value"]);
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
					default:
						break;
				}
			}
			protocols[file.name!"xml"] = protocol;
		}
	}

	d.d(attributes, protocols, metadata, creative);
	java.java(attributes, protocols, creative);
	js.js(attributes, protocols, creative);

	doc.doc(attributes, protocols, metadata);
	json.json(attributes, protocols, creative);

}

@property string name(string ext)(string file) {
	return file[file.lastIndexOf(dirSeparator)+1..$-ext.length-1];
}

@property string text(Element element) {
	return decode(strip((){
		if(element.texts.length) {
			return element.texts[0].to!string;
		} else {
			try {
				return element.text;
			} catch(DecodeException) {
				return "";
			}
		}
	}()));
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
	return Base64URL.encode(cast(ubyte[])name).replace("-", "_").replace("=", "")[0..min($, 16)];
}

void write(string file, string data, string from="") {
	_write(file, "/*\n * This file has been automatically generated by sel-utils and\n" ~
		" * released under the GNU General Public License version 3.\n *\n" ~
		" * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE\n" ~
		" * Repository: https://github.com/sel-project/sel-utils\n" ~
		(from.length ? " * Generator: https://github.com/sel-project/sel-utils/blob/master/xml/" ~ from ~ ".xml\n" : "") ~
		" */\n" ~ data.strip ~ "\n");
}
