/*
 * This file was automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 * 
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generated from https://github.com/sel-project/sel-utils/blob/master/xml/protocol/pocket105.xml
 */
package sul.protocol.pocket105.play;

import java.nio.charset.StandardCharsets;

import sul.utils.*;

public class PlaySound extends Packet {

	public static final byte ID = (byte)86;

	public static final boolean CLIENTBOUND = true;
	public static final boolean SERVERBOUND = false;

	@Override
	public int getId() {
		return ID;
	}

	public String unknown0;
	public sul.protocol.pocket105.types.BlockPosition position;
	public float unknown2;
	public float unknown3;

	public PlaySound() {}

	public PlaySound(String unknown0, sul.protocol.pocket105.types.BlockPosition position, float unknown2, float unknown3) {
		this.unknown0 = unknown0;
		this.position = position;
		this.unknown2 = unknown2;
		this.unknown3 = unknown3;
	}

	@Override
	public int length() {
		return Buffer.varuintLength(unknown0.getBytes(StandardCharsets.UTF_8).length) + unknown0.getBytes(StandardCharsets.UTF_8).length + position.length() + 9;
	}

	@Override
	public byte[] encode() {
		this._buffer = new byte[this.length()];
		this.writeBigEndianByte(ID);
		byte[] d5b9ba=unknown0.getBytes(StandardCharsets.UTF_8); this.writeVaruint((int)d5b9ba.length); this.writeBytes(d5b9ba);
		this.writeBytes(position.encode());
		this.writeLittleEndianFloat(unknown2);
		this.writeLittleEndianFloat(unknown3);
		return this.getBuffer();
	}

	@Override
	public void decode(byte[] buffer) {
		this._buffer = buffer;
		readBigEndianByte();
		int bvd5b9ba=this.readVaruint(); unknown0=new String(this.readBytes(bvd5b9ba), StandardCharsets.UTF_8);
		position=new sul.protocol.pocket105.types.BlockPosition(); position._index=this._index; position.decode(this._buffer); this._index=position._index;
		unknown2=readLittleEndianFloat();
		unknown3=readLittleEndianFloat();
	}

	public static PlaySound fromBuffer(byte[] buffer) {
		PlaySound ret = new PlaySound();
		ret.decode(buffer);
		return ret;
	}

	@Override
	public String toString() {
		return "PlaySound(unknown0: " + this.unknown0 + ", position: " + this.position.toString() + ", unknown2: " + this.unknown2 + ", unknown3: " + this.unknown3 + ")";
	}

}
