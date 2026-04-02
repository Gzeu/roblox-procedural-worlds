--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/StreamingManager  [v2 NEW]
-- Runtime chunk loader/unloader.
-- Tracks which chunks have been generated; generates new ones
-- when a player enters their radius, and clears terrain voxels
-- for chunks that are too far from all players.
--
-- Usage: call StreamingManager.Start(seed) after initial world gen.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")

local WorldConfig  = require(ReplicatedStorage:WaitForChild("WorldConfig"))
local ChunkHandler = require(ReplicatedStorage:WaitForChild("ChunkHandler"))

local Terrain = Workspace.Terrain

type ChunkKey = string   -- "cx,cz"
type ChunkState = "loaded" | "unloaded"

local StreamingManager = {}

-- Track loaded chunks: key → state
local chunkStates: { [ChunkKey]: ChunkState } = {}
-- Track active generation tasks to avoid double-spawning
local generating: { [ChunkKey]: boolean } = {}

-- ----------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------
local function chunkKey(cx: number, cz: number): ChunkKey
	return cx .. "," .. cz
end

-- Snap a world coordinate to its chunk origin
local function snapToChunk(v: number, chunkSize: number): number
	return math.floor(v / chunkSize) * chunkSize
end

-- Get all chunk origins within radius of a world position
local function getChunksInRadius(
	wx: number, wz: number,
	radius: number, chunkSize: number
): { { x: number, z: number } }
	local result = {}
	for dx = -radius, radius, chunkSize do
		for dz = -radius, radius, chunkSize do
			if dx * dx + dz * dz <= radius * radius then
				local cx = snapToChunk(wx + dx, chunkSize)
				local cz = snapToChunk(wz + dz, chunkSize)
				table.insert(result, { x = cx, z = cz })
			end
		end
	end
	return result
end

-- Clear terrain voxels for a chunk (replace with Air)
local function unloadChunk(cx: number, cz: number)
	local cfg   = WorldConfig.Settings
	local vSize = cfg.VoxelSize
	-- Erase from deep bedrock to max mountain height
	local minY = cfg.CaveMinY - vSize * 4
	local maxY = cfg.BaseY + cfg.MountainAmplitude + cfg.TerrainAmplitude + vSize * 4
	local size = Vector3.new(cfg.ChunkSize, maxY - minY, cfg.ChunkSize)
	local centerY = (maxY + minY) / 2
	local center = Vector3.new(
		cx + cfg.ChunkSize / 2,
		centerY,
		cz + cfg.ChunkSize / 2
	)
	local ok, err = pcall(Terrain.FillBlock, Terrain,
		CFrame.new(center), size, Enum.Material.Air)
	if not ok then
		warn("[StreamingManager] Unload error:", err)
	end
end

-- ----------------------------------------------------------------
-- Start: begins the streaming loop
-- ----------------------------------------------------------------
function StreamingManager.Start(seed: number)
	local cfg = WorldConfig.Settings

	task.spawn(function()
		while true do
			task.wait(cfg.StreamingCheckInterval)

			-- Gather all required chunk keys from all player positions
			local requiredKeys: { [ChunkKey]: { x: number, z: number } } = {}

			for _, player in Players:GetPlayers() do
				local char = player.Character
				if not char then continue end
				local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not root then continue end

				local pos = root.Position
				local nearby = getChunksInRadius(
					pos.X, pos.Z,
					cfg.StreamingRadius,
					cfg.ChunkSize
				)
				for _, coord in nearby do
					requiredKeys[chunkKey(coord.x, coord.z)] = coord
				end
			end

			-- Load missing chunks
			for key, coord in requiredKeys do
				if chunkStates[key] ~= "loaded" and not generating[key] then
					generating[key] = true
					task.spawn(function()
						local ok, err = pcall(ChunkHandler.GenerateChunk,
							coord.x, coord.z, seed)
						if ok then
							chunkStates[key] = "loaded"
						else
							warn("[StreamingManager] Load failed:", err)
						end
						generating[key] = nil
					end)
				end
			end

			-- Unload distant chunks (only ones not in requiredKeys)
			for key, state in chunkStates do
				if state == "loaded" and not requiredKeys[key] then
					local parts = string.split(key, ",")
					local cx = tonumber(parts[1]) or 0
					local cz = tonumber(parts[2]) or 0
					task.spawn(function()
						unloadChunk(cx, cz)
						chunkStates[key] = "unloaded"
					end)
				end
			end
		end
	end)
end

-- Mark a chunk as loaded (called by WorldGenerator for initial gen)
function StreamingManager.MarkLoaded(cx: number, cz: number)
	chunkStates[chunkKey(cx, cz)] = "loaded"
end

return StreamingManager
