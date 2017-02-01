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

public class MovePlayer extends Packet {

	public static final byte ID = (byte)20;

	public static final boolean CLIENTBOUND = true;
	public static final boolean SERVERBOUND = true;

	// animation
	public static final byte FULL = 0;
	public static final byte NONE = 1;
	public static final byte ROTATION = 2;

	public long entityId;
	public Tuples.FloatXYZ position;
	public float pitch;
	public float headYaw;
	public float yaw;
	public byte animation;
	public boolean onGround;

	public MovePlayer() {}

	public MovePlayer(long entityId, Tuples.FloatXYZ position, float pitch, float headYaw, float yaw, byte animation, boolean onGround) {
		this.entityId = entityId;
		this.position = position;
		this.pitch = pitch;
		this.headYaw = headYaw;
		this.yaw = yaw;
		this.animation = animation;
		this.onGround = onGround;
	}

	@Override
	public int length() {
		return Buffer.varlongLength(entityId) + 27;
	}

	@Override
	public byte[] encode() {
		this._buffer = new byte[this.length()];
		this.writeBigEndianByte(ID);
		this.writeVarlong(entityId);
		this.writeLittleEndianFloat(position.x); this.writeLittleEndianFloat(position.y); this.writeLittleEndianFloat(position.z);
		this.writeLittleEndianFloat(pitch);
		this.writeLittleEndianFloat(headYaw);
		this.writeLittleEndianFloat(yaw);
		this.writeBigEndianByte(animation);
		this.writeBool(onGround);
		return this.getBuffer();
	}

	@Override
	public void decode(byte[] buffer) {
		this._buffer = buffer;
		readBigEndianByte();
		entityId=this.readVarlong();
		position.x=readLittleEndianFloat(); position.y=readLittleEndianFloat(); position.z=readLittleEndianFloat();
		pitch=readLittleEndianFloat();
		headYaw=readLittleEndianFloat();
		yaw=readLittleEndianFloat();
		animation=readBigEndianByte();
		onGround=this.readBool();
	}

	public static MovePlayer fromBuffer(byte[] buffer) {
		MovePlayer ret = new MovePlayer();
		ret.decode(buffer);
		return ret;
	}

}
