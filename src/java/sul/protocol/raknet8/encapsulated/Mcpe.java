/*
 * This file has been automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generator: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/raknet8.xml
 */
package sul.protocol.raknet8.encapsulated;

import java.util.UUID;

import sul.protocol.raknet8.types.*;
import sul.utils.*;

class Mcpe extends Packet {

	public final static byte ID = (byte)254;

	public final static boolean CLIENTBOUND = true;
	public final static boolean SERVERBOUND = true;

	public byte[] packet;

	@Override
	public int length() {
		return packet.length;
	}

	@Override
	public byte[] encode() {
	}

	@Override
	public void decode(byte[] buffer) {
	}

}
