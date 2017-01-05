module doc;

import std.algorithm : min, canFind;
import std.conv : to;
import std.file;
import std.xml;
import std.path : dirSeparator;
import std.string;

import std.stdio : writeln;

void doc() {

	mkdirRecurse("../doc");

	enum defaultTypes = ["bool", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "string", "varshort", "varushort", "varint", "varuint", "varlong", "varulong", "uuid"];

	string[string] aliases;

	@property string convert(string type) {
		auto end = min(cast(size_t)type.lastIndexOf("["), cast(size_t)type.lastIndexOf("<"), type.length);
		immutable t = type[0..end];
		if(defaultTypes.canFind(t)) return type;
		auto a = t in aliases;
		if(a) return *a;
		else return "[" ~ t ~ "](#" ~ t.toLower ~ ")" ~ type[end..$];
	}

	// protocol
	foreach(string file ; dirEntries("../xml/protocol", SpanMode.breadth)) {
		if(file.isFile && file.endsWith(".xml")) {
			immutable name = file.name;
			string data;
			string types;
			foreach(element ; new Document(cast(string)read(file)).elements) {
				switch(element.tag.name) {
					case "software":
						data ~= "# " ~ element.text.strip ~ " ";
						break;
					case "protocol":
						data ~= element.text.strip ~ "\n\n";
						break;
					case "description":
						data ~= element.text.strip ~ "\n\n";
						break;
					case "encoding":
						data ~= "## Encoding\n\n";
						foreach(enc ; element.elements) {
							switch(enc.tag.name) {
								case "endianness":break;
								case "alias":
									with(enc.tag) aliases[attr["name"]] = attr["type"];
									break;
								case "type":
									types ~= "#### " ~ enc.tag.attr["name"].pretty ~ "\n\n";
									types ~= " | | | \n---|---|---\n";
									foreach(field ; enc.elements) {
										if(field.tag.name == "field") {
											types ~= field.tag.attr["name"].pretty ~ " | " ~ convert(field.tag.attr["type"]) ~ " | ";
											if(field.texts.length) types ~= field.texts[0].to!string.strip.replace("|", "\\|");
											types ~= "\n";
										}
									}
									types ~= "\n";
									break;
								default:
									break;
							}
						}
						data ~= "--------\n\n";
						break;
					case "packets":
						data ~= "## Packets\n\n";
						data ~= "Section | Packets\n---|:---:\n";
						string sdata;
						foreach(section ; element.elements) {
							immutable sn = section.tag.attr["name"].pretty;
							data ~= "[" ~ sn ~ "](#" ~ sn.toLower.replace(" ", "-") ~ ") | " ~ to!string(section.elements.length) ~ "\n";
							sdata ~= "### " ~ sn ~ "\n\n";
							sdata ~= "Name | DEC | HEX | Clientbound | Serverbound\n---|:---:|:---:|:---:|:---:\n";
							string packets = "";
							foreach(packet ; section.elements) {
								immutable packetName = packet.tag.attr["name"].pretty;
								with(packet.tag) sdata ~= "[" ~ packetName ~ "](#" ~ packetName.toLower.replace(" ", "-") ~ ") | " ~ attr["id"] ~ " | " ~ attr["id"].to!size_t.to!string(16) ~ " | " ~ (attr["clientbound"] == "true" ? "✓" : "") ~ " | " ~ (attr["serverbound"] == "true" ? "✓" : "") ~ "\n";
								packets ~= "#### " ~ packetName ~ "\n\n";
								string fields, constants, variants;
								foreach(field ; packet.elements) {
									switch(field.tag.name) {
										case "description":
											packets ~= field.text.strip ~ "\n\n";
											break;
										case "field":
											fields ~= field.tag.attr["name"] ~ " | " ~ convert(field.tag.attr["type"]) ~ " | ";
											if(field.texts.length) fields ~= field.texts[0].to!string.strip.replace("|", "\\|");
											if(field.elements.length) {
												constants ~= "* " ~ field.tag.attr["name"].pretty ~ "\n\n";
												foreach(constant ; field.elements) {
													if(constant.tag.name == "constant") {
														with(constant.tag) constants ~= "\t* " ~ attr["name"].pretty ~ ": " ~ attr["value"] ~ "\n";
													}
												}
											}
											fields ~= "\n";
											break;
										case "variants":
											variants ~= "##### Variants:\n\n";
											variants ~= "**Field:** " ~ field.tag.attr["field"] ~ "\n\n";

											variants ~= "\n\n";
											break;
										default:
											break;
									}
								}
								if(fields.length) packets ~= " | | | \n---|---|---\n" ~ fields ~ "\n";
								if(constants.length) packets ~= "##### Constants:\n\n" ~ constants ~ "\n\n";
								if(variants.length) packets ~= variants;
							}
							sdata ~= "\n" ~ packets ~ "\n\n--\n\n";
						}
						data ~= "\n" ~ sdata;
						break;
					default:
						break;
				}
			}
			if(types.length) data ~= "\n\n--------\n\n## Types:\n\n" ~ types;
			write("../doc/" ~ name ~ ".md", data);
		}
	}

}

@property string name(string file) {
	return file[file.lastIndexOf(dirSeparator)+1..$-4];
}

@property string pretty(string name) {
	string ret;
	foreach(c ; name) {
		if(c >= 'A' && c <= 'Z' || c >= '0' && c <= '9') ret ~= ' ';
		ret ~= c;
	}
	if(!ret.length) return ret;
	else return toUpper(ret[0..1]) ~ ret[1..$];
}
