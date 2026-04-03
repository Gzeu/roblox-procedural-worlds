-- LODManager.lua
-- Level-of-Detail manager: reduces part density for distant chunks
-- v2.3.0

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local WorldConfig = require(script.Parent.WorldConfig)

local LODManager = {}

-- LOD tiers based on chunk distance from player
local LOD_TIERS = {
	{ maxDist = 2,  detail = 1.0 },  -- Full detail
	{ maxDist = 4,  detail = 0.5 },  -- Half detail: merge small parts
	{ maxDist = 7,  detail = 0.25 }, -- Quarter: only terrain base
	{ maxDist = 999,detail = 0.0 },  -- Invisible / unloaded
}

local chunkModels  = {}   -- { ["cx,cz"] = Model }
local lastLOD      = {}   -- { ["cx,cz"] = tierIndex }
local UPDATE_RATE  = 2    -- seconds between full LOD sweeps
local lastUpdate   = 0

local function getChunkKey(cx, cz)
	return cx .. "," .. cz
end

local function getLODTier(distChunks)
	for i, tier in ipairs(LOD_TIERS) do
		if distChunks <= tier.maxDist then
			return i, tier.detail
		end
	end
	return #LOD_TIERS, 0
end

local function applyLOD(chunkModel, tierIndex, detail)
	if not chunkModel or not chunkModel.Parent then return end

	for _, part in ipairs(chunkModel:GetDescendants()) do
		if part:IsA("BasePart") then
			if detail == 0.0 then
				-- Hide very distant chunks
				part.LocalTransparencyModifier = 1
			elseif detail < 0.5 then
				-- Show terrain base only (hide decorations)
				local isDecor = part:GetAttribute("IsDecoration")
				part.LocalTransparencyModifier = isDecor and 1 or 0
			else
				-- Full or half detail — show everything
				part.LocalTransparencyModifier = 0
			end
		end
	end
end

function LODManager.RegisterChunk(cx, cz, model)
	local key = getChunkKey(cx, cz)
	chunkModels[key] = model
end

function LODManager.UnregisterChunk(cx, cz)
	local key = getChunkKey(cx, cz)
	chunkModels[key] = nil
	lastLOD[key]     = nil
end

function LODManager.UpdateAll()
	local playerPositions = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				local cx = math.floor(root.Position.X / WorldConfig.ChunkSize)
				local cz = math.floor(root.Position.Z / WorldConfig.ChunkSize)
				table.insert(playerPositions, { cx = cx, cz = cz })
			end
		end
	end

	for key, model in pairs(chunkModels) do
		local cx, cz = key:match("(-?%d+),(-?%d+)")
		cx, cz = tonumber(cx), tonumber(cz)
		if not cx then continue end

		local minDist = math.huge
		for _, ppos in ipairs(playerPositions) do
			local d = math.sqrt((cx - ppos.cx)^2 + (cz - ppos.cz)^2)
			if d < minDist then minDist = d end
		end

		local tierIndex, detail = getLODTier(minDist)
		if lastLOD[key] ~= tierIndex then
			lastLOD[key] = tierIndex
			applyLOD(model, tierIndex, detail)
		end
	end
end

function LODManager.Start()
	RunService.Heartbeat:Connect(function()
		if tick() - lastUpdate < UPDATE_RATE then return end
		lastUpdate = tick()
		LODManager.UpdateAll()
	end)
end

return LODManager
