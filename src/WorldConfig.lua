-- WorldConfig.lua
-- Central configuration for the procedural world generator
-- v3.0 | roblox-procedural-worlds

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
WorldConfig.EVENT_BUS_DEBUG         = false  -- verbose event logging
WorldConfig.AI_ENABLED              = true   -- master switch for MobAI
WorldConfig.AI_BEHAVIOR_TREE        = true   -- use BT engine vs raw FSM
WorldConfig.AI_DIRECTOR_ENABLED     = true   -- dynamic difficulty adjustment
WorldConfig.AI_DIRECTOR_DECAY_RATE  = 0.02   -- score regression per second
WorldConfig.AI_PATHFINDING_COOLDOWN = 0.8    -- seconds between path recomputes
WorldConfig.AI_DETECT_MULTIPLIER    = 1.0    -- global detect range scale
WorldConfig.AI_DAMAGE_MULTIPLIER    = 1.0    -- global damage scale override

-- AIDirector difficulty tiers (matches AIDirector.lua TIERS)
WorldConfig.AI_DIFFICULTY_TIERS = {
	"Trivial", "Easy", "Normal", "Hard", "Extreme", "Nightmare"
}

return WorldConfig
