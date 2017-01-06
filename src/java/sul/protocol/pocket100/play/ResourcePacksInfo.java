/*
 * This file has been automatically generated by sel-utils and
 * it's released under the GNU General Public License version 3.
 *
 * Repository: https://github.com/sel-project/sel-utils
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * From: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/pocket100.xml
 */
package sul.protocol.pocket100.play;

import java.util.UUID;

import sul.protocol.pocket100.types.*;
import sul.utils.Packet;

class ResourcePacksInfo extends Packet {

	public final static byte ID = (byte)7;

	public final static boolean CLIENTBOUND = true;
	public final static boolean SERVERBOUND = false;

	public boolean mustAccept;
	public Pack[] behaviourPacks;
	public Pack[] resourcePacks;

	@Override
	public byte[] encode() {
	}

	@Override
	public void decode(byte[] buffer) {
	}

}
