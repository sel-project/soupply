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
module sul.sounds;

import sul.conversion;
import sul.json;

template Sounds(string game, size_t protocol) {

	mixin(soundsEnum(cast(JSONObject)UtilsJSON!("sounds", game, protocol)));

}

// Sounds.??
private string soundsEnum(JSONObject json) {
	return "struct Sounds {}";
}
