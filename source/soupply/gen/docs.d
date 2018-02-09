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
module soupply.docs;

import std.algorithm : min, max, canFind, sort;
import std.conv : to;
static import std.file;
import std.json : JSONValue;
import std.regex : ctRegex, replaceAll, matchFirst;
import std.string;
import std.typecons : Tuple, tuple;

import soupply.data;
import soupply.generator;
import soupply.util;

class DocsGenerator : Generator {

	static this() {
		Generator.register!DocsGenerator("soupply.github.io", "");
	}

	protected override void generateImpl(Data _data) {
		
		enum defaultTypes = ["bool", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "string", "varshort", "varushort", "varint", "varuint", "varlong", "varulong", "triad", "uuid", "bytes"];

		Source source(string path) {
			auto ret = new Source(this, path, "md");
			ret.line("---").line("layout: default").line("---").nl;
			return ret;
		}

		foreach(string game, Protocols ptrs; _data.protocols) {

			immutable gameName = game[0..$-ptrs.protocol.to!string.length];

			Source head(string[] location...) {
				foreach(ref l ; location) l = l.replace("_", "-");
				location = game ~ location;
				auto ret = source("protocol/" ~ join(location, "/"));
				// add navigation
				string[] links = ["[home](/)"];
				foreach(i, nav; location) {
					if(i < location.length - 1) links ~= "[" ~ nav ~ "](/protocol/" ~ join(location[0..i+1], "/") ~ ")";
					else links ~= nav;
				}
				ret.line(links.join("  /  ")).nl;
				// add title
				ret.line("# " ~ pretty(toCamelCase(location[$-1]))).nl;
				return ret;
			}

			@property string convert(string type) {
				auto array = type.indexOf("[");
				auto tup = type.indexOf("<");
				if(array >= 0) return convert(type[0..array]) ~ type[array..$];
				else if(tup >= 0) return convert(type[0..tup]) ~ type[tup..$].replace("<", "&lt;").replace(">", "&gt;");
				else if(type == "metadata") return "[metadata](/protocol/" ~ game ~ "/metadata)";
				else if(defaultTypes.canFind(type)) return type;
				else if(type in ptrs.data.arrays) return "[" ~ toCamelCase(type) ~ "](/protocol/" ~ game ~ "/arrays)";
				else return "[" ~ toCamelCase(type) ~ "](/protocol/" ~ game ~ "/types/" ~ type.replace("_", "-") ~ ")";
			}

			auto metadata = game in _data.metadatas;

			auto data = source("protocol/" ~ game);
			data.line("# " ~ ptrs.software ~ " " ~ ptrs.protocol.to!string).nl; // title
			uint[] others;
			foreach(otherGame, op; _data.protocols) {
				if(otherGame != game && otherGame.startsWith(gameName)) {
					others ~= to!uint(otherGame[gameName.length..$]);
				}
			}
			if(others.length) {
				sort(others);
				string[] str;
				foreach(o ; others) {
					str ~= "[" ~ o.to!string ~ "](./" ~ game ~ ")";
				}
				//data ~= "\t\t<p><strong>Compare</strong>: " ~ str.join(", ") ~ "</p>\n";
				data.line("**Other protocols**: " ~ str.join(", ")).nl;
			}
			string[] jumps = ["[Encoding](#encoding)", "[Packets](#packets)"];
			if(ptrs.data.types.length) jumps ~= "[Types](" ~ game ~ "/types)";
			if(ptrs.data.arrays.length) jumps ~= "[Arrays](" ~ game ~ "/arrays)";
			if(metadata) jumps ~= "[Metadata](" ~ game ~ "/metadata)";
			data.line("**Jump to**: " ~ jumps.join(", ")).nl;
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
					immutable month = ["January", "February", "March", "April", "May"," June", "July", "August", "September", "October", "November", "December"][to!size_t(spl[1]) - 1];
					data.line("**Released**: " ~ month ~ " " ~ day ~ ", " ~ spl[0]).nl;
				}
			}
			if(ptrs.data.from.length) {
				if(ptrs.data.to.length) {
					if(ptrs.data.from == ptrs.data.to) data.line("Used in version **" ~ ptrs.data.from ~ "**");
					else data.line("Used from version **" ~ ptrs.data.from ~ "** to **" ~ ptrs.data.to ~ "**");
				} else {
					data.line("In use since version **" ~ ptrs.data.from ~ "**");
				}
				data.nl;
			}
			if(ptrs.data.description.length) {
				data.line("-----");
				data.line(ptrs.data.description).nl;
				data.line("-----");
			}

			// endianness
			data.line("## Encoding").nl;
			data.line("**Endianness**:").nl;
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
					bool check(Protocol.Field field) {
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
			data.line("big endian | little endian");
			data.line("---|---");
			data.line(be.join(", ") ~ " | " ~ le.join(", ")).nl;
			data.line("**Ids**: " ~ ptrs.data.id).nl;
			data.line("**Array's length**: " ~ ptrs.data.arrayLength).nl;
			data.line("-----");

			// sections (legend)
			data.line("## Packets").nl;
			data.line("Section | Packets");
			data.line("---|:---:");
			foreach(section ; ptrs.data.sections) {
				data.line("[" ~ pretty(toCamelCase(section.name)) ~ "](" ~ game ~ "/" ~ section.name.replace("_", "-") ~ ") | " ~ to!string(section.packets.length));
			}
			data.save();
			
			// field (generic)
			void writeFields(string[] namespace, Protocol.Field[] fields, string fieldsDesc="## Fields") {
				if(fields.length) {
					data.line(fieldsDesc).nl;
					bool endianness, condition, default_;
					foreach(field ; fields) {
						endianness |= field.endianness.length != 0;
						condition |= field.condition.length != 0;
						default_ |= field.default_.length != 0;
					}
					data.put("Name | Type");
					if(endianness) data.put(" | Endianness");
					if(condition) data.put(" | When");
					if(default_) data.put(" | Default");
					data.nl;
					data.put("---|---");
					if(endianness) data.put("|:---:");
					if(condition) data.put("|:---:");
					if(default_) data.put("|:---:");
					data.nl;
					bool descripted = false;
					foreach(field ; fields) {
						if(field.description.length || field.constants.length) {
							descripted = true;
							data.put("[" ~ field.name.replace("_", " ") ~ "](#" ~ link(namespace ~ field.name) ~ ")");
						} else {
							data.put(field.name.replace("_", " "));
						}
						data.put(" | " ~ convert(field.type));
						if(endianness) data.put(" | " ~ field.endianness.replace("_", " "));
						if(condition) data.put(" | " ~ (field.condition.length ? cond(field.condition.replace("_", " ")) : ""));
						if(default_) data.put(" | " ~ field.default_);
						data.nl;
					}
					data.nl;
					if(descripted) {
						foreach(field ; fields) {
							if(field.description.length || field.constants.length) {
								data.line("### " ~ field.name.replace("_", " ")).nl;
								if(field.description.length) data.line(field.description).nl;
								if(field.constants.length) {
									bool notes;
									foreach(constant ; field.constants) {
										if(constant.description.length) {
											notes = true;
											break;
										}
									}
									data.line("**Constants**:");
									data.line("Name | Value" ~ (notes ? " |  |" : ""));
									data.line("---|:---:" ~ (notes ? "|---" : ""));
									foreach(constant ; field.constants) {
										data.put("[" ~ constant.name.replace("_", " ") ~ "](" ~ link(namespace ~ field.name ~ constant.name) ~ ")");
										data.put(" | " ~ constant.value);
										if(notes) data.put(" | " ~ constant.description);
										data.nl;
									}
									data.nl;
								}
							}
						}
					}
				}
			}

			// sections
			foreach(section ; ptrs.data.sections) {

				data = head(section.name);
				if(section.description.length) data.line(section.description).nl;
				data.line("Packet | Id | Clientbound | Serverbound");
				data.line("---|:---:|:---:|:---:");
				foreach(packet ; section.packets) {
					data.put("[" ~ pretty(toCamelCase(packet.name)) ~ "](" ~ section.name ~ packet.name.replace("_", "-") ~ ") | " ~ to!string(packet.id) ~ " | ");
					data.put((packet.clientbound ? "✓" : " ") ~ " | " ~ (packet.serverbound ? "✓" : " "));
					data.nl;
				}
				data.nl;
				data.save();

				// packets
				foreach(packet ; section.packets) {
				
					data = head(section.name, packet.name);
					data.line("**Id**: " ~ packet.id.to!string).nl;
					data.line("**Id** (hex): " ~ ("00" ~ packet.id.to!string(16))[$-2..$]).nl;
					data.line("**Id** (bin): " ~ ("00000000" ~ packet.id.to!string(2))[$-8..$]).nl;
					data.line("**Clientbound**: " ~ (packet.clientbound ? "✔️" : "✖️")).nl;
					data.line("**Serverbound**: " ~ (packet.serverbound ? "✔️" : "✖️")).nl;
					if(packet.description.length) data.line(packet.description).nl;
					writeFields([], packet.fields);
					if(packet.variants.length) {
						data.line("## Variants").nl;
						data.line("Variant | Field | Value");
						data.line("---|---|:---:");
						foreach(variant ; packet.variants) {
							data.line("[" ~ pretty(toCamelCase(variant.name)) ~ "](#" ~ variant.name ~ ") | " ~ toCamelCase(packet.variantField) ~ " | " ~ variant.value);
						}
						data.nl;
						foreach(variant ; packet.variants) {
							data.line("### " ~ pretty(toCamelCase(variant.name))).nl;
							if(variant.description.length) data.line(variant.description).nl;
							writeFields([variant.name], variant.fields, "### Additional Fields");
						}
					}
					data.save();
				}
			}

			// types
			if(ptrs.data.types.length) {

				data = head("types");
				//TODO
				data.save();

				foreach(type ; ptrs.data.types) {
					data = head("types", type.name);
					if(type.length.length) data.line("⚠️️ This type is prefixed with its length encoded as **" ~ type.length ~ "** ⚠️️").nl;
					if(type.description.length) data.line(type.description).nl;
					writeFields([], type.fields);
					data.save();
				}

			}

			// arrays
			if(ptrs.data.arrays.length) {

				data = head("arrays");
				bool e = false;
				foreach(a ; ptrs.data.arrays) {
					e |= a.endianness.length != 0;
				}
				data.put("Name | Base | Length");
				if(e) data.put(" | Length's endianness");
				data.nl;
				data.put("---|---|---");
				if(e) data.put("|---");
				data.nl;
				foreach(name, a ; ptrs.data.arrays) {
					data.line(toCamelCase(name) ~ " | " ~ convert(a.base) ~ " | " ~ convert(a.length) ~ (e ? " | " ~ a.endianness.replace("_", " ") : ""));
				}
				data.save();

			}

			// metadata
			if(metadata) {

				data = head("metadata");

				// encoding
				data.line("## Encoding").nl;
				if((*metadata).data.prefix.length) data.line("**Prefix**: " ~ (*metadata).data.prefix).nl;
				if((*metadata).data.length.length) data.line("**Length**: " ~ (*metadata).data.length).nl;
				/*data ~= "[\n\n";
				data ~= "   Value's type (" ~ (*metadata).data.type ~ "\n\n";
				data ~= "   Value's id (" ~ (*metadata).data.id ~ "\n\n";
				data ~= "   Value (type varies)\n\n";
				data ~= "]\n\n";*/
				if((*metadata).data.suffix.length) data.line("**Suffix**: " ~ (*metadata).data.suffix).nl;

				// types
				bool e = false;
				foreach(type ; (*metadata).data.types) {
					if(type.endianness.length) e = true;
				}
				data.line("## Types").nl;
				data.line("Name | Type | Id" ~ (e ? " | Endianness" : ""));
				data.line("---|---|:---:" ~ (e ? "|---" : ""));
				foreach(type ; (*metadata).data.types) {
					data.line(toCamelCase(type.name) ~ " | " ~ convert(type.type) ~ " | " ~ to!string(type.id) ~ (e ? " | " ~ type.endianness.replace("_", " ") : ""));
				}
				data.nl;

				// data
				data.line("## Data");
				data.line("Name | Type | Id | Default | Required");
				data.line("---|---|---|---|---");
				foreach(meta ; (*metadata).data.data) {
					immutable name = pretty(toCamelCase(meta.name));
					if(meta.description.length || meta.flags.length) data.put("[" ~ name ~ "](#" ~ name.toLower.replace(" ", "-") ~ ")");
					else data.put(name);
					data.put(" | " ~ convert(meta.type) ~ " | " ~ to!string(meta.id) ~ " | " ~ meta.default_ ~ " | " ~ (meta.required ? "✓" : " "));
					data.nl;
				}
				data.nl;

				// data's description and flags
				foreach(meta ; (*metadata).data.data) {
					if(meta.description.length || meta.flags.length) {
						data.line("### " ~ pretty(toCamelCase(meta.name))).nl;
						if(meta.description.length) data.line(meta.description).nl;
						if(meta.flags.length) {
							bool description;
							foreach(flag ; meta.flags) {
								if(flag.description.length) {
									description = true;
									break;
								}
							}
							data.line("Flag | Bit" ~ (description ? " | Description" : ""));
							data.line("---|---" ~ (description ? " | Description" : ""));
							foreach(flag ; meta.flags) {
								data.line(flag.name.replace("_", " ") ~ " | " ~ flag.bit.to!string ~ (description ? " | " ~ flag.description.replace("\n", " ") : ""));
							}
						}
					}
				}
				data.save();
			}

		}
		
		// index
		Tuple!(Protocol, uint, string)[][string] p;
		foreach(game, prts; _data.protocols) {
			p[prts.software] ~= tuple(prts.data, prts.protocol, game);
		}
		auto data = source("index");
		//TODO description
		foreach(string name ; ["Minecraft: Java Edition", "Minecraft (Bedrock Engine)", "Minecraft: Pocket Edition", "Raknet"]) {
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
			data.line("## [" ~ name ~ "](protocol/" ~ namespace ~ ")").nl;
			data.line("Protocol | Packets | Released | From | To");
			data.line(":---:|:---:|:---:|:---:|:---:");
			foreach(cp ; sorted) {
				immutable ps = to!string(cp[1]);
				size_t packets = 0;
				foreach(section ; cp[0].sections) packets += section.packets.length;
				data.put("[" ~ ps ~ "](" ~ cp[2][0..$-ps.length] ~ ps ~ ") | " ~ to!string(packets));
				if(_released) data.put(" | " ~ cp[0].released);
				if(_from) data.put(" | " ~ cp[0].from);
				if(_to) data.put(" | " ~ cp[0].to);
				data.nl;
			}
			data.nl;
			size_t latest = sorted[0][1];
			foreach_reverse(cp ; sorted) {
				if(cp[0].released) latest = cp[1];
			}
			//TODO copy latest (released) into game/index.html using `latest`
			//std.file.write("../pages/" ~ namespace ~ ".html", std.file.read("../pages/" ~ namespace ~ to!string(latest) ~ ".html")); //TODO replace canonical?
		}
		data.save();

	}

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
