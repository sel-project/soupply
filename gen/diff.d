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
module diff;

import std.algorithm : min, max, canFind, sort;
import std.conv : to;
import std.datetime : Date;
static import std.file;
import std.xml;
import std.path : dirSeparator;
import std.regex : ctRegex, replaceAll, matchFirst;
import std.string;
import std.typecons : Tuple, tuple;

import std.stdio : writeln;

import all;

void diff(Attributes[string] attributes, Protocols[string] protocols, Metadatas[string] metadatas) {
	
	enum defaultTypes = ["bool", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "string", "varshort", "varushort", "varint", "varuint", "varlong", "varulong", "triad", "uuid", "bytes", "metadata"];
	
	@property string convert(string type) {
		auto end = min(cast(size_t)type.lastIndexOf("["), cast(size_t)type.lastIndexOf("<"), type.length);
		immutable t = type[0..end];
		immutable e = type[end..$].replace("<", "&lt;").replace(">", "&gt;");
		if(defaultTypes.canFind(t)) return t ~ e;
		else return toCamelCase(t) ~ e;
	}

	bool isFieldChanged(Field fa, Field fb) {
		if(fa.name != fb.name || fa.type != fb.type || fa.condition != fb.condition || fa.endianness != fb.endianness || fa.constants.length != fb.constants.length) return true;
		foreach(j ; 0..fa.constants.length) {
			if(fa.constants[j].name != fb.constants[j].name || fa.constants[j].value != fb.constants[j].value) return true;
		}
		return false;
	}

	bool isPacketChanged(Packet a, Packet b) {
		bool checkFields(Field[] fa, Field[] fb) {
			if(fa.length != fb.length) return true;
			foreach(i ; 0..fa.length) {
				if(isFieldChanged(fa[i], fb[i])) return true;
			}
			return false;
		}
		// check if fields, constants or variants are different
		if(checkFields(a.fields, b.fields) || a.variantField != b.variantField || a.variants.length != b.variants.length) return true;
		//TODO check variants
		return false;
	}

	void writeDiff(ref string data, string space, Field[] a, Field[] b) {
		data ~= space ~ "<table>\n";
		data ~= space ~ "\t<tr><th>Field</th><th>Type</th></tr>\n";
		string con;
		foreach(i ; 0..max(a.length, b.length)) {
			void writeImpl(Field field, string cls="", bool cons=false) {
				data ~= space ~ "\t<tr" ~ (cls.length ? " class=\"" ~ cls ~ "\"" : "") ~ "><td>" ~ field.name.replace("_", " ") ~ "</td><td>" ~ convert(field.type) ~ "</td></tr>\n";
				if(field.constants.length && cons) {
					con ~= space ~ "\t<li>\n";
					con ~= space ~ "\t\t<p>" ~ field.name.replace("_", " ") ~ "</p>\n";
					con ~= space ~ "\t\t<table>\n";
					con ~= space ~ "\t\t\t<tr><th>Constant</th><th>Value</th></tr>\n";
					foreach(c ; field.constants) {
						con ~= space ~ "\t\t\t<tr><td>" ~ c.name.replace("_", " ") ~ "</td><td class=\"center\">" ~ c.value ~ "</td></tr>\n";
					}
					con ~= space ~ "\t\t</table>\n";
					con ~= space ~ "\t</li>\n";
				}
			}
			if(i >= a.length) {
				// added
				writeImpl(b[i], "added");
			} else if(i >= b.length) {
				// removed
				writeImpl(a[i], "removed");
			} else {
				// may be modified
				if(isFieldChanged(a[i], b[i])) {
					bool c_name = a[i].name != b[i].name;
					bool c_type = convert(a[i].type) != convert(b[i].type);
					data ~= space ~ "\t<tr>";
					if(c_name) data ~= "<td class=\"removed\">" ~ toCamelCase(a[i].name) ~ "</td>";
					else data ~= "<td rowspan=\"2\">" ~ toCamelCase(a[i].name) ~ "</td>";
					if(c_type) data ~= "<td class=\"removed\">" ~ convert(a[i].type) ~ "</td>";
					else data ~= "<td rowspan=\"2\">" ~ convert(a[i].type) ~ "</td>";
					data ~= "</tr>\n" ~ space ~ "\t<tr>";
					if(c_name) data ~= "<td class=\"added\">" ~ toCamelCase(b[i].name) ~ "</td>";
					if(c_type) data ~= "<td class=\"added\">" ~ convert(b[i].type) ~ "</td>";
					data ~= "</tr>\n";
					if(a[i].constants.length || b[i].constants.length) {
						con ~= space ~ "\t<li>\n";
						con ~= space ~ "\t\t<p>" ~ toCamelCase(a[i].name) ~ "</p>\n";
						con ~= space ~ "\t\t<table>\n";
						con ~= space ~ "\t\t\t<tr><th>Constant</th><th>Value</th></tr>\n";
						foreach(j ; 0..max(a[i].constants.length, b[i].constants.length)) {
							if(j >= a[i].constants.length) {
								con ~= space ~ "\t\t\t<tr class=\"added\"><td>" ~ b[i].constants[j].name.replace("_", " ") ~ "</td><td class=\"center\">" ~ b[i].constants[j].value ~ "</td></tr>\n";
							} else if(j >= b[i].constants.length) {
								con ~= space ~ "\t\t\t<tr class=\"removed\"><td>" ~ a[i].constants[j].name.replace("_", " ") ~ "</td><td class=\"center\">" ~ a[i].constants[j].value ~ "</td></tr>\n";
							} else {
								//TODO could be changed
								con ~= space ~ "\t\t\t<tr><td>" ~ b[i].constants[j].name.replace("_", " ") ~ "</td><td class=\"center\">" ~ b[i].constants[j].value ~ "</td></tr>\n";
							}
						}
						/*foreach(c ; field.constants) {
							con ~= space ~ "\t\t\t<tr><td>" ~ toCamelCase(c.name) ~ "</td><td class=\"center\">" ~ c.value ~ "</td></tr>\n";
						}*/
						con ~= space ~ "\t\t</table>\n";
						con ~= space ~ "\t</li>\n";
					}
				} else {
					writeImpl(b[i]);
				}
			}
		}
		data ~= space ~ "</table>\n";
		if(con.length) {
			// constants changed
			data ~= space ~ "<p><strong>Constants</strong>:</p>\n";
			data ~= space ~ "<ul>\n";
			data ~= con;
			data ~= space ~ "</ul>\n";
		}
	}

	foreach(string game, Protocols ptrs; protocols) {
		immutable gameName = game[0..$-ptrs.protocol.to!string.length];
		auto attributes = game in attributes;
		auto metadata = game in metadatas;
		uint[] others;
		foreach(otherGame, op; protocols) {
			if(otherGame.startsWith(gameName)) {
				immutable p = to!uint(otherGame[gameName.length..$]);
				if(p < ptrs.protocol) others ~= p;
			}
		}
		if(others.length) {
			sort(others);
			foreach(other ; others) {
				auto op = protocols[gameName ~ to!string(other)];
				immutable _min = min(other, ptrs.protocol);
				immutable _max = max(other, ptrs.protocol);
				string data = head(ptrs.software ~ " " ~ ptrs.protocol.to!string);
				data ~= "\t\t<h1>" ~ ptrs.software ~ "</h1>\n";
				data ~= "\t\t<h3>Differencies between protocols <a href=\"../" ~ to!string(_min) ~ ".html\">" ~ to!string(_min) ~ "</a> and <a href=\"../" ~ to!string(_max) ~ ".html\">" ~ to!string(_max) ~ "</a></h3>\n";
				// endianness
				{
					bool changed = false;

				}
				// sections
				{
					bool changed = ptrs.data.sections.length != op.data.sections.length;
					if(!changed) {
						// check amount of packets
						foreach(i, section; ptrs.data.sections) {
							if(section.name != op.data.sections[i].name || section.packets.length != op.data.sections[i].packets.length) {
								changed = true;
								break;
							}
						}
					}
					if(changed) {
						data ~= "\t\t<h2 id=\"sections\">Sections</h2>\n";
						data ~= "\t\t<table>\n";
						data ~= "\t\t\t<tr><th>Section</th><th>Packets</th></tr>\n";
						foreach(i ; 0..max(ptrs.data.sections.length, op.data.sections.length)) {
							if(i < ptrs.data.sections.length && i < op.data.sections.length && ptrs.data.sections[i].name == op.data.sections[i].name) {
								immutable sname = pretty(toCamelCase(ptrs.data.sections[i].name));
								if(ptrs.data.sections[i].packets.length != op.data.sections[i].packets.length) {
									// number of packets changed
									data ~= "\t\t\t<tr><td rowspan=\"2\">" ~ sname ~ "</td><td class=\"center removed\">" ~ op.data.sections[i].packets.length.to!string ~ "</td></tr>\n";
									data ~= "\t\t\t<tr><td class=\"center added\">" ~ ptrs.data.sections[i].packets.length.to!string ~ "</td></tr>\n";
								} else {
									data ~= "\t\t\t<tr><td>" ~ sname ~ "</td><td class=\"center\">" ~ ptrs.data.sections[i].packets.length.to!string ~ "</td></tr>\n";
								}
							} else {
								if(i < op.data.sections.length) {
									// removed
									auto s = op.data.sections[i];
									data ~= "\t\t\t<tr class=\"removed\"><td>" ~ pretty(toCamelCase(s.name)) ~ "</td><td class=\"center\">" ~ s.packets.length.to!string ~ "</td></tr>\n";
								}
								if(i < ptrs.data.sections.length) {
									// added
									auto s = op.data.sections[i];
									data ~= "\t\t\t<tr class=\"added\"><td>" ~ pretty(toCamelCase(s.name)) ~ "</td><td class=\"center\">" ~ s.packets.length.to!string ~ "</td></tr>\n";
								}
							}
						}
						data ~= "\t\t</table>\n";
					}
				}
				// packets
				{
					string d;
					foreach(i ; 0..max(ptrs.data.sections.length, op.data.sections.length)) {
						void writePacket(Packet pk, string cls="", string href="") {
							d ~= "\t\t\t<tr" ~ (cls.length ? " class=\"" ~ cls ~ "\"" : "") ~ "><td>";
							if(href.length) d ~= "<a href=\"" ~ href ~ "\">";
							d ~= pretty(toCamelCase(pk.name));
							if(href.length) d ~= "</a>";
							d ~= "</td><td class=\"center\">" ~ pk.id.to!string ~ "</td><td class=\"center\">" ~ (pk.clientbound ? "✓" : "") ~ "</td><td class=\"center\">" ~ (pk.serverbound ? "✓" : "") ~ "</td></tr>\n";
						}
						if(i < ptrs.data.sections.length && i < op.data.sections.length && ptrs.data.sections[i].name == op.data.sections[i].name) {
							auto a = op.data.sections[i];
							auto b = ptrs.data.sections[i];
							bool changed = a.packets.length != b.packets.length;
							if(!changed) {
								foreach(j ; 0..a.packets.length) {
									auto pa = a.packets[i];
									auto pb = b.packets[i];
									if(pa.name != pb.name || pa.id != pb.id || pa.clientbound != pb.clientbound || pa.serverbound != pb.serverbound) {
										changed = true;
										break;
									}
								}
							}
							if(changed) {
								// write something changed (it could also be the boundness)
								d ~= "\t\t<h2>" ~ pretty(toCamelCase(a.name)) ~ "</h2>\n";
								d ~= "\t\t<table>\n";
								d ~= "\t\t\t<tr><th>Packet</th><th>Id</th><th>Clientbound</th><th>Serverbound</th></tr>\n";
								ptrdiff_t last_a = -1;
								foreach(j, packet; b.packets) {
									bool matched = false;
									foreach(k, a_packet; a.packets) {
										if(packet.name == a_packet.name) {
											matched = true;
											bool c_id = packet.id != a_packet.id;
											bool c_c = packet.clientbound != a_packet.clientbound;
											bool c_s = packet.serverbound != a_packet.serverbound;
											if(c_id || c_c || c_s) {
												// changed
												d ~= "\t\t\t<tr><td rowspan=\"2\">" ~ pretty(toCamelCase(packet.name)) ~ "</td>";
												if(c_id) d ~= "<td class=\"removed\">" ~ a_packet.id.to!string ~ "</td>";
												else d ~= "<td rowspan=\"2\">" ~ packet.id.to!string ~ "</td>";
												if(c_c) d ~= "<td class=\"center removed\">" ~ (a_packet.clientbound ? "✓" : "") ~ "</td>";
												else d ~= "<td rowspan=\"2\" class=\"center\">" ~ (packet.clientbound ? "✓" : "") ~ "</td>";
												if(c_s) d ~= "<td class=\"center removed\">" ~ (a_packet.serverbound ? "✓" : "") ~ "</td>";
												else d ~= "<td rowspan=\"2\" class=\"center\">" ~ (packet.serverbound ? "✓" : "") ~ "</td>";
												d ~= "</tr>\n\t\t\t<tr>";
												if(c_id) d ~= "<td class=\"center added\">" ~ packet.id.to!string ~ "</td>";
												if(c_c) d ~= "<td class=\"center added\">" ~ (packet.clientbound ? "✓" : "") ~ "</td>";
												if(c_s) d ~= "<td class=\"center added\">" ~ (packet.serverbound ? "✓" : "") ~ "</td>";
												d ~= "</tr>\n";
											} else {
												writePacket(packet);
											}
											break;
										}
									}
									if(!matched) {
										// added
										writePacket(packet, "added", "../" ~ ptrs.protocol.to!string ~ ".html#" ~ link(a.name, packet.name));
									}
								}
								d ~= "\t\t</table>\n";
							}
							// also write changes to fields, constants or variants
							string dd;
							foreach(j, packet; b.packets) {
								bool matched = false;
								foreach(k, a_packet; a.packets) {
									if(packet.name == a_packet.name) {
										matched = true;
										if(isPacketChanged(a_packet, packet)) {
											// something changed
											dd ~= "\t\t\t<li>\n";
											dd ~= "\t\t\t\t<h3>" ~ pretty(toCamelCase(packet.name)) ~ "</h3>\n";
											writeDiff(dd, "\t\t\t\t", a_packet.fields, packet.fields);
											//TODO variants
											dd ~= "\t\t\t</li>\n";
										}
									}
								}
								if(!matched) {
									// added

								}
							}
							if(dd.length) {
								d ~= "\t\t<ul>\n" ~ dd ~ "\t\t</ul>\n";
							}
						} else {
							void writeImpl(string section, uint p, Packet[] packets) {
								d ~= "\t\t\t<tr><th>Packet</th><th>Id</th><th>Clientbound</th><th>Serverbound</th></tr>\n";
								foreach(packet ; packets) {
									writePacket(packet, "", "../" ~ p.to!string ~ ".html#" ~ link(section, packet.name));
								}
							}
							if(i < op.data.sections.length) {
								// write everything but red
								d ~= "\t\t<h3>" ~ pretty(toCamelCase(op.data.sections[i].name)) ~ "</h3>\n";
								d ~= "\t\t<table class=\"removed\">\n";
								writeImpl(op.data.sections[i].name, other, op.data.sections[i].packets);
								d ~= "\t\t</table>\n";
							}
							if(i < ptrs.data.sections.length) {
								// write everything green
								d ~= "\t\t<h3>" ~ pretty(toCamelCase(ptrs.data.sections[i].name)) ~ "</h3>\n";
								d ~= "\t\t<table class=\"added\">\n";
								writeImpl(ptrs.data.sections[i].name, ptrs.protocol.to!uint, ptrs.data.sections[i].packets);
								d ~= "\t\t</table>\n";
							}
						}
					}
					if(d.length) {
						data ~= "\t\t<h2 id=\"packets\">Packets</h2>\n";
						data ~= d;
					}
				}
				// types

				// arrays

				// metadata

				// attributes

				data ~= "\t</body>\n</html>\n";
				std.file.mkdirRecurse("../docs/" ~ gameName ~ "/diff");
				std.file.write("../docs/" ~ gameName ~ "/diff/" ~ to!string(_min) ~ "-" ~ to!string(_max) ~ ".html", data);
			}
		}
	}
	
}

string head(string title) {
	return "<!DOCTYPE html>\n<html lang=\"en\">\n" ~
		"\t<head>\n\t\t<meta charset=\"UTF-8\" />\n" ~
			"\t\t<title>" ~ title ~ " | SEL Utils</title>\n" ~
			"\t\t<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\" />\n" ~
			"\t\t<link rel=\"icon\" type=\"image/png\" href=\"../../favicon.png\" />\n" ~
			"\t\t<link rel=\"stylesheet\" href=\"../../style.css\" />\n\t</head>\n" ~
			"\t<body>\n\t\t<div style=\"text-align:center;padding-top:16px\"><a href=\"../..\"><div><img src=\"../../logo.png\" alt=\"SEL\" style=\"width:224px;height:104px\" /></div></a>" ~
			"<div><a href=\"../..\">Index</a>&nbsp;&nbsp;" ~
			"<a href=\"https://github.com/sel-project/sel-utils/blob/master/README.md\">About</a>&nbsp;&nbsp;" ~
			"<a href=\"https://github.com/sel-project/sel-utils/blob/master/TYPES.md\">Types</a>&nbsp;&nbsp;" ~
			"<a href=\"https://github.com/sel-project/sel-utils/blob/master/CONTRIBUTING.md\">Contribute</a>&nbsp;&nbsp;" ~
			"<a href=\"https://github.com/sel-project/sel-utils\">Github</a></div></div>\n";
}

@property string pretty(string name) {
	string ret;
	foreach(c ; name) {
		if(c >= 'A' && c <= 'Z' || c >= '0' && c <= '9') ret ~= ' ';
		ret ~= c;
	}
	if(!ret.length) return ret;
	else return (toUpper(ret[0..1]) ~ ret[1..$]).replace(" And ", " and ").replace(" Of ", " of ").replace(" In ", " in ");
}

string link(string[] pieces...) {
	foreach(ref piece ; pieces) piece = piece.replace("_", "-");
	return pieces.join("_");
}

string cond(string c) {
	c = "$+code$-" ~ c
		.replace("&", " & ")
			.replace("|", " | ")
			.replace("& &", "&&")
			.replace("| |", "||")
			.replace("==true", "$+/code$- is $+code$-$+span style=\"color:#009688\"$-true$+/span$-")
			.replace("==false", "$+/code$- is $+code$-$+span style=\"color:#009688\"$-false$+/span$-")
			.replace("==", "$+/code$- is equal to $+code$-")
			.replace("!=", "$+/code$- is not equal to $+code$-")
			.replace(">=", "$+/code$- is greater than or equal to $+code$-")
			.replace("<=", "$+/code$- is less than or equal to $+code$-")
			.replace(">", "$+/code$- is greater than $+code$-")
			.replace("<", "$+/code$- is less than $+code$-") ~ "$+/code$-";
	return c.replace("$+", "<").replace("$-", ">");
}
