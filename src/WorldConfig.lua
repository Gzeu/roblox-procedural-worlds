-- WorldConfig.lua
-- Central configuration for the procedural world generator
-- v3.1 | roblox-procedural-worlds

local WorldConfig = {}

-- ─────────────────────────────────────────────────────────────────
-- WORLD DIMENSIONS
-- ─────────────────────────────────────────────────────────────────
WorldConfig.WORLD_WIDTH  = 2000
WorldConfig.WORLD_HEIGHT = 800
WorldConfig.WORLD_DEPTH  = 2000

-- ─────────────────────────────────────────────────────────────────
-- CHUNK SETTINGS
-- ─────────────────────────────────────────────────────────────────
WorldConfig.CHUNK_SIZE        = 64
WorldConfig.RENDER_DISTANCE   = 5
WorldConfig.UNLOAD_DISTANCE   = 8
WorldConfig.MAX_ACTIVE_CHUNKS = 200

-- ─────────────────────────────────────────────────────────────────
-- TERRAIN NOISE
-- ─────────────────────────────────────────────────────────────────
WorldConfig.NOISE_SCALE       = 0.008
WorldConfig.NOISE_OCTAVES     = 6
WorldConfig.NOISE_PERSISTENCE = 0.5
WorldConfig.NOISE_LACUNARITY  = 2.0
WorldConfig.HEIGHT_MULTIPLIER = 120
WorldConfig.SEA_LEVEL         = 40

-- ─────────────────────────────────────────────────────────────────
-- BIOME THRESHOLDS
-- ─────────────────────────────────────────────────────────────────
WorldConfig.BIOMES = {
	{ name = "Tundra",    minTemp=0.0, maxTemp=0.2, minMoist=0.0, maxMoist=1.0 },
	{ name = "Taiga",     minTemp=0.2, maxTemp=0.4, minMoist=0.4, maxMoist=1.0 },
	{ name = "Grassland", minTemp=0.4, maxTemp=0.6, minMoist=0.2, maxMoist=0.6 },
	{ name = "Forest",    minTemp=0.4, maxTemp=0.7, minMoist=0.6, maxMoist=1.0 },
	{ name = "Desert",    minTemp=0.7, maxTemp=1.0, minMoist=0.0, maxMoist=0.2 },
	{ name = "Savanna",   minTemp=0.7, maxTemp=1.0, minMoist=0.2, maxMoist=0.5 },
	{ name = "Jungle",    minTemp=0.8, maxTemp=1.0, minMoist=0.7, maxMoist=1.0 },
	{ name = "Swamp",     minTemp=0.5, maxTemp=0.75,minMoist=0.75,maxMoist=1.0 },
	{ name = "Volcanic",  minTemp=0.9, maxTemp=1.0, minMoist=0.0, maxMoist=0.15},
	{ name = "Ocean",     minTemp=0.0, maxTemp=1.0, minMoist=0.0, maxMoist=1.0, isOcean=true },
}

-- ─────────────────────────────────────────────────────────────────
-- TREE DENSITY
-- ─────────────────────────────────────────────────────────────────
WorldConfig.TREE_DENSITY = {
	Forest=18, Jungle=28, Taiga=12, Grassland=4,
	Swamp=8, Tundra=1, Savanna=3, Desert=0, Volcanic=0,
}

-- ─────────────────────────────────────────────────────────────────
-- ORE GENERATION
-- ─────────────────────────────────────────────────────────────────
WorldConfig.ORES = {
	{ name="Coal",         rarity=0.12,  minDepth=5,   maxDepth=50  },
	{ name="Iron",         rarity=0.08,  minDepth=15,  maxDepth=80  },
	{ name="Gold",         rarity=0.03,  minDepth=40,  maxDepth=120 },
	{ name="Diamond",      rarity=0.01,  minDepth=80,  maxDepth=200 },
	{ name="MagicCrystal", rarity=0.005, minDepth=100, maxDepth=300 },
}

-- ─────────────────────────────────────────────────────────────────
-- WEATHER
-- ─────────────────────────────────────────────────────────────────
WorldConfig.WEATHER = {
	Clear=0.50, Cloudy=0.20, Rain=0.15,
	Storm=0.08, Fog=0.05,    Snow=0.02,
}

-- ─────────────────────────────────────────────────────────────────
-- DAY / NIGHT
-- ─────────────────────────────────────────────────────────────────
WorldConfig.DAY_LENGTH_SECONDS = 480
WorldConfig.SUNRISE_HOUR       = 6
WorldConfig.SUNSET_HOUR        = 20

-- ─────────────────────────────────────────────────────────────────
-- MOB SPAWNING
-- ─────────────────────────────────────────────────────────────────
WorldConfig.MOB_SPAWN_RADIUS   = 80
WorldConfig.MOB_DESPAWN_RADIUS = 150
WorldConfig.MAX_MOBS_PER_CHUNK = 6
WorldConfig.MOBS = {
	{ name="Goblin",  biomes={"Forest","Grassland"}, level=1,  spawnChance=0.4,  isHostile=true  },
	{ name="Skeleton",biomes={"Desert","Tundra"},    level=3,  spawnChance=0.3,  isHostile=true  },
	{ name="Troll",   biomes={"Swamp","Taiga"},      level=8,  spawnChance=0.15, isHostile=true  },
	{ name="Dragon",  biomes={"Volcanic"},            level=25, spawnChance=0.05, isHostile=true  },
	{ name="Deer",    biomes={"Forest","Grassland"},  level=0,  spawnChance=0.5,  isHostile=false },
	{ name="Wolf",    biomes={"Taiga","Tundra"},      level=5,  spawnChance=0.25, isHostile=true  },
}

-- ─────────────────────────────────────────────────────────────────
-- DUNGEON / VILLAGE
-- ─────────────────────────────────────────────────────────────────
WorldConfig.DUNGEON_CHANCE        = 0.004
WorldConfig.DUNGEON_MIN_ROOMS     = 6
WorldConfig.DUNGEON_MAX_ROOMS     = 18
WorldConfig.DUNGEON_ROOM_MIN_SIZE = 12
WorldConfig.DUNGEON_ROOM_MAX_SIZE = 28
WorldConfig.VILLAGE_CHANCE        = 0.006
WorldConfig.VILLAGE_MIN_BUILDINGS = 5
WorldConfig.VILLAGE_MAX_BUILDINGS = 14

-- ─────────────────────────────────────────────────────────────────
-- PLAYER
-- ─────────────────────────────────────────────────────────────────
WorldConfig.PLAYER_MAX_HP       = 100
WorldConfig.PLAYER_BASE_SPEED   = 16
WorldConfig.PLAYER_SPRINT_SPEED = 28
WorldConfig.INVENTORY_SLOTS     = 32
WorldConfig.HOTBAR_SLOTS        = 8

-- ─────────────────────────────────────────────────────────────────
-- RIVER / LOD
-- ─────────────────────────────────────────────────────────────────
WorldConfig.RIVER_CHANCE      = 0.12
WorldConfig.RIVER_MIN_LENGTH  = 200
WorldConfig.RIVER_MAX_LENGTH  = 800
WorldConfig.RIVER_WIDTH       = 10
WorldConfig.LOD_LEVELS = {
	{ distance=60,  detail="HIGH"    },
	{ distance=150, detail="MEDIUM"  },
	{ distance=300, detail="LOW"     },
	{ distance=500, detail="MINIMAL" },
}

-- ─────────────────────────────────────────────────────────────────
-- v2.5 FEATURES
-- ─────────────────────────────────────────────────────────────────
WorldConfig.TELEPORT_COOLDOWN  = 10
WorldConfig.MAX_WAYPOINTS      = 20
WorldConfig.CRAFTING_ENABLED   = true
WorldConfig.PARTICLE_POOL_SIZE = 50

-- ─────────────────────────────────────────────────────────────────
-- v3.0 AI SETTINGS
-- ─────────────────────────────────────────────────────────────────
WorldConfig.EVENT_BUS_DEBUG         = false
WorldConfig.AI_ENABLED              = true
WorldConfig.AI_BEHAVIOR_TREE        = true
WorldConfig.AI_DIRECTOR_ENABLED     = true
WorldConfig.AI_DIRECTOR_DECAY_RATE  = 0.02
WorldConfig.AI_PATHFINDING_COOLDOWN = 0.8
WorldConfig.AI_DETECT_MULTIPLIER    = 1.0
WorldConfig.AI_DAMAGE_MULTIPLIER    = 1.0
WorldConfig.AI_DIFFICULTY_TIERS     = {
	"Trivial", "Easy", "Normal", "Hard", "Extreme", "Nightmare"
}

-- ─────────────────────────────────────────────────────────────────
-- v2.5 — FACTIONS
-- ─────────────────────────────────────────────────────────────────
WorldConfig.FACTIONS = {
	{ id="Ironclad",     displayName="Ironclad Guard",  alignment="Lawful"  },
	{ id="WildHunters",  displayName="Wild Hunters",     alignment="Neutral" },
	{ id="ShadowCult",   displayName="Shadow Cult",      alignment="Chaotic" },
	{ id="MerchantGuild",displayName="Merchant Guild",   alignment="Neutral" },
}
WorldConfig.FACTION_RELATIONS = {
	Ironclad     = { WildHunters="Neutral", ShadowCult="Hostile",  MerchantGuild="Allied"  },
	WildHunters  = { Ironclad="Neutral",    ShadowCult="Neutral",  MerchantGuild="Neutral" },
	ShadowCult   = { Ironclad="Hostile",    WildHunters="Neutral", MerchantGuild="Hostile" },
	MerchantGuild= { Ironclad="Allied",     WildHunters="Neutral", ShadowCult="Hostile"   },
}

-- ─────────────────────────────────────────────────────────────────
-- v2.5 — CLAN
-- ─────────────────────────────────────────────────────────────────
WorldConfig.MAX_CLAN_MEMBERS = 20

-- ─────────────────────────────────────────────────────────────────
-- v2.5 — DAILY REWARDS
-- ─────────────────────────────────────────────────────────────────
WorldConfig.DAILY_REWARD_STREAK = {
	[1] = { gold=50,   xp=100 },
	[2] = { gold=60,   xp=120 },
	[3] = { gold=75,   xp=150 },
	[4] = { gold=90,   xp=180 },
	[5] = { gold=110,  xp=220, bonus="HealthPotion" },
	[6] = { gold=130,  xp=260 },
	[7] = { gold=200,  xp=500, bonus="MagicCrystal" },
}

-- ─────────────────────────────────────────────────────────────────
-- v2.6 — ECONOMY
-- ─────────────────────────────────────────────────────────────────
WorldConfig.STARTING_GOLD = 100
WorldConfig.SHOP_ITEMS = {
	{ id="HealthPotion",  buy=30,  sell=12  },
	{ id="IronSword",     buy=150, sell=60  },
	{ id="MagicCrystal",  buy=500, sell=200 },
	{ id="Coal",          buy=5,   sell=2   },
	{ id="Gold",          buy=40,  sell=15  },
	{ id="Diamond",       buy=800, sell=350 },
}

-- ─────────────────────────────────────────────────────────────────
-- v2.6 — SKILLS
-- ─────────────────────────────────────────────────────────────────
WorldConfig.MAX_PLAYER_LEVEL = 50
WorldConfig.XP_BASE          = 100
WorldConfig.XP_EXPONENT      = 1.4
WorldConfig.SKILL_POINTS_PER = 1
WorldConfig.SKILLS = {
	{ id="Swordsmanship", type="Passive", maxRank=5, statBonus={ meleeDmg=0.08 } },
	{ id="Archery",       type="Passive", maxRank=5, statBonus={ rangedDmg=0.10 } },
	{ id="Toughness",     type="Passive", maxRank=5, statBonus={ maxHp=20 } },
	{ id="Fireball",      type="Active",  maxRank=3, cooldown=6,  manaCost=25 },
	{ id="Blink",         type="Active",  maxRank=3, cooldown=12, manaCost=40 },
	{ id="Heal",          type="Active",  maxRank=3, cooldown=18, manaCost=35 },
}

-- ─────────────────────────────────────────────────────────────────
-- v2.7 — BOSSES
-- ─────────────────────────────────────────────────────────────────
WorldConfig.BOSS_RESPAWN_DELAY = 600  -- seconds
WorldConfig.BOSSES = {
	{
		id          = "TerrorGolem",
		displayName = "Terror Golem",
		minLevel    = 15,
		maxHp       = 5000,
		phases      = {
			{ hpThreshold=1.0, dmgMult=1.0, speed=14, ability="Smash"      },
			{ hpThreshold=0.6, dmgMult=1.4, speed=18, ability="RockShower"  },
			{ hpThreshold=0.3, dmgMult=2.0, speed=22, ability="Berserk"     },
		},
		rewardXP    = 2000,
		lootId      = "BossChest",
		spawnBiomes = { "Volcanic", "Tundra" },
	},
	{
		id          = "SwampWitch",
		displayName = "Swamp Witch",
		minLevel    = 20,
		maxHp       = 3500,
		phases      = {
			{ hpThreshold=1.0, dmgMult=1.0,  speed=12, ability="CurseAura"   },
			{ hpThreshold=0.5, dmgMult=1.6,  speed=15, ability="SummonToads"  },
			{ hpThreshold=0.25,dmgMult=2.2,  speed=18, ability="DeathWail"    },
		},
		rewardXP    = 1800,
		lootId      = "WitchRelics",
		spawnBiomes = { "Swamp", "Jungle" },
	},
}

-- ─────────────────────────────────────────────────────────────────
-- v2.5 — CRAFTING RECIPES
-- ─────────────────────────────────────────────────────────────────
WorldConfig.CRAFTING_RECIPES = {
	{
		id      = "IronSword",
		inputs  = { { item="Iron", qty=3 }, { item="Coal", qty=1 } },
		output  = { item="IronSword", qty=1 },
		level   = 1,
	},
	{
		id      = "HealthPotion",
		inputs  = { { item="Herb", qty=2 }, { item="Water", qty=1 } },
		output  = { item="HealthPotion", qty=2 },
		level   = 1,
	},
	{
		id      = "DiamondArmor",
		inputs  = { { item="Diamond", qty=8 }, { item="IronSword", qty=2 } },
		output  = { item="DiamondArmor", qty=1 },
		level   = 10,
	},
	{
		id      = "MagicStaff",
		inputs  = { { item="MagicCrystal", qty=3 }, { item="Wood", qty=2 } },
		output  = { item="MagicStaff", qty=1 },
		level   = 8,
	},
}

-- ─────────────────────────────────────────────────────────────────
-- DEBUG
-- ─────────────────────────────────────────────────────────────────
WorldConfig.Debug = false

return WorldConfig
