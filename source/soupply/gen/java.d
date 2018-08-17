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

import transforms : snakeCase, camelCaseLower, camelCaseUpper;

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

				openCloseTag("artifactId", game);
				openCloseTag("packaging", "jar").nl;

				openTag("dependencies");
				openTag("dependency");
				openCloseTag("groupId", SOFTWARE);
				openCloseTag("artifactId", "util");
				openCloseTag("version", d.version_.to!string);
				closeTag();
				closeTag().nl;
				
				openTag("build");
				openCloseTag("finalName", game);
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
					} else if(aopen == -1) {
						if(field.type.indexOf("<") != -1 || conv.startsWith(SOFTWARE ~ ".") || field.type == "metadata") {
							source.stat("this." ~ name ~ " = new " ~ conv ~ "()");
						} else if(field.type == "uuid") {
							source.stat("this." ~ name ~ " = new UUID(0, 0)");
						}
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

		string endiannessOf(string type, string over="") {
			if(over.length) return camelCaseUpper(over);
			else return camelCaseUpper(info.protocol.endianness);
		}

		// encoding
		void createEncoding(CodeMaker source, string type, string name, string e="", string arrayLength="", string lengthEndianness="") {
			if(type[0] == 'u' && defaultTypes.canFind(type[1..$])) type = type[1..$];
			auto lo = type.lastIndexOf("[");
			if(lo > 0) {
				auto lc = type.lastIndexOf("]");
				immutable nt = type[0..lo];
				immutable cnt = source.convertType(nt);
				if(lo == lc - 1) {
					// dynamic array, has length
					if(arrayLength.length) {
						// custom length
						createEncoding(source, arrayLength, "(" ~ source.convertType(arrayLength) ~ ")" ~ name ~ ".length", lengthEndianness);
					} else {
						// default length
						createEncoding(source, info.protocol.arrayLength, "(" ~ source.convertType(info.protocol.arrayLength) ~ ")" ~ name ~ ".length");
					}
				}
				if(cnt == "byte") source.stat("_buffer.writeBytes(" ~ name ~ ")");
				else {
					source.block("for(" ~ cnt ~ " " ~ hash(name) ~ ":" ~ name ~ ")");
					createEncoding(source, nt, hash(name));
					source.endBlock();
				}
			} else {
				auto ts = type.lastIndexOf("<");
				if(ts > 0) {
					auto te = type.lastIndexOf(">");
					string nt = type[0..ts];
					string[] ret;
					foreach(i ; type[ts+1..te]) {
						createEncoding(source, nt, name ~ "." ~ i);
					}
				} else {
					if(type.startsWith("var")) source.stat("_buffer.write" ~ capitalize(type) ~ "(" ~ name ~ ")");
					else if(type == "string"){ source.stat("byte[] " ~ hash(name) ~ " = _buffer.convertString(" ~ name ~ ")"); createEncoding(source, "byte[]", hash(name)); }
					else if(type == "uuid") source.stat("_buffer.writeUUID(" ~ name ~ ")");
					else if(type == "bytes") source.stat("_buffer.writeBytes(" ~ name ~ ")");
					else if(type == "bool" || type == "byte") source.stat("_buffer.write" ~ capitalize(type) ~ "(" ~ name ~ ")");
					else if(defaultTypes.canFind(type)) source.stat("_buffer.write" ~ endiannessOf(type, e) ~ capitalize(type) ~ "(" ~ name ~ ")");
					else source.stat(name ~ ".encodeBody(_buffer)");
				}
			}
		}

		void createEncodings(CodeMaker source, Protocol.Field[] fields) {
			string nextc = "";
			foreach(i, field; fields) {
				if(field.condition.length && field.condition != nextc) source.block("if(" ~ camelCaseLower(field.condition) ~ ")");
				createEncoding(source, field.type, field.name=="?" ? "unknown" ~ i.to!string : convertName(field.name), field.endianness, field.length, field.lengthEndianness);
				if(field.condition.length && (i >= fields.length - 1 || fields[i+1].condition != field.condition)) source.endBlock();
				nextc = field.condition;
			}
		}

		// decoding
		void createDecoding(CodeMaker source, string type, string name, string e="", string arrayLength="", string lengthEndianness="") {
			if(type[0] == 'u' && defaultTypes.canFind(type[1..$])) type = type[1..$];
			auto lo = type.lastIndexOf("[");
			if(lo > 0) {
				auto lc = type.lastIndexOf("]");
				immutable nt = type[0..lo];
				immutable cnt = source.convertType(nt);
				if(lo == lc - 1) {
					if(arrayLength.length) {
						createDecoding(source, arrayLength, "final int " ~ hash("l" ~ name), lengthEndianness);
					} else {
						createDecoding(source, info.protocol.arrayLength, "final int " ~ hash("l" ~ name));
					}
				}
				if(cnt == "byte") {
					source.stat(name ~ " = _buffer.readBytes(" ~ (lo == lc - 1 ? hash("l" ~ name) : name ~ ".length") ~ ")");
				} else {
					if(lo == lc - 1) source.stat(name ~ " = new " ~ (cnt.indexOf("[") >= 0 ? (cnt[0..cnt.indexOf("[")] ~ "[" ~ hash("l" ~ name) ~ "][]") : (cnt ~ "[" ~ hash("l" ~ name) ~ "]")));
					source.block("for(int " ~ hash(name) ~ "=0;" ~ hash(name) ~ "<" ~ name ~ ".length;" ~ hash(name) ~ "++)");
					createDecoding(source, nt, name ~ "[" ~ hash(name) ~ "]");
					source.endBlock();
				}
			} else {
				auto ts = type.lastIndexOf("<");
				if(ts > 0) {
					auto te = type.lastIndexOf(">");
					string nt = type[0..ts];
					string[] ret;
					foreach(i ; type[ts+1..te]) {
						createDecoding(source, nt, name ~ "." ~ i);
					}
				} else {
					if(type.startsWith("var")) source.stat(name ~ " = _buffer.read" ~ capitalize(type) ~ "()");
					else if(type == "string"){ createDecoding(source, info.protocol.arrayLength, "final int " ~ hash("len" ~ name)); source.stat(name ~ " = _buffer.readString(" ~ hash("len" ~ name) ~ ")"); }
					else if(type == "uuid") source.stat(name ~ " = _buffer.readUUID()");
					else if(type == "bytes") source.stat(name ~ " = _buffer.readBytes(_buffer._buffer.length-_buffer._index)");
					else if(type == "bool" || type == "byte") source.stat(name ~ " = _buffer.read" ~ capitalize(type) ~ "()");
					else if(defaultTypes.canFind(type)) source.stat(name ~ " = _buffer.read" ~ endiannessOf(type, e) ~ capitalize(type) ~ "()");
					else source.stat(name ~ ".decodeBody(_buffer)");
				}
			}
		}

		void createDecodings(CodeMaker source, Protocol.Field[] fields) {
			string nextc = "";
			foreach(i, field; fields) {
				if(field.condition.length && field.condition != nextc) source.block("if(" ~ camelCaseLower(field.condition) ~ ")");
				createDecoding(source, field.type, field.name=="?" ? "unknown" ~ i.to!string : convertName(field.name), field.endianness, field.length, field.lengthEndianness);
				if(field.condition.length && (i >= fields.length - 1 || fields[i+1].condition != field.condition)) source.endBlock();
				nextc = field.condition;
			}
		}
		
		// generate packet class
		auto pk = make(game, "src/main/java", SOFTWARE, game, "Packet");
		with(pk) {
			
			clear(); // remove pre-generated package declaration
			stat("package " ~ SOFTWARE ~ "." ~ game).nl;
			stat("import " ~ SOFTWARE ~ ".util.Buffer");
			stat("import " ~ SOFTWARE ~ ".util.DecodeException").nl;
			block("public abstract class Packet extends " ~ SOFTWARE ~ ".util.Packet").nl;
			stat("public abstract " ~ convertType(info.protocol.id) ~ " getId()").nl;
			
			// encode
			line("@Override");
			block("public byte[] encode()");
			stat("Buffer _buffer = new Buffer()");
			createEncoding(pk, info.protocol.id, "this.getId()");
			if(info.protocol.padding) stat("_buffer.writeBytes(new byte[" ~ info.protocol.padding.to!string ~ "])");
			stat("this.encodeBody(_buffer)");
			stat("return _buffer.toByteArray()");
			endBlock().nl;
			
			// decode
			line("@Override");
			block("public void decode(byte[] data) throws DecodeException");
			stat("Buffer _buffer = new Buffer(data)");
			createDecoding(pk, info.protocol.id, "final int _id");
			if(info.protocol.padding) stat("_buffer.readBytes(" ~ info.protocol.padding.to!string ~ ")");
			stat("this.decodeBody(_buffer)");
			endBlock().nl;
			
			endBlock();
			save();
			
		}

		// types
		foreach(type ; info.protocol.types) {
			immutable clength = type.length.length != 0;
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
				block("public void encodeBody(Buffer _buffer)");
				if(clength) {
					stat("Buffer _nbuffer = new Buffer()");
					stat("this.encodeBodyImpl(_nbuffer)");
					createEncoding(t, type.length, "_nbuffer._buffer.length");
					stat("_buffer.writeBytes(_nbuffer.toByteArray())");
					endBlock().nl;
					block("private void encodeBodyImpl(Buffer _buffer)");
				}
				createEncodings(t, type.fields);
				endBlock().nl;
				// decode
				line("@Override");
				block("public void decodeBody(Buffer _buffer) throws DecodeException");
				if(clength) {
					createDecoding(t, type.length, "final int _length");
					stat("this.decodeBodyImpl(new Buffer(_buffer.readBytes(_length)))");
					endBlock().nl;
					block("private void decodeBodyImpl(Buffer _buffer) throws DecodeException");
				}
				createDecodings(t, type.fields);
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
					block("public void encodeBody(Buffer _buffer)");
					createEncodings(p, packet.fields);
					endBlock().nl;
					// decode
					line("@Override");
					block("public void decodeBody(Buffer _buffer) throws DecodeException");
					createDecodings(p, packet.fields);
					endBlock().nl;
					// static decode
					block("public static " ~ camelCaseUpper(packet.name) ~ " fromBuffer(byte[] buffer)");
					stat(camelCaseUpper(packet.name) ~ " packet = new " ~ camelCaseUpper(packet.name) ~ "()");
					stat("packet.safeDecode(buffer)");
					stat("return packet");
					endBlock().nl;
					if(packet.variantField.length) {
						block("private void encodeMainBody(Buffer _buffer)");
						stat("this.encodeBody(_buffer)");
						endBlock().nl;
						// variants
						foreach(variant ; packet.variants) {
							block("public class " ~ camelCaseUpper(variant.name) ~ " extends Type").nl;
							writeFields(p, camelCaseUpper(variant.name), variant.fields);
							// encode
							line("@Override");
							block("public void encodeBody(Buffer _buffer)");
							stat(convertName(packet.variantField) ~ " = " ~ variant.value);
							stat("encodeMainBody(_buffer)");
							createEncodings(p, variant.fields);
							endBlock().nl;
							// decode
							line("@Override");
							block("public void decodeBody(Buffer _buffer) throws DecodeException");
							createDecodings(p, variant.fields);
							endBlock().nl;
							endBlock().nl;
						}
					}
					endBlock();
					save();
				}
			}
		}

		// metadata

		// metadata values
		auto m = make(game, "src/main/java", SOFTWARE, game, "metadata/MetadataValue");
		immutable id = m.convertType(info.metadata.id);
		immutable ty = m.convertType(info.metadata.type);
		with(m) {
			clear();
			stat("package " ~ SOFTWARE ~ "." ~ game ~ ".metadata").nl;
			stat("import java.util.*");
			stat("import " ~ SOFTWARE ~ ".util.*").nl;
			block("public abstract class MetadataValue").nl;
			stat("public " ~ id ~ " id");
			stat("private " ~ ty ~ " type").nl;
			// ctor
			block("public MetadataValue(" ~ id ~ " id, " ~ ty ~ " type)");
			stat("this.id = id");
			stat("this.type = type");
			endBlock().nl;
			// encode
			block("public void encodeBody(Buffer _buffer)");
			createEncoding(m, info.metadata.id, "id");
			createEncoding(m, info.metadata.type, "type");
			endBlock().nl;
			// decode
			stat("public abstract void decodeBody(Buffer _buffer) throws DecodeException");
			endBlock();
			save();
		}
		foreach(type ; info.metadata.types) {
			immutable name = camelCaseUpper(type.name);
			auto tt = make(game, "src/main/java", SOFTWARE, game, "metadata/Metadata" ~ name);
			with(tt) {
				immutable conv = convertType(type.type);
				clear();
				stat("package " ~ SOFTWARE ~ "." ~ game ~ ".metadata").nl;
				stat("import java.util.*");
				stat("import " ~ SOFTWARE ~ ".util.*").nl;
				block("public class Metadata" ~ name ~ " extends MetadataValue").nl;
				stat("public " ~ conv ~ " value").nl;
				// ctor
				block("public Metadata" ~ name ~ "(" ~ id ~ " id, " ~ convertType(type.type) ~ " value)");
				stat("super(id, (" ~ ty ~ ")" ~ type.id.to!string ~ ")");
				stat("this.value = value");
				endBlock().nl;
				block("public Metadata" ~ name ~ "(" ~ id ~ " id)");
				if(type.type.indexOf("<") != -1 || conv.startsWith(SOFTWARE ~ ".")) stat("this(id, new " ~ convertType(type.type) ~ "())");
				else if(conv.indexOf("[") != -1) stat("this(id, new " ~ conv ~ "{})");
				else if(type.type == "bool") stat("this(id, false)");
				else if(type.type == "string") stat("this(id, \"\")");
				else stat("this(id, (" ~ convertType(type.type) ~ ")0)");
				endBlock().nl;
				// encode
				line("@Override");
				block("public void encodeBody(Buffer _buffer)");
				stat("super.encodeBody(_buffer)");
				createEncoding(tt, type.type, "value", type.endianness);
				endBlock().nl;
				// decode
				line("@Override");
				block("public void decodeBody(Buffer _buffer) throws DecodeException");
				createDecoding(tt, type.type, "value", type.endianness);
				endBlock().nl;
				endBlock();
				save();
			}
		}

		// init types
		string[string] typetable;
		foreach(type ; info.metadata.types) {
			typetable[type.name] = type.type;
		}

		// metadata
		auto mm = make(game, "src/main/java", SOFTWARE, game, "metadata/Metadata");
		with(mm) {
			clear();
			stat("package " ~ SOFTWARE ~ "." ~ game ~ ".metadata").nl;
			stat("import java.util.HashMap");
			stat("import " ~ SOFTWARE ~ ".util.*").nl;
			block("public class Metadata extends HashMap<" ~ (ty=="int" ? "Integer" : capitalize(ty)) ~ ", MetadataValue>").nl;
			// ctor
			block("public Metadata()");
			foreach(d ; info.metadata.data) {
				if(d.required) {
					stat("this.values.put(" ~ d.id.to!string ~ ", new Metadata" ~ camelCaseUpper(d.type) ~ "(" ~ d.id.to!string ~ ", (" ~ convertType(typetable[d.type]) ~ ")" ~ (d.default_.length ? d.default_ : ".init") ~ "))");
				}
			}
			endBlock().nl;
			// add
			block("public void add(MetadataValue value)");
			stat("this.put(value.id, value)");
			endBlock().nl;
			// encode
			block("public void encodeBody(Buffer _buffer)");
			if(info.metadata.length.length) createEncoding(mm, info.metadata.length, "this.size()");
			block("for(MetadataValue value : this.values())");
			stat("value.encodeBody(_buffer)");
			endBlock();
			if(info.metadata.suffix.length) createEncoding(mm, info.metadata.id, "(" ~ id ~ ")" ~ info.metadata.suffix);
			endBlock().nl;
			// decode
			block("public void decodeBody(Buffer _buffer) throws DecodeException");
			if(info.metadata.length.length) {
				createDecoding(mm, info.metadata.length, convertType(info.metadata.length) ~ " length");
				block("while(length-- > 0)");
				createDecoding(mm, info.metadata.id, "final " ~ id ~ " id");
			} else {
				// suffix
				block("while(true)");
				createDecoding(mm, info.metadata.id, "final " ~ id ~ " id");
				stat("if(id == " ~ info.metadata.suffix ~ ") break");
			}
			createDecoding(mm, info.metadata.type, "final " ~ ty ~ " type");
			stat("MetadataValue value = getMetadataValue(id, type)");
			stat("value.decodeBody(_buffer)");
			stat("this.add(value)");
			endBlock();
			endBlock().nl;
			block("public static MetadataValue getMetadataValue(" ~ id ~ " id, " ~ ty ~ " type) throws MetadataException");
			block("switch(type)");
			foreach(type ; info.metadata.types) stat("case " ~ type.id.to!string ~ ": return new Metadata" ~ camelCaseUpper(type.name) ~ "(id)");
			stat("default: throw new MetadataException(id, type)");
			endBlock();
			endBlock().nl;
			// getters and setters
			foreach(d ; info.metadata.data) {
				immutable tp = convertType(typetable[d.type]);
				// getter
				block("public " ~ tp ~ " get" ~ camelCaseUpper(d.name) ~ "()");
				stat("MetadataValue value = this.values.get(" ~ d.id.to!string ~ ")");
				stat("if(value != null && value instanceof Metadata" ~ camelCaseUpper(d.type) ~ ") return ((Metadata" ~ camelCaseUpper(d.type) ~ ")value).value");
				if(d.default_.length) stat("return (" ~ tp ~ ")" ~ d.default_);
				else if(defaultTypes[0..$-2].canFind(tp)) stat("else return 0");
				else stat("else return null");
				endBlock().nl;
				// setter
				block("public void set" ~ camelCaseUpper(d.name) ~ "(" ~ tp ~ " _value)");
				stat("MetadataValue value = this.values.get(" ~ d.id.to!string ~ ")");
				stat("if(value != null && value instanceof Metadata" ~ camelCaseUpper(d.type) ~ ") ((Metadata" ~ camelCaseUpper(d.type) ~ ")value).value = _value");
				stat("else this.values.put(" ~ d.id.to!string ~ ", new Metadata" ~ camelCaseUpper(d.type) ~ "(" ~ d.id.to!string ~ ", _value)");
				endBlock().nl;
			}
			endBlock();
			save();
		}
		
		/+
		
		// protocols
		string[] tuples;
		foreach(string game, Protocols prs; protocols) {

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
		
		+/
		
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
		else if(t == "metadata") return "soupply." ~ game ~ ".metadata.Metadata";
		else return "soupply." ~ game ~ ".type." ~ toPascalCase(t) ~ e;
	}

}
