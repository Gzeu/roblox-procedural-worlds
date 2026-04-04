--!strict
-- ============================================================
-- MODULE: StreamingManager  [v1.1 - fixed]
-- Manages chunk streaming: load near players, unload far chunks.
-- ============================================================

local WorldConfig = require(script.Parent.WorldConfig)

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local StreamingManager = {}

local loadedChunks:  { [string]: boolean } = {}
local pendingChunks: { string }            = {}
local currentSeed = 0

local WorldGenerator  -- lazy-required to avoid circular dep

local function key(cx: number, cz: number): string
	return cx .. "," .. cz
end

function StreamingManager.RequestChunk(cx: number, cz: number)
	local k = key(cx, cz)
	if loadedChunks[k] then return end
	if not table.find(pendingChunks, k) then
		table.insert(pendingChunks, k)
	end
end

function StreamingManager.Start(seed: number)
	currentSeed = seed

	-- Lazy require to avoid circular dependency
	if not WorldGenerator then
		WorldGenerator = require(script.Parent.WorldGenerator)
	end

	local PROCESS_PER_FRAME = 2
	local UNLOAD_DISTANCE   = (WorldConfig.Settings.RenderDistance or 3) + 2

	RunService.Heartbeat:Connect(function()
		-- Process pending queue
		for i = 1, math.min(PROCESS_PER_FRAME, #pendingChunks) do
			local k = table.remove(pendingChunks, 1)
			if not k then break end
			if not loadedChunks[k] then
				loadedChunks[k] = true
				local cx, cz = k:match("(-?%d+),(-?%d+)")
				if cx and cz then
					task.spawn(WorldGenerator.GenerateChunk, tonumber(cx), tonumber(cz))
				end
			end
		end

		-- Unload far chunks
		local toUnload = {}
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if not char then continue end
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not root then continue end
			local pcx = math.floor(root.Position.X / WorldConfig.Settings.ChunkSize)
			local pcz = math.floor(root.Position.Z / WorldConfig.Settings.ChunkSize)

			for k in loadedChunks do
				local cx, cz = k:match("(-?%d+),(-?%d+)")
				if cx and cz then
					local dx = math.abs(tonumber(cx)! - pcx)
					local dz = math.abs(tonumber(cz)! - pcz)
					if dx > UNLOAD_DISTANCE or dz > UNLOAD_DISTANCE then
						table.insert(toUnload, k)
					end
				end
			end
		end

		for _, k in ipairs(toUnload) do
			loadedChunks[k] = nil
		end
	end)
end

return StreamingManager
