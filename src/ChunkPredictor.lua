--!strict
-- ============================================================
-- MODULE: ChunkPredictor
-- Predicts which chunks a player will need next based on
-- velocity + heading, pre-queues them before the player arrives.
-- Eliminates loading gaps at runtime.
-- v1.0.0 | roblox-procedural-worlds
-- ============================================================

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig   = require(ReplicatedStorage:WaitForChild("WorldConfig"))
local ChunkHandler  = require(ReplicatedStorage:WaitForChild("ChunkHandler"))

local ChunkPredictor = {}

-- Internal state
local playerState: { [number]: {
	prevPos:    Vector3,
	velocity:   Vector3,
	loadedKeys: { [string]: boolean },
	queuedKeys: { [string]: boolean },
}} = {}

local CHUNK_SIZE      = WorldConfig.CHUNK_SIZE or 64
local PREDICT_AHEAD   = 3        -- how many seconds ahead to predict
local PREDICT_RADIUS  = 2        -- extra chunk radius around predicted pos
local TICK_RATE       = 0.25     -- update interval (seconds)
local MAX_QUEUE_SIZE  = 12       -- max pending chunk loads per player

local loadQueue: { { cx: number, cz: number, playerId: number } } = {}
local isProcessing = false

-- ── Helpers ──────────────────────────────────────────────────────

local function chunkKey(cx: number, cz: number): string
	return cx .. "," .. cz
end

local function worldToChunk(wx: number, wz: number): (number, number)
	return math.floor(wx / CHUNK_SIZE) * CHUNK_SIZE,
	       math.floor(wz / CHUNK_SIZE) * CHUNK_SIZE
end

local function getPlayerRootPos(player: Player): Vector3?
	local char = player.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	return hrp and hrp.Position or nil
end

-- ── Queue Processing ─────────────────────────────────────────────

local function processQueue(seed: number)
	if isProcessing or #loadQueue == 0 then return end
	isProcessing = true

	task.spawn(function()
		while #loadQueue > 0 do
			local entry = table.remove(loadQueue, 1)
			local ok, err = pcall(ChunkHandler.GenerateChunk, entry.cx, entry.cz, seed)
			if not ok then
				warn("[ChunkPredictor] GenerateChunk failed:", err)
			end
			task.wait() -- yield between chunks to avoid frame spike
		end
		isProcessing = false
	end)
end

local function enqueueChunk(cx: number, cz: number, playerId: number, seed: number)
	local state = playerState[playerId]
	if not state then return end

	local key = chunkKey(cx, cz)
	if state.loadedKeys[key] or state.queuedKeys[key] then return end
	if #loadQueue >= MAX_QUEUE_SIZE then return end

	state.queuedKeys[key] = true
	table.insert(loadQueue, { cx = cx, cz = cz, playerId = playerId })
	processQueue(seed)
end

-- ── Core Prediction ──────────────────────────────────────────────

local function predictForPlayer(player: Player, seed: number)
	local userId = player.UserId
	local state  = playerState[userId]
	if not state then return end

	local pos = getPlayerRootPos(player)
	if not pos then return end

	-- Estimate velocity from delta position
	local vel = (pos - state.prevPos) / TICK_RATE
	state.velocity = vel
	state.prevPos  = pos

	-- Predicted future position
	local futurePos = pos + vel * PREDICT_AHEAD

	-- Enqueue chunks around predicted position
	local baseCX, baseCZ = worldToChunk(futurePos.X, futurePos.Z)

	for dx = -PREDICT_RADIUS, PREDICT_RADIUS do
		for dz = -PREDICT_RADIUS, PREDICT_RADIUS do
			enqueueChunk(
				baseCX + dx * CHUNK_SIZE,
				baseCZ + dz * CHUNK_SIZE,
				userId,
				seed
			)
		end
	end
end

-- ── Public API ───────────────────────────────────────────────────

--- Mark a chunk as loaded so we don't re-queue it.
function ChunkPredictor.MarkLoaded(cx: number, cz: number, playerId: number)
	local state = playerState[playerId]
	if not state then return end
	local key = chunkKey(cx, cz)
	state.loadedKeys[key]  = true
	state.queuedKeys[key]  = nil
end

--- Mark a chunk as unloaded (player moved away).
function ChunkPredictor.MarkUnloaded(cx: number, cz: number, playerId: number)
	local state = playerState[playerId]
	if not state then return end
	local key = chunkKey(cx, cz)
	state.loadedKeys[key] = nil
end

--- Start the prediction loop for the given world seed.
function ChunkPredictor.Start(seed: number)
	-- Track joining players
	Players.PlayerAdded:Connect(function(player)
		local pos = getPlayerRootPos(player) or Vector3.zero
		playerState[player.UserId] = {
			prevPos    = pos,
			velocity   = Vector3.zero,
			loadedKeys = {},
			queuedKeys = {},
		}
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerState[player.UserId] = nil
	end)

	-- Init existing players
	for _, player in ipairs(Players:GetPlayers()) do
		local pos = getPlayerRootPos(player) or Vector3.zero
		playerState[player.UserId] = {
			prevPos    = pos,
			velocity   = Vector3.zero,
			loadedKeys = {},
			queuedKeys = {},
		}
	end

	-- Prediction tick
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < TICK_RATE then return end
		elapsed = 0
		for _, player in ipairs(Players:GetPlayers()) do
			predictForPlayer(player, seed)
		end
	end)

end

return ChunkPredictor
