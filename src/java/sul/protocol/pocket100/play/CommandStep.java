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

class CommandStep extends Packet {

	public final static byte ID = (byte)78;

	public final static boolean CLIENTBOUND = false;
	public final static boolean SERVERBOUND = true;

	public String command;
	public String overload;
	public int ?;
	public int ?;
	public boolean isOutput;
	public long ?;
	public String input;
	public String output;

	@Override
	public int length() {
		return Var.Uint.length(command.getBytes(StandardCharset.UTF_8).length) + command.getBytes(StandardCharset.UTF_8).length + Var.Uint.length(overload.getBytes(StandardCharset.UTF_8).length) + overload.getBytes(StandardCharset.UTF_8).length + Var.Uint.length(?) + Var.Uint.length(?) + Var.Ulong.length(?) + Var.Uint.length(input.getBytes(StandardCharset.UTF_8).length) + input.getBytes(StandardCharset.UTF_8).length + Var.Uint.length(output.getBytes(StandardCharset.UTF_8).length) + output.getBytes(StandardCharset.UTF_8).length + 1;
	}

	@Override
	public byte[] encode() {
	}

	@Override
	public void decode(byte[] buffer) {
	}

}
