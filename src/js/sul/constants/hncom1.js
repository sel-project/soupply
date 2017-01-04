const Constants = {

	RemoteCommand: {

		origin: {

			HUB: 0,
			RCON: 2,
			EXTERNAL_CONSOLE: 1,

		},

	},

	Remove: {

		reason: {

			LEFT: 0,
			KICKED: 2,
			TIMED_OUT: 1,
			TRANSFERRED: 3,

		},

	},

	Add: {

		reason: {

			FORCIBLY_TRANSFERRED: 2,
			TRANSFERRED: 1,
			FIRST_JOIN: 0,

		},

	},

	Nodes: {

		type: {

			REMOVE: 1,
			ADD: 0,

		},

	},

	UpdateList: {

		list: {

			WHITELIST: 0,
			BLACKLIST: 1,

		},

		action: {

			REMOVE: 1,
			ADD: 0,

		},

	},

}
