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
 * Logs a message from the server's console. It may be a result of a command, a debug
 * message or any other message that the server retains able to be seen by the External
 * Console.
 */
class ConsoleMessage extends Packet {

	public final static byte ID = (byte)3;

	public final static boolean CLIENTBOUND = true;
	public final static boolean SERVERBOUND = false;

	/**
	 * Name of the node that has created the log or an empty string if the log has been
	 * created by the hub or by a server implementation that isn't based on the hub-node
	 * structure.
	 */
	public String node;

	/**
	 * Unix timestamp in milliseconds that indicates the exact time when the log has been
	 * generated by the server.
	 */
	public long timestamp;

	/**
	 * Name of the logger. It is the world name if the log has been generated by a world's
	 * message (like a broadcast or a chat message).
	 */
	public String logger;

	/**
	 * The logged message. It may contain Minecraft's formatting codes which should be
	 * translated into appropriate colours by the client-side implementation.
	 */
	public String message;

	@Override
	public byte[] encode() {
	}

	@Override
	public void decode(byte[] buffer) {
	}

}
