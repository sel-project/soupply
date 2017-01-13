/*
 * This file has been automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generator: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/hncom1.xml
 */
/**
 * Packets used during the authentication process to exchange informations.
 */
module sul.protocol.hncom1.login;

import std.bitmanip : write, peek;
import std.conv : to;
import std.system : Endian;
import std.typetuple : TypeTuple;
import std.typecons : Tuple;
import std.uuid : UUID;

import sul.utils.buffer;
import sul.utils.var;

static import sul.protocol.hncom1.types;

alias Packets = TypeTuple!(Connection, ConnectionResponse, Info, Ready);

/**
 * First real packet sent by the client with its informations.
 */
class Connection : Buffer {

	public enum ubyte ID = 0;

	public enum bool CLIENTBOUND = false;
	public enum bool SERVERBOUND = true;

	public enum string[] FIELDS = ["protocol", "name", "main"];

	/**
	 * Version of the protocol used by the client that must match the hub's one
	 */
	public uint protocol;

	/**
	 * Name of the node that will be validated by the hub. It should always be lowercase
	 * and only contain letters, numbers and basic punctuation symbols.
	 */
	public string name;

	/**
	 * Indicates whether the node accepts clients when they first connect to the hub or
	 * exclusively when they are manually transferred.
	 */
	public bool main;

	public pure nothrow @safe @nogc this() {}

	public pure nothrow @safe @nogc this(uint protocol, string name=string.init, bool main=bool.init) {
		this.protocol = protocol;
		this.name = name;
		this.main = main;
	}

	public pure nothrow @safe ubyte[] encode(bool writeId=true)() {
		_buffer.length = 0;
		static if(writeId){ writeBigEndianUbyte(ID); }
		writeBytes(varuint.encode(protocol));
		writeBytes(varuint.encode(cast(uint)name.length)); writeString(name);
		writeBigEndianBool(main);
		return _buffer;
	}

	public pure nothrow @safe void decode(bool readId=true)() {
		static if(readId){ ubyte _id; _id=readBigEndianUbyte(); }
		protocol=varuint.decode(_buffer, &_index);
		uint bmftzq=varuint.decode(_buffer, &_index); name=readString(bmftzq);
		main=readBigEndianBool();
	}

	public static pure nothrow @safe Connection fromBuffer(bool readId=true)(ubyte[] buffer) {
		Connection ret = new Connection();
		ret._buffer = buffer;
		ret.decode!readId();
		return ret;
	}

}

/**
 * Reply always sent after the Connection packet. It indicates the status of the connection,
 * which is accepted only when every field of the packet is true.
 */
class ConnectionResponse : Buffer {

	public enum ubyte ID = 1;

	public enum bool CLIENTBOUND = true;
	public enum bool SERVERBOUND = false;

	public enum string[] FIELDS = ["protocolAccepted", "nameAccepted", "reason"];

	/**
	 * Indicates whether the protocol given at Connection.protocol is equals to the server's
	 * one.
	 */
	public bool protocolAccepted;

	/**
	 * Indicates whether the name has passed the server's validation process.
	 */
	public bool nameAccepted;

	/**
	 * If the nameAccepted is false, indicates the reason why it isn't valid.
	 */
	public string reason;

	public pure nothrow @safe @nogc this() {}

	public pure nothrow @safe @nogc this(bool protocolAccepted, bool nameAccepted=bool.init, string reason=string.init) {
		this.protocolAccepted = protocolAccepted;
		this.nameAccepted = nameAccepted;
		this.reason = reason;
	}

	public pure nothrow @safe ubyte[] encode(bool writeId=true)() {
		_buffer.length = 0;
		static if(writeId){ writeBigEndianUbyte(ID); }
		writeBigEndianBool(protocolAccepted);
		writeBigEndianBool(nameAccepted);
		if(nameAccepted==false){ writeBytes(varuint.encode(cast(uint)reason.length)); writeString(reason); }
		return _buffer;
	}

	public pure nothrow @safe void decode(bool readId=true)() {
		static if(readId){ ubyte _id; _id=readBigEndianUbyte(); }
		protocolAccepted=readBigEndianBool();
		nameAccepted=readBigEndianBool();
		if(nameAccepted==false){ uint cmvhc29u=varuint.decode(_buffer, &_index); reason=readString(cmvhc29u); }
	}

	public static pure nothrow @safe ConnectionResponse fromBuffer(bool readId=true)(ubyte[] buffer) {
		ConnectionResponse ret = new ConnectionResponse();
		ret._buffer = buffer;
		ret.decode!readId();
		return ret;
	}

}

class Info : Buffer {

	public enum ubyte ID = 2;

	public enum bool CLIENTBOUND = true;
	public enum bool SERVERBOUND = false;

	public enum string[] FIELDS = ["serverId", "displayName", "onlineMode", "games", "online", "max", "language", "acceptedLanguages", "nodes", "uuidPool", "socialJson", "additionalJson"];

	public ulong serverId;
	public string displayName;
	public bool onlineMode;
	public sul.protocol.hncom1.types.Game[] games;
	public uint online;
	public uint max;
	public string language;
	public string[] acceptedLanguages;
	public string[] nodes;
	public ulong uuidPool;
	public string socialJson;
	public string additionalJson;

	public pure nothrow @safe @nogc this() {}

	public pure nothrow @safe @nogc this(ulong serverId, string displayName=string.init, bool onlineMode=bool.init, sul.protocol.hncom1.types.Game[] games=(sul.protocol.hncom1.types.Game[]).init, uint online=uint.init, uint max=uint.init, string language=string.init, string[] acceptedLanguages=(string[]).init, string[] nodes=(string[]).init, ulong uuidPool=ulong.init, string socialJson=string.init, string additionalJson=string.init) {
		this.serverId = serverId;
		this.displayName = displayName;
		this.onlineMode = onlineMode;
		this.games = games;
		this.online = online;
		this.max = max;
		this.language = language;
		this.acceptedLanguages = acceptedLanguages;
		this.nodes = nodes;
		this.uuidPool = uuidPool;
		this.socialJson = socialJson;
		this.additionalJson = additionalJson;
	}

	public pure nothrow @safe ubyte[] encode(bool writeId=true)() {
		_buffer.length = 0;
		static if(writeId){ writeBigEndianUbyte(ID); }
		writeBigEndianUlong(serverId);
		writeBytes(varuint.encode(cast(uint)displayName.length)); writeString(displayName);
		writeBigEndianBool(onlineMode);
		writeBytes(varuint.encode(cast(uint)games.length)); foreach(z2ftzxm;games){ z2ftzxm.encode(bufferInstance); }
		writeBytes(varuint.encode(online));
		writeBytes(varuint.encode(max));
		writeBytes(varuint.encode(cast(uint)language.length)); writeString(language);
		writeBytes(varuint.encode(cast(uint)acceptedLanguages.length)); foreach(ywnjzxb0zwrmyw5n;acceptedLanguages){ writeBytes(varuint.encode(cast(uint)ywnjzxb0zwrmyw5n.length)); writeString(ywnjzxb0zwrmyw5n); }
		writeBytes(varuint.encode(cast(uint)nodes.length)); foreach(bm9kzxm;nodes){ writeBytes(varuint.encode(cast(uint)bm9kzxm.length)); writeString(bm9kzxm); }
		writeBigEndianUlong(uuidPool);
		writeBytes(varuint.encode(cast(uint)socialJson.length)); writeString(socialJson);
		writeBytes(varuint.encode(cast(uint)additionalJson.length)); writeString(additionalJson);
		return _buffer;
	}

	public pure nothrow @safe void decode(bool readId=true)() {
		static if(readId){ ubyte _id; _id=readBigEndianUbyte(); }
		serverId=readBigEndianUlong();
		uint zglzcgxheu5hbwu=varuint.decode(_buffer, &_index); displayName=readString(zglzcgxheu5hbwu);
		onlineMode=readBigEndianBool();
		games.length=varuint.decode(_buffer, &_index); foreach(ref z2ftzxm;games){ z2ftzxm.decode(bufferInstance); }
		online=varuint.decode(_buffer, &_index);
		max=varuint.decode(_buffer, &_index);
		uint bgfuz3vhz2u=varuint.decode(_buffer, &_index); language=readString(bgfuz3vhz2u);
		acceptedLanguages.length=varuint.decode(_buffer, &_index); foreach(ref ywnjzxb0zwrmyw5n;acceptedLanguages){ uint exduanp4yjb6d3jt=varuint.decode(_buffer, &_index); ywnjzxb0zwrmyw5n=readString(exduanp4yjb6d3jt); }
		nodes.length=varuint.decode(_buffer, &_index); foreach(ref bm9kzxm;nodes){ uint ym05a3p4bq=varuint.decode(_buffer, &_index); bm9kzxm=readString(ym05a3p4bq); }
		uuidPool=readBigEndianUlong();
		uint c29jawfssnnvbg=varuint.decode(_buffer, &_index); socialJson=readString(c29jawfssnnvbg);
		uint ywrkaxrpb25hbepz=varuint.decode(_buffer, &_index); additionalJson=readString(ywrkaxrpb25hbepz);
	}

	public static pure nothrow @safe Info fromBuffer(bool readId=true)(ubyte[] buffer) {
		Info ret = new Info();
		ret._buffer = buffer;
		ret.decode!readId();
		return ret;
	}

}

class Ready : Buffer {

	public enum ubyte ID = 3;

	public enum bool CLIENTBOUND = false;
	public enum bool SERVERBOUND = true;

	public enum string[] FIELDS = ["plugins"];

	public sul.protocol.hncom1.types.Plugin[] plugins;

	public pure nothrow @safe @nogc this() {}

	public pure nothrow @safe @nogc this(sul.protocol.hncom1.types.Plugin[] plugins) {
		this.plugins = plugins;
	}

	public pure nothrow @safe ubyte[] encode(bool writeId=true)() {
		_buffer.length = 0;
		static if(writeId){ writeBigEndianUbyte(ID); }
		writeBytes(varuint.encode(cast(uint)plugins.length)); foreach(cgx1z2lucw;plugins){ cgx1z2lucw.encode(bufferInstance); }
		return _buffer;
	}

	public pure nothrow @safe void decode(bool readId=true)() {
		static if(readId){ ubyte _id; _id=readBigEndianUbyte(); }
		plugins.length=varuint.decode(_buffer, &_index); foreach(ref cgx1z2lucw;plugins){ cgx1z2lucw.decode(bufferInstance); }
	}

	public static pure nothrow @safe Ready fromBuffer(bool readId=true)(ubyte[] buffer) {
		Ready ret = new Ready();
		ret._buffer = buffer;
		ret.decode!readId();
		return ret;
	}

}
