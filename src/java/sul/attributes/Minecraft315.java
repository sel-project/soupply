/*
 * This file has been automatically generated by sel-utils and
 * it's released under the GNU General Public License version 3.
 *
 * Repository: https://github.com/sel-project/sel-utils
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * From: https://github.com/sel-project/sel-utils/blob/master/xml/attributes/Minecraft315.xml
 */
package sul.attributes;

public enum Minecraft315 {

	MAX_HEALTH("generic.maxHealth", 0, 1024, 20);

	ABSORPTION("generic.absorption", 0, 4, 0);

	SPEED("generic.movementSpeed", 0, 24791, 0.1);

	KNOCKBACK_RESISTANCE("generic.knockbackResistance", 0, 1, 0);

	public final String name;
	public final float min, max, def;

	Minecraft315(String name, float min, float max, float def) {
		this.name = name;
		this.min = min;
		this.max = max;
		this.def = def;
	}

}
