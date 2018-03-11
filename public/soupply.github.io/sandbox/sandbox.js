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

var decodeInfo;

function initDecode(buffer) {
	decodeInfo = {
		buffer: buffer,
		length: buffer._buffer.length,
		index: buffer._buffer.length,
		data: []
	};
}

function traceDecode(variable) {
	decodeInfo.data.push({
		variable: variable,
		from: decodeInfo.length - decodeInfo.index,
		to: decodeInfo.length - decodeInfo.buffer._buffer.length
	});
	decodeInfo.index = decodeInfo.buffer._buffer.length;
}

window.onload = function(){
	
	var hash = location.hash;
	if(hash.startsWith("#")) {
		
		var packetName;
		var data = [];
		
		var s = hash.indexOf(":");
		if(s == -1) {
			packetName = hash.substr(1);
		} else {
			packetName = hash.substr(1, s - 1);
			data = eval("[" + hash.substr(s + 1) + "]");
		}
		
		var packet = eval("new " + packetName + "()");
		if(data.length) packet.decodeBody(data);
		
		console.log(data);
		console.log(packet);
		console.log(decodeInfo);
		
	}
	
};
