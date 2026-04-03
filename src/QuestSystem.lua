-- QuestSystem.lua
-- Procedural quest generation tied to biomes, dungeons, and mobs
-- v2.3.0

local Players       = game:GetService("Players")
local WorldConfig   = require(script.Parent.WorldConfig)
local BiomeResolver = require(script.Parent.BiomeResolver)
local LootTable     = require(script.Parent.LootTable)

local QuestSystem = {}

-- Active quests per player: { [userId] = { quest1, quest2, ... } }
local playerQuests = {}

local QUEST_TEMPLATES = {
	{
		type     = "kill",
		title    = "Exterminator",
		desc     = "Slay {count} {mob} in the {biome}.",
		countMin = 3, countMax = 10,
		rewardTier = "Uncommon",
	},
	{
		type     = "explore",
		title    = "Cartographer",
		desc     = "Discover {count} new chunks in the {biome} biome.",
		countMin = 2, countMax = 8,
		rewardTier = "Common",
	},
	{
		type     = "loot",
		title    = "Treasure Hunter",
		desc     = "Open {count} chests in dungeons.",
		countMin = 1, countMax = 5,
		rewardTier = "Rare",
	},
	{
		type     = "survive",
		title    = "Survivor",
		desc     = "Survive for {count} minutes in the {biome}.",
		countMin = 2, countMax = 10,
		rewardTier = "Uncommon",
	},
	{
		type     = "boss",
		title    = "Dragon Slayer",
		desc     = "Defeat the boss mob of {biome}.",
		countMin = 1, countMax = 1,
		rewardTier = "Legendary",
	},
}

local function pickBiomeName(seed)
	local biomes = WorldConfig.Biomes
	local idx    = (seed % #biomes) + 1
	return biomes[idx].name
end

local function pickMobForBiome(biomeName, seed)
	local pool = WorldConfig.MobSpawns[biomeName] or WorldConfig.MobSpawns.Default
	local idx  = (seed % #pool) + 1
	return pool[idx].name
end

local function generateQuest(player, seed)
	local rng      = Random.new(seed)
	local template = QUEST_TEMPLATES[rng:NextInteger(1, #QUEST_TEMPLATES)]
	local biome    = pickBiomeName(seed)
	local mob      = pickMobForBiome(biome, seed + 1)
	local count    = rng:NextInteger(template.countMin, template.countMax)

	local desc = template.desc
		:gsub("{count}",  tostring(count))
		:gsub("{mob}",    mob)
		:gsub("{biome}",  biome)

	local reward = LootTable.Generate(template.rewardTier, seed + 7)

	return {
		id          = seed,
		type        = template.type,
		title       = template.title,
		description = desc,
		biome       = biome,
		mob         = mob,
		targetCount = count,
		progress    = 0,
		completed   = false,
		reward      = reward,
		rewardTier  = template.rewardTier,
		player      = player,
	}
end

function QuestSystem.AssignQuests(player, seed)
	local userId   = player.UserId
	local rng      = Random.new(seed + userId)
	local quests   = {}
	local questCount = WorldConfig.QuestsPerPlayer or 3

	for i = 1, questCount do
		local questSeed = rng:NextInteger(1, 2^30)
		table.insert(quests, generateQuest(player, questSeed))
	end

	playerQuests[userId] = quests
	return quests
end

function QuestSystem.UpdateProgress(player, questType, amount)
	local userId = player.UserId
	if not playerQuests[userId] then return end

	for _, quest in ipairs(playerQuests[userId]) do
		if quest.type == questType and not quest.completed then
			quest.progress = quest.progress + (amount or 1)
			if quest.progress >= quest.targetCount then
				quest.completed = true
				QuestSystem.OnQuestComplete(player, quest)
			end
		end
	end
end

function QuestSystem.OnQuestComplete(player, quest)
	warn("[QuestSystem] Quest complete:", quest.title, "for", player.Name)
	-- Reward delivery hook — extend this to give items via inventory system
	player:SetAttribute("LastCompletedQuest", quest.title)
	player:SetAttribute("LastRewardTier", quest.rewardTier)
end

function QuestSystem.GetQuests(player)
	return playerQuests[player.UserId] or {}
end

function QuestSystem.Start(worldSeed)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.delay(2, function()
				QuestSystem.AssignQuests(player, worldSeed + player.UserId)
			end)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerQuests[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			QuestSystem.AssignQuests(player, worldSeed + player.UserId)
		end
	end
end

return QuestSystem
