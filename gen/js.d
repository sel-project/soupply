module js;

import std.ascii : newline;
import std.file : mkdir, mkdirRecurse, exists;
import std.json;
import std.path : dirSeparator;
import std.string;

import all;

void js(JSONValue[string] jsons) {
	
	mkdirRecurse("../src/js/sul");
	
	// attributes
	foreach(string game, JSONValue attributes; jsons["attributes"].object) {
		string data = `const Attributes = {` ~ newline ~ newline;
		foreach(string name, JSONValue value; attributes.object) {
			auto obj = value.object;
			data ~= `	` ~ toUpper(name) ~ `: {"name": ` ~ obj["name"].toString() ~ `, "min": ` ~ obj["min"].toString() ~ `, "max": ` ~ obj["max"].toString() ~ `, "default": ` ~ obj["default"].toString() ~ `},` ~ newline ~ newline;
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

	// creative
	foreach(string game, JSONValue creative; jsons["creative"].object) {
		string data = `const Creative = [` ~ newline ~ newline;
		foreach(JSONValue item ; creative.array) {
			auto obj = item.object;
			auto name = "name" in obj;
			auto id = "id" in obj;
			auto meta = "meta" in obj;
			auto ench = "enchantment" in obj;
			if(name && id) {
				data ~= `	{"name": ` ~ name.toString() ~ `, ` ~ 
					`"id": ` ~ id.toString() ~ `, ` ~ 
					`"meta": ` ~ (meta ? meta.toString() : "0") ~
					(ench ? `, "enchantment": {"type": ` ~ ench.object["type"].toString() ~ `, "level": ` ~ ench.object["level"].toString() ~ `}` : "") ~ `},` ~ newline;
			}
		}
		if(!exists("../src/js/sul/creative")) mkdir("../src/js/sul/creative");
		write("../src/js/sul/creative/" ~ game ~ ".js", data ~ newline ~ "]" ~ newline);
	}
	
}
