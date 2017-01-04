module sul.attributes.minecraft315;

import std.typecons : Tuple;

alias Attribute = Tuple!(string, "name", float, "min", float, "max", float, "def");

struct Attributes {

	@disable this();

	enum absorption = Attribute("generic.absorption", 0, 4, 0);

	enum maxHealth = Attribute("generic.maxHealth", 0, 1024, 20);

	enum speed = Attribute("generic.movementSpeed", 0, 24791, 0.1);

	enum knockbackResistance = Attribute("generic.knockbackResistance", 0, 1, 0);

}
