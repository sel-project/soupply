/*
 * This file was automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generated from https://github.com/sel-project/sel-utils/blob/master/xml/protocol/pocket101.xml
 */
package sul.protocol.pocket101.play;

import sul.utils.*;

public class CraftingData extends Packet {

	public static final byte ID = (byte)53;

	public static final boolean CLIENTBOUND = true;
	public static final boolean SERVERBOUND = false;

	public sul.protocol.pocket101.types.Recipe[] recipes;

	public CraftingData() {}

	public CraftingData(sul.protocol.pocket101.types.Recipe[] recipes) {
		this.recipes = recipes;
	}

	@Override
	public int length() {
		int length=Buffer.varuintLength(recipes.length) + 1; for(sul.protocol.pocket101.types.Recipe cmvjaxblcw:recipes){ length+=cmvjaxblcw.length(); } return length;
	}

	@Override
	public byte[] encode() {
		this._buffer = new byte[this.length()];
		this.writeBigEndianByte(ID);
		this.writeVaruint((int)recipes.length); for(sul.protocol.pocket101.types.Recipe cmvjaxblcw:recipes){ this.writeBytes(cmvjaxblcw.encode()); }
		return this.getBuffer();
	}

	@Override
	public void decode(byte[] buffer) {
		this._buffer = buffer;
		readBigEndianByte();
		int bhjly2lwzxm=this.readVaruint(); recipes=new sul.protocol.pocket101.types.Recipe[bhjly2lwzxm]; for(int cmvjaxblcw=0;cmvjaxblcw<recipes.length;cmvjaxblcw++){ recipes[cmvjaxblcw]=new sul.protocol.pocket101.types.Recipe(); recipes[cmvjaxblcw]._index=this._index; recipes[cmvjaxblcw].decode(this._buffer); this._index=recipes[cmvjaxblcw]._index; }
	}

	public static CraftingData fromBuffer(byte[] buffer) {
		CraftingData ret = new CraftingData();
		ret.decode(buffer);
		return ret;
	}

}
