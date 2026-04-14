-- WaterFlow.lua
-- Lakes from heightmap basins, waterfalls on steep slopes, fishing hooks
-- Integrates with SeasonSystem (FreezeWater event) and RiverCarver
-- v2.8 | roblox-procedural-worlds

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(script.Parent.WorldConfig)
local EventBus = require(script.Parent.EventBus)

local WaterFlow = {}

local CONFIG = WorldConfig.WaterFlow or {
	Enabled            = true,
	LakeThreshold      = -8,      -- heightmap value below which a lake forms
	LakeColor          = Color3.fromRGB(40, 100, 180),
	FrozenColor        = Color3.fromRGB(180, 220, 255),
	WaterfallThreshold = 20,      -- height difference in studs for waterfall
	WaterfallWidth     = 6,
	MaxLakesPerChunk   = 3,
	LakeDepth          = 4,
}

local registeredLakes = {}   -- { part, originalColor, frozen }
local registeredFalls = {}   -- { emitter }
local frozen = false

-- ─── Lake generation ──────────────────────────────────────────
local function createLakePart(centerX, centerY, centerZ, sizeX, sizeZ)
	local lake = Instance.new("Part")
	lake.Name = "Lake"
	lake.Anchored = true
	lake.CanCollide = false
	lake.Transparency = 0.4
	lake.Material = Enum.Material.Water
	lake.Color = CONFIG.LakeColor
	lake.Size = Vector3.new(sizeX, CONFIG.LakeDepth, sizeZ)
	lake.CFrame = CFrame.new(centerX, centerY, centerZ)
	lake.Parent = workspace

	local entry = { part = lake, originalColor = CONFIG.LakeColor, frozen = false }
	table.insert(registeredLakes, entry)
	EventBus:Fire("LakeCreated", {
		position = lake.Position,
		size     = lake.Size,
	})
	return lake
end

-- Scan a heightmap grid (2D array of y-values) and place lakes in basins
function WaterFlow.GenerateLakes(heightmap, originX, originZ, cellSize, seed)
	if not CONFIG.Enabled then return end
	local rows = #heightmap
	local cols = #heightmap[1]
	local lakeCount = 0

	for r = 2, rows - 1 do
		for c = 2, cols - 1 do
			if lakeCount >= CONFIG.MaxLakesPerChunk then break end
			local h = heightmap[r][c]
			-- Basin detection: lower than all 4 neighbours
			if h <= CONFIG.LakeThreshold
				and h < heightmap[r-1][c]
				and h < heightmap[r+1][c]
				and h < heightmap[r][c-1]
				and h < heightmap[r][c+1]
			then
				local wx = originX + (c - 1) * cellSize
				local wz = originZ + (r - 1) * cellSize
				local sz = math.random(20, 60)
				create LakePart(wx, h + 2, wz, sz, sz)
				lakeCount = lakeCount + 1
			end
		end
	end
end

-- ─── Waterfall generation ──────────────────────────────────────
local function createWaterfall(topPos, bottomPos)
	local height = topPos.Y - bottomPos.Y
	if height < CONFIG.WaterfallThreshold then return end

	local midY = (topPos.Y + bottomPos.Y) / 2
	local fall = Instance.new("Part")
	fall.Name = "Waterfall"
	fall.Anchored = true
	fall.CanCollide = false
	fall.Transparency = 0.5
	fall.Material = Enum.Material.Water
	fall.Color = CONFIG.LakeColor
	fall.Size = Vector3.new(CONFIG.WaterfallWidth, height, 2)
	fall.CFrame = CFrame.new(topPos.X, midY, topPos.Z)
	fall.Parent = workspace

	-- Particle emitter for mist effect
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Rate = 20
	emitter.Speed = NumberRange.new(2, 5)
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Color = ColorSequence.new(Color3.fromRGB(200, 220, 255))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 3),
	})
	emitter.Parent = fall
	table.insert(registeredFalls, { part = fall, emitter = emitter })
	EventBus:Fire("WaterfallCreated", { position = topPos, height = height })
end

function WaterFlow.GenerateWaterfalls(heightmap, originX, originZ, cellSize)
	if not CONFIG.Enabled then return end
	local rows = #heightmap
	local cols = #heightmap[1]
	for r = 1, rows - 1 do
		for c = 1, cols - 1 do
			local h1 = heightmap[r][c]
			local h2 = heightmap[r+1][c]
			local diff = math.abs(h1 - h2)
			if diff >= CONFIG.WaterfallThreshold then
				local topH = math.max(h1, h2)
				local botH = math.min(h1, h2)
				local wx = originX + (c - 1) * cellSize
				local wz = originZ + (r - 1) * cellSize
				createWaterfall(
					Vector3.new(wx, topH, wz),
					Vector3.new(wx, botH, wz)
				)
			end
		end
	end
end

-- ─── Freeze / Unfreeze (SeasonSystem integration) ─────────────────
local function setFrozen(isFrozen)
	if frozen == isFrozen then return end
	frozen = isFrozen
	local tweenInfo = TweenInfo.new(8, Enum.EasingStyle.Sine)
	for _, entry in ipairs(registeredLakes) do
		if entry.part and entry.part.Parent then
			local targetColor = isFrozen and CONFIG.FrozenColor or entry.originalColor
			local targetMaterial = isFrozen and Enum.Material.Ice or Enum.Material.Water
			local tween = TweenService:Create(entry.part, tweenInfo, {
				Color       = targetColor,
				Transparency = isFrozen and 0.1 or 0.4,
			})
			entry.part.Material = targetMaterial
			tween:Play()
			entry.frozen = isFrozen
		end
	end
	-- Disable waterfall particles when frozen
	for _, fall in ipairs(registeredFalls) do
		if fall.emitter then
			fall.emitter.Enabled = not isFrozen
		end
	end
	EventBus:Fire("WaterFrozenChanged", isFrozen)
end

-- ─── Public API ───────────────────────────────────────────────
function WaterFlow.IsFrozen()
	return frozen
end

function WaterFlow.GetLakes()
	return registeredLakes
end

function WaterFlow.Init()
	if not CONFIG.Enabled then return end
	-- Listen to SeasonSystem freeze events
	EventBus:On("FreezeWater", function(shouldFreeze)
		setFrozen(shouldFreeze)
	end)
	-- Fishing system hook: fire LakesReady once loaded
	EventBus:Fire("WaterFlowReady")
	if WorldConfig.Debug then
		warn("[WaterFlow] Initialized | LakeThreshold:", CONFIG.LakeThreshold)
	end
end

return WaterFlow
