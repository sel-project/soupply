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
// file created to work on linux systems
module push;

import std.algorithm : canFind;
import std.base64 : Base64;
import std.conv : to;
import std.file;
import std.json : parseJSON;
import std.process : wait, spawnShell, executeShell;
import std.regex : replaceAll, regex;
import std.stdio : writeln;
import std.string : endsWith, replace, strip, join, indexOf, lastIndexOf, toLower;
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

	wait(spawnShell("git clone https://github.com/sel-utils/" ~ lang ~ ".git " ~ lang));

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

		void[] ec;
		if(exists(lang ~ "/.editorconfig")) ec = read(lang ~ "/.editorconfig");

		void checkout(string branch, string match) {
			string protocol;
			if(branch != match) {
				protocol = match[branch.length..$];
			}
			wait(spawnShell("cd " ~ lang ~ " && git checkout " ~ branch));
			if(!exists(lang ~ "/.git/refs/heads/" ~ branch)) {
				// create new branch
				wait(spawnShell("cd " ~ lang ~ " && git checkout --orphan " ~ branch));
			} else {
				// checkout existing branch and update it
				writeln("Branch ", branch, " already exists, pulling files...");
				wait(spawnShell("cd " ~ lang ~ " && git pull"));
			}
			// delete all files but .git
			executeShell("cd " ~ lang ~ " && find . -type f -not -wholename '*.git*' -print0 | xargs -0 rm --");
			// copy .editorconfig
			if(ec.length) write(lang ~ "/.editorconfig", ec);
			// copy only files that has 'match' in the name
			auto regex_file = regex("(" ~ branch ~ ")" ~ protocol, "mi");
			auto regex_content = regex("(" ~branch ~ ")" ~ protocol ~ "((?!\\.xml))", "mi");
			foreach(string file ; dirEntries("src/" ~ lang ~ "/", SpanMode.breadth)) {
				if(file.isFile && file.toLower.indexOf(match) != -1) {
					string dest = file[("src/" ~ lang).length+1..$];
					if(protocol.length) dest = dest.replaceAll(regex_file, "$1");
					if(dest.indexOf("/") != -1) mkdirRecurse(lang ~ "/" ~ dest[0..dest.lastIndexOf("/")]);
					string content = cast(string)read(file);
					if(protocol.length) content = content.replaceAll(regex_content, "$1");
					write(lang  ~ "/" ~ dest, content);
				}
			}
			wait(spawnShell("cd " ~ lang ~ " && git add --all . && git commit -m " ~ message ~ " -m " ~ desc ~ " && git push -u \"https://${TOKEN}@github.com/sel-utils/" ~ lang ~ "\" " ~ branch));
			// go back to master
			wait(spawnShell("cd " ~ lang ~ " && git checkout master"));
		}

		// update branches using push_info.json
		foreach(game, data; parseJSON(cast(string)read("push_info.json")).object) {
			foreach(protocol ; data["protocols"].array) {
				immutable branch = game ~ protocol.integer.to!string;
				checkout(branch, branch);
			}
			checkout(game, game ~ data["latest"].integer.to!string);
		}
		
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
