/*
 * This file was automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generated from https://github.com/sel-project/sel-utils/blob/master/xml/protocol/hncom1.xml
 */
package sul.protocol.hncom1.status;

import java.nio.charset.StandardCharsets;

import sul.utils.*;

public class AddNode extends Packet {

	public static final byte ID = (byte)5;

	public static final boolean CLIENTBOUND = true;
	public static final boolean SERVERBOUND = false;

	public int hubId;
	public String name;
	public boolean main;
	public sul.protocol.hncom1.types.Game[] acceptedGames;

	public AddNode() {}

	public AddNode(int hubId, String name, boolean main, sul.protocol.hncom1.types.Game[] acceptedGames) {
		this.hubId = hubId;
		this.name = name;
		this.main = main;
		this.acceptedGames = acceptedGames;
	}

	@Override
	public int length() {
		int length=Buffer.varuintLength(hubId) + Buffer.varuintLength(name.getBytes(StandardCharsets.UTF_8).length) + name.getBytes(StandardCharsets.UTF_8).length + Buffer.varuintLength(acceptedGames.length) + 2; for(sul.protocol.hncom1.types.Game ywnjzxb0zwrhyw1l:acceptedGames){ length+=ywnjzxb0zwrhyw1l.length(); } return length;
	}

	@Override
	public byte[] encode() {
		this._buffer = new byte[this.length()];
		this.writeBigEndianByte(ID);
		this.writeVaruint(hubId);
		byte[] bmftzq=name.getBytes(StandardCharsets.UTF_8); this.writeVaruint((int)bmftzq.length); this.writeBytes(bmftzq);
		this.writeBool(main);
		this.writeVaruint((int)acceptedGames.length); for(sul.protocol.hncom1.types.Game ywnjzxb0zwrhyw1l:acceptedGames){ this.writeBytes(ywnjzxb0zwrhyw1l.encode()); }
		return this.getBuffer();
	}

	@Override
	public void decode(byte[] buffer) {
		this._buffer = buffer;
		readBigEndianByte();
		hubId=this.readVaruint();
		int bgvubmftzq=this.readVaruint(); name=new String(this.readBytes(bgvubmftzq), StandardCharsets.UTF_8);
		main=this.readBool();
		int bgfjy2vwdgvkr2ft=this.readVaruint(); acceptedGames=new sul.protocol.hncom1.types.Game[bgfjy2vwdgvkr2ft]; for(int ywnjzxb0zwrhyw1l=0;ywnjzxb0zwrhyw1l<acceptedGames.length;ywnjzxb0zwrhyw1l++){ acceptedGames[ywnjzxb0zwrhyw1l]=new sul.protocol.hncom1.types.Game(); acceptedGames[ywnjzxb0zwrhyw1l]._index=this._index; acceptedGames[ywnjzxb0zwrhyw1l].decode(this._buffer); this._index=acceptedGames[ywnjzxb0zwrhyw1l]._index; }
	}

	public static AddNode fromBuffer(byte[] buffer) {
		AddNode ret = new AddNode();
		ret.decode(buffer);
		return ret;
	}

}