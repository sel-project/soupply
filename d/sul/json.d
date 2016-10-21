module sul.json;

import std.conv : ConvException, to;

enum JsonType {

	object,
	array,
	string,
	integer,
	floating,
	boolean

}

public string minimize(string input) {
	
	string op = "";
	
	bool isstring = false;
	bool isbackslash = false;
	
	foreach(char c ; input) {
		if(!isbackslash && c == '"') {
			isstring ^= true;
		}
		if(isstring || (c == '"' || c == '=' || c == '.' || c == '{' || c == '}' || c == '[' || c == ']' || c == ':' || c == ',' || c == '+' || c == '-' || c == 'e' || c == 'E' || c == 'n' || c == 'u' || c == 'l' || c == 'f' || c == 'a' || c == 's' || c == 't' || c== 'r' || (c >= '0' && c <= '9'))) {
			op ~= c;
		}
		if(isbackslash) {
			isbackslash = false;
		} else if(c == '\\') {
			isbackslash = true;
		}
	}
	
	return op;
	
}

public const(JSON) parseJSON(string json) {
	
	if(json.length >= 2 && json[0] == '{' && json[$-1] == '}') {
		
		json = json[1..$-1];
		
		string[] keys;
		const(JSON)[] values;

		while(json.length > 0) {
			
			string key = readString(json);
			
			if(json[0] == ':') {
				json = json[1..$];
				bool found = false;
				size_t comma = nextComma(json, found);
				keys ~= key;
				values = values ~ parseJSON(json[0..comma-(found ? 1 : 0)]);
				json = json[comma..$];
			}
			
		}
		
		return new JSONObject(keys, values);
		
	}
	
	if(json.length >= 2 && json[0] == '[' && json[$-1] == ']') {
		
		json = json[1..$-1];
		
		const(JSON)[] ret;
		
		while(json.length > 0) {
			
			bool found = false;
			size_t comma = nextComma(json, found);
			ret = ret ~ parseJSON(json[0..comma-(found ? 1 : 0)]);
			json = json[comma..$];
			
		}
		
		return new JSONArray(ret);
		
	}
	
	if(json.length >= 2 && json[0] == '"' && json[$-1] == '"') {
		
		return new JSONString(readString(json));
		
	}
	
	try {
		
		return new JSONInteger(json.to!long);
		
	} catch(ConvException) {}
	
	try {
		
		return new JSONFloating(json.to!double);
		
	} catch(ConvException) {}

	if(json == "true" || json == "false") {

		return new JSONBoolean(json == "true");

	}
	
	return null;
	
}

private string readString(ref string json) {
	if(json[0] != '"') throw new Exception("THAT'S NOT A STRING!");
	size_t count = 1;
	bool isbackslash = false;
	string ret = "";
	foreach(char c ; json[1..$]) {
		count++;
		if(!isbackslash && c == '"') break;
		if(!isbackslash && c == '\\') {
			isbackslash = true;
			continue;
		}
		ret ~= c;
		isbackslash = false;
	}
	json = json[count..$];
	return ret;
}

private size_t nextComma(string json, ref bool found) {
	size_t ret = 0;
	bool isstring = false;
	bool isbackslash = false;
	int arrays = 0;
	int objects = 0;
	foreach(char c ; json) {
		if(!isbackslash && c == '"') {
			isstring ^= true;
		}
		if(!isstring) {
			if(c == '[') arrays++;
			if(c == ']') arrays--;
			if(c == '{') objects++;
			if(c == '}') objects--;
		}
		ret++;
		if(!isstring && !isbackslash && c == ',' && arrays == 0 && objects == 0) {
			found = true;
			break;
		}
		if(isbackslash) {
			isbackslash = false;
		} else if(c == '\\') {
			isbackslash = true;
		}
	}
	return ret;
}

abstract class JSON {
	
	public abstract pure nothrow @property @safe @nogc const JsonType type();
	
}

class JSONOf(T, JsonType json_type) : JSON {

	public T value;

	public this() {}

	public this(T value) {
		this.value = value;
	}

	public override pure nothrow @property @safe @nogc const JsonType type() {
		return json_type;
	}

	alias value this;

}

//alias JSONObject = JSONOf!(const(JSON)[string], JsonType.object);

alias JSONArray = JSONOf!(const(JSON)[], JsonType.array);

alias JSONString = JSONOf!(string, JsonType.string);

alias JSONInteger = JSONOf!(long, JsonType.integer);

alias JSONFloating = JSONOf!(double, JsonType.floating);

alias JSONBoolean = JSONOf!(bool, JsonType.boolean);

class JSONObject : JSONArray {

	public string[] keys;

	public this() {}

	public this(string[] keys, const(JSON)[] values) {
		super(values);
		this.keys = keys;
	}

	public override pure nothrow @property @safe @nogc const JsonType type() {
		return JsonType.object;
	}

	public const(JSON)* opBinaryRight(string op)(string key) if(op == "in") {
		auto i = index(key, this.keys);
		return i >= 0 ? &this.value[i] : null;
	}

	public const(JSON) opIndex(string key) {
		return this.value[index(key, this.keys)];
	}

	public int opApply(scope int delegate(ref string, ref const(JSON)) dg) {
		int result = 0;
		foreach(size_t i, string key; this.keys) {
			result = dg(key, this.value[i]);
			if(result) break;
		}
		return result;
	}

}

private ptrdiff_t index(T)(T search, T[] array) {
	foreach(size_t i, T v; array) {
		if(search == v) return i;
	}
	return -1;
}
