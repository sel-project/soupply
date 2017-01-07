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

class AddEntity extends Packet {

	public final static byte ID = (byte)14;

	public final static boolean CLIENTBOUND = true;
	public final static boolean SERVERBOUND = false;

	public long entityId;
	public long runtimeId;
	public int type;
	public Tuples.FloatXYZ position;
	public Tuples.FloatXYZ motion;
	public float pitch;
	public float yaw;
	public Attribute[] attributes;
	public byte[] metadata;
	public long[] links;

	@Override
	public int length() {
		return Var.Long.length(entityId) + Var.Long.length(runtimeId) + Var.Uint.length(type) + position.length() + motion.length() + Var.Uint.length(attributes.length) + attributes.length() + Var.Uint.length(metadata.length) + metadata.length() + Var.Uint.length(links.length) + links.length() + 8;
	}

	@Override
	public byte[] encode() {
	}

	@Override
	public void decode(byte[] buffer) {
	}

}
