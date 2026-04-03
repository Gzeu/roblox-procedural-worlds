-- WorldConfig.lua
-- Central configuration for world generation, biomes, mobs, loot
-- v2.2.0

local WorldConfig = {}

-- ─── Chunk & Terrain ────────────────────────────────────────────────────────
WorldConfig.ChunkSize       = 64
WorldConfig.RenderDistance  = 4
WorldConfig.BaseHeight      = 20
WorldConfig.NoiseScale      = 0.015
WorldConfig.HeightAmplitude = 60

-- ─── Biomes ─────────────────────────────────────────────────────────────────
WorldConfig.Biomes = {
	{ name = "Ocean",       tempMin = -1,  tempMax = 0.1,  humMin = 0.6,  humMax = 1.0,  color = "Deep blue" },
	{ name = "Desert",      tempMin = 0.6, tempMax = 1.0,  humMin = 0.0,  humMax = 0.3,  color = "Sand yellow" },
	{ name = "Savanna",     tempMin = 0.5, tempMax = 0.9,  humMin = 0.3,  humMax = 0.6,  color = "Bright yellow" },
	{ name = "Plains",      tempMin = 0.2, tempMax = 0.6,  humMin = 0.3,  humMax = 0.6,  color = "Bright green" },
	{ name = "Forest",      tempMin = 0.1, tempMax = 0.6,  humMin = 0.5,  humMax = 0.8,  color = "Dark green" },
	{ name = "Taiga",       tempMin = -0.3,tempMax = 0.2,  humMin = 0.4,  humMax = 0.8,  color = "Medium blue" },
	{ name = "Tundra",      tempMin = -1,  tempMax = -0.2, humMin = 0.0,  humMax = 0.5,  color = "White" },
	{ name = "Swamp",       tempMin = 0.2, tempMax = 0.5,  humMin = 0.7,  humMax = 1.0,  color = "Olive" },
	{ name = "Jungle",      tempMin = 0.5, tempMax = 1.0,  humMin = 0.75, humMax = 1.0,  color = "Lime green" },
	{ name = "Mountains",   tempMin = -0.5,tempMax = 0.3,  humMin = 0.2,  humMax = 0.7,  color = "Medium stone grey" },
}

-- ─── Ores ───────────────────────────────────────────────────────────────────
WorldConfig.Ores = {
	{ name = "Coal",     color = "Really black",    freq = 0.08, minDepth =  0, maxDepth = 60, veinSize = 5 },
	{ name = "Iron",     color = "Reddish brown",   freq = 0.05, minDepth =  5, maxDepth = 50, veinSize = 4 },
	{ name = "Gold",     color = "Bright yellow",   freq = 0.02, minDepth = 15, maxDepth = 35, veinSize = 3 },
	{ name = "Diamond",  color = "Cyan",             freq = 0.01, minDepth = 25, maxDepth = 30, veinSize = 2 },
	{ name = "Emerald",  color = "Bright green",    freq = 0.008,minDepth = 20, maxDepth = 28, veinSize = 2 },
}

-- ─── Dungeons ───────────────────────────────────────────────────────────────
WorldConfig.DungeonFrequency  = 0.003
WorldConfig.DungeonRoomCount  = { min = 5, max = 12 }
WorldConfig.DungeonChestTiers = { "Common", "Uncommon", "Rare", "Legendary" }
WorldConfig.DungeonChestWeights = { 50, 30, 15, 5 }

-- ─── Loot Tables ────────────────────────────────────────────────────────────
WorldConfig.LootTables = {
	Common = {
		minItems = 1, maxItems = 3,
		pool = {
			{ name = "Wooden Sword",   weight = 30, minQty = 1, maxQty = 1 },
			{ name = "Bread",          weight = 40, minQty = 1, maxQty = 3 },
			{ name = "Leather Armor",  weight = 20, minQty = 1, maxQty = 1 },
			{ name = "Torch",          weight = 50, minQty = 2, maxQty = 5 },
			{ name = "Gold Coin",      weight = 35, minQty = 1, maxQty = 10 },
		},
	},
	Uncommon = {
		minItems = 2, maxItems = 4,
		pool = {
			{ name = "Iron Sword",     weight = 25, minQty = 1, maxQty = 1 },
			{ name = "Chain Mail",     weight = 20, minQty = 1, maxQty = 1 },
			{ name = "Health Potion",  weight = 30, minQty = 1, maxQty = 2 },
			{ name = "Gold Coin",      weight = 40, minQty = 5, maxQty = 20 },
			{ name = "Magic Scroll",   weight = 15, minQty = 1, maxQty = 1 },
		},
	},
	Rare = {
		minItems = 2, maxItems = 5,
		pool = {
			{ name = "Steel Sword",    weight = 20, minQty = 1, maxQty = 1 },
			{ name = "Plate Armor",    weight = 15, minQty = 1, maxQty = 1 },
			{ name = "Mana Potion",    weight = 25, minQty = 1, maxQty = 2 },
			{ name = "Gold Coin",      weight = 30, minQty = 20, maxQty = 50 },
			{ name = "Enchanted Ring", weight = 10, minQty = 1, maxQty = 1 },
		},
	},
	Legendary = {
		minItems = 3, maxItems = 6,
		pool = {
			{ name = "Dragon Sword",   weight = 10, minQty = 1, maxQty = 1 },
			{ name = "Void Staff",     weight = 8,  minQty = 1, maxQty = 1 },
			{ name = "Phoenix Armor",  weight = 7,  minQty = 1, maxQty = 1 },
			{ name = "Gold Coin",      weight = 30, minQty = 50, maxQty = 200 },
			{ name = "Orb of Power",   weight = 5,  minQty = 1, maxQty = 1 },
			{ name = "Ancient Tome",   weight = 12, minQty = 1, maxQty = 1 },
		},
	},
}

-- ─── Mob Spawns ─────────────────────────────────────────────────────────────
WorldConfig.MobSpawnCap = 10  -- max mobs per player

WorldConfig.MobSpawns = {
	Default = {
		{ name = "Zombie",  hp = 80,  color = "Bright green",    size = Vector3.new(2,3,2), biome = "Default" },
		{ name = "Skeleton",hp = 60,  color = "White",            size = Vector3.new(2,3,2), biome = "Default" },
	},
	Forest = {
		{ name = "Wolf",    hp = 50,  color = "Medium stone grey",size = Vector3.new(2,2,3), biome = "Forest"  },
		{ name = "Spider",  hp = 40,  color = "Really black",     size = Vector3.new(3,2,3), biome = "Forest"  },
		{ name = "Goblin",  hp = 45,  color = "Bright green",     size = Vector3.new(2,3,2), biome = "Forest"  },
	},
	Desert = {
		{ name = "Scorpion",hp = 70,  color = "Sand yellow",      size = Vector3.new(3,2,3), biome = "Desert"  },
		{ name = "Mummy",   hp = 100, color = "White",            size = Vector3.new(2,4,2), biome = "Desert"  },
	},
	Tundra = {
		{ name = "IceGolem",hp = 150, color = "Cyan",             size = Vector3.new(3,5,3), biome = "Tundra"  },
		{ name = "Yeti",    hp = 120, color = "White",            size = Vector3.new(3,4,3), biome = "Tundra"  },
	},
	Swamp = {
		{ name = "Slime",   hp = 60,  color = "Lime green",       size = Vector3.new(3,3,3), biome = "Swamp"   },
		{ name = "Witch",   hp = 80,  color = "Dark purple",      size = Vector3.new(2,4,2), biome = "Swamp"   },
	},
	Jungle = {
		{ name = "Raptor",  hp = 90,  color = "Bright green",     size = Vector3.new(3,3,4), biome = "Jungle"  },
		{ name = "Shaman",  hp = 70,  color = "Dark orange",      size = Vector3.new(2,4,2), biome = "Jungle"  },
	},
	Mountains = {
		{ name = "Troll",   hp = 200, color = "Medium stone grey",size = Vector3.new(4,5,4), biome = "Mountains" },
		{ name = "Eagle",   hp = 45,  color = "White",            size = Vector3.new(3,2,3), biome = "Mountains" },
	},
	Ocean = {
		{ name = "Kraken",  hp = 300, color = "Deep blue",        size = Vector3.new(6,4,6), biome = "Ocean"   },
	},
}

-- ─── Rivers ─────────────────────────────────────────────────────────────────
WorldConfig.RiverFrequency = 0.004
WorldConfig.RiverWidth     = { min = 8, max = 20 }
WorldConfig.RiverDepth     = 4

-- ─── Weather ────────────────────────────────────────────────────────────────
WorldConfig.WeatherCycle = 120  -- seconds per full cycle
WorldConfig.WeatherTypes = { "Clear", "Cloudy", "Rain", "Thunderstorm", "Fog", "Blizzard" }

return WorldConfig
