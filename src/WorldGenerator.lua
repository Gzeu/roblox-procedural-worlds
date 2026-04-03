-- WorldGenerator.lua
-- Master orchestrator — all subsystems
-- v2.5.0

local WorldConfig        = require(script.Parent.WorldConfig)
local BiomeResolver      = require(script.Parent.BiomeResolver)
local ChunkHandler       = require(script.Parent.ChunkHandler)
local OreGenerator       = require(script.Parent.OreGenerator)
local RiverCarver        = require(script.Parent.RiverCarver)
local DungeonGenerator   = require(script.Parent.DungeonGenerator)
local VillageGenerator   = require(script.Parent.VillageGenerator)
local WeatherManager     = require(script.Parent.WeatherManager)
local SeedPersistence    = require(script.Parent.SeedPersistence)
local StreamingManager   = require(script.Parent.StreamingManager)
local MobSpawner         = require(script.Parent.MobSpawner)
local QuestSystem        = require(script.Parent.QuestSystem)
local AdminPanel         = require(script.Parent.AdminPanel)
local LODManager         = require(script.Parent.LODManager)
local PlayerPersistence  = require(script.Parent.PlayerPersistence)
local NPCDialogue        = require(script.Parent.NPCDialogue)
local DayNightCycle      = require(script.Parent.DayNightCycle)

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local WorldGenerator = {}

local currentSeed  = 0
local initialized  = false
local activeChunks = {}

function WorldGenerator.GetSeed()  return currentSeed end
function WorldGenerator.SetSeed(s) currentSeed = s; SeedPersistence.Save(s) end

function WorldGenerator.GenerateChunk(cx, cz)
	local key = cx .. "," .. cz
	if activeChunks[key] then return end
	activeChunks[key] = true

	local worldX = cx * WorldConfig.ChunkSize
	local worldZ = cz * WorldConfig.ChunkSize

	local chunkModel = ChunkHandler.BuildChunk(cx, cz, currentSeed)
	if chunkModel then LODManager.RegisterChunk(cx, cz, chunkModel) end

	OreGenerator.PlaceOres(worldX, worldZ, currentSeed)
	RiverCarver.CarveAt(worldX, worldZ, currentSeed)
	DungeonGenerator.TrySpawnAt(worldX, worldZ, currentSeed)
	VillageGenerator.TrySpawnAt(worldX, worldZ, currentSeed)
end

function WorldGenerator.Init(forceSeed)
	if initialized then return end
	initialized = true

	local saved = SeedPersistence.Load()
	if forceSeed then
		currentSeed = forceSeed
	elseif saved and saved ~= 0 then
		currentSeed = saved
	else
		currentSeed = math.random(1, 2^31 - 1)
		SeedPersistence.Save(currentSeed)
	end

	if WorldConfig.Debug then warn("[WorldGenerator] Seed:", currentSeed) end

	-- Boot all subsystems
	PlayerPersistence.Start()
	WeatherManager.Start(currentSeed)
	StreamingManager.Start(currentSeed)
	MobSpawner.Start(currentSeed)
	QuestSystem.Start(currentSeed)
	NPCDialogue.Start(currentSeed)
	DayNightCycle.Start(0.5)  -- start at noon
	LODManager.Start()
	AdminPanel.Init(WorldGenerator, MobSpawner)

	-- Initial chunk grid
	for dx = -WorldConfig.RenderDistance, WorldConfig.RenderDistance do
		for dz = -WorldConfig.RenderDistance, WorldConfig.RenderDistance do
			WorldGenerator.GenerateChunk(dx, dz)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			WorldGenerator._TrackPlayer(player)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then WorldGenerator._TrackPlayer(player) end
	end
end

function WorldGenerator._TrackPlayer(player)
	local lastCX, lastCZ = nil, nil
	RunService.Heartbeat:Connect(function()
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local cx = math.floor(root.Position.X / WorldConfig.ChunkSize)
		local cz = math.floor(root.Position.Z / WorldConfig.ChunkSize)
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
