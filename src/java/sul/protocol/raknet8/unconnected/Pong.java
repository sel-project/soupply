/*
 * This file has been automatically generated by sel-utils and
 * it's released under the GNU General Public License version 3.
 *
 * Repository: https://github.com/sel-project/sel-utils
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * From: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/raknet8.xml
 */
package sul.protocol.raknet8.unconnected;

import java.util.UUID;

import sul.protocol.raknet8.types.*;
import sul.utils.Packet;

class Pong extends Packet {

	public final static byte ID = (byte)28;

	public final static boolean CLIENTBOUND = true;
	public final static boolean SERVERBOUND = false;

	public long pingId;
	public long serverId;
	public byte[16] magic;
	public String status;

	@Override
	public byte[] encode() {
	}

	@Override
	public void decode(byte[] buffer) {
	}

}
