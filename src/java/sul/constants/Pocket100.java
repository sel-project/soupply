package sul.constants;

final class Pocket100 {

	private Pocket100() {}

	public final static class MovePlayer {

		public final static class mode {

			public final static int RESET = 1;
			public final static int NORMAL = 0;
			public final static int ROTATION = 2;

		}

	}

	public final static class PlayStatus {

		public final static class status {

			public final static int SPAWNED = 3;
			public final static int OUTDATED_SERVER = 2;
			public final static int INVALID_TENANT = 4;
			public final static int EDITION_MISMATCH = 5;
			public final static int OUTDATED_CLIENT = 1;
			public final static int OK = 0;

		}

	}

	public final static class Login {

		public final static class edition {

			public final static int EDUCATION = 1;
			public final static int CLASSIC = 0;

		}

	}

	public final static class LevelEvent {

		public final static class eventId {

			public final static int STOP_THUNDER = 3004;
			public final static int START_RAIN = 3001;
			public final static int ADD_PARTICLE = 16384;
			public final static int STOP_RAIN = 3003;
			public final static int PLAYERS_SLEEPING = 9800;
			public final static int START_THUNDER = 3002;
			public final static int SET_DATA = 4000;

		}

	}

	public final static class PlayerAction {

		public final static class action {

			public final static int STOP_BREAK = 2;
			public final static int DIMENSION_CHANGE = 13;
			public final static int START_SNEAK = 11;
			public final static int STOP_SPRINT = 10;
			public final static int JUMP = 8;
			public final static int STOP_SLEEPING = 6;
			public final static int ABORT_BREAK = 1;
			public final static int STOP_SNEAK = 12;
			public final static int START_BREAK = 0;
			public final static int START_SPRINT = 9;
			public final static int ABORT_DIMENSION_CHANGE = 14;
			public final static int RESPAWN = 7;
			public final static int STOP_GLIDING = 16;
			public final static int RELEASE_ITEM = 5;
			public final static int START_GLIDING = 15;

		}

	}

	public final static class DropItem {

		public final static class type {

			public final static int DROP = 0;

		}

	}

	public final static class MobEffect {

		public final static class eventId {

			public final static int REMOVE = 3;
			public final static int MODIFY = 2;
			public final static int ADD = 1;

		}

	}

	public final static class BossEvent {

		public final static class event {

			public final static int REMOVE = 2;
			public final static int UPDATE = 1;
			public final static int ADD = 0;

		}

	}

	public final static class EntityEvent {

		public final static class eventId {

			public final static int TAME_FAIL = 6;
			public final static int FISH_HOOK_HOOK = 13;
			public final static int DEATH_ANIMATION = 3;
			public final static int EAT_GRASS_ANIMATION = 10;
			public final static int TAME_SUCCESS = 7;
			public final static int FISH_HOOK_BUBBLES = 11;
			public final static int SHAKE_WET = 8;
			public final static int USE_ITEM = 9;
			public final static int HURT_ANIMATION = 2;
			public final static int AMBIENT_SOUND = 16;
			public final static int FISH_HOOK_TEASE = 14;
			public final static int RESPAWN = 17;
			public final static int FISH_HOOK_POSITION = 12;
			public final static int SQUID_INK_CLOUD = 15;

		}

	}

	public final static class UpdateBlock {

		public final static class flagsAndMeta {

			public final static int PRIORITY = 8;
			public final static int NOGRAPHIC = 4;
			public final static int NEIGHBOURS = 1;
			public final static int NETWORK = 2;

		}

	}

	public final static class Interact {

		public final static class action {

			public final static int HOVER = 4;
			public final static int INTERACT = 2;
			public final static int LEAVE_VEHICLE = 3;
			public final static int ATTACK = 1;

		}

	}

	public final static class Animate {

		public final static class action {

			public final static int WAKE_UP = 3;
			public final static int BREAKING = 1;

		}

	}

	public final static class ContainerSetContent {

		public final static class window {

			public final static int ARMOR = 120;
			public final static int CREATIVE = 121;
			public final static int INVENTORY = 0;

		}

	}

	public final static class AdventureSettings {

		public final static class flags {

			public final static int AUTO_JUMP = 32;
			public final static int PVP_DISABLED = 2;
			public final static int FLYING = 1024;
			public final static int MVP_DISABLED = 8;
			public final static int IMMUTABLE_WORLD = 1;
			public final static int EVP_DISABLED = 16;
			public final static int NO_CLIP = 256;
			public final static int ALLOW_FLIGHT = 64;
			public final static int PVM_DISABLED = 4;

		}

		public final static class permissions {

			public final static int OPERATOR = 1;
			public final static int AUTOMATION = 3;
			public final static int HOST = 2;
			public final static int USER = 0;
			public final static int ADMIN = 4;

		}

	}

	public final static class SetEntityLink {

		public final static class type {

			public final static int REMOVE = 1;
			public final static int ADD = 0;

		}

	}

}
