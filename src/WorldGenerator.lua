-- WorldGenerator.lua
-- Master orchestrator — all subsystems
-- v3.0.0 — Multi-player chunk streaming, chunk unloading, event hooks, metrics

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
local EventBus          = require(script.Parent.EventBus)

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local WorldGenerator = {}

local currentSeed    = 0
local initialized    = false
local activeChunks   = {}
local chunkRefCount  = {}
local worldReady     = false
local metrics        = { chunksGenerated = 0, chunksUnloaded = 0, totalPlayers = 0 }

function WorldGenerator.GetSeed()      return currentSeed   end
function WorldGenerator.IsReady()      return worldReady    end
function WorldGenerator.GetMetrics()   return metrics       end
function WorldGenerator.SetSeed(s)
	currentSeed = s
	SeedPersistence.Save(s)
	EventBus.emit("World:SeedChanged", s)
end

function WorldGenerator.GenerateChunk(cx, cz)
	local key = cx .. "," .. cz
	if activeChunks[key] then return end
	activeChunks[key] = true
	metrics.chunksGenerated += 1

	local worldX = cx * WorldConfig.Settings.ChunkSize
	local worldZ = cz * WorldConfig.Settings.ChunkSize

	ChunkHandler.GenerateChunk(worldX, worldZ, currentSeed)
	LODManager.RegisterChunk(cx, cz, nil)
	OreGenerator.PlaceOres(worldX, worldZ, currentSeed)
	RiverCarver.CarveAt(worldX, worldZ, currentSeed)
	DungeonGenerator.TrySpawnAt(worldX, worldZ, currentSeed)
	VillageGenerator.TrySpawnAt(worldX, worldZ, currentSeed)

	EventBus.emit("World:ChunkGenerated", cx, cz)
end

function WorldGenerator.UnloadChunk(cx, cz)
	local key = cx .. "," .. cz
	if not activeChunks[key] then return end
	activeChunks[key] = nil
	chunkRefCount[key] = nil
	metrics.chunksUnloaded += 1
	if ChunkHandler.UnloadChunk then
		ChunkHandler.UnloadChunk(
			cx * WorldConfig.Settings.ChunkSize,
			cz * WorldConfig.Settings.ChunkSize
		)
	end
	EventBus.emit("World:ChunkUnloaded", cx, cz)
end

function WorldGenerator.Regenerate(newSeed)
	for key in pairs(activeChunks) do
		local kcx, kcz = key:match("(-?%d+),(-?%d+)")
		if kcx then
			WorldGenerator.UnloadChunk(tonumber(kcx), tonumber(kcz))
		end
	end
	activeChunks  = {}
	chunkRefCount = {}
	initialized   = false
	worldReady    = false
	WorldGenerator.SetSeed(newSeed or math.random(1, 2^31 - 1))
	WorldGenerator.Init(currentSeed)
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

	print("[WorldGenerator] v3.0 | Seed:", currentSeed)

	PlayerPersistence.Start()
	WeatherManager.Start(currentSeed)
	StreamingManager.Start(currentSeed)
	MobSpawner.Start(currentSeed)
	QuestSystem.Start(currentSeed)
	NPCDialogue.Start(currentSeed)
	DayNightCycle.Start(0.5)
	LODManager.Start()
	AdminPanel.Init(WorldGenerator, MobSpawner)

	local SYNC_RADIUS = 1
	local rd = WorldConfig.Settings.RenderDistance or 3

	print("[WorldGenerator] Generating spawn terrain (sync, radius", SYNC_RADIUS, ")...")
	for dx = -SYNC_RADIUS, SYNC_RADIUS do
		for dz = -SYNC_RADIUS, SYNC_RADIUS do
			WorldGenerator.GenerateChunk(dx, dz)
		end
	end
	print("[WorldGenerator] Spawn terrain ready — worldReady = true")
	worldReady = true
	EventBus.emit("World:Ready", currentSeed)

	for dx = -rd, rd do
		for dz = -rd, rd do
			if math.abs(dx) > SYNC_RADIUS or math.abs(dz) > SYNC_RADIUS then
				task.spawn(WorldGenerator.GenerateChunk, dx, dz)
			end
		end
	end

	Players.PlayerAdded:Connect(function(player)
		metrics.totalPlayers += 1
		EventBus.emit("World:PlayerAdded", player)
		player.CharacterAdded:Connect(function()
			WorldGenerator._TrackPlayer(player)
		end)
	end)
	Players.PlayerRemoving:Connect(function()
		metrics.totalPlayers = math.max(0, metrics.totalPlayers - 1)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			metrics.totalPlayers += 1
			WorldGenerator._TrackPlayer(player)
		end
	end

	task.spawn(function()
		while true do
			task.wait(60)
			local active = 0
			for _ in pairs(activeChunks) do active += 1 end
			print(string.format(
				"[WorldGenerator] +%d -%d active:%d players:%d",
				metrics.chunksGenerated, metrics.chunksUnloaded,
				active, metrics.totalPlayers
			))
		end
	end)
end

function WorldGenerator._TrackPlayer(player)
	local lastCX, lastCZ = nil, nil
	local prevChunks     = {}
	local rd             = WorldConfig.Settings.RenderDistance or 3
	local UNLOAD_MARGIN  = 2

	RunService.Heartbeat:Connect(function()
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local cfg = WorldConfig.Settings
		local cx  = math.floor(root.Position.X / cfg.ChunkSize)
		local cz  = math.floor(root.Position.Z / cfg.ChunkSize)
		if cx == lastCX and cz == lastCZ then return end
		lastCX, lastCZ = cx, cz

		local newChunks = {}
		for dx = -rd, rd do
			for dz = -rd, rd do
				local key = (cx+dx) .. "," .. (cz+dz)
				newChunks[key] = true
				task.spawn(WorldGenerator.GenerateChunk, cx+dx, cz+dz)
			end
		end

		local unloadR = rd + UNLOAD_MARGIN
		for key in pairs(prevChunks) do
			if not newChunks[key] then
				local kcx, kcz = key:match("(-?%d+),(-?%d+)")
				if kcx then
					if math.abs(tonumber(kcx)-cx) > unloadR or
					   math.abs(tonumber(kcz)-cz) > unloadR then
						task.spawn(WorldGenerator.UnloadChunk, tonumber(kcx), tonumber(kcz))
					end
				end
			end
		end
		prevChunks = newChunks
	end)
end

return WorldGenerator
