module sul.buffers;

static import std.bitmanip;
import std.meta : NoDuplicates;
import std.system : Endian;
import std.traits : isArray;

import sul.types.var;

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
			this.writeLength(value.length, buffer);
			foreach(av ; value) {
				this.write(av, buffer);
			}
		} else static if(T.stringof.length > 3 && T.stringof[0..3] == "var") {
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
