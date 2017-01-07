module all;

import std.algorithm : min;
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


alias Constant = Tuple!(string, "name", string, "value");

alias Field = Tuple!(string, "name", string, "type", string, "condition", string, "endianness", string, "description", Constant[], "constants");

alias Variant = Tuple!(string, "name", string, "value", string, "description", Field[], "fields");

alias Packet = Tuple!(string, "name", size_t, "id", bool, "clientbound", bool, "serverbound", string, "description", Field[], "fields", string, "variantField", Variant[], "variants");

alias Type = Tuple!(string, "name", string, "description", Field[], "fields");

alias Section = Tuple!(string, "name", Packet[], "packets");

alias Array = Tuple!(string, "name", string, "base", string, "length", string, "endianness");

alias Protocol = Tuple!(string, "released", string, "from", string, "to", string, "description", string, "id", string, "arrayLength", string[string], "endianness", Section[], "sections", Type[], "types", Array[], "arrays");

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

	// constants
	JSONValue[string] constants;
	foreach(string file ; dirEntries("../json/constants", SpanMode.breadth)) {
		if(file.isFile && file.endsWith(".json")) {
			constants[file.name!"json"] = parseJSON(cast(string)read(file)).object["constants"];
		}
	}

	// metadata
	JSONValue[string] metadata;
	foreach(string file ; dirEntries("../json/metadata", SpanMode.breadth)) {
		if(file.isFile && file.endsWith(".json")) {
			metadata[file.name!"json"] = parseJSON(cast(string)read(file)).object;
		}
	}

	// particles
	JSONValue[string] particles;

	// protocol
	JSONValue[string] p;
	foreach(string file ; dirEntries("../json/protocol", SpanMode.breadth)) {
		if(file.isFile && file.endsWith(".json")) {
			p[file.name!"json"] = parseJSON(cast(string)read(file)).object;
		}
	}

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
									with(e.tag) protocol.data.arrays ~= Array(attr["name"].replace("-", "_"), convert(attr["base"].replace("-", "_")), convert(attr["length"].replace("-", "_")), ("endianness" in attr ? attr["endianness"].replace("-", "_") : ""));
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

	// sounds
	JSONValue[string] sounds;

	auto jsons = [
		"constants": JSONValue(constants),
		"metadata": JSONValue(metadata),
		"particles": JSONValue(particles),
		"protocol": JSONValue(p),
		"sounds": JSONValue(sounds),
	];

	d.d(attributes, jsons);
	java.java(attributes, protocols, jsons);
	js.js(attributes, jsons);

	doc.doc(protocols);
	json.json(attributes);

}

@property string name(string ext)(string file) {
	return file[file.lastIndexOf(dirSeparator)+1..$-ext.length-1];
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

void write(string file, string data, string from="") {
	_write(file, "/*\n * This file has been automatically generated by sel-utils and\n" ~
		" * released under the GNU General Public License version 3.\n *\n" ~
		" * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE\n" ~
		" * Repository: https://github.com/sel-project/sel-utils\n" ~
		(from.length ? " * Generator: https://github.com/sel-project/sel-utils/blob/master/xml/" ~ from ~ ".xml\n" : "") ~
		" */\n" ~ data.strip ~ "\n");
}
