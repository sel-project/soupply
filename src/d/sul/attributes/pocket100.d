module sul.attributes.pocket100;

import std.typecons : Tuple;

alias Attribute = Tuple!(string, "name", float, "min", float, "max", float, "def");

struct Attributes {

	@disable this();

	enum speed = Attribute("minecraft:movement", 0, 24791, 0.1);

	enum knockbackResistance = Attribute("minecraft:generic.knockback_resistance", 0, 1, 0);

	enum level = Attribute("minecraft:player.level", 0, 24791, 0);

	enum experience = Attribute("minecraft:player.experience", 0, 1, 0);

	enum health = Attribute("minecraft:health", 0, 20, 20);

	enum hunger = Attribute("minecraft:player.hunger", 0, 20, 20);

	enum saturation = Attribute("minecraft:player.saturation", 0, 20, 5);

	enum absorption = Attribute("minecraft:generic.absorption", 0, 4, 0);

}
