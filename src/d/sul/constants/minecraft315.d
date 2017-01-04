module sul.constants.minecraft315;

import sul.types.var;

static struct Constants {

	static struct PlayerDigging {

		static struct status {

			enum uint finishedDigging = 2;
			enum uint dropItemStack = 3;
			enum uint dropItem = 4;
			enum uint swapItemInHand = 6;
			enum uint releaseItem = 5;
			enum uint startedDigging = 0;
			enum uint cancelledDigging = 1;

		}

	}

	static struct EntityAction {

		static struct action {

			enum uint startElytraFlying = 8;
			enum uint openHorseInventory = 7;
			enum uint startSprinting = 3;
			enum uint leaveBed = 2;
			enum uint startHorseJump = 5;
			enum uint stopHorseJump = 6;
			enum uint startSneaking = 0;
			enum uint stopSprinting = 4;
			enum uint stopSneaking = 1;

		}

	}

	static struct ClientStatus {

		static struct action {

			enum uint requestStats = 1;
			enum uint openInventory = 2;
			enum uint respawn = 0;

		}

	}

	static struct WindowProperty {

		static struct property {

			enum ushort fireIcon = 0;
			enum ushort maximumFuelBurnTime = 1;
			enum ushort levelRequirementForBottomEnchantmentSlot = 2;
			enum ushort secondPotionEffect = 2;
			enum ushort enchantmentSeed = 3;
			enum ushort repairCost = 0;
			enum ushort progressArrow = 2;
			enum ushort levelRequirementForTopEnchantmentSlot = 0;
			enum ushort powerLevel = 0;
			enum ushort levelRequirementForMiddleEnchantmentSlot = 1;
			enum ushort firstPotionEffect = 1;
			enum ushort brewTime = 0;
			enum ushort maximumProgress = 3;

		}

	}

	static struct AnimationClientbound {

		static struct animation {

			enum ubyte swingOffhand = 3;
			enum ubyte criticalEffect = 4;
			enum ubyte swingMainArm = 0;
			enum ubyte takeDamage = 1;
			enum ubyte magicalCriticalEffect = 5;
			enum ubyte leaveBed = 2;

		}

	}

	static struct SpawnGlobalEntity {

		static struct type {

			enum ubyte thunderbolt = 1;

		}

	}

	static struct ScoreboardObjective {

		static struct mode {

			enum ubyte remove = 1;
			enum ubyte update = 2;
			enum ubyte create = 0;

		}

	}

	static struct Handshake {

		static struct next {

			enum uint login = 2;
			enum uint status = 1;

		}

	}

	static struct Title {

		static struct action {

			enum uint setSubtitle = 1;
			enum uint setTitle = 0;
			enum uint setTimesAndDisplay = 2;
			enum uint reset = 4;
			enum uint hide = 3;

		}

	}

	static struct ChangeGameState {

		static struct value {

			enum float bright = 0;
			enum float dark = 1;
			enum float respawn = 0;
			enum float showCredits = 1;
			enum float showMovementControls = 101;
			enum float showJumpControls = 102;
			enum float showWelcomeDemo = 0;
			enum float showInventoryControls = 103;

		}

		static struct reason {

			enum ubyte fadeTime = 8;
			enum ubyte arrowHittingPlayer = 6;
			enum ubyte invalidBed = 0;
			enum ubyte endRaining = 1;
			enum ubyte exitEnd = 4;
			enum ubyte elderGuardianAppearance = 10;
			enum ubyte fadeValue = 7;
			enum ubyte demoMessage = 5;
			enum ubyte beginRaining = 2;
			enum ubyte changeGamemode = 3;

		}

	}

	static struct UpdateScore {

		static struct action {

			enum ubyte remove = 1;
			enum ubyte update = 0;

		}

	}

	static struct PlayerAbilities {

		static struct flags {

			enum ubyte creativeMode = 8;
			enum ubyte allowFlying = 4;
			enum ubyte flying = 2;
			enum ubyte invulnerable = 1;

		}

	}

	static struct DisplayScoreboard {

		static struct position {

			enum ubyte list = 0;
			enum ubyte sidebar = 1;
			enum ubyte belowName = 2;

		}

	}

	static struct EntityStatus {

		static struct status {

			enum ubyte hurt = 2;
			enum ubyte death = 3;

		}

	}

	static struct ChatMessageClientbound {

		static struct position {

			enum ubyte chat = 0;
			enum ubyte systemMessage = 1;
			enum ubyte aboveHotbar = 2;

		}

	}

	static struct UseEntity {

		static struct type {

			enum uint interactAt = 2;
			enum uint interact = 0;
			enum uint attack = 1;

		}

	}

	static struct Map {

		static struct iconType {

			enum farAwayPlayer = 8;
			enum whiteCross = 4;
			enum blueSquare = 7;
			enum temple = 10;
			enum greenArrow = 1;
			enum redArrow = 2;
			enum whiteCircle = 6;
			enum mansion = 9;
			enum blueArrow = 3;
			enum redPointer = 5;
			enum whiteArrow = 0;

		}

	}

	static struct AnimationServerbound {

		static struct hand {

			enum uint left = 1;
			enum uint right = 0;

		}

	}

}
