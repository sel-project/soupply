/*
 * This file has been automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generator: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/hncom1.xml
 */
package sul.protocol.hncom1.player;

import java.util.UUID;

import sul.protocol.hncom1.types.*;
import sul.utils.*;

class Add extends Packet {

	public final static byte ID = (byte)10;

	public final static boolean CLIENTBOUND = true;
	public final static boolean SERVERBOUND = false;

	// reason
	public static immutable byte FIRST_JOIN = 0;
	public static immutable byte TRANSFERRED = 1;
	public static immutable byte FORCIBLY_TRANSFERRED = 2;

	// game
	public static immutable byte POCKET = 1;
	public static immutable byte MINECRAFT = 2;

	public int hubId;
	public byte reason;
	public int protocol;
	public String username;
	public String displayName;
	public Address address;
	public byte game;
	public UUID uuid;
	public Skin skin;
	public int latency;
	public float packetLoss;
	public String language;

	@Override
	public int length() {
	}

	@Override
	public byte[] encode() {
		this.buffer = new byte[this.length()];
		this.index = 0;
		this.writeByteB(ID);
		this.writeVaruint(hubId);
		this.writeByteB(reason);
		this.writeVaruint(protocol);
		byte[] dxnlcm5hbwu=username.getBytes("UTF-8"); this.writeVaruint((int)dxnlcm5hbwu.length); this.writeBytes(dxnlcm5hbwu);
		byte[] zglzcgxheu5hbwu=displayName.getBytes("UTF-8"); this.writeVaruint((int)zglzcgxheu5hbwu.length); this.writeBytes(zglzcgxheu5hbwu);
		this.writeBytes(address.encode());
		this.writeByteB(game);
		this.writeLongB(uuid.getLeastSignificantBits()); this.writeLongB(uuid.getMostSignificantBits());
		this.writeBytes(skin.encode());
		this.writeVaruint(latency);
		this.writeFloatB(packetLoss);
		byte[] bgfuz3vhz2u=language.getBytes("UTF-8"); this.writeVaruint((int)bgfuz3vhz2u.length); this.writeBytes(bgfuz3vhz2u);
		return this.buffer;
	}

	@Override
	public void decode(byte[] buffer) {
		this.buffer = buffer;
		this.index = 0;
	}

}
