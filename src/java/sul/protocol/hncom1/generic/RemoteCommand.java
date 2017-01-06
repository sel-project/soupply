/*
 * This file has been automatically generated by sel-utils and
 * it's released under the GNU General Public License version 3.
 *
 * Repository: https://github.com/sel-project/sel-utils
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * From: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/hncom1.xml
 */
package sul.protocol.hncom1.generic;

import java.util.UUID;

import sul.protocol.hncom1.types.*;
import sul.utils.Packet;

class RemoteCommand extends Packet {

	public final static byte ID = (byte)8;

	public final static boolean CLIENTBOUND = true;
	public final static boolean SERVERBOUND = false;

	// origin
	public final static byte HUB = (byte)0;
	public final static byte EXTERNAL_CONSOLE = (byte)1;
	public final static byte RCON = (byte)2;

	public byte origin;
	public Address sender;
	public String command;

	@Override
	public byte[] encode() {
	}

	@Override
	public void decode(byte[] buffer) {
	}

}
