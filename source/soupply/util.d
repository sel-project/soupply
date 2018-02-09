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
module soupply.util;

import std.algorithm : canFind, min;
import std.base64 : Base64URL;
import std.conv : to;
import std.json : JSONValue;
import std.regex : ctRegex, replaceAll;
import std.string : toLower;

import transforms : snakeCase, camelCaseLower, camelCaseUpper;

@property string toSnakeCase(const string input) {
	return input.snakeCase;
}

@property string toCamelCase(const string input) {
	return input.camelCaseLower;
}

@property string toPascalCase(const string input) {
	return input.camelCaseUpper;
}

string hash(string name) {
	string ret;
	foreach(i, c; Base64URL.encode(cast(ubyte[])name).toLower.replaceAll(ctRegex!`[_\-=]`, "")) {
		if((i & 1) == 0) ret ~= c;
	}
	while("0123456789".canFind(ret[0])) ret = ret[1..$];
	return ret.toLower[0..min($, 8)];
}

string constOf(string value) {
	if(value == "true" || value == "false") return value;
	try {
		to!real(value);
		return value;
	} catch(Exception) {
		return JSONValue(value).toString();
	}
}
