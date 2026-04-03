-- init.server.lua
-- Bootstrap entry point: loads all modules in dependency order
-- v3.0 | roblox-procedural-worlds

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

-- ── Core infrastructure ──────────────────────────────────────────
local EventBus         = require(script.Parent.EventBus)
local WorldConfig      = require(script.Parent.WorldConfig)
local SeedPersistence  = require(script.Parent.SeedPersistence)
local WorldGenerator   = require(script.Parent.WorldGenerator)
local ChunkHandler     = require(script.Parent.ChunkHandler)
local StreamingManager = require(script.Parent.StreamingManager)
local BiomeResolver    = require(script.Parent.BiomeResolver)
local LODManager       = require(script.Parent.LODManager)

-- ── World features ───────────────────────────────────────────────
local AssetPlacer      = require(script.Parent.AssetPlacer)
local StructurePlacer  = require(script.Parent.StructurePlacer)
local OreGenerator     = require(script.Parent.OreGenerator)
local RiverCarver      = require(script.Parent.RiverCarver)
local VillageGenerator = require(script.Parent.VillageGenerator)
local DungeonGenerator = require(script.Parent.DungeonGenerator)
local MobSpawner       = require(script.Parent.MobSpawner)
local DayNightCycle    = require(script.Parent.DayNightCycle)
local WeatherManager   = require(script.Parent.WeatherManager)

-- ── Player systems ───────────────────────────────────────────────
local Inventory          = require(script.Parent.Inventory)
local PlayerPersistence  = require(script.Parent.PlayerPersistence)
local QuestSystem        = require(script.Parent.QuestSystem)
local CombatSystem       = require(script.Parent.CombatSystem)
local NPCDialogue        = require(script.Parent.NPCDialogue)
local LootTable          = require(script.Parent.LootTable)
local CraftingSystem     = require(script.Parent.CraftingSystem)
local TeleportManager    = require(script.Parent.TeleportManager)
local ParticleEffects    = require(script.Parent.ParticleEffects)

-- ── v3.0 AI systems ──────────────────────────────────────────────
local MobAI        = require(script.Parent.MobAI)
local AINavigator  = require(script.Parent.AINavigator)
local BehaviorTree = require(script.Parent.BehaviorTree)
local AIDirector   = require(script.Parent.AIDirector)
local AIConfig     = require(script.Parent.AIConfig)

print("[ProceduralWorlds] Initializing v3.0...")

-- ── World seed ───────────────────────────────────────────────────
local seed = SeedPersistence.loadSeed() or SeedPersistence.generateSeed()
print("[ProceduralWorlds] World seed: " .. tostring(seed))
WorldGenerator.init(seed, WorldConfig)

-- ── Ambient systems ──────────────────────────────────────────────
DayNightCycle.start(WorldConfig.DAY_LENGTH_SECONDS)
WeatherManager.start()

-- ── Default waypoints ────────────────────────────────────────────
TeleportManager.registerWaypoint("Spawn",   Vector3.new(0,   50,  0))
TeleportManager.registerWaypoint("Market",  Vector3.new(300, 50,  0))
TeleportManager.registerWaypoint("Dungeon", Vector3.new(-600,30,  400))
TeleportManager.registerWaypoint("Arena",   Vector3.new(800, 50, -200))

-- ── EventBus global hooks ────────────────────────────────────────
EventBus.on("MobAI:Died", function(mobModel, killer)
	if killer then
		local loot = LootTable.roll(mobModel.Name or "Goblin")
		EventBus.emit("LootTable:Dropped", mobModel, loot)
		ParticleEffects.emit(
			mobModel:FindFirstChild("HumanoidRootPart") and
			mobModel.HumanoidRootPart.Position or Vector3.new(),
			"Spark", 0.4
		)
	end
end)

EventBus.on("AIDirector:ScoreUpdated", function(player, score, tierName)
	if WorldConfig.EVENT_BUS_DEBUG then
		print(string.format("[AIDirector] %s | score=%.2f tier=%s",
			player.Name, score, tierName))
	end
end)

if WorldConfig.EVENT_BUS_DEBUG then
	EventBus.on("MobAI:StateChanged", function(model, prev, next)
		print(string.format("[MobAI] %s: %s → %s", model.Name or "?", prev, next))
	end)
end

-- ── Player lifecycle ─────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	PlayerPersistence.onJoin(player)
	QuestSystem.initPlayer(player)
	EventBus.emit("Player:Joined", player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerPersistence.onLeave(player)
	EventBus.emit("Player:Left", player)
end)

print("[ProceduralWorlds] v3.0 ready! AI systems online.")
