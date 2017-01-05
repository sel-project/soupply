# Raknet 8

Protocol used by SEL to communicate with external sources using TCP or web sockets.

## Encoding

--------

## Packets

Section | Packets
---|:---:
[Status](#status) | 2
[Login](#login) | 8
[Connected](#connected) | 6

### Status

Name | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Ping](#ping) | 1 | 1 |  | ✓
[Pong](#pong) | 28 | 1C | ✓ | 

#### Ping

 | | | 
---|---|---
pingId | long | 
magic | ubyte[16] | 

#### Pong

 | | | 
---|---|---
pingId | long | 
serverId | long | 
magic | ubyte[16] | 
status | string | 



--

### Login

Name | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Open Connection Request 1](#open-connection-request-1) | 5 | 5 |  | ✓
[Open Connection Reply 1](#open-connection-reply-1) | 6 | 6 | ✓ | 
[Open Connection Request 2](#open-connection-request-2) | 7 | 7 |  | ✓
[Open Connection Reply 2](#open-connection-reply-2) | 8 | 8 | ✓ | 
[Client Connect](#client-connect) | 9 | 9 |  | ✓
[Server Handshake](#server-handshake) | 16 | 10 | ✓ | 
[Client Handshake](#client-handshake) | 19 | 13 |  | ✓
[Client Cancel Connection](#client-cancel-connection) | 21 | 15 |  | ✓

#### Open Connection Request 1

 | | | 
---|---|---
magic | ubyte[16] | 
protocol | ubyte | 
mtu | [bytes](#bytes) | 

#### Open Connection Reply 1

 | | | 
---|---|---
magic | ubyte[16] | 
serverId | long | 
security | bool | 
mtuLength | ushort | 

#### Open Connection Request 2

 | | | 
---|---|---
magic | ubyte[16] | 
serverAddress | [address](#address) | 
mtuLength | ushort | 
clientId | long | 

#### Open Connection Reply 2

 | | | 
---|---|---
magic | ubyte[16] | 
serverId | long | 
serverAddress | [address](#address) | 
mtuLength | ushort | 
security | bool | 

#### Client Connect

 | | | 
---|---|---
clientId | long | 
pingId | long | 

#### Server Handshake

 | | | 
---|---|---
clientAddress | [address](#address) | 
mtuLength | ushort | 
systemAddresses | [address](#address)[10] | 
pingId | long | 
serverId | long | 

#### Client Handshake

 | | | 
---|---|---
clientAddress | [address](#address) | 
systemAddresses | [address](#address)[10] | 
pingId | long | 
clientId | long | 

#### Client Cancel Connection



--

### Connected

Name | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Ping](#ping) | 0 | 0 |  | ✓
[Pong](#pong) | 3 | 3 | ✓ | 
[Ack](#ack) | 192 | C0 | ✓ | ✓
[Nack](#nack) | 160 | A0 | ✓ | ✓
[Encapsulated](#encapsulated) | 132 | 84 | ✓ | ✓
[Mcpe Packet](#mcpe-packet) | 254 | FE | ✓ | ✓

#### Ping

 | | | 
---|---|---
time | long | 

#### Pong

 | | | 
---|---|---
time | long | 

#### Ack

 | | | 
---|---|---
packets | [acknowledge](#acknowledge)[] | 

#### Nack

 | | | 
---|---|---
packets | [acknowledge](#acknowledge)[] | 

#### Encapsulated

 | | | 
---|---|---
count | [triad](#triad) | 
encapsulation | [encapsulation](#encapsulation) | 

#### Mcpe Packet

 | | | 
---|---|---
packet | [bytes](#bytes) | 



--



--------

## Types:

#### Address

 | | | 
---|---|---
Type | ubyte | 
Ipv 4 | ubyte[4] | 
Ipv 6 | ubyte[16] | 
Port | ushort | 

#### Acknowledge

 | | | 
---|---|---
Unique | bool | 
First | [triad](#triad) | 
Last | [triad](#triad) | 

#### Encapsulation

 | | | 
---|---|---
Info | ubyte | 
Length | ushort | 
Message Index | [triad](#triad) | 
Order Index | [triad](#triad) | 
Order Channel | ubyte | 
Split | [split](#split) | 
Payload | [bytes](#bytes) | 

#### Split

 | | | 
---|---|---
Count | uint | 
Id | ushort | 
Order | uint | 

