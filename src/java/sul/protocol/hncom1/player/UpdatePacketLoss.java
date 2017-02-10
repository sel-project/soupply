/*
 * This file was automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generated from https://github.com/sel-project/sel-utils/blob/master/xml/protocol/hncom1.xml
 */
package sul.protocol.hncom1.player;

import sul.utils.*;

/**
 * Updates the player's packet loss if it uses a connectionless protocol like UDP.
 */
public class UpdatePacketLoss extends Packet {

	public static final byte ID = (byte)23;

	public static final boolean CLIENTBOUND = true;
	public static final boolean SERVERBOUND = false;

	public int hubId;

	/**
	 * Percentage of lost packets in range 0 (no packet lost) to 100 (every packet lost).
	 */
	public float packetLoss;

	public UpdatePacketLoss() {}

	public UpdatePacketLoss(int hubId, float packetLoss) {
		this.hubId = hubId;
		this.packetLoss = packetLoss;
	}

	@Override
	public int length() {
		return Buffer.varuintLength(hubId) + 5;
	}

	@Override
	public byte[] encode() {
		this._buffer = new byte[this.length()];
		this.writeBigEndianByte(ID);
		this.writeVaruint(hubId);
		this.writeBigEndianFloat(packetLoss);
		return this.getBuffer();
	}

	@Override
	public void decode(byte[] buffer) {
		this._buffer = buffer;
		readBigEndianByte();
		hubId=this.readVaruint();
		packetLoss=readBigEndianFloat();
	}

	public static UpdatePacketLoss fromBuffer(byte[] buffer) {
		UpdatePacketLoss ret = new UpdatePacketLoss();
		ret.decode(buffer);
		return ret;
	}

	@Override
	public String toString() {
		return "UpdatePacketLoss(hubId: " + this.hubId + ", packetLoss: " + this.packetLoss + ")";
	}

}
