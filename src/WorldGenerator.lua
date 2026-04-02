--!strict
-- ============================================================
-- MAIN SCRIPT: ServerScriptService/WorldGenerator
-- - Resolves seed (random or fixed)
-- - Builds the full chunk queue
-- - Dispatches chunks via task.spawn() with a concurrency cap
--   to avoid flooding the Lua scheduler
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local WorldConfig  = require(ReplicatedStorage:WaitForChild("WorldConfig"))
local ChunkHandler = require(ReplicatedStorage:WaitForChild("ChunkHandler"))
local AssetPlacer  = require(ReplicatedStorage:WaitForChild("AssetPlacer"))

-- Seed resolution
local seed: number
if WorldConfig.Settings.Seed == 0 then
	seed = math.floor(tick() % 100000)
	print("[WorldGenerator] Random seed:", seed)
else
	seed = WorldConfig.Settings.Seed
	print("[WorldGenerator] Fixed seed:", seed)
end
math.randomseed(seed)

-- Initialise ProceduralAssets folder
AssetPlacer.Init()

-- Build chunk origin queue (world centred on 0,0)
local cfg   = WorldConfig.Settings
local halfX = cfg.WorldSizeX / 2
local halfZ = cfg.WorldSizeZ / 2

type ChunkCoord = { x: number, z: number }
local chunkQueue: { ChunkCoord } = {}

for cx = -halfX, halfX - cfg.ChunkSize, cfg.ChunkSize do
	for cz = -halfZ, halfZ - cfg.ChunkSize, cfg.ChunkSize do
		table.insert(chunkQueue, { x = cx, z = cz })
	end
end

local totalChunks = #chunkQueue
print(string.format(
	"[WorldGenerator] %d chunks queued (%dx%d world, %d stud chunks)",
	totalChunks, cfg.WorldSizeX, cfg.WorldSizeZ, cfg.ChunkSize
))

-- Throttled dispatch loop
local activeChunks    = 0
local completedChunks = 0
local queueIndex      = 1
local maxConcurrent   = cfg.MaxConcurrentChunks

local connection: RBXScriptConnection
connection = RunService.Heartbeat:Connect(function()
	while queueIndex <= totalChunks and activeChunks < maxConcurrent do
		local coord = chunkQueue[queueIndex]
		queueIndex   += 1
		activeChunks += 1

		task.spawn(function()
			local ok, err = pcall(ChunkHandler.GenerateChunk, coord.x, coord.z, seed)
			if not ok then
				warn(string.format("[WorldGenerator] Chunk (%d,%d) failed: %s", coord.x, coord.z, tostring(err)))
			end
			activeChunks    -= 1
			completedChunks += 1
			if completedChunks % 25 == 0 or completedChunks == totalChunks then
				print(string.format("[WorldGenerator] %d / %d chunks (%.0f%%)",
					completedChunks, totalChunks,
					(completedChunks / totalChunks) * 100
				))
			end
		end)
	end

	if completedChunks >= totalChunks then
		connection:Disconnect()
		print("[WorldGenerator] ✅ World generation complete!")
	end
end)
