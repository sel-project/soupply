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

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.UUID;

public class Buffer {

	public byte[] _buffer;
	public int _index;
	
	public Buffer() {}
	
	public Buffer(byte[] buffer)
	{
		_buffer = buffer;
	}
	
	private void requireLength(int required)
	{
		if(_index + required > _buffer.length) _buffer = Arrays.copyOf(_buffer, _buffer.length + 64);
	}
	
	private void checkLength(int required) throws BufferOverflowException
	{
		if(_index + required > _buffer.length) throw new BufferOverflowException(_index + required, _buffer.length);
	}

	public byte[] toByteArray()
	{
		return Arrays.copyOfRange(_buffer, 0, _index);
	}

	public void writeBytes(byte[] a)
	{
		this.requireLength(a.length);
		for(byte b : a) _buffer[_index++] = b;
	}

	public byte[] readBytes(int a) throws BufferOverflowException
	{
		this.checkLength(a);
		_index += a;
		return Arrays.copyOfRange(_buffer, _index - a, _index);
	}
	
	public byte[] convertString(String string)
	{
		return string.getBytes(StandardCharsets.UTF_8);
	}
	
	public String readString(int length) throws BufferOverflowException
	{
		return new String(this.readBytes(length), StandardCharsets.UTF_8);
	}

	public void writeBool(boolean a)
	{
		this.requireLength(1);
		_buffer[_index++] = (byte)(a ? 1 : 0);
	}

	public boolean readBool() throws BufferOverflowException
	{
		return this.readByte() != 0;
	}

	public void writeByte(byte a)
	{
		this.requireLength(1);
		_buffer[_index++] = (byte)a;
	}

	public byte readByte() throws BufferOverflowException
	{
		this.checkLength(1);
		return (byte)_buffer[_index++];
	}

	public void writeBigEndianShort(short a)
	{
		this.requireLength(2);
		_buffer[_index++] = (byte)(a >>> 8);
		_buffer[_index++] = (byte)(a);
	}

	public short readBigEndianShort() throws BufferOverflowException
	{
		this.checkLength(2);
		short _ret = 0;
		_ret |= (short)_buffer[_index++] << 8;
		_ret |= (short)_buffer[_index++];
		return _ret;
	}

	public void writeLittleEndianShort(short a)
	{
		this.requireLength(2);
		_buffer[_index++] = (byte)(a);
		_buffer[_index++] = (byte)(a >>> 8);
	}

	public short readLittleEndianShort() throws BufferOverflowException
	{
		this.checkLength(2);
		short _ret = 0;
		_ret |= (short)_buffer[_index++];
		_ret |= (short)_buffer[_index++] << 8;
		return _ret;
	}

	public void writeBigEndianInt(int a)
	{
		this.requireLength(4);
		_buffer[_index++] = (byte)(a >>> 24);
		_buffer[_index++] = (byte)(a >>> 16);
		_buffer[_index++] = (byte)(a >>> 8);
		_buffer[_index++] = (byte)(a);
	}

	public int readBigEndianInt() throws BufferOverflowException
	{
		this.checkLength(4);
		int _ret = 0;
		_ret |= (int)_buffer[_index++] << 24;
		_ret |= (int)_buffer[_index++] << 16;
		_ret |= (int)_buffer[_index++] << 8;
		_ret |= (int)_buffer[_index++];
		return _ret;
	}

	public void writeLittleEndianInt(int a)
	{
		this.requireLength(4);
		_buffer[_index++] = (byte)(a);
		_buffer[_index++] = (byte)(a >>> 8);
		_buffer[_index++] = (byte)(a >>> 16);
		_buffer[_index++] = (byte)(a >>> 24);
	}

	public int readLittleEndianInt() throws BufferOverflowException
	{
		this.checkLength(4);
		int _ret = 0;
		_ret |= (int)_buffer[_index++];
		_ret |= (int)_buffer[_index++] << 8;
		_ret |= (int)_buffer[_index++] << 16;
		_ret |= (int)_buffer[_index++] << 24;
		return _ret;
	}

	public void writeBigEndianLong(long a)
	{
		this.requireLength(8);
		_buffer[_index++] = (byte)(a >>> 56);
		_buffer[_index++] = (byte)(a >>> 48);
		_buffer[_index++] = (byte)(a >>> 40);
		_buffer[_index++] = (byte)(a >>> 32);
		_buffer[_index++] = (byte)(a >>> 24);
		_buffer[_index++] = (byte)(a >>> 16);
		_buffer[_index++] = (byte)(a >>> 8);
		_buffer[_index++] = (byte)(a);
	}

	public long readBigEndianLong() throws BufferOverflowException
	{
		this.checkLength(8);
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
		this.requireLength(8);
		_buffer[_index++] = (byte)(a);
		_buffer[_index++] = (byte)(a >>> 8);
		_buffer[_index++] = (byte)(a >>> 16);
		_buffer[_index++] = (byte)(a >>> 24);
		_buffer[_index++] = (byte)(a >>> 32);
		_buffer[_index++] = (byte)(a >>> 40);
		_buffer[_index++] = (byte)(a >>> 48);
		_buffer[_index++] = (byte)(a >>> 56);
	}

	public long readLittleEndianLong() throws BufferOverflowException
	{
		this.checkLength(8);
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

	public float readBigEndianFloat() throws BufferOverflowException
	{
		return Float.intBitsToFloat(this.readBigEndianInt());
	}

	public void writeLittleEndianFloat(float a)
	{
		this.writeLittleEndianInt(Float.floatToIntBits(a));
	}

	public float readLittleEndianFloat() throws BufferOverflowException
	{
		return Float.intBitsToFloat(this.readLittleEndianInt());
	}

	public void writeBigEndianDouble(double a)
	{
		this.writeBigEndianLong(Double.doubleToLongBits(a));
	}

	public double readBigEndianDouble() throws BufferOverflowException
	{
		return Double.longBitsToDouble(this.readBigEndianLong());
	}

	public void writeLittleEndianDouble(double a)
	{
		this.writeLittleEndianLong(Double.doubleToLongBits(a));
	}

	public double readLittleEndianDouble() throws BufferOverflowException
	{
		return Double.longBitsToDouble(this.readLittleEndianLong());
	}

	public void writeVarshort(long a)
	{
		this.writeVarushort(a >= 0 ? a * 2  : a * -2 - 1);
	}

	public short readVarshort() throws BufferOverflowException
	{
		short ret = this.readVarushort();
		return (short)((ret & 1) == 0 ? ret / 2 : (-ret - 1) / 2);
	}

	public void writeVarushort(long a)
	{
		while(a > 127)
		{
			this.requireLength(1);
			_buffer[_index++] = (byte)(a & 127 | 128);
			a >>>= 7;
		}
		this.requireLength(1);
		_buffer[_index++] = (byte)(a & 255);
	}

	public short readVarushort() throws BufferOverflowException
	{
		int limit = 0;
		short ret = 0;
		do
		{
			this.checkLength(1);
			ret |= (short)(_buffer[_index] & 127) << (limit * 7);
		} while(_buffer[_index++] < 0 && ++limit < 3 && _index < _buffer.length);
		return ret;
	}

	public void writeVarint(long a)
	{
		this.writeVaruint(a >= 0 ? a * 2  : a * -2 - 1);
	}

	public int readVarint() throws BufferOverflowException
	{
		int ret = this.readVaruint();
		return (int)((ret & 1) == 0 ? ret / 2 : (-ret - 1) / 2);
	}

	public void writeVaruint(long a)
	{
		while(a > 127)
		{
			this.requireLength(1);
			_buffer[_index++] = (byte)(a & 127 | 128);
			a >>>= 7;
		}
		this.requireLength(1);
		_buffer[_index++] = (byte)(a & 255);
	}

	public int readVaruint() throws BufferOverflowException
	{
		int limit = 0;
		int ret = 0;
		do
		{
			this.checkLength(1);
			ret |= (int)(_buffer[_index] & 127) << (limit * 7);
		} while(_buffer[_index++] < 0 && ++limit < 5 && _index < _buffer.length);
		return ret;
	}

	public void writeVarlong(long a)
	{
		this.writeVarulong(a >= 0 ? a * 2  : a * -2 - 1);
	}

	public long readVarlong() throws BufferOverflowException
	{
		long ret = this.readVarulong();
		return (long)((ret & 1) == 0 ? ret / 2 : (-ret - 1) / 2);
	}

	public void writeVarulong(long a)
	{
		while(a > 127)
		{
			this.requireLength(1);
			_buffer[_index++] = (byte)(a & 127 | 128);
			a >>>= 7;
		}
		this.requireLength(1);
		_buffer[_index++] = (byte)(a & 255);
	}

	public long readVarulong() throws BufferOverflowException
	{
		int limit = 0;
		long ret = 0;
		do
		{
			this.checkLength(1);
			ret |= (long)(_buffer[_index] & 127) << (limit * 7);
		} while(_buffer[_index++] < 0 && ++limit < 10 && _index < _buffer.length);
		return ret;
	}
	
	public void writeUUID(UUID uuid)
	{
		this.writeBigEndianLong(uuid.getLeastSignificantBits());
		this.writeBigEndianLong(uuid.getMostSignificantBits());
	}
	
	public UUID readUUID() throws BufferOverflowException
	{
		return new UUID(this.readBigEndianLong(), this.readBigEndianLong());
	}

}
