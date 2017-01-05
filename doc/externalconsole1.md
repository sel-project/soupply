# External Console 1

Protocol used by SEL to communicate with external sources using TCP or web sockets.

## Encoding

--------

## Packets

Section | Packets
---|:---:
[Login](#login) | 3
[Status](#status) | 3
[Play](#play) | 3

### Login

Name | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Auth Credentials](#auth-credentials) | 0 | 0 | ✓ | 
[Auth](#auth) | 1 | 1 |  | ✓
[Welcome](#welcome) | 2 | 2 | ✓ | 

#### Auth Credentials

 | | | 
---|---|---
protocol | ubyte | Protocol used by the server. If the client uses a different one it should close the connection without sending any packet.
hashAlgorithm | string | Algorithm used by the server to match the the hash. If empty no hashing is done and the password is sent raw.
payload | ubyte[16] | Payload to add to the password encoded as UTF-8 (if hashAlgorithm is not empty) before hashing it.

#### Auth

 | | | 
---|---|---
hash | ubyte[] | 

#### Welcome

 | | | 
---|---|---
status | ubyte | 

##### Variants:

**Field:** status





--

### Status

Name | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Keep Alive](#keep-alive) | 0 | 0 | ✓ | ✓
[Update Nodes](#update-nodes) | 1 | 1 | ✓ | 
[Update Stats](#update-stats) | 2 | 2 | ✓ | 

#### Keep Alive

 | | | 
---|---|---
count | uint | 

#### Update Nodes

 | | | 
---|---|---
action | ubyte | 
node | string | 

#### Update Stats

 | | | 
---|---|---
displayName | string | 
onlinePlayers | uint | 
maxPlayers | uint | 
uptime | uint | 
upload | uint | 
download | uint | 



--

### Play

Name | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Console Message](#console-message) | 3 | 3 | ✓ | 
[Command](#command) | 4 | 4 |  | 
[Permission Denied](#permission-denied) | 5 | 5 | ✓ | 

#### Console Message

 | | | 
---|---|---
node | string | Name of the node that has created the log or an empty string if the log has been created by the hub or by a server implementation that isn&apos;t based on the hub-node structure.
timestamp | ulong | Unix timestamp in milliseconds that indicates the exact time when the log has been generated by the server.
logger | string | Name of the logger. It is the world name if the log has been generated by a world&apos;s message (like a broadcast or a chat message).
message | string | The logged message. It may contain Minecraft&apos;s formatting codes which should be translated into appropriate colours by the client-side implementation.

#### Command

 | | | 
---|---|---
command | string | Command to be executed on the server. On SEL servers it should start with a slash or a point (hub command) or a node name followed by the command (node command).

#### Permission Denied



--



--------

## Types:

#### Game

 | | | 
---|---|---
Type | ubyte | 
Protocols | uint[] | 
