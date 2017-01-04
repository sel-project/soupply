const Constants = {

	PlayerDigging: {

		status: {

			FINISHED_DIGGING: 2,
			DROP_ITEM_STACK: 3,
			DROP_ITEM: 4,
			SWAP_ITEM_IN_HAND: 6,
			RELEASE_ITEM: 5,
			STARTED_DIGGING: 0,
			CANCELLED_DIGGING: 1,

		},

	},

	EntityAction: {

		action: {

			START_ELYTRA_FLYING: 8,
			OPEN_HORSE_INVENTORY: 7,
			START_SPRINTING: 3,
			LEAVE_BED: 2,
			START_HORSE_JUMP: 5,
			STOP_HORSE_JUMP: 6,
			START_SNEAKING: 0,
			STOP_SPRINTING: 4,
			STOP_SNEAKING: 1,

		},

	},

	ClientStatus: {

		action: {

			REQUEST_STATS: 1,
			OPEN_INVENTORY: 2,
			RESPAWN: 0,

		},

	},

	WindowProperty: {

		property: {

			FIRE_ICON: 0,
			MAXIMUM_FUEL_BURN_TIME: 1,
			LEVEL_REQUIREMENT_FOR_BOTTOM_ENCHANTMENT_SLOT: 2,
			SECOND_POTION_EFFECT: 2,
			ENCHANTMENT_SEED: 3,
			REPAIR_COST: 0,
			PROGRESS_ARROW: 2,
			LEVEL_REQUIREMENT_FOR_TOP_ENCHANTMENT_SLOT: 0,
			POWER_LEVEL: 0,
			LEVEL_REQUIREMENT_FOR_MIDDLE_ENCHANTMENT_SLOT: 1,
			FIRST_POTION_EFFECT: 1,
			BREW_TIME: 0,
			MAXIMUM_PROGRESS: 3,

		},

	},

	AnimationClientbound: {

		animation: {

			SWING_OFFHAND: 3,
			CRITICAL_EFFECT: 4,
			SWING_MAIN_ARM: 0,
			TAKE_DAMAGE: 1,
			MAGICAL_CRITICAL_EFFECT: 5,
			LEAVE_BED: 2,

		},

	},

	SpawnGlobalEntity: {

		type: {

			THUNDERBOLT: 1,

		},

	},

	ScoreboardObjective: {

		mode: {

			REMOVE: 1,
			UPDATE: 2,
			CREATE: 0,

		},

	},

	Handshake: {

		next: {

			LOGIN: 2,
			STATUS: 1,

		},

	},

	Title: {

		action: {

			SET_SUBTITLE: 1,
			SET_TITLE: 0,
			SET_TIMES_AND_DISPLAY: 2,
			RESET: 4,
			HIDE: 3,

		},

	},

	ChangeGameState: {

		value: {

			BRIGHT: 0,
			DARK: 1,
			RESPAWN: 0,
			SHOW_CREDITS: 1,
			SHOW_MOVEMENT_CONTROLS: 101,
			SHOW_JUMP_CONTROLS: 102,
			SHOW_WELCOME_DEMO: 0,
			SHOW_INVENTORY_CONTROLS: 103,

		},

		reason: {

			FADE_TIME: 8,
			ARROW_HITTING_PLAYER: 6,
			INVALID_BED: 0,
			END_RAINING: 1,
			EXIT_END: 4,
			ELDER_GUARDIAN_APPEARANCE: 10,
			FADE_VALUE: 7,
			DEMO_MESSAGE: 5,
			BEGIN_RAINING: 2,
			CHANGE_GAMEMODE: 3,

		},

	},

	UpdateScore: {

		action: {

			REMOVE: 1,
			UPDATE: 0,

		},

	},

	PlayerAbilities: {

		flags: {

			CREATIVE_MODE: 8,
			ALLOW_FLYING: 4,
			FLYING: 2,
			INVULNERABLE: 1,

		},

	},

	DisplayScoreboard: {

		position: {

			LIST: 0,
			SIDEBAR: 1,
			BELOW_NAME: 2,

		},

	},

	EntityStatus: {

		status: {

			HURT: 2,
			DEATH: 3,

		},

	},

	ChatMessageClientbound: {

		position: {

			CHAT: 0,
			SYSTEM_MESSAGE: 1,
			ABOVE_HOTBAR: 2,

		},

	},

	UseEntity: {

		type: {

			INTERACT_AT: 2,
			INTERACT: 0,
			ATTACK: 1,

		},

	},

	Map: {

		iconType: {

			WHITE_CROSS: 4,
			BLUE_SQUARE: 7,
			GREEN_ARROW: 1,
			RED_ARROW: 2,
			WHITE_CIRCLE: 6,
			BLUE_ARROW: 3,
			RED_POINTER: 5,
			WHITE_ARROW: 0,

		},

	},

	AnimationServerbound: {

		hand: {

			LEFT: 1,
			RIGHT: 0,

		},

	},

}
