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

import core.atomic : atomicOp;

import std.algorithm : canFind;
import std.array : Appender;
import std.ascii : newline;
import std.concurrency : spawnLinked, receiveOnly, LinkTerminated;
import std.conv : to;
import std.datetime.stopwatch : StopWatch;
import std.digest.md : md5Of;
import std.file : _read = read, _write = write, exists, isFile, isDir, remove, mkdirRecurse, rmdir, dirEntries, SpanMode;
import std.parallelism : TaskPool, task;
import std.path : buildPath, buildNormalizedPath, dirSeparator;
import std.stdio : writeln;
import std.string : indexOf, lastIndexOf, toLower, replace, split, join, strip, stripRight, startsWith, endsWith, capitalize;

import soupply.data;

private shared size_t __files, __bytes;

struct GeneratorInfo {

	string name;
	string repo;
	string source;
	string[] comment;
	Generator generator;

}

struct Editorconfig {

	string newline = "\n";
	string indentation = "\t";
	bool finalNewline = false;

}

abstract class Generator {

	private static string[] repos;
	private static GeneratorInfo[] generators;

	/**
	 * Registers a new generator.
	 * Example:
	 * ---
	 * Generator.register!MyGenerator("myg", "src/my", "//");
	 * ---
	 */
	public static void register(T:Generator)(string name, string repo, string source, string[] comment=null) {
		if(!repos.canFind(repo)) repos ~= repo;
		generators ~= GeneratorInfo(name, repo, source, comment, new T());
	}

	/// ditto
	public static void register(T:Generator)(string name, string repo, string source, string comment) {
		register!T(name, repo, source, [comment, comment,  comment]);
	}

	/**
	 * Generates code from every registered generator.
	 */
	public static void generateAll(Data data, bool nopush) {

		static ubyte[16][string] diff(string path) {
			ubyte[16][string] ret;
			if(exists("gen/" ~ path)) {
				if(exists("gen/" ~ path ~ "/.nopush")) remove("gen/" ~ path ~ "/.nopush");
				foreach(file ; dirEntries("gen/" ~ path, SpanMode.breadth)) {
					if(file.isFile && file.indexOf("/.git/") == -1) {
						ret[file[path.length + 5..$]] = md5Of(_read(file));
					}
				}
			}
			return ret;
		}

		ubyte[16][string][string] files;

		Editorconfig[string][string] editorconfig;
		string[string] downloads;

		StopWatch total;
		total.start();

		string[string] rep = [
			"name": SOFTWARE.toLower,
			"name.capital": SOFTWARE.capitalize,
			"description": data.description,
			"license": data.license,
			"version": data.version_,
		];

		// copy files, init editorconfig, get downloads
		foreach(repo ; repos) {
			if(nopush) files[repo] = diff(repo);
			editorconfig[repo] = (Editorconfig[string]).init;
			init(repo, rep, editorconfig[repo], downloads);
		}

		static void generate(GeneratorInfo info, Editorconfig[string] editorconfig, Data data) {

			synchronized writeln("Generating data for ", info.name, " in path ", buildNormalizedPath(buildPath("gen", info.name, info.source)));

			StopWatch timer;
			timer.start();

			try {
			
					with(info) generator.generate(repo, source, comment, editorconfig, data);

			} catch(Throwable e) {

				writeln(e);

			}
			
			timer.stop();
			synchronized writeln("Generated data for ", info.name, " in ", timer.peek);

		}

		static void download(string path, string url) {

			synchronized writeln("Downloading ", url);

			version(Windows) {
				import std.net.curl : get;
				char[] data = get(url);
			} else {
				import std.process : executeShell;
				string data = executeShell("curl -sL " ~ url).output.strip;
			}
			_write(path, data);

			synchronized writeln("Downloaded ", url, " into ", path);

		}

		TaskPool pool = new TaskPool();

		writeln("Generating data from ", generators.length, " generators using ", pool.size, " workers");

		foreach(info ; generators) pool.put(task!generate(info, editorconfig[info.repo], data));

		foreach(path, url; downloads) pool.put(task!download(path, url));

		pool.finish(true);

		// delete empty directories or copy licence
		void[] license = _read("LICENSE");
		foreach(string dir ; dirEntries("gen/", SpanMode.shallow)) {
			if(dir.isDir) {
				bool empty = true;
				foreach(_ ; dirEntries(dir, SpanMode.breadth)) {
					empty = false;
					break;
				}
				if(empty) {
					rmdir(dir);
				} else {
					_write(dir ~ "/LICENSE", license);
				}
			}
		}

		total.stop();
		writeln("Done. Generated ", __bytes / 1000, " kB in ", __files, " files in ", total.peek);

		if(nopush) {
			foreach(repo ; repos) {
				if(files[repo] == diff(repo)) _write("gen/" ~ repo ~ "/.nopush", "");
			}
		}

	}

	private static void init(string repo, string[string] rep, ref Editorconfig[string] editorconfig, ref string[string] downloads) {
		
		// create paths
		immutable gen = buildPath("gen", repo) ~ dirSeparator;
		
		if(!exists(gen)) {
			// create the directory
			mkdirRecurse(gen);
		}
		
		// copy and convert content of public into gen/name
		immutable public_ = buildPath("public", repo) ~ dirSeparator;
		if(exists(public_)) {
			foreach(string file ; dirEntries(public_, SpanMode.breadth)) {
				string path = file[public_.length..$];
				if(file.isFile) {
					string filedata = cast(string)_read(file);
					foreach(key, value; rep) {
						filedata = filedata.replace("{{" ~ key ~ "}}", value);
					}
					// add to download queue or copy
					if(file.endsWith(".download")) downloads[gen ~ path[0..$-9]] = filedata;
					else _write(gen ~ path, filedata);
					// parse editorconfig
					if(path == ".editorconfig") {
						string[] current;
						bool spaces = false;
						void add(string[] exts...) {
							foreach(ext ; exts) editorconfig[ext] = Editorconfig.init;
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
											foreach(c ; current) editorconfig[c].newline = value;
											break;
										case "indent_style":
											spaces = value == "space";
											if(!spaces) foreach(c ; current) editorconfig[c].indentation = "\t";
											break;
										case "indent_size":
											if(spaces) {
												char[] indent = new char[to!size_t(value)];
												foreach(ref i ; indent) i = ' ';
												foreach(c ; current) editorconfig[c].indentation = indent.idup;
											}
											break;
										case "insert_final_newline":
											foreach(c ; current) editorconfig[c].finalNewline = true;
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
		}

	}

	protected Data data;

	private string path;
	private string[] comment; // open, continue, close

	private Editorconfig[string] editorconfig;
	
	protected final @property Generator generator() {
		return this;
	}

	public final void generate(string repo, string source, string[] comment, Editorconfig[string] editorconfig, Data data) {

		if("*" !in editorconfig) editorconfig["*"] = Editorconfig.init;

		// save/init variables
		this.data = data;
		this.path = buildPath("gen", repo, source) ~ dirSeparator;
		this.comment = comment;
		this.editorconfig = editorconfig;
		
		// generate data
		this.generateImpl(data);

	}
	
	protected abstract void generateImpl(Data);

	protected void write(Maker maker, string generatorFile=null) {
		this.write(maker.data, maker.file, generatorFile);
	}

	protected void write(string data, string file, string generatorFile=null) {
		immutable path = buildNormalizedPath(buildPath(this.path, file));
		immutable dir = path[0..path.lastIndexOf(dirSeparator)];
		mkdirRecurse(dir);
		if(this.comment !is null && !["json", "yml", "sh", "xml", "sdl"].canFind(file.split(".")[$-1])) {
			//TODO use right newline
			auto header = Header(this.comment);
			header.open();
			header.put("This file has been automatically generated by Soupply and released under the " ~ this.data.license ~ " license.");
			if(generatorFile !is null) header.put("Generated from " ~ generatorFile); //TODO prepend repo link
			header.close();
			data = header.data ~ data;
		}
		atomicOp!"+="(__bytes, data.length);
		atomicOp!"+="(__files, 1);
		_write(path, data);
	}

}

private struct Header {

	Appender!string appender;
	private string[] _comment;

	this(string[] comment) {
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

class Maker {

	protected immutable string _newline;
	protected immutable string _indent;
	protected immutable bool _final_newline;

	private Generator generator;
	public immutable string file;

	public Appender!string appender;
	protected size_t indentSize = 0;

	public this(Generator generator, string path, string extension) {
		if(extension.startsWith("min.")) {
			extension = extension[4..$];
			_newline = "";
			_indent = "";
			_final_newline = false;
		} else {
			auto e = extension in generator.editorconfig;
			if(e is null) e = "*" in generator.editorconfig;
			_newline = (*e).newline;
			_indent = (*e).indentation;
			_final_newline = (*e).finalNewline;
		}
		this.generator = generator;
		this.file = path ~ "." ~ extension;
	}

	@property string data() {
		string ret = appender.data.stripRight;
		if(_final_newline) ret ~= _newline;
		return ret;
	}

	void clear() {
		this.appender = Appender!string.init;
	}

	/**
	 * Saves the file calling the `write` method on the generator.
	 */
	void save(string generatorFile=null) {
		generator.write(this, generatorFile);
	}

	/**
	 * Puts a newline string as specified in the constructor.
	 */
	@property typeof(this) nl() {
		put(_newline);
		return this;
	}

	/**
	 * Puts the amount of newlines as specified in the first parameter.
	 */
	@property typeof(this) nl(size_t amount) {
		foreach(i ; 0..amount) nl();
		return this;
	}

	/**
	 * Puts an indentation string as specified in the constructor.
	 */
	@property typeof(this) indent() {
		put(_indent);
		return this;
	}
	
	@property typeof(this) indent(size_t amount) {
		foreach(i ; 0..amount) indent();
		return this;
	}

	/**
	 * Adds a line of code to the appender.
	 * The line is indentated and a newline is added at the end.
	 */
	typeof(this) line(string data) {
		indent(indentSize).put(data);
		return nl;
	}

	/**
	 * Adds code to the appended indentating it but without adding
	 * the newline at the end.
	 */
	typeof(this) inline(string data) {
		indent(indentSize).put(data);
		return this;
	}

	/**
	 * Adds a level of indentation.
	 */
	typeof(this) add_indent() {
		indentSize++;
		return this;
	}

	/**
	 * Removes a level of indentation.
	 */
	typeof(this) remove_indent() {
		indentSize--;
		return this;
	}

	/**
	 * Puts an opening brace, a new line and adds a level
	 * of indentation.
	 */
	typeof(this) ob() {
		return line("{").add_indent();
	}

	/**
	 * Removes a level of indentation, puts a closing brace
	 * and a new line.
	 */
	typeof(this) cb() {
		return remove_indent().line("}");
	}

	alias appender this;

}

class XmlMaker : Maker {

	private string[] tags;

	public this(Generator generator, string path, string extension="xml") {
		super(generator, path, extension);
	}

	private string makeTag(string tag, string[string] attr) {
		string ret = "<" ~ tag;
		if(attr !is null) {
			foreach(key, value; attr) ret ~= " " ~ key ~ "=\"" ~ value ~ "\"";
		}
		return ret;
	}

	typeof(this) openTag(string tag, string[string] attr=null) {
		line(makeTag(tag, attr) ~ ">");
		add_indent();
		tags ~= tag;
		return this;
	}

	typeof(this) inlineTag(string tag, string[string] attr=null) {
		line(makeTag(tag, attr) ~ " />");
		return this;
	}

	typeof(this) openCloseTag(string tag, string content, string[string] attr=null) {
		line(makeTag(tag, attr) ~ ">" ~ content ~ "</" ~ tag ~ ">");
		return this;
	}

	typeof(this) openCloseTag(string tag, string[string] attr=null) {
		return this.openCloseTag(tag, "", attr);
	}

	typeof(this) closeTag() {
		remove_indent();
		line("</" ~ tags[$-1] ~ ">");
		tags = tags[0..$-1];
		return this;
	}

}
