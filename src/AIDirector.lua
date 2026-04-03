-- AIDirector.lua
-- Dynamic Difficulty Adjustment (DDA) system
-- Monitors player performance and scales mob stats, spawn rate, and loot in real-time
-- v3.0 | roblox-procedural-worlds

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local EventBus   = require(script.Parent.EventBus)

local AIDirector = {}
AIDirector.__index = AIDirector

-- ── Difficulty tiers ─────────────────────────────────────────────
local TIERS = {
	{ name = "Trivial",  threshold = -0.6,  damageScale = 0.5,  hpScale = 0.6,  spawnScale = 0.6,  lootBonus = 0.0 },
	{ name = "Easy",     threshold = -0.3,  damageScale = 0.75, hpScale = 0.8,  spawnScale = 0.8,  lootBonus = 0.0 },
	{ name = "Normal",   threshold =  0.0,  damageScale = 1.0,  hpScale = 1.0,  spawnScale = 1.0,  lootBonus = 0.0 },
	{ name = "Hard",     threshold =  0.3,  damageScale = 1.3,  hpScale = 1.3,  spawnScale = 1.2,  lootBonus = 0.1 },
	{ name = "Extreme",  threshold =  0.6,  damageScale = 1.7,  hpScale = 1.7,  spawnScale = 1.5,  lootBonus = 0.25 },
	{ name = "Nightmare",threshold =  0.85, damageScale = 2.2,  hpScale = 2.2,  spawnScale = 1.8,  lootBonus = 0.4 },
}

-- ── Per-player performance tracking ─────────────────────────────
local playerStats = {}
-- Format: { killStreak, deathStreak, avgKillTime, totalKills, totalDeaths, score, lastTick }

local function initStats()
	return {
		killStreak    = 0,
		deathStreak   = 0,
		totalKills    = 0,
		totalDeaths   = 0,
		killTimes     = {},   -- ring buffer of time-between-kills
		score         = 0.0,  -- normalized -1..1 (negative = player struggling)
		tier          = 3,    -- index into TIERS, starts at Normal
	}
end

-- ── Score update ─────────────────────────────────────────────────
-- score moves toward +1 when player kills fast, toward -1 when dying
local KILL_WEIGHT  = 0.15
local DEATH_WEIGHT = 0.25
local DECAY_RATE   = 0.02  -- per second drift toward 0 (regression to mean)

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function scoreToTier(score)
	local idx = 1
	for i, t in ipairs(TIERS) do
		if score >= t.threshold then idx = i end
	end
	return idx
end

-- ── Public API ───────────────────────────────────────────────────

function AIDirector.getPlayerStats(player)
	local uid = player.UserId
	if not playerStats[uid] then
		playerStats[uid] = initStats()
	end
	return playerStats[uid]
end

function AIDirector.onKill(player, mobModel)
	local s = AIDirector.getPlayerStats(player)
	s.killStreak  += 1
	s.deathStreak  = 0
	s.totalKills  += 1
	s.score = clamp(s.score + KILL_WEIGHT, -1, 1)
	s.tier  = scoreToTier(s.score)
	EventBus.emit("AIDirector:ScoreUpdated", player, s.score, TIERS[s.tier].name)
end

function AIDirector.onDeath(player)
	local s = AIDirector.getPlayerStats(player)
	s.deathStreak += 1
	s.killStreak   = 0
	s.totalDeaths += 1
	s.score = clamp(s.score - DEATH_WEIGHT, -1, 1)
	s.tier  = scoreToTier(s.score)
	EventBus.emit("AIDirector:ScoreUpdated", player, s.score, TIERS[s.tier].name)
end

-- Get current difficulty multipliers for a player
function AIDirector.getScaling(player)
	local s = AIDirector.getPlayerStats(player)
	return TIERS[s.tier]
end

-- Get tier name for a player
function AIDirector.getTierName(player)
	local s = AIDirector.getPlayerStats(player)
	return TIERS[s.tier].name
end

-- Apply scaling to a MobAI config (returns modified copy)
function AIDirector.applyScaling(player, baseConfig)
	local scaling = AIDirector.getScaling(player)
	local cfg = {}
	for k, v in pairs(baseConfig) do cfg[k] = v end
	cfg.damage = math.floor((cfg.damage or 10) * scaling.damageScale)
	cfg.maxHP  = math.floor((cfg.maxHP  or 100) * scaling.hpScale)
	return cfg
end

-- ── Score decay loop (server heartbeat) ──────────────────────────
local _lastDecay = os.clock()
RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	if now - _lastDecay < 1 then return end
	_lastDecay = now

	for uid, s in pairs(playerStats) do
		-- Drift score toward 0 over time
		if s.score > 0 then
			s.score = math.max(0, s.score - DECAY_RATE)
		elseif s.score < 0 then
			s.score = math.min(0, s.score + DECAY_RATE)
		end
		s.tier = scoreToTier(s.score)
	end
end)

-- ── Cleanup on leave ─────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
	playerStats[player.UserId] = nil
end)

-- ── Global EventBus hooks ────────────────────────────────────────
EventBus.on("MobAI:Died", function(mobModel, attacker)
	if attacker and attacker:IsA("Player") then
		AIDirector.onKill(attacker, mobModel)
	end
end)

Players.PlayerAdded:Connect(function(player)
	if player.Character then
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Died:Connect(function()
				AIDirector.onDeath(player)
			end)
		end
	end
	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			hum.Died:Connect(function()
				AIDirector.onDeath(player)
			end)
		end
	end)
end)

return AIDirector
