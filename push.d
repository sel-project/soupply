module push;

import std.algorithm : canFind;
import std.file;
import std.process : wait, spawnShell;
import std.string : endsWith, replace;

void main(string[] args) {

	// variables that will be replaced in .template files
	string[string] variables;
	variables["VERSION"] = cast(string)read("gen/.version");

	string lang = args[1];

	string dest = lang ~ "/" ~ args[3];

	args = args[4..$]; // exclude from comparation

	wait(spawnShell("git clone git://github.com/sel-utils/" ~ lang ~ " " ~ lang));

	void diff() {

		// remove old files
		foreach(string file ; dirEntries(dest, SpanMode.breadth)) {
			if(file.isFile) remove(file);
		}

		// copy new files
		foreach(string file ; dirEntries("src/" ~ lang, SpanMode.breadth)) {
			if(file.isFile) write(dest ~ file[lang.length + 4..$], read(file));
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

		// push
		wait(spawnShell(`cd ` ~ lang ~ ` && git add --all . && git commit -m "${MESSAGE}" -m "${DESC}" && git push "https://${TOKEN}@github.com/sel-utils/` ~ lang ~ `" master`));

		// push tags
		if(args[2] == "true") {
			wait(spawnShell(`cd ` ~ lang ~ ` && git tag -a v` ~ variables["VERSION"] ~ ` -m "${MESSAGE}" && git push --tags "https://${TOKEN}@github.com/sel-utils/` ~ lang ~ `" master`));
		}

	}

	// compare files (from src/$LANG to $LANG/$DEST)
	ptrdiff_t count = 0;
	foreach(string file ; dirEntries("src/" ~ lang, SpanMode.breadth)) {
		if(file.isFile) {
			count++;
			immutable location = file[lang.length + 5..$];
			if(!args.canFind(location)) {
				if(exists(dest ~ location)) {
					if(read(file) != read(dest ~ location)) {
						return diff();
					}
				} else {
					return diff();
				}
			}
		}
	}

	// maybe some file has been added or removed
	foreach(string file ; dirEntries(dest, SpanMode.breadth)) count--;
	if(count != 0) diff();

}
