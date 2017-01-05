// This file has been automatically generated by sel-utils
// https://github.com/sel-project/sel-utils
module sul.attributes.minecraft210;

import std.typecons : Tuple;

alias Attribute = Tuple!(string, "name", float, "min", float, "max", float, "def");

struct Attributes {

	@disable this();

	enum maxHealth = Attribute("generic.maxHealth", 0, 1024, 20);

	enum absorption = Attribute("generic.absorption", 0, 4, 0);

	enum speed = Attribute("generic.movementSpeed", 0, 24791, 0.1);

	enum knockbackResistance = Attribute("generic.knockbackResistance", 0, 1, 0);

}