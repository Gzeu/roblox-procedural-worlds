--!strict
-- ============================================================
-- MAIN SCRIPT: ServerScriptService/WorldGenerator  [v2.1]
-- Orchestrates full world generation:
--   1. Seed resolution (DataStore persistence or manual override)
--   2. Initial chunk grid with concurrency throttle
--   3. River carving (post-terrain)
--   4. Dungeon generation (post-terrain, underground)
--   5. StreamingManager boot (runtime load/unload)
--   6. WeatherManager boot (biome-zone weather)
-- ============================================================

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local WorldConfig      = require(ReplicatedStorage:WaitForChild("WorldConfig"))
local ChunkHandler     = require(ReplicatedStorage:WaitForChild("ChunkHandler"))
local StreamingManager = require(ReplicatedStorage:WaitForChild("StreamingManager"))
local AssetPlacer      = require(ReplicatedStorage:WaitForChild("AssetPlacer"))
local RiverCarver      = require(ReplicatedStorage:WaitForChild("RiverCarver"))
local DungeonGenerator = require(ReplicatedStorage:WaitForChild("DungeonGenerator"))
local WeatherManager   = require(ReplicatedStorage:WaitForChild("WeatherManager"))
local SeedPersistence  = require(ServerScriptService:WaitForChild("SeedPersistence"))

-- ----------------------------------------------------------------
-- Resolve Seed
-- ----------------------------------------------------------------
local cfg = WorldConfig.Settings

local seed: number
if cfg.Seed ~= 0 then
	seed = cfg.Seed
	print("[WorldGenerator] Using manual seed:", seed)
else
	seed = SeedPersistence.GetOrCreateSeed()
end

math.randomseed(seed)

-- ----------------------------------------------------------------
-- Init asset container in Workspace
-- ----------------------------------------------------------------
AssetPlacer.Init()

-- ----------------------------------------------------------------
-- Initial chunk generation
-- ----------------------------------------------------------------
local halfX = cfg.WorldSizeX / 2
local halfZ = cfg.WorldSizeZ / 2

local pending   = 0
local completed = 0
local total     = 0

for _ = -halfX, halfX - cfg.ChunkSize, cfg.ChunkSize do
	for _ = -halfZ, halfZ - cfg.ChunkSize, cfg.ChunkSize do
		total += 1
	end
end

print(string.format("[WorldGenerator] Generating %d chunks (seed=%d)…", total, seed))

for cx = -halfX, halfX - cfg.ChunkSize, cfg.ChunkSize do
	for cz = -halfZ, halfZ - cfg.ChunkSize, cfg.ChunkSize do
		while pending >= cfg.MaxConcurrentChunks do
			task.wait(0.05)
		end
		pending += 1
		task.spawn(function()
			local ok, err = pcall(ChunkHandler.GenerateChunk, cx, cz, seed)
			if ok then
				StreamingManager.MarkLoaded(cx, cz)
			else
				warn(string.format("[WorldGenerator] Chunk (%d,%d) failed: %s", cx, cz, tostring(err)))
			end
			pending   -= 1
			completed += 1
		end)
	end
end

while completed < total do
	task.wait(0.5)
	print(string.format("[WorldGenerator] Progress: %d / %d chunks", completed, total))
end

print("[WorldGenerator] Initial terrain complete.")

-- ----------------------------------------------------------------
-- Post-terrain passes
-- ----------------------------------------------------------------
task.spawn(function()
	print("[WorldGenerator] Starting river carving…")
	RiverCarver.CarveRivers(seed)
end)

task.spawn(function()
	print("[WorldGenerator] Starting dungeon generation…")
	DungeonGenerator.GenerateDungeons(seed)
end)

-- ----------------------------------------------------------------
-- Runtime systems
-- ----------------------------------------------------------------
StreamingManager.Start(seed)
WeatherManager.Start(seed)

print("[WorldGenerator] All systems running.")
