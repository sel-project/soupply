module push;

import std.algorithm : canFind;
import std.file;
import std.process : wait, spawnShell;
import std.stdio : writeln;
import std.string : endsWith, replace, strip;

		
void main(string[] args) {

	// variables that will be replaced in .template files
	string[string] variables;
	variables["VERSION"] = cast(string)read("gen/.version");

	string lang = args[1];

	string dest = lang ~ "/" ~ args[3];

	string[] exclude = args[4..$]; // exclude from comparation
	
	string message = strip(cast(string)read("message.txt"));
	string desc = strip(cast(string)read("desc.txt"));

	wait(spawnShell("git clone git://github.com/sel-utils/" ~ lang ~ " " ~ lang));

	void diff() {
	
		wait(spawnShell("rm -r " ~ dest));
		wait(spawnShell("cp -r src/" ~ lang ~ "/. " ~ dest));

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

		// add other files
		wait(spawnShell("cp -f gen/.version " ~ lang));
		wait(spawnShell("cp -f readme/" ~ lang ~ ".md " ~ lang ~ "/README.md"));

		// push
		wait(spawnShell(`cd ` ~ lang ~ ` && git add --all . && git commit -m "` ~ message ~ `" -m "` ~ desc ~ `" && git push "https://${TOKEN}@github.com/sel-utils/` ~ lang ~ `" master`));

		// push tags
		if(args[2] == "true") {
			wait(spawnShell(`cd ` ~ lang ~ ` && git tag -a v` ~ variables["VERSION"] ~ ` -m "` ~ message ~ `" && git push --tags "https://${TOKEN}@github.com/sel-utils/` ~ lang ~ `" master`));
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
