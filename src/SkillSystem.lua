-- SkillSystem.lua
-- RPG attribute system: XP → LevelUp → SkillPoints → 4 attributes
-- Attributes: Strength, Agility, Intelligence, Endurance
-- v4.0 | roblox-procedural-worlds

local Players    = game:GetService("Players")
local EventBus   = require(script.Parent.EventBus)
local WorldConfig = require(script.Parent.WorldConfig)

local SkillSystem = {}

-- ── XP curve: XP needed for level N = BASE * N^EXPONENT ─────────
local XP_BASE     = 100
local XP_EXPONENT = 1.45
local MAX_LEVEL   = 100

-- ── Attribute bonuses per point ─────────────────────────────────
-- Strength:     +2 melee damage, +5 carry weight
-- Agility:      +0.5 move speed, +3% dodge chance cap
-- Intelligence: +5% XP gain bonus, +2 magic damage
-- Endurance:    +10 max HP, +1 HP regen per 10s
local ATTR_BONUSES = {
	Strength     = { meleeDamage = 2,   carryWeight = 5    },
	Agility      = { moveSpeed   = 0.5, dodgeChance = 0.03 },
	Intelligence = { xpBonus     = 0.05,magicDamage = 2    },
	Endurance    = { maxHP       = 10,  hpRegen     = 1    },
}

-- ── Per-player data ──────────────────────────────────────────────
-- { level, xp, skillPoints, attributes = {S,A,I,E}, bonuses = {} }
local playerData = {}

local function initData()
	return {
		level       = 1,
		xp          = 0,
		xpToNext    = XP_BASE,
		skillPoints = 0,
		attributes  = {
			Strength     = 0,
			Agility      = 0,
			Intelligence = 0,
			Endurance    = 0,
		},
		bonuses = {
			meleeDamage  = 0,
			carryWeight  = 0,
			moveSpeed    = 0,
			dodgeChance  = 0,
			xpBonus      = 0,
			magicDamage  = 0,
			maxHP        = 0,
			hpRegen      = 0,
		},
	}
end

local function xpForLevel(level)
	return math.floor(XP_BASE * (level ^ XP_EXPONENT))
end

local function recomputeBonuses(data)
	for bonus in pairs(data.bonuses) do
		data.bonuses[bonus] = 0
	end
	for attr, points in pairs(data.attributes) do
		local bonusTable = ATTR_BONUSES[attr]
		if bonusTable then
			for bonus, perPoint in pairs(bonusTable) do
				data.bonuses[bonus] = (data.bonuses[bonus] or 0) + perPoint * points
			end
		end
	end
end

-- ── Public API ───────────────────────────────────────────────────

function SkillSystem.getStats(player)
	local uid = player.UserId
	if not playerData[uid] then
		playerData[uid] = initData()
	end
	return playerData[uid]
end

function SkillSystem.awardXP(player, amount)
	local data = SkillSystem.getStats(player)
	-- Apply intelligence XP bonus
	local bonus = 1 + data.bonuses.xpBonus
	local earned = math.floor(amount * bonus)
	data.xp = data.xp + earned
	EventBus.emit("SkillSystem:XPGained", player, earned, data.xp)

	-- Level up loop
	while data.xp >= data.xpToNext and data.level < MAX_LEVEL do
		data.xp       = data.xp - data.xpToNext
		data.level    = data.level + 1
		data.xpToNext = xpForLevel(data.level)
		data.skillPoints = data.skillPoints + WorldConfig.SKILL_POINTS_PER_LEVEL
		EventBus.emit("SkillSystem:LevelUp", player, data.level, data.skillPoints)
		if WorldConfig.EVENT_BUS_DEBUG then
			warn(string.format("[SkillSystem] %s → Level %d (+%d SP)",
				player.Name, data.level, WorldConfig.SKILL_POINTS_PER_LEVEL))
		end
	end
end

function SkillSystem.spendPoint(player, attribute)
	local data = SkillSystem.getStats(player)
	if data.skillPoints <= 0 then
		return false, "No skill points available"
	end
	if not ATTR_BONUSES[attribute] then
		return false, "Unknown attribute: " .. tostring(attribute)
	end
	local cap = WorldConfig.SKILL_ATTRIBUTE_CAP or 50
	if data.attributes[attribute] >= cap then
		return false, "Attribute at cap"
	end
	data.skillPoints             = data.skillPoints - 1
	data.attributes[attribute]   = data.attributes[attribute] + 1
	recomputeBonuses(data)
	EventBus.emit("SkillSystem:PointSpent", player, attribute, data.attributes[attribute])
	return true
end

function SkillSystem.getBonus(player, bonusKey)
	local data = SkillSystem.getStats(player)
	return data.bonuses[bonusKey] or 0
end

function SkillSystem.getLevel(player)
	return SkillSystem.getStats(player).level
end

function SkillSystem.getXPProgress(player)
	local data = SkillSystem.getStats(player)
	return data.xp, data.xpToNext, data.level
end

-- ── Hook: award XP on mob kill via EventBus ──────────────────────
EventBus.on("MobAI:Died", function(mobModel, killer)
	if killer and killer:IsA("Player") then
		local xpAmount = mobModel:GetAttribute("XPReward") or
			(WorldConfig.MOB_BASE_XP or 20)
		SkillSystem.awardXP(killer, xpAmount)
	end
end)

-- ── Hook: award XP on boss kill ──────────────────────────────────
EventBus.on("BossEncounter:Defeated", function(bossModel, killer)
	if killer and killer:IsA("Player") then
		local xpAmount = bossModel:GetAttribute("XPReward") or
			(WorldConfig.BOSS_BASE_XP or 500)
		SkillSystem.awardXP(killer, xpAmount)
	end
end)

-- ── Cleanup ──────────────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
	playerData[player.UserId] = nil
end)

return SkillSystem
