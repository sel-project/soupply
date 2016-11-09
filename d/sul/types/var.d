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
module sul.types.var;

import std.traits : isNumeric, isIntegral, isSigned, isUnsigned, Unsigned;

struct var(T) if(isNumeric!T && isIntegral!T && T.sizeof > 1) {
	
	alias U = Unsigned!T;
	
	private static immutable U MASK = U.max - 0x7F;
	private static immutable size_t MAX_BYTES = T.sizeof + 1;
	private static immutable size_t RIGHT_SHIFT = (T.sizeof * 8) - 1;
	
	public T value;
	
	public pure nothrow @safe @nogc this(T value) {
		this.value = value;
	}

	public pure nothrow @safe @nogc void opAssign(T)(T value) {
		this.value = value;
	}
	
	public pure nothrow @property @safe @nogc U unsigned() {
		static if(isUnsigned!T) {
			return this.value;
		} else {
			return cast(U)((this.value << 1) ^ (this.value >> RIGHT_SHIFT));
		}
	}
	
	public pure nothrow @safe ubyte[] encode() {
		ubyte[] buffer;
		U unsigned = this.unsigned;
		while((unsigned & MASK) != 0) {
			buffer ~= unsigned & 0x7F | 0x80;
			unsigned >>>= 7;
		}
		buffer ~= unsigned & 0xFF;
		return buffer;
	}

	alias value this;
	
	public static pure nothrow @safe var!T fromBuffer(ref ubyte[] buffer) {
		if(buffer.length == 0) return var!T.init;
		U unsigned = 0;
		size_t j, k;
		do {
			k = buffer[0];
			buffer = buffer[1..$];
			unsigned |= (k & 0x7F) << (j++ * 7);
		} while(buffer.length != 0 && j < MAX_BYTES && (k & 0x80) != 0);
		static if(isUnsigned!T) {
			return var!T(unsigned);
		} else {
			T value = unsigned >> 1;
			if(unsigned & 1) {
				value++;
				return var!T(-value);
			} else {
				return var!T(value);
			}
		}
	}

	public static pure nothrow @safe var!T[] convert(T[] array) {
		var!T[] ret = new var!T[array.length];
		foreach(size_t i, ref var!T value; ret) {
			value = array[i];
		}
		return ret;
	}
	
	public enum stringof = "var" ~ T.stringof;
	
}

alias varshort = var!short;

alias varushort = var!ushort;

alias varint = var!int;

alias varuint = var!uint;

alias varlong = var!long;

alias varulong = var!ulong;
