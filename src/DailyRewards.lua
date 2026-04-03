--!strict
-- ============================================================
-- MODULE: DailyRewards
-- Daily login streak system.
-- Day 1: 50 coins   Day 2: 100   Day 3: 200
-- Day 4: 300 coins  Day 5: 500   Day 6: 750
-- Day 7: 1000 coins + Legendary item
-- Streak resets if player misses >24 hours since last claim.
-- v1.0.0 | roblox-procedural-worlds
-- ============================================================

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")

local DailyRewards = {}

local STORE = DataStoreService:GetDataStore("DailyRewards_v1")

local STREAK_REWARDS: { { coins: number, item: string? } } = {
	{ coins = 50  },
	{ coins = 100 },
	{ coins = 200 },
	{ coins = 300 },
	{ coins = 500 },
	{ coins = 750 },
	{ coins = 1000, item = "Legendary" },
}

local RESET_WINDOW = 86400 * 2  -- 48 hours grace window before streak resets

export type StreakData = {
	streak:    number,
	lastClaim: number,  -- os.time()
}

-- ── DataStore Helpers ─────────────────────────────────────────────

local function loadStreak(userId: number): StreakData
	local ok, data = pcall(STORE.GetAsync, STORE, tostring(userId))
	if ok and data then return data end
	return { streak = 0, lastClaim = 0 }
end

local function saveStreak(userId: number, data: StreakData)
	pcall(STORE.SetAsync, STORE, tostring(userId), data)
end

-- ── Claim Logic ────────────────────────────────────────────────────

export type ClaimResult = {
	success:   boolean,
	coins:     number,
	item:      string?,
	streak:    number,
	nextReset: number,  -- seconds until streak resets
	message:   string,
}

--- Attempt to claim today's reward. Returns ClaimResult.
function DailyRewards.Claim(player: Player): ClaimResult
	local userId = player.UserId
	local data   = loadStreak(userId)
	local now    = os.time()
	local elapsed = now - data.lastClaim

	-- Already claimed today?
	if elapsed < 86400 then
		return {
			success   = false,
			coins     = 0,
			streak    = data.streak,
			nextReset = 86400 - elapsed,
			message   = string.format("Come back in %dh %dm!",
				math.floor((86400 - elapsed) / 3600),
				math.floor(((86400 - elapsed) % 3600) / 60)),
		}
	end

	-- Streak reset?
	if elapsed > RESET_WINDOW then
		data.streak = 0
	end

	data.streak    = (data.streak % #STREAK_REWARDS) + 1
	data.lastClaim = now

	local reward = STREAK_REWARDS[data.streak]

	-- Apply coins via EconomyManager if available
	local ok, EconomyManager = pcall(require,
		game:GetService("ReplicatedStorage"):WaitForChild("EconomyManager"))
	if ok and EconomyManager then
		EconomyManager.addBalance(player, reward.coins)
	end

	saveStreak(userId, data)

	return {
		success   = true,
		coins     = reward.coins,
		item      = reward.item,
		streak    = data.streak,
		nextReset = 86400,
		message   = string.format("Day %d reward: %d coins%s!",
			data.streak,
			reward.coins,
			reward.item and " + " .. reward.item or ""),
	}
end

--- Get streak info without claiming.
function DailyRewards.GetInfo(player: Player): StreakData & { canClaim: boolean, nextDay: number }
	local data    = loadStreak(player.UserId)
	local elapsed = os.time() - data.lastClaim
	return {
		streak    = data.streak,
		lastClaim = data.lastClaim,
		canClaim  = elapsed >= 86400,
		nextDay   = (data.streak % #STREAK_REWARDS) + 1,
	}
end

-- ── Lifecycle ────────────────────────────────────────────────────

function DailyRewards.Start()
	-- Auto-claim prompt on join (sets attribute; GUI reacts client-side)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			task.wait(3)  -- wait for character + UI to load
			local info = DailyRewards.GetInfo(player)
			player:SetAttribute("DailyCanClaim", info.canClaim)
			player:SetAttribute("DailyStreak",   info.streak)
			player:SetAttribute("DailyNextDay",  info.nextDay)
		end)
	end)
end

return DailyRewards
