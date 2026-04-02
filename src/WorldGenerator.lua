--!strict
-- ============================================================
-- MAIN SCRIPT: ServerScriptService/WorldGenerator  [v2]
-- - Resolves seed
-- - Dispatches all chunks with concurrency throttle
-- - Marks each chunk loaded in StreamingManager
-- - Starts StreamingManager after initial generation
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local WorldConfig      = require(ReplicatedStorage:WaitForChild("WorldConfig"))
local ChunkHandler     = require(ReplicatedStorage:WaitForChild("ChunkHandler"))
local AssetPlacer      = require(ReplicatedStorage:WaitForChild("AssetPlacer"))
local StreamingManager = require(ReplicatedStorage:WaitForChild("StreamingManager"))

-- Seed
local seed: number
if WorldConfig.Settings.Seed == 0 then
	seed = math.floor(tick() % 100000)
	print("[WorldGenerator] 🌍 Random seed:", seed)
else
	seed = WorldConfig.Settings.Seed
	print("[WorldGenerator] 🌍 Fixed seed:", seed)
end
math.randomseed(seed)

AssetPlacer.Init()

-- Build chunk queue
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

local totalChunks     = #chunkQueue
local activeChunks    = 0
local completedChunks = 0
local queueIndex      = 1

print(string.format(
	"[WorldGenerator] Queued %d chunks (%d×%d world, chunkSize=%d)",
	totalChunks, cfg.WorldSizeX, cfg.WorldSizeZ, cfg.ChunkSize
))

local startTime = tick()

local connection: RBXScriptConnection
connection = RunService.Heartbeat:Connect(function()
	-- Fill up to concurrency cap
	while queueIndex <= totalChunks and activeChunks < cfg.MaxConcurrentChunks do
		local coord = chunkQueue[queueIndex]
		queueIndex   += 1
		activeChunks += 1

		task.spawn(function()
			local ok, err = pcall(ChunkHandler.GenerateChunk, coord.x, coord.z, seed)
			if ok then
				StreamingManager.MarkLoaded(coord.x, coord.z)
			else
				warn(string.format("[WorldGenerator] Chunk (%d,%d) failed: %s",
					coord.x, coord.z, tostring(err)))
			end
			activeChunks    -= 1
			completedChunks += 1

			if completedChunks % 25 == 0 or completedChunks == totalChunks then
				print(string.format("[WorldGenerator] %d/%d (%.0f%%)",
					completedChunks, totalChunks,
					(completedChunks / totalChunks) * 100))
			end
		end)
	end

	if completedChunks >= totalChunks then
		connection:Disconnect()
		local elapsed = math.floor(tick() - startTime)
		print(string.format(
			"[WorldGenerator] ✅ Done! %d chunks in %ds. Seed: %d",
			totalChunks, elapsed, seed
		))
		-- Start runtime streaming around players
		StreamingManager.Start(seed)
	end
end)
