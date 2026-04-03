-- init.server.lua
-- Bootstrap entry point: loads all modules in dependency order
-- v5.0 | roblox-procedural-worlds

local Players = game:GetService("Players")

-- Core infrastructure
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
local Inventory         = require(script.Parent.Inventory)
local PlayerPersistence = require(script.Parent.PlayerPersistence)
local QuestSystem       = require(script.Parent.QuestSystem)
local CombatSystem      = require(script.Parent.CombatSystem)
local LootTable         = require(script.Parent.LootTable)
local CraftingSystem    = require(script.Parent.CraftingSystem)
local TeleportManager   = require(script.Parent.TeleportManager)
local ParticleEffects   = require(script.Parent.ParticleEffects)
local AdminPanel        = require(script.Parent.AdminPanel)

-- v3.0 AI systems
local MobAI        = require(script.Parent.MobAI)
local AINavigator  = require(script.Parent.AINavigator)
local BehaviorTree = require(script.Parent.BehaviorTree)
local AIDirector   = require(script.Parent.AIDirector)
local AIConfig     = require(script.Parent.AIConfig)

-- v4.0 AI + RPG systems
local AIMemory        = require(script.Parent.AIMemory)
local AIGroupBehavior = require(script.Parent.AIGroupBehavior)
local SkillSystem     = require(script.Parent.SkillSystem)
local BossEncounter   = require(script.Parent.BossEncounter)
local NPCDialogue     = require(script.Parent.NPCDialogue)

-- v5.0 anime RPG + roguelite + economy
local FightingStyles = require(script.Parent.FightingStyles)
local AwakenSystem   = require(script.Parent.AwakenSystem)
local ClanSystem     = require(script.Parent.ClanSystem)
local RunModifiers   = require(script.Parent.RunModifiers)
local BaseBuilding   = require(script.Parent.BaseBuilding)
local EconomyManager = require(script.Parent.EconomyManager)

print("[ProceduralWorlds] Initializing v5.0...")

-- World seed
local seed = SeedPersistence.loadSeed() or SeedPersistence.generateSeed()
print("[ProceduralWorlds] World seed: " .. tostring(seed))
WorldGenerator.init(seed, WorldConfig)

-- Ambient systems
DayNightCycle.start(WorldConfig.DAY_LENGTH_SECONDS)
WeatherManager.start()

-- Default waypoints
TeleportManager.registerWaypoint("Spawn",    Vector3.new(0,     50,  0))
TeleportManager.registerWaypoint("Market",   Vector3.new(300,   50,  0))
TeleportManager.registerWaypoint("Dungeon",  Vector3.new(-600,  30,  400))
TeleportManager.registerWaypoint("Arena",    Vector3.new(800,   50, -200))
TeleportManager.registerWaypoint("BossLair", Vector3.new(-1200, 30,  800))
TeleportManager.registerWaypoint("Sanctum",  Vector3.new(1500,  60,  1500))

-- EventBus hooks
EventBus.on("MobAI:Died", function(mobModel, killer)
	AIMemory.clearMemory(mobModel)
	if killer then
		local loot = LootTable.roll(mobModel.Name or "Goblin")
		EventBus.emit("LootTable:Dropped", mobModel, loot)
		ParticleEffects.emit(
			mobModel:FindFirstChild("HumanoidRootPart") and mobModel.HumanoidRootPart.Position or Vector3.new(),
			"Spark", 0.4
		)
		if killer:IsA("Player") then
			AwakenSystem.grantEnergy(killer, mobModel:GetAttribute("AwakenEnergyReward") or 8)
		end
	end
end)

EventBus.on("AIGroup:Alert",   function(packId, alertPos) AIGroupBehavior.onAlert(packId, alertPos) end)
EventBus.on("AIGroup:Retreat", function(packId)           AIGroupBehavior.onRetreat(packId) end)

EventBus.on("Boss:PhaseChanged", function(bossModel, phase)
	print(string.format("[BossEncounter] %s entered phase %d", bossModel.Name, phase))
	ParticleEffects.emit(
		bossModel:FindFirstChild("HumanoidRootPart") and bossModel.HumanoidRootPart.Position or Vector3.new(),
		"Magic", 1.5
	)
end)

EventBus.on("Boss:Enraged", function(bossModel)
	print(string.format("[BossEncounter] %s is ENRAGED!", bossModel.Name))
	ParticleEffects.emit(
		bossModel:FindFirstChild("HumanoidRootPart") and bossModel.HumanoidRootPart.Position or Vector3.new(),
		"Blood", 2.0
	)
end)

EventBus.on("Boss:Defeated", function(bossModel, killerPlayer)
	print(string.format("[BossEncounter] %s defeated by %s!", bossModel.Name, killerPlayer and killerPlayer.Name or "unknown"))
	if killerPlayer and killerPlayer:IsA("Player") then
		SkillSystem.awardXP(killerPlayer, bossModel:GetAttribute("XPReward") or (WorldConfig.BOSS_BASE_XP or 500))
		AwakenSystem.grantEnergy(killerPlayer, bossModel:GetAttribute("AwakenEnergyReward") or 40)
	end
end)

EventBus.on("SkillSystem:LevelUp", function(player, newLevel)
	print(string.format("[SkillSystem] %s reached level %d!", player.Name, newLevel))
	ParticleEffects.emit(
		player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			and player.Character.HumanoidRootPart.Position or Vector3.new(),
		"Heal", 1.0
	)
	if newLevel >= 5  then FightingStyles.unlockStyle(player, "Rogue")     end
	if newLevel >= 10 then FightingStyles.unlockStyle(player, "Mystic")    end
	if newLevel >= 20 then FightingStyles.unlockStyle(player, "Berserker") end
end)

EventBus.on("NPCDialogue:QuestAccepted",  function(player, questId) QuestSystem.acceptQuest(player, questId)  end)
EventBus.on("NPCDialogue:QuestCompleted", function(player, questId)
	QuestSystem.completeQuest(player, questId)
	SkillSystem.awardXP(player, 100)
end)

EventBus.on("RunModifiers:Started", function(runId)
	if WorldConfig.EVENT_BUS_DEBUG then
		print(string.format("[RunModifiers] Run started: %s", tostring(runId)))
	end
end)

EventBus.on("BaseBuilding:Placed", function(player, record)
	if WorldConfig.EVENT_BUS_DEBUG then
		print(string.format("[BaseBuilding] %s placed %s (#%d)", player.Name, tostring(record.templateName), record.id))
	end
end)

EventBus.on("Economy:Purchased", function(buyer, listingId, quantity, total)
	if WorldConfig.EVENT_BUS_DEBUG then
		print(string.format("[Economy] %s bought listing %d x%d for %dg", buyer.Name, listingId, quantity, total))
	end
end)

if WorldConfig.EVENT_BUS_DEBUG then
	EventBus.on("MobAI:StateChanged",    function(model, prev, nxt) print(string.format("[MobAI] %s: %s -> %s", model.Name or "?", prev, nxt)) end)
	EventBus.on("FightingStyles:Changed", function(p, s) print(string.format("[FightingStyles] %s -> %s", p.Name, s)) end)
	EventBus.on("AwakenSystem:Activated", function(p, s) print(string.format("[AwakenSystem] %s activated %s", p.Name, s)) end)
	EventBus.on("ClanSystem:Assigned",    function(p, c) print(string.format("[ClanSystem] %s -> clan %s", p.Name, c)) end)
end

-- Player lifecycle
Players.PlayerAdded:Connect(function(player)
	PlayerPersistence.onJoin(player)
	QuestSystem.initPlayer(player)
	SkillSystem.getStats(player)
	ClanSystem.initPlayer(player)
	FightingStyles.initPlayer(player)
	AwakenSystem.initPlayer(player)
	EconomyManager.initPlayer(player)
	EventBus.emit("Player:Joined", player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerPersistence.onLeave(player)
	EventBus.emit("Player:Left", player)
end)

print("[ProceduralWorlds] v5.0 ready -- FightingStyles, AwakenSystem, ClanSystem, RunModifiers, BaseBuilding, EconomyManager online.")
