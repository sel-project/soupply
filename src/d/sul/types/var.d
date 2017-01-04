
module sul.types.var;

import std.traits : isNumeric, isIntegral, isSigned, isUnsigned, Unsigned;

struct var(T) if(isNumeric!T && isIntegral!T && T.sizeof > 1) {
	
	alias U = Unsigned!T;
	
	public static immutable U MASK = U.max - 0x7F;
	public static immutable size_t MAX_BYTES = T.sizeof * 8 / 7 + (T.sizeof * 8 % 7 == 0 ? 0 : 1);
	public static immutable size_t RIGHT_SHIFT = (T.sizeof * 8) - 1;
	
	public static pure nothrow @safe ubyte[] encode(T value) {
		ubyte[] buffer;
		static if(isUnsigned!T) {
			U unsigned = value;
		} else {
			//U unsigned = cast(U)((value << 1) ^ (value >> RIGHT_SHIFT));
			U unsigned = cast(U)(value << 1);
			if(value < 0) {
				unsigned |= 1;
				unsigned = -unsigned;
			}
		}
		while((unsigned & MASK) != 0) {
			buffer ~= unsigned & 0x7F | 0x80;
			unsigned >>>= 7;
		}
		buffer ~= unsigned & 0xFF;
		return buffer;
	}
	
	public static pure nothrow @safe T fromBuffer(ref ubyte[] buffer) {
		if(buffer.length == 0) return T.init;
		U unsigned = 0;
		size_t j, k;
		do {
			k = buffer[0];
			buffer = buffer[1..$];
			unsigned |= (k & 0x7F) << (j++ * 7);
		} while(buffer.length != 0 && j < MAX_BYTES && (k & 0x80) != 0);
		static if(isUnsigned!T) {
			return unsigned;
		} else {
			T value = unsigned >> 1;
			if(unsigned & 1) {
				value++;
				return -value;
			} else {
				return value;
			}
		}
	}
	
	public enum stringof = "var" ~ T.stringof;
	
}

alias varshort = var!short;

alias varushort = var!ushort;

alias varint = var!int;

alias varuint = var!uint;

alias varlong = var!long;

alias varulong = var!ulong;
	