# Hncom 1

Communication between hub and nodes.

## Encoding

#### Plugin

 | | | 
---|---|---
Name | string | 
Version | string | 
#### Address

 | | | 
---|---|---
Bytes | ubyte[] | 
Port | ushort | 
#### Game

 | | | 
---|---|---
Type | ubyte | 
Protocols | uint[] | 
Motd | string | 
Port | ushort | 
#### Skin

 | | | 
---|---|---
Name | string | 
Data | ubyte[] | 
#### Log

 | | | 
---|---|---
Timestamp | ulong | 
Logger | string | 
Message | string | 
--------

## Packets

### Login

Name | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Connection](#connection) | 0 | 0 |  | ✔
[Connection Response](#connection-response) | 1 | 1 | ✔ | 
[Info](#info) | 2 | 2 | ✔ | 
[Ready](#ready) | 3 | 3 |  | ✔

#### Connection

 | | | 
---|---|---
protocol | varuint | Version of the protocol used by the client that must match the hub&apos;s one

name | string | Name of the node that will be validated by the hub.

mainNode | bool | Indicates whether the node accepts clients when they first connect to the hub or only when they are manually transferred.

#### Connection Response

 | | | 
---|---|---
protocolAccepted | bool | 

nameAccepted | bool | 

#### Info

 | | | 
---|---|---
serverId | long | 

onlineMode | bool | 

displayName | string | 

games | [game](#game)[] | 

online | varuint | 

max | varuint | 

language | string | 

acceptedLanguages | string[] | 

nodes | string[] | 

socialJson | string | 

additionalJson | string | 

#### Ready

 | | | 
---|---|---
plugins | [plugin](#plugin)[] | 



--

### Status

Name | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Players](#players) | 4 | 4 | ✔ | 
[Nodes](#nodes) | 5 | 5 | ✔ | 
[Resources Usage](#resources-usage) | 6 | 6 | ✔ | 

#### Players

 | | | 
---|---|---
online | varuint | 

max | varuint | 

#### Nodes

 | | | 
---|---|---
action | ubyte | 

node | string | 

##### Constants:

* Action

	* Add: 0
	* Remove: 1


#### Resources Usage

 | | | 
---|---|---
tps | float | 

ram | varulong | 

cpu | float | 



--

### Generic

Name | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Logs](#logs) | 7 | 7 |  | ✔
[Remote Command](#remote-command) | 8 | 8 | ✔ | 
[Update_list](#update_list) | 9 | 9 |  | ✔

#### Logs

 | | | 
---|---|---
messages | [log](#log)[] | 

#### Remote Command

 | | | 
---|---|---
origin | ubyte | 

sender | [address](#address) | 

command | string | 

##### Constants:

* Origin

	* Hub: 0
	* External Console: 1
	* Rcon: 2


#### Update_list

 | | | 
---|---|---
list | ubyte | 

action | ubyte | 

type | ubyte | 

##### Constants:

* List

	* Whitelist: 0
	* Blacklist: 1
* Action

	* Add: 0
	* Remove: 1


##### Variants:

**Field:** type





--

### Player

Name | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Add](#add) | 10 | A | ✔ | 
[Remove](#remove) | 11 | B | ✔ | 
[Kick](#kick) | 12 | C |  | ✔
[Transfer](#transfer) | 13 | D |  | ✔
[Update Language](#update-language) | 14 | E |  | ✔
[Update Display Name](#update-display-name) | 15 | F |  | ✔
[Update Latency](#update-latency) | 16 | 10 | ✔ | 
[Update Packet Loss](#update-packet-loss) | 17 | 11 | ✔ | 
[Game Packet](#game-packet) | 18 | 12 | ✔ | ✔
[Ordered Game Packet](#ordered-game-packet) | 19 | 13 |  | ✔

#### Add

 | | | 
---|---|---
hubId | varuint | 

reason | ubyte | 

protocol | varuint | 

username | string | 

displayName | [ string](# string) | 

address | [address](#address) | 

game | ubyte | 

uuid | uuid | 

skin | [skin](#skin) | 

latency | varuint | 

packetLoss | float | 

language | string | 

##### Constants:

* Reason

	* First Join: 0
	* Transferred: 1
	* Forcibly Transferred: 2


#### Remove

 | | | 
---|---|---
hubId | varuint | 

reason | ubyte | 

##### Constants:

* Reason

	* Left: 0
	* Timed Out: 1
	* Kicked: 2
	* Transferred: 3


#### Kick

 | | | 
---|---|---
hubId | varuint | 

reason | string | 

translation | bool | 

#### Transfer

 | | | 
---|---|---
hubId | varuint | 

node | string | 

#### Update Language

 | | | 
---|---|---
hubId | varuint | 

language | string | 

#### Update Display Name

 | | | 
---|---|---
hubId | varuint | 

displayName | string | 

#### Update Latency

 | | | 
---|---|---
hubId | varuint | 

latency | varuint | 

#### Update Packet Loss

 | | | 
---|---|---
hubId | varuint | 

packetLoss | float | 

#### Game Packet

 | | | 
---|---|---
hubId | varuint | 

packet | [bytes](#bytes) | 

#### Ordered Game Packet

 | | | 
---|---|---
hubId | varuint | 

order | varuint | 

packet | [bytes](#bytes) | 



--

