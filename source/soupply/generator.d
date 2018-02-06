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
import std.conv : to;
import std.file : _read = read, _write = write, exists, isFile, remove, mkdirRecurse, dirEntries, SpanMode;
import std.path : buildPath, buildNormalizedPath, dirSeparator;
import std.string : indexOf, lastIndexOf, replace, split, strip, startsWith, endsWith;

import soupply.data;

abstract class Generator {

	private static void delegate(Data)[string] generators;

	/**
	 * Registers a new generator.
	 * Example:
	 * ---
	 * Generator.register!MyGenerator("myg", "src/my", "//");
	 * ---
	 */
	public static void register(T:Generator)(string name, string source, string[3] comment) {
		generators[name] = (Data data){ new T().generate(name, source, comment, data); };
	}

	/**
	 * Generates code from every registered generator.
	 */
	public static void generateAll(Data data) {
		foreach(name, generator; generators) generator(data);
	}

	protected Data data;

	private string path;
	private string[3] comment; // open, continue, close

	private string[2][string] editorconfig; // editorconfig["*"] = ["\r\n", "\t"]

	public final void generate(string name, string source, string[3] comment, Data data) {

		// save/init variables
		this.data = data;
		this.comment = comment;
		this.editorconfig["*"] = [newline, "\t"];

		// create paths
		this.path = buildPath("gen", name, source) ~ dirSeparator;
		immutable gen = buildPath("gen", name) ~ dirSeparator;

		if(exists(gen)) {
			// remove every file that has been previously generated
			foreach(file ; dirEntries(gen, SpanMode.depth)) {
				if(file.isFile) remove(file);
			}
		} else {
			// create the directory
			mkdirRecurse(gen);
		}

		// copy licence
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
				string filedata = cast(string)_read(file);
				foreach(key, value; rep) {
					filedata = filedata.replace("{{" ~ key ~ "}}", value);
				}
				_write(gen ~ path, filedata);
				if(path == ".editorconfig") {
					string[] current;
					bool spaces = false;
					void add(string[] exts...) {
						foreach(ext ; exts) this.editorconfig[ext] = [newline, "\t"];
						current = exts;
					}
					foreach(line ; split(filedata, "\n")) {
						line = line.strip;
						if(line.startsWith("[*") && line.endsWith("]")) {
							line = line[2..$-1];
							if(line.length) {
								if(line.startsWith(".")) {
									line = line[1..$];
									if(line.startsWith("{") && line.endsWith("}")) add(split(line[1..$-1], ","));
									else add(line);
								}
							} else {
								add("*");
							}
						} else if(current.length) {
							immutable eq = line.indexOf("=");
							if(eq != -1) {
								string value = line[eq+1..$].strip;
								switch(line[0..eq].strip) {
									case "end_of_line":
										value = value.replace("cr", "\r");
										value = value.replace("lf", "\n");
										foreach(c ; current) this.editorconfig[c][0] = value;
										break;
									case "indent_style":
										spaces = value == "space";
										if(!spaces) foreach(c ; current) this.editorconfig[c][1] = "\t";
										break;
									case "indent_size":
										if(spaces) {
											char[] indent = new char[to!size_t(value)];
											foreach(ref i ; indent) i = ' ';
											foreach(c ; current) this.editorconfig[c][1] = indent.idup;
										}
										break;
									case "insert_final_newline":
										//TODO
										break;
									default:
										break;
								}
							}
						}
					}
				}
			} else {
				// dirs should be spanned first
				mkdirRecurse(gen ~ path);
			}
		}

		// generate data
		this.generateImpl(data);

	}

	protected abstract void generateImpl(Data);

	protected void write(Source source, string generatorFile=null) {
		immutable path = buildNormalizedPath(buildPath(this.path, source.file));
		immutable dir = path[0..path.lastIndexOf(dirSeparator)];
		mkdirRecurse(dir);
		string data = source.data;
		if(this.comment.length) {
			//TODO use right newline
			auto header = Header(this.comment);
			header.open();
			header.put("This file has been automatically generated by Soupply and released un the " ~ this.data.license ~ " license.");
			if(generatorFile !is null) header.put("Generated from " ~ generatorFile); //TODO prepend repo link
			header.close();
			data = header.data ~ data;
		}
		_write(path, data); //TODO insert/remove final newline
	}

}

private struct Header {

	Appender!string appender;
	private string[3] _comment;

	this(string[3] comment) {
		_comment = comment;
	}

	void open() {
		appender.put(_comment[0]);
		appender.put(newline);
	}

	void put(string data) {
		appender.put(_comment[1]);
		appender.put(" ");
		appender.put(data);
		appender.put(newline);
	}

	void close() {
		appender.put(_comment[2]);
		appender.put(newline);
	}

	alias appender this;

}

class Source {

	private immutable string _newline;
	private immutable string _indent;
	private immutable string _final_newline;

	public immutable string file;

	Appender!string appender;
	private size_t indentSize = 0;

	public this(Generator generator, string path, string extension) {
		auto e = extension in generator.editorconfig;
		if(e is null) e = "*" in generator.editorconfig;
		_newline = (*e)[0];
		_indent = (*e)[1];
		_final_newline = "";
		this.file = path ~ "." ~ extension;
	}

	/**
	 * Adds text to the appender.
	 */
	typeof(this) put(string data) {
		appender.put(data);
		return this;
	}

	/**
	 * Puts a newline string as specified in the constructor.
	 */
	@property typeof(this) nl() {
		return put(_newline);
	}
	
	@property typeof(this) nl(size_t amount) {
		foreach(i ; 0..amount) nl();
		return this;
	}

	/**
	 * Puts an indentation string as specified in the constructor.
	 */
	@property typeof(this) t() {
		return put(_indent);
	}
	
	@property typeof(this) t(size_t amount) {
		foreach(i ; 0..amount) t();
		return this;
	}

	/**
	 * Adds a line of code to the appender.
	 * The line is indentated and a newline is added at the end.
	 */
	typeof(this) line(string data) {
		return t(indentSize).put(data).nl;
	}

	/**
	 * Adds code to the appended indentating it but without adding
	 * the newline at the end.
	 */
	typeof(this) inline(string data) {
		return t(indentSize).put(data);
	}

	/**
	 * Adds a level of indentation.
	 */
	typeof(this) i() {
		indentSize++;
		return this;
	}

	/**
	 * Removes a level of indentation.
	 */
	typeof(this) d() {
		indentSize--;
		return this;
	}

	/**
	 * Puts an opening bracket, a new line and adds a level
	 * of indentation.
	 */
	typeof(this) ob() {
		return line("{").i;
	}

	/**
	 * Removes a level of indentation, puts a closing bracket
	 * and a new line.
	 */
	typeof(this) cb() {
		return d.line("}");
	}

	@property string data() {
		return appender.data;
	}

}
