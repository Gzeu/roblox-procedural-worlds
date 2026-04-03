--!strict
-- ============================================================
-- MODULE: LeaderboardManager
-- Global ordered DataStore leaderboards:
--   CHUNKS_EXPLORED  — most chunks discovered
--   BOSS_KILLS       — most boss defeats
--   GOLD_EARNED      — total economy gold
--   FACTION_POWER    — total faction territory controlled
-- Updates lazily on stat change (max 1 write per 60s per stat per player).
-- v1.0.0 | roblox-procedural-worlds
-- ============================================================

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")

local LeaderboardManager = {}

local BOARDS = {
	CHUNKS_EXPLORED = DataStoreService:GetOrderedDataStore("lb_chunks_v1"),
	BOSS_KILLS      = DataStoreService:GetOrderedDataStore("lb_boss_v1"),
	GOLD_EARNED     = DataStoreService:GetOrderedDataStore("lb_gold_v1"),
	FACTION_POWER   = DataStoreService:GetOrderedDataStore("lb_faction_v1"),
}

local WRITE_COOLDOWN = 60   -- seconds between writes per (player, board)
local TOP_N          = 10   -- entries per page

-- Cooldown tracker: { [userId..boardName] = lastWriteTime }
local writeCooldown: { [string]: number } = {}

-- ── Write ────────────────────────────────────────────────────────

--- Submit a score to a leaderboard. Respects cooldown.
function LeaderboardManager.Submit(player: Player, boardName: string, value: number)
	local ds = BOARDS[boardName]
	if not ds then
		warn("[Leaderboard] Unknown board:", boardName)
		return
	end

	local key = tostring(player.UserId) .. boardName
	local now = os.clock()
	if (writeCooldown[key] or 0) + WRITE_COOLDOWN > now then return end
	writeCooldown[key] = now

	task.spawn(function()
		local ok, err = pcall(ds.SetAsync, ds, tostring(player.UserId), math.floor(value))
		if not ok then
			warn("[Leaderboard] SetAsync failed:", boardName, err)
		end
	end)
end

-- ── Read ──────────────────────────────────────────────────────────

export type LeaderboardEntry = { rank: number, userId: number, score: number, name: string }

--- Fetch top N entries from a board.
--- @param boardName string
--- @param count     number (default TOP_N)
function LeaderboardManager.GetTop(boardName: string, count: number?): { LeaderboardEntry }
	local ds = BOARDS[boardName]
	if not ds then return {} end

	local pages
	local ok, err = pcall(function()
		pages = ds:GetSortedAsync(false, count or TOP_N)
	end)
	if not ok then
		warn("[Leaderboard] GetSortedAsync failed:", boardName, err)
		return {}
	end

	local results: { LeaderboardEntry } = {}
	local page = pages:GetCurrentPage()
	for rank, entry in ipairs(page) do
		local userId = tonumber(entry.key) or 0
		local name   = "Player"
		local nameOk, resolvedName = pcall(game.Players.GetNameFromUserIdAsync, Players, userId)
		if nameOk then name = resolvedName end
		table.insert(results, {
			rank   = rank,
			userId = userId,
			score  = entry.value,
			name   = name,
		})
	end
	return results
end

--- Get a single player's score on a board.
function LeaderboardManager.GetScore(player: Player, boardName: string): number
	local ds = BOARDS[boardName]
	if not ds then return 0 end
	local ok, val = pcall(ds.GetAsync, ds, tostring(player.UserId))
	if ok and val then return val end
	return 0
end

-- ── Auto-update hooks ─────────────────────────────────────────────
-- Called from EventBus handlers in init.server.lua

function LeaderboardManager.OnChunkExplored(player: Player, totalChunks: number)
	LeaderboardManager.Submit(player, "CHUNKS_EXPLORED", totalChunks)
end

function LeaderboardManager.OnBossKill(player: Player, totalKills: number)
	LeaderboardManager.Submit(player, "BOSS_KILLS", totalKills)
end

function LeaderboardManager.OnGoldEarned(player: Player, totalGold: number)
	LeaderboardManager.Submit(player, "GOLD_EARNED", totalGold)
end

function LeaderboardManager.Start()
	-- Nothing needed on start; hooks called externally
	print("[Leaderboard] Online — boards: CHUNKS_EXPLORED, BOSS_KILLS, GOLD_EARNED, FACTION_POWER")
end

return LeaderboardManager
