module sul.conversion;

import std.conv : to;
import std.path : dirSeparator;
import std.string : toLower, toUpper;

import sul.json;

static const UtilsJSON(string type, string game, size_t protocol, bool min=true) = parseJSON(minimize(import(type ~ dirSeparator ~ game ~ to!string(protocol) ~ (min ? ".min" : "") ~ ".json")));

@property string toCamelCase(string str, bool cap=false) {
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
	return cap && ret.length > 0 ? toUpper(ret[0..1]) ~ ret[1..$] : ret;
}
