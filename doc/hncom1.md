# Hub-Node Communication 1

Communication between hub and nodes.

## Endianness

all: Big Endian

--------

## Packets

Section | Packets
---|:---:
[Login](#login) | 4
[Status](#status) | 3
[Generic](#generic) | 3
[Player](#player) | 10

### Login

Packet | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Connection](#connection) | 0 | 0 |  | ✓
[Connection Response](#connection-response) | 1 | 1 | ✓ | 
[Info](#info) | 2 | 2 | ✓ | 
[Ready](#ready) | 3 | 3 |  | ✓

* ### Connection

	**ID**: 0

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* protocol

		**Type**: varuint

		Version of the protocol used by the client that must match the hub's one

	* name

		**Type**: string

		Name of the node that will be validated by the hub.

	* mainNode

		**Type**: bool

		Indicates whether the node accepts clients when they first connect to the hub or exclusively when they are manually transferred.


* ### Connection Response

	**ID**: 1

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* protocolAccepted

		**Type**: bool

	* nameAccepted

		**Type**: bool


* ### Info

	**ID**: 2

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* serverId

		**Type**: long

	* onlineMode

		**Type**: bool

	* displayName

		**Type**: string

	* games

		**Type**: [game](#game)[]

	* online

		**Type**: varuint

	* max

		**Type**: varuint

	* language

		**Type**: string

	* acceptedLanguages

		**Type**: string[]

	* nodes

		**Type**: string[]

	* socialJson

		**Type**: string

	* additionalJson

		**Type**: string


* ### Ready

	**ID**: 3

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* plugins

		**Type**: [plugin](#plugin)[]


### Status

Packet | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Players](#players) | 4 | 4 | ✓ | 
[Nodes](#nodes) | 5 | 5 | ✓ | 
[Resources Usage](#resources-usage) | 6 | 6 | ✓ | 

* ### Players

	**ID**: 4

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* online

		**Type**: varuint

	* max

		**Type**: varuint


* ### Nodes

	**ID**: 5

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* action

		**Type**: ubyte

		**Constants**:

		Name | Value
		---|:---:
		add | 0
		remove | 1

	* node

		**Type**: string


* ### Resources Usage

	**ID**: 6

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* tps

		**Type**: float

	* ram

		**Type**: varulong

	* cpu

		**Type**: float


### Generic

Packet | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Logs](#logs) | 7 | 7 |  | ✓
[Remote Command](#remote-command) | 8 | 8 | ✓ | 
[Update List](#update-list) | 9 | 9 |  | ✓

* ### Logs

	**ID**: 7

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* messages

		**Type**: [log](#log)[]


* ### Remote Command

	**ID**: 8

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* origin

		**Type**: ubyte

		**Constants**:

		Name | Value
		---|:---:
		hub | 0
		externalConsole | 1
		rcon | 2

	* sender

		**Type**: [address](#address)

	* command

		**Type**: string


* ### Update List

	**ID**: 9

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* list

		**Type**: ubyte

		**Constants**:

		Name | Value
		---|:---:
		whitelist | 0
		blacklist | 1

	* action

		**Type**: ubyte

		**Constants**:

		Name | Value
		---|:---:
		add | 0
		remove | 1

	* type

		**Type**: ubyte


	**Variants**:

	**Field**: type

	* By Hub Id

		**Field's value**: 0

		**Additional Fields**:

		* hubId

			**Type**: varuint


	* By Name

		**Field's value**: 1

		**Additional Fields**:

		* username

			**Type**: string


	* By Suuid

		**Field's value**: 2

		**Additional Fields**:

		* game

			**Type**: ubyte

		* uuid

			**Type**: uuid


### Player

Packet | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Add](#add) | 10 | A | ✓ | 
[Remove](#remove) | 11 | B | ✓ | 
[Kick](#kick) | 12 | C |  | ✓
[Transfer](#transfer) | 13 | D |  | ✓
[Update Language](#update-language) | 14 | E |  | ✓
[Update Display Name](#update-display-name) | 15 | F |  | ✓
[Update Latency](#update-latency) | 16 | 10 | ✓ | 
[Update Packet Loss](#update-packet-loss) | 17 | 11 | ✓ | 
[Game Packet](#game-packet) | 18 | 12 | ✓ | ✓
[Ordered Game Packet](#ordered-game-packet) | 19 | 13 |  | ✓

* ### Add

	**ID**: 10

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* hubId

		**Type**: varuint

	* reason

		**Type**: ubyte

		**Constants**:

		Name | Value
		---|:---:
		firstJoin | 0
		transferred | 1
		forciblyTransferred | 2

	* protocol

		**Type**: varuint

	* username

		**Type**: string

	* displayName

		**Type**: string

	* address

		**Type**: [address](#address)

	* game

		**Type**: ubyte

	* uuid

		**Type**: uuid

	* skin

		**Type**: [skin](#skin)

	* latency

		**Type**: varuint

	* packetLoss

		**Type**: float

	* language

		**Type**: string


* ### Remove

	**ID**: 11

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* hubId

		**Type**: varuint

	* reason

		**Type**: ubyte

		**Constants**:

		Name | Value
		---|:---:
		left | 0
		timedOut | 1
		kicked | 2
		transferred | 3


* ### Kick

	**ID**: 12

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* hubId

		**Type**: varuint

	* reason

		**Type**: string

	* translation

		**Type**: bool


* ### Transfer

	**ID**: 13

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* hubId

		**Type**: varuint

	* node

		**Type**: string


* ### Update Language

	**ID**: 14

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* hubId

		**Type**: varuint

	* language

		**Type**: string


* ### Update Display Name

	**ID**: 15

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* hubId

		**Type**: varuint

	* displayName

		**Type**: string


* ### Update Latency

	**ID**: 16

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* hubId

		**Type**: varuint

	* latency

		**Type**: varuint


* ### Update Packet Loss

	**ID**: 17

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* hubId

		**Type**: varuint

	* packetLoss

		**Type**: float


* ### Game Packet

	**ID**: 18

	**Clientbound**: yes

	**Serverbound**: yes

	**Fields**:

	* hubId

		**Type**: varuint

	* packet

		**Type**: bytes


* ### Ordered Game Packet

	**ID**: 19

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* hubId

		**Type**: varuint

	* order

		**Type**: varuint

	* packet

		**Type**: bytes


--------

## Types

* ### Plugin

	**Fields**:

	* name

		**Type**: string

	* version

		**Type**: string


* ### Address

	Internet protocol address. Could be either version 4 and 6.

	**Fields**:

	* bytes

		**Type**: ubyte[]

		Bytes of the address. The length may be 4 (for ipv4 addresses) or 16 (for ipv6 addresses). The byte order is always big-endian (network order).

	* port

		**Type**: ushort

		Port of the address.


* ### Game

	**Fields**:

	* type

		**Type**: ubyte

	* protocols

		**Type**: uint[]

	* motd

		**Type**: string

	* port

		**Type**: ushort


* ### Skin

	**Fields**:

	* name

		**Type**: string

	* data

		**Type**: ubyte[]


* ### Log

	**Fields**:

	* timestamp

		**Type**: ulong

	* logger

		**Type**: string

	* message

		**Type**: string


