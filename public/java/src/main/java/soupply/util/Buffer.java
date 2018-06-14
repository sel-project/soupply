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
package soupply.util;

import java.nio.ByteBuffer;

class Buffer {

	public byte[] _buffer;

	public int _index;
	
	public Buffer() {}
	
	public Buffer(byte[] buffer)
	{
		_buffer = buffer;
	}
	
	private void requireLength(int required) {
		if(_index + required > _buffer.length)
		{
			_buffer = Arrays.copyOf(_buffer, _buffer + 64);
		}
	}
	
	private void checkLength(int required) throws IOException {
		
	}

	public byte[] toByteArray()
	{
		return Arrays.copyOfRange(_buffer, 0, _index);
	}

	public void writeBytes(byte[] a)
	{
		for(byte b : a) _buffer[_index++] = b;
	}

	public byte[] readBytes(int a)
	{
		byte[] _ret = new byte[a];
		for(int i=0; i<a && _index<_buffer.length; i++) _ret[i] = _buffer[_index++];
		return _ret;
	}

	public void writeBool(boolean a)
	{
		_buffer[_index++] = (byte)(a ? 1 : 0);
	}

	public boolean readBool() {
		return _index < _buffer.length && _buffer[_index++] != 0;
	}

	public void writeBigEndianByte(byte a)
	{
		_buffer[_index++] = (byte)a;
	}

	public byte readBigEndianByte()
	{
		if(_buffer.length < _index + 1) return (byte)0;
		return (byte)_buffer[_index++];
	}

	public void writeLittleEndianByte(byte a)
	{
		_buffer[_index++] = (byte)a;
	}

	public byte readLittleEndianByte()
	{
		if(_buffer.length < _index + 1) return (byte)0;
		return (byte)_buffer[_index++];
	}

	public void writeBigEndianShort(short a)
	{
		_buffer[_index++] = (byte)(a >>> 8);
		_buffer[_index++] = (byte)(a);
	}

	public short readBigEndianShort()
	{
		if(_buffer.length < _index + 2) return (short)0;
		short _ret = 0;
		_ret |= (short)_buffer[_index++] << 8;
		_ret |= (short)_buffer[_index++];
		return _ret;
	}

	public void writeLittleEndianShort(short a)
	{
		_buffer[_index++] = (byte)(a);
		_buffer[_index++] = (byte)(a >>> 8);
	}

	public short readLittleEndianShort()
	{
		if(_buffer.length < _index + 2) return (short)0;
		short _ret = 0;
		_ret |= (short)_buffer[_index++];
		_ret |= (short)_buffer[_index++] << 8;
		return _ret;
	}

	public void writeBigEndianInt(int a)
	{
		_buffer[_index++] = (byte)(a >>> 24);
		_buffer[_index++] = (byte)(a >>> 16);
		_buffer[_index++] = (byte)(a >>> 8);
		_buffer[_index++] = (byte)(a);
	}

	public int readBigEndianInt()
	{
		if(_buffer.length < _index + 4) return (int)0;
		int _ret = 0;
		_ret |= (int)_buffer[_index++] << 24;
		_ret |= (int)_buffer[_index++] << 16;
		_ret |= (int)_buffer[_index++] << 8;
		_ret |= (int)_buffer[_index++];
		return _ret;
	}

	public void writeLittleEndianInt(int a)
	{
		_buffer[_index++] = (byte)(a);
		_buffer[_index++] = (byte)(a >>> 8);
		_buffer[_index++] = (byte)(a >>> 16);
		_buffer[_index++] = (byte)(a >>> 24);
	}

	public int readLittleEndianInt()
	{
		if(_buffer.length < _index + 4) return (int)0;
		int _ret = 0;
		_ret |= (int)_buffer[_index++];
		_ret |= (int)_buffer[_index++] << 8;
		_ret |= (int)_buffer[_index++] << 16;
		_ret |= (int)_buffer[_index++] << 24;
		return _ret;
	}

	public void writeBigEndianLong(long a)
	{
		_buffer[_index++] = (byte)(a >>> 56);
		_buffer[_index++] = (byte)(a >>> 48);
		_buffer[_index++] = (byte)(a >>> 40);
		_buffer[_index++] = (byte)(a >>> 32);
		_buffer[_index++] = (byte)(a >>> 24);
		_buffer[_index++] = (byte)(a >>> 16);
		_buffer[_index++] = (byte)(a >>> 8);
		_buffer[_index++] = (byte)(a);
	}

	public long readBigEndianLong()
	{
		if(_buffer.length < _index + 8) return (long)0;
		long _ret = 0;
		_ret |= (long)_buffer[_index++] << 56;
		_ret |= (long)_buffer[_index++] << 48;
		_ret |= (long)_buffer[_index++] << 40;
		_ret |= (long)_buffer[_index++] << 32;
		_ret |= (long)_buffer[_index++] << 24;
		_ret |= (long)_buffer[_index++] << 16;
		_ret |= (long)_buffer[_index++] << 8;
		_ret |= (long)_buffer[_index++];
		return _ret;
	}

	public void writeLittleEndianLong(long a)
	{
		_buffer[_index++] = (byte)(a);
		_buffer[_index++] = (byte)(a >>> 8);
		_buffer[_index++] = (byte)(a >>> 16);
		_buffer[_index++] = (byte)(a >>> 24);
		_buffer[_index++] = (byte)(a >>> 32);
		_buffer[_index++] = (byte)(a >>> 40);
		_buffer[_index++] = (byte)(a >>> 48);
		_buffer[_index++] = (byte)(a >>> 56);
	}

	public long readLittleEndianLong()
	{
		if(_buffer.length < _index + 8) return (long)0;
		long _ret = 0;
		_ret |= (long)_buffer[_index++];
		_ret |= (long)_buffer[_index++] << 8;
		_ret |= (long)_buffer[_index++] << 16;
		_ret |= (long)_buffer[_index++] << 24;
		_ret |= (long)_buffer[_index++] << 32;
		_ret |= (long)_buffer[_index++] << 40;
		_ret |= (long)_buffer[_index++] << 48;
		_ret |= (long)_buffer[_index++] << 56;
		return _ret;
	}

	public void writeBigEndianFloat(float a)
	{
		this.writeBigEndianInt(Float.floatToIntBits(a));
	}

	public float readBigEndianFloat()
	{
		return Float.intBitsToFloat(this.readBigEndianInt());
	}

	public void writeLittleEndianFloat(float a)
	{
		this.writeLittleEndianInt(Float.floatToIntBits(a));
	}

	public float readLittleEndianFloat()
	{
		return Float.intBitsToFloat(this.readLittleEndianInt());
	}

	public void writeBigEndianDouble(double a)
	{
		this.writeBigEndianLong(Double.doubleToLongBits(a));
	}

	public double readBigEndianDouble()
	{
		return Double.longBitsToDouble(this.readBigEndianLong());
	}

	public void writeLittleEndianDouble(double a)
	{
		this.writeLittleEndianLong(Double.doubleToLongBits(a));
	}

	public double readLittleEndianDouble()
	{
		return Double.longBitsToDouble(this.readLittleEndianLong());
	}

	public void writeVarshort(long a)
	{
		this.writeVarushort(a >= 0 ? a * 2  : a * -2 - 1);
	}

	public short readVarshort()
	{
		short ret = this.readVarushort();
		return (short)((ret & 1) == 0 ? ret / 2 : (-ret - 1) / 2);
	}

	public static int varshortLength(short a)
	{
		int length = 1;
		while((a & 128) != 0 && length < 3)
	{
			length++;
			a >>>= 7;
		}
		return length;
	}

	public void writeVarushort(long a)
	{
		while(a > 127)
	{
			_buffer[_index++] = (byte)(a & 127 | 128);
			a >>>= 7;
		}
		_buffer[_index++] = (byte)(a & 255);
	}

	public short readVarushort()
	{
		int limit = 0;
		short ret = 0;
		do {
			ret |= (short)(_buffer[_index] & 127) << (limit * 7);
		} while(_buffer[_index++] < 0 && ++limit < 3 && _index < _buffer.length);
		return ret;
	}

	public static int varushortLength(short a)
	{
		int length = 1;
		while((a & 128) != 0 && length < 3)
	{
			length++;
			a >>>= 7;
		}
		return length;
	}

	public void writeVarint(long a)
	{
		this.writeVaruint(a >= 0 ? a * 2  : a * -2 - 1);
	}

	public int readVarint()
	{
		int ret = this.readVaruint();
		return (int)((ret & 1) == 0 ? ret / 2 : (-ret - 1) / 2);
	}

	public static int varintLength(int a)
	{
		int length = 1;
		while((a & 128) != 0 && length < 5)
	{
			length++;
			a >>>= 7;
		}
		return length;
	}

	public void writeVaruint(long a)
	{
		while(a > 127)
	{
			_buffer[_index++] = (byte)(a & 127 | 128);
			a >>>= 7;
		}
		_buffer[_index++] = (byte)(a & 255);
	}

	public int readVaruint()
	{
		int limit = 0;
		int ret = 0;
		do {
			ret |= (int)(_buffer[_index] & 127) << (limit * 7);
		} while(_buffer[_index++] < 0 && ++limit < 5 && _index < _buffer.length);
		return ret;
	}

	public static int varuintLength(int a)
	{
		int length = 1;
		while((a & 128) != 0 && length < 5)
	{
			length++;
			a >>>= 7;
		}
		return length;
	}

	public void writeVarlong(long a)
	{
		this.writeVarulong(a >= 0 ? a * 2  : a * -2 - 1);
	}

	public long readVarlong()
	{
		long ret = this.readVarulong();
		return (long)((ret & 1) == 0 ? ret / 2 : (-ret - 1) / 2);
	}

	public static int varlongLength(long a)
	{
		int length = 1;
		while((a & 128) != 0 && length < 10)
	{
			length++;
			a >>>= 7;
		}
		return length;
	}

	public void writeVarulong(long a)
	{
		while(a > 127)
	{
			_buffer[_index++] = (byte)(a & 127 | 128);
			a >>>= 7;
		}
		_buffer[_index++] = (byte)(a & 255);
	}

	public long readVarulong()
	{
		int limit = 0;
		long ret = 0;
		do {
			ret |= (long)(_buffer[_index] & 127) << (limit * 7);
		} while(_buffer[_index++] < 0 && ++limit < 10 && _index < _buffer.length);
		return ret;
	}

	public static int varulongLength(long a)
	{
		int length = 1;
		while((a & 128) != 0 && length < 10)
	{
			length++;
			a >>>= 7;
		}
		return length;
	}

	public boolean eof()
	{
		return _index >= _buffer.length;
	}

}
