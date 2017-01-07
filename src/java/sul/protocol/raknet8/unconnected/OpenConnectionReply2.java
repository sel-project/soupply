/*
 * This file has been automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generator: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/raknet8.xml
 */
package sul.protocol.raknet8.unconnected;

import java.util.UUID;

import sul.protocol.raknet8.types.*;
import sul.utils.*;

class OpenConnectionReply2 extends Packet {

	public final static byte ID = (byte)8;

	public final static boolean CLIENTBOUND = true;
	public final static boolean SERVERBOUND = false;

	public byte[16] magic;
	public long serverId;
	public Address serverAddress;
	public short mtuLength;
	public boolean security;

	@Override
	public int length() {
		return magic.length() + serverAddress.length() + 13;
	}

	@Override
	public byte[] encode() {
	}

	@Override
	public void decode(byte[] buffer) {
	}

}
