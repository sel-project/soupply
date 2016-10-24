/*
 * Copyright (c) 2016 SEL
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
module sul.conversion;

import std.conv : to;
import std.path : dirSeparator;
import std.string : toLower, toUpper;

import sul.json;

/**
 * Reads a compile-time file or assserts with an helpful message.
 * The file readed should be in the format {type}.{game}{protocol}.json
 * and the content should be a minified JSON.
 */
alias file(string type, string game, size_t protocol) = fileImpl!(type ~ "." ~ game ~ to!string(protocol) ~ ".json");

/// ditto
alias file(string type) = fileImpl!(type ~ ".json");

template fileImpl(string name) {
	static if(__traits(compiles, import(name))) {
		enum fileImpl = import(name);
	} else {
		static assert(0, "Cannot find file '" ~ name ~ "'. Run 'sel update utils' to update or install sel-utils");
	}
}

/**
 * Reads a compile-time minified JSON file and parses it into
 * a constants JSON object.
 */
static const UtilsJSON(string type, string game, size_t protocol) = parseJSON(file!(type, game, protocol));

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
