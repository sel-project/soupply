# Hub-Node Communication 1

Communication between hub and nodes.

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

#### Connection

Field | Type | Description
---|---|---
protocol | varuint | Version of the protocol used by the client that must match the hub's one
name | string | Name of the node that will be validated by the hub.
mainNode | bool | Indicates whether the node accepts clients when they first connect to the hub or exclusively when they are manually transferred.

#### Connection Response

Field | Type
---|---
protocolAccepted | bool
nameAccepted | bool

#### Info

Field | Type
---|---
serverId | long
onlineMode | bool
displayName | string
games | [game](#game)[]
online | varuint
max | varuint
language | string
acceptedLanguages | string[]
nodes | string[]
socialJson | string
additionalJson | string

#### Ready

Field | Type
---|---
plugins | [plugin](#plugin)[]

### Status

Packet | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Players](#players) | 4 | 4 | ✓ | 
[Nodes](#nodes) | 5 | 5 | ✓ | 
[Resources Usage](#resources-usage) | 6 | 6 | ✓ | 

#### Players

Field | Type
---|---
online | varuint
max | varuint

#### Nodes

Field | Type
---|---
action | ubyte
node | string

#### Resources Usage

Field | Type
---|---
tps | float
ram | varulong
cpu | float

### Generic

Packet | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Logs](#logs) | 7 | 7 |  | ✓
[Remote Command](#remote-command) | 8 | 8 | ✓ | 
[Update List](#update-list) | 9 | 9 |  | ✓

#### Logs

Field | Type
---|---
messages | [log](#log)[]

#### Remote Command

Field | Type
---|---
origin | ubyte
sender | [address](#address)
command | string

#### Update List

Field | Type
---|---
list | ubyte
action | ubyte
type | ubyte

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

#### Add

Field | Type
---|---
hubId | varuint
reason | ubyte
protocol | varuint
username | string
displayName | string
address | [address](#address)
game | ubyte
uuid | uuid
skin | [skin](#skin)
latency | varuint
packetLoss | float
language | string

#### Remove

Field | Type
---|---
hubId | varuint
reason | ubyte

#### Kick

Field | Type
---|---
hubId | varuint
reason | string
translation | bool

#### Transfer

Field | Type
---|---
hubId | varuint
node | string

#### Update Language

Field | Type
---|---
hubId | varuint
language | string

#### Update Display Name

Field | Type
---|---
hubId | varuint
displayName | string

#### Update Latency

Field | Type
---|---
hubId | varuint
latency | varuint

#### Update Packet Loss

Field | Type
---|---
hubId | varuint
packetLoss | float

#### Game Packet

Field | Type
---|---
hubId | varuint
packet | bytes

#### Ordered Game Packet

Field | Type
---|---
hubId | varuint
order | varuint
packet | bytes

--------

### Types

#### Plugin

Field | Type
---|---
name | string
version | string

#### Address

Internet protocol address. Could be either version 4 and 6.

Field | Type | Description
---|---|---
bytes | ubyte[] | Bytes of the address. The length may be 4 (for ipv4 addresses) or 16 (for ipv6 addresses). The byte order is always big-endian (network order).
port | ushort | Port of the address.

#### Game

Field | Type
---|---
type | ubyte
protocols | uint[]
motd | string
port | ushort

#### Skin

Field | Type
---|---
name | string
data | ubyte[]

#### Log

Field | Type
---|---
timestamp | ulong
logger | string
message | string

