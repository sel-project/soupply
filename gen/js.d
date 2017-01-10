/*
 * Copyright (c) 2016-2017 SEL
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
module js;

import std.ascii : newline;
import std.conv : to;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.path : dirSeparator;
import std.string;

import all;

void js(Attributes[string] attributes, Protocols[string] protocols, Creative[string] creative) {
	
	mkdirRecurse("../src/js/sul");
	
	// attributes
	foreach(string game, Attributes attrs; attributes) {
		string data = "const Attributes = {\n\n";
		foreach(attr ; attrs.data) {
			data ~= "\t" ~ toUpper(attr.id) ~ ": {name: " ~ JSONValue(attr.name).toString() ~ ", min: " ~ attr.min.to!string ~ ", max: " ~ attr.max.to!string ~ ", default: " ~ attr.def.to!string ~ "},\n\n";
		}
		if(!exists("../src/js/sul/attributes")) mkdir("../src/js/sul/attributes");
		write("../src/js/sul/attributes/" ~ game ~ ".js", data ~ "}", "attributes/" ~ game);
	}
	
}
