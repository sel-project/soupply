/*
 * This file has been automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generator: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/minecraft107.xml
 */
package sul.protocol.minecraft107.login;

import java.util.UUID;

import sul.protocol.minecraft107.types.*;
import sul.utils.*;

class EncryptionResponse extends Packet {

	public final static int ID = (int)1;

	public final static boolean CLIENTBOUND = false;
	public final static boolean SERVERBOUND = true;

	public byte[] sharedSecret;
	public byte[] verifyToken;

	@Override
	public int length() {
	}

	@Override
	public byte[] encode() {
		this.buffer = new byte[this.length()];
		this.index = 0;
		this.writeVaruint(ID);
		this.writeVaruint((int)sharedSecret.length); for(ubyte c2hhcmvku2vjcmv0:sharedSecret){ this.writeByteB(c2hhcmvku2vjcmv0); }
		this.writeVaruint((int)verifyToken.length); for(ubyte dmvyawz5vg9rzw4:verifyToken){ this.writeByteB(dmvyawz5vg9rzw4); }
		return this.buffer;
	}

	@Override
	public void decode(byte[] buffer) {
		this.buffer = buffer;
		this.index = 0;
	}

}