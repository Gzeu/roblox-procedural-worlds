-- SkillSystem.lua
-- XP gain, level-up, skill tree (active + passive), cooldown tracking
-- v2.6.0

local WorldConfig = require(script.Parent.WorldConfig)
local SkillSystem = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ── Config ─────────────────────────────────────────────────────────
local MAX_LEVEL        = WorldConfig.MAX_PLAYER_LEVEL or 50
local XP_BASE          = WorldConfig.XP_BASE          or 100   -- XP for level 1
local XP_EXPONENT      = WorldConfig.XP_EXPONENT       or 1.4
local SKILL_POINTS_PER = WorldConfig.SKILL_POINTS_PER  or 1

-- Skill catalogue
local SKILLS = WorldConfig.SKILLS or {
	{ id="Swordsmanship", type="Passive", maxRank=5, statBonus={ meleeDmg=0.08 } },
	{ id="Archery",       type="Passive", maxRank=5, statBonus={ rangedDmg=0.10 } },
	{ id="Toughness",     type="Passive", maxRank=5, statBonus={ maxHp=20 } },
	{ id="Fireball",      type="Active",  maxRank=3, cooldown=6,  manaCost=25 },
	{ id="Blink",         type="Active",  maxRank=3, cooldown=12, manaCost=40 },
	{ id="Heal",          type="Active",  maxRank=3, cooldown=18, manaCost=35 },
}

-- ── State ──────────────────────────────────────────────────────────
local profiles    = {}  -- [userId] = { xp, level, skillPoints, ranks, cooldowns }

-- ── Helpers ────────────────────────────────────────────────────────
local function xpRequired(level)
	return math.floor(XP_BASE * (level ^ XP_EXPONENT))
end

local function newProfile()
	local ranks = {}
	for _, sk in SKILLS do ranks[sk.id] = 0 end
	return { xp=0, level=1, skillPoints=0, ranks=ranks, cooldowns={} }
end

local function findSkill(id)
	for _, s in SKILLS do if s.id == id then return s end end
	return nil
end

-- ── Public API ─────────────────────────────────────────────────────
function SkillSystem.RegisterPlayer(player)
	profiles[player.UserId] = newProfile()
end

function SkillSystem.UnregisterPlayer(player)
	profiles[player.UserId] = nil
end

---Awards XP; handles level-ups.
function SkillSystem.AwardXP(player, amount)
	local prof = profiles[player.UserId]
	if not prof then return end
	if prof.level >= MAX_LEVEL then return end
	prof.xp += amount
	while prof.level < MAX_LEVEL and prof.xp >= xpRequired(prof.level) do
		prof.xp    -= xpRequired(prof.level)
		prof.level += 1
		prof.skillPoints += SKILL_POINTS_PER
		if WorldConfig.Debug then
			warn("[SkillSystem]", player.Name, "leveled up to", prof.level)
		end
	end
end

---Invests one skill point into skillId. Returns success, reason.
function SkillSystem.UpgradeSkill(player, skillId)
	local prof = profiles[player.UserId]
	if not prof then return false, "no_profile" end
	local sk = findSkill(skillId)
	if not sk then return false, "unknown_skill" end
	if prof.skillPoints < 1 then return false, "no_points" end
	if prof.ranks[skillId] >= sk.maxRank then return false, "max_rank" end
	prof.skillPoints -= 1
	prof.ranks[skillId] += 1
	return true, "ok"
end

---Activates an active skill. Returns success, reason.
function SkillSystem.UseSkill(player, skillId)
	local prof = profiles[player.UserId]
	if not prof then return false, "no_profile" end
	local sk = findSkill(skillId)
	if not sk or sk.type ~= "Active" then return false, "not_active" end
	if prof.ranks[skillId] < 1 then return false, "not_learned" end
	local now = os.clock()
	local ready = prof.cooldowns[skillId] or 0
	if now < ready then return false, "on_cooldown" end
	prof.cooldowns[skillId] = now + (sk.cooldown or 0)
	return true, "ok"
end

function SkillSystem.GetProfile(player)
	return profiles[player.UserId]
end

function SkillSystem.GetSkillCatalogue()
	return SKILLS
end

function SkillSystem.Init()
	Players.PlayerAdded:Connect(SkillSystem.RegisterPlayer)
	Players.PlayerRemoving:Connect(SkillSystem.UnregisterPlayer)
	for _, p in Players:GetPlayers() do
		SkillSystem.RegisterPlayer(p)
	end
end

function SkillSystem.Start() end

return SkillSystem
