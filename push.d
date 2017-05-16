/*
 * Copyright (c) 2017 SEL
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 */
module push;

import std.algorithm : canFind;
import std.base64 : Base64;
import std.conv : to;
import std.file;
import std.json : parseJSON;
import std.process : wait, spawnShell;
import std.stdio : writeln;
import std.string : endsWith, replace, strip, join, lastIndexOf;
import std.typetuple : TypeTuple;
		
void main(string[] args) {

	// variables that will be replaced in .template files
	string[string] variables;
	variables["VERSION"] = "1.2." ~ to!string(to!uint(strip(cast(string)read("gen/version.txt"))) - 88);

	string lang = args[1];

	if(!exists("src/" ~ lang)) return;

	string dest = lang ~ "/" ~ args[3];

	string[] exclude, include;
	auto json = parseJSON(cast(string)Base64.decode(args[4]));
	foreach(immutable t ; TypeTuple!("exclude", "include")) {
		auto array = t in json;
		if(array) {
			foreach(el ; (*array).array) {
				mixin(t) ~= el.str;
			}
		}
	}
	
	string message = "\"" ~ replace(strip(cast(string)read("message.txt")), "\"", "\\\"") ~ "\"";
	string desc = "\"" ~ replace(strip(cast(string)read("desc.txt")), "\"", "\\\"") ~ "\"";

	wait(spawnShell("git clone git://github.com/sel-utils/" ~ lang ~ " " ~ lang));

	void diff() {
	
		wait(spawnShell("rm -r " ~ dest));
		wait(spawnShell("cp -r src/" ~ lang ~ "/. " ~ dest));

		// copy additional files
		foreach(incl ; include) {
			if(incl.lastIndexOf("/") > 0) mkdirRecurse(dest ~ "/" ~ incl[0..incl.lastIndexOf("/")]);
			write(dest ~ "/" ~ incl, read("src/" ~ lang ~ "/" ~ incl));
		}

		// replace template files
		foreach(string file ; dirEntries(lang, SpanMode.breadth)) {
			if(file.isFile && file.endsWith(".template")) {
				string data = cast(string)read(file);
				foreach(var, value; variables) {
					data = data.replace("{{" ~ var ~ "}}", value);
				}
				write(file[0..$-9], data);
			}
		}

		// add/remove other files
		wait(spawnShell("cp -f readme/" ~ lang ~ ".md " ~ lang ~ "/README.md"));
		if(exists(lang ~ "/.version")) remove(lang ~ "/.version");

		string[] cmd = [
			"cd " ~ lang,
			"git add --all .",
			"git commit -m " ~ message ~ " -m " ~ desc
		];

		// create tag
		if(args[2] == "true") {
			cmd ~= "git tag -a v" ~ variables["VERSION"] ~ " -m " ~ message;
		}

		cmd ~= "git push --follow-tags \"https://${TOKEN}@github.com/sel-utils/" ~ lang ~ "\" master";

		// push (changed files and tag)
		wait(spawnShell(cmd.join(" && ")));
		
	}

	// compare files (from src/$LANG to $LANG/$DEST)
	ptrdiff_t count = 0;
	foreach(string file ; dirEntries("src/" ~ lang, SpanMode.breadth)) {
		if(file.isFile) {
			count++;
			immutable location = file[lang.length + 5..$];
			if(!exclude.canFind(location)) {
				if(exists(dest ~ "/" ~ location)) {
					if(read(file) != read(dest ~ "/" ~ location)) {
						writeln("File ", location, " is different, the repository will be updated");
						return diff();
					}
				} else {
					writeln("File ", location, " is new, the repository will be updated");
					return diff();
				}
			}
		}
	}

	// maybe some file has been added or removed
	foreach(string file ; dirEntries(dest, SpanMode.breadth)) {
		if(file.isFile) count--;
	}
	if(count != 0) {
		writeln("One ore more files have been removed, the repository will be updated");
		diff();
	}

}
