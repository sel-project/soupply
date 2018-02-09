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
module soupply.gen.json;

import std.json : JSONValue;
import std.string : startsWith;

import soupply.data;
import soupply.generator;
import soupply.util;

import transforms : snakeCase;

version(JSON):

class JSONGenerator : Generator {

	static this() {
		Generator.register!JSONGenerator("json", "");
	}

	protected override void generateImpl(Data data) {

		void encode(string path, JSONValue[string] json) {
			write(JSONValue(json).toPrettyString(), path ~ ".json");
			foreach(key ; json.keys) {
				if(key.startsWith("__")) json.remove(key);
			}
			write(JSONValue(json).toString(), path ~ ".min.json");
		}

		// protocol
		foreach(game, protocol; data.protocols) {
			
			JSONValue[string] create() {
				return [
					"__website": JSONValue("https://sel-project.github.io/soupply"),
					"__software": JSONValue(protocol.software),
					"__protocol": JSONValue(protocol.protocol)
				];
			}

			with(protocol.data) {

				auto json = create();

				// encoding
				JSONValue[string] encoding;
				encoding["endianness"] = (JSONValue[string]).init;
				foreach(type, e; endianness) encoding["endianness"][type] = e;
				encoding["id"] = id;
				encoding["array_length"] = arrayLength;

				// arrays
				JSONValue[string] _arrays;
				foreach(name, array; arrays) {
					JSONValue[string] _array;
					_array["base"] = array.base;
					_array["length"] = array.length;
					if(array.endianness.length) _array["endianness"] = array.endianness;
					_arrays[name] = _array;
				}

				// types
				JSONValue[string] _types;

				// packets
				JSONValue[string] packets;

				json["encoding"] = encoding;
				json["arrays"] = _arrays;
				json["types"] = _types;
				json["packets"] = packets;

				encode("protocol/" ~ game, json);

			}

			//TODO metadata

		}

	}

}
