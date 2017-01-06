/*
 * This file has been automatically generated by sel-utils and
 * it's released under the GNU General Public License version 3.
 *
 * Repository: https://github.com/sel-project/sel-utils
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * From: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/externalconsole1.xml
 */
package sul.protocol.externalconsole1.play;

import java.util.UUID;

import sul.protocol.externalconsole1.types.*;
import sul.utils.Packet;

/**
 * Bodyless packet only sent in response to [Command](#command) when the server doesn't
 * allow the execution of remote commands through the External Console protocol. The
 * ideal client should never receive this packet avoiding the use of [Command](#command)
 * if the remoteCommands field in [Welcome.Accepted](#accepted) is not true.
 */
class PermissionDenied extends Packet {

	public final static byte ID = (byte)5;

	public final static boolean CLIENTBOUND = true;
	public final static boolean SERVERBOUND = false;


	@Override
	public byte[] encode() {
	}

	@Override
	public void decode(byte[] buffer) {
	}

}
