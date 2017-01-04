module all;

import std.file;
import std.json;
import std.path : dirSeparator;
import std.string;

static import d;
static import java;
static import js;

void main(string[] args) {

	// attributes
	JSONValue[string] attributes;
	foreach(string file ; dirEntries("../json/attributes", SpanMode.breadth)) {
		if(file.isFile && file.endsWith(".json")) {
			attributes[file.name] = parseJSON(cast(string)read(file)).object["attributes"];
		}
	}

	// constants
	JSONValue[string] constants;
	foreach(string file ; dirEntries("../json/constants", SpanMode.breadth)) {
		if(file.isFile && file.endsWith(".json")) {
			constants[file.name] = parseJSON(cast(string)read(file)).object["constants"];
		}
	}

	// creative
	JSONValue[string] creative;
	foreach(string file ; dirEntries("../json/creative", SpanMode.breadth)) {
		if(file.isFile && file.endsWith(".json")) {
			creative[file.name] = parseJSON(cast(string)read(file)).object["items"];
		}
	}

	// metadata
	JSONValue[string] metadata;

	// particles
	JSONValue[string] particles;

	// protocol
	JSONValue[string] protocol;
	foreach(string file ; dirEntries("../json/protocol", SpanMode.breadth)) {
		if(file.isFile && file.endsWith(".json")) {
			protocol[file.name] = parseJSON(cast(string)read(file)).object;
		}
	}

	auto jsons = [
		"attributes": JSONValue(attributes),
		"constants": JSONValue(constants),
		"creative": JSONValue(creative),
		"metadata": JSONValue(metadata),
		"particles": JSONValue(particles),
		"protocol": JSONValue(protocol)
	];

	d.d(jsons);
	java.java(jsons);
	js.js(jsons);

}

@property string name(string file) {
	return file[file.lastIndexOf(dirSeparator)+1..$-5];
}

@property string toCamelCase(string str) {
	string ret = "";
	bool next_up = false;
	foreach(char c ; str.toLower.dup) {
		if(c == '_') {
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
