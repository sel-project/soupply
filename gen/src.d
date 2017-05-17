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
module src;

import std.algorithm : sort, max, canFind, count;
import std.base64;
import std.conv : to, ConvException;
import std.datetime : StopWatch, AutoStart;
static import std.file;
import std.json;
import std.math : isNaN;
import std.path : dirSeparator;
import std.stdio : writeln;
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

struct Options {

	struct Repo {

		struct Badge {

			string image, url, alt;

		}

		bool exists = false;

		string name, src;
		string[] exclude, include;
		bool tag;
		Badge[] badges;

		alias exists this;

	}
	
	Repo repo;

	string indentation = "tabs";

	string start = "";
	string end = "\n";

	bool stripEmptyLines = true;

	struct Header {

		bool exists = true;

		string open = "/*";
		string line = " * ";
		string close = " */";

		alias exists this;

	}

	Header header;

	struct Types {

		string[string] names;

		string[string] basic;
		string[size_t] tuples;
		string arrays;
		string fixedArrays;
		string metadata;
		string others;

	}

	Types types;

	struct Default {

		string number;
		string type;
		string str;
		string array, fixedArray;
		string uuid;

	}

	Default def;

	struct Expressions {

		string basic;
		string types;
		string each;
		string tuples;
		string arrayLength, stringLength;

	}

	Expressions encoding, decoding;

}

size_t lines_of_code, total_files;

void src(string[] args, Attributes[string] attributes, Protocols[string] protocols, Metadatas[string] metadatas, Creative[string] creative, Block[] blocks, Item[] items, Entity[] entities, Enchantment[] enchantments, Effect[] effects, Biome[] biomes) {

	std.file.mkdirRecurse("../readme");

	string[] languages;

	string[string] travis;
	string[][string] readme;

	// read templates
	foreach(string file ; std.file.dirEntries("../templates", std.file.SpanMode.breadth)) {
		if(std.file.isDir(file)) {
			languages ~= file[13..$];
		}
	}

	global["WEBSITE"] = "https://github.com/sel-project/sel-utils";
	global["DESCRIPTION"] = "Automatically generated libraries for Minecraft and Minecraft: Pocket Edition";
	global["VERSION"] = to!string(sulVersion);

	foreach(lang ; languages) {

		auto timer = StopWatch(AutoStart.yes);

		Options options;

		if(std.file.exists("../templates/" ~ lang ~ "/options.json")) {
			auto json = parseJSON(cast(string)std.file.read("../templates/" ~ lang ~ "/options.json")).object;
			auto repo = "repo" in json;
			auto header = "header" in json;
			auto indentation = "indentation" in json;
			auto start = "start" in json;
			auto end = "end" in json;
			auto stripEmptyLines = "strip_empty_lines" in json;
			auto types = "types" in json;
			if(repo) {
				options.repo.exists = true;
				options.repo.name = (*repo)["name"].str;
				options.repo.src = (*repo)["src"].str;
				auto exclude = "exclude" in *repo;
				auto include = "include" in *repo;
				auto tag = "tag" in *repo;
				auto badges = "badges" in *repo;
				foreach(immutable t ; TypeTuple!("exclude", "include")) {
					if(mixin(t)) {
						if((*mixin(t)).type == JSON_TYPE.STRING) mixin("options.repo." ~ t) = [(*mixin(t)).str];
						else if((*mixin(t)).type == JSON_TYPE.ARRAY) {
							foreach(ex ; (*mixin(t)).array) {
								mixin("options.repo." ~ t) ~= ex.str;
							}
						}
					}
				}
				options.repo.tag = tag && (*tag).type == JSON_TYPE.TRUE;
				if(badges) {
					foreach(b ; (*badges).array) {
						options.repo.badges ~= Options.Repo.Badge(b["image"].str, b["url"].str, b["alt"].str);
					}
				}
			}
			if(indentation) {
				options.indentation = (*indentation).str;
			}
			if(start) options.start = (*start).str;
			if(end) options.end = (*end).str;
			if(stripEmptyLines) options.stripEmptyLines = (*stripEmptyLines).type != JSON_TYPE.FALSE;
			if(header) {
				if((*header).type == JSON_TYPE.OBJECT) {
					auto open = "open" in *header;
					auto line = "line" in *header;
					auto close = "close" in *header;
					if(open) options.header.open = (*open).str;
					if(line) options.header.line = (*line).str;
					if(close) options.header.close = (*close).str;
				} else {
					options.header.exists = (*header).type != JSON_TYPE.FALSE;
				}
			}
			if(types) {
				auto names = "names" in *types;
				if(names) {
					foreach(from, to; (*names).object) {
						options.types.names[from] = to.str;
					}
				}
				auto conv = "conv" in *types;
				if(conv) {
					auto basic = "basic" in *conv;
					auto tuples = "tuples" in *conv;
					auto arrays = "arrays" in *conv;
					auto metadata = "metadata" in *conv;
					auto others = "others" in *conv;
					if(basic) {
						foreach(key, value; (*basic).object) {
							options.types.basic[key] = value.str;
						}
					}
					if(tuples) {
						foreach(size, value; (*tuples).object) {
							options.types.tuples[to!size_t(size)] = value.str;
						}
					}
					if(arrays) {
						auto dynamic = "dynamic" in *arrays;
						auto fixed = "fixed" in *arrays;
						if(dynamic) options.types.arrays = (*dynamic).str;
						if(fixed) options.types.fixedArrays = (*fixed).str;
					}
					if(metadata) options.types.metadata = (*metadata).str;
					if(others) options.types.others = (*others).str;
				}
				auto def = "default" in *types;
				if(def) {
					auto number = "number" in *def;
					auto type = "type" in *def;
					auto str = "string" in *def;
					auto array = "array" in *def;
					auto fixedArray = "fixed_array" in *def;
					auto uuid = "uuid" in *def;
					if(number) options.def.number = (*number).str;
					if(type) options.def.type = (*type).str;
					if(str) options.def.str = (*str).str;
					if(array) options.def.array = (*array).str;
					if(fixedArray) options.def.fixedArray = (*fixedArray).str;
					if(uuid) options.def.uuid = (*uuid).str;
				}
				foreach(immutable exp ; TypeTuple!("encoding", "decoding")) {
					auto data = exp in *types;
					if(data) {
						auto basic = "basic" in *data;
						auto types_ = "types" in *data;
						auto each = "arrays" in *data;
						auto tuples = "tuples" in *data;
						auto arrayLength = "array_length" in *data;
						auto stringLength = "string_length" in *data;
						if(basic) mixin("options." ~ exp ~ ".basic") = (*basic).str;
						if(types_) mixin("options." ~ exp ~ ".types") = (*types_).str;
						if(each) mixin("options." ~ exp ~ ".each") = (*each).str;
						if(tuples) mixin("options." ~ exp ~ ".tuples") = (*tuples).str;
						if(arrayLength) mixin("options." ~ exp ~ ".arrayLength") = (*arrayLength).str;
						if(stringLength) mixin("options." ~ exp ~ ".stringLength") = (*stringLength).str;
					}
				}
			}
		}

		immutable bool allt = templateExists(lang, "all");

		Data[string] values;
		if(allt) values["all"] = (Data[string]).init;

		// utils
		if(templateExists(lang, "utils")) {
			values["utils"] = Data([Data(["": Data.init])]);
		}

		foreach(immutable type ; TypeTuple!("attributes", "creative", "protocols", "metadatas", "blocks", "items", "entities", "enchantments", "effects", "biomes")) {
			if(templateExists(lang, type)) {
				Data[] data = mixin("create" ~ capitalize(type) ~ "(" ~ type ~ ", options)");
				values[type] = data;
				if(allt) values["all"].object[type] = data;
			}
		}
		
		if(!args.length || args.canFind(lang)) {

			foreach(type, data; values) {
				addLast(data.array);
				auto temp = parseTemplate(lang, type, options);
				auto ptr = type in temp;
				if(data.type == Data.Type.array) {
					foreach(d ; data.array) {
						(*ptr).parse(d.object, temp);
					}
				} else if(data.type == Data.Type.object) {
					(*ptr).parse(data.object, temp);
				}
			}

		}

		string crm = "[![SEL](https://i.imgur.com/cTu1FE5.png)](https://github.com/sel-project/sel-utils)\n\n" ~
				"**Automatically generated libraries for Minecraft and Minecraft: Pocket Edition from [sel-project/sel-utils](https://github.com/sel-project/sel-utils)**\n\n" ~
				"To report a problem or request a new feature related to the generated code open an issue on [sel-utils](https://github.com/sel-project/sel-utils) adding `" ~ lang ~ "` in the title or in the description.\n" ~
				"To contribute at the project read the [contribution guidelines](https://github.com/sel-project/sel-utils/blob/master/CONTRIBUTING.md).\n\n";

		if(options.repo) {
			travis[lang] = " - ./push " ~ lang ~ " " ~ to!string(options.repo.tag) ~ " " ~ options.repo.src ~ " " ~ Base64.encode(cast(ubyte[])JSONValue(["exclude": options.repo.exclude, "include": options.repo.include]).toString()).idup;
			string rm;
			foreach(badge ; options.repo.badges) {
				rm ~= "[![" ~ badge.alt ~ "](" ~ badge.image ~ ")](" ~ badge.url ~ ") ";
			}
			rm ~= "\n\n";
			void writeCheck(string search, string display) {
				rm ~= "- [" ~ (search in values ? "x" : " ") ~ "] " ~ display ~ "\n";
			}
			writeCheck("protocols", "Protocol");
			writeCheck("metadatas", "Metadata");
			writeCheck("blocks", "Blocks");
			writeCheck("items", "Items");
			writeCheck("entities", "Entities");
			writeCheck("effects", "Effects");
			writeCheck("enchantments", "Enchantments");
			writeCheck("biomes", "Biomes");
			writeCheck("windows", "Windows");
			writeCheck("recipes", "Recipes");
			readme[lang] = [options.repo.name, "### [" ~ options.repo.name ~ "](https://github.com/sel-utils/" ~ lang ~ ")\n\n" ~ rm];
			crm ~= rm;
			//TODO generate repository's README.md with examples
		}

		std.file.write("../readme/" ~ lang ~ ".md", crm ~ "\n");

		timer.stop();

		writeln("Generated code for ", (options.repo.name.length ? options.repo.name : lang), " in ", timer.peek.msecs, " ms");

	}

	sort(languages);

	// rewrite .travis.yml
	{
		string file = cast(string)std.file.read("../templates/.travis.yml.template");
		foreach_reverse(lang ; languages) {
			auto ptr = lang in travis;
			if(ptr) file ~= *ptr ~ "\n";
		}
		std.file.write("../.travis.yml", file);
	}

	// rewrite README.md
	{
		import std.regex : ctRegex, replaceAll;
		string num(size_t conv) {
			return conv.to!string.dup.reverse.replaceAll(ctRegex!"([0-9]{3})", "$1 ").reverse.idup.strip.replace(" ", "&#8239;");
		}
		string file = cast(string)std.file.read("../templates/README.md.template");
		string[] langs;
		string[] descs;
		foreach(lang ; languages) {
			auto ptr = lang in readme;
			if(ptr) {
				langs ~= "[" ~ (*ptr)[0] ~ "](#" ~ lang ~ ")";
				descs ~= (*ptr)[1];
			}
		}
		file ~= "\n**Jump to**: " ~ langs.join(", ") ~ "\n\n";
		file ~= num(lines_of_code) ~ " lines of code in " ~ num(total_files) ~ " files\n\n";
		file ~= descs.join("\n\n");
		std.file.write("../README.md", file);
	}

}

// add last to every array that contains an object
void addLast(ref Data[] data) {
	foreach(i, ref d; data) {
		if(d.type == Data.Type.array) {
			addLast(d.array);
		} else if(d.type == Data.Type.object) {
			d.object["FIRST"] = to!string(i == 0);
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

string createEncoded(string value, string type) {
	if(type == "string") return JSONValue(value).toString();
	else return value;
}

enum endiannessTypes = ["short", "ushort", "triad", "int", "uint", "long", "ulong", "float", "double"];

enum basicTypes = ["bool", "byte", "ubyte", "short", "ushort", "varshort", "varushort", "triad", "int", "uint", "varint", "varuint", "long", "ulong", "varlong", "varulong", "float", "double", "string", "uuid", "bytes"];

Data[] createAttributes(Attributes[string] attributes, Options options) {
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

Data[] createCreative(Creative[string] creative, Options options) {
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

Data[] createProtocols(Protocols[string] protocols, Options options) {
	Data[] ret;
	foreach(game, p; protocols) {

		/**
		 * What's left to do:
		 * - decoding
		 * - encoded length
		 */

		immutable defaultEndianness = p.data.endianness["*"];

		/**
		 * Gets the endianness for a field.
		 * Returns: "big-endian" or "little-endian"
		 */
		string getEndianness(Field field) {
			if(field.endianness.length) return field.endianness;
			auto custom = field.type in p.data.endianness;
			if(custom) {
				return *custom;
			} else {
				// the encoder/decoder will unset the endianness if the type doesn't need it
				return defaultEndianness;
			}
		}

		/**
		 * Converts a type into a language-accepted type.
		 */
		string convertType(string type) {
			auto custom = type in p.data.arrays;
			if(custom) {
				// custom array
				type = (*custom).base ~ "[]";
			}
			auto array = type.lastIndexOf("[");
			if(array >= 0) {
				assert(type[$-1] == ']');
				Data[string] d;
				d["TYPE"] = convertType(type[0..array]);
				if(array == type.length - 2) {
					// normal array
					if(options.types.arrays.length) {
						return parseValue(options.types.arrays, d, (Template[string]).init, 0);
					}
				} else {
					// fixed-size array
					if(options.types.fixedArrays.length) {
						d["SIZE"] = type[array+1..$-1];
						return parseValue(options.types.fixedArrays, d, (Template[string]).init, 0);
					}
				}
				return d["TYPE"].str ~ type[array..$];
			}
			auto tuple = type.indexOf("<");
			if(tuple >= 0) {
				// tuple
				assert(type[$-1] == '>');
				string coords = type[tuple+1..$-1];
				auto t = coords.length in options.types.tuples;
				if(!t) return type;
				string[string] repl = ["%": convertType(type[0..tuple])];
				foreach(i, c; coords) repl["$" ~ to!string(i)] = "" ~ c;
				string ret = *t;
				foreach(from, to; repl) ret = ret.replace(from, to);
				return ret;
			}
			if(basicTypes.canFind(type)) {
				auto conv = type in options.types.basic;
				return conv ? *conv : type;
			} else {
				// metadata or special type (sul-defined)
				return parseValue(type == "metadata" ? options.types.metadata : options.types.others, ["GAME": Data(game), "TYPE": Data(type)], (Template[string]).init, 0);
			}
		}

		/**
		 * Converts a name into a language-accepted name.
		 * Params:
		 * 		name = the original name of the variables
		 * 		i = the packet's index of the field, used for unknown variables
		 * Example:
		 * ---
		 * // D does not accept 'body' as variable name
		 * assert(convertName("body", 0) == "body_");
		 * 
		 * // unknown variable
		 * assert(convertName("?", 1) == "unknown1");
		 */
		string convertName(string name, size_t index) {
			if(name == "?") return "unknown" ~ to!string(index);
			auto conv = name in options.types.names;
			return conv ? *conv : name;
		}

		/**
		 * Gets the default initialization value for a type.
		 */
		string getDefault(string type) {
			auto custom = type in p.data.arrays;
			if(custom) {
				type = (*custom).base ~ "[]";
			}
			Data[string] d;
			string exp;
			if(type.endsWith("]")) {
				auto array = type.lastIndexOf("[");
				d["TYPE"] = convertType(type[0..array]);
				if(array == type.length - 2) {
					exp = options.def.array;
				} else {
					d["SIZE"] = type[array+1..$-1];
					exp = options.def.fixedArray;
				}
			} else if(type.endsWith(">")) {
				return "null";
			} else {
				if(type == "string") {
					return options.def.str;
				} else if(type == "bytes") {
					d["TYPE"] = convertType("ubyte");
					exp = options.def.array;
				} else if(type == "uuid") {
					return options.def.uuid;
				} else if(type == "bool") {
					return "false";
				} else if(basicTypes.canFind(type)) {
					d["TYPE"] = convertType(type);
					exp = options.def.number;
				} else {
					d["NAME"] = type;
					exp = options.def.type;
				}
			}
			return parseValue(exp, d, (Template[string]).init, 0);
		}
		 
		/**
		 * Creates the encoding function(s) as specified in the language's
		 * options.json file.
		 * Params:
		 * 		type = type of the value, not converted
		 * 		data = current data
		 */
		string convertEncoding(string type, Data[string] data) {
			
			string ret;
			
			/**
			 * Adds the encoding expression for a length to 'ret'.
			 * Params:
			 * 		type = ltype of the length
			 * 		conv = expression to get the length from the settings
			 * 		data = current data
			 */
			void encodeLength(string ltype, string conv, string endianness=defaultEndianness) {
				auto d = data.dup;
				d["NAME"] = conv.replace("%", data["NAME"].str);
				d["ORIGINAL_TYPE"] = ltype;
				d["TYPE"] = convertType(ltype);
				d["ENDIANNESS"] = endianness;
				ret ~= convertEncoding(ltype, d);
				ret ~= " ";
			}
			
			string length = p.data.arrayLength;
			string lengthEndianness = defaultEndianness;
			auto custom = type in p.data.arrays;
			if(custom) {
				type = (*custom).base ~ "[]";
				length = (*custom).length;
				if((*custom).endianness.length) {
					lengthEndianness = (*custom).endianness;
				}
			}
			if(type == "ubyte[]") {
				// use the same function used for 'bytes' instead of encode every element
				encodeLength(length, options.encoding.arrayLength, lengthEndianness);
				type = "bytes";
			}
			if(type.endsWith("]")) {
				// array
				auto t = type[0..type.lastIndexOf("[")];
				if(type.length - t.length == 2) {
					// not-fixed array, encode length
					encodeLength(length, options.encoding.arrayLength);
				}
				data["ELEMENT_NAME"] = data["NAME"].str ~ "_child";
				data["ELEMENT_ORIGINAL_TYPE"] = t;
				data["ELEMENT_TYPE"] = convertType(t);
				auto d = data.dup;
				d["NAME"] = data["ELEMENT_NAME"];
				d["ORIGINAL_TYPE"] = data["ELEMENT_ORIGINAL_TYPE"];
				d["TYPE"] = data["ELEMENT_TYPE"];
				data["CONTENT"] = convertEncoding(t, d);
				return ret ~ parseValue(options.encoding.each, data, (Template[string]).init, 0);
			} else if(type.endsWith(">")) {
				// tuple
				auto t = type[0..type.lastIndexOf("<")];
				string[] r;
				foreach(i, char c; type[type.lastIndexOf("<")+1..$-1]) {
					auto d = data.dup;
					d["INDEX"] = to!string(i);
					d["INDEX1"] = to!string(i+1);
					d["NAME"] = parseValue(options.encoding.tuples, d, (Template[string]).init, 0);
					d["ORIGINAL_TYPE"] = t;
					d["TYPE"] = convertType(t);
					d["ENDIANNESS"] = getEndianness(Field("", t));
					r ~= convertEncoding(t, d);
				}
				return ret ~ r.join(" ");
			} else {
				if(type == "string") encodeLength(length, options.encoding.stringLength);
				auto d = data.dup;
				d["ORIGINAL_TYPE"] = type;
				d["TYPE"] = convertType(type);
				return ret ~ parseValue((){
					if(basicTypes.canFind(type)) {
						if(!endiannessTypes.canFind(type)) d.remove("ENDIANNESS");
						return options.encoding.basic;
					} else {
						return options.encoding.types;
					}
				}(), d, (Template[string]).init, 0);
			}
		}
		
		/**
		 * Creates the decoding function(s) as specified in the language's
		 * options.json file.
		 * Params:
		 * 		type = type of the value, not converted
		 * 		data = current data
		 */
		string convertDecoding(string type, Data[string] data) {
			
			string ret;
			
			/**
			 * Adds the decoding expression for a length to 'ret'.
			 * Params:
			 * 		type = ltype of the length
			 * 		conv = expression to get the length from the settings
			 * 		data = current data
			 */
			void decodeLength(string ltype, string conv, string endianness=defaultEndianness) {
				auto d = data.dup;
				d["NAME"] = conv.replace("%", data["NAME"].str);
				d["ORIGINAL_TYPE"] = ltype;
				d["TYPE"] = convertType(ltype);
				d["ENDIANNESS"] = endianness;
				ret ~= convertEncoding(ltype, d);
				ret ~= " ";
			}
			
			/+string length = p.data.arrayLength;
			string lengthEndianness = defaultEndianness;
			auto custom = type in p.data.arrays;
			if(custom) {
				type = (*custom).base ~ "[]";
				length = (*custom).length;
				if((*custom).endianness.length) {
					lengthEndianness = (*custom).endianness;
				}
			}
			if(type == "ubyte[]") {
				// use the same function used for 'bytes' instead of encode every element
				decodeLength(length, options.encoding.arrayLength, lengthEndianness);
				type = "bytes";
			}
			if(type.endsWith("]")) {
				// array
				auto t = type[0..type.lastIndexOf("[")];
				if(type.length - t.length == 2) {
					// not-fixed array, encode length
					encodeLength(length, options.encoding.arrayLength);
				}
				data["ELEMENT_NAME"] = data["NAME"].str ~ "_child";
				data["ELEMENT_ORIGINAL_TYPE"] = t;
				data["ELEMENT_TYPE"] = convertType(t);
				auto d = data.dup;
				d["NAME"] = data["ELEMENT_NAME"];
				d["ORIGINAL_TYPE"] = data["ELEMENT_ORIGINAL_TYPE"];
				d["TYPE"] = data["ELEMENT_TYPE"];
				data["CONTENT"] = convertEncoding(t, d);
				return ret ~ parseValue(options.encoding.each, data, (Template[string]).init, 0);
			} else +/if(type.endsWith(">")) {
				// tuple
				auto t = type[0..type.lastIndexOf("<")];
				string[] r;
				foreach(i, char c; type[type.lastIndexOf("<")+1..$-1]) {
					auto d = data.dup;
					d["INDEX"] = to!string(i);
					d["INDEX1"] = to!string(i+1);
					d["NAME"] = parseValue(options.decoding.tuples, d, (Template[string]).init, 0);
					d["ORIGINAL_TYPE"] = t;
					d["TYPE"] = convertType(t);
					d["ENDIANNESS"] = getEndianness(Field("", t));
					r ~= convertDecoding(t, d);
				}
				return ret ~ r.join(" ");
			} else {
				//if(type == "string") decodeLength(length, options.encoding.stringLength);
				auto d = data.dup;
				d["ORIGINAL_TYPE"] = type;
				d["TYPE"] = convertType(type);
				return ret ~ parseValue((){
					if(basicTypes.canFind(type)) {
						if(!endiannessTypes.canFind(type)) d.remove("ENDIANNESS");
						return options.decoding.basic;
					} else {
						return options.decoding.types;
					}
				}(), d, (Template[string]).init, 0);
			}
		}

		/**
		 * Creates a constant.
		 */
		Data[] createConstants(Field field, Constant[] constants) {
			Data[] ret;
			foreach(constant ; constants) {
				Data[string] c;
				c["NAME"] = constant.name;
				c["TYPE"] = convertType(field.type);
				c["VALUE"] = constant.value;
				c["VALUE_ENCODED"] = createEncoded(constant.value, field.type);
				ret ~= Data(c);
			}
			return ret;
		}

		/**
		 * Converts an array of fields into Data.
		 */
		Data[] createFields(Field[] fields) {
			Data[] ret;
			foreach(i, field; fields) {
				Data[string] f;
				f["ORIGINAL_NAME"] = field.name;
				f["NAME"] = convertName(field.name, i);
				f["ORIGINAL_TYPE"] = field.type;
				f["TYPE"] = convertType(field.type);
				f["CUSTOM_TYPE"] = to!string(!basicTypes.canFind(field.type) && field.type.indexOf("[") == -1 && field.type.indexOf("<") == -1); //TODO not in custom arrays
				f["WHEN"] = field.condition;
				f["HAS_ENDIANNESS"] = to!string(field.endianness != "");
				f["ENDIANNESS"] = getEndianness(field);
				f["DEFAULT"] = field.def;
				f["DEFAULT_ENCODED"] = createEncoded(field.def, field.type);
				f["DEFAULT_DECLARATION"] = field.def.length ? field.def : getDefault(field.type); //TODO
				f["HAS_CONSTANTS"] = to!string(field.constants.length != 0);
				f["CONSTANTS"] = createConstants(field, field.constants);
				f["ENCODING"] = convertEncoding(field.type, f);
				f["DECODING"] = convertDecoding(field.type, f);
				ret ~= Data(f);
			}
			return ret;
		}
		Data[string] g;
		immutable generator = "protocol/" ~ game;
		g["GENERATOR"] = generator;
		g["GAME"] = game;
		g["SOFTWARE"] = p.software;
		g["PROTOCOL"] = p.protocol.to!string;
		g["ID"] = p.data.id;
		g["ARRAY_LENGTH"] = p.data.arrayLength;
		g["DEFAULT_ENDIANNESS"] = p.data.endianness["*"];
		g["HAS_ENDIANNESS"] = to!string(p.data.endianness.length > 1);
		if(p.data.endianness.length > 1) {
			g["ENDIANNESS"] = (){
				Data[] ret;
				foreach(type, e; (){ auto ret=p.data.endianness.dup; ret.remove("*"); return ret; }()) {
					ret ~= Data(["TYPE": Data(type), "ENDIANNESS": Data(e)]);
				}
				return ret;
			}();
		}
		g["HAS_ARRAYS"] = to!string(p.data.arrays.length != 0);
		immutable id_type = convertType(p.data.id);
		g["ARRAYS"] = new Data[0];
		g["TYPES"] = new Data[0];
		g["SECTIONS"] = new Data[0];
		foreach(string name, array; p.data.arrays) {
			Data[string] a;
			a["NAME"] = name;
			a["BASE"] = array.base;
			a["LENGTH"] = array.length;
			a["ENDIANNESS"] = array.endianness;
			g["ARRAYS"].array ~= Data(a);
		}
		foreach(type ; p.data.types) {
			Data[string] t;
			t["GENERATOR"] = generator;
			t["GAME"] = game;
			t["NAME"] = type.name;
			t["HAS_FIELDS"] = to!string(type.fields.length != 0);
			t["FIELDS"] = createFields(type.fields);
			t["IS_LENGTH_PREFIXED"] = to!string(type.length.length != 0);
			t["LENGTH"] = type.length;
			t["LENGTH_ENCODE"] = (){ auto d = t.dup; d["NAME"] = "length"; return convertEncoding(type.length, d); }();
			t["LENGTH_DECODE"] = replace((){ auto d = t.dup; d["NAME"] = "length"; return convertDecoding(type.length, d); }(), "length =", "").strip;
			g["TYPES"].array ~= Data(t);
		}
		foreach(section ; p.data.sections) {
			Data[string] s;
			s["GENERATOR"] = generator;
			s["GAME"] = game;
			s["NAME"] = section.name;
			s["DESCRIPTION"] = section.description;
			s["PACKETS"] = new Data[0];
			foreach(packet ; section.packets) {
				Data[string] pk;
				pk["GENERATOR"] = generator;
				pk["GAME"] = game;
				pk["ID_TYPE"] = p.data.id;
				pk["ID_TYPE_ENCODED"] = id_type;
				pk["SECTION"] = section.name;
				pk["NAME"] = packet.name;
				pk["ID"] = packet.id.to!string;
				pk["CLIENTBOUND"] = packet.clientbound.to!string;
				pk["SERVERBOUND"] = packet.serverbound.to!string;
				pk["HAS_FIELDS"] = to!string(packet.fields.length != 0);
				pk["FIELDS"] = createFields(packet.fields);
				pk["HAS_VARIANTS"] = to!string(packet.variants.length != 0);
				if(packet.variants.length) {
					pk["VARIANT_FIELD"] = packet.variantField;
					pk["VARIANTS"] = (){
						Data[] vret;
						foreach(variant ; packet.variants) {
							Data[string] v;
							v["PARENT_NAME"] = packet.name;
							v["VARIANT_FIELD"] = convertName(packet.variantField, 0);
							v["NAME"] = variant.name;
							v["VALUE"] = variant.value;
							v["VALUE_ENCODED"] = createEncoded(variant.value, ""); //TODO variant field
							v["FIELDS"] = createFields(variant.fields);
							vret ~= Data(v);
						}
						return vret;
					}();
				}
				s["PACKETS"].array ~= Data(pk);
			}
			g["SECTIONS"].array ~= Data(s);
		}
		ret ~= Data(g);
	}
	return ret;
}

Data[] createMetadatas(Metadatas[string] metadatas, Options options) {
	Data[] ret;
	foreach(game, m; metadatas) {
		Data[string] g;
		g["GENERATOR"] = "metadata/" ~ game;
		g["GAME"] = game;
		g["SOFTWARE"] = m.software;
		g["PROTOCOL"] = m.protocol.to!string;
		g["LENGTH"] = m.data.length;
		g["SUFFIX"] = m.data.suffix;
		g["TYPE"] = m.data.type;
		g["ID"] = m.data.id;
		string[string] typesMap;
		g["TYPES"] = (){
			Data[] r;
			foreach(type ; m.data.types) {
				typesMap[type.name] = type.type;
				r ~= Data(["NAME": Data(type.name), "TYPE": Data(type.type), "ID": Data(type.id.to!string), "ENDIANNESS": Data(type.endianness)]);
			}
			return r;
		}();
		g["METADATA"] = (){
			Data[] r;
			foreach(metadata ; m.data.data) {
				Data[string] m;
				m["NAME"] = metadata.name;
				m["ORIGINAL_TYPE"] = metadata.type;
				//m["TYPE"] = convertType(game, typesMap[metadata.type], options.types);
				m["ID"] = metadata.id.to!string;
				m["REQUIRED"] = metadata.required.to!string;
				m["DEFAULT"] = metadata.def;
				m["DEFAULT_ENCODED"] = createEncoded(metadata.def, metadata.type);
				m["HAS_FLAGS"] = to!string(metadata.flags.length != 0);
				if(metadata.flags.length) {
					m["FLAGS"] = (){
						Data[] f;
						foreach(flag ; metadata.flags) {
							f ~= Data(["OWNER": Data(metadata.name), "TYPE": Data(metadata.type), "NAME": Data(flag.name), "BIT": Data(flag.bit.to!string)]);
						}
						return f;
					}();
				}
				r ~= Data(m);
			}
			return r;
		}();
		ret ~= Data(g);
	}
	return ret;
}

Data[] createBlocks(Block[] blocks, Options options) {
	Data[] ret;
	foreach(i, block; blocks) {
		Data[string] values;
		values["NAME"] = block.name;
		values["ID"] = block.id.to!string;
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

Data[] createItems(Item[] items, Options options) {
	Data[] ret;
	foreach(i, item; items) {
		Data[string] values;
		values["NAME"] = item.name;
		values["INDEX"] = i.to!string;
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

Data[] createEntities(Entity[] entities, Options options) {
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

Data[] createEnchantments(Enchantment[] enchantments, Options options) {
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

Data[] createEffects(Effect[] effects, Options options) {
	Data[] ret;
	foreach(effect ; effects) {
		Data[string] values;
		values["NAME"] = effect.name;
		values["HAS_MINECRAFT"] = to!string(effect.minecraft >= 0);
		values["MINECRAFT"] = effect.minecraft.to!string;
		values["HAS_POCKET"] = to!string(effect.pocket >= 0);
		values["POCKET"] = effect.pocket.to!string;
		values["COLOR"] = effect.particles.to!string;
		values["COLOR_16"] = (effect.particles.to!string(16) ~ "000000")[0..6];
		ret ~= Data(values);
	}
	return [Data(["EFFECTS": Data(ret), "GENERATOR": Data("effects")])];
}

Data[] createBiomes(Biome[] biomes, Options options) {
	Data[] ret;
	foreach(biome ; biomes) {
		Data[string] values;
		values["NAME"] = biome.name;
		values["ID"] = biome.id.to!string;
		values["TEMPERATURE"] = biome.temperature.to!string;
		ret ~= Data(values);
	}
	return [Data(["BIOMES": Data(ret), "GENERATOR": Data("biomes")])];
}

// stuff about template parsing

@property bool templateExists(string lang, string t) {
	return std.file.exists("../templates/" ~ lang ~ "/" ~ t ~ ".template");
}

class Template {

	Options options;

	public string lang, location, content, originalContent;

	private size_t space = 0;

	private bool write_header = true;
	private string header_open = "/*";
	private string header_line = " * ";
	private string header_close = " */";

	private string new_line = "\n";
	private string tab = "\t";

	private this() {}

	public this(Options options, string lang, string location, string content) {
		this.options = options;
		this.lang = lang;
		this.location = location;
		this.content = content;
		if(options.indentation == "spaces") {
			this.tab = "    ";
			this.content = this.content.replace("\t", "    ");
		}
		this.originalContent = this.content.dup;
	}

	public string parse(Data[string] values, Template[string] templates, size_t space=0) {
		string ret = parseValue(this.content, values, templates, space);
		if(this.location.length && this.location != "inline") {
			string[] lines = ret.split("\n");
			foreach(ref line ; lines) line = line.stripRight;
			ret = lines.join("\n");
			immutable location = "../src/" ~ this.lang ~ "/sul/" ~ parseValue(this.location, values, templates, 0);
			std.file.mkdirRecurse(location[0..location.lastIndexOf("/")]);
			if(this.options.header && !location.endsWith("proj") && !location.endsWith(".xml")) {
				auto gen = "GENERATOR" in values;
				ret = createHeader(gen ? (*gen).str : "", this.options.header.open, this.options.header.line, this.options.header.close) ~ ret;
			}
			std.file.write(location, this.options.start ~ ret ~ this.options.end);
			lines_of_code += ret.count("\n");
			total_files++;
		}
		return ret;
	}

	public Template addTabulation(size_t amount) {
		/*Template ret = new Template();
		foreach(m ; __traits(allMembers, Template)) {
			static if(is(typeof(__traits(getMember, ret, m)))) mixin("ret." ~ m ~ " = this." ~ m ~ ";");
		}*/
		auto ret = new Template(this.options, this.lang, this.location, this.originalContent);
		string space;
		foreach(i ; 0..amount) space ~= ret.tab;
		string[] lines = ret.content.split("\n");
		foreach(ref line ; lines) {
			if(line.length) {
				if(!line.startsWith("{{") || !line.endsWith("}}")) line = space ~ (line.startsWith("^") ? line[1..$] : line);
			}
		}
		ret.content = lines.join("\n");
		return ret;
	}

}

Template[string] parseTemplate(string lang, string t, Options options) {
	Template[string] ret;
	string data = cast(string)std.file.read("../templates/" ~ lang ~ "/" ~ t ~ ".template");
	// cannot use regex because they eat memory
	foreach(match ; data.replace("\r\n", "\n").split("--- start ")) {
		auto m = match.strip.split("---");
		if(m.length >= 3) {
			string[] header = m[0].strip.split(" ");
			string content = m[1..$-2].join("---")[1..$-1];
			if(options.stripEmptyLines) {
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
string parseValue(string value, Data[string] values, Template[string] templates, size_t space) {
	// TODO use regex
	@property size_t l(){ return value.length - 1; }
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
				ret ~= parseValueImpl(value[open_at..i], values, templates, space);
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
string parseValueImpl(string value, Data[string] values, Template[string] templates, size_t space) {
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
			return parseValue(result, values, templates, space);
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
		auto tmp = value[0..at] in templates;
		if(tmp) {
			value = value[at+1..$];
			ptrdiff_t tabs = -1;
			auto comma = value.indexOf(",");
			if(comma >= 0) {
				try {
					tabs = to!size_t(value[0..comma]);
					space += tabs;
					value = value[comma+1..$];
				} catch(ConvException) {}
			}
			Template getTemplate() {
				if(tabs >= 0) {
					return (*tmp).addTabulation(space);
				} else {
					return *tmp;
				}
			}
			auto v = getValue(value);
			if(v && (*v).type == Data.Type.array) {
				auto t = getTemplate();
				string[] ret;
				foreach(d ; (*v).array) {
					ret ~= t.parse(d.object, templates, space);
				}
				return ret.join(t.location == "inline" ? "" : "\n");
			} else if(tabs >= 0) {
				return getTemplate().parse(values, templates, space);
			}
		}
	}
	auto ptr = getValue(value);
	if(ptr && (*ptr).type == Data.Type.string) {
		return (*ptr).str;
	} else {
		auto tmp = value in templates;
		if(tmp) {
			return (*tmp).parse(values, templates, space);
		}
	}
	return "";
}
