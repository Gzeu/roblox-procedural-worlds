--!strict
-- ============================================================
-- MODULE: ProceduralQuestGen
-- Generates infinite, unique quests based on:
--   - Player level + stats
--   - Current biome
--   - Active faction relations
--   - World seed (reproducible per player per day)
-- Extends and replaces QUEST_TEMPLATES from QuestSystem.
-- v1.0.0 | roblox-procedural-worlds
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldConfig       = require(ReplicatedStorage:WaitForChild("WorldConfig"))
local LootTable         = require(ReplicatedStorage:WaitForChild("LootTable"))

local ProceduralQuestGen = {}

-- ── Quest DNA ────────────────────────────────────────────────────
-- Each dimension picks randomly — combinations = 5×8×5×4 = 800 base variants
-- Multiplied by biome + mob + count variance = effectively infinite

local VERBS = {
	kill     = { "Slay",    "Eliminate", "Hunt",    "Destroy",  "Purge"   },
	explore  = { "Discover","Scout",     "Map",      "Survey",   "Chart"   },
	collect  = { "Gather",  "Retrieve",  "Salvage",  "Harvest",  "Collect" },
	deliver  = { "Deliver", "Transport", "Escort",   "Smuggle",  "Return"  },
	survive  = { "Survive", "Endure",    "Withstand","Outlast",  "Resist"  },
	boss     = { "Defeat",  "Vanquish",  "Conquer",  "Overthrow","Slay"    },
	craft    = { "Forge",   "Craft",     "Build",    "Assemble", "Create"  },
	defend   = { "Protect", "Guard",     "Defend",   "Shield",   "Secure"  },
}

local ADJECTIVES = {
	"Ancient", "Cursed", "Stolen", "Sacred", "Corrupted",
	"Legendary", "Forgotten", "Dire", "Enchanted", "Forbidden",
}

local QUEST_TYPES: { {
	type:       string,
	baseReward: string,
	countMin:   number,
	countMax:   number,
	biomeBonus: { [string]: number }?,
}} = {
	{ type="kill",    baseReward="Uncommon", countMin=3,  countMax=15,
	  biomeBonus={ Volcanic=2, Jungle=1, Swamp=1 } },

	{ type="explore", baseReward="Common",   countMin=2,  countMax=10,
	  biomeBonus={ Tundra=1, Desert=1, Ocean=2 } },

	{ type="collect", baseReward="Common",   countMin=5,  countMax=20,
	  biomeBonus={ Forest=1, Grassland=1 } },

	{ type="deliver", baseReward="Rare",     countMin=1,  countMax=3,
	  biomeBonus={} },

	{ type="survive", baseReward="Uncommon", countMin=3,  countMax=10,
	  biomeBonus={ Volcanic=2, Swamp=1 } },

	{ type="boss",    baseReward="Legendary",countMin=1,  countMax=1,
	  biomeBonus={ Volcanic=3 } },

	{ type="craft",   baseReward="Uncommon", countMin=1,  countMax=5,
	  biomeBonus={} },

	{ type="defend",  baseReward="Rare",     countMin=1,  countMax=3,
	  biomeBonus={ Grassland=1, Forest=1 } },
}

local REWARD_TIERS = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
local TIER_INDEX   = { Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5 }

-- ── Internal Helpers ─────────────────────────────────────────────

local function rngPick<T>(rng: Random, t: {T}): T
	return t[rng:NextInteger(1, #t)]
end

local function upgradeTier(tier: string, steps: number): string
	local idx = math.min((TIER_INDEX[tier] or 1) + steps, #REWARD_TIERS)
	return REWARD_TIERS[idx]
end

local function getBiomeMobs(biomeName: string): { string }
	local mobs = {}
	for _, mob in ipairs(WorldConfig.MOBS or {}) do
		for _, b in ipairs(mob.biomes or {}) do
			if b == biomeName then
				table.insert(mobs, mob.name)
				break
			end
		end
	end
	if #mobs == 0 then mobs = { "Goblin", "Skeleton", "Troll" } end
	return mobs
end

local function levelToTierBonus(level: number): number
	if level >= 50 then return 3
	elseif level >= 25 then return 2
	elseif level >= 10 then return 1
	else return 0
	end
end

-- ── Quest Title Builder ───────────────────────────────────────────

local function buildTitle(rng: Random, qtype: string, biomeName: string, mob: string): string
	local verb = rngPick(rng, VERBS[qtype] or VERBS.kill)
	local adj  = rngPick(rng, ADJECTIVES)

	if qtype == "kill" then
		return verb .. " the " .. adj .. " " .. mob
	elseif qtype == "explore" then
		return verb .. " the " .. adj .. " " .. biomeName
	elseif qtype == "collect" then
		return verb .. " " .. adj .. " Resources"
	elseif qtype == "boss" then
		return verb .. " the " .. adj .. " " .. biomeName .. " Boss"
	elseif qtype == "defend" then
		return verb .. " the " .. adj .. " Outpost"
	else
		return verb .. " " .. adj .. " " .. qtype:sub(1,1):upper() .. qtype:sub(2)
	end
end

-- ── Quest Description Builder ────────────────────────────────────

local DESC_TEMPLATES: { [string]: { string } } = {
	kill    = {
		"The {biome} is overrun — eliminate {count} {mob} before they spread.",
		"A bounty has been placed on {count} {mob} terrorizing the {biome}.",
		"Prove your worth: slay {count} {mob} in the heart of {biome}.",
	},
	explore = {
		"Uncharted territory awaits — discover {count} new regions in {biome}.",
		"Map {count} unexplored chunks deep within the {biome}.",
	},
	collect = {
		"Gather {count} rare materials hidden across the {biome}.",
		"The faction needs {count} resources. Harvest them from {biome}.",
	},
	deliver = {
		"Transport {count} cargo packages safely through hostile territory.",
		"A merchant needs {count} deliveries completed before nightfall.",
	},
	survive = {
		"Endure {count} minutes in the deadly {biome} without dying.",
		"Survive a {count}-minute siege in the heart of {biome}.",
	},
	boss    = {
		"The {biome} boss has awakened. Defeat it before chaos spreads.",
		"Earn legendary status: vanquish the guardian of {biome}.",
	},
	craft   = {
		"Forge {count} enchanted items using materials from {biome}.",
		"The faction demands {count} crafted weapons of quality.",
	},
	defend  = {
		"Protect the outpost against {count} incoming attack waves.",
		"Hold the line — defend the settlement from {count} enemy waves.",
	},
}

local function buildDesc(rng: Random, qtype: string, count: number, biome: string, mob: string): string
	local templates = DESC_TEMPLATES[qtype] or DESC_TEMPLATES.kill
	local template  = rngPick(rng, templates)
	return template
		:gsub("{count}", tostring(count))
		:gsub("{biome}", biome)
		:gsub("{mob}",   mob)
end

-- ── Public API ───────────────────────────────────────────────────

export type Quest = {
	id:          number,
	type:        string,
	title:       string,
	description: string,
	biome:       string,
	mob:         string,
	targetCount: number,
	progress:    number,
	completed:   boolean,
	rewardTier:  string,
	reward:      any,
	expiresAt:   number,  -- os.clock() deadline
	factionId:   string?,
}

--- Generate a single procedural quest.
--- @param seed       Deterministic seed (player UserId + day + index)
--- @param level      Player level (affects reward tier)
--- @param biomeName  Current or target biome
--- @param factionId  Optional faction context
function ProceduralQuestGen.Generate(
	seed:      number,
	level:     number,
	biomeName: string,
	factionId: string?
): Quest
	local rng      = Random.new(seed)
	local qDef     = rngPick(rng, QUEST_TYPES)
	local mobs     = getBiomeMobs(biomeName)
	local mob      = rngPick(rng, mobs)

	-- Scale count by level
	local levelScale = 1 + math.floor(level / 10) * 0.2
	local count = math.round(
		rng:NextInteger(qDef.countMin, qDef.countMax) * levelScale
	)

	-- Reward tier = base + level bonus + biome bonus
	local tierBonus = levelToTierBonus(level)
	local biomeBonus = (qDef.biomeBonus and qDef.biomeBonus[biomeName]) or 0
	local rewardTier = upgradeTier(qDef.baseReward, tierBonus + biomeBonus)

	local title = buildTitle(rng, qDef.type, biomeName, mob)
	local desc  = buildDesc(rng, qDef.type, count, biomeName, mob)
	local reward = LootTable.Generate(rewardTier, seed + 999)

	-- Quest expires in 20–60 minutes depending on type
	local durations = { boss=3600, defend=1800, deliver=1200 }
	local duration  = durations[qDef.type] or rng:NextInteger(1200, 3600)

	return {
		id          = seed,
		type        = qDef.type,
		title       = title,
		description = desc,
		biome       = biomeName,
		mob         = mob,
		targetCount = count,
		progress    = 0,
		completed   = false,
		rewardTier  = rewardTier,
		reward      = reward,
		expiresAt   = os.clock() + duration,
		factionId   = factionId,
	} :: Quest
end

--- Generate a batch of quests for a player.
function ProceduralQuestGen.GenerateBatch(
	playerId:  number,
	worldSeed: number,
	level:     number,
	biomeName: string,
	count:     number?,
	factionId: string?
): { Quest }
	local qty    = count or 3
	local quests = {}
	-- Day-based seed so quests refresh daily but are reproducible
	local day    = math.floor(os.time() / 86400)
	local base   = worldSeed + playerId + day * 1000

	for i = 1, qty do
		table.insert(quests,
			ProceduralQuestGen.Generate(base + i * 97, level, biomeName, factionId)
		)
	end
	return quests
end

return ProceduralQuestGen
