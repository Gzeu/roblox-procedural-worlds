-- WorldConfig.lua
-- Central configuration for the procedural world
-- v1.2 — added Settings table (ChunkHandler expects WorldConfig.Settings)

local WorldConfig = {}

WorldConfig.Settings = {
	-- Chunk
	ChunkSize        = 64,
	VoxelSize        = 4,
	RenderDistance   = 3,

	-- Terrain
	BaseY            = 20,
	TerrainAmplitude = 60,
	TerrainScale     = 200,
	MountainAmplitude= 80,
	MountainScale    = 400,

	-- Water
	WaterLevel       = 16,

	-- Caves
	CaveMinY         = -40,
	CaveMaxY         = 30,
	CaveScale        = 20,
	CaveThreshold    = 0.35,

	-- Biome noise
	TempScale        = 300,
	MoistureScale    = 300,
}

-- Legacy flat keys (used by some modules)
WorldConfig.ChunkSize         = WorldConfig.Settings.ChunkSize
WorldConfig.VoxelSize         = WorldConfig.Settings.VoxelSize
WorldConfig.RenderDistance    = WorldConfig.Settings.RenderDistance
WorldConfig.BaseY             = WorldConfig.Settings.BaseY
WorldConfig.TerrainAmplitude  = WorldConfig.Settings.TerrainAmplitude
WorldConfig.TerrainScale      = WorldConfig.Settings.TerrainScale
WorldConfig.WaterLevel        = WorldConfig.Settings.WaterLevel

-- Game systems config
WorldConfig.DAY_LENGTH_SECONDS = 240
WorldConfig.BOSS_BASE_XP       = 500
WorldConfig.NOISE_SCALE        = 0.008
WorldConfig.SEA_LEVEL          = 40
WorldConfig.HEIGHT_MULT        = 120
WorldConfig.EVENT_BUS_DEBUG    = false

return WorldConfig
