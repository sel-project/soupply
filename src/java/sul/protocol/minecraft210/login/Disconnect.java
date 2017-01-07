/*
 * This file has been automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generator: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/minecraft210.xml
 */
package sul.protocol.minecraft210.login;

import java.util.UUID;

import sul.protocol.minecraft210.types.*;
import sul.utils.*;

class Disconnect extends Packet {

	public final static int ID = (int)0;

	public final static boolean CLIENTBOUND = true;
	public final static boolean SERVERBOUND = false;

	public String reason;

	@Override
	public int length() {
		return Var.Uint.length(reason.getBytes(StandardCharset.UTF_8).length) + reason.getBytes(StandardCharset.UTF_8).length;
	}

	@Override
	public byte[] encode() {
	}

	@Override
	public void decode(byte[] buffer) {
	}

}
