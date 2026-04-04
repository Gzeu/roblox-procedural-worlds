-- WorldGenerator.lua
-- Master orchestrator — all subsystems
-- v2.7.0 — FIX: initial chunks generated SYNC so player never spawns in void

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

local currentSeed   = 0
local initialized   = false
local activeChunks  = {}
local worldReady    = false   -- set to true after initial terrain is done

function WorldGenerator.GetSeed()    return currentSeed end
function WorldGenerator.IsReady()    return worldReady  end
function WorldGenerator.SetSeed(s)   currentSeed = s; SeedPersistence.Save(s) end

-- ── Generate one chunk (idempotent) ────────────────────────────────────
function WorldGenerator.GenerateChunk(cx, cz)
	local key = cx .. "," .. cz
	if activeChunks[key] then return end
	activeChunks[key] = true

	local worldX = cx * WorldConfig.Settings.ChunkSize
	local worldZ = cz * WorldConfig.Settings.ChunkSize

	ChunkHandler.GenerateChunk(worldX, worldZ, currentSeed)
	LODManager.RegisterChunk(cx, cz, nil)
	OreGenerator.PlaceOres(worldX, worldZ, currentSeed)
	RiverCarver.CarveAt(worldX, worldZ, currentSeed)
	DungeonGenerator.TrySpawnAt(worldX, worldZ, currentSeed)
	VillageGenerator.TrySpawnAt(worldX, worldZ, currentSeed)
end

-- ── Init ───────────────────────────────────────────────────────────────
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

	-- ── CRITICAL FIX: generate spawn-area chunks SYNCHRONOUSLY ────────
	-- Players must not be allowed in until terrain at (0,0) exists.
	-- We generate a tight 1-chunk radius sync first, then async outer ring.
	local rd = WorldConfig.Settings.RenderDistance or 3
	local SYNC_RADIUS = 1  -- guaranteed before first spawn

	print("[WorldGenerator] Generating spawn terrain (sync)...")
	for dx = -SYNC_RADIUS, SYNC_RADIUS do
		for dz = -SYNC_RADIUS, SYNC_RADIUS do
			WorldGenerator.GenerateChunk(dx, dz)   -- blocking call
		end
	end
	print("[WorldGenerator] Spawn terrain ready — players may enter.")
	worldReady = true

	-- Outer chunks async (no blocking)
	for dx = -rd, rd do
		for dz = -rd, rd do
			if math.abs(dx) > SYNC_RADIUS or math.abs(dz) > SYNC_RADIUS then
				task.spawn(WorldGenerator.GenerateChunk, dx, dz)
			end
		end
	end

	-- Track players for dynamic streaming
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			WorldGenerator._TrackPlayer(player)
		end)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then WorldGenerator._TrackPlayer(player) end
	end
end

-- ── Track player position and stream nearby chunks ─────────────────────
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
