module sul.buffers;

static import std.bitmanip;
import std.conv : to;
import std.meta : NoDuplicates;
import std.string;
import std.system : Endian;
import std.traits : isArray, isDynamicArray;
import std.typetuple : TypeTuple;
import std.uuid : UUID;

import sul.types.var;

struct RemainingBytes {
	ubyte[] bytes;
	alias bytes this;
}

struct Triad {
	int value;
	alias value this;
}

mixin template BufferMethods(Endian endianness, L, E...) {

	static import std.bitmanip;
	import std.traits : isArray, isDynamicArray;

	protected static Endian endiannessOf(T)() {
		foreach(F ; E) {
			static if(is(T == F)) return !endianness;
		}
		return endianness;
	}

	public void write(T)(T value, ref ubyte[] buffer) {
		static if(is(T == RemainingBytes)) {
			buffer ~= value;
		} else static if(is(T == UUID)) {
			this.write(value.data, buffer);
		} else static if(isArray!T) {
			static if(isDynamicArray!T) this.writeLength(value.length, buffer);
			static if(is(T == ubyte[]) || is(T == byte[]) || is(T == string)) {
				buffer ~= cast(ubyte[])value;
			} else {
				foreach(av ; value) {
					this.write(av, buffer);
				}
			}
		} else static if(T.stringof.length > 3 && T.stringof.startsWith("var")) {
			buffer ~= value.encode();
		} else {
			mixin("this.write" ~ capital(Base!T.stringof) ~ "(value, buffer);");
		}
	}

	public T read(T)(ref ubyte[] buffer) {
		static if(is(T == RemainingBytes)) {
			ubyte[] ret = buffer.dup;
			buffer.length = 0;
			return RemainingBytes(ret);
		} else static if(is(T == UUID)) {
			ubyte[16] uuid = this.read(16, buffer);
			return UUID(uuid);
		} else static if(is(T == string)) {
			return cast(string)this.read!(ubyte[])(buffer);
		} else static if(isArray!T) {
			alias R = Type!T;
			static if(isDynamicArray!T) {
				static if(is(R == ubyte) || is(R == byte)) {
					return this.read(this.readLength(buffer), buffer);
				} else {
					R[] ret = new R[this.readLength(buffer)];
					foreach(ref R value ; ret) {
						value = this.read!R(buffer);
					}
					return ret;
				}
			} else {
				T ret;
				static if(is(R == ubyte) || is(R == byte) || is(R == char) || is(R == immutable(char))) {
					ret = cast(R[])this.read(ret.length, buffer);
				} else {
					foreach(ref R value ; ret) {
						value = this.read!R(buffer);
					}
				}
				return ret;
			}
		} else static if(T.stringof.length >= 3 && T.stringof.startsWith("var")) {
			return T.fromBuffer(buffer);
		} else {
			mixin("return this.read" ~ capital(Base!T.stringof) ~ "(buffer);");
		}
	}

	public ubyte[] read(size_t length, ref ubyte[] buffer) {
		if(buffer.length < length) buffer.length = length;
		ubyte[] ret = buffer[0..length];
		buffer = buffer[length..$];
		return ret;
	}

	protected void writeLength(size_t length, ref ubyte[] buffer) {
		static if(is(L == size_t)) {
			this.write(length, buffer);
		} else static if(__traits(compiles, { L l = length; })) {
			L l = length;
			this.write(l, buffer);
		} else {
			this.write(L(length.to!uint), buffer);
		}
	}

	protected size_t readLength(ref ubyte[] buffer) {
		return this.read!L(buffer);
	}

	mixin((){
		string w, r;
		foreach(T ; TypeTuple!(bool, byte, ubyte, short, ushort, int, uint, long, ulong, float, double)) {
			w ~= "public void write" ~ capital(T.stringof) ~ "(" ~ T.stringof ~ " value, ref ubyte[] buffer){";
			w ~= "size_t index = buffer.length;";
			w ~= "buffer.length += " ~ to!string(T.sizeof) ~ ";";
			w ~= "std.bitmanip.write!(" ~ T.stringof ~ ", endiannessOf!(" ~ T.stringof ~ ")())(buffer, value, index);";
			w ~= "}";
			r ~= "public " ~ T.stringof ~ " read" ~ capital(T.stringof) ~ "(ref ubyte[] buffer){";
			r ~= "if(buffer.length < " ~ to!string(T.sizeof) ~ "){buffer.length=" ~ to!string(T.sizeof) ~ ";}";
			r ~= "return std.bitmanip.read!(" ~ T.stringof ~ ", endiannessOf!(" ~ T.stringof ~ ")())(buffer);";
			r ~= "}";
		}
		return w ~ r;
	}());

	public void writeChar(char c, ref ubyte[] buffer) {
		this.write(cast(ubyte)c, buffer);
	}

	public char readChar(ref ubyte[] buffer) {
		return cast(char)this.read!ubyte(buffer);
	}

	public void writeTriad(int value, ref ubyte[] buffer) {
		static if(endiannessOf!Triad == Endian.bigEndian) {
			buffer ~= value & 255;
			buffer ~= (value >> 8) & 255;
			buffer ~= (value >> 16) & 255;
		} else {
			buffer ~= (value >> 16) & 255;
			buffer ~= (value >> 8) & 255;
			buffer ~= value & 255;
		}
	}

	public int readTriad(ref ubyte[] buffer) {
		int ret = 0;
		if(buffer.length < 3) buffer.length = 3;
		static if(endiannessOf!Triad == Endian.bigEndian) {
			ret |= buffer[0];
			ret |= buffer[1] << 8;
			ret |= buffer[2] << 16;
		} else {
			ret |= buffer[0] << 16;
			ret |= buffer[1] << 8;
			ret |= buffer[2];
		}
		buffer = buffer[3..$];
		return ret;
	}

}

template Base(T) {
	static if(is(T == immutable)) {
		mixin("alias Base = " ~ T.stringof.replace("immutable(", "").replace(")", "") ~ ";");
	} else {
		alias Base = T;
	}
}

template Type(T) {
	static if(T.stringof.indexOf("[") >= 0) {
		mixin("alias Type = " ~ T.stringof[0..T.stringof.indexOf("[")] ~ ";");
	} else {
		alias Type = T;
	}
}

string capital(string str) {
	if(str.length == 0) return str;
	else return toUpper(str[0..1]) ~ str[1..$];
}

class Buffer(E...) if(E.length >= 1) {

	mixin Instance;

	static if(is(typeof(E[0]) == Endian)) {
		alias endianness = E[0];
		alias SwitchedEndianness = E[1..$];
	} else static if(is(typeof(E[0].endianness) == Endian)) {
		alias endianness = E[0].endianness;
		alias SwitchedEndianness = NoDuplicates!(E[0].SwitchedEndianness, E[1..$]);
	} else {
		static assert(0, "Invalid buffer");
	}

	public void write(T)(T value, ref ubyte[] buffer) {
		static if(isArray!T) {
			static if(!isDynamicArray!T) this.writeLength(value.length, buffer);
			foreach(av ; value) {
				this.write(av, buffer);
			}
		} else static if(T.stringof.length > 3 && T.stringof.startsWith("var")) {
			buffer ~= value.encode();
		} else {
			buffer.length += T.sizeof;
			std.bitmanip.write!(T, endianness)(buffer, value, 0);
		}
	}

	public void writeLength(size_t length, ref ubyte[] buffer) {
		this.write(length, buffer);
	}

}

void mergeEndianness(E...)() {

}

mixin template Instance() {

	private static typeof(this) n_instance;

	public static this() {
		n_instance = new typeof(this);
	}

	public static nothrow @property @safe @nogc instance() {
		return n_instance;
	}

}

// (big-endian, short, little-endian)
// (buffer!(...), float, little-endian)

template BufferOf(string game, size_t protocol) {
	mixin((){

			import sul.conversion;
			import sul.json;

			auto json = cast(JSONObject)UtilsJSON!("protocol", game, protocol);

			auto encoding = cast(JSONObject)json["encoding"];

			auto metadata = cast(JSONObject)encoding["metadata"];

			string ret = "";

			ret ~= "class BufferOf : Buffer!(Endian.bigEndian) {

				mixin Instance;

				void writeMetadata(T)(ubyte id, T value, ref ubyte[] buffer) {

					this.write(value, buffer);
				}

				void writeMetadataLength(uint length, ref ubyte[] buffer) {";
					if(metadata["length"] !is null) {
						ret ~= cast(JSONString)metadata["length"] ~ " l  = length;";
						ret ~= "this.write!" ~ cast(JSONString)metadata["length"] ~ "(l, buffer);";
					}
			ret ~= "}
				
				void writeMetadataEnd(ref ubyte[] buffer) {";
					if(metadata["end"] !is null) {
						ret ~= "this.write!ubyte(" ~ to!string(cast(JSONInteger)metadata["end"]) ~ ", buffer);";
					}
			ret ~= "}

			}";

			return ret;

		}());
}
