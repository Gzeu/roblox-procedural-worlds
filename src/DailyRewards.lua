-- DailyRewards.lua
-- Streak-based daily reward system with escalating rewards
-- v2.5.0

local WorldConfig = require(script.Parent.WorldConfig)
local DailyRewards = {}

local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local DailyStore = DataStoreService:GetDataStore("DailyRewardsV1")

-- ── Config ─────────────────────────────────────────────────────────
local STREAK_TABLE = WorldConfig.DAILY_REWARD_STREAK or {
	-- day = { gold, xp, bonus? }
	[1]  = { gold=50,   xp=100 },
	[2]  = { gold=60,   xp=120 },
	[3]  = { gold=75,   xp=150 },
	[4]  = { gold=90,   xp=180 },
	[5]  = { gold=110,  xp=220, bonus="HealthPotion" },
	[6]  = { gold=130,  xp=260 },
	[7]  = { gold=200,  xp=500, bonus="MagicCrystal" },
}
local MAX_STREAK    = 7
local RESET_SECONDS = 86400  -- 24 h

-- ── Helpers ────────────────────────────────────────────────────────
local function loadData(uid)
	local ok, data = pcall(function()
		return DailyStore:GetAsync("daily_" .. uid)
	end)
	return (ok and data) or { streak=0, lastClaim=0 }
end

local function saveData(uid, data)
	pcall(function()
		DailyStore:SetAsync("daily_" .. uid, data)
	end)
end

-- ── Public API ─────────────────────────────────────────────────────

---Attempts to claim today's reward.
---@return boolean, table|string  claimed, reward or reason
function DailyRewards.Claim(player)
	local uid  = player.UserId
	local data = loadData(uid)
	local now  = os.time()

	-- Already claimed today?
	if (now - data.lastClaim) < RESET_SECONDS then
		local remaining = RESET_SECONDS - (now - data.lastClaim)
		return false, { reason="already_claimed", cooldown=remaining }
	end

	-- Streak broken?
	if (now - data.lastClaim) > (RESET_SECONDS * 2) then
		data.streak = 0
	end

	data.streak = math.min(data.streak + 1, MAX_STREAK)
	data.lastClaim = now

	local reward = STREAK_TABLE[data.streak] or STREAK_TABLE[MAX_STREAK]

	saveData(uid, data)

	if WorldConfig.Debug then
		warn("[DailyRewards]", player.Name, "claimed day", data.streak,
			"| gold:", reward.gold, "xp:", reward.xp)
	end

	return true, {
		streak   = data.streak,
		gold     = reward.gold,
		xp       = reward.xp,
		bonus    = reward.bonus,
	}
end

---Returns next claim info without claiming.
function DailyRewards.GetStatus(player)
	local data = loadData(player.UserId)
	local now  = os.time()
	local elapsed = now - data.lastClaim
	return {
		streak      = data.streak,
		canClaim    = elapsed >= RESET_SECONDS,
		cooldown    = math.max(0, RESET_SECONDS - elapsed),
		nextReward  = STREAK_TABLE[math.min(data.streak + 1, MAX_STREAK)],
	}
end

function DailyRewards.Init()
	Players.PlayerAdded:Connect(function(player)
		if WorldConfig.Debug then
			warn("[DailyRewards] Player joined:", player.Name)
		end
	end)
end

function DailyRewards.Start() end

return DailyRewards
