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
module doc;

import std.conv : to;
static import std.file;
import std.string;

import all;

void doc(Protocols[string] protocols) {

	std.file.mkdirRecurse("../doc");

	foreach(string g, Protocols ptrs; protocols) {
		immutable ps = ptrs.protocol.to!string;
		immutable game = g[0..$-ps.length];
		std.file.mkdirRecurse("../doc/" ~ game);
		std.file.write("../doc/" ~ game ~ "/" ~ ps ~ ".md", "This documentation has been moved to [docs/" ~ game ~ "/" ~ ps ~ ".html](https://sel-project.github.io/sel-utils/" ~ game ~ "/" ~ ps ~ ".html)\n");
	}

	// index
	std.file.write("../doc/index.md", "This documentation has been moved to [docs/index.html](https://sel-project.github.io/sel-utils/index.html)\n");

}
