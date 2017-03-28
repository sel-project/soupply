import std.file;
import std.regex : regex, replaceAll;

void main(string[] args) {

	// read variables
	string[string] variables;
	variables["VERSION"] = cast(string)read(".version");

	// replace
	auto file = cast(string)read(args[1]);
	foreach(string index, string rep; variables) {
		file = file.replaceAll(regex(`\{\{` ~ index ~ `\}\}`), rep);
	}
	write(args[2], file);

}
