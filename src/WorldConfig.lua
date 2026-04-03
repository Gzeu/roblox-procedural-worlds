--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/WorldConfig  [v2.1]
-- Single source of truth for all generation parameters.
-- ============================================================

local WorldConfig = {}

WorldConfig.Settings = {
	WorldSizeX = 500,
	WorldSizeZ = 500,
	ChunkSize = 30,
	BaseY = 0,
	WaterLevel = -8,
	-- 0 = random seed (persisted via DataStore); non-zero = manual override
	Seed = 0,
	TerrainScale   = 120,
	MountainScale  = 60,
	CaveScale      = 40,
	TempScale      = 200,
	MoistureScale  = 180,
	TerrainAmplitude  = 20,
	MountainAmplitude = 35,
	CaveThreshold = 0.30,
	CaveMinY      = -60,
	CaveMaxY      = -10,
	VoxelSize = 4,
	TreeSpawnChance      = 0.04,
	RockSpawnChance      = 0.02,
	BushSpawnChance      = 0.03,
	StructureSpawnChance = 0.005,
	MaxConcurrentChunks = 10,
	StreamingRadius = 300,
	StreamingCheckInterval = 5,
	WeatherCheckInterval = 8,
}

-- ============================================================
-- River Settings  [v2.1]
-- ============================================================
WorldConfig.RiverSettings = {
	SpringGridStep  = 80,
	SpringMinHeight = 12,
	MaxSteps        = 200,
	StepSize        = 4,
	RiverRadius     = 6,
	MaxRivers       = 12,
}

-- ============================================================
-- Dungeon Settings  [v2.1]
-- ============================================================
WorldConfig.DungeonSettings = {
	DungeonY       = -90,
	DungeonWidth   = 80,
	DungeonHeight  = 80,
	GridStep       = 150,
	MaxDungeons    = 6,
	SpawnThreshold = 0.25,
}

-- ============================================================
-- Ore vein definitions
-- ============================================================
WorldConfig.OreVeins = {
	{
		Name       = "Coal",
		Material   = Enum.Material.SmoothPlastic,
		MinY       = -60,
		MaxY       = -5,
		Scale      = 18,
		Threshold  = 0.72,
		SeedOffset = 10000,
	},
	{
		Name       = "Iron",
		Material   = Enum.Material.Metal,
		MinY       = -80,
		MaxY       = -20,
		Scale      = 14,
		Threshold  = 0.78,
		SeedOffset = 20000,
	},
	{
		Name       = "Gold",
		Material   = Enum.Material.Neon,
		MinY       = -120,
		MaxY       = -50,
		Scale      = 12,
		Threshold  = 0.84,
		SeedOffset = 30000,
	},
	{
		Name       = "Diamond",
		Material   = Enum.Material.Ice,
		MinY       = -160,
		MaxY       = -90,
		Scale      = 10,
		Threshold  = 0.90,
		SeedOffset = 40000,
	},
}

-- ============================================================
-- Biome definitions
-- ============================================================
WorldConfig.Biomes = {
	Forest = {
		Name            = "Forest",
		SurfaceMaterial = Enum.Material.Grass,
		FillMaterial    = Enum.Material.Mud,
		DebugColor      = Color3.fromRGB(34, 139, 34),
		Trees           = true,
		Rocks           = true,
		Bushes          = true,
		Structures      = { "Campfire", "WoodRuin" },
	},
	Desert = {
		Name            = "Desert",
		SurfaceMaterial = Enum.Material.Sand,
		FillMaterial    = Enum.Material.Sandstone,
		DebugColor      = Color3.fromRGB(210, 180, 100),
		Trees           = false,
		Rocks           = true,
		Bushes          = false,
		Structures      = { "SandRuin", "Obelisk" },
	},
	Snow = {
		Name            = "Snow",
		SurfaceMaterial = Enum.Material.Snow,
		FillMaterial    = Enum.Material.Glacier,
		DebugColor      = Color3.fromRGB(220, 235, 255),
		Trees           = true,
		Rocks           = false,
		Bushes          = false,
		Structures      = { "Igloo", "IceSpike" },
	},
	Grassland = {
		Name            = "Grassland",
		SurfaceMaterial = Enum.Material.Grass,
		FillMaterial    = Enum.Material.Ground,
		DebugColor      = Color3.fromRGB(124, 200, 80),
		Trees           = false,
		Rocks           = false,
		Bushes          = true,
		Structures      = { "Campfire" },
	},
	Jungle = {
		Name            = "Jungle",
		SurfaceMaterial = Enum.Material.Grass,
		FillMaterial    = Enum.Material.Mud,
		DebugColor      = Color3.fromRGB(0, 100, 20),
		Trees           = true,
		Rocks           = false,
		Bushes          = true,
		Structures      = { "JungleTemple", "Campfire" },
	},
	Tundra = {
		Name            = "Tundra",
		SurfaceMaterial = Enum.Material.Snow,
		FillMaterial    = Enum.Material.Ground,
		DebugColor      = Color3.fromRGB(180, 200, 210),
		Trees           = false,
		Rocks           = true,
		Bushes          = false,
		Structures      = { "IceSpike" },
	},
	Volcano = {
		Name            = "Volcano",
		SurfaceMaterial = Enum.Material.Basalt,
		FillMaterial    = Enum.Material.Basalt,
		DebugColor      = Color3.fromRGB(120, 30, 10),
		Trees           = false,
		Rocks           = true,
		Bushes          = false,
		Structures      = { "LavaPillar", "AshRuin" },
	},
	Swamp = {
		Name            = "Swamp",
		SurfaceMaterial = Enum.Material.Mud,
		FillMaterial    = Enum.Material.Mud,
		DebugColor      = Color3.fromRGB(60, 90, 50),
		Trees           = true,
		Rocks           = false,
		Bushes          = true,
		Structures      = { "WoodRuin", "Campfire" },
	},
	Ocean = {
		Name            = "Ocean",
		SurfaceMaterial = Enum.Material.Sand,
		FillMaterial    = Enum.Material.Sand,
		DebugColor      = Color3.fromRGB(30, 80, 180),
		Trees           = false,
		Rocks           = false,
		Bushes          = false,
		Structures      = {},
	},
}

return WorldConfig
