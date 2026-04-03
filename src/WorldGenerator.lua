-- WorldGenerator.lua
-- Main orchestrator: terrain, biomes, ores, rivers, dungeons, weather, mobs
-- v2.2.0

local WorldConfig      = require(script.Parent.WorldConfig)
local BiomeResolver    = require(script.Parent.BiomeResolver)
local ChunkHandler     = require(script.Parent.ChunkHandler)
local OreGenerator     = require(script.Parent.OreGenerator)
local RiverCarver      = require(script.Parent.RiverCarver)
local DungeonGenerator = require(script.Parent.DungeonGenerator)
local WeatherManager   = require(script.Parent.WeatherManager)
local SeedPersistence  = require(script.Parent.SeedPersistence)
local StreamingManager = require(script.Parent.StreamingManager)
local MobSpawner       = require(script.Parent.MobSpawner)

local Players  = game:GetService("Players")
local RunService = game:GetService("RunService")

local WorldGenerator = {}

local currentSeed    = 0
local initialized    = false
local activeChunks   = {}

-- ─── Seed ───────────────────────────────────────────────────────────────────
function WorldGenerator.GetSeed()
	return currentSeed
end

function WorldGenerator.SetSeed(seed)
	currentSeed = seed
end

-- ─── Chunk Generation ───────────────────────────────────────────────────────
function WorldGenerator.GenerateChunk(cx, cz)
	local key = cx .. "," .. cz
	if activeChunks[key] then return end
	activeChunks[key] = true

	local worldX = cx * WorldConfig.ChunkSize
	local worldZ = cz * WorldConfig.ChunkSize

	-- Terrain
	ChunkHandler.BuildChunk(cx, cz, currentSeed)

	-- Ores
	OreGenerator.PlaceOres(worldX, worldZ, currentSeed)

	-- River carve pass
	RiverCarver.CarveAt(worldX, worldZ, currentSeed)

	-- Dungeon spawn attempt
	DungeonGenerator.TrySpawnAt(worldX, worldZ, currentSeed)
end

-- ─── Init ───────────────────────────────────────────────────────────────────
function WorldGenerator.Init(forceSeed)
	if initialized then return end
	initialized = true

	-- Resolve seed
	local saved = SeedPersistence.Load()
	if forceSeed then
		currentSeed = forceSeed
	elseif saved and saved ~= 0 then
		currentSeed = saved
	else
		currentSeed = math.random(1, 2^31 - 1)
		SeedPersistence.Save(currentSeed)
	end

	print("[WorldGenerator] Seed:", currentSeed)

	-- Start subsystems
	WeatherManager.Start(currentSeed)
	StreamingManager.Start(currentSeed)
	MobSpawner.Start(currentSeed)

	-- Initial chunk load around spawn
	for dx = -WorldConfig.RenderDistance, WorldConfig.RenderDistance do
		for dz = -WorldConfig.RenderDistance, WorldConfig.RenderDistance do
			WorldGenerator.GenerateChunk(dx, dz)
		end
	end

	-- Track players for dynamic loading
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			WorldGenerator._TrackPlayer(player)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			WorldGenerator._TrackPlayer(player)
		end
	end
end

-- ─── Player Tracking ────────────────────────────────────────────────────────
function WorldGenerator._TrackPlayer(player)
	local lastCX, lastCZ = nil, nil

	RunService.Heartbeat:Connect(function()
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local pos = root.Position
		local cx  = math.floor(pos.X / WorldConfig.ChunkSize)
		local cz  = math.floor(pos.Z / WorldConfig.ChunkSize)

		if cx ~= lastCX or cz ~= lastCZ then
			lastCX, lastCZ = cx, cz
			for dx = -WorldConfig.RenderDistance, WorldConfig.RenderDistance do
				for dz = -WorldConfig.RenderDistance, WorldConfig.RenderDistance do
					WorldGenerator.GenerateChunk(cx + dx, cz + dz)
				end
			end
		end
	end)
end

return WorldGenerator
