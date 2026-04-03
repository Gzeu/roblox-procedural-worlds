-- init.server.lua
-- Bootstrap entry point: loads all modules in dependency order
-- v2.5 | roblox-procedural-worlds

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Core modules
local EventBus         = require(script.Parent.EventBus)
local WorldConfig      = require(script.Parent.WorldConfig)
local SeedPersistence  = require(script.Parent.SeedPersistence)
local WorldGenerator   = require(script.Parent.WorldGenerator)
local ChunkHandler     = require(script.Parent.ChunkHandler)
local StreamingManager = require(script.Parent.StreamingManager)
local BiomeResolver    = require(script.Parent.BiomeResolver)
local LODManager       = require(script.Parent.LODManager)

-- World features
local AssetPlacer      = require(script.Parent.AssetPlacer)
local StructurePlacer  = require(script.Parent.StructurePlacer)
local OreGenerator     = require(script.Parent.OreGenerator)
local RiverCarver      = require(script.Parent.RiverCarver)
local VillageGenerator = require(script.Parent.VillageGenerator)
local DungeonGenerator = require(script.Parent.DungeonGenerator)
local MobSpawner       = require(script.Parent.MobSpawner)
local DayNightCycle    = require(script.Parent.DayNightCycle)
local WeatherManager   = require(script.Parent.WeatherManager)

-- Player systems
local Inventory          = require(script.Parent.Inventory)
local PlayerPersistence  = require(script.Parent.PlayerPersistence)
local QuestSystem        = require(script.Parent.QuestSystem)
local CombatSystem       = require(script.Parent.CombatSystem)
local NPCDialogue        = require(script.Parent.NPCDialogue)
local LootTable          = require(script.Parent.LootTable)

-- v2.5 new modules
local CraftingSystem   = require(script.Parent.CraftingSystem)
local TeleportManager  = require(script.Parent.TeleportManager)
local ParticleEffects  = require(script.Parent.ParticleEffects)

print("[ProceduralWorlds] Initializing v2.5...")

-- Generate or restore world seed
local seed = SeedPersistence.loadSeed() or SeedPersistence.generateSeed()
print("[ProceduralWorlds] World seed: " .. tostring(seed))

-- Boot world generator
WorldGenerator.init(seed, WorldConfig)

-- Start ambient systems
DayNightCycle.start(WorldConfig.DAY_LENGTH_SECONDS)
WeatherManager.start()

-- Register default waypoints
TeleportManager.registerWaypoint("Spawn",   Vector3.new(0, 50, 0))
TeleportManager.registerWaypoint("Market",  Vector3.new(300, 50, 0))
TeleportManager.registerWaypoint("Dungeon", Vector3.new(-600, 30, 400))

-- Global event hooks (debug)
if WorldConfig.EVENT_BUS_DEBUG then
	EventBus.on("CraftingSystem:CraftSuccess", function(player, recipe)
		print("[DEBUG] " .. player.Name .. " crafted: " .. recipe)
	end)
	EventBus.on("TeleportManager:PlayerTeleported", function(player, pos)
		print("[DEBUG] " .. player.Name .. " teleported to " .. tostring(pos))
	end)
end

-- Player lifecycle
Players.PlayerAdded:Connect(function(player)
	PlayerPersistence.onJoin(player)
	QuestSystem.initPlayer(player)
	EventBus.emit("Player:Joined", player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerPersistence.onLeave(player)
	EventBus.emit("Player:Left", player)
end)

print("[ProceduralWorlds] v2.5 ready!")
