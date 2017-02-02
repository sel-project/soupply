/*
 * This file was automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generated from https://github.com/sel-project/sel-utils/blob/master/xml/protocol/hncom1.xml
 */
package sul.protocol.hncom1.player;

import java.nio.charset.StandardCharsets;

import sul.utils.*;

public class UpdateDisplayName extends Packet {

	public static final byte ID = (byte)17;

	public static final boolean CLIENTBOUND = false;
	public static final boolean SERVERBOUND = true;

	public int hubId;
	public String displayName;

	public UpdateDisplayName() {}

	public UpdateDisplayName(int hubId, String displayName) {
		this.hubId = hubId;
		this.displayName = displayName;
	}

	@Override
	public int length() {
		return Buffer.varuintLength(hubId) + Buffer.varuintLength(displayName.getBytes(StandardCharsets.UTF_8).length) + displayName.getBytes(StandardCharsets.UTF_8).length + 1;
	}

	@Override
	public byte[] encode() {
		this._buffer = new byte[this.length()];
		this.writeBigEndianByte(ID);
		this.writeVaruint(hubId);
		byte[] zglzcgxheu5hbwu=displayName.getBytes(StandardCharsets.UTF_8); this.writeVaruint((int)zglzcgxheu5hbwu.length); this.writeBytes(zglzcgxheu5hbwu);
		return this.getBuffer();
	}

	@Override
	public void decode(byte[] buffer) {
		this._buffer = buffer;
		readBigEndianByte();
		hubId=this.readVaruint();
		int bgvuzglzcgxheu5h=this.readVaruint(); displayName=new String(this.readBytes(bgvuzglzcgxheu5h), StandardCharsets.UTF_8);
	}

	public static UpdateDisplayName fromBuffer(byte[] buffer) {
		UpdateDisplayName ret = new UpdateDisplayName();
		ret.decode(buffer);
		return ret;
	}

}
