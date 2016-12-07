/*
 * Copyright (c) 2016 SEL
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 * 
 */
module sul.particles;

import sul.conversion;
import sul.json;

template Particles(string game, size_t protocol) {

	mixin(particlesEnum(cast(JSONObject)utilsJSON!("particles", game, protocol)));

}

private string particlesEnum(JSONObject json) {
	string ret = "enum Particles : size_t{";
	if("particles" in json && json["particles"].type == JsonType.object) {
		foreach(string particle_name, const(JSON) particle; cast(JSONObject)json["particles"]) {
			if(particle.type == JsonType.integer) {
				ret ~= toCamelCase(particle_name) ~ "=" ~ to!string((cast(JSONInteger)particle).value) ~ ",";
			}
		}
	}
	return ret ~ "}";
}
