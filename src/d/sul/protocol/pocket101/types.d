/*
 * This file was automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generated from https://github.com/sel-project/sel-utils/blob/master/xml/protocol/pocket101.xml
 */
module sul.protocol.pocket101.types;

import std.bitmanip : write, peek;
import std.conv : to;
import std.system : Endian;
import std.typecons : Tuple;
import std.uuid : UUID;

import sul.utils.buffer;
import sul.utils.var;

import sul.metadata.pocket101;

struct Pack {

	public enum string[] FIELDS = ["id", "vers", "size"];

	public string id;
	public string vers;
	public ulong size;

	public pure nothrow @safe void encode(Buffer buffer) {
		with(buffer) {
			writeBytes(varuint.encode(cast(uint)id.length)); writeString(id);
			writeBytes(varuint.encode(cast(uint)vers.length)); writeString(vers);
			writeBigEndianUlong(size);
		}
	}

	public pure nothrow @safe void decode(Buffer buffer) {
		with(buffer) {
			uint awq=varuint.decode(_buffer, &_index); id=readString(awq);
			uint dmvycw=varuint.decode(_buffer, &_index); vers=readString(dmvycw);
			size=readBigEndianUlong();
		}
	}

}

struct BlockPosition {

	public enum string[] FIELDS = ["x", "y", "z"];

	public int x;
	public uint y;
	public int z;

	public pure nothrow @safe void encode(Buffer buffer) {
		with(buffer) {
			writeBytes(varint.encode(x));
			writeBytes(varuint.encode(y));
			writeBytes(varint.encode(z));
		}
	}

	public pure nothrow @safe void decode(Buffer buffer) {
		with(buffer) {
			x=varint.decode(_buffer, &_index);
			y=varuint.decode(_buffer, &_index);
			z=varint.decode(_buffer, &_index);
		}
	}

}

struct Slot {

	public enum string[] FIELDS = ["id", "metaAndCount", "nbt"];

	public int id;
	public int metaAndCount;
	public ubyte[] nbt;

	public pure nothrow @safe void encode(Buffer buffer) {
		with(buffer) {
			writeBytes(varint.encode(id));
			if(id>0){ writeBytes(varint.encode(metaAndCount)); }
			if(id>0){ writeLittleEndianUshort(cast(ushort)nbt.length); writeBytes(nbt); }
		}
	}

	public pure nothrow @safe void decode(Buffer buffer) {
		with(buffer) {
			id=varint.decode(_buffer, &_index);
			if(id>0){ metaAndCount=varint.decode(_buffer, &_index); }
			if(id>0){ nbt.length=readLittleEndianUshort(); if(_buffer.length>=_index+nbt.length){ nbt=_buffer[_index.._index+nbt.length].dup; _index+=nbt.length; } }
		}
	}

}

struct Attribute {

	public enum string[] FIELDS = ["min", "max", "value", "def", "name"];

	public float min;
	public float max;
	public float value;
	public float def;
	public string name;

	public pure nothrow @safe void encode(Buffer buffer) {
		with(buffer) {
			writeLittleEndianFloat(min);
			writeLittleEndianFloat(max);
			writeLittleEndianFloat(value);
			writeLittleEndianFloat(def);
			writeBytes(varuint.encode(cast(uint)name.length)); writeString(name);
		}
	}

	public pure nothrow @safe void decode(Buffer buffer) {
		with(buffer) {
			min=readLittleEndianFloat();
			max=readLittleEndianFloat();
			value=readLittleEndianFloat();
			def=readLittleEndianFloat();
			uint bmftzq=varuint.decode(_buffer, &_index); name=readString(bmftzq);
		}
	}

}

struct Skin {

	public enum string[] FIELDS = ["name", "data"];

	public string name;
	public ubyte[] data;

	public pure nothrow @safe void encode(Buffer buffer) {
		with(buffer) {
			writeBytes(varuint.encode(cast(uint)name.length)); writeString(name);
			writeBytes(varuint.encode(cast(uint)data.length)); writeBytes(data);
		}
	}

	public pure nothrow @safe void decode(Buffer buffer) {
		with(buffer) {
			uint bmftzq=varuint.decode(_buffer, &_index); name=readString(bmftzq);
			data.length=varuint.decode(_buffer, &_index); if(_buffer.length>=_index+data.length){ data=_buffer[_index.._index+data.length].dup; _index+=data.length; }
		}
	}

}

struct PlayerList {

	public enum string[] FIELDS = ["uuid", "entityId", "displayName", "skin"];

	public UUID uuid;
	public long entityId;
	public string displayName;
	public sul.protocol.pocket101.types.Skin skin;

	public pure nothrow @safe void encode(Buffer buffer) {
		with(buffer) {
			writeBytes(uuid.data);
			writeBytes(varlong.encode(entityId));
			writeBytes(varuint.encode(cast(uint)displayName.length)); writeString(displayName);
			skin.encode(bufferInstance);
		}
	}

	public pure nothrow @safe void decode(Buffer buffer) {
		with(buffer) {
			if(_buffer.length>=_index+16){ ubyte[16] dxvpza=_buffer[_index.._index+16].dup; _index+=16; uuid=UUID(dxvpza); }
			entityId=varlong.decode(_buffer, &_index);
			uint zglzcgxheu5hbwu=varuint.decode(_buffer, &_index); displayName=readString(zglzcgxheu5hbwu);
			skin.decode(bufferInstance);
		}
	}

}

struct Recipe {

	// type
	public enum int SHAPELESS = 0;
	public enum int SHAPED = 1;
	public enum int FURNACE = 2;
	public enum int FURNACE_DATA = 3;
	public enum int MULTI = 4;

	public enum string[] FIELDS = ["type", "data"];

	public int type;
	public ubyte[] data;

	public pure nothrow @safe void encode(Buffer buffer) {
		with(buffer) {
			writeBytes(varint.encode(type));
			writeBytes(data);
		}
	}

	public pure nothrow @safe void decode(Buffer buffer) {
		with(buffer) {
			type=varint.decode(_buffer, &_index);
			data=_buffer[_index..$].dup; _index=_buffer.length;
		}
	}

}
