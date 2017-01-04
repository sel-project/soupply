package sul.constants;

final class Hncom1 {

	private Hncom1() {}

	public final static class RemoteCommand {

		public final static class origin {

			public final static int HUB = 0;
			public final static int RCON = 2;
			public final static int EXTERNAL_CONSOLE = 1;

		}

	}

	public final static class Remove {

		public final static class reason {

			public final static int LEFT = 0;
			public final static int KICKED = 2;
			public final static int TIMED_OUT = 1;
			public final static int TRANSFERRED = 3;

		}

	}

	public final static class Add {

		public final static class reason {

			public final static int FORCIBLY_TRANSFERRED = 2;
			public final static int TRANSFERRED = 1;
			public final static int FIRST_JOIN = 0;

		}

	}

	public final static class Nodes {

		public final static class type {

			public final static int REMOVE = 1;
			public final static int ADD = 0;

		}

	}

	public final static class UpdateList {

		public final static class list {

			public final static int WHITELIST = 0;
			public final static int BLACKLIST = 1;

		}

		public final static class action {

			public final static int REMOVE = 1;
			public final static int ADD = 0;

		}

	}

}
