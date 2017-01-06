# Minecraft: Pocket Edition 100

## Packets

Section | Packets
---|:---:
[Play](#play) | 2

### Play

Packet | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Login](#login) | 1 | 1 |  | ✓
[Play Status](#play-status) | 2 | 2 | ✓ | 

#### Login

Field | Type
---|---
protocol | uint
edition | ubyte
body | ubyte[]

#### Play Status

Field | Type
---|---
status | uint

--------

### Types

#### Pack

Field | Type
---|---
id | string
version | string
size | ulong

#### Block Position

Field | Type
---|---
x | varint
y | varuint
z | varint

#### Slot

Field | Type | Condition
---|---|---
id | varint | 
metaAndCount | varint | id>0
nbt | [slotNbt](#slot_nbt) | id>0

#### Attribute

Field | Type
---|---
min | float
max | float
value | float
default | float
name | string

#### Skin

Field | Type
---|---
name | string
data | ubyte[]

#### Player List

Field | Type
---|---
uuid | uuid
entityId | varlong
displayName | string
skin | [skin](#skin)

