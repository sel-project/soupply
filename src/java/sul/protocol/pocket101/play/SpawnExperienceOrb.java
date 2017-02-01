/*
 * This file was automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generated from https://github.com/sel-project/sel-utils/blob/master/xml/protocol/pocket101.xml
 */
package sul.protocol.pocket101.play;

import sul.utils.*;

public class SpawnExperienceOrb extends Packet {

	public static final byte ID = (byte)65;

	public static final boolean CLIENTBOUND = true;
	public static final boolean SERVERBOUND = false;

	public Tuples.FloatXYZ position;
	public int count;

	public SpawnExperienceOrb() {}

	public SpawnExperienceOrb(Tuples.FloatXYZ position, int count) {
		this.position = position;
		this.count = count;
	}

	@Override
	public int length() {
		return Buffer.varintLength(count) + 13;
	}

	@Override
	public byte[] encode() {
		this._buffer = new byte[this.length()];
		this.writeBigEndianByte(ID);
		this.writeLittleEndianFloat(position.x); this.writeLittleEndianFloat(position.y); this.writeLittleEndianFloat(position.z);
		this.writeVarint(count);
		return this.getBuffer();
	}

	@Override
	public void decode(byte[] buffer) {
		this._buffer = buffer;
		readBigEndianByte();
		position.x=readLittleEndianFloat(); position.y=readLittleEndianFloat(); position.z=readLittleEndianFloat();
		count=this.readVarint();
	}

	public static SpawnExperienceOrb fromBuffer(byte[] buffer) {
		SpawnExperienceOrb ret = new SpawnExperienceOrb();
		ret.decode(buffer);
		return ret;
	}

}
