/*
 * This file was automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generated from https://github.com/sel-project/sel-utils/blob/master/xml/protocol/hncom1.xml
 */
package sul.protocol.hncom1.status;

import sul.utils.*;

/**
 * Updates the usage of the resources in the node.
 */
public class ResourcesUsage extends Packet {

	public static final byte ID = (byte)7;

	public static final boolean CLIENTBOUND = false;
	public static final boolean SERVERBOUND = true;

	public float tps;
	public long ram;
	public float cpu;

	public ResourcesUsage() {}

	public ResourcesUsage(float tps, long ram, float cpu) {
		this.tps = tps;
		this.ram = ram;
		this.cpu = cpu;
	}

	@Override
	public int length() {
		return Buffer.varulongLength(ram) + 9;
	}

	@Override
	public byte[] encode() {
		this._buffer = new byte[this.length()];
		this.writeBigEndianByte(ID);
		this.writeBigEndianFloat(tps);
		this.writeVarulong(ram);
		this.writeBigEndianFloat(cpu);
		return this.getBuffer();
	}

	@Override
	public void decode(byte[] buffer) {
		this._buffer = buffer;
		readBigEndianByte();
		tps=readBigEndianFloat();
		ram=this.readVarulong();
		cpu=readBigEndianFloat();
	}

	public static ResourcesUsage fromBuffer(byte[] buffer) {
		ResourcesUsage ret = new ResourcesUsage();
		ret.decode(buffer);
		return ret;
	}

}
