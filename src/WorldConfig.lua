--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/WorldConfig
-- Single source of truth for all generation parameters.
-- Edit values here to tune the world without touching other scripts.
-- ============================================================

local WorldConfig = {}

WorldConfig.Settings = {
	-- World footprint in studs (centered on origin)
	WorldSizeX = 500,
	WorldSizeZ = 500,

	-- Chunk size in studs (must divide evenly into WorldSize)
	ChunkSize = 30,

	-- Y origin for the terrain surface
	BaseY = 0,

	-- Everything below this Y is filled with Water material
	WaterLevel = -8,

	-- Set to 0 for a random seed each run; any other int = fixed seed
	Seed = 0,

	-- Noise scales (higher = smoother / more zoomed out features)
	TerrainScale   = 120,
	MountainScale  = 60,
	CaveScale      = 40,
	TempScale      = 200,
	MoistureScale  = 180,

	-- Vertical amplitude (studs) for each noise layer
	TerrainAmplitude  = 20,
	MountainAmplitude = 35,

	-- Cave generation: voxel becomes Air when noise < this threshold
	CaveThreshold = 0.30,
	-- Only punch caves between these Y values
	CaveMinY = -60,
	CaveMaxY = -10,

	-- Voxel resolution in studs (Roblox minimum = 4)
	VoxelSize = 4,

	-- Per-column surface spawn probabilities
	TreeSpawnChance  = 0.04,
	RockSpawnChance  = 0.02,
	BushSpawnChance  = 0.03,

	-- Max parallel chunk tasks (tune to your server's performance)
	MaxConcurrentChunks = 8,
}

-- ----------------------------------------------------------------
-- Biome definitions
-- SurfaceMaterial → the topmost voxel layer
-- FillMaterial    → subsurface voxels down to bedrock
-- Trees/Rocks/Bushes → asset placement flags
-- ----------------------------------------------------------------
WorldConfig.Biomes = {
	Forest = {
		Name            = "Forest",
		SurfaceMaterial = Enum.Material.Grass,
		FillMaterial    = Enum.Material.Mud,
		DebugColor      = Color3.fromRGB(34, 139, 34),
		Trees  = true,
		Rocks  = true,
		Bushes = true,
	},
	Desert = {
		Name            = "Desert",
		SurfaceMaterial = Enum.Material.Sand,
		FillMaterial    = Enum.Material.Sandstone,
		DebugColor      = Color3.fromRGB(237, 201, 100),
		Trees  = false,
		Rocks  = true,
		Bushes = false,
	},
	Snow = {
		Name            = "Snow",
		SurfaceMaterial = Enum.Material.Snow,
		FillMaterial    = Enum.Material.Glacier,
		DebugColor      = Color3.fromRGB(220, 235, 255),
		Trees  = true,
		Rocks  = true,
		Bushes = false,
	},
	Grassland = {
		Name            = "Grassland",
		SurfaceMaterial = Enum.Material.Grass,
		FillMaterial    = Enum.Material.Ground,
		DebugColor      = Color3.fromRGB(124, 200, 80),
		Trees  = false,
		Rocks  = false,
		Bushes = true,
	},
}

return WorldConfig
