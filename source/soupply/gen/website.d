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
module soupply.website;

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

import transforms : snakeCase, camelCaseLower, camelCaseUpper;

class DocsGenerator : Generator {

	static this() {
		Generator.register!DocsGenerator("soupply.github.io", "");
	}

	protected override void generateImpl(Data _data) {
		
		enum defaultTypes = ["bool", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "string", "varshort", "varushort", "varint", "varuint", "varlong", "varulong", "triad", "uuid", "bytes"];

		Maker make(string path) {
			auto ret = new Maker(this, path, "md");
			ret.line("---").line("layout: default").line("---").nl;
			return ret;
		}

		foreach(string game, info; _data.info) {

			immutable gameName = info.game;

			Maker head(string[] location...) {
				foreach(ref l ; location) l = l.replace("_", "-");
				location = game ~ location;
				auto ret = make("protocol/" ~ join(location, "/"));
				// add navigation
				string[] links = ["[home](/)"];
				foreach(i, nav; location) {
					if(i < location.length - 1) links ~= "[" ~ nav ~ "](/protocol/" ~ join(location[0..i+1], "/") ~ ")";
					else links ~= nav;
				}
				ret.line(links.join("  /  ")).nl;
				// add title
				ret.line("# " ~ pretty(location[$-1].replace("-", " "))).nl;
				return ret;
			}

			@property string convert(string type) {
				auto array = type.indexOf("[");
				auto tup = type.indexOf("<");
				if(array >= 0) return convert(type[0..array]) ~ type[array..$];
				else if(tup >= 0) return convert(type[0..tup]) ~ type[tup..$].replace("<", "&lt;").replace(">", "&gt;");
				else if(type == "metadata") return "[metadata](/protocol/" ~ game ~ "/metadata)";
				else if(defaultTypes.canFind(type)) return type;
				else if(type in info.protocol.arrays) return "[" ~ camelCaseLower(type) ~ "](/protocol/" ~ game ~ "/arrays)";
				else return "[" ~ camelCaseLower(type) ~ "](/protocol/" ~ game ~ "/types/" ~ type.replace("_", "-") ~ ")";
			}

			auto data = make("protocol/" ~ game);
			data.line("# " ~ info.software ~ " " ~ info.version_.to!string).nl; // title
			uint[] others;
			foreach(otherGame, oi; _data.info) {
				if(otherGame != game && oi.game == info.game) {
					others ~= oi.version_;
				}
			}
			if(others.length) {
				sort(others);
				string[] str, cmp;
				foreach(o ; others) {
					str ~= "[" ~ o.to!string ~ "](./" ~ game ~ ")";
					cmp ~= "[" ~ o.to!string ~ "](../diff/" ~ info.game ~ "/" ~ to!string(min(info.version_, o)) ~ "-" ~ to!string(max(info.version_, o)) ~ ")";
				}
				data.line("**Other protocols**: " ~ str.join(", ")).nl;
				data.line("**Compare changes**: " ~ cmp.join(", ")).nl;
			}
			string[] jumps = ["[Encoding](#encoding)", "[Packets](#packets)"];
			if(info.protocol.types.length) jumps ~= "[Types](" ~ game ~ "/types)";
			if(info.protocol.arrays.length) jumps ~= "[Arrays](" ~ game ~ "/arrays)";
			jumps ~= "[Metadata](" ~ game ~ "/metadata)";
			data.line("**Jump to**: " ~ jumps.join(", ")).nl;
			if(info.released.length) {
				auto spl = info.released.split("/");
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
			if(info.from.length) {
				if(info.to.length) {
					if(info.from == info.to) data.line("Used in version **" ~ info.from ~ "**");
					else data.line("Used from version **" ~ info.from ~ "** to **" ~ info.to ~ "**");
				} else {
					data.line("In use since version **" ~ info.from ~ "**");
				}
				data.nl;
			}
			if(info.description.length) {
				data.line("-----");
				data.line(info.description).nl;
				data.line("-----");
			}

			// endianness
			data.line("## Encoding").nl;
			//TODO encoding format (id, body) or (id, padding, body)
			data.line("**Endianness**:").nl;
			string def = "big_endian";
			string[string] change;
			foreach(string type, string end; info.protocol.endianness) {
				if(type != "*") change[type] = end;
			}
			string[] be, le;
			string[] used;
			foreach(string type ; ["short", "ushort", "int", "uint", "long", "ulong", "float", "double"]) {
				(){
					bool checkImpl(string ft) {
						auto t = ft in info.protocol.arrays;
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
					if(checkImpl(info.protocol.id)) return;
					if(checkImpl(info.protocol.arrayLength)) return;
					foreach(type ; info.protocol.types) {
						foreach(field ; type.fields) if(check(field)) return;
					}
					foreach(section ; info.protocol.sections) {
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
			data.line("**Ids**: " ~ info.protocol.id).nl;
			data.line("**Array's length**: " ~ info.protocol.arrayLength).nl;
			if(info.protocol.padding) data.line("**Padding**: " ~ info.protocol.padding.to!string ~ " bytes").nl;
			data.line("-----");

			// sections (legend)
			data.line("## Packets").nl;
			data.line("Section | Packets");
			data.line("---|:---:");
			foreach(section ; info.protocol.sections) {
				data.line("[" ~ pretty(camelCaseLower(section.name)) ~ "](" ~ game ~ "/" ~ section.name.replace("_", "-") ~ ") | " ~ to!string(section.packets.length));
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
									data.line("**Constants**:").nl;
									data.line("Name | Value" ~ (notes ? " |  |" : ""));
									data.line("---|:---:" ~ (notes ? "|---" : ""));
									foreach(constant ; field.constants) {
										data.put(constant.name.replace("_", " "));
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
			foreach(section ; info.protocol.sections) {

				data = head(section.name);
				if(section.description.length) data.line(section.description).nl;
				data.line("Packet | Id | Clientbound | Serverbound");
				data.line("---|:---:|:---:|:---:");
				foreach(packet ; section.packets) {
					data.put("[" ~ pretty(camelCaseLower(packet.name)) ~ "](" ~ section.name ~ "/" ~ packet.name.replace("_", "-") ~ ") | " ~ to!string(packet.id) ~ " | ");
					data.put((packet.clientbound ? "✓" : " ") ~ " | " ~ (packet.serverbound ? "✓" : " "));
					data.nl;
				}
				data.nl;
				data.save();

				// packets
				foreach(packet ; section.packets) {
				
					data = head(section.name, packet.name);
					data.line("Encode/decode this packet in [Sandbox](../../../sandbox/" ~ game ~ "#" ~ camelCaseUpper(section.name) ~ "." ~ camelCaseUpper(packet.name) ~ ")").nl;
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
							data.line("[" ~ pretty(camelCaseLower(variant.name)) ~ "](#" ~ variant.name ~ ") | " ~ camelCaseLower(packet.variantField) ~ " | " ~ variant.value);
						}
						data.nl;
						foreach(variant ; packet.variants) {
							data.line("### " ~ pretty(camelCaseLower(variant.name))).nl;
							if(variant.description.length) data.line(variant.description).nl;
							writeFields([variant.name], variant.fields, "### Additional Fields");
						}
					}
					data.save();
				}
			}

			// types
			if(info.protocol.types.length) {

				data = head("types");
				//TODO
				data.save();

				foreach(type ; info.protocol.types) {
					data = head("types", type.name);
					if(type.length.length) data.line("⚠️️ This type is prefixed with its length encoded as **" ~ type.length ~ "** ⚠️️").nl;
					if(type.description.length) data.line(type.description).nl;
					writeFields([], type.fields);
					data.save();
				}

			}

			// arrays
			if(info.protocol.arrays.length) {

				data = head("arrays");
				bool e = false;
				foreach(a ; info.protocol.arrays) {
					e |= a.endianness.length != 0;
				}
				data.put("Name | Base | Length");
				if(e) data.put(" | Length's endianness");
				data.nl;
				data.put("---|---|---");
				if(e) data.put("|---");
				data.nl;
				foreach(name, a ; info.protocol.arrays) {
					data.line(camelCaseLower(name) ~ " | " ~ convert(a.base) ~ " | " ~ convert(a.length) ~ (e ? " | " ~ a.endianness.replace("_", " ") : ""));
				}
				data.save();

			}

			// metadata
			data = head("metadata");

			// encoding
			data.line("## Encoding").nl;
			if(info.metadata.prefix.length) data.line("**Prefix**: " ~ info.metadata.prefix).nl;
			if(info.metadata.length.length) data.line("**Length**: " ~ info.metadata.length).nl;
			/*data ~= "[\n\n";
			data ~= "   Value's type (" ~ (*metadata).data.type ~ "\n\n";
			data ~= "   Value's id (" ~ (*metadata).data.id ~ "\n\n";
			data ~= "   Value (type varies)\n\n";
			data ~= "]\n\n";*/
			if(info.metadata.suffix.length) data.line("**Suffix**: " ~ info.metadata.suffix).nl;

			// types
			bool e = false;
			foreach(type ; info.metadata.types) {
				if(type.endianness.length) e = true;
			}
			data.line("## Types").nl;
			data.line("Name | Type | Id" ~ (e ? " | Endianness" : ""));
			data.line("---|---|:---:" ~ (e ? "|---" : ""));
			foreach(type ; info.metadata.types) {
				data.line(camelCaseLower(type.name) ~ " | " ~ convert(type.type) ~ " | " ~ to!string(type.id) ~ (e ? " | " ~ type.endianness.replace("_", " ") : ""));
			}
			data.nl;

			// data
			data.line("## Data");
			data.line("Name | Type | Id | Default | Required");
			data.line("---|---|---|---|---");
			foreach(meta ; info.metadata.data) {
				immutable name = pretty(camelCaseLower(meta.name));
				if(meta.description.length || meta.flags.length) data.put("[" ~ name ~ "](#" ~ name.toLower.replace(" ", "-") ~ ")");
				else data.put(name);
				data.put(" | " ~ convert(meta.type) ~ " | " ~ to!string(meta.id) ~ " | " ~ meta.default_ ~ " | " ~ (meta.required ? "✓" : " "));
				data.nl;
			}
			data.nl;

			// data's description and flags
			foreach(meta ; info.metadata.data) {
				if(meta.description.length || meta.flags.length) {
					data.line("### " ~ pretty(camelCaseLower(meta.name))).nl;
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
		
		// index
		auto data = make("index");
		Info[][string] games;
		foreach(game, info; _data.info) {
			games[info.game] ~= info;
		}
		foreach(game, info; games) {
			sort!((a, b) => a.version_ > b.version_)(info);
			data.line("## [" ~ info[0].software ~ "](protocol/" ~ game ~ to!string(info[0].version_) ~ ")").nl;
			data.line("Protocol | Packets | Released | From | To");
			data.line(":---:|:---:|:---:|:---:|:---:");
			foreach(ci ; info) {
				size_t packets = 0;
				foreach(section ; ci.protocol.sections) packets += section.packets.length;
				data.put("[" ~ to!string(ci.version_) ~ "](protocol/" ~ ci.game ~ to!string(ci.version_) ~ ") | " ~ to!string(packets));
				data.put(" | " ~ ci.released);
				data.put(" | " ~ ci.from);
				data.put(" | " ~ ci.to);
				data.nl;
			}
			data.nl;
		}
		data.save();

	}

}

/+string head(string title, bool back, string game="", string protocol="", string section="") {
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
}+/

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

class DiffGenerator : Generator {

	static this() {
		Generator.register!DiffGenerator("soupply.github.io", "diff");
	}

	protected override void generateImpl(Data data) {

		Info[][string] games;

		foreach(info ; data.info) {
			games[info.game] ~= info;
		}

		foreach(game, others; games) {

			while(others.length > 1) {

				Info a = others[0];
				others = others[1..$];

				foreach(b ; others) {

					immutable newer = to!string(min(a.version_, b.version_));
					immutable older = to!string(max(a.version_, b.version_));

					with(new Maker(this, game ~ "/" ~ newer ~ "-" ~ older, "md")) {

						line("# " ~ a.software).nl;
						line("Changes from protocol **" ~ newer ~ "** to **" ~ older ~ "**").nl;
						line("__This page is still under construction__");
						save();

					}

				}

			}

		}

	}

}

class SandboxGenerator : Generator {

	static this() {
		Generator.register!SandboxGenerator("soupply.github.io", "sandbox");
	}

	protected override void generateImpl(Data data) {

		foreach(game, info; data.info) {

			with(new Maker(this, game, "html")) {

				line("<!DOCTYPE html>");
				line("<head>").add_indent();
				line("<title>Soupply's sandbox</title>");
				line("<script src='buffer.js'></script>");
				line("<script src='sandbox.js'></script>");
				string[] sections = ["types"];
				foreach(section ; info.protocol.sections) sections ~= section.name;
				foreach(section ; sections) {
					line("<script src='src/" ~ game ~ "/" ~ section ~ ".js'></script>");
				}
				remove_indent();
				line("</head>");

				save();

			}

		}

	}

}
