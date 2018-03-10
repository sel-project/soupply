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
module soupply.gen.code;

import std.string : format, join;

import soupply.data;
import soupply.generator;

abstract class CodeGenerator : Generator {

	private const CodeMaker.Settings settings;
	private const string extension;

	protected bool oneClassPerModule;

	private string game;

	public this(CodeMaker.Settings settings, string extension) {
		this.settings = settings;
		this.extension = extension;
	}

	protected CodeMaker make(string[] module_...) {
		foreach(ref m ; module_) {
			m = this.convertModule(m);
		}
		return new CodeMaker(this, module_, this.extension, this.settings, this.game);
	}

	protected override void generateImpl(Data data) {
		foreach(game, info; data.info) {
			this.game = game;
			this.generateGame(game, info);
		}
	}

	protected void generateGame(string game, Info info) {

		/+immutable id = this.convertType(game, protocolInfo.data.id);
		immutable arrayLength = this.convertType(game, protocolInfo.data.arrayLength);
		
		//TODO create specific encoder for module
		
		with(make("protocol", game, "packet")) {
			startClass("Packet");
			
			endClass();
		}
		
		// types
		//TODO use module maker
		with(make("protocol", game, "types")) {
			
			
		}+/

	}

	protected string convertModule(string name) {
		return name;
	}

	protected string convertName(string name) {
		return name;
	}

	protected string convertType(string game, string type) {
		return type;
	}

}

class CodeMaker : Maker {
	
	static struct Settings {
		
		bool semicolons = true;
		bool braces = true;
		bool inlineBraces = true;
		bool spaceAfterBlock = true;

		string moduleDeclaration;
		string moduleSeparator = ".";
		string importDeclartion;

		string baseModule = SOFTWARE;
		string standardLibrary;
		
		string comment = "//";

		string moduleStat;
		string importStat;
		string classStat;
		string constStat;
		
	}

	private CodeGenerator cg;
	
	private const Settings settings;
	private const string _game;
	
	private immutable string _semicolon;
	private immutable string _open_brace;
	
	public this(CodeGenerator generator, string[] module_, string extension, inout Settings settings, string game) {
		super(generator, join(module_, "/"), extension);
		this.cg = generator;
		this.settings = settings;
		_game = game;
		_semicolon = settings.semicolons ? ";" : "";
		_open_brace = settings.spaceAfterBlock ? " {" : "{";
		// add module declaration
		this.stat(format(settings.moduleStat, join(settings.baseModule ~ module_, settings.moduleSeparator))).nl;
	}

	public string convertName(string name) {
		return this.cg.convertName(name);
	}

	public string convertType(string type) {
		return this.cg.convertType(_game, type);
	}
	
	// ------
	// inline
	// ------
	
	/**
	 * Adds a comment.
	 */
	typeof(this) comment(string comment) {
		line(settings.comment ~ comment);
		return this;
	}
	
	/**
	 * Adds a statement, appending a semicolon at the end of it if
	 * specified in the settings.
	 */
	typeof(this) stat(string stat) {
		line(stat ~ _semicolon);
		return this;
	}
	
	/**
	 * Adds an import.
	 */
	typeof(this) addImport(string module_, string[] selective...) {
		return stat("import " ~ module_ ~ (selective.length ? " : " ~ selective.join(", ") : ""));
	}
	
	typeof(this) addImportStd(string module_, string[] selective...) {
		return addImport(settings.standardLibrary ~ settings.moduleSeparator ~ module_, selective);
	}
	
	typeof(this) addImportLib(string module_, string[] selective...) {
		return addImport(settings.baseModule ~ settings.moduleSeparator ~ module_, selective);
	}

	/**
	 * Adds a constant.
	 */
	typeof(this) addConst(string key, string value) {
		return stat(format(settings.constStat, key, value));
	}
	
	/**
	 * Adds a variable declaration.
	 */
	typeof(this) var(string type, string name) {
		return stat(convertType(type) ~ " " ~ convertName(name));
	}
	
	/// ditto
	typeof(this) var(string modifiers, string type, string name) {
		return stat(modifiers ~ " " ~ convertType(type) ~ " " ~ convertName(name));
	}
	
	/// ditto
	typeof(this) var_assign(string type, string name, string value) {
		return stat(convertType(type) ~ " " ~ convertName(name) ~ " = " ~ value);
	}
	
	/// ditto
	typeof(this) var_assign(string modifiers, string type, string name, string value) {
		return stat(modifiers ~ " " ~ convertType(type) ~ " " ~ convertName(name) ~ " = " ~ value);
	}
	
	/**
	 * Performs an operation.
	 */
	typeof(this) op(string name0, string op, string name1) {
		return stat(name0 ~ " " ~ op ~ " " ~ name1);
	}
	
	/**
	 * Assigns a variable.
	 */
	typeof(this) assign(string name, string value) {
		return op(name, "=", value);
	}
	
	// ------
	// scopes
	// ------
	
	/**
	 * Adds a declaration and opens a brace.
	 */
	typeof(this) block(string data) {
		inline(data);
		if(settings.inlineBraces) appender.put(_open_brace);
		else nl.inline("{");
		add_indent();
		nl;
		return this;
	}

	typeof(this) endBlock() {
		remove_indent();
		inline("}");
		nl;
		return this;
	}
	
	typeof(this) addClass(string class_) {
		return block("class " ~ class_);
	}
	
}

