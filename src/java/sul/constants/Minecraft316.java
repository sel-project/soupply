package sul.constants;

final class Minecraft316 {

	private Minecraft316() {}

	public final static class PlayerDigging {

		public final static class status {

			public final static int FINISHED_DIGGING = 2;
			public final static int DROP_ITEM_STACK = 3;
			public final static int DROP_ITEM = 4;
			public final static int SWAP_ITEM_IN_HAND = 6;
			public final static int RELEASE_ITEM = 5;
			public final static int STARTED_DIGGING = 0;
			public final static int CANCELLED_DIGGING = 1;

		}

	}

	public final static class EntityAction {

		public final static class action {

			public final static int START_ELYTRA_FLYING = 8;
			public final static int OPEN_HORSE_INVENTORY = 7;
			public final static int START_SPRINTING = 3;
			public final static int LEAVE_BED = 2;
			public final static int START_HORSE_JUMP = 5;
			public final static int STOP_HORSE_JUMP = 6;
			public final static int START_SNEAKING = 0;
			public final static int STOP_SPRINTING = 4;
			public final static int STOP_SNEAKING = 1;

		}

	}

	public final static class ClientStatus {

		public final static class action {

			public final static int REQUEST_STATS = 1;
			public final static int OPEN_INVENTORY = 2;
			public final static int RESPAWN = 0;

		}

	}

	public final static class WindowProperty {

		public final static class property {

			public final static int FIRE_ICON = 0;
			public final static int MAXIMUM_FUEL_BURN_TIME = 1;
			public final static int LEVEL_REQUIREMENT_FOR_BOTTOM_ENCHANTMENT_SLOT = 2;
			public final static int SECOND_POTION_EFFECT = 2;
			public final static int ENCHANTMENT_SEED = 3;
			public final static int REPAIR_COST = 0;
			public final static int PROGRESS_ARROW = 2;
			public final static int LEVEL_REQUIREMENT_FOR_TOP_ENCHANTMENT_SLOT = 0;
			public final static int POWER_LEVEL = 0;
			public final static int LEVEL_REQUIREMENT_FOR_MIDDLE_ENCHANTMENT_SLOT = 1;
			public final static int FIRST_POTION_EFFECT = 1;
			public final static int BREW_TIME = 0;
			public final static int MAXIMUM_PROGRESS = 3;

		}

	}

	public final static class AnimationClientbound {

		public final static class animation {

			public final static int SWING_OFFHAND = 3;
			public final static int CRITICAL_EFFECT = 4;
			public final static int SWING_MAIN_ARM = 0;
			public final static int TAKE_DAMAGE = 1;
			public final static int MAGICAL_CRITICAL_EFFECT = 5;
			public final static int LEAVE_BED = 2;

		}

	}

	public final static class SpawnGlobalEntity {

		public final static class type {

			public final static int THUNDERBOLT = 1;

		}

	}

	public final static class ScoreboardObjective {

		public final static class mode {

			public final static int REMOVE = 1;
			public final static int UPDATE = 2;
			public final static int CREATE = 0;

		}

	}

	public final static class Handshake {

		public final static class next {

			public final static int LOGIN = 2;
			public final static int STATUS = 1;

		}

	}

	public final static class Title {

		public final static class action {

			public final static int SET_SUBTITLE = 1;
			public final static int SET_TITLE = 0;
			public final static int SET_TIMES_AND_DISPLAY = 2;
			public final static int RESET = 4;
			public final static int HIDE = 3;

		}

	}

	public final static class ChangeGameState {

		public final static class value {

			public final static int BRIGHT = 0;
			public final static int DARK = 1;
			public final static int RESPAWN = 0;
			public final static int SHOW_CREDITS = 1;
			public final static int SHOW_MOVEMENT_CONTROLS = 101;
			public final static int SHOW_JUMP_CONTROLS = 102;
			public final static int SHOW_WELCOME_DEMO = 0;
			public final static int SHOW_INVENTORY_CONTROLS = 103;

		}

		public final static class reason {

			public final static int FADE_TIME = 8;
			public final static int ARROW_HITTING_PLAYER = 6;
			public final static int INVALID_BED = 0;
			public final static int END_RAINING = 1;
			public final static int EXIT_END = 4;
			public final static int ELDER_GUARDIAN_APPEARANCE = 10;
			public final static int FADE_VALUE = 7;
			public final static int DEMO_MESSAGE = 5;
			public final static int BEGIN_RAINING = 2;
			public final static int CHANGE_GAMEMODE = 3;

		}

	}

	public final static class UpdateScore {

		public final static class action {

			public final static int REMOVE = 1;
			public final static int UPDATE = 0;

		}

	}

	public final static class PlayerAbilities {

		public final static class flags {

			public final static int CREATIVE_MODE = 8;
			public final static int ALLOW_FLYING = 4;
			public final static int FLYING = 2;
			public final static int INVULNERABLE = 1;

		}

	}

	public final static class DisplayScoreboard {

		public final static class position {

			public final static int LIST = 0;
			public final static int SIDEBAR = 1;
			public final static int BELOW_NAME = 2;

		}

	}

	public final static class EntityStatus {

		public final static class status {

			public final static int HURT = 2;
			public final static int DEATH = 3;

		}

	}

	public final static class ChatMessageClientbound {

		public final static class position {

			public final static int CHAT = 0;
			public final static int SYSTEM_MESSAGE = 1;
			public final static int ABOVE_HOTBAR = 2;

		}

	}

	public final static class UseEntity {

		public final static class type {

			public final static int INTERACT_AT = 2;
			public final static int INTERACT = 0;
			public final static int ATTACK = 1;

		}

	}

	public final static class Map {

		public final static class iconType {

			public final static int FAR_AWAY_PLAYER = 8;
			public final static int WHITE_CROSS = 4;
			public final static int BLUE_SQUARE = 7;
			public final static int TEMPLE = 10;
			public final static int GREEN_ARROW = 1;
			public final static int RED_ARROW = 2;
			public final static int WHITE_CIRCLE = 6;
			public final static int MANSION = 9;
			public final static int BLUE_ARROW = 3;
			public final static int RED_POINTER = 5;
			public final static int WHITE_ARROW = 0;

		}

	}

	public final static class AnimationServerbound {

		public final static class hand {

			public final static int LEFT = 1;
			public final static int RIGHT = 0;

		}

	}

}
