module js;

import std.ascii : newline;
import std.conv : to;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.path : dirSeparator;
import std.string;

import all;

void js(Attributes[string] attributes, JSONValue[string] jsons) {
	
	mkdirRecurse("../src/js/sul");
	
	// attributes
	foreach(string game, Attributes attrs; attributes) {
		string data = "const Attributes = {\n\n";
		foreach(attr ; attrs.data) {
			//TODO convert to snake case
			data ~= "\t" ~ toUpper(toSnakeCase(attr.id)) ~ ": {\"name\": \"" ~ attr.name ~ "\", \"min\": " ~ attr.min.to!string ~ ", \"max\": " ~ attr.max.to!string ~ ", \"default\": " ~ attr.def.to!string ~ "},\n\n";
		}
		if(!exists("../src/js/sul/attributes")) mkdir("../src/js/sul/attributes");
		write("../src/js/sul/attributes/" ~ game ~ ".js", data ~ "}" ~ newline);
	}
	
	// constants
	foreach(string game, JSONValue constants; jsons["constants"].object) {
		string data = `const Constants = {` ~ newline ~ newline;
		foreach(string name, JSONValue value; constants.object) {
			data ~= `	` ~ toPascalCase(name) ~ `: {` ~ newline ~ newline;
			foreach(string field, JSONValue v; value.object) {
				data ~= `		` ~ toCamelCase(field) ~ `: {` ~ newline ~ newline;
				foreach(string var, JSONValue content; v.object) {
					data ~= `			` ~ toUpper(var) ~ `: ` ~ content.toString() ~ `,` ~ newline;
				}
				data ~= newline ~ `		},` ~ newline ~ newline;
			}
			data ~= `	},` ~ newline ~ newline;
		}
		if(!exists("../src/js/sul/constants")) mkdir("../src/js/sul/constants");
		write("../src/js/sul/constants/" ~ game ~ ".js", data ~ "}" ~ newline);
	}
	
}
