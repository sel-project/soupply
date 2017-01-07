/*
 * This file has been automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generator: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/pocket100.xml
 */
package sul.protocol.pocket100.play;

import java.util.UUID;

import sul.protocol.pocket100.types.*;
import sul.utils.*;

class Login extends Packet {

	public final static byte ID = (byte)1;

	public final static boolean CLIENTBOUND = false;
	public final static boolean SERVERBOUND = true;

	// edition
	public final static byte CLASSIC = (byte)0;
	public final static byte EDUCATION = (byte)1;

	public int protocol;
	public byte edition;
	public byte[] body;

	@Override
	public int length() {
		return Var.Uint.length(body.length) + body.length() + 5;
	}

	@Override
	public byte[] encode() {
	}

	@Override
	public void decode(byte[] buffer) {
	}

}
