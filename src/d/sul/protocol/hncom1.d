module sul.protocol.hncom1;

import std.bitmanip : read, write;
import std.conv : to;
import std.uuid : UUID;
import std.system : Endian;
import std.typecons : Tuple, tuple;

import sul.types.var;

static struct Types {

	static struct Skin {

		public string name;
		public ubyte[] data;

		public void encode(ref ubyte[] buffer) {
			ubyte[] bmFtZQ=cast(ubyte[])name; buffer~=varuint.encode(bmFtZQ.length.to!uint); buffer~=bmFtZQ;
			buffer~=varuint.encode(data.length.to!uint); buffer~=data;
		}

		public void decode(ref ubyte[] buffer) {
			ubyte[] bmFtZQ; bmFtZQ.length=varuint.fromBuffer(buffer);if(buffer.length>=bmFtZQ.length){ bmFtZQ=buffer[0..bmFtZQ.length]; buffer=buffer[bmFtZQ.length..$]; }; name=cast(string)bmFtZQ;
			data.length=varuint.fromBuffer(buffer);if(buffer.length>=data.length){ data=buffer[0..data.length]; buffer=buffer[data.length..$]; }
		}

	}

	static struct Address {

		public ubyte[] bytes;
		public ushort port;

		public void encode(ref ubyte[] buffer) {
			buffer~=varuint.encode(bytes.length.to!uint); buffer~=bytes;
			buffer.length+=ushort.sizeof; write!(ushort, Endian.bigEndian)(buffer, port, buffer.length-ushort.sizeof);
		}

		public void decode(ref ubyte[] buffer) {
			bytes.length=varuint.fromBuffer(buffer);if(buffer.length>=bytes.length){ bytes=buffer[0..bytes.length]; buffer=buffer[bytes.length..$]; }
			if(buffer.length>=ushort.sizeof){ port=read!(ushort, Endian.bigEndian)(buffer); }
		}

	}

	static struct Log {

		public ulong timestamp;
		public string logger;
		public string message;

		public void encode(ref ubyte[] buffer) {
			buffer.length+=ulong.sizeof; write!(ulong, Endian.bigEndian)(buffer, timestamp, buffer.length-ulong.sizeof);
			ubyte[] bG9nZ2Vy=cast(ubyte[])logger; buffer~=varuint.encode(bG9nZ2Vy.length.to!uint); buffer~=bG9nZ2Vy;
			ubyte[] bWVzc2FnZQ=cast(ubyte[])message; buffer~=varuint.encode(bWVzc2FnZQ.length.to!uint); buffer~=bWVzc2FnZQ;
		}

		public void decode(ref ubyte[] buffer) {
			if(buffer.length>=ulong.sizeof){ timestamp=read!(ulong, Endian.bigEndian)(buffer); }
			ubyte[] bG9nZ2Vy; bG9nZ2Vy.length=varuint.fromBuffer(buffer);if(buffer.length>=bG9nZ2Vy.length){ bG9nZ2Vy=buffer[0..bG9nZ2Vy.length]; buffer=buffer[bG9nZ2Vy.length..$]; }; logger=cast(string)bG9nZ2Vy;
			ubyte[] bWVzc2FnZQ; bWVzc2FnZQ.length=varuint.fromBuffer(buffer);if(buffer.length>=bWVzc2FnZQ.length){ bWVzc2FnZQ=buffer[0..bWVzc2FnZQ.length]; buffer=buffer[bWVzc2FnZQ.length..$]; }; message=cast(string)bWVzc2FnZQ;
		}

	}

	static struct Game {

		public ubyte type;
		public uint[] protocols;
		public string motd;
		public ushort port;

		public void encode(ref ubyte[] buffer) {
			buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, type, buffer.length-ubyte.sizeof);
			buffer~=varuint.encode(protocols.length.to!uint);foreach(cHJvdG9jb2xz;protocols){ buffer.length+=uint.sizeof; write!(uint, Endian.bigEndian)(buffer, cHJvdG9jb2xz, buffer.length-uint.sizeof); }
			ubyte[] bW90ZA=cast(ubyte[])motd; buffer~=varuint.encode(bW90ZA.length.to!uint); buffer~=bW90ZA;
			buffer.length+=ushort.sizeof; write!(ushort, Endian.bigEndian)(buffer, port, buffer.length-ushort.sizeof);
		}

		public void decode(ref ubyte[] buffer) {
			if(buffer.length>=ubyte.sizeof){ type=read!(ubyte, Endian.bigEndian)(buffer); }
			protocols.length=varuint.fromBuffer(buffer);foreach(ref cHJvdG9jb2xz;protocols){ if(buffer.length>=uint.sizeof){ cHJvdG9jb2xz=read!(uint, Endian.bigEndian)(buffer); }}
			ubyte[] bW90ZA; bW90ZA.length=varuint.fromBuffer(buffer);if(buffer.length>=bW90ZA.length){ bW90ZA=buffer[0..bW90ZA.length]; buffer=buffer[bW90ZA.length..$]; }; motd=cast(string)bW90ZA;
			if(buffer.length>=ushort.sizeof){ port=read!(ushort, Endian.bigEndian)(buffer); }
		}

	}

	static struct Plugin {

		public string name;
		public string vers;

		public void encode(ref ubyte[] buffer) {
			ubyte[] bmFtZQ=cast(ubyte[])name; buffer~=varuint.encode(bmFtZQ.length.to!uint); buffer~=bmFtZQ;
			ubyte[] dmVycw=cast(ubyte[])vers; buffer~=varuint.encode(dmVycw.length.to!uint); buffer~=dmVycw;
		}

		public void decode(ref ubyte[] buffer) {
			ubyte[] bmFtZQ; bmFtZQ.length=varuint.fromBuffer(buffer);if(buffer.length>=bmFtZQ.length){ bmFtZQ=buffer[0..bmFtZQ.length]; buffer=buffer[bmFtZQ.length..$]; }; name=cast(string)bmFtZQ;
			ubyte[] dmVycw; dmVycw.length=varuint.fromBuffer(buffer);if(buffer.length>=dmVycw.length){ dmVycw=buffer[0..dmVycw.length]; buffer=buffer[dmVycw.length..$]; }; vers=cast(string)dmVycw;
		}

	}

}

static struct Packets {

	static struct Generic {

		static struct Logs {

			public enum ubyte packetId = 7;

			public enum bool clientbound = false;
			public enum bool serverbound = true;

			public Types.Log[] messages;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer~=varuint.encode(messages.length.to!uint);foreach(bWVzc2FnZXM;messages){ bWVzc2FnZXM.encode(buffer); }
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				messages.length=varuint.fromBuffer(buffer);foreach(ref bWVzc2FnZXM;messages){ bWVzc2FnZXM.decode(buffer);}
				return this;
			}

		}

		static struct RemoteCommand {

			public enum ubyte packetId = 8;

			public enum bool clientbound = true;
			public enum bool serverbound = false;

			public ubyte origin;
			public Types.Address sender;
			public string command;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, origin, buffer.length-ubyte.sizeof);
				sender.encode(buffer);
				ubyte[] Y29tbWFuZA=cast(ubyte[])command; buffer~=varuint.encode(Y29tbWFuZA.length.to!uint); buffer~=Y29tbWFuZA;
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				if(buffer.length>=ubyte.sizeof){ origin=read!(ubyte, Endian.bigEndian)(buffer); }
				sender.decode(buffer);
				ubyte[] Y29tbWFuZA; Y29tbWFuZA.length=varuint.fromBuffer(buffer);if(buffer.length>=Y29tbWFuZA.length){ Y29tbWFuZA=buffer[0..Y29tbWFuZA.length]; buffer=buffer[Y29tbWFuZA.length..$]; }; command=cast(string)Y29tbWFuZA;
				return this;
			}

		}

		static struct UpdateList {

			public enum ubyte packetId = 9;

			public enum bool clientbound = false;
			public enum bool serverbound = true;

			public ubyte list;
			public ubyte action;
			public ubyte type;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, list, buffer.length-ubyte.sizeof);
				buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, action, buffer.length-ubyte.sizeof);
				buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, type, buffer.length-ubyte.sizeof);
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				if(buffer.length>=ubyte.sizeof){ list=read!(ubyte, Endian.bigEndian)(buffer); }
				if(buffer.length>=ubyte.sizeof){ action=read!(ubyte, Endian.bigEndian)(buffer); }
				if(buffer.length>=ubyte.sizeof){ type=read!(ubyte, Endian.bigEndian)(buffer); }
				return this;
			}

			static struct ByName {

				public ubyte list;
				public ubyte action;
				public enum ubyte type = 1;
				public string username;

				public ubyte[] encode(bool write_id=true)() {
					ubyte[] buffer;
					static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
					buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, list, buffer.length-ubyte.sizeof);
					buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, action, buffer.length-ubyte.sizeof);
					buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, type, buffer.length-ubyte.sizeof);
					ubyte[] dXNlcm5hbWU=cast(ubyte[])username; buffer~=varuint.encode(dXNlcm5hbWU.length.to!uint); buffer~=dXNlcm5hbWU;
					return buffer;
				}

				public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
					static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
					if(buffer.length>=ubyte.sizeof){ list=read!(ubyte, Endian.bigEndian)(buffer); }
					if(buffer.length>=ubyte.sizeof){ action=read!(ubyte, Endian.bigEndian)(buffer); }
					ubyte __field_value; if(buffer.length>=ubyte.sizeof){ __field_value=read!(ubyte, Endian.bigEndian)(buffer); }
					ubyte[] dXNlcm5hbWU; dXNlcm5hbWU.length=varuint.fromBuffer(buffer);if(buffer.length>=dXNlcm5hbWU.length){ dXNlcm5hbWU=buffer[0..dXNlcm5hbWU.length]; buffer=buffer[dXNlcm5hbWU.length..$]; }; username=cast(string)dXNlcm5hbWU;
					return this;
				}

			}

			static struct ByHubId {

				public ubyte list;
				public ubyte action;
				public enum ubyte type = 0;
				public uint hubId;

				public ubyte[] encode(bool write_id=true)() {
					ubyte[] buffer;
					static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
					buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, list, buffer.length-ubyte.sizeof);
					buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, action, buffer.length-ubyte.sizeof);
					buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, type, buffer.length-ubyte.sizeof);
					buffer~=varuint.encode(hubId);
					return buffer;
				}

				public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
					static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
					if(buffer.length>=ubyte.sizeof){ list=read!(ubyte, Endian.bigEndian)(buffer); }
					if(buffer.length>=ubyte.sizeof){ action=read!(ubyte, Endian.bigEndian)(buffer); }
					ubyte __field_value; if(buffer.length>=ubyte.sizeof){ __field_value=read!(ubyte, Endian.bigEndian)(buffer); }
					hubId=varuint.fromBuffer(buffer);
					return this;
				}

			}

			static struct BySuuid {

				public ubyte list;
				public ubyte action;
				public enum ubyte type = 2;
				public ubyte game;
				public UUID uuid;

				public ubyte[] encode(bool write_id=true)() {
					ubyte[] buffer;
					static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
					buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, list, buffer.length-ubyte.sizeof);
					buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, action, buffer.length-ubyte.sizeof);
					buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, type, buffer.length-ubyte.sizeof);
					buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, game, buffer.length-ubyte.sizeof);
					buffer~=uuid.data;
					return buffer;
				}

				public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
					static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
					if(buffer.length>=ubyte.sizeof){ list=read!(ubyte, Endian.bigEndian)(buffer); }
					if(buffer.length>=ubyte.sizeof){ action=read!(ubyte, Endian.bigEndian)(buffer); }
					ubyte __field_value; if(buffer.length>=ubyte.sizeof){ __field_value=read!(ubyte, Endian.bigEndian)(buffer); }
					if(buffer.length>=ubyte.sizeof){ game=read!(ubyte, Endian.bigEndian)(buffer); }
					if(buffer.length>=16){ ubyte[16] dXVpZA=buffer[0..16]; buffer=buffer[16..$]; uuid=UUID(dXVpZA); }
					return this;
				}

			}

		}

	}

	static struct Player {

		static struct UpdateLatency {

			public enum ubyte packetId = 18;

			public enum bool clientbound = true;
			public enum bool serverbound = false;

			public uint hubId;
			public uint latency;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer~=varuint.encode(hubId);
				buffer~=varuint.encode(latency);
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				hubId=varuint.fromBuffer(buffer);
				latency=varuint.fromBuffer(buffer);
				return this;
			}

		}

		static struct Transfer {

			public enum ubyte packetId = 13;

			public enum bool clientbound = false;
			public enum bool serverbound = true;

			public uint hubId;
			public string node;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer~=varuint.encode(hubId);
				ubyte[] bm9kZQ=cast(ubyte[])node; buffer~=varuint.encode(bm9kZQ.length.to!uint); buffer~=bm9kZQ;
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				hubId=varuint.fromBuffer(buffer);
				ubyte[] bm9kZQ; bm9kZQ.length=varuint.fromBuffer(buffer);if(buffer.length>=bm9kZQ.length){ bm9kZQ=buffer[0..bm9kZQ.length]; buffer=buffer[bm9kZQ.length..$]; }; node=cast(string)bm9kZQ;
				return this;
			}

		}

		static struct OrderedGamePacket {

			public enum ubyte packetId = 17;

			public enum bool clientbound = false;
			public enum bool serverbound = true;

			public uint hubId;
			public uint order;
			public ubyte[] packet;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer~=varuint.encode(hubId);
				buffer~=varuint.encode(order);
				buffer~=packet;
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				hubId=varuint.fromBuffer(buffer);
				order=varuint.fromBuffer(buffer);
				packet=buffer.dup; buffer.length=0;
				return this;
			}

		}

		static struct Add {

			public enum ubyte packetId = 10;

			public enum bool clientbound = true;
			public enum bool serverbound = false;

			public uint hubId;
			public ubyte reason;
			public uint protocol;
			public string username;
			public string displayName;
			public Types.Address address;
			public ubyte game;
			public UUID uuid;
			public Types.Skin skin;
			public uint latency;
			public float packetLoss;
			public string language;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer~=varuint.encode(hubId);
				buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, reason, buffer.length-ubyte.sizeof);
				buffer~=varuint.encode(protocol);
				ubyte[] dXNlcm5hbWU=cast(ubyte[])username; buffer~=varuint.encode(dXNlcm5hbWU.length.to!uint); buffer~=dXNlcm5hbWU;
				ubyte[] ZGlzcGxheU5hbWU=cast(ubyte[])displayName; buffer~=varuint.encode(ZGlzcGxheU5hbWU.length.to!uint); buffer~=ZGlzcGxheU5hbWU;
				address.encode(buffer);
				buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, game, buffer.length-ubyte.sizeof);
				buffer~=uuid.data;
				skin.encode(buffer);
				buffer~=varuint.encode(latency);
				buffer.length+=float.sizeof; write!(float, Endian.bigEndian)(buffer, packetLoss, buffer.length-float.sizeof);
				ubyte[] bGFuZ3VhZ2U=cast(ubyte[])language; buffer~=varuint.encode(bGFuZ3VhZ2U.length.to!uint); buffer~=bGFuZ3VhZ2U;
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				hubId=varuint.fromBuffer(buffer);
				if(buffer.length>=ubyte.sizeof){ reason=read!(ubyte, Endian.bigEndian)(buffer); }
				protocol=varuint.fromBuffer(buffer);
				ubyte[] dXNlcm5hbWU; dXNlcm5hbWU.length=varuint.fromBuffer(buffer);if(buffer.length>=dXNlcm5hbWU.length){ dXNlcm5hbWU=buffer[0..dXNlcm5hbWU.length]; buffer=buffer[dXNlcm5hbWU.length..$]; }; username=cast(string)dXNlcm5hbWU;
				ubyte[] ZGlzcGxheU5hbWU; ZGlzcGxheU5hbWU.length=varuint.fromBuffer(buffer);if(buffer.length>=ZGlzcGxheU5hbWU.length){ ZGlzcGxheU5hbWU=buffer[0..ZGlzcGxheU5hbWU.length]; buffer=buffer[ZGlzcGxheU5hbWU.length..$]; }; displayName=cast(string)ZGlzcGxheU5hbWU;
				address.decode(buffer);
				if(buffer.length>=ubyte.sizeof){ game=read!(ubyte, Endian.bigEndian)(buffer); }
				if(buffer.length>=16){ ubyte[16] dXVpZA=buffer[0..16]; buffer=buffer[16..$]; uuid=UUID(dXVpZA); }
				skin.decode(buffer);
				latency=varuint.fromBuffer(buffer);
				if(buffer.length>=float.sizeof){ packetLoss=read!(float, Endian.bigEndian)(buffer); }
				ubyte[] bGFuZ3VhZ2U; bGFuZ3VhZ2U.length=varuint.fromBuffer(buffer);if(buffer.length>=bGFuZ3VhZ2U.length){ bGFuZ3VhZ2U=buffer[0..bGFuZ3VhZ2U.length]; buffer=buffer[bGFuZ3VhZ2U.length..$]; }; language=cast(string)bGFuZ3VhZ2U;
				return this;
			}

		}

		static struct Kick {

			public enum ubyte packetId = 12;

			public enum bool clientbound = false;
			public enum bool serverbound = true;

			public uint hubId;
			public string reason;
			public bool translation;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer~=varuint.encode(hubId);
				ubyte[] cmVhc29u=cast(ubyte[])reason; buffer~=varuint.encode(cmVhc29u.length.to!uint); buffer~=cmVhc29u;
				buffer.length+=bool.sizeof; write!(bool, Endian.bigEndian)(buffer, translation, buffer.length-bool.sizeof);
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				hubId=varuint.fromBuffer(buffer);
				ubyte[] cmVhc29u; cmVhc29u.length=varuint.fromBuffer(buffer);if(buffer.length>=cmVhc29u.length){ cmVhc29u=buffer[0..cmVhc29u.length]; buffer=buffer[cmVhc29u.length..$]; }; reason=cast(string)cmVhc29u;
				if(buffer.length>=bool.sizeof){ translation=read!(bool, Endian.bigEndian)(buffer); }
				return this;
			}

		}

		static struct UpdateLanguage {

			public enum ubyte packetId = 14;

			public enum bool clientbound = false;
			public enum bool serverbound = true;

			public uint hubId;
			public string language;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer~=varuint.encode(hubId);
				ubyte[] bGFuZ3VhZ2U=cast(ubyte[])language; buffer~=varuint.encode(bGFuZ3VhZ2U.length.to!uint); buffer~=bGFuZ3VhZ2U;
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				hubId=varuint.fromBuffer(buffer);
				ubyte[] bGFuZ3VhZ2U; bGFuZ3VhZ2U.length=varuint.fromBuffer(buffer);if(buffer.length>=bGFuZ3VhZ2U.length){ bGFuZ3VhZ2U=buffer[0..bGFuZ3VhZ2U.length]; buffer=buffer[bGFuZ3VhZ2U.length..$]; }; language=cast(string)bGFuZ3VhZ2U;
				return this;
			}

		}

		static struct Remove {

			public enum ubyte packetId = 11;

			public enum bool clientbound = true;
			public enum bool serverbound = false;

			public uint hubId;
			public ubyte reason;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer~=varuint.encode(hubId);
				buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, reason, buffer.length-ubyte.sizeof);
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				hubId=varuint.fromBuffer(buffer);
				if(buffer.length>=ubyte.sizeof){ reason=read!(ubyte, Endian.bigEndian)(buffer); }
				return this;
			}

		}

		static struct UpdateDisplayName {

			public enum ubyte packetId = 15;

			public enum bool clientbound = false;
			public enum bool serverbound = true;

			public uint hubId;
			public string displayName;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer~=varuint.encode(hubId);
				ubyte[] ZGlzcGxheU5hbWU=cast(ubyte[])displayName; buffer~=varuint.encode(ZGlzcGxheU5hbWU.length.to!uint); buffer~=ZGlzcGxheU5hbWU;
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				hubId=varuint.fromBuffer(buffer);
				ubyte[] ZGlzcGxheU5hbWU; ZGlzcGxheU5hbWU.length=varuint.fromBuffer(buffer);if(buffer.length>=ZGlzcGxheU5hbWU.length){ ZGlzcGxheU5hbWU=buffer[0..ZGlzcGxheU5hbWU.length]; buffer=buffer[ZGlzcGxheU5hbWU.length..$]; }; displayName=cast(string)ZGlzcGxheU5hbWU;
				return this;
			}

		}

		static struct GamePacket {

			public enum ubyte packetId = 16;

			public enum bool clientbound = true;
			public enum bool serverbound = true;

			public uint hubId;
			public ubyte[] packet;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer~=varuint.encode(hubId);
				buffer~=packet;
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				hubId=varuint.fromBuffer(buffer);
				packet=buffer.dup; buffer.length=0;
				return this;
			}

		}

		static struct UpdatePacketLoss {

			public enum ubyte packetId = 19;

			public enum bool clientbound = true;
			public enum bool serverbound = false;

			public uint hubId;
			public float packetLoss;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer~=varuint.encode(hubId);
				buffer.length+=float.sizeof; write!(float, Endian.bigEndian)(buffer, packetLoss, buffer.length-float.sizeof);
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				hubId=varuint.fromBuffer(buffer);
				if(buffer.length>=float.sizeof){ packetLoss=read!(float, Endian.bigEndian)(buffer); }
				return this;
			}

		}

	}

	static struct Login {

		static struct Ready {

			public enum ubyte packetId = 3;

			public enum bool clientbound = false;
			public enum bool serverbound = true;

			public Types.Plugin[] plugins;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer~=varuint.encode(plugins.length.to!uint);foreach(cGx1Z2lucw;plugins){ cGx1Z2lucw.encode(buffer); }
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				plugins.length=varuint.fromBuffer(buffer);foreach(ref cGx1Z2lucw;plugins){ cGx1Z2lucw.decode(buffer);}
				return this;
			}

		}

		static struct ConnectionResponse {

			public enum ubyte packetId = 1;

			public enum bool clientbound = true;
			public enum bool serverbound = false;

			public bool protocolAccepted;
			public bool nameAccepted;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer.length+=bool.sizeof; write!(bool, Endian.bigEndian)(buffer, protocolAccepted, buffer.length-bool.sizeof);
				buffer.length+=bool.sizeof; write!(bool, Endian.bigEndian)(buffer, nameAccepted, buffer.length-bool.sizeof);
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				if(buffer.length>=bool.sizeof){ protocolAccepted=read!(bool, Endian.bigEndian)(buffer); }
				if(buffer.length>=bool.sizeof){ nameAccepted=read!(bool, Endian.bigEndian)(buffer); }
				return this;
			}

		}

		static struct Info {

			public enum ubyte packetId = 2;

			public enum bool clientbound = true;
			public enum bool serverbound = false;

			public long serverId;
			public bool onlineMode;
			public string displayName;
			public Types.Game[] games;
			public uint online;
			public uint max;
			public string language;
			public string[] acceptedLanguages;
			public string[] nodes;
			public string socialJson;
			public string additionalJson;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer.length+=long.sizeof; write!(long, Endian.bigEndian)(buffer, serverId, buffer.length-long.sizeof);
				buffer.length+=bool.sizeof; write!(bool, Endian.bigEndian)(buffer, onlineMode, buffer.length-bool.sizeof);
				ubyte[] ZGlzcGxheU5hbWU=cast(ubyte[])displayName; buffer~=varuint.encode(ZGlzcGxheU5hbWU.length.to!uint); buffer~=ZGlzcGxheU5hbWU;
				buffer~=varuint.encode(games.length.to!uint);foreach(Z2FtZXM;games){ Z2FtZXM.encode(buffer); }
				buffer~=varuint.encode(online);
				buffer~=varuint.encode(max);
				ubyte[] bGFuZ3VhZ2U=cast(ubyte[])language; buffer~=varuint.encode(bGFuZ3VhZ2U.length.to!uint); buffer~=bGFuZ3VhZ2U;
				buffer~=varuint.encode(acceptedLanguages.length.to!uint);foreach(YWNjZXB0ZWRMYW5n;acceptedLanguages){ ubyte[] WVdOalpYQjBaV1JN=cast(ubyte[])YWNjZXB0ZWRMYW5n; buffer~=varuint.encode(WVdOalpYQjBaV1JN.length.to!uint); buffer~=WVdOalpYQjBaV1JN; }
				buffer~=varuint.encode(nodes.length.to!uint);foreach(bm9kZXM;nodes){ ubyte[] Ym05a1pYTQ=cast(ubyte[])bm9kZXM; buffer~=varuint.encode(Ym05a1pYTQ.length.to!uint); buffer~=Ym05a1pYTQ; }
				ubyte[] c29jaWFsSnNvbg=cast(ubyte[])socialJson; buffer~=varuint.encode(c29jaWFsSnNvbg.length.to!uint); buffer~=c29jaWFsSnNvbg;
				ubyte[] YWRkaXRpb25hbEpz=cast(ubyte[])additionalJson; buffer~=varuint.encode(YWRkaXRpb25hbEpz.length.to!uint); buffer~=YWRkaXRpb25hbEpz;
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				if(buffer.length>=long.sizeof){ serverId=read!(long, Endian.bigEndian)(buffer); }
				if(buffer.length>=bool.sizeof){ onlineMode=read!(bool, Endian.bigEndian)(buffer); }
				ubyte[] ZGlzcGxheU5hbWU; ZGlzcGxheU5hbWU.length=varuint.fromBuffer(buffer);if(buffer.length>=ZGlzcGxheU5hbWU.length){ ZGlzcGxheU5hbWU=buffer[0..ZGlzcGxheU5hbWU.length]; buffer=buffer[ZGlzcGxheU5hbWU.length..$]; }; displayName=cast(string)ZGlzcGxheU5hbWU;
				games.length=varuint.fromBuffer(buffer);foreach(ref Z2FtZXM;games){ Z2FtZXM.decode(buffer);}
				online=varuint.fromBuffer(buffer);
				max=varuint.fromBuffer(buffer);
				ubyte[] bGFuZ3VhZ2U; bGFuZ3VhZ2U.length=varuint.fromBuffer(buffer);if(buffer.length>=bGFuZ3VhZ2U.length){ bGFuZ3VhZ2U=buffer[0..bGFuZ3VhZ2U.length]; buffer=buffer[bGFuZ3VhZ2U.length..$]; }; language=cast(string)bGFuZ3VhZ2U;
				acceptedLanguages.length=varuint.fromBuffer(buffer);foreach(ref YWNjZXB0ZWRMYW5n;acceptedLanguages){ ubyte[] WVdOalpYQjBaV1JN; WVdOalpYQjBaV1JN.length=varuint.fromBuffer(buffer);if(buffer.length>=WVdOalpYQjBaV1JN.length){ WVdOalpYQjBaV1JN=buffer[0..WVdOalpYQjBaV1JN.length]; buffer=buffer[WVdOalpYQjBaV1JN.length..$]; }; YWNjZXB0ZWRMYW5n=cast(string)WVdOalpYQjBaV1JN;}
				nodes.length=varuint.fromBuffer(buffer);foreach(ref bm9kZXM;nodes){ ubyte[] Ym05a1pYTQ; Ym05a1pYTQ.length=varuint.fromBuffer(buffer);if(buffer.length>=Ym05a1pYTQ.length){ Ym05a1pYTQ=buffer[0..Ym05a1pYTQ.length]; buffer=buffer[Ym05a1pYTQ.length..$]; }; bm9kZXM=cast(string)Ym05a1pYTQ;}
				ubyte[] c29jaWFsSnNvbg; c29jaWFsSnNvbg.length=varuint.fromBuffer(buffer);if(buffer.length>=c29jaWFsSnNvbg.length){ c29jaWFsSnNvbg=buffer[0..c29jaWFsSnNvbg.length]; buffer=buffer[c29jaWFsSnNvbg.length..$]; }; socialJson=cast(string)c29jaWFsSnNvbg;
				ubyte[] YWRkaXRpb25hbEpz; YWRkaXRpb25hbEpz.length=varuint.fromBuffer(buffer);if(buffer.length>=YWRkaXRpb25hbEpz.length){ YWRkaXRpb25hbEpz=buffer[0..YWRkaXRpb25hbEpz.length]; buffer=buffer[YWRkaXRpb25hbEpz.length..$]; }; additionalJson=cast(string)YWRkaXRpb25hbEpz;
				return this;
			}

		}

		static struct Connection {

			public enum ubyte packetId = 0;

			public enum bool clientbound = false;
			public enum bool serverbound = true;

			public uint protocol;
			public string name;
			public bool mainNode;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer~=varuint.encode(protocol);
				ubyte[] bmFtZQ=cast(ubyte[])name; buffer~=varuint.encode(bmFtZQ.length.to!uint); buffer~=bmFtZQ;
				buffer.length+=bool.sizeof; write!(bool, Endian.bigEndian)(buffer, mainNode, buffer.length-bool.sizeof);
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				protocol=varuint.fromBuffer(buffer);
				ubyte[] bmFtZQ; bmFtZQ.length=varuint.fromBuffer(buffer);if(buffer.length>=bmFtZQ.length){ bmFtZQ=buffer[0..bmFtZQ.length]; buffer=buffer[bmFtZQ.length..$]; }; name=cast(string)bmFtZQ;
				if(buffer.length>=bool.sizeof){ mainNode=read!(bool, Endian.bigEndian)(buffer); }
				return this;
			}

		}

	}

	static struct Status {

		static struct Players {

			public enum ubyte packetId = 4;

			public enum bool clientbound = true;
			public enum bool serverbound = false;

			public uint online;
			public uint max;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer~=varuint.encode(online);
				buffer~=varuint.encode(max);
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				online=varuint.fromBuffer(buffer);
				max=varuint.fromBuffer(buffer);
				return this;
			}

		}

		static struct Nodes {

			public enum ubyte packetId = 5;

			public enum bool clientbound = true;
			public enum bool serverbound = false;

			public ubyte type;
			public string node;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, type, buffer.length-ubyte.sizeof);
				ubyte[] bm9kZQ=cast(ubyte[])node; buffer~=varuint.encode(bm9kZQ.length.to!uint); buffer~=bm9kZQ;
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				if(buffer.length>=ubyte.sizeof){ type=read!(ubyte, Endian.bigEndian)(buffer); }
				ubyte[] bm9kZQ; bm9kZQ.length=varuint.fromBuffer(buffer);if(buffer.length>=bm9kZQ.length){ bm9kZQ=buffer[0..bm9kZQ.length]; buffer=buffer[bm9kZQ.length..$]; }; node=cast(string)bm9kZQ;
				return this;
			}

		}

		static struct ResourcesUsage {

			public enum ubyte packetId = 6;

			public enum bool clientbound = false;
			public enum bool serverbound = true;

			public float tps;
			public ulong ramUsed;
			public float cpuUsed;

			public ubyte[] encode(bool write_id=true)() {
				ubyte[] buffer;
				static if(write_id){ buffer.length+=ubyte.sizeof; write!(ubyte, Endian.bigEndian)(buffer, packetId, buffer.length-ubyte.sizeof); }
				buffer.length+=float.sizeof; write!(float, Endian.bigEndian)(buffer, tps, buffer.length-float.sizeof);
				buffer~=varulong.encode(ramUsed);
				buffer.length+=float.sizeof; write!(float, Endian.bigEndian)(buffer, cpuUsed, buffer.length-float.sizeof);
				return buffer;
			}

			public typeof(this) decode(bool read_id=true)(ubyte[] buffer) {
				static if(read_id){ ubyte _packet_id; if(buffer.length>=ubyte.sizeof){ _packet_id=read!(ubyte, Endian.bigEndian)(buffer); } }
				if(buffer.length>=float.sizeof){ tps=read!(float, Endian.bigEndian)(buffer); }
				ramUsed=varulong.fromBuffer(buffer);
				if(buffer.length>=float.sizeof){ cpuUsed=read!(float, Endian.bigEndian)(buffer); }
				return this;
			}

		}

	}

}
