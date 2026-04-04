--!strict
-- ============================================================
-- MODULE: ChunkPredictor  [v1.1 - fixed]
-- Predicts which chunks a player will need next based on velocity
-- and pre-queues them for generation.
-- ============================================================

local WorldConfig      = require(script.Parent.WorldConfig)
local StreamingManager = require(script.Parent.StreamingManager)

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local ChunkPredictor = {}

local PREDICT_SECONDS = 3   -- how far ahead to predict (seconds)
local UPDATE_RATE     = 0.5 -- how often to run prediction (seconds)

local playerVelocities: { [number]: Vector3 } = {}
local lastPositions:    { [number]: Vector3 } = {}
local lastUpdate = 0

local function getChunkCoord(pos: Vector3): (number, number)
	local cs = WorldConfig.Settings.ChunkSize
	return math.floor(pos.X / cs), math.floor(pos.Z / cs)
end

local function updateVelocity(player: Player)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local pid = player.UserId
	local prev = lastPositions[pid]
	if prev then
		playerVelocities[pid] = (root.Position - prev) / UPDATE_RATE
	end
	lastPositions[pid] = root.Position
end

local function predictChunks(player: Player)
	local pid = player.UserId
	local vel = playerVelocities[pid]
	if not vel then return end

	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local futurePos = root.Position + vel * PREDICT_SECONDS
	local cx, cz = getChunkCoord(futurePos)

	for dx = -1, 1 do
		for dz = -1, 1 do
			StreamingManager.RequestChunk(cx + dx, cz + dz)
		end
	end
end

function ChunkPredictor.Start()
	RunService.Heartbeat:Connect(function(dt)
		lastUpdate += dt
		if lastUpdate < UPDATE_RATE then return end
		lastUpdate = 0

		for _, player in ipairs(Players:GetPlayers()) do
			updateVelocity(player)
			predictChunks(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerVelocities[player.UserId] = nil
		lastPositions[player.UserId]    = nil
	end)
end

return ChunkPredictor
