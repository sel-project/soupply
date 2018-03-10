/*
 * Copyright (c) 2016-2018 sel-project
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */
class Buffer {

	constructor() {
		this._buffer = [];
	}

	writeBytes(a) {
		for(var i in a) {
			this._buffer.push(a[i]);
		}
	}

	readBytes(a) {
		var ret = this._buffer.slice(0, a);
		this._buffer = this._buffer.slice(a, this._buffer.length);
		while(ret.length < a) ret.push(0)
		return ret;
	}
	
	writeBool(a) {
		this._buffer.push(a ? 1 : 0);
	}
	
	readByte() {
		return this._buffer.shift() != 0;
	}

	writeByte(a) {
		this._buffer.push(a);
	}

	readByte(a) {
		return this._buffer.shift();
	}

	writeBigEndianShort(a) {
		this._buffer.push((a >>> 8) & 255);
		this._buffer.push((a) & 255);
	}

	readBigEndianShort(a) {
		var _ret = 0;
		_ret |= this._buffer.shift() << 8;
		_ret |= this._buffer.shift();
		return _ret;
	}

	writeLittleEndianShort(a) {
		this._buffer.push((a) & 255);
		this._buffer.push((a >>> 8) & 255);
	}

	readLittleEndianShort(a) {
		var _ret = 0;
		_ret |= this._buffer.shift();
		_ret |= this._buffer.shift() << 8;
		return _ret;
	}

	writeBigEndianInt(a) {
		this._buffer.push((a >>> 24) & 255);
		this._buffer.push((a >>> 16) & 255);
		this._buffer.push((a >>> 8) & 255);
		this._buffer.push((a) & 255);
	}

	readBigEndianInt(a) {
		var _ret = 0;
		_ret |= this._buffer.shift() << 24;
		_ret |= this._buffer.shift() << 16;
		_ret |= this._buffer.shift() << 8;
		_ret |= this._buffer.shift();
		return _ret;
	}

	writeLittleEndianInt(a) {
		this._buffer.push((a) & 255);
		this._buffer.push((a >>> 8) & 255);
		this._buffer.push((a >>> 16) & 255);
		this._buffer.push((a >>> 24) & 255);
	}

	readLittleEndianInt(a) {
		var _ret = 0;
		_ret |= this._buffer.shift();
		_ret |= this._buffer.shift() << 8;
		_ret |= this._buffer.shift() << 16;
		_ret |= this._buffer.shift() << 24;
		return _ret;
	}

	writeBigEndianLong(a) {
		this._buffer.push((a >>> 56) & 255);
		this._buffer.push((a >>> 48) & 255);
		this._buffer.push((a >>> 40) & 255);
		this._buffer.push((a >>> 32) & 255);
		this._buffer.push((a >>> 24) & 255);
		this._buffer.push((a >>> 16) & 255);
		this._buffer.push((a >>> 8) & 255);
		this._buffer.push((a) & 255);
	}

	readBigEndianLong(a) {
		var _ret = 0;
		_ret |= this._buffer.shift() << 56;
		_ret |= this._buffer.shift() << 48;
		_ret |= this._buffer.shift() << 40;
		_ret |= this._buffer.shift() << 32;
		_ret |= this._buffer.shift() << 24;
		_ret |= this._buffer.shift() << 16;
		_ret |= this._buffer.shift() << 8;
		_ret |= this._buffer.shift();
		return _ret;
	}

	writeLittleEndianLong(a) {
		this._buffer.push((a) & 255);
		this._buffer.push((a >>> 8) & 255);
		this._buffer.push((a >>> 16) & 255);
		this._buffer.push((a >>> 24) & 255);
		this._buffer.push((a >>> 32) & 255);
		this._buffer.push((a >>> 40) & 255);
		this._buffer.push((a >>> 48) & 255);
		this._buffer.push((a >>> 56) & 255);
	}

	readLittleEndianLong(a) {
		var _ret = 0;
		_ret |= this._buffer.shift();
		_ret |= this._buffer.shift() << 8;
		_ret |= this._buffer.shift() << 16;
		_ret |= this._buffer.shift() << 24;
		_ret |= this._buffer.shift() << 32;
		_ret |= this._buffer.shift() << 40;
		_ret |= this._buffer.shift() << 48;
		_ret |= this._buffer.shift() << 56;
		return _ret;
	}

	writeBigEndianFloat(a) {
		this.writeBytes(new Uint8Array(new Float32Array([a]).buffer));
	}

	readBigEndianFloat() {
		return new Float32Array(new Uint8Array(this.readBytes(4)).buffer, 0, 1)[0];
	}

	writeLittleEndianFloat(a) {
		this.writeBytes(new Uint8Array(new Float32Array([a]).buffer));
	}

	readLittleEndianFloat() {
		return new Float32Array(new Uint8Array(this.readBytes(4)).buffer, 0, 1)[0];
	}

	writeBigEndianDouble(a) {
		this.writeBytes(new Uint8Array(new Float64Array([a]).buffer));
	}

	readBigEndianDouble() {
		return new Float64Array(new Uint8Array(this.readBytes(8)).buffer, 0, 1)[0];
	}

	writeLittleEndianDouble(a) {
		this.writeBytes(new Uint8Array(new Float64Array([a]).buffer));
	}

	readLittleEndianDouble() {
		return new Float64Array(new Uint8Array(this.readBytes(8)).buffer, 0, 1)[0];
	}

	writeVarshort(a) {
		this.writeVarushort(a >= 0 ? a * 2 : a * -2 - 1);
	}

	readVarshort() {
		var ret = this.readVarushort();
		return (ret & 1) == 0 ? ret / 2 : (-ret - 1) / 2;
	}

	writeVarushort(a) {
		while(a > 127) {
			this._buffer.push(a & 127 | 128);
			a >>>= 7;
		}
		this._buffer.push(a & 255);
	}

	readVarushort() {
		var limit = 0;
		var ret = 0;
		do {
			ret |= (this._buffer[0] & 127) << (limit * 7);
		} while(this._buffer.shift() > 127 && ++limit < 3);
		return ret;
	}

	writeVarint(a) {
		this.writeVaruint(a >= 0 ? a * 2 : a * -2 - 1);
	}

	readVarint() {
		var ret = this.readVaruint();
		return (ret & 1) == 0 ? ret / 2 : (-ret - 1) / 2;
	}

	writeVaruint(a) {
		while(a > 127) {
			this._buffer.push(a & 127 | 128);
			a >>>= 7;
		}
		this._buffer.push(a & 255);
	}

	readVaruint() {
		var limit = 0;
		var ret = 0;
		do {
			ret |= (this._buffer[0] & 127) << (limit * 7);
		} while(this._buffer.shift() > 127 && ++limit < 5);
		return ret;
	}

	writeVarlong(a) {
		this.writeVarulong(a >= 0 ? a * 2 : a * -2 - 1);
	}

	readVarlong() {
		var ret = this.readVarulong();
		return (ret & 1) == 0 ? ret / 2 : (-ret - 1) / 2;
	}

	writeVarulong(a) {
		while(a > 127) {
			this._buffer.push(a & 127 | 128);
			a >>>= 7;
		}
		this._buffer.push(a & 255);
	}

	readVarulong() {
		var limit = 0;
		var ret = 0;
		do {
			ret |= (this._buffer[0] & 127) << (limit * 7);
		} while(this._buffer.shift() > 127 && ++limit < 10);
		return ret;
	}

	encodeString(string) {
		var conv = unescape(encodeURIComponent(string));
		var ret = [];
		for(var i in conv) ret.push(conv.charCodeAt(i));
		return ret;
	}

	decodeString(array) {
		return decodeURIComponent(escape(String.fromCharCode.apply(null, array)));
	}

}
