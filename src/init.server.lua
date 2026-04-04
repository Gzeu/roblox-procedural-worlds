-- init.server.lua
-- Bootstrap entry point: loads all modules in dependency order
-- v7.2 | roblox-procedural-worlds
--
-- IMPORTANT: All ModuleScripts are CHILDREN of this Script (ProceduralWorldsServer).
-- So we use require(script.ModuleName), NOT require(script.Parent.ModuleName).

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

-- LAYER 0: Infrastructure (no deps)
local EventBus            = require(script.EventBus)
local WorldConfig         = require(script.WorldConfig)
local DataStoreManager    = require(script.DataStoreManager)
local SeedPersistence     = require(script.SeedPersistence)
local AntiExploit         = require(script.AntiExploit)
local NotificationBridge  = require(script.NotificationBridge)

-- LAYER 1: World Generation
local WorldGenerator   = require(script.WorldGenerator)
local ChunkHandler     = require(script.ChunkHandler)
local StreamingManager = require(script.StreamingManager)
local BiomeResolver    = require(script.BiomeResolver)
local LODManager       = require(script.LODManager)
local ChunkPredictor   = require(script.ChunkPredictor)
local ObjectPool       = require(script.ObjectPool)

-- LAYER 2: World Features
local AssetPlacer      = require(script.AssetPlacer)
local StructurePlacer  = require(script.StructurePlacer)
local OreGenerator     = require(script.OreGenerator)
local RiverCarver      = require(script.RiverCarver)
local VillageGenerator = require(script.VillageGenerator)
local DungeonGenerator = require(script.DungeonGenerator)
local FactionSystem    = require(script.FactionSystem)
local DayNightCycle    = require(script.DayNightCycle)
local WeatherManager   = require(script.WeatherManager)

-- LAYER 3: Player Systems
local Inventory           = require(script.Inventory)
local InventoryRemote     = require(script.InventoryRemote)
local PlayerPersistence   = require(script.PlayerPersistence)
local QuestSystem         = require(script.QuestSystem)
local ProceduralQuestGen  = require(script.ProceduralQuestGen)
local CombatSystem        = require(script.CombatSystem)
local LootTable           = require(script.LootTable)
local CraftingSystem      = require(script.CraftingSystem)
local TeleportManager     = require(script.TeleportManager)
local ParticleEffects     = require(script.ParticleEffects)
local AdminPanel          = require(script.AdminPanel)

-- LAYER 4: AI Systems
local MobAI           = require(script.MobAI)
local MobSpawner      = require(script.MobSpawner)
local AINavigator     = require(script.AINavigator)
local BehaviorTree    = require(script.BehaviorTree)
local AIDirector      = require(script.AIDirector)
local AIConfig        = require(script.AIConfig)
local AIMemory        = require(script.AIMemory)
local AIGroupBehavior = require(script.AIGroupBehavior)

-- LAYER 5: RPG + Economy
local SkillSystem     = require(script.SkillSystem)
local BossEncounter   = require(script.BossEncounter)
local NPCDialogue     = require(script.NPCDialogue)
local FightingStyles  = require(script.FightingStyles)
local AwakenSystem    = require(script.AwakenSystem)
local ClanSystem      = require(script.ClanSystem)
local RunModifiers    = require(script.RunModifiers)
local BaseBuilding    = require(script.BaseBuilding)
local EconomyManager  = require(script.EconomyManager)
local SeedShare       = require(script.SeedShare)

-- LAYER 6: Animation + Sound (v7.0)
local AnimationManager = require(script.AnimationManager)
local SoundManager     = require(script.SoundManager)

-- LAYER 7: Monetization + Social
local GamepassManager         = require(script.GamepassManager)
local DeveloperProductHandler = require(script.DeveloperProductHandler)
local PremiumPerks            = require(script.PremiumPerks)
local LeaderboardManager      = require(script.LeaderboardManager)
local DailyRewards            = require(script.DailyRewards)

print("[ProceduralWorlds] Initializing v7.2")

-- BOOT SEQUENCE

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
local seed = SeedPersistence.Load() or math.random(1, 2^31 - 1)
print("[ProceduralWorlds] World seed: " .. tostring(seed))

-- 3. Init world -- BLOCKING until spawn terrain is ready
WorldGenerator.Init(seed)

-- 4. Seed sharing
SeedShare.HookChatCommand({
    seed       = seed,
    noiseScale = WorldConfig.NOISE_SCALE   or 0.008,
    seaLevel   = WorldConfig.SEA_LEVEL     or 40,
    heightMult = WorldConfig.HEIGHT_MULT   or 120,
})

-- 5. Predictive streaming
ChunkPredictor.Start(seed)

-- 6. Ambient systems
DayNightCycle.Start(WorldConfig.DAY_LENGTH_SECONDS or 240)
WeatherManager.Start()
FactionSystem.Start()

-- 7. Waypoints
TeleportManager.registerWaypoint("Spawn",    Vector3.new(0,     50,  0))
TeleportManager.registerWaypoint("Market",   Vector3.new(300,   50,  0))
TeleportManager.registerWaypoint("Dungeon",  Vector3.new(-600,  30,  400))
TeleportManager.registerWaypoint("Arena",    Vector3.new(800,   50, -200))
TeleportManager.registerWaypoint("BossLair", Vector3.new(-1200, 30,  800))
TeleportManager.registerWaypoint("Sanctum",  Vector3.new(1500,  60,  1500))

-- SPAWN GUARD
-- Prevents players from falling before terrain is ready.
local SAFE_SPAWN_Y = 80

local function guardSpawn(player)
    player.CharacterAdded:Connect(function(character)
        if not WorldGenerator.IsReady() then
            repeat task.wait(0.1) until WorldGenerator.IsReady()
        end
        task.wait(0.1)
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(0, SAFE_SPAWN_Y, 0)
        end
    end)
end

-- EVENT BUS HOOKS

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
        local xp     = bossModel:GetAttribute("XPReward") or (WorldConfig.BOSS_BASE_XP or 500)
        local scaled = PremiumPerks.ScaleXP(killerPlayer, xp)
        SkillSystem.awardXP(killerPlayer, scaled)
        AwakenSystem.grantEnergy(killerPlayer, bossModel:GetAttribute("AwakenEnergyReward") or 40)
        local kills = (killerPlayer:GetAttribute("BossKills") or 0) + 1
        killerPlayer:SetAttribute("BossKills", kills)
        LeaderboardManager.OnBossKill(killerPlayer, kills)
        NotificationBridge.Notify(killerPlayer, {
            category = "SYSTEM",
            title    = "Boss Defeated!",
            body     = bossModel.Name .. " slain! " .. scaled .. " XP earned.",
            duration = 6,
        })
    end
end)

EventBus.on("Boss:Spawned", function(bossModel, spawnPos)
    if spawnPos then NotificationBridge.BossSpawn(spawnPos, bossModel.Name) end
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

-- PLAYER LIFECYCLE

Players.PlayerAdded:Connect(function(player)
    guardSpawn(player)
    DataStoreManager.Load(player)
    PlayerPersistence.onJoin(player)
    QuestSystem.initPlayer(player)
    SkillSystem.getStats(player)
    ClanSystem.initPlayer(player)
    FightingStyles.initPlayer(player)
    AwakenSystem.initPlayer(player)
    EconomyManager.initPlayer(player)
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

print("[ProceduralWorlds] v7.2 ready -- all modules loaded as script children.")
