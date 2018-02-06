/*
 * Copyright (c) 2016-2018 sel-project
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */
module soupply.main;

import std.algorithm : canFind, min;
import std.conv : to;
import std.file : dirEntries, SpanMode, read, isFile, _write = write;
import std.json;
import std.path : dirSeparator;
import std.process : environment;
import std.regex : ctRegex, replaceAll;
import std.string;
import std.xml;

import soupply.data;
import soupply.generator;

void main(string[] args) {

	args = args[1..$];

	if(args.canFind("-h") || args.canFind("--help")) {
		//TODO write help
		return;
	}

	immutable version_ = environment.get("BUILD_VERSION", "1");

	// metadata
	Metadatas[string] metadatas;
	foreach(string file ; dirEntries("data/metadata", SpanMode.breadth)) {
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
								m.data.types ~= Metadata.Type(t.tag.attr["name"].replace("-", "_"), t.tag.attr["type"].replace("-", "_"), t.tag.attr["id"].to!ubyte, e ? replace(*e, "-", "_") : "");
							}
						}
						break;
					case "metadatas":
						foreach(md ; element.elements) {
							if(md.tag.name == "type") {
								Metadata.Data data;
								data.name = md.tag.attr["name"].replace("-", "_");
								data.description = text(md);
								data.type = md.tag.attr["type"].replace("-", "_");
								data.id = md.tag.attr["id"].to!ubyte;
								if("default" in md.tag.attr) data.default_ = md.tag.attr["default"];
								if("required" in md.tag.attr) data.required = md.tag.attr["required"].to!bool;
								foreach(f ; md.elements) {
									if(f.tag.name == "flag") {
										data.flags ~= Metadata.Flag(f.tag.attr["name"].replace("-", "_"), text(f), to!size_t(f.tag.attr["bit"]));

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
			metadatas[file.name!"xml"] = m;
		}
	}

	// protocol
	Protocols[string] protocols;
	foreach(string file ; dirEntries("data/protocol", SpanMode.breadth)) {
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
									Protocol.Type type;
									type.name = e.tag.attr["name"].replace("-", "_");
									type.description = text(e);
									if("length" in e.tag.attr) type.length = e.tag.attr["length"].length ? convert(e.tag.attr["length"].replace("-", "_")) : protocol.data.arrayLength;
									foreach(f ; e.elements) {
										if(f.tag.name == "field") {
											Protocol.Field field;
											with(f.tag) {
												field.name = attr["name"].replace("-", "_");
												field.type = convert(attr["type"].replace("-", "_"));
												field.description = text(f);
												if("endianness" in attr) field.endianness = attr["endianness"].replace("-", "_");
												if("when" in attr) field.condition = attr["when"].replace("-", "_");
												if("default" in attr) field.default_ = attr["default"];
											}
											foreach(c ; f.elements) {
												if(c.tag.name == "constant") {
													field.constants ~= Protocol.Constant(c.tag.attr["name"].replace("-", "_"), text(c), c.tag.attr["value"]);
												}
											}
											type.fields ~= field;
										}
									}
									protocol.data.types ~= type;
									break;
								case "array":
									with(e.tag) protocol.data.arrays[attr["name"].replace("-", "_")] = Protocol.Array(convert(attr["base"].replace("-", "_")), convert(attr["length"].replace("-", "_")), ("endianness" in attr ? attr["endianness"].replace("-", "_") : ""));
									break;
								default:
									break;
							}
						}
						break;
					case "packets":
						foreach(s ; element.elements) {
							if(s.tag.name == "section") {
								Protocol.Section section;
								section.name = s.tag.attr["name"].replace("-", "_");
								section.description = text(s);
								foreach(pk ; s.elements) {
									if(pk.tag.name == "packet") {
										Protocol.Packet packet;
										packet.name = pk.tag.attr["name"].replace("-", "_");
										packet.id = pk.tag.attr["id"].to!size_t;
										packet.clientbound = pk.tag.attr["clientbound"].to!bool;
										packet.serverbound = pk.tag.attr["serverbound"].to!bool;
										packet.description = text(pk);
										foreach(fv ; pk.elements) {
											if(fv.tag.name == "field") {
												Protocol.Field field;
												field.name = fv.tag.attr["name"].replace("-", "_");
												field.type = convert(fv.tag.attr["type"].replace("-", "_"));
												field.description = text(fv);
												if("endianness" in fv.tag.attr) field.endianness = fv.tag.attr["endianness"].replace("-", "_");
												if("when" in fv.tag.attr) field.condition = fv.tag.attr["when"].replace("-", "_");
												if("default" in fv.tag.attr) field.default_ = fv.tag.attr["default"];
												foreach(c ; fv.elements) {
													if(c.tag.name == "constant") {
														field.constants ~= Protocol.Constant(c.tag.attr["name"].replace("-", "_"), text(c), c.tag.attr["value"]);
													}
												}
												packet.fields ~= field;
											} else if(fv.tag.name == "variants") {
												packet.variantField = fv.tag.attr["field"].replace("-", "_");
												foreach(v ; fv.elements) {
													if(v.tag.name == "variant") {
														Protocol.Variant variant;
														variant.name = v.tag.attr["name"].replace("-", "_");
														variant.value = v.tag.attr["value"].replace("-", "_");
														variant.description = text(v);
														foreach(f ; v.elements) {
															if(f.tag.name == "field") {
																Protocol.Field field;
																field.name = f.tag.attr["name"].replace("-", "_");
																field.type = convert(f.tag.attr["type"].replace("-", "_"));
																field.description = text(f);
																if("endianness" in f.tag.attr) field.endianness = f.tag.attr["endianness"].replace("-", "_");
																if("when" in f.tag.attr) field.condition = f.tag.attr["when"].replace("-", "_");
																if("default" in f.tag.attr) field.default_ = f.tag.attr["default"];
																foreach(c ; f.elements) {
																	if(c.tag.name == "constant") {
																		field.constants ~= Protocol.Constant(c.tag.attr["name"].replace("-", "_"), text(c), c.tag.attr["value"]);
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

	Generator.generateAll(Data("Automatically generated libraries for encoding and decoding Minecraft protocols", "MIT", "2.0." ~ version_, protocols, metadatas));

	// minify json
/+	if(!args.length || args.canFind("json")) {
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
	}+/

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

void write(string file, string data, string from="", string open="/*", string line=" * ", string close=" */") {
	_write(file, createHeader(from, open, line, close) ~ data);
}

string createHeader(string from, string open, string line, string close) {
	return open ~ "\n" ~
		line ~ "This file was automatically generated by sel-utils and\n" ~
		line ~ "released under the MIT License.\n" ~
		line ~ "\n" ~
		line ~ "License: https://github.com/sel-project/sel-utils/blob/master/LICENSE\n" ~
		line ~ "Repository: https://github.com/sel-project/sel-utils\n" ~
		(from.length ? line ~ "Generated from https://github.com/sel-project/sel-utils/blob/master/xml/" ~ from ~ ".xml\n" : "") ~
		close ~ "\n";
}
