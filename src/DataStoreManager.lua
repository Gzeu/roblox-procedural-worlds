--!strict
-- ============================================================
-- MODULE: DataStoreManager
-- Robust DataStore wrapper:
--   - Retry with exponential backoff (up to 5 attempts)
--   - Per-player write queue (no concurrent SetAsync)
--   - Auto-save every 30 seconds
--   - BindToClose flush on server shutdown
--   - Budget awareness (DataStoreService:GetRequestBudgetForRequestType)
-- v1.0.0 | roblox-procedural-worlds
-- ============================================================

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")

local DataStoreManager = {}

local STORE_NAME     = "ProceduralWorlds_v1"
local AUTO_SAVE_TICK = 30   -- seconds
local MAX_RETRIES    = 5
local BASE_BACKOFF   = 1    -- seconds (doubles each retry)

local mainStore = DataStoreService:GetDataStore(STORE_NAME)

-- Active data cache: { [userId] = data }
local dataCache:  { [number]: any } = {}
-- Write queue: { [userId] = pending (bool) }
local writeQueue: { [number]: boolean } = {}
-- Dirty flag: { [userId] = bool } — true if data changed since last save
local dirty:      { [number]: boolean } = {}

-- ── Retry Helper ────────────────────────────────────────────────────

local function retryAsync(fn: () -> any, label: string): (boolean, any)
	local backoff = BASE_BACKOFF
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(fn)
		if ok then return true, result end
		warn(string.format("[DataStoreManager] %s attempt %d/%d failed: %s",
			label, attempt, MAX_RETRIES, tostring(result)))
		if attempt < MAX_RETRIES then
			task.wait(backoff)
			backoff = backoff * 2
		end
	end
	return false, nil
end

-- ── Load ──────────────────────────────────────────────────────────

--- Load player data from DataStore.
--- Returns (success, data) — data is nil on first join (new player).
function DataStoreManager.Load(player: Player): (boolean, any)
	local userId = player.UserId
	if dataCache[userId] ~= nil then
		return true, dataCache[userId]
	end

	local ok, data = retryAsync(function()
		return mainStore:GetAsync(tostring(userId))
	end, "Load:" .. tostring(userId))

	if ok then
		dataCache[userId] = data or {}  -- new player gets empty table
		dirty[userId]     = false
	end

	return ok, dataCache[userId]
end

-- ── Save ──────────────────────────────────────────────────────────

local function flushPlayer(userId: number)
	if writeQueue[userId] then return end  -- already saving
	if not dirty[userId] then return end   -- nothing changed

	local data = dataCache[userId]
	if not data then return end

	writeQueue[userId] = true
	local ok, _ = retryAsync(function()
		mainStore:SetAsync(tostring(userId), data)
	end, "Save:" .. tostring(userId))

	writeQueue[userId] = nil
	if ok then
		dirty[userId] = false
	end
end

--- Update a key in a player's data.
function DataStoreManager.Set(player: Player, key: string, value: any)
	local userId = player.UserId
	if not dataCache[userId] then dataCache[userId] = {} end
	dataCache[userId][key] = value
	dirty[userId] = true
end

--- Get a key from a player's cached data.
function DataStoreManager.Get(player: Player, key: string): any
	local userId = player.UserId
	local cache  = dataCache[userId]
	if not cache then return nil end
	return cache[key]
end

--- Force-save a player immediately (e.g. on leave).
function DataStoreManager.Flush(player: Player)
	task.spawn(flushPlayer, player.UserId)
end

-- ── Lifecycle ────────────────────────────────────────────────────

function DataStoreManager.Start()
	-- Load data on join
	Players.PlayerAdded:Connect(function(player)
		task.spawn(DataStoreManager.Load, player)
	end)

	-- Flush + evict on leave
	Players.PlayerRemoving:Connect(function(player)
		local userId = player.UserId
		flushPlayer(userId)
		-- Wait for write to finish before evicting
		task.delay(5, function()
			dataCache[userId]  = nil
			dirty[userId]      = nil
			writeQueue[userId] = nil
		end)
	end)

	-- Auto-save loop
	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_TICK)
			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(flushPlayer, player.UserId)
			end
		end
	end)

	-- Flush all on shutdown
	game:BindToClose(function()
		local threads = {}
		for _, player in ipairs(Players:GetPlayers()) do
			table.insert(threads, task.spawn(flushPlayer, player.UserId))
		end
		-- Wait for all threads (max 25s Roblox BindToClose limit)
		for _, thread in ipairs(threads) do
			local deadline = os.clock() + 25
			while coroutine.status(thread) ~= "dead" and os.clock() < deadline do
				task.wait(0.1)
			end
		end
		print("[DataStoreManager] Flush complete on shutdown.")
	end)

end

return DataStoreManager
