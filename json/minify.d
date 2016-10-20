module minify;

import std.file;
import std.json;
import std.path : dirSeparator;
import std.stdio : writeln;
import std.string;

void main(string[] args) {

	foreach(string path ; dirEntries("", SpanMode.breadth)) {
		if(path.isFile && path.endsWith(".json") && !path.endsWith(".min.json")) {
			string dest = path[0..$-5] ~ ".min.json";
			auto file = read(path);
			size_t size = file.length;
			auto json = minimize(parseJSON(cast(string)file));
			auto min = toJSON(&json);
			writeln("Minified ", path, " (", size, " bytes) into ", dest, " (", min.length, " bytes)");
			write(dest, min);
		}
	}

}

JSONValue minimize(JSONValue json) {
	if(json.type == JSON_TYPE.OBJECT) {
		auto object = json.object;
		foreach(string key, ref JSONValue value; object) {
			if(key.startsWith("__")) object.remove(key);
			else value = minimize(value);
		}
		return JSONValue(object);
	} else if(json.type == JSON_TYPE.ARRAY) {
		auto array = json.array;
		foreach(size_t i, ref JSONValue value; array) {
			value = minimize(value);
			if(value.type == JSON_TYPE.OBJECT && value.object.length == 0) {
				array = array[0..i] ~ array[i+1..$];
			}
		}
		return JSONValue(array);
	} else {
		return json;
	}
}
