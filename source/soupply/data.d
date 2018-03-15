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
module soupply.data;

import std.json : JSONValue;

/**
 * Name of the software.
 */
enum SOFTWARE = "soupply";

struct Data {

	string description;
	string license;
	string version_;
	
	Info[string] info;
	
}

struct Info {

	string file;
	string software;
	string game;
	uint version_;
	
	string released;
	string from, to;
	bool latest = false;
	string description;

	Protocol protocol;
	Metadata metadata;

}

struct Protocol {

	struct Constant { string name; string description; string value; }

	struct Field { string name; string type; string condition; string endianness; string length; string lengthEndianness; string default_; string description; Constant[] constants; }

	struct Variant { string name; string value; string description; Field[] fields; }

	struct Packet { string name; uint id; bool clientbound; bool serverbound; string description; Field[] fields; string variantField; Variant[] variants; JSONValue[] tests; }

	struct Type { string name; string description; Field[] fields; string length; }

	struct Section { string name; string description; Packet[] packets; }

	string id;
	string arrayLength;
	string endianness;
	size_t padding = 0;
	Section[] sections;
	Type[] types;

}

struct Metadata {

	struct Type { string name; string type; ubyte id; string endianness; }

	struct Flag { string name; string description; uint bit; }

	struct Data { string name; string description; string type; ubyte id; string default_; bool required; Flag[] flags; }

	string prefix;
	string length;
	string suffix;
	string type;
	string id;
	Type[] types;
	Data[] data;

}
