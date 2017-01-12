/*
 * This file has been automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generator: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/externalconsole1.xml
 */
package sul.protocol.externalconsole1.status;

import java.util.UUID;

import sul.protocol.externalconsole1.types.*;
import sul.utils.*;

/**
 * Requests an UpdateStats packet to the server, which should sent it immediately instead
 * of waiting for the next automatic update.
 */
class RequestStats extends Packet {

	public final static byte ID = (byte)2;

	public final static boolean CLIENTBOUND = false;
	public final static boolean SERVERBOUND = true;

	@Override
	public int length() {
	}

	@Override
	public byte[] encode() {
		this.buffer = new byte[this.length()];
		this.index = 0;
		this.writeByteB(ID);
		return this.buffer;
	}

	@Override
	public void decode(byte[] buffer) {
		this.buffer = buffer;
		this.index = 0;
	}

}
