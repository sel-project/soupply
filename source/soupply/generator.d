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
module soupply.generator;

import std.array : Appender;
import std.ascii : newline;
import std.file : _read = read, _write = write, isFile, mkdirRecurse, dirEntries, SpanMode;
import std.path : buildPath, dirSeparator;
import std.string : lastIndexOf, replace;

import soupply.data;

class Generator {

	private static void delegate(Data)[string] generators;

	/**
	 * Registers a new generator.
	 * Example:
	 * ---
	 * Generator.register!MyGenerator("myg", "src/my");
	 * ---
	 */
	public static void register(T:Generator)(string name, string source) {
		generators[name] = (Data data){ new T().generate(name, source, data); };
	}

	/**
	 * Generates code from every registered generator.
	 */
	public static void generateAll(Data data) {
		foreach(name, generator; generators) generator(data);
	}

	private string path;

	public final void generate(string name, string source, Data data) {
		this.path = buildPath("gen", name, source) ~ dirSeparator;
		immutable gen = buildPath("gen", name) ~ dirSeparator;
		//TODO clean content of gen/name
		mkdirRecurse(gen);
		_write(gen ~ "LICENSE", _read("LICENSE"));
		// copy content of public into gen/name
		string[string] rep = [
			"name": SOFTWARE,
			"description": data.description,
			"license": data.license,
			"version": data.version_,
		];
		immutable public_ = buildPath("public", name) ~ dirSeparator;
		foreach(file ; dirEntries(public_, SpanMode.breadth)) {
			immutable path = file[public_.length..$];
			if(file.isFile) {
				string data = cast(string)_read(file);
				foreach(key, value; rep) {
					data = data.replace("{{" ~ key ~ "}}", value);
				}
				_write(gen ~ path, data);
			} else {
				// dirs should be spanned first
				mkdirRecurse(gen ~ path);
			}
		}
		//TODO copy and convert public files
		this.generateImpl(data);
	}

	protected abstract void generateImpl(Data);

	protected void write(string _path, const(void)[] data, string generatorFile=null) {
		immutable path = buildPath(this.path, path);
		immutable dir = path[0..path.lastIndexOf(dirSeparator)];
		mkdirRecurse(dir);
		_write(path, data);
	}

}

struct Source {

	private immutable string indent;

	Appender!string appender;
	private size_t indentSize = 0;

	public this(string indent) {
		this.indent = indent;
	}

	/**
	 * Adds text to the appender.
	 */
	typeof(this) put(string data) {
		this.appender.put(data);
		return this;
	}

	@property typeof(this) br() {
		return this.put(newline);
	}
	
	@property typeof(this) br(size_t amount) {
		foreach(i ; 0..amount) this.br();
		return this;
	}
	
	@property typeof(this) t() {
		return this.put(this.tab);
	}
	
	@property typeof(this) t(size_t amount) {
		foreach(i ; 0..amount) this.t();
		return this;
	}

	/**
	 * Adds a line of code to the appender.
	 * The line is indentated and a newline is added at the end.
	 */
	typeof(this) line(string data) {
		return this.t(this.indentSize).put(data).br();
	}

	/**
	 * Adds a level of indentation.
	 */
	typeof(this) i() {
		this.indentSize++;
		return this;
	}

	/**
	 * Removes a level of indentation.
	 */
	typeof(this) d() {
		this.indentSize--;
		return this;
	}

	@property string data() {
		return this.appender.data;
	}

}
