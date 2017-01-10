/*
 * This file has been automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generator: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/externalconsole1.xml
 */
package sul.protocol.externalconsole1.types;

import java.util.UUID;

import sul.utils.*;

/**
 * Resource usage of a node.
 */
final class NodeStats {

	/**
	 * Name of the node. Should match a name given in [Welcome.Accepted.connectedNodes](#login.welcome.accepted.connected-nodes)
	 * or one added using the UpdateNodes packet.
	 */
	public String name;

	/**
	 * Ticks per second of the node in range 0..20. If the value is less than 20, the server
	 * is lagging.
	 */
	public float tps;

	/**
	 * RAM allocated by the node in bytes.
	 * If the value is 0 the node couldn't retrieve the amount of memory allocated by its
	 * process.
	 */
	public long ram;

	/**
	 * Percentage of CPU used by the node. The value can be higher than 100 when the machine
	 * where the node is running has more than one CPU.
	 * If the value is `not a number` the node couldn't retrieve the amount of CPU used
	 * by its process.
	 */
	public float cpu;

}