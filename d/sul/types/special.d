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
module sul.types.special;

import std.traits : isNumeric, isIntegral, isSigned, isUnsigned, Unsigned;

struct Special(T) if(isNumeric!T && isIntegral!T && T.sizeof > 1) {

	alias U = Unsigned!T;

	private T n_value;

	public pure nothrow @safe @nogc this(T value) {
		this.n_value = value;
	}

	public pure nothrow @property @safe @nogc T value() {
		return this.n_value;
	}

	public pure nothrow @property @safe @nogc U unsigned() {
		return this.value << 1 | (this.value < 0 ? 1 : 0);
	}

	alias value this;

	enum stringof = "special" ~ T.stringof;

}

alias specialint = Special!int;

alias specialuint = Special!uint;
