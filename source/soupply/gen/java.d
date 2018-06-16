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
module soupply.gen.java;

import std.algorithm : sort, canFind, min, max, reverse, count;
import std.array : replicate;
import std.ascii : newline;
import std.conv : to;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.math : isNaN;
import std.path : dirSeparator;
import std.regex : ctRegex, replaceAll, matchFirst;
import std.string;
import std.typecons : tuple;
import std.typetuple : TypeTuple;

import soupply.data;
import soupply.generator;
import soupply.gen.code;
import soupply.util;

class JavaGenerator : CodeGenerator {

	static this() {
		Generator.register!JavaGenerator("Java", "java", "");
	}

	public this() {
		
		CodeMaker.Settings settings;
		settings.inlineBraces = false;
		settings.moduleSeparator = ".";
		settings.standardLibrary = "std";
		
		settings.moduleStat = "package %s";
		settings.importStat = "import %s";
		settings.classStat = "class %s";
		settings.constStat = "enum %s = %d";
		
		super(settings, "java");
		
	}

	import std.stdio : writeln;

	protected override void generateImpl(Data d) {

		super.generateImpl(d);

		// generate main maven file
		with(new XmlMaker(this, "pom")) {

			openTag("project", ["xmlns": "http://maven.apache.org/POM/4.0.0", "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance", "xsi:schemaLocation": "http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"]).nl;
			openCloseTag("modelVersion", "4.0.0").nl;

			openCloseTag("groupId", SOFTWARE);
			openCloseTag("artifactId", SOFTWARE);
			openCloseTag("version", d.version_.to!string);
			openCloseTag("packaging", "pom").nl;

			openCloseTag("name", SOFTWARE);
			openCloseTag("description", d.description.to!string).nl;

			string[] modules = ["util"];
			foreach(game, info; d.info) {
				modules ~= game;
				if(info.latest) modules ~= info.game;
			}
			sort(modules);
			openTag("modules");
			foreach(m ; modules) {
				openCloseTag("module", m);
			}
			closeTag().nl;

			openTag("build");
			openCloseTag("finalName", SOFTWARE);
			openCloseTag("directory", "${project.basedir}/target");
			openTag("plugins");
			openTag("plugin");
			openCloseTag("groupId", "org.apache.maven.plugins");
			openCloseTag("artifactId", "maven-jar-plugin");
			openCloseTag("version", "2.3.1");
			closeTag();
			closeTag();
			closeTag().nl;

			closeTag();
			save();

		}

		// generate maven files
		foreach(game, info; d.info) {
			with(new XmlMaker(this, game ~ "/pom")) {

				openTag("project", ["xmlns": "http://maven.apache.org/POM/4.0.0", "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance", "xsi:schemaLocation": "http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"]).nl;
				openCloseTag("modelVersion", "4.0.0").nl;

				openTag("parent");
				openCloseTag("groupId", SOFTWARE);
				openCloseTag("artifactId", SOFTWARE);
				openCloseTag("version", d.version_.to!string);
				closeTag().nl;

				openCloseTag("artifactId", game).nl;

				openTag("dependencies");
				openTag("dependency");
				openCloseTag("groupId", SOFTWARE);
				openCloseTag("artifactId", "util");
				openCloseTag("version", d.version_.to!string);
				closeTag();
				closeTag().nl;

				closeTag();
				save();

			}
		}
		
		// generate latest modules
		foreach(game, info; d.info) {
			if(info.latest) {
				// read files from {game}/src/main/java/{game} and copy to {info.game}/src/main/java/{info.game}
				import std.file;
				foreach(string dir ; dirEntries("gen/java/" ~ game, SpanMode.breadth)) {
					if(dir.isDir) mkdirRecurse(dir.replace(game, info.game));
				}
				foreach(string file ; dirEntries("gen/java/" ~ game, SpanMode.breadth)) {
					if(file.isFile) std.file.write(file.replace(game, info.game), replace(cast(string)read(file), game, info.game));
					//if(file.isFile) std.file.write(file.replace(game, info.game), read(file));
				}
			}
		}

		// generate tuples
		string[] tuples;
		void add(string type) {
			immutable open = type.indexOf("<");
			if(open != -1) {
				immutable tuple = this.convertType("", type[0..open]) ~ "." ~ type[open+1..type.indexOf(">")];
				if(!tuples.canFind(tuple)) tuples ~= tuple;
			}
		}
		void fields(Protocol.Field[] fields) {
			foreach(field ; fields) add(field.type);
		}
		foreach(info ; d.info) {
			foreach(type ; info.protocol.types) fields(type.fields);
			foreach(section ; info.protocol.sections) {
				foreach(packet ; section.packets) {
					fields(packet.fields);
					foreach(variant ; packet.variants) fields(variant.fields);
				}
			}
		}

		foreach(tuple ; tuples) {
			immutable p = tuple.indexOf(".");
			immutable type = convertType("", tuple[0..p]);
			immutable coords = tuple[p+1..$];
			immutable name = capitalize(tuple[0..p]) ~ toUpper(coords);
			with(make("util/src/main/java", SOFTWARE, "util", name)) {
				clear();
				stat("package " ~ SOFTWARE ~ ".util").nl;
				block("public class " ~ name).nl;
				// fields
				string[] ctor;
				foreach(coord ; coords) {
					stat("public " ~ type ~ " " ~ coord);
					ctor ~= (type ~ " " ~ coord);
				}
				nl();
				// empty ctor
				line("public " ~ name ~ "() {}").nl;
				// ctor
				block("public " ~ name ~ "(" ~ ctor.join(", ") ~ ")");
				foreach(coord ; coords) {
					stat("this." ~ coord ~ " = " ~ coord);
				}
				endBlock().nl;
				endBlock();
				save();
			}
		}

	}

	protected override void generateGame(string game, Info info) {

		// generate packet class
		with(make(game, "src/main/java", SOFTWARE, game, "Packet")) {

			clear(); // remove pre-generated package declaration
			stat("package " ~ SOFTWARE ~ "." ~ game).nl;
			stat("import " ~ SOFTWARE ~ ".util.Buffer").nl;
			block("public abstract class Packet extends " ~ SOFTWARE ~ ".util.Packet").nl;
			stat("public abstract " ~ convertType(info.protocol.id) ~ " getId()").nl;

			// encode
			line("@Override");
			block("public byte[] encode()");
			stat("Buffer buffer = new Buffer()");
			stat("buffer.write" ~ capitalize(info.protocol.id) ~ "(this.getId())");
			if(info.protocol.padding) stat("buffer.writeBytes(new byte[" ~ info.protocol.padding.to!string ~ "])");
			stat("this.encodeBody(buffer)");
			endBlock().nl;

			// decode
			line("@Override");
			block("public void decode(byte[] _buffer)");
			stat("Buffer buffer = new Buffer(_buffer)");
			stat("buffer.read" ~ capitalize(info.protocol.id) ~ "()");
			if(info.protocol.padding) stat("buffer.readBytes(" ~ info.protocol.padding.to!string ~ ")");
			stat("this.decodeBody(buffer)");
			endBlock().nl;

			endBlock();
			save();
			
		}

		void writeFields(CodeMaker source, string className, Protocol.Field[] fields) {
			// constants
			foreach(field ; fields) {
				if(field.constants.length) {
					source.line("// " ~ field.name.replace("_", " "));
					foreach(constant ; field.constants) {
						source.stat("public static final " ~ source.convertType(field.type) ~ " " ~ toUpper(constant.name) ~ " = " ~ (field.type == "string" ? JSONValue(constant.value).toString() : "(" ~ source.convertType(field.type) ~ ")" ~ constant.value));
					}
					source.nl;
				}
			}
			// fields
			foreach(i, field; fields) {
				source.stat("public " ~ source.convertType(field.type) ~ " " ~ (field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name)) ~ (field.default_.length ? " = " ~ constOf(field.default_) : ""));
				if(i == fields.length - 1) source.nl;
			}
			// constructors
			if(fields.length) {
				source.block("public " ~ className ~ "()");
				// init static arrays and classes
				foreach(i, field; fields) {
					immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
					immutable conv = source.convertType(field.type);
					// static arrays
					immutable aopen = field.type.indexOf("[");
					immutable aclose = field.type.indexOf("]");
					if(aopen != -1 && aclose > aopen + 1) {
						source.stat("this." ~ name ~ " = new " ~ conv.replace("[]", field.type[aopen..aclose+1]));
					} else if(aopen == -1 && (field.type.indexOf("<") != -1 || conv.startsWith(SOFTWARE ~ ".") || field.type == "uuid" || field.type == "metadata")) {
						source.stat("this." ~ name ~ " = new " ~ conv ~ "()");
					}
				}
				source.endBlock().nl;
				string[] args;
				foreach(i, field; fields) {
					immutable type = source.convertType(field.type);
					immutable p = type.canFind('[');
					args ~= type ~ " " ~ (field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name));
				}
				source.block("public " ~ className ~ "(" ~ args.join(", ") ~ ")");
				foreach(i, field; fields) {
					immutable name = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
					source.stat("this." ~ name ~ " = " ~ name);
				}
				source.endBlock().nl;
			}
		}

		// types
		foreach(type ; info.protocol.types) {
			auto t = make(game, "src/main/java", SOFTWARE, game, "type", camelCaseUpper(type.name));
			with(t) {
				clear();
				stat("package " ~ SOFTWARE ~ "." ~ game ~ ".type").nl;
				stat("import java.util.*");
				stat("import " ~ SOFTWARE ~ ".util.*").nl;
				block("public class " ~ camelCaseUpper(type.name) ~ " extends Type").nl;
				// fields
				writeFields(t, camelCaseUpper(type.name), type.fields);
				// encode
				line("@Override");
				block("public void encodeBody(Buffer buffer)");

				endBlock().nl;
				// decode
				line("@Override");
				block("public void decodeBody(Buffer buffer)");

				endBlock().nl;
				endBlock();
				save();
			}
		}

		// sections and packets
		foreach(section ; info.protocol.sections) {
			foreach(packet ; section.packets) {
				auto p = make(game, "src/main/java", SOFTWARE, game, "protocol", section.name, camelCaseUpper(packet.name));
				with(p) {
					clear();
					stat("package " ~ SOFTWARE ~ "." ~ game ~ ".protocol." ~ section.name).nl;
					stat("import java.util.*");
					stat("import " ~ SOFTWARE ~ ".util.*").nl;
					block("public class " ~ camelCaseUpper(packet.name) ~ " extends " ~ SOFTWARE ~ "." ~ game ~ ".Packet").nl;
					stat("public static final " ~ convertType(info.protocol.id) ~ " ID = " ~ packet.id.to!string).nl;
					// fields
					writeFields(p, camelCaseUpper(packet.name), packet.fields);
					// id
					line("@Override");
					block("public " ~ convertType(info.protocol.id) ~ " getId()");
					stat("return ID");
					endBlock().nl;
					// encode
					line("@Override");
					block("public void encodeBody(Buffer buffer)");
					
					endBlock().nl;
					// decode
					line("@Override");
					block("public void decodeBody(Buffer buffer)");
					
					endBlock().nl;
					//TODO variants
					endBlock();
					save();
				}
			}
		}

		// metadata
		with(make(game, "src/main/java", SOFTWARE, game, "Metadata")) {
			clear();
			stat("package " ~ SOFTWARE ~ "." ~ game);
			block("public class Metadata");
			//TODO
			endBlock();
			save();
		}
		
		/+
		
		// protocols
		string[] tuples;
		foreach(string game, Protocols prs; protocols) {
			
			@property string convertName(string name) {
				if(name == "default") return "def";
				else return toCamelCase(name);
			}
			
			immutable id = convert(prs.data.id);
			immutable arrayLength = convert(prs.data.arrayLength);
			
			// returns the endianness for a type
			string endiannessOf(string type, string over="") {
				if(!over.length) {
					auto e = type in prs.data.endianness;
					if(e) over = *e;
					else over = prs.data.endianness["*"];
				}
				return toPascalCase(over);
			}
			
			// encoding expression
			string createEncoding(string type, string name, string e="") {
				if(type[0] == 'u' && defaultTypes.canFind(type[1..$])) type = type[1..$];
				auto conv = type in prs.data.arrays ? prs.data.arrays[type].base ~ "[]" : type;
				auto lo = conv.lastIndexOf("[");
				if(lo > 0) {
					string ret = "";
					auto lc = conv.lastIndexOf("]");
					immutable nt = conv[0..lo];
					immutable cnt = convert(nt);
					if(lo == lc - 1) {
						auto ca = type in prs.data.arrays;
						if(ca) {
							auto c = *ca;
							ret ~= createEncoding(c.length, "(" ~ convert(c.length) ~ ")" ~ name ~ ".length", c.endianness);
						} else {
							ret ~= createEncoding(prs.data.arrayLength, "(" ~ arrayLength ~ ")" ~ name ~ ".length");
						}
						ret ~= " ";
					}
					if(cnt == "byte") return ret ~ "this.writeBytes(" ~ name ~ ");";
					else return ret ~ "for(" ~ cnt ~ " " ~ hash(name) ~ ":" ~ name ~ "){ " ~ createEncoding(nt, hash(name)) ~ " }";
				}
				auto ts = conv.lastIndexOf("<");
				if(ts > 0) {
					auto te = conv.lastIndexOf(">");
					string nt = conv[0..ts];
					string[] ret;
					foreach(i ; conv[ts+1..te]) {
						ret ~= createEncoding(nt, name ~ "." ~ i);
					}
					return ret.join(" ");
				}
				type = conv;
				if(type.startsWith("var")) return "this.write" ~ capitalize(type) ~ "(" ~ name ~ ");";
				else if(type == "string") return "byte[] " ~ hash(name) ~ "=" ~ name ~ ".getBytes(StandardCharsets.UTF_8); " ~ createEncoding("byte[]", hash(name));
				else if(type == "uuid") return "this.writeBigEndianLong(" ~ name ~ ".getLeastSignificantBits()); this.writeBigEndianLong(" ~ name ~ ".getMostSignificantBits());";
				else if(type == "bytes") return "this.writeBytes(" ~ name ~ ");";
				else if(type == "bool") return "this.writeBool(" ~ name ~ ");";
				else if(type == "triad" || defaultTypes.canFind(type)) return "this.write" ~ endiannessOf(type, e) ~ capitalize(type) ~ "(" ~ name ~ ");";
				else return "this.writeBytes(" ~ name ~ ".encode());";
			}
			
			// decoding expressions
			string createDecoding(string type, string name, string e="") {
				if(type[0] == 'u' && defaultTypes.canFind(type[1..$])) type = type[1..$];
				auto conv = type in prs.data.arrays ? prs.data.arrays[type].base ~ "[]" : type;
				auto lo = conv.lastIndexOf("[");
				if(lo > 0) {
					string ret = "";
					auto lc = conv.lastIndexOf("]");
					immutable nt = conv[0..lo];
					immutable cnt = convert(nt);
					if(lo == lc - 1) {
						auto ca = type in prs.data.arrays;
						if(ca) {
							auto c = *ca;
							ret ~= createDecoding(c.length, "int " ~ hash("l" ~ name), c.endianness);
						} else {
							ret ~= createDecoding(prs.data.arrayLength, "int " ~ hash("l" ~ name));
						}
						ret ~= " ";
					} else {
						ret ~= "final int " ~ hash("l" ~ name) ~ "=" ~ conv[lo+1..lc] ~ "; ";
					}
					immutable newexp = cnt.indexOf("[") >= 0 ? (cnt[0..cnt.indexOf("[")] ~ "[" ~ hash("l" ~ name) ~ "][]") : (cnt ~ "[" ~ hash("l" ~ name) ~ "]");
					if(cnt == "byte") return ret ~ name ~ "=this.readBytes(" ~ hash("l" ~ name) ~ ");";
					else return ret ~ name ~ "=new " ~ newexp ~ "; for(int " ~ hash(name) ~ "=0;" ~ hash(name) ~ "<" ~ name ~ ".length;" ~ hash(name) ~ "++){ " ~ createDecoding(nt, name ~ "[" ~ hash(name) ~ "]") ~ " }";
				}
				auto ts = conv.lastIndexOf("<");
				if(ts > 0) {
					auto te = conv.lastIndexOf(">");
					string nt = conv[0..ts];
					string[] ret;
					foreach(i ; conv[ts+1..te]) {
						ret ~= createDecoding(nt, name ~ "." ~ i);
					}
					return name ~ "=new " ~ convert(conv) ~ "(); " ~ ret.join(" ");
				}
				type = conv;
				if(type.startsWith("var")) return name ~ "=this.read" ~ capitalize(type) ~ "();";
				else if(type == "string") return createDecoding(prs.data.arrayLength, arrayLength ~ " " ~ hash("len" ~ name)) ~ " " ~ name ~ "=new String(this.readBytes(" ~ hash("len" ~ name) ~ "), StandardCharsets.UTF_8);";
				else if(type == "uuid") return createDecoding("long", "long " ~ hash("\x00" ~ name)) ~ " " ~ createDecoding("long", "long " ~ hash("\xF0" ~ name)) ~ " " ~ name ~ "=new UUID(" ~ hash("\x00" ~ name) ~ "," ~ hash("\xF0" ~ name) ~ ");";
				else if(type == "bytes") return name ~ "=this.readBytes(this._buffer.length-this._index);";
				else if(type == "bool") return name ~ "=this.readBool();";
				else if(defaultTypes.canFind(type) || type == "triad") return name ~ "=read" ~ endiannessOf(type, e) ~ capitalize(type) ~ "();";
				else return name ~ "=new " ~ convert(type) ~ "(); " ~ name ~ "._index=this._index; " ~ name ~ ".decode(this._buffer); this._index=" ~ name ~ "._index;";
			}
			
			// write generic fields
			void writeFields(ref string data, string space, string className, Field[] fields, ptrdiff_t id=-1, bool hasVariants=false, bool isVariant=false, string length="") { // hasId is true when fields belong to a packet, false when a type
				// constants
				foreach(field ; fields) {
					if(field.constants.length) {
						data ~= space ~ "// " ~ field.name.replace("_", " ") ~ "\n";
						foreach(constant ; field.constants) {
							data ~= space ~ "public static final " ~ convert(field.type) ~ " " ~ toUpper(constant.name) ~ " = " ~ (field.type == "string" ? JSONValue(constant.value).toString() : "(" ~ convert(field.type) ~ ")" ~ constant.value) ~ ";\n";
						}
						data ~= "\n";
					}
				}
				// fields
				foreach(i, field; fields) {
					immutable c = convert(field.type);
					immutable oa = field.type.indexOf("[");
					immutable ca = field.type.indexOf("]");
					data ~= space ~ "public " ~ c ~ " " ~ (field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name));
					//if(c.indexOf("[") != -1) data ~= " = new " ~ c[0..c.indexOf("[")] ~ "[" ~ (ca == -1 || ca == oa + 1 ? "0" : field.type[oa+1..ca]) ~ "]";
					if(c.indexOf("[") != -1) data ~= " = new " ~ c[0..c.indexOf("[")] ~ (oa == -1 ? "[0]" : field.type[oa..$].replace("[]", "[0]"));
					else if(field.def.length) data ~= " = " ~ constOf(field.def);
					else if(field.type == "bytes") data ~= " = new byte[0]";
					else if(c.startsWith("Tuples.")) data ~= " = new " ~ c ~ "()";
					data ~= ";\n";
					if(i == fields.length - 1) data ~= "\n";
				}
				// constructors
				if(fields.length) {
					data ~= space ~ "public " ~ className ~ "() {}\n\n";
					data ~= space ~ "public " ~ className ~ "(";
					foreach(i, field; fields) {
						data ~= convert(field.type) ~ " " ~ (field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name)) ~ (i != fields.length - 1 ? ", " : "");
					}
					data ~= ") {\n";
					foreach(i, field; fields) {
						immutable n = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
						data ~= space ~ "\tthis." ~ n ~ " = "~ n ~ ";\n";
					}
					data ~= space ~ "}\n\n";
				}
				// length
				data ~= space ~ "@Override\n";
				data ~= space ~ "public int length() {\n";
				data ~= space ~ "\t" ~ fieldsLength(fields, id >= 0 ? prs.data.id : "", id, length) ~ ";\n";
				data ~= space ~ "}\n\n";
				// encoding
				data ~= space ~ "@Override\n";
				data ~= space ~ "public byte[] encode() {\n";
				if(hasVariants) {
					data ~= space ~ "\treturn this.encodeImpl();\n";
					data ~= space ~ "}\n\n";
					data ~= space ~ "private byte[] encodeImpl() {\n";
					data ~= space ~ "\tthis._buffer = new byte[this.length()];\n";
				} else if(isVariant) {
					data ~= space ~ "\tbyte[] _encode = encodeImpl();\n";
					data ~= space ~ "\tthis._buffer = new byte[_encode.length + this.length()];\n";
					data ~= space ~ "\tthis.writeBytes(_encode);\n";
				} else {
					data ~= space ~ "\tthis._buffer = new byte[this.length()];\n";
				}
				if(id >= 0) {
					data ~= space ~ "\t" ~ createEncoding(prs.data.id, "ID") ~ "\n";
				}
				foreach(i, field; fields) {
					bool c = field.condition.length != 0;
					data ~= space ~ "\t" ~ (c ? "if(" ~ toCamelCase(field.condition) ~ "){ " : "") ~ createEncoding(field.type, field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.endianness) ~ (c ? " }" : "") ~ "\n";
				}
				if(length.length) {
					data ~= space ~ "\tbyte[] _this = this.getBuffer();\n";
					data ~= space ~ "\tthis._buffer = new byte[10 + _this.length];\n"; // longest length of a length type
					data ~= space ~ "\tthis._index = 0;\n";
					data ~= space ~ "\t" ~ createEncoding(length, "_this.length") ~ "\n";
					data ~= space ~ "\tthis.writeBytes(_this);\n";
				}
				data ~= space ~ "\treturn this.getBuffer();\n";
				data ~= space ~ "}\n\n";
				// decoding
				data ~= space ~ "@Override\n";
				data ~= space ~ "public void decode(byte[] buffer) {\n";
				data ~= space ~ "\tthis._buffer = buffer;\n";
				if(length.length) {
					data ~= space ~ "\t" ~ createDecoding(length, "final int _length") ~ "\n";
					data ~= space ~ "\tfinal int _length_index = this._index;\n";
					data ~= space ~ "\tthis._buffer = this.readBytes(_length);\n";
					data ~= space ~ "\tthis._index = 0;\n";
				}
				if(id >= 0) {
					data ~= space ~ "\t" ~ createDecoding(prs.data.id, "").split("=")[1..$].join("=") ~ "\n";
				}
				foreach(i, field; fields) {
					bool c = field.condition.length != 0;
					data ~= space ~ "\t" ~ (c ? "if(" ~ toCamelCase(field.condition) ~ "){ " : "") ~ createDecoding(field.type, field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name), field.endianness) ~ (c ? " }" : "") ~ "\n";
				}
				if(length.length) {
					data ~= space ~ "\tthis._index += _length_index;\n";
				}
				data ~= space ~ "}\n\n";
				if(isVariant) {
					data ~= space ~ "public void decode() {\n";
					data ~= space ~ "\tthis.decode(remainingBuffer());\n";
					data ~= space ~ "}\n\n";
				}
				if(hasVariants) {
					data ~= space ~ "private byte[] remainingBuffer() {\n";
					data ~= space ~ "\treturn java.util.Arrays.copyOfRange(this._buffer, this._index, this._buffer.length);\n";
					data ~= space ~ "}\n\n";
				}
			}

			void createToString(ref string data, string space, string className, Field[] fields) {
				data ~= space ~ "@Override\n";
				data ~= space ~ "public String toString() {\n";
				string[] f;
				foreach(i, field; fields) {
					immutable c = convert(field.type);
					immutable n = field.name == "?" ? "unknown" ~ to!string(i) : convertName(field.name);
					string dec = n ~ ": \" + ";
					if(c.endsWith("[]")) {
						bool deep = true;
						foreach(simple ; ["boolean", "byte", "short", "int", "long", "float", "double"]) {
							if(c.startsWith(simple)) {
								deep = false;
								break;
							}
						}
						if(deep) dec ~= "Arrays.deepToString(this." ~ n ~ ")";
						else dec ~= "Arrays.toString(this." ~ n ~ ")";
					} else {
						if(["boolean", "byte", "short", "int", "long", "float", "double", "String"].canFind(c)) dec ~= "this." ~ n;
						else dec ~= "this." ~ n ~ ".toString()";
					}
					f ~= dec;
				}
				data ~= space ~ "\treturn \"" ~ className ~ "(" ~ (f.length ? (f.join(" + \", ") ~ " + \"") : "") ~ ")\";\n";
				data ~= space ~ "}\n\n";
			}
			
			@property string imports(Field[] fields) {
				bool str, arrays, uuid;
				foreach(field ; fields) {
					auto conv = convert(field.type);
					if(conv.endsWith("[]")) arrays = true;
					immutable t = conv.split("[")[0].split("<")[0];
					if(t == "String") str = true;
					else if(t == "UUID") uuid = true;
					else if(field.type.indexOf("<") != -1) {
						immutable a = convert(field.type.split("<")[0]) ~ "|" ~ field.type.split("<")[1].split(">")[0];
						if(!tuples.canFind(a)) tuples ~= a;
					}
				}
				string ret = "";
				if(str) ret ~= "import java.nio.charset.StandardCharsets;\n";
				if(arrays) ret ~= "import java.util.Arrays;\n";
				if(uuid) ret ~= "import java.util.UUID;\n";
				if(str || arrays || uuid) ret ~= "\n";
				return ret;
			}
			
			foreach(type ; prs.data.types) {
				string data = "package sul.protocol." ~ game ~ ".types;\n\n" ~ imports(type.fields) ~ "import sul.utils.*;\n\n";
				data ~= "public class " ~ toPascalCase(type.name) ~ " extends Stream {\n\n";
				writeFields(data, "\t", toPascalCase(type.name), type.fields, -1, false, false, type.length);
				createToString(data, "\t", toPascalCase(type.name), type.fields);
				data ~= "\n}";
				write("../src/java/sul/protocol/" ~ game ~ "/types/" ~ toPascalCase(type.name) ~ ".java", data, "protocol/" ~ game);
			}
			string sections = "package sul.protocol." ~ game ~ ";\n\n";
			sections ~= "import java.util.Collections;\nimport java.util.Map;\nimport java.util.HashMap;\n\n";
			sections ~= "import sul.utils.Packet;\n\n";
			sections ~= "public final class Packets {\n\n";
			sections ~= "\tprivate Packets() {}\n\n";
			foreach(section ; prs.data.sections) {
				sections ~= "\tpublic static final Map<Integer, Class<? extends Packet>> " ~ section.name.toUpper ~ ";\n\n";
			}
			sections ~= "\tstatic {\n\n";
			foreach(section ; prs.data.sections) {
				immutable sectionName = section.name.replace("_", "");
				sections ~= "\t\tHashMap<Integer, Class<? extends Packet>> " ~ sectionName ~ " = new HashMap<Integer, Class<? extends Packet>>();\n";
				mkdirRecurse("../src/java/sul/protocol/" ~ game ~ "/" ~ sectionName);
				foreach(packet ; section.packets) {
					sections ~= "\t\t" ~ sectionName ~ ".put(" ~ packet.id.to!string ~ ", sul.protocol." ~ game ~ "." ~ sectionName ~ "." ~ toPascalCase(packet.name) ~ ".class);\n";
					string data = "package sul.protocol." ~ game ~ "." ~ sectionName ~ ";\n\n" ~ imports(packet.fields ~ (){ Field[] fields;foreach(v;packet.variants){fields~=v.fields;}return fields;}()) ~ "import sul.utils.*;\n\n";
					data ~= "public class " ~ toPascalCase(packet.name) ~ " extends Packet {\n\n";
					data ~= "\tpublic static final " ~ id ~ " ID = (" ~ id ~ ")" ~ to!string(packet.id) ~ ";\n\n";
					data ~= "\tpublic static final boolean CLIENTBOUND = " ~ to!string(packet.clientbound) ~ ";\n";
					data ~= "\tpublic static final boolean SERVERBOUND = " ~ to!string(packet.serverbound) ~ ";\n\n";
					data ~= "\t@Override\n";
					data ~= "\tpublic int getId() {\n";
					data ~= "\t\treturn ID;\n";
					data ~= "\t}\n\n";
					writeFields(data, "\t", toPascalCase(packet.name), packet.fields, packet.id, packet.variants.length != 0, false);
					data ~= "\tpublic static " ~ toPascalCase(packet.name) ~ " fromBuffer(byte[] buffer) {\n";
					data ~= "\t\t" ~ toPascalCase(packet.name) ~ " ret = new " ~ toPascalCase(packet.name) ~ "();\n";
					data ~= "\t\tret.decode(buffer);\n";
					data ~= "\t\treturn ret;\n";
					data ~= "\t}\n\n";
					createToString(data, "\t", toPascalCase(packet.name), packet.fields);
					if(packet.variantField.length) {
						string vt = "";
						foreach(field ; packet.fields) {
							if(field.name == packet.variantField) {
								vt = convert(field.type);
								break;
							}
						}
						foreach(variant ; packet.variants) {
							data ~= "\tpublic class " ~ toPascalCase(variant.name) ~ " extends Packet {\n\n";
							data ~= "\t\tpublic static final " ~ vt ~ " " ~ toUpper(packet.variantField) ~ " = (" ~ vt ~ ")" ~ variant.value ~ ";\n\n";
							data ~= "\t\t@Override\n";
							data ~= "\t\tpublic int getId() {\n";
							data ~= "\t\t\treturn ID;\n";
							data ~= "\t\t}\n\n";
							writeFields(data, "\t\t", toPascalCase(variant.name), variant.fields, -1, false, true);
							createToString(data, "\t\t", toPascalCase(packet.name) ~ "." ~ toPascalCase(variant.name), variant.fields);
							data ~= "\t}\n\n";
						}
					}
					data ~= "}";
					write("../src/java/sul/protocol/" ~ game ~ "/" ~ sectionName ~ "/" ~ toPascalCase(packet.name) ~ ".java", data, "protocol/" ~ game);
				}
				sections ~= "\t\t" ~ section.name.toUpper ~ " = Collections.unmodifiableMap(" ~ sectionName ~ ");\n\n";
			}
			sections ~= "\t}\n\n}";
			write("../src/java/sul/protocol/" ~ game ~ "/Packets.java", sections);

			// metadata
			auto m = game in metadatas;
			string data = "package sul.metadata;\n\nimport java.nio.charset.StandardCharsets;\n\nimport sul.utils.*;\n\n";
			data ~= "@SuppressWarnings(\"unused\")\n";
			data ~= "public class " ~ toPascalCase(game) ~ " extends Stream {\n\n";
			if(m) {
				//TODO variables
				//TODO length
				data ~= "\t@Override\n\tpublic int length() {\n";
				data ~= "\t\treturn 1;\n"; // just the length or the suffix
				data ~= "\t}\n\n";
				//TODO encode
				data ~= "\t@Override\n\tpublic byte[] encode() {\n";
				// only encoding as empty
				if(m.data.length.length) data ~= "\t\t" ~ createEncoding(m.data.length, "0") ~ "\n";
				else if(m.data.suffix.length) data ~= "\t\t" ~ createEncoding("ubyte", "(byte)" ~ m.data.suffix) ~ "\n";
				data ~= "\t\treturn this.getBuffer();\n";
				data ~= "\t}\n\n";
				//TODO decode
				data ~= "\t@Override\n\tpublic void decode(byte[] buffer) {\n";
				// decoding but not saving
				data ~= "\t\tbyte metadata;\n";
				if(m.data.length.length) {
					data ~= "\t\t" ~ createDecoding(m.data.length, "int length") ~ "\n";
					data ~= "\t\twhile(length-- > 0) {\n";
					data ~= "\t\t\t" ~ createDecoding("byte", "metadata") ~ "\n";
				} else if(m.data.suffix.length) {
					data ~= "\t\twhile(!this.eof() && (" ~ createDecoding("byte", "metadata")[0..$-1] ~ ") != (byte)" ~ m.data.suffix ~ ") {\n";
				}
				data ~= "\t\t\tswitch(" ~ createDecoding("byte", "")[1..$-1] ~ ") {\n";
				foreach(type ; m.data.types) {
					data ~= "\t\t\t\tcase " ~ type.id.to!string ~ ":\n";
					data ~= "\t\t\t\t\t" ~ convert(type.type) ~ " _" ~ type.id.to!string ~ ";\n";
					data ~= "\t\t\t\t\t" ~ createDecoding(type.type, "_" ~ type.id.to!string, type.endianness) ~ "\n";
					data ~= "\t\t\t\t\tbreak;\n";
				}
				data ~= "\t\t\t\tdefault: break;\n";
				data ~= "\t\t\t}\n";
				data ~= "\t\t}\n";
				data ~= "\t}\n\n";
			} else {
				// dummy class
				data ~= "\t@Override\n\tpublic int length() {\n\t\treturn 0;\n\t}\n\n";
				data ~= "\t@Override\n\tpublic byte[] encode() {\n\t\tthrow new MetadataException(\"Metadata for " ~ game ~ " is not supported\");\n\t}\n\n";
				data ~= "\t@Override\n\tpublic void decode(byte[] buffer) {\n\t\tthrow new MetadataException(\"Metadata for " ~ game ~ " is not supported\");\n\t}\n\n";
			}
			data ~= "}";
			mkdirRecurse("../src/java/sul/metadata");
			if(usesMetadata) write("../src/java/sul/metadata/" ~ toPascalCase(game) ~ ".java", data, m ? "metadata/" ~ game : "");

		}
		
		// tuples
		string tp = "package sul.utils;\n\npublic final class Tuples {\n\n\tprivate Tuples() {}\n\n";
		foreach(t ; tuples) {
			auto spl = t.split("|");
			immutable name = capitalize(spl[0]) ~ spl[1].toUpper();
			tp ~= "\tpublic static class " ~ name ~ " {\n\n";
			tp ~= "\t\tpublic " ~ spl[0] ~ " " ~ spl[1].split("").join(", ") ~ ";\n\n";
			tp ~= "\t\tpublic " ~ name ~ "() {}\n\n";
			tp ~= "\t\tpublic " ~ name ~ "(" ~ spl[0] ~ " " ~ spl[1].split("").join(", " ~ spl[0] ~ " ") ~ ") {\n";
			foreach(c ; spl[1].split("")) {
				tp ~= "\t\t\tthis." ~ c ~ " = " ~ c ~ ";\n";
			}
			tp ~= "\t\t}\n\n";
			tp ~= "\t\t@Override\n";
			tp ~= "\t\tpublic String toString() {\n";
			tp ~= "\t\t\treturn \"" ~ capitalize(spl[0]) ~ spl[1].toUpper() ~ "(";
			foreach(i, c; spl[1].split("")) {
				tp ~= c ~ ": \" + " ~ c ~ " + \"" ~ (i != spl[1].length - 1 ? ", " : "");
			}
			tp ~= ")\";\n";
			tp ~= "\t\t}\n\n";
			tp ~= "\t}\n\n";
		}
		write("../src/java/sul/utils/Tuples.java", tp ~ "}");+/
		
	}
	
	// name conversion
	
	enum keywords = ["default"];
	
	protected override string convertName(string name) {
		return keywords.canFind(name) ? name ~ "_" : name.camelCaseLower;
	}

	// type conversion
	
	enum defaultTypes = ["boolean", "byte", "short", "int", "long", "float", "double", "String", "UUID"];
	
	enum string[string] defaultAliases = [
		"bool": "boolean",
		"ubyte": "byte",
		"ushort": "short",
		"uint": "int",
		"ulong": "long",
		"string": "String",
		"uuid": "UUID",
		"bytes": "byte[]",
		"varshort": "short",
		"varushort": "short",
		"varint": "int",
		"varuint": "int",
		"varlong": "long",
		"varulong": "long"
	];
	
	protected override string convertType(string game, string type) {
		auto end = min(cast(size_t)type.indexOf("["), cast(size_t)type.lastIndexOf("<"), type.length);
		auto t = type[0..end];
		auto e = type[end..$].replaceAll(ctRegex!`\[[0-9]{1,}\]`, "[]");
		auto a = t in defaultAliases;
		if(a) return convertType(game, *a ~ e);
		if(e.length && e[0] == '<') return toPascalCase(t) ~ toUpper(e[1..e.indexOf(">")]) ~ e[e.indexOf(">")+1..$];
		else if(defaultTypes.canFind(t)) return t ~ e;
		else if(t == "metadata") return "soupply." ~ game ~ ".Metadata";
		else return "soupply." ~ game ~ ".type." ~ toPascalCase(t) ~ e;
	}

}
