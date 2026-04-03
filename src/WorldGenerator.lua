-- WorldGenerator.lua
-- Master orchestrator — all subsystems
-- v2.6.0 — fixed: all requires via script.Parent; BuildChunk → GenerateChunk

local WorldConfig       = require(script.Parent.WorldConfig)
local BiomeResolver     = require(script.Parent.BiomeResolver)
local ChunkHandler      = require(script.Parent.ChunkHandler)
local OreGenerator      = require(script.Parent.OreGenerator)
local RiverCarver       = require(script.Parent.RiverCarver)
local DungeonGenerator  = require(script.Parent.DungeonGenerator)
local VillageGenerator  = require(script.Parent.VillageGenerator)
local WeatherManager    = require(script.Parent.WeatherManager)
local SeedPersistence   = require(script.Parent.SeedPersistence)
local StreamingManager  = require(script.Parent.StreamingManager)
local MobSpawner        = require(script.Parent.MobSpawner)
local QuestSystem       = require(script.Parent.QuestSystem)
local AdminPanel        = require(script.Parent.AdminPanel)
local LODManager        = require(script.Parent.LODManager)
local PlayerPersistence = require(script.Parent.PlayerPersistence)
local NPCDialogue       = require(script.Parent.NPCDialogue)
local DayNightCycle     = require(script.Parent.DayNightCycle)

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

	local worldX = cx * WorldConfig.Settings.ChunkSize
	local worldZ = cz * WorldConfig.Settings.ChunkSize

	-- GenerateChunk returns nothing; terrain is filled directly into Workspace.Terrain
	ChunkHandler.GenerateChunk(worldX, worldZ, currentSeed)
	LODManager.RegisterChunk(cx, cz, nil)

	OreGenerator.PlaceOres(worldX, worldZ, currentSeed)
	RiverCarver.CarveAt(worldX, worldZ, currentSeed)
	DungeonGenerator.TrySpawnAt(worldX, worldZ, currentSeed)
	VillageGenerator.TrySpawnAt(worldX, worldZ, currentSeed)
end

function WorldGenerator.Init(forceSeed)
	if initialized then return end
	initialized = true

	local saved = SeedPersistence.Load()
	if forceSeed and forceSeed ~= 0 then
		currentSeed = forceSeed
	elseif saved and saved ~= 0 then
		currentSeed = saved
	else
		currentSeed = math.random(1, 2^31 - 1)
		SeedPersistence.Save(currentSeed)
	end

	print("[WorldGenerator] Seed:", currentSeed)

	-- Boot subsystems
	PlayerPersistence.Start()
	WeatherManager.Start(currentSeed)
	StreamingManager.Start(currentSeed)
	MobSpawner.Start(currentSeed)
	QuestSystem.Start(currentSeed)
	NPCDialogue.Start(currentSeed)
	DayNightCycle.Start(0.5)
	LODManager.Start()
	AdminPanel.Init(WorldGenerator, MobSpawner)

	-- Generate initial chunk grid around spawn
	local rd = WorldConfig.Settings.RenderDistance or 3
	for dx = -rd, rd do
		for dz = -rd, rd do
			task.spawn(WorldGenerator.GenerateChunk, dx, dz)
		end
	end

	-- Track players
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
		local cfg = WorldConfig.Settings
		local cx = math.floor(root.Position.X / cfg.ChunkSize)
		local cz = math.floor(root.Position.Z / cfg.ChunkSize)
		if cx ~= lastCX or cz ~= lastCZ then
			lastCX, lastCZ = cx, cz
			local rd = cfg.RenderDistance or 3
			for dx = -rd, rd do
				for dz = -rd, rd do
					task.spawn(WorldGenerator.GenerateChunk, cx + dx, cz + dz)
				end
			end
		end
	end)
end

return WorldGenerator
