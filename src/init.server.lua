-- init.server.lua
-- Bootstrap entry point: loads all modules in dependency order
-- v6.0 | roblox-procedural-worlds
-- Phase 4: Monetization + Stability + Social

local Players = game:GetService("Players")

-- ── LAYER 0: Infrastructure (no deps) ─────────────────────────────

local EventBus            = require(script.Parent.EventBus)
local WorldConfig         = require(script.Parent.WorldConfig)
local DataStoreManager    = require(script.Parent.DataStoreManager)
local SeedPersistence     = require(script.Parent.SeedPersistence)
local AntiExploit         = require(script.Parent.AntiExploit)
local NotificationBridge  = require(script.Parent.NotificationBridge)

-- ── LAYER 1: World Generation ─────────────────────────────────────

local WorldGenerator   = require(script.Parent.WorldGenerator)
local ChunkHandler     = require(script.Parent.ChunkHandler)
local StreamingManager = require(script.Parent.StreamingManager)
local BiomeResolver    = require(script.Parent.BiomeResolver)
local LODManager       = require(script.Parent.LODManager)
local ChunkPredictor   = require(script.Parent.ChunkPredictor)
local ObjectPool       = require(script.Parent.ObjectPool)

-- ── LAYER 2: World Features ───────────────────────────────────────

local AssetPlacer      = require(script.Parent.AssetPlacer)
local StructurePlacer  = require(script.Parent.StructurePlacer)
local OreGenerator     = require(script.Parent.OreGenerator)
local RiverCarver      = require(script.Parent.RiverCarver)
local VillageGenerator = require(script.Parent.VillageGenerator)
local DungeonGenerator = require(script.Parent.DungeonGenerator)
local FactionSystem    = require(script.Parent.FactionSystem)
local DayNightCycle    = require(script.Parent.DayNightCycle)
local WeatherManager   = require(script.Parent.WeatherManager)

-- ── LAYER 3: Player Systems ───────────────────────────────────────

local Inventory           = require(script.Parent.Inventory)
local PlayerPersistence   = require(script.Parent.PlayerPersistence)
local QuestSystem         = require(script.Parent.QuestSystem)
local ProceduralQuestGen  = require(script.Parent.ProceduralQuestGen)
local CombatSystem        = require(script.Parent.CombatSystem)
local LootTable           = require(script.Parent.LootTable)
local CraftingSystem      = require(script.Parent.CraftingSystem)
local TeleportManager     = require(script.Parent.TeleportManager)
local ParticleEffects     = require(script.Parent.ParticleEffects)
local AdminPanel          = require(script.Parent.AdminPanel)

-- ── LAYER 4: AI Systems ─────────────────────────────────────────

local MobAI           = require(script.Parent.MobAI)
local MobSpawner      = require(script.Parent.MobSpawner)
local AINavigator     = require(script.Parent.AINavigator)
local BehaviorTree    = require(script.Parent.BehaviorTree)
local AIDirector      = require(script.Parent.AIDirector)
local AIConfig        = require(script.Parent.AIConfig)
local AIMemory        = require(script.Parent.AIMemory)
local AIGroupBehavior = require(script.Parent.AIGroupBehavior)

-- ── LAYER 5: RPG + Economy ───────────────────────────────────────

local SkillSystem     = require(script.Parent.SkillSystem)
local BossEncounter   = require(script.Parent.BossEncounter)
local NPCDialogue     = require(script.Parent.NPCDialogue)
local FightingStyles  = require(script.Parent.FightingStyles)
local AwakenSystem    = require(script.Parent.AwakenSystem)
local ClanSystem      = require(script.Parent.ClanSystem)
local RunModifiers    = require(script.Parent.RunModifiers)
local BaseBuilding    = require(script.Parent.BaseBuilding)
local EconomyManager  = require(script.Parent.EconomyManager)
local SeedShare       = require(script.Parent.SeedShare)

-- ── LAYER 6: Monetization + Social (Phase 4) ──────────────────

local GamepassManager        = require(script.Parent.GamepassManager)
local DeveloperProductHandler = require(script.Parent.DeveloperProductHandler)
local PremiumPerks           = require(script.Parent.PremiumPerks)
local LeaderboardManager     = require(script.Parent.LeaderboardManager)
local DailyRewards           = require(script.Parent.DailyRewards)

print("[ProceduralWorlds] ╔══════════════════════════════╗")
print("[ProceduralWorlds] ║  Initializing v6.0 (Phase 4)     ║")
print("[ProceduralWorlds] ╚══════════════════════════════╝")

-- ── BOOT SEQUENCE ──────────────────────────────────────────────────

-- 1. Infrastructure
DataStoreManager.Start()
AntiExploit.Start()
NotificationBridge.Start()
GamepassManager.Start()
DeveloperProductHandler.Start()
PremiumPerks.Start()
LeaderboardManager.Start()
DailyRewards.Start()

-- 2. World seed
local seed = SeedPersistence.loadSeed() or SeedPersistence.generateSeed()
print("[ProceduralWorlds] World seed: " .. tostring(seed))
WorldGenerator.init(seed, WorldConfig)

-- 3. Seed sharing
SeedShare.HookChatCommand({
	seed       = seed,
	noiseScale = WorldConfig.NOISE_SCALE   or 0.008,
	seaLevel   = WorldConfig.SEA_LEVEL     or 40,
	heightMult = WorldConfig.HEIGHT_MULT   or 120,
})

-- 4. Predictive streaming
ChunkPredictor.Start(seed)

-- 5. Ambient systems
DayNightCycle.start(WorldConfig.DAY_LENGTH_SECONDS)
WeatherManager.start()
FactionSystem.Start()

-- 6. Waypoints
TeleportManager.registerWaypoint("Spawn",    Vector3.new(0,     50,  0))
TeleportManager.registerWaypoint("Market",   Vector3.new(300,   50,  0))
TeleportManager.registerWaypoint("Dungeon",  Vector3.new(-600,  30,  400))
TeleportManager.registerWaypoint("Arena",    Vector3.new(800,   50, -200))
TeleportManager.registerWaypoint("BossLair", Vector3.new(-1200, 30,  800))
TeleportManager.registerWaypoint("Sanctum",  Vector3.new(1500,  60,  1500))

-- ── EVENT BUS HOOKS ──────────────────────────────────────────────

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
	ParticleEffects.emit(
		bossModel:FindFirstChild("HumanoidRootPart") and bossModel.HumanoidRootPart.Position or Vector3.new(),
		"Blood", 2.0
	)
end)

EventBus.on("Boss:Defeated", function(bossModel, killerPlayer)
	print(string.format("[BossEncounter] %s defeated by %s!",
		bossModel.Name, killerPlayer and killerPlayer.Name or "unknown"))
	if killerPlayer and killerPlayer:IsA("Player") then
		local xp  = bossModel:GetAttribute("XPReward") or (WorldConfig.BOSS_BASE_XP or 500)
		local scaled = PremiumPerks.ScaleXP(killerPlayer, xp)
		SkillSystem.awardXP(killerPlayer, scaled)
		AwakenSystem.grantEnergy(killerPlayer, bossModel:GetAttribute("AwakenEnergyReward") or 40)
		-- Leaderboard
		local kills = (killerPlayer:GetAttribute("BossKills") or 0) + 1
		killerPlayer:SetAttribute("BossKills", kills)
		LeaderboardManager.OnBossKill(killerPlayer, kills)
		-- Notification
		NotificationBridge.Notify(killerPlayer, {
			category = "SYSTEM",
			title    = "🐲 Boss Defeated!",
			body     = bossModel.Name .. " slain! " .. scaled .. " XP earned.",
			duration = 6,
		})
	end
end)

EventBus.on("Boss:Spawned", function(bossModel, spawnPos)
	if spawnPos then
		NotificationBridge.BossSpawn(spawnPos, bossModel.Name)
	end
end)

EventBus.on("SkillSystem:LevelUp", function(player, newLevel)
	ParticleEffects.emit(
		player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			and player.Character.HumanoidRootPart.Position or Vector3.new(),
		"Heal", 1.0
	)
	if newLevel >= 5  then FightingStyles.unlockStyle(player, "Rogue")     end
	if newLevel >= 10 then FightingStyles.unlockStyle(player, "Mystic")    end
	if newLevel >= 20 then FightingStyles.unlockStyle(player, "Berserker") end
	NotificationBridge.LevelUp(player, newLevel)
end)

EventBus.on("NPCDialogue:QuestAccepted",  function(player, questId) QuestSystem.acceptQuest(player, questId) end)
EventBus.on("NPCDialogue:QuestCompleted", function(player, questId)
	QuestSystem.completeQuest(player, questId)
	local scaled = PremiumPerks.ScaleXP(player, 100)
	SkillSystem.awardXP(player, scaled)
	local quest = QuestSystem.GetQuestById and QuestSystem.GetQuestById(player, questId)
	if quest then
		NotificationBridge.QuestComplete(player, quest.title or questId, quest.rewardTier or "Common")
	end
end)

EventBus.on("Chunk:Explored", function(player, totalChunks)
	LeaderboardManager.OnChunkExplored(player, totalChunks)
end)

EventBus.on("Economy:Purchased", function(buyer, listingId, quantity, total)
	local totalGold = (buyer:GetAttribute("TotalGoldEarned") or 0) + total
	buyer:SetAttribute("TotalGoldEarned", totalGold)
	LeaderboardManager.OnGoldEarned(buyer, totalGold)
end)

EventBus.on("FactionSystem:Conquered", function(player, cx, cz, newFactionId)
	FactionSystem.ConquerChunk(cx, cz, newFactionId, player)
end)

if WorldConfig.EVENT_BUS_DEBUG then
	EventBus.on("MobAI:StateChanged",     function(m, p, n) print(string.format("[MobAI] %s: %s -> %s", m.Name or "?", p, n)) end)
	EventBus.on("FightingStyles:Changed", function(p, s) print(string.format("[FightingStyles] %s -> %s", p.Name, s)) end)
	EventBus.on("AwakenSystem:Activated", function(p, s) print(string.format("[AwakenSystem] %s activated %s", p.Name, s)) end)
	EventBus.on("ClanSystem:Assigned",    function(p, c) print(string.format("[ClanSystem] %s -> clan %s", p.Name, c)) end)
end

-- ── PLAYER LIFECYCLE ─────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
	-- Core data first
	DataStoreManager.Load(player)
	PlayerPersistence.onJoin(player)
	-- Systems
	QuestSystem.initPlayer(player)
	SkillSystem.getStats(player)
	ClanSystem.initPlayer(player)
	FightingStyles.initPlayer(player)
	AwakenSystem.initPlayer(player)
	EconomyManager.initPlayer(player)
	-- Phase 4
	FactionSystem.Start()  -- idempotent
	-- Daily reward check (async)
	task.spawn(function()
		task.wait(3)
		local info = DailyRewards.GetInfo(player)
		if info.canClaim then
			NotificationBridge.DailyReady(player, info.nextDay)
		end
	end)
	EventBus.emit("Player:Joined", player)
end)

Players.PlayerRemoving:Connect(function(player)
	DataStoreManager.Flush(player)
	PlayerPersistence.onLeave(player)
	EventBus.emit("Player:Left", player)
end)

print("[ProceduralWorlds] v6.0 ready.")
print("[ProceduralWorlds] Modules: DataStore, AntiExploit, NotificationBridge,")
print("[ProceduralWorlds]          Gamepasses, DevProducts, PremiumPerks,")
print("[ProceduralWorlds]          Leaderboards, DailyRewards, ChunkPredictor,")
print("[ProceduralWorlds]          FactionSystem, ProceduralQuestGen, SeedShare.")
