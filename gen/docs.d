/*
 * Copyright (c) 2017 SEL
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 */
module docs;

import std.algorithm : min, max, canFind, sort;
import std.conv : to;
static import std.file;
import std.json : JSONValue;
import std.regex : ctRegex, replaceAll, matchFirst;
import std.string;
import std.typecons : Tuple, tuple;

import all;

void writeHtml(string file, string data, string from="") {
	write(file, data ~ "\n", from, "<!--", " + ", " +-->");
}

void docs(Attributes[string] attributes, Protocols[string] protocols, Metadatas[string] metadatas) {
	
	std.file.mkdirRecurse("../pages");
	
	enum defaultTypes = ["bool", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "string", "varshort", "varushort", "varint", "varuint", "varlong", "varulong", "triad", "uuid", "bytes"];
	

	
	foreach(string game, Protocols ptrs; protocols) {
		immutable gameName = game[0..$-ptrs.protocol.to!string.length];
		@property string convert(string type) {
			auto array = type.indexOf("[");
			auto tup = type.indexOf("<");
			if(array >= 0) return convert(type[0..array]) ~ type[array..$];
			else if(tup >= 0) return convert(type[0..tup]) ~ type[tup..$].replace("<", "&lt;").replace(">", "&gt;");
			else if(type == "metadata") return "<a href=\"/protocol/" ~ game ~ "/metadata\">metadata</a>";
			else if(defaultTypes.canFind(type)) return type;
			else if(type in ptrs.data.arrays) return "<a href=\"/protocol/" ~ game ~ "/arrays#" ~ type.replace("_", "-") ~ "\">" ~ toCamelCase(type) ~ "</a>";
			else return "<a href=\"/protocol/" ~ game ~ "/types/" ~ type.replace("_", "-") ~ "\">" ~ toCamelCase(type) ~ "</a>";
		}
		auto attributes = game in attributes;
		auto metadata = game in metadatas;
		string data = head(ptrs.software ~ " " ~ ptrs.protocol.to!string, true, gameName, ptrs.protocol.to!string);
		data ~= "\t\t<h1>" ~ ptrs.software ~ " " ~ ptrs.protocol.to!string ~ "</h1>\n";
		data ~= "\t\t<a href=\"https://twitter.com/__selproject\" class=\"twitter-follow-button\" data-lang=\"en\" data-show-count=\"true\">Follow @__selproject</a>\n";
		data ~= "\t\t<div style=\"height:4px\"></div>\n";
		data ~= "\t\t<div class=\"g-plusone\" data-size=\"medium\"></div>\n";
		uint[] others;
		foreach(otherGame, op; protocols) {
			if(otherGame != game && otherGame.startsWith(gameName)) {
				others ~= to!uint(otherGame[gameName.length..$]);
			}
		}
		if(others.length) {
			sort(others);
			string[] str;
			foreach(o ; others) {
				//str ~= "<a href=\"diff/" ~ to!string(min(o, ptrs.protocol)) ~ "-" ~ to!string(max(o, ptrs.protocol)) ~ ".html\">" ~ to!string(o) ~ "</a>";
				str ~= "<a href=\"./" ~ gameName ~ o.to!string ~ "\">" ~ o.to!string ~ "</a>";
			}
			//data ~= "\t\t<p><strong>Compare</strong>: " ~ str.join(", ") ~ "</p>\n";
			data ~= "\t\t<p>Other protocols: " ~ str.join(", ") ~ "</p>\n";
		}
		string[] jumps = ["<a href=\"#encoding\">Encoding</a>", "<a href=\"#packets\">Packets</a>"];
		//if(ptrs.data.types.length) jumps ~= "<a href=\"" ~ game ~ "/types\">Types</a>"; // has no dedicated page
		if(ptrs.data.arrays.length) jumps ~= "<a href=\"" ~ game ~ "/arrays\">Arrays</a>";
		if(metadata) jumps ~= "<a href=\"" ~ game ~ "/metadata\">Metadata</a>";
		if(attributes) jumps ~= "<a href=\"" ~ game ~ "/attributes\">Attributes</a>";
		data ~= "\t\t<p><strong>Jump to</strong>: " ~ jumps.join(", ") ~ "</p>\n";
		if(ptrs.data.released.length) {
			auto spl = ptrs.data.released.split("/");
			if(spl.length == 3) {
				immutable day = spl[2] ~ (){
					auto ret = spl[2];
					if(spl[2].length != 2 || spl[0][$-2] == '1') {
						if(spl[2][$-1] == '1') return "st";
						else if(spl[2][$-1] == '2') return "nd";
						else if(spl[2][$-1] == '3') return "rd";
					}
					return "th";
				}();
				immutable month = ["January", "February", "March", "April", "May"," June", "July", "August", "September", "October", "November", "December"][to!size_t(spl[1])];
				data ~= "\t\t<p><strong>Released</strong>: " ~ month ~ " " ~ day ~ ", " ~ spl[0] ~ "</p>\n";
			}
		}
		if(ptrs.data.from.length) {
			data ~= "\t\t<p>";
			if(ptrs.data.to.length) {
				if(ptrs.data.from == ptrs.data.to) data ~= "Used in version <strong>" ~ ptrs.data.from ~ "</strong>";
				else data ~= "Used from version <strong>" ~ ptrs.data.from ~ "</strong> to <strong>" ~ ptrs.data.to ~ "</strong>";
			} else {
				data ~= "In use since version <strong>" ~ ptrs.data.from ~ "</strong>";
			}
			data ~= "</p>\n";
		}
		if(ptrs.data.description.length) data ~= desc("\t\t", ptrs.data.description);
		data ~= "\t\t<hr>\n";
		// field (generic)
		void writeFields(string[] namespace, Field[] fields, size_t spaces, string fieldDesc="Fields") {
			string space;
			foreach(i ; 0..spaces) space ~= "\t";
			if(fields.length) {
				data ~= space ~ "<p><strong>" ~ fieldDesc ~ "</strong>:</p>\n";
				bool endianness, condition, def;
				foreach(field ; fields) {
					endianness |= field.endianness.length != 0;
					condition |= field.condition.length != 0;
					def |= field.def.length != 0;
				}
				data ~= space ~ "<table>\n";
				data ~= space ~ "\t<tr>\n";
				data ~= space ~ "\t\t<th>Name</th>\n";
				data ~= space ~ "\t\t<th>Type</th>\n";
				if(endianness) data ~= space ~ "\t\t<th>Endianness</th>\n";
				if(condition) data ~= space ~ "\t\t<th>When</th>\n";
				if(def) data ~= space ~ "\t\t<th>Default</t>\n";
				data ~= space ~ "\t</tr>\n";
				bool descripted = false;
				foreach(field ; fields) {
					data ~= space ~ "\t<tr>\n" ~ space ~ "\t\t<td>";
					if(field.description.length || field.constants.length) {
						descripted = true;
						data ~= "<a href=\"#" ~ link(namespace ~ field.name) ~ "\">" ~ field.name.replace("_", " ") ~ "</a>";
					} else {
						data ~= field.name.replace("_", " ");
					}
					data ~= "</td>\n" ~ space ~ "\t\t<td>" ~ convert(field.type) ~ "</td>\n";
					if(endianness) data ~= space ~ "\t\t<td class=\"center\">" ~ field.endianness.replace("_", " ") ~ "</td>\n";
					if(condition) data ~= space ~ "\t\t<td class=\"center\">" ~ (field.condition.length ? cond(field.condition.replace("_", " ")) : "") ~ "</td>\n";
					if(def) data ~= space ~ "\t\t<td class=\"center\">" ~ field.def ~ "</td>\n";
					data ~= space ~ "\t</tr>\n";
				}
				data ~= space ~ "</table>\n";
				if(descripted) {
					data ~= space ~ "<ul>\n";
					foreach(field ; fields) {
						if(field.description.length || field.constants.length) {
							data ~= space ~ "\t<li>\n";
							data ~= space ~ "\t\t<strong id=\"" ~ link(namespace ~ field.name) ~ "\">" ~ field.name.replace("_", " ") ~ "</strong>\n";
							if(field.description.length) data ~= desc(space ~ "\t\t", field.description);
							if(field.constants.length) {
								bool notes;
								foreach(constant ; field.constants) {
									if(constant.description.length) {
										notes = true;
										break;
									}
								}
								data ~= space ~ "\t\t<p><strong>Constants</strong>:</p>\n";
								data ~= space ~ "\t\t<table>\n";
								data ~= space ~ "\t\t\t<tr><th>Name</th><th>Value</th>" ~ (notes ? "<th></th>" : "") ~ "</tr>\n";
								foreach(constant ; field.constants) {
									data ~= space ~ "\t\t\t<tr>\n";
									data ~= space ~ "\t\t\t\t<td id=\"" ~ link(namespace ~ field.name ~ constant.name) ~ "\">" ~ constant.name.replace("_", " ") ~ "</td>\n";
									data ~= space ~ "\t\t\t\t<td class=\"center\">" ~ constant.value ~ "</td>\n";
									if(notes) data ~= space ~ "\t\t\t\t<td>" ~ constant.description.replaceAll(ctRegex!"`([^`]*)`", "<code>$1</code>") ~ "</td>\n";
									data ~= space ~ "\t\t\t</tr>\n";
								}
								data ~= space ~ "\t\t</table>\n";
							}
							data ~= space ~ "\t</li>\n";
						}
					}
					data ~= space ~ "</ul>\n";
				}
			}
		}
		// endianness
		data ~= "\t\t<h2 id=\"encoding\">Encoding</h2>\n";
		data ~= "\t\t<p><strong>Endianness</strong>:</p>\n";
		data ~= "\t\t<table>\n";
		string def = "big_endian";
		string[string] change;
		foreach(string type, string end; ptrs.data.endianness) {
			if(type != "*") change[type] = end;
		}
		string[] be, le;
		string[] used;
		foreach(string type ; ["short", "ushort", "int", "uint", "long", "ulong", "float", "double"]) {
			(){
				bool checkImpl(string ft) {
					auto t = ft in ptrs.data.arrays;
					if(t ? (*t).base.startsWith(type) || (*t).length.startsWith(type) : ft.startsWith(type)) {
						auto e = type in change ? change[type] : def;
						if(e == "big_endian") be ~= type;
						else le ~= type;
						return true;
					}
					return false;
				}
				bool check(Field field) {
					return checkImpl(field.type);
				}
				if(checkImpl(ptrs.data.id)) return;
				if(checkImpl(ptrs.data.arrayLength)) return;
				foreach(type ; ptrs.data.types) {
					foreach(field ; type.fields) if(check(field)) return;
				}
				foreach(section ; ptrs.data.sections) {
					foreach(packet ; section.packets) {
						foreach(field ; packet.fields) if(check(field)) return;
						foreach(variant ; packet.variants) {
							foreach(field ; variant.fields) if(check(field)) return;
						}
					}
				}
			}();
		}
		data ~= "\t\t\t<tr>\n\t\t\t\t<td>big endian</td>\n\t\t\t\t<td>" ~ be.join(", ") ~ "</td>\n\t\t\t</tr>\n";
		data ~= "\t\t\t<tr>\n\t\t\t\t<td>little endian</td>\n\t\t\t\t<td>" ~ le.join(", ") ~ "</td>\n\t\t\t</tr>\n";
		data ~= "\t\t</table>\n";
		data ~= "\t\t<p><strong>Ids</strong>: " ~ ptrs.data.id ~ "</p>\n";
		data ~= "\t\t<p><strong>Array's length</strong>: " ~ ptrs.data.arrayLength ~ "</p>\n";
		data ~= "\t\t<hr>\n";
		// sections (legend)
		data ~= "\t\t<h2 id=\"packets\">Packets</h2>\n";
		data ~= "\t\t<table>\n";
		data ~= "\t\t\t<tr>\n\t\t\t\t<th>Section</th>\n\t\t\t\t<th>Packets</th>\n\t\t\t</tr>\n";
		foreach(section ; ptrs.data.sections) {
			data ~= "\t\t\t<tr>\n";
			data ~= "\t\t\t\t<td><a href=\"" ~ game ~ "/" ~ section.name.replace("_", "-") ~ "\">" ~ pretty(toCamelCase(section.name)) ~ "</a></td>\n";
			data ~= "\t\t\t\t<td class=\"center\">" ~ to!string(section.packets.length) ~ "</td>\n";
			data ~= "\t\t\t</tr>\n";
		}
		data ~= "\t\t</table>\n";
		data ~= "\t</body>\n";
		data ~= "</html>";
		writeHtml("../pages/" ~ game ~ ".html", data);
		std.file.mkdirRecurse("../pages/" ~ game);

		// sections
		foreach(section ; ptrs.data.sections) {
			data = head(ptrs.software ~ " " ~ ptrs.protocol.to!string, true, gameName, ptrs.protocol.to!string, "/" ~ section.name);
			data ~= "\t\t<h2>" ~ pretty(toCamelCase(section.name)) ~ "</h2>\n";
			if(section.description.length) data ~= desc("\t\t", section.description);
			data ~= "\t\t<table>\n";
			data ~= "\t\t\t<tr>\n\t\t\t\t<th>Packets</th>\n\t\t\t\t<th>Id</th>\n\t\t\t\t<th>Clientbound</th>\n\t\t\t\t<th>Serverbound</th>\n\t\t\t</tr>\n";
			foreach(packet ; section.packets) {
				data ~= "\t\t\t<tr>\n";
				data ~= "\t\t\t\t<td><a href=\"" ~ section.name ~ "/" ~ packet.name.replace("_", "-") ~ "\">" ~ pretty(toCamelCase(packet.name)) ~ "</a></td>\n";
				data ~= "\t\t\t\t<td class=\"center\">" ~ packet.id.to!string ~ "</td>\n";
				//data ~= "\t\t\t\t<td class=\"center\">" ~ ("0" ~ packet.id.to!string(16))[$-2..$] ~ "₁₆</td>\n";
				data ~= "\t\t\t\t<td class=\"center\">" ~ (packet.clientbound ? "✓" : "") ~ "</td>\n";
				data ~= "\t\t\t\t<td class=\"center\">" ~ (packet.serverbound ? "✓" : "") ~ "</td>\n";
				data ~= "\t\t\t</tr>\n";
			}
			data ~= "\t\t</table>\n";
			data ~= "\t</body>\n";
			data ~= "</html>";
			writeHtml("../pages/" ~ game ~ "/" ~ section.name ~ ".html", data);
			std.file.mkdirRecurse("../pages/" ~ game ~ "/" ~ section.name);

			// packets
			foreach(packet ; section.packets) {
				data = head(ptrs.software ~ " " ~ ptrs.protocol.to!string, true, gameName, ptrs.protocol.to!string, "/" ~ section.name ~ "/" ~ packet.name.replace("_", "-"));
				data ~= "\t\t<p><a href=\"../../" ~ game ~ "\">" ~ game ~ "</a> / <strong><a href=\"../" ~ section.name ~ "\">" ~ section.name ~ "</a></strong></p>\n";
				data ~= "\t\t<h2>" ~ pretty(toCamelCase(packet.name)) ~ "</h2>\n";
				data ~= "\t\t<div class=\"desc\">\n";
				data ~= "\t\t\t<p><strong>Id</strong>: " ~ packet.id.to!string ~ "</p>\n";
				data ~= "\t\t\t<p><strong>Hex</strong>: " ~ ("00" ~ packet.id.to!string(16))[$-2..$] ~ "</p>\n";
				data ~= "\t\t\t<p><strong>Bin</strong>: " ~ ("00000000" ~ packet.id.to!string(2))[$-8..$] ~ "</p>\n";
				data ~= "\t\t\t<p>";
				if(packet.clientbound && packet.serverbound) data ~= "Sent by the <strong>server</strong> and the <strong>client</strong>";
				else if(packet.clientbound) data ~= "Sent by the <strong>server</strong>";
				else if(packet.serverbound) data ~= "Sent by the <strong>client</strong>";
				else data ~= "Unbounded (not sent by the <strong>server</strong> nor by the <strong>client</strong>";
				data ~= "</p>\n";
				data ~= "\t\t</div>\n";
				if(packet.description.length) data ~= desc("\t\t", packet.description);
				writeFields([], packet.fields, 4);
				if(packet.variants.length) {
					data ~= "\t\t<p><strong>Variants</strong>:</p>\n";
					data ~= "\t\t<table>\n";
					data ~= "\t\t\t<tr>\n";
					data ~= "\t\t\t\t<th>Variant</th>\n";
					data ~= "\t\t\t\t<th>Field</th>\n";
					data ~= "\t\t\t\t<th>Value</th>\n";
					data ~= "\t\t\t</tr>\n";
					foreach(variant ; packet.variants) {
						data ~= "\t\t\t<tr>\n";
						data ~= "\t\t\t\t<td><a href=\"#" ~ link(variant.name) ~ "\">" ~ pretty(toCamelCase(variant.name)) ~ "</a></td>\n";
						data ~= "\t\t\t\t<td>" ~ toCamelCase(packet.variantField) ~ "</td>\n";
						data ~= "\t\t\t\t<td class=\"center\">" ~ variant.value ~ "</td>\n";
						data ~= "\t\t\t</tr>\n";
					}
					data ~= "\t\t</table>\n";
					data ~= "\t\t<ul>\n";
					foreach(variant ; packet.variants) {
						data ~= "\t\t\t<li>\n";
						data ~= "\t\t\t\t<h3 id=\"" ~ link(variant.name) ~ "\">" ~ pretty(toCamelCase(variant.name)) ~ "</h3>\n";
						if(variant.description.length) data ~= desc("\t\t\t\t", variant.description);
						writeFields([variant.name], variant.fields, 6, "Additional Fields");
						data ~= "\t\t\t</li>\n";
					}
					data ~= "\t\t</ul>\n";
				}
				data ~= "\t</body>\n";
				data ~= "</html>";
				writeHtml("../pages/" ~ game ~ "/" ~ section.name ~ "/" ~ packet.name.replace("_", "-") ~ ".html", data);
			}
		}
		// types
		if(ptrs.data.types.length) {
			data = head(ptrs.software ~ " " ~ ptrs.protocol.to!string, true, gameName, ptrs.protocol.to!string, "/types");
			data ~= "\t\t<h2>Types</h2>\n";
			//TODO index table instead of jump to
			data ~= "\t</body>\n";
			data ~= "</html>";
			/+if(ptrs.data.types.length > 3) {
				string[] jt;
				foreach(type ; ptrs.data.types) {
					jt ~= "<a href=\"#" ~ link("types", type.name) ~ "\">" ~ pretty(toCamelCase(type.name)) ~ "</a>";
				}
				data ~= "\t\t<p><strong>Jump to</strong>: " ~ jt.join(", ") ~ "</p>\n";
			}+/
			writeHtml("../pages/" ~ game ~ "/types.html", data);
			std.file.mkdirRecurse("../pages/" ~ game ~ "/types");
			foreach(type ; ptrs.data.types) {
				data = head(ptrs.software ~ " " ~ ptrs.protocol.to!string, true, gameName, ptrs.protocol.to!string, "/types/" ~ type.name.replace("_", "-"));
				data ~= "\t\t<h2>" ~ pretty(toCamelCase(type.name)) ~ "</h2>\n";
				if(type.length.length) data ~= "\t\t<p>⚠️️ This type is prefixed with its length encoded as <strong>" ~ type.length ~ "</strong> ⚠️️</p>\n";
				if(type.description.length) data ~= desc("\t\t", type.description);
				writeFields([], type.fields, 2);
				data ~= "\t</body>\n";
				data ~= "</html>";
				writeHtml("../pages/" ~ game ~ "/types/" ~ type.name.replace("_", "-") ~ ".html", data);
			}
		}
		// arrays
		if(ptrs.data.arrays.length) {
			data = head(ptrs.software ~ " " ~ ptrs.protocol.to!string, true, gameName, ptrs.protocol.to!string, "/arrays");
			data ~= "\t\t<h2>Arrays</h2>\n";
			bool e = false;
			foreach(a ; ptrs.data.arrays) {
				e |= a.endianness.length != 0;
			}
			data ~= "\t\t<table>\n";
			data ~= "\t\t\t<tr>\n";
			data ~= "\t\t\t\t<th>Name</th>\n";
			data ~= "\t\t\t\t<th>Base</th>\n";
			data ~= "\t\t\t\t<th>Length</th>\n";
			if(e) data ~= "\t\t\t\t<th>Length's Endianness</th>\n";
			data ~= "\t\t\t</tr>\n";
			foreach(name, a ; ptrs.data.arrays) {
				data ~= "\t\t\t<tr id=\"" ~ link("types", name) ~ "\">\n";
				data ~= "\t\t\t\t<td>" ~ toCamelCase(name) ~ "</td>\n";
				data ~= "\t\t\t\t<td>" ~ convert(a.base) ~ "</td>\n";
				data ~= "\t\t\t\t<td>" ~ convert(a.length) ~ "</td>\n";
				if(e) data ~= "\t\t\t\t<td>" ~ a.endianness.replace("_", " ") ~ "</td>\n";
				data ~= "\t\t\t</tr>\n";
			}
			data ~= "\t\t</table>\n";
			data ~= "\t</body>\n";
			data ~= "</html>";
			writeHtml("../pages/" ~ game ~ "/arrays.html", data);
		}
		// metadata
		if(metadata) {
			data = head(ptrs.software ~ " " ~ ptrs.protocol.to!string, true, gameName, ptrs.protocol.to!string, "/metadata");
			data ~= "\t\t<h2>Metadata</h2>\n";
			data ~= "\t\t<ul>\n";
			// encoding
			data ~= "\t\t\t<li>\n";
			data ~= "\t\t\t\t<h3>Encoding</h3>\n";
			if((*metadata).data.prefix.length) data ~= "\t\t\t\t<p><strong>Prefix</strong>: " ~ (*metadata).data.prefix ~ "</p>\n";
			if((*metadata).data.length.length) data ~= "\t\t\t\t<p><strong>Length</strong>: " ~ (*metadata).data.length ~ "</p>\n";
			/*data ~= "[\n\n";
			data ~= "   Value's type (" ~ (*metadata).data.type ~ "\n\n";
			data ~= "   Value's id (" ~ (*metadata).data.id ~ "\n\n";
			data ~= "   Value (type varies)\n\n";
			data ~= "]\n\n";*/
			if((*metadata).data.suffix.length) data ~= "\t\t\t\t<p><strong>Suffix</strong>: " ~ (*metadata).data.suffix ~ "</p>\n";
			data ~= "\t\t\t</li>\n";
			// type
			bool e = false;
			foreach(type ; (*metadata).data.types) {
				if(type.endianness.length) e = true;
			}
			data ~= "\t\t\t<li>\n";
			data ~= "\t\t\t\t<h3>Types</h3>\n";
			data ~= "\t\t\t\t<table>\n";
			data ~= "\t\t\t\t\t<tr>\n";
			data ~= "\t\t\t\t\t\t<th>Name</th>\n";
			data ~= "\t\t\t\t\t\t<th>Type</th>\n";
			data ~= "\t\t\t\t\t\t<th>Id</th>\n";
			if(e) data ~= "\t\t\t\t\t\t<th>Endianness</th>\n";
			data ~= "\t\t\t\t\t</tr>\n";
			foreach(type ; (*metadata).data.types) {
				data ~= "\t\t\t\t\t<tr>\n";
				data ~= "\t\t\t\t\t\t<td>" ~ toCamelCase(type.name) ~ "</td>\n";
				data ~= "\t\t\t\t\t\t<td>" ~ convert(type.type) ~ "</td>\n";
				data ~= "\t\t\t\t\t\t<td class=\"center\">" ~ type.id.to!string ~ "</td>\n";
				if(e) data ~= "\t\t\t\t\t\t<td>" ~ type.endianness.replace("-", " ") ~ "</td>\n";
				data ~= "\t\t\t\t\t</tr>\n";
			}
			data ~= "\t\t\t\t</table>\n";
			data ~= "\t\t\t</li>\n";
			// data
			data ~= "\t\t\t<li>\n";
			data ~= "\t\t\t\t<h3>Data</h3>\n";
			data ~= "\t\t\t\t<table>\n";
			data ~= "\t\t\t\t\t<tr>\n";
			data ~= "\t\t\t\t\t\t<th>Name</th>\n";
			data ~= "\t\t\t\t\t\t<th>Type</th>\n";
			data ~= "\t\t\t\t\t\t<th colspan=\"2\">Id</th>\n";
			data ~= "\t\t\t\t\t\t<th>Default</th>\n";
			data ~= "\t\t\t\t\t\t<th>Required</th>\n";
			data ~= "\t\t\t\t\t</tr>\n";
			foreach(meta ; (*metadata).data.data) {
				data ~= "\t\t\t\t\t<tr>\n";
				data ~= "\t\t\t\t\t\t<td>";
				immutable name = pretty(toCamelCase(meta.name));
				if(meta.description.length || meta.flags.length) data ~= "<a href=\"#" ~ link(meta.name) ~ "\">" ~ name ~ "</a>";
				else data ~= name;
				data ~= "</td>\n";
				data ~= "\t\t\t\t\t\t<td>" ~ convert(meta.type) ~ "</td>\n";
				data ~= "\t\t\t\t\t\t<td class=\"center\">" ~ meta.id.to!string ~ "</td>\n";
				data ~= "\t\t\t\t\t\t<td class=\"center\">" ~ meta.id.to!string(16) ~ "₁₆</td>\n";
				data ~= "\t\t\t\t\t\t<td class=\"center\">" ~ meta.def ~ "</td>\n";
				data ~= "\t\t\t\t\t\t<td class=\"center\">" ~ (meta.required ? "✓" : "") ~ "</td>\n";
				data ~= "\t\t\t\t\t</tr>\n";
			}
			data ~= "\t\t\t\t</table>\n";
			data ~= "\t\t\t\t<ul>\n";
			foreach(meta ; (*metadata).data.data) {
				if(meta.description.length || meta.flags.length) {
					data ~= "\t\t\t\t\t<li>\n";
					data ~= "\t\t\t\t\t<h4 id=\"" ~ link(meta.name) ~ "\">" ~ pretty(toCamelCase(meta.name)) ~ "</h4>\n";
					if(meta.description.length) data ~= desc("\t\t\t\t\t", meta.description);
					if(meta.flags.length) {
						bool description;
						foreach(flag ; meta.flags) {
							if(flag.description.length) {
								description = true;
								break;
							}
						}
						data ~= "\t\t\t\t\t<table>\n";
						data ~= "\t\t\t\t\t\t<tr>\n";
						data ~= "\t\t\t\t\t\t\t<th>Flag</th>\n";
						data ~= "\t\t\t\t\t\t\t<th colspan=\"2\">Bit</th>\n";
						if(description) data ~= "\t\t\t\t\t\t\t<th>Description</th>\n";
						data ~= "\t\t\t\t\t\t</tr>\n";
						foreach(flag ; meta.flags) {
							data ~= "\t\t\t\t\t\t<tr>\n";
							data ~= "\t\t\t\t\t\t\t<td>" ~ flag.name.replace("_", " ") ~ "</td>\n";
							data ~= "\t\t\t\t\t\t\t<td class=\"center\">" ~ flag.bit.to!string ~ "</td>\n";
							data ~= "\t\t\t\t\t\t\t<td class=\"center\">" ~ flag.bit.to!string(16) ~ "₁₆</td>\n";
							if(description) data ~= "\t\t\t\t\t\t\t<td>" ~ flag.description.replace("\n", " ") ~ "</td>\n";
							data ~= "\t\t\t\t\t\t</tr>\n";
						}
						data ~= "\t\t\t\t\t</table>\n";
					}
					data ~= "\t\t\t\t\t</li>\n";
				}
			}
			data ~= "\t\t\t\t</ul>\n";
			data ~= "\t\t\t</li>\n";
			data ~= "\t\t</ul>\n";
			data ~= "\t</body>\n";
			data ~= "</html>";
			writeHtml("../pages/" ~ game ~ "/metadata.html", data);
		}
		// attributes
		if(attributes) {
			data = head(ptrs.software ~ " " ~ ptrs.protocol.to!string, true, gameName, ptrs.protocol.to!string, "/attributes");
			data ~= "\t\t<h2>Attributes</h2>\n";
			string[] jmp;
			foreach(attribute ; (*attributes).data) jmp ~= "<a href=\"#" ~ link(attribute.name) ~ "\"/>" ~ pretty(toCamelCase(attribute.id)) ~ "</a>";
			data ~= "\t\t<p><strong>Jump to</strong>: " ~ jmp.join(", ") ~ "</p>\n";
			data ~= "\t\t<ul>\n";
			foreach(attribute ; (*attributes).data) {
				data ~= "\t\t\t<li>\n";
				data ~= "\t\t\t\t<h3 id=\"" ~ link(attribute.id) ~ "\">" ~ pretty(toCamelCase(attribute.id)) ~ "</h3>\n";
				data ~= "\t\t\t\t<code class=\"attribute\">" ~ attribute.name ~ "</code>\n";
				data ~= "\t\t\t\t<div class=\"desc attribute\">\n";
				data ~= "\t\t\t\t\t<p><strong>Minimum</strong>: " ~ attribute.min.to!string ~ "</p>\n";
				data ~= "\t\t\t\t\t<p><strong>Maximum</strong>: " ~ attribute.max.to!string ~ "</p>\n";
				data ~= "\t\t\t\t\t<p><strong>Default</strong>: " ~ attribute.def.to!string ~ "</p>\n";
				data ~= "\t\t\t\t</div>\n";
				if(attribute.description.length) data ~= desc("\t\t\t\t", attribute.description);
				data ~= "\t\t\t</li>\n";
			}
			data ~= "\t\t</ul>\n";
		}
		data ~= "\t</body>\n</html>\n";
		data ~= "\t</body>\n";
		data ~= "</html>";
		writeHtml("../pages/" ~ game ~ "/attributes.html", data);
	}
	
	// index
	JSONValue[string] push_info;
	Tuple!(Protocol, size_t, string)[][string] p;
	foreach(game, prts; protocols) {
		p[prts.software] ~= tuple(prts.data, prts.protocol, game);
	}
	string data = head("Index", false);
	data ~= "\t\t<div style=\"padding-top:84px\"></div>\n";
	foreach(string name ; ["Minecraft", "Minecraft: Pocket Edition", "Raknet", "Hub-Node Communication", "External Console"]) {
		size_t date(string str) {
			auto spl = str.split("/");
			if(spl.length == 3) return (to!size_t(spl[0]) * 366 + to!size_t(spl[1])) * 31 + to!size_t(spl[2]);
			else return size_t.max;
		}
		string namespace = p[name][0][2][0..$-(p[name][0][1].to!string.length)];
		auto sorted = sort!((a, b) => date(a[0].released) > date(b[0].released))(p[name]).release();
		bool _released, _from, _to;
		foreach(pr ; sorted) {
			_released |= pr[0].released.length != 0;
			_from |= pr[0].from.length != 0;
			_to |= pr[0].to.length != 0;
		}
		data ~= "\t\t<h2><a href=\"" ~ namespace ~ "\">" ~ name ~ "</a></h2>\n";
		data ~= "\t\t<table>\n";
		data ~= "\t\t\t<tr>\n";
		data ~= "\t\t\t\t<th>Protocol</th>\n";
		data ~= "\t\t\t\t<th>Packets</th>\n";
		if(_released) data ~= "\t\t\t\t<th>Released</th>\n";
		if(_from) data ~= "\t\t\t\t<th>From</th>\n";
		if(_to) data ~= "\t\t\t\t<th>To</th>\n";
		data ~= "\t\t\t</tr>\n";
		JSONValue[] json;
		foreach(cp ; sorted) {
			json ~= JSONValue(cp[1]);
			immutable ps = to!string(cp[1]);
			size_t packets = 0;
			foreach(section ; cp[0].sections) packets += section.packets.length;
			data ~= "\t\t\t<tr>\n";
			data ~= "\t\t\t\t<td class=\"center\"><a href=\"" ~ cp[2][0..$-ps.length] ~ ps ~ "\">" ~ ps ~ "</a></td>\n";
			data ~= "\t\t\t\t<td class=\"center\">" ~ to!string(packets) ~ "</td>\n";
			if(_released) data ~= "\t\t\t\t<td class=\"center\">" ~ cp[0].released ~ "</td>\n";
			if(_from) data ~= "\t\t\t\t<td class=\"center\">" ~ cp[0].from ~ "</td>\n";
			if(_to) data ~= "\t\t\t\t<td class=\"center\">" ~ cp[0].to ~ "</td>\n";
			data ~= "\t\t\t</tr>\n";
		}
		size_t latest;
		foreach_reverse(cp ; sorted) {
			if(cp[0].released) latest = cp[1];
		}
		push_info[namespace] = JSONValue(["latest": JSONValue(latest), "protocols": JSONValue(json)]);
		data ~= "\t\t</table>\n";
		// copy latest (released) into game/index.html
		std.file.write("../pages/" ~ namespace ~ ".html", std.file.read("../pages/" ~ namespace ~ to!string(latest) ~ ".html")); //TODO replace canonical?
	}
	data ~= "\t</body>\n</html>\n";
	writeHtml("../pages/index.html", data);
	// write info for push.d to create branches
	std.file.write("../push_info.json", JSONValue(push_info).toString());

}

string head(string title, bool back, string game="", string protocol="", string section="") {
	return "<!DOCTYPE html>\n<html lang=\"en\">\n" ~
			"\t<head>\n\t\t<meta charset=\"UTF-8\" />\n" ~
			"\t\t<title>" ~ title ~ "</title>\n" ~
			"\t\t<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\" />\n" ~
			"\t\t<meta name=\"theme-color\" content=\"#1E2327\" />\n" ~
			//(description.length ? "\t\t<meta name=\"description\" content=\"" ~ description.replace(`"`, `\"`) ~ "\" />\n" : "") ~
			"\t\t<link rel=\"icon\" type=\"image/png\" href=\"/favicon.png\" />\n" ~
			"\t\t<link rel=\"canonical\" href=\"https://sel-utils.github.io/protocol/" ~ game ~ protocol ~ section ~ "\" />\n" ~
			"\t\t<link rel=\"stylesheet\" href=\"/style.css\" />\n" ~
			"\t\t<link rel=\"stylesheet\" href=\"https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.9.0/styles/github.min.css\" />\n" ~
			"\t\t<script src=\"https://apis.google.com/js/platform.js\" async defer></script>\n" ~
			"\t\t<script src=\"https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.9.0/highlight.min.js\"></script>\n" ~
			"\t\t<script>hljs.initHighlightingOnLoad();</script>\n" ~
			"\t\t<script src=\"https://platform.twitter.com/widgets.js\"></script>\n" ~
			"\t\t<script>(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)})(window,document,'script','https://www.google-analytics.com/analytics.js','ga');ga('create', 'UA-98448660-1', 'auto');ga('send', 'pageview');</script>\n" ~
			"\t</head>\n" ~
			"\t<body>\n" ~
			"\t\t<div class=\"nav\">" ~
			"<a href=\"/protocol/\">Index</a>  " ~
			"<a href=\"https://github.com/sel-project/sel-utils/blob/master/README.md\">About</a>    " ~
			"<a href=\"https://github.com/sel-project/sel-utils/blob/master/TYPES.md\">Types</a>    " ~
			"<a href=\"https://github.com/sel-project/sel-utils/blob/master/CONTRIBUTING.md\">Contribute</a>    " ~
			(game.length ? "<a href=\"https://github.com/sel-project/sel-utils/blob/master/xml/protocol/" ~ game ~ protocol ~ ".xml\">XML</a>    " : "") ~
			"<a href=\"https://github.com/sel-project/sel-utils\">Github</a></div></div>\n" ~
			"\t\t</div>\n" ~
			"\t\t<div class=\"logo\" onclick=\"if(document.body.classList.contains('dark')){document.body.classList.remove('dark');}else{document.body.classList.add('dark');}\"></div>\n"; //TODO remember theme
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

string desc(string space, string description) {
	string ret;
	bool code = false, list = false;
	foreach(s ; description
		.replaceAll(ctRegex!`[\r\t]+`, "")
		.replaceAll(ctRegex!`\[([a-zA-Z0-9_\-\.]+)\]\((#[a-z0-9_\-]+)\)`, `<a href="$2">$1</a>`)
		.replaceAll(ctRegex!`\[([a-zA-Z0-9_\-\. ]+)\]\(([a-zA-Z0-9_\-\.\:\/\#]+)\)`, `<a href="$2" target="_blank">$1</a>`)
		.split("\n")) {

		if(code) {
			if(s.startsWith("```")) {
				ret ~= "</code>\n" ~ space ~ "</pre>\n";
				code = false;
			} else {
				ret ~= s ~ "\n";
			}
		} else {
			if(!s.length) continue;
			if(s.startsWith("+ ")) {
				if(!list) {
					ret ~= space ~ "<ul>\n";
					list = true;
				}
				ret ~= space ~ "\t<li>" ~ s[2..$].strip ~ "</li>\n";
				continue;
			} else if(list) {
				ret ~= space ~ "</ul>\n";
				list = false;
			}
			if(s.startsWith("```")) {
				ret ~= space ~ "<pre>\n" ~ space ~ "\t<code class=\"" ~ s[3..$] ~ "\">";
				code = true;
			} else {
				string h = "######";
				while((h = h[1..$]).length) {
					if(s.startsWith(h)) {
						ret ~= space ~ "<h" ~ to!string(h.length) ~ ">" ~ s[h.length..$].strip ~ "</h" ~ to!string(h.length) ~ ">\n";
						break;
					}
				}
				if(!h.length) ret ~= space ~ "<p>" ~ s.replaceAll(ctRegex!"`([^`]+)`", `<code>$1</code>`) ~ "</p>\n";
			}
		}
	}
	if(list) ret ~= space ~ "</ul>\n";
	return ret;
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
