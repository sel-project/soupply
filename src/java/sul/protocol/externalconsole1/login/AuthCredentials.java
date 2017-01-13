/*
 * This file has been automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generator: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/externalconsole1.xml
 */
package sul.protocol.externalconsole1.login;

import java.util.UUID;

import sul.protocol.externalconsole1.types.*;
import sul.utils.*;

/**
 * First packet sent by the server after the connection has been successfully established.
 * It contains informations about how the client should authenticate.
 */
class AuthCredentials extends Packet {

	public final static byte ID = (byte)0;

	public final static boolean CLIENTBOUND = true;
	public final static boolean SERVERBOUND = false;

	/**
	 * Protocol used by the server. If the client uses a different one it should close
	 * the connection without trying to perform authentication.
	 */
	public byte protocol;

	/**
	 * Whether to perform hashing on the password.
	 */
	public boolean hash;

	/**
	 * Algorithm used by the server to hash the concatenation of password and payload.
	 * The value should be sent in lowercase without any separation symbol (for example
	 * `md5` instead of `MD5`, `sha256` instead of `SHA-256`).
	 * See Auth.hash for more details.
	 */
	public String hashAlgorithm;

	/**
	 * Payload to cancatenate with the password encoded as UTF-8 before hashing it, as
	 * described in the Auth.hash's field description.
	 */
	public byte[16] payload;

	@Override
	public int length() {
	}

	@Override
	public byte[] encode() {
		this.buffer = new byte[this.length()];
		this.index = 0;
		this.writeByteB(ID);
		this.writeByteB(protocol);
		this.writeBoolB(hash);
		if(hash==true){ byte[] agfzaefsz29yaxro=hashAlgorithm.getBytes("UTF-8"); this.writeShortB((short)agfzaefsz29yaxro.length); this.writeBytes(agfzaefsz29yaxro); }
		if(hash==true){ for(ubyte cgf5bg9hza:payload){ this.writeByteB(cgf5bg9hza); } }
		return this.buffer;
	}

	@Override
	public void decode(byte[] buffer) {
		this.buffer = buffer;
		this.index = 0;
	}

}
