/*
 * This file has been automatically generated by sel-utils and
 * released under the GNU General Public License version 3.
 *
 * License: https://github.com/sel-project/sel-utils/blob/master/LICENSE
 * Repository: https://github.com/sel-project/sel-utils
 * Generator: https://github.com/sel-project/sel-utils/blob/master/xml/protocol/externalconsole1.xml
 */
/**
 * Protocol used to communicate with external sources using a raw TCP protocol or Web
 * Sockets.
 * 
 * <h2>Features</h2>
 * + Organized remote logs
 * + Execution of remote commands (if the server allows it)
 * + Authentication using password hashing (optional)
 * + Server's resources usage
 * + Support for the hub-node layout
 * 
 * <h2>Connecting</h2>
 * 
 * <h3>Using raw TCP sockets</h3>
 * The raw TCP protocol, also referred as "classic", uses a stream-oriented TCP connection.
 * This means that packets are not prefixed with their length and every packet's length
 * is fixed or can be calculated at runtime.
 * The connection starts with a client sending the string `classic` encoded in UTF-8
 * to the server, which replies with an AuthCredentials packet and waits for the client
 * to authenticate.
 * 
 * <h3>Using Web Sockets</h3>
 * The websocket protocol uses json packets instead of binary ones and encodes the
 * byte arrays into strings using base64.
 * 
 * <h2>Authenticating</h2>
 */
module sul.protocol.externalconsole1;

public import sul.protocol.externalconsole1.types;

public import sul.protocol.externalconsole1.login;
public import sul.protocol.externalconsole1.status;
public import sul.protocol.externalconsole1.connected;
