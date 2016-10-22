module sul.conversion;

import std.conv : to;
import std.path : dirSeparator;
import std.string : toLower, toUpper;

import sul.json;

template File(string type, string game, size_t protocol) {
	immutable name = type ~ "." ~ game ~ to!string(protocol) ~ ".json";
	static assert(__traits(compiles, import(name)), "Cannot find file '" ~ name ~ "'. Run 'sel update utils' to update or install sel-utils");
	enum File = import(name);
}

static const UtilsJSON(string type, string game, size_t protocol) = parseJSON(minimize(File!(type, game, protocol)));

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
