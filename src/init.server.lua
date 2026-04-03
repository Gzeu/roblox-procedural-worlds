-- init.server.lua
-- Bootstrap entry point: loads all modules in dependency order
-- v4.0 | roblox-procedural-worlds

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
local LootTable          = require(script.Parent.LootTable)
local CraftingSystem     = require(script.Parent.CraftingSystem)
local TeleportManager    = require(script.Parent.TeleportManager)
local ParticleEffects    = require(script.Parent.ParticleEffects)
local AdminPanel         = require(script.Parent.AdminPanel)

-- ── v3.0 AI systems ──────────────────────────────────────────────
local MobAI        = require(script.Parent.MobAI)
local AINavigator  = require(script.Parent.AINavigator)
local BehaviorTree = require(script.Parent.BehaviorTree)
local AIDirector   = require(script.Parent.AIDirector)
local AIConfig     = require(script.Parent.AIConfig)

-- ── v4.0 AI + RPG systems ────────────────────────────────────────
local AIMemory        = require(script.Parent.AIMemory)
local AIGroupBehavior = require(script.Parent.AIGroupBehavior)
local SkillSystem     = require(script.Parent.SkillSystem)
local BossEncounter   = require(script.Parent.BossEncounter)
local NPCDialogue     = require(script.Parent.NPCDialogue)

print("[ProceduralWorlds] Initializing v4.0...")

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
TeleportManager.registerWaypoint("BossLair",Vector3.new(-1200, 30, 800))

-- ── EventBus global hooks ────────────────────────────────────────

-- Mob death: loot drop + particles + memory wipe
EventBus.on("MobAI:Died", function(mobModel, killer)
	AIMemory.clearMemory(mobModel)
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

-- AI Group: propagate alert to nearby pack members
EventBus.on("AIGroup:Alert", function(packId, alertPos)
	AIGroupBehavior.onAlert(packId, alertPos)
end)

-- AI Group: coordinate retreat when pack health drops below threshold
EventBus.on("AIGroup:Retreat", function(packId)
	AIGroupBehavior.onRetreat(packId)
end)

-- Boss: phase transition notifications
EventBus.on("Boss:PhaseChanged", function(bossModel, phase)
	print(string.format("[BossEncounter] %s entered phase %d", bossModel.Name, phase))
	ParticleEffects.emit(
		bossModel:FindFirstChild("HumanoidRootPart") and
		bossModel.HumanoidRootPart.Position or Vector3.new(),
		"Magic", 1.5
	)
end)

-- Boss: enrage triggered
EventBus.on("Boss:Enraged", function(bossModel)
	print(string.format("[BossEncounter] %s is ENRAGED!", bossModel.Name))
	ParticleEffects.emit(
		bossModel:FindFirstChild("HumanoidRootPart") and
		bossModel.HumanoidRootPart.Position or Vector3.new(),
		"Blood", 2.0
	)
end)

-- Boss: defeated
EventBus.on("Boss:Defeated", function(bossModel, killerPlayer)
	print(string.format("[BossEncounter] %s defeated by %s!",
		bossModel.Name, killerPlayer and killerPlayer.Name or "unknown"))
	if killerPlayer then
		SkillSystem.grantXP(killerPlayer, 500)
	end
end)

-- Skill System: level up celebration
EventBus.on("SkillSystem:LevelUp", function(player, newLevel)
	print(string.format("[SkillSystem] %s reached level %d!", player.Name, newLevel))
	ParticleEffects.emit(
		player.Character and
		player.Character:FindFirstChild("HumanoidRootPart") and
		player.Character.HumanoidRootPart.Position or Vector3.new(),
		"Heal", 1.0
	)
end)

-- NPC Dialogue: quest accepted via dialogue choice
EventBus.on("NPCDialogue:QuestAccepted", function(player, questId)
	QuestSystem.acceptQuest(player, questId)
	print(string.format("[NPCDialogue] %s accepted quest: %s", player.Name, questId))
end)

-- NPC Dialogue: quest completed via dialogue
EventBus.on("NPCDialogue:QuestCompleted", function(player, questId)
	QuestSystem.completeQuest(player, questId)
	SkillSystem.grantXP(player, 100)
end)

-- AIDirector difficulty tracking
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
	EventBus.on("AIMemory:Updated", function(mobModel, memType, value)
		print(string.format("[AIMemory] %s | %s = %s",
			mobModel.Name or "?", memType, tostring(value)))
	end)
end

-- ── Player lifecycle ─────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	PlayerPersistence.onJoin(player)
	QuestSystem.initPlayer(player)
	SkillSystem.initPlayer(player)
	EventBus.emit("Player:Joined", player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerPersistence.onLeave(player)
	SkillSystem.savePlayer(player)
	EventBus.emit("Player:Left", player)
end)

print("[ProceduralWorlds] v4.0 ready! AI Memory, Group Behavior, Skills, Bosses & Dialogue v2 online.")
