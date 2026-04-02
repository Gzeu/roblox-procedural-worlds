--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/WorldConfig  [v2]
-- Single source of truth for all generation parameters.
-- ============================================================

local WorldConfig = {}

WorldConfig.Settings = {
	-- World footprint in studs (centred on origin)
	WorldSizeX = 500,
	WorldSizeZ = 500,

	-- Chunk size in studs
	ChunkSize = 30,

	-- Y origin for terrain surface
	BaseY = 0,

	-- Below this Y → Water material
	WaterLevel = -8,

	-- 0 = random seed each run; any other int = reproducible
	Seed = 0,

	-- Noise scales
	TerrainScale  = 120,
	MountainScale = 60,
	CaveScale     = 40,
	TempScale     = 200,
	MoistureScale = 180,

	-- Height amplitudes (studs)
	TerrainAmplitude  = 20,
	MountainAmplitude = 35,

	-- Cave settings
	CaveThreshold = 0.30,
	CaveMinY      = -60,
	CaveMaxY      = -10,

	-- Voxel resolution (Roblox min = 4)
	VoxelSize = 4,

	-- Surface spawn probabilities
	TreeSpawnChance      = 0.04,
	RockSpawnChance      = 0.02,
	BushSpawnChance      = 0.03,
	StructureSpawnChance = 0.005,

	-- Max parallel chunk tasks
	MaxConcurrentChunks = 10,

	-- Streaming: radius (studs) around each player to keep loaded
	StreamingRadius = 300,
	-- How often (seconds) streaming manager checks player positions
	StreamingCheckInterval = 5,
}

-- ----------------------------------------------------------------
-- 9 Biomes — (temperature, moisture) poles defined in BiomeResolver
-- ----------------------------------------------------------------
WorldConfig.Biomes = {
	Forest = {
		Name            = "Forest",
		SurfaceMaterial = Enum.Material.Grass,
		FillMaterial    = Enum.Material.Mud,
		DebugColor      = Color3.fromRGB(34, 139, 34),
		Trees = true, Rocks = true, Bushes = true,
		Structures = { "Campfire", "WoodRuin" },
	},
	Desert = {
		Name            = "Desert",
		SurfaceMaterial = Enum.Material.Sand,
		FillMaterial    = Enum.Material.Sandstone,
		DebugColor      = Color3.fromRGB(237, 201, 100),
		Trees = false, Rocks = true, Bushes = false,
		Structures = { "SandRuin", "Obelisk" },
	},
	Snow = {
		Name            = "Snow",
		SurfaceMaterial = Enum.Material.Snow,
		FillMaterial    = Enum.Material.Glacier,
		DebugColor      = Color3.fromRGB(220, 235, 255),
		Trees = true, Rocks = true, Bushes = false,
		Structures = { "Igloo", "IceSpike" },
	},
	Grassland = {
		Name            = "Grassland",
		SurfaceMaterial = Enum.Material.Grass,
		FillMaterial    = Enum.Material.Ground,
		DebugColor      = Color3.fromRGB(124, 200, 80),
		Trees = false, Rocks = false, Bushes = true,
		Structures = { "Campfire" },
	},
	Jungle = {
		Name            = "Jungle",
		SurfaceMaterial = Enum.Material.Grass,
		FillMaterial    = Enum.Material.Mud,
		DebugColor      = Color3.fromRGB(0, 100, 20),
		Trees = true, Rocks = true, Bushes = true,
		Structures = { "JungleTemple", "Campfire" },
	},
	Tundra = {
		Name            = "Tundra",
		SurfaceMaterial = Enum.Material.Snow,
		FillMaterial    = Enum.Material.Ground,
		DebugColor      = Color3.fromRGB(180, 210, 230),
		Trees = false, Rocks = true, Bushes = false,
		Structures = { "IceSpike" },
	},
	Volcano = {
		Name            = "Volcano",
		SurfaceMaterial = Enum.Material.Basalt,
		FillMaterial    = Enum.Material.Basalt,
		DebugColor      = Color3.fromRGB(180, 40, 10),
		Trees = false, Rocks = true, Bushes = false,
		Structures = { "LavaPillar", "AshRuin" },
	},
	Swamp = {
		Name            = "Swamp",
		SurfaceMaterial = Enum.Material.Mud,
		FillMaterial    = Enum.Material.Mud,
		DebugColor      = Color3.fromRGB(70, 90, 50),
		Trees = true, Rocks = false, Bushes = true,
		Structures = { "WoodRuin", "Campfire" },
	},
	Ocean = {
		Name            = "Ocean",
		SurfaceMaterial = Enum.Material.Sand,
		FillMaterial    = Enum.Material.Sand,
		DebugColor      = Color3.fromRGB(30, 80, 180),
		Trees = false, Rocks = false, Bushes = false,
		Structures = {},
	},
}

-- ----------------------------------------------------------------
-- Ore vein definitions — spawned by OreGenerator module
-- MinY/MaxY: depth range; Threshold: noise rarity (lower = rarer)
-- Material: the Roblox Enum.Material to fill ore voxels with
-- ----------------------------------------------------------------
WorldConfig.OreVeins = {
	{
		Name      = "Coal",
		Material  = Enum.Material.Slate,
		MinY      = -60, MaxY = -5,
		Scale     = 20,
		Threshold = 0.72,
		SeedOffset = 10000,
	},
	{
		Name      = "Iron",
		Material  = Enum.Material.Cobblestone,
		MinY      = -80, MaxY = -20,
		Scale     = 18,
		Threshold = 0.78,
		SeedOffset = 20000,
	},
	{
		Name      = "Gold",
		Material  = Enum.Material.SmoothPlastic, -- replace with custom material
		MinY      = -100, MaxY = -40,
		Scale     = 15,
		Threshold = 0.83,
		SeedOffset = 30000,
	},
	{
		Name      = "Diamond",
		Material  = Enum.Material.Ice,           -- replace with custom material
		MinY      = -120, MaxY = -60,
		Scale     = 12,
		Threshold = 0.88,
		SeedOffset = 40000,
	},
}

return WorldConfig
