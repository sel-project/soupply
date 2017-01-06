# Raknet 8

Minecraft: Pocket Edition's networking protocol.

## Packets

Section | Packets
---|:---:
[Control](#control) | 3
[Unconnected](#unconnected) | 6
[Encapsulated](#encapsulated) | 7

### Control

Packet | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Ack](#ack) | 192 | C0 | ✓ | ✓
[Nack](#nack) | 160 | A0 | ✓ | ✓
[Encapsulated](#encapsulated) | 132 | 84 | ✓ | ✓

#### Ack

Field | Type
---|---
packets | [acknowledge](#acknowledge)[]

#### Nack

Field | Type
---|---
packets | [acknowledge](#acknowledge)[]

#### Encapsulated

Field | Type
---|---
count | [triad](#triad)
encapsulation | [encapsulation](#encapsulation)

### Unconnected

Packet | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Ping](#ping) | 1 | 1 |  | ✓
[Pong](#pong) | 28 | 1C | ✓ | 
[Open Connection Request 1](#open-connection-request-1) | 5 | 5 |  | ✓
[Open Connection Reply 1](#open-connection-reply-1) | 6 | 6 | ✓ | 
[Open Connection Request 2](#open-connection-request-2) | 7 | 7 |  | ✓
[Open Connection Reply 2](#open-connection-reply-2) | 8 | 8 | ✓ | 

#### Ping

Field | Type
---|---
pingId | long
magic | ubyte[16]

#### Pong

Field | Type
---|---
pingId | long
serverId | long
magic | ubyte[16]
status | string

#### Open Connection Request 1

Field | Type
---|---
magic | ubyte[16]
protocol | ubyte
mtu | bytes

#### Open Connection Reply 1

Field | Type
---|---
magic | ubyte[16]
serverId | long
security | bool
mtuLength | ushort

#### Open Connection Request 2

Field | Type
---|---
magic | ubyte[16]
serveraddress | [address](#address)
mtuLength | ushort
clientId | long

#### Open Connection Reply 2

Field | Type
---|---
magic | ubyte[16]
serverId | long
serverAddress | [address](#address)
mtuLength | ushort
security | bool

### Encapsulated

Packet | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Client Connect](#client-connect) | 9 | 9 |  | ✓
[Server Handshake](#server-handshake) | 16 | 10 | ✓ | 
[Client Handshake](#client-handshake) | 19 | 13 |  | ✓
[Client Cancel Connection](#client-cancel-connection) | 21 | 15 |  | ✓
[Ping](#ping) | 0 | 0 |  | ✓
[Pong](#pong) | 3 | 3 | ✓ | 
[Mcpe](#mcpe) | 254 | FE | ✓ | ✓

#### Client Connect

Field | Type
---|---
clientId | long
pingId | long

#### Server Handshake

Field | Type
---|---
clientAddress | [address](#address)
mtuLength | ushort
systemAddresses | [address](#address)[10]
pingId | long
serverId | long

#### Client Handshake

Field | Type
---|---
clientAddress | [address](#address)
systemAddresses | [address](#address)[10]
pingId | long
clientId | long

#### Client Cancel Connection

#### Ping

Field | Type
---|---
time | long

#### Pong

Field | Type
---|---
time | long

#### Mcpe

Field | Type
---|---
packet | bytes

--------

### Types

#### Address

Field | Type | Condition
---|---|---
type | ubyte | 
ipv4 | ubyte[4] | type==4
ipv6 | ubyte[16] | type==6
port | ushort | 

#### Acknowledge

Field | Type | Condition
---|---|---
unique | bool | 
first | [triad](#triad) | 
last | [triad](#triad) | unique==false

#### Encapsulation

Field | Type | Condition
---|---|---
info | ubyte | 
length | ushort | 
messageIndex | [triad](#triad) | (info&0x7f)>=64
orderIndex | [triad](#triad) | (info&0x7f)>=96
orderChannel | ubyte | (info&0x7f)>=96
split | [split](#split) | (info&0x10)!=0
payload | bytes | 

#### Split

Field | Type
---|---
count | uint
id | ushort
order | uint

