# Minecraft: Pocket Edition 100

## Endianness

all: Big Endian

float: Little Endian

--------

## Packets

Section | Packets
---|:---:
[Play](#play) | 74

### Play

Packet | DEC | HEX | Clientbound | Serverbound
---|:---:|:---:|:---:|:---:
[Login](#login) | 1 | 1 |  | ✓
[Play Status](#play-status) | 2 | 2 | ✓ | 
[Server Handshake](#server-handshake) | 3 | 3 | ✓ | 
[Client Magic](#client-magic) | 4 | 4 |  | ✓
[Disconnect](#disconnect) | 5 | 5 | ✓ | 
[Batch](#batch) | 6 | 6 | ✓ | ✓
[Resource Packs Info](#resource-packs-info) | 7 | 7 | ✓ | 
[Resource Pack Client Response](#resource-pack-client-response) | 9 | 9 |  | ✓
[Text](#text) | 10 | A | ✓ | ✓
[Set Time](#set-time) | 11 | B | ✓ | 
[Start Game](#start-game) | 12 | C | ✓ | 
[Add Player](#add-player) | 13 | D | ✓ | 
[Add Entity](#add-entity) | 14 | E | ✓ | 
[Remove Entity](#remove-entity) | 15 | F | ✓ | 
[Add Item Entity](#add-item-entity) | 16 | 10 | ✓ | 
[Add Hanging Entity](#add-hanging-entity) | 17 | 11 | ✓ | 
[Take Item Entity](#take-item-entity) | 18 | 12 | ✓ | 
[Move Entity](#move-entity) | 19 | 13 | ✓ | 
[Move Player](#move-player) | 20 | 14 | ✓ | ✓
[Rider Jump](#rider-jump) | 21 | 15 | ✓ | ✓
[Remove Block](#remove-block) | 22 | 16 |  | ✓
[Update Block](#update-block) | 23 | 17 | ✓ | 
[Add Painting](#add-painting) | 24 | 18 | ✓ | 
[Explode](#explode) | 25 | 19 | ✓ | 
[Level Sound Event](#level-sound-event) | 26 | 1A | ✓ | ✓
[Level Event](#level-event) | 27 | 1B | ✓ | 
[Block Event](#block-event) | 28 | 1C | ✓ | 
[Entity Event](#entity-event) | 29 | 1D | ✓ | ✓
[Mob Effect](#mob-effect) | 30 | 1E | ✓ | 
[Update Attributes](#update-attributes) | 31 | 1F | ✓ | 
[Mob Equipment](#mob-equipment) | 32 | 20 | ✓ | ✓
[Mob Armor Equipment](#mob-armor-equipment) | 33 | 21 | ✓ | ✓
[Interact](#interact) | 34 | 22 |  | ✓
[Use Item](#use-item) | 35 | 23 |  | ✓
[Player Action](#player-action) | 36 | 24 |  | ✓
[Player Fall](#player-fall) | 37 | 25 |  | ✓
[Hurt Armor](#hurt-armor) | 38 | 26 | ✓ | 
[Set Entity Data](#set-entity-data) | 39 | 27 | ✓ | 
[Set Entity Motion](#set-entity-motion) | 40 | 28 | ✓ | 
[Set Entity Link](#set-entity-link) | 41 | 29 | ✓ | 
[Set Health](#set-health) | 42 | 2A | ✓ | 
[Set Spawn Position](#set-spawn-position) | 43 | 2B | ✓ | 
[Animate](#animate) | 44 | 2C | ✓ | ✓
[Respawn](#respawn) | 45 | 2D | ✓ | 
[Drop Item](#drop-item) | 46 | 2E |  | ✓
[Inventory Action](#inventory-action) | 47 | 2F |  | ✓
[Container Open](#container-open) | 48 | 30 | ✓ | 
[Container Close](#container-close) | 49 | 31 | ✓ | 
[Container Set Slot](#container-set-slot) | 50 | 32 | ✓ | 
[Container Set Data](#container-set-data) | 51 | 33 | ✓ | 
[Container Set Content](#container-set-content) | 52 | 34 | ✓ | 
[Crafting Data](#crafting-data) | 53 | 35 | ✓ | ✓
[Crafting Event](#crafting-event) | 54 | 36 |  | ✓
[Adventure Settings](#adventure-settings) | 55 | 37 | ✓ | ✓
[Block Entity Data](#block-entity-data) | 56 | 38 | ✓ | 
[Player Input](#player-input) | 57 | 39 |  | ✓
[Full Chunk Data](#full-chunk-data) | 58 | 3A | ✓ | 
[Set Cheats Enabled](#set-cheats-enabled) | 59 | 3B | ✓ | 
[Set Difficulty](#set-difficulty) | 60 | 3C | ✓ | 
[Change Dimension](#change-dimension) | 61 | 3D | ✓ | 
[Set Player Gametype](#set-player-gametype) | 62 | 3E | ✓ | 
[Player List](#player-list) | 63 | 3F | ✓ | 
[Spawn Experience Orb](#spawn-experience-orb) | 65 | 41 | ✓ | 
[Map Info Request](#map-info-request) | 67 | 43 |  | ✓
[Request Chunk Radius](#request-chunk-radius) | 68 | 44 |  | ✓
[Chunk Radius Updated](#chunk-radius-updated) | 69 | 45 | ✓ | 
[Item Frame Drop Item](#item-frame-drop-item) | 70 | 46 | ✓ | 
[Replace Selected Item](#replace-selected-item) | 71 | 47 |  | ✓
[Camera](#camera) | 73 | 49 | ✓ | 
[Add Item](#add-item) | 74 | 4A | ✓ | 
[Boss Event](#boss-event) | 75 | 4B | ✓ | 
[Show Credits](#show-credits) | 76 | 4C | ✓ | 
[Available Commands](#available-commands) | 77 | 4D | ✓ | 
[Command Step](#command-step) | 78 | 4E |  | ✓

* ### Login

	**ID**: 1

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* protocol

		**Type**: uint

	* edition

		**Type**: ubyte

		**Constants**:

		Name | Value
		---|:---:
		classic | 0
		education | 1

	* body

		**Type**: ubyte[]


* ### Play Status

	**ID**: 2

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* status

		**Type**: uint

		**Constants**:

		Name | Value
		---|:---:
		ok | 0
		outdatedClient | 1
		outdatedServer | 2
		spawned | 3
		invalidTenant | 4
		editionMismatch | 5


* ### Server Handshake

	**ID**: 3

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* serverPublicKey

		**Type**: string

	* token

		**Type**: ubyte[]


* ### Client Magic

	**ID**: 4

	**Clientbound**: no

	**Serverbound**: yes

* ### Disconnect

	**ID**: 5

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* hideDisconnectionScreen

		**Type**: bool

	* message

		**Type**: string


* ### Batch

	**ID**: 6

	**Clientbound**: yes

	**Serverbound**: yes

	**Fields**:

	* data

		**Type**: ubyte[]


* ### Resource Packs Info

	**ID**: 7

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* mustAccept

		**Type**: bool

	* behaviourPacks

		**Type**: [pack](#pack)[]

	* resourcePacks

		**Type**: [pack](#pack)[]


* ### Resource Pack Client Response

	**ID**: 9

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* status

		**Type**: ubyte

	* resourcePackVersion

		**Type**: ushort


* ### Text

	**ID**: 10

	**Clientbound**: yes

	**Serverbound**: yes

	**Fields**:

	* type

		**Type**: ubyte


	**Variants**:

	**Field**: type

	* Raw

		**Field's value**: 0

		**Additional Fields**:

		* message

			**Type**: string


	* Chat

		**Field's value**: 1

		**Additional Fields**:

		* sender

			**Type**: string

		* message

			**Type**: string


	* Translation

		**Field's value**: 2

		**Additional Fields**:

		* message

			**Type**: string

		* parameters

			**Type**: string[]


	* Popup

		**Field's value**: 3

		**Additional Fields**:

		* title

			**Type**: string

		* subtitle

			**Type**: string


	* Tip

		**Field's value**: 4

		**Additional Fields**:

		* message

			**Type**: string


	* System

		**Field's value**: 5

		**Additional Fields**:

		* message

			**Type**: string


	* Whisper

		**Field's value**: 6

		**Additional Fields**:

		* sender

			**Type**: string

		* message

			**Type**: string


* ### Set Time

	**ID**: 11

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* time

		**Type**: varint

	* daylightCycle

		**Type**: bool


* ### Start Game

	**ID**: 12

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* entityId

		**Type**: varlong

	* runtimeId

		**Type**: varlong

	* position

		**Type**: float\<xyz\>

	* yaw

		**Type**: float

	* pitch

		**Type**: float

	* seed

		**Type**: varint

	* dimension

		**Type**: varint

		**Constants**:

		Name | Value
		---|:---:
		overworld | 0
		nether | 1
		end | 2

	* generator

		**Type**: varint

		**Constants**:

		Name | Value
		---|:---:
		old | 0
		infinite | 1
		flat | 2

	* worldGamemode

		**Type**: varint

		**Constants**:

		Name | Value
		---|:---:
		survival | 0
		creative | 1

	* difficulty

		**Type**: varint

		**Constants**:

		Name | Value
		---|:---:
		peaceful | 0
		easy | 1
		normal | 2
		hard | 3

	* spawnPosition

		**Type**: varint\<xyz\>

	* loadedInCreative

		**Type**: bool

	* time

		**Type**: varint

	* edition

		**Type**: ubyte

		**Constants**:

		Name | Value
		---|:---:
		classic | 0
		education | 1

	* rainLevel

		**Type**: float

	* lightingLevel

		**Type**: float

	* cheatsEnabled

		**Type**: bool

	* textureRequired

		**Type**: bool

	* levelId

		**Type**: string

	* worldName

		**Type**: string


* ### Add Player

	**ID**: 13

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* uuid

		**Type**: uuid

	* username

		**Type**: string

	* entityId

		**Type**: varlong

	* runtimeId

		**Type**: varlong

	* position

		**Type**: float\<xyz\>

	* motion

		**Type**: float\<xyz\>

	* pitch

		**Type**: float

	* headYaw

		**Type**: float

	* yaw

		**Type**: float

	* heldItem

		**Type**: [slot](#slot)

	* metadata

		**Type**: bytes


* ### Add Entity

	**ID**: 14

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* entityId

		**Type**: varlong

	* runtimeId

		**Type**: varlong

	* type

		**Type**: varuint

	* position

		**Type**: float\<xyz\>

	* motion

		**Type**: float\<xyz\>

	* pitch

		**Type**: float

	* yaw

		**Type**: float

	* attributes

		**Type**: [attribute](#attribute)[]

	* metadata

		**Type**: ubyte[]

	* links

		**Type**: varlong[]


* ### Remove Entity

	**ID**: 15

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* entityId

		**Type**: varlong


* ### Add Item Entity

	**ID**: 16

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* entityId

		**Type**: varlong

	* runtimeId

		**Type**: varlong

	* item

		**Type**: [slot](#slot)

	* position

		**Type**: float\<xyz\>

	* motion

		**Type**: float\<xyz\>


* ### Add Hanging Entity

	**ID**: 17

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* entityId

		**Type**: varlong

	* runtimeId

		**Type**: varlong

	* position

		**Type**: [blockPosition](#block-position)

	* ?

		**Type**: varint


* ### Take Item Entity

	**ID**: 18

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* taken

		**Type**: varlong

	* collector

		**Type**: varlong


* ### Move Entity

	**ID**: 19

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* entityId

		**Type**: varlong

	* position

		**Type**: float\<xyz\>

	* pitch

		**Type**: float

	* headYaw

		**Type**: float

	* yaw

		**Type**: float


* ### Move Player

	**ID**: 20

	**Clientbound**: yes

	**Serverbound**: yes

	**Fields**:

	* entityId

		**Type**: varlong

	* position

		**Type**: float\<xyz\>

	* pitch

		**Type**: float

	* headYaw

		**Type**: float

	* yaw

		**Type**: float

	* animation

		**Type**: ubyte

		**Constants**:

		Name | Value
		---|:---:
		full | 0
		none | 1
		rotation | 2

	* onGround

		**Type**: bool


* ### Rider Jump

	**ID**: 21

	**Clientbound**: yes

	**Serverbound**: yes

	**Fields**:

	* rider

		**Type**: varlong


* ### Remove Block

	**ID**: 22

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* position

		**Type**: [blockPosition](#block-position)


* ### Update Block

	**ID**: 23

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* position

		**Type**: [blockPosition](#block-position)

	* block

		**Type**: varuint

	* flagsAndMeta

		**Type**: varuint

		**Constants**:

		Name | Value
		---|:---:
		neighbors | 1
		network | 2
		noGraphic | 4
		priority | 8


* ### Add Painting

	**ID**: 24

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* entityId

		**Type**: varlong

	* runtimeId

		**Type**: varlong

	* position

		**Type**: [blockPosition](#block-position)

	* direction

		**Type**: varint

	* title

		**Type**: string


* ### Explode

	**ID**: 25

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* position

		**Type**: float\<xyz\>

	* radius

		**Type**: float

	* destroyedBlocks

		**Type**: [blockPosition](#block-position)[]


* ### Level Sound Event

	**ID**: 26

	**Clientbound**: yes

	**Serverbound**: yes

	**Fields**:

	* sound

		**Type**: ubyte

	* position

		**Type**: float\<xyz\>

	* volume

		**Type**: varuint

	* pitch

		**Type**: varint

	* ?

		**Type**: bool


* ### Level Event

	**ID**: 27

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* eventId

		**Type**: varint

		**Constants**:

		Name | Value
		---|:---:
		startRain | 3001
		startThunder | 3002
		stopRain | 3003
		stopThunder | 3004
		setData | 4000
		playersSleeping | 9800

	* position

		**Type**: float\<xyz\>

	* data

		**Type**: varint


* ### Block Event

	**ID**: 28

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* position

		**Type**: [blockPosition](#block-position)

	* data

		**Type**: varint[2]


* ### Entity Event

	**ID**: 29

	**Clientbound**: yes

	**Serverbound**: yes

	**Fields**:

	* entityId

		**Type**: varlong

	* eventId

		**Type**: ubyte

		**Constants**:

		Name | Value
		---|:---:
		hurtAnimation | 2
		deathAnimation | 3
		tameFail | 6
		tameSuccess | 7
		shakeWet | 8
		useItem | 9
		eatGrassAnimation | 10
		fishHookBubbles | 11
		fishHookPosition | 12
		fishHookHook | 13
		fishHookTease | 14
		squidInkCloud | 15
		ambientSound | 16
		respawn | 17

	* ?

		**Type**: varint


* ### Mob Effect

	**ID**: 30

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* entityId

		**Type**: varlong

	* eventId

		**Type**: ubyte

		**Constants**:

		Name | Value
		---|:---:
		add | 0
		modify | 1
		remove | 2

	* effect

		**Type**: varint

	* amplifier

		**Type**: varint

	* particles

		**Type**: bool

	* duration

		**Type**: varint


* ### Update Attributes

	**ID**: 31

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* entityId

		**Type**: varlong

	* attributes

		**Type**: [attribute](#attribute)[]


* ### Mob Equipment

	**ID**: 32

	**Clientbound**: yes

	**Serverbound**: yes

	**Fields**:

	* entityId

		**Type**: varlong

	* item

		**Type**: [slot](#slot)

	* slot

		**Type**: ubyte

	* selectedSlot

		**Type**: ubyte

	* ?

		**Type**: ubyte


* ### Mob Armor Equipment

	**ID**: 33

	**Clientbound**: yes

	**Serverbound**: yes

	**Fields**:

	* entityId

		**Type**: varlong

	* armor

		**Type**: [slot](#slot)[4]


* ### Interact

	**ID**: 34

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* action

		**Type**: ubyte

		**Constants**:

		Name | Value
		---|:---:
		attack | 1
		interact | 2
		leaveVehicle | 3
		hover | 4

	* target

		**Type**: varlong


* ### Use Item

	**ID**: 35

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* blockPosition

		**Type**: [blockPosition](#block-position)

	* hotbarSlot

		**Type**: varuint

	* face

		**Type**: varint

	* facePosition

		**Type**: float\<xyz\>

	* position

		**Type**: float\<xyz\>

	* slot

		**Type**: varint

	* item

		**Type**: [slot](#slot)


* ### Player Action

	**ID**: 36

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* entityId

		**Type**: varlong

	* action

		**Type**: varint

		**Constants**:

		Name | Value
		---|:---:
		startBreak | 0
		abortBreak | 1
		stopBreak | 2
		releaseItem | 5
		stopSleeping | 6
		respawn | 7
		jump | 8
		startSprint | 9
		stopSprint | 10
		startSneak | 11
		stopSneak | 12
		dimensionChange | 13
		abortDimensionChange | 14
		startGliding | 15
		stopGliding | 16

	* position

		**Type**: [blockPosition](#block-position)

	* face

		**Type**: varint


* ### Player Fall

	**ID**: 37

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* distance

		**Type**: float


* ### Hurt Armor

	**ID**: 38

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* health

		**Type**: varint


* ### Set Entity Data

	**ID**: 39

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* entityId

		**Type**: varlong

	* metadata

		**Type**: bytes


* ### Set Entity Motion

	**ID**: 40

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* entityId

		**Type**: varlong

	* motion

		**Type**: float\<xyz\>


* ### Set Entity Link

	**ID**: 41

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* from

		**Type**: varlong

	* to

		**Type**: varlong

	* action

		**Type**: ubyte

		**Constants**:

		Name | Value
		---|:---:
		add | 0
		remove | 1


* ### Set Health

	**ID**: 42

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* health

		**Type**: varint


* ### Set Spawn Position

	**ID**: 43

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* ?

		**Type**: varint

	* position

		**Type**: [blockPosition](#block-position)

	* ?

		**Type**: bool


* ### Animate

	**ID**: 44

	**Clientbound**: yes

	**Serverbound**: yes

	**Fields**:

	* action

		**Type**: varint

		**Constants**:

		Name | Value
		---|:---:
		breaking | 1
		wakeUp | 3

	* entityId

		**Type**: varlong


* ### Respawn

	**ID**: 45

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* position

		**Type**: float\<xyz\>


* ### Drop Item

	**ID**: 46

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* action

		**Type**: ubyte

		**Constants**:

		Name | Value
		---|:---:
		drop | 0

	* item

		**Type**: [slot](#slot)


* ### Inventory Action

	**ID**: 47

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* action

		**Type**: varint

	* item

		**Type**: [slot](#slot)


* ### Container Open

	**ID**: 48

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* window

		**Type**: ubyte

	* type

		**Type**: ubyte

	* slotCount

		**Type**: varint

	* position

		**Type**: [blockPosition](#block-position)

	* entityId

		**Type**: varlong


* ### Container Close

	**ID**: 49

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* window

		**Type**: ubyte


* ### Container Set Slot

	**ID**: 50

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* window

		**Type**: ubyte

	* slot

		**Type**: varint

	* hotbarSlot

		**Type**: varint

	* item

		**Type**: [slot](#slot)

	* ?

		**Type**: ubyte


* ### Container Set Data

	**ID**: 51

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* window

		**Type**: ubyte

	* property

		**Type**: varint

	* value

		**Type**: varint


* ### Container Set Content

	**ID**: 52

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* window

		**Type**: ubyte

	* slots

		**Type**: [slot](#slot)[]

	* hotbar

		**Type**: varint[]


* ### Crafting Data

	**ID**: 53

	**Clientbound**: yes

	**Serverbound**: yes

	**Fields**:

	* recipes

		**Type**: [recipe](#recipe)[]


* ### Crafting Event

	**ID**: 54

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* window

		**Type**: ubyte

	* type

		**Type**: varint

	* uuid

		**Type**: uuid

	* input

		**Type**: [slot](#slot)[]

	* output

		**Type**: [slot](#slot)[]


* ### Adventure Settings

	**ID**: 55

	**Clientbound**: yes

	**Serverbound**: yes

	**Fields**:

	* flags

		**Type**: varuint

		**Constants**:

		Name | Value
		---|:---:
		immutableWorld | 1
		pvpDisabled | 2
		pvmDisabled | 4
		mvpDisbaled | 8
		evpDisabled | 16
		autoJump | 32
		allowFlight | 64
		noClip | 256
		flying | 1024

	* permissions

		**Type**: varuint

		**Constants**:

		Name | Value
		---|:---:
		user | 0
		operator | 1
		host | 2
		automation | 3
		admin | 4


* ### Block Entity Data

	**ID**: 56

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* position

		**Type**: [blockPosition](#block-position)

	* metadata

		**Type**: bytes


* ### Player Input

	**ID**: 57

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* motion

		**Type**: float\<xyz\>

	* flags

		**Type**: ubyte

	* ?

		**Type**: bool


* ### Full Chunk Data

	**ID**: 58

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* position

		**Type**: varint\<xz\>

	* data

		**Type**: ubyte[]

	* tiles

		**Type**: ubyte[]


* ### Set Cheats Enabled

	**ID**: 59

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* enabled

		**Type**: bool


* ### Set Difficulty

	**ID**: 60

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* difficulty

		**Type**: varuint

		**Constants**:

		Name | Value
		---|:---:
		peaceful | 0
		easy | 1
		normal | 2
		hard | 3


* ### Change Dimension

	**ID**: 61

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* dimension

		**Type**: varint

		**Constants**:

		Name | Value
		---|:---:
		overworld | 0
		nether | 1
		end | 2

	* position

		**Type**: float\<xyz\>

	* ?

		**Type**: bool


* ### Set Player Gametype

	**ID**: 62

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* gametype

		**Type**: varint

		**Constants**:

		Name | Value
		---|:---:
		survival | 0
		creative | 1


* ### Player List

	**ID**: 63

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* action

		**Type**: ubyte


	**Variants**:

	**Field**: action

	* Add

		**Field's value**: 0

		**Additional Fields**:

		* players

			**Type**: [playerList](#player-list)[]


	* Remove

		**Field's value**: 1

		**Additional Fields**:

		* players

			**Type**: uuid[]


* ### Spawn Experience Orb

	**ID**: 65

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* position

		**Type**: float\<xyz\>

	* count

		**Type**: varint


* ### Map Info Request

	**ID**: 67

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* mapId

		**Type**: varlong


* ### Request Chunk Radius

	**ID**: 68

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* radius

		**Type**: varint


* ### Chunk Radius Updated

	**ID**: 69

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* radius

		**Type**: varint


* ### Item Frame Drop Item

	**ID**: 70

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* position

		**Type**: [blockPosition](#block-position)

	* item

		**Type**: [slot](#slot)


* ### Replace Selected Item

	**ID**: 71

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* item

		**Type**: [slot](#slot)


* ### Camera

	**ID**: 73

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* entityId

		**Type**: varlong

	* runtimeId

		**Type**: varlong


* ### Add Item

	**ID**: 74

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* item

		**Type**: [slot](#slot)


* ### Boss Event

	**ID**: 75

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* entityId

		**Type**: varlong

	* eventId

		**Type**: varuint

		**Constants**:

		Name | Value
		---|:---:
		add | 0
		update | 1
		remove | 2


* ### Show Credits

	**ID**: 76

	**Clientbound**: yes

	**Serverbound**: no

* ### Available Commands

	**ID**: 77

	**Clientbound**: yes

	**Serverbound**: no

	**Fields**:

	* commands

		**Type**: string


* ### Command Step

	**ID**: 78

	**Clientbound**: no

	**Serverbound**: yes

	**Fields**:

	* command

		**Type**: string

	* overload

		**Type**: string

	* ?

		**Type**: varuint

	* ?

		**Type**: varuint

	* isOutput

		**Type**: bool

	* ?

		**Type**: varulong

	* input

		**Type**: string

	* output

		**Type**: string


--------

## Types

* ### Pack

	**Fields**:

	* id

		**Type**: string

	* version

		**Type**: string

	* size

		**Type**: ulong


* ### Block Position

	**Fields**:

	* x

		**Type**: varint

	* y

		**Type**: varuint

	* z

		**Type**: varint


* ### Slot

	**Fields**:

	* id

		**Type**: varint

	* metaAndCount

		**Type**: varint

		**When**: id>0

	* nbt

		**Type**: [slotNbt](#slot-nbt)

		**When**: id>0


* ### Attribute

	**Fields**:

	* min

		**Type**: float

	* max

		**Type**: float

	* value

		**Type**: float

	* default

		**Type**: float

	* name

		**Type**: string


* ### Skin

	**Fields**:

	* name

		**Type**: string

	* data

		**Type**: ubyte[]


* ### Player List

	**Fields**:

	* uuid

		**Type**: uuid

	* entityId

		**Type**: varlong

	* displayName

		**Type**: string

	* skin

		**Type**: [skin](#skin)


