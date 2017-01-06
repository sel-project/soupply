/*
 * This file has been automatically generated by sel-utils and
 * it's released under the GNU General Public License version 3.
 *
 * Repository: https://github.com/sel-project/sel-utils
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * From: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/hncom1.xml
 */
package sul.protocol.hncom1.player;

import java.util.UUID;

import sul.protocol.hncom1.types.*;
import sul.utils.Packet;

class UpdateLatency extends Packet {

	public final static byte ID = (byte)16;

	public final static boolean CLIENTBOUND = true;
	public final static boolean SERVERBOUND = false;

	public int hubId;
	public int latency;

	@Override
	public byte[] encode() {
	}

	@Override
	public void decode(byte[] buffer) {
	}

}
