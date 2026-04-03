--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/RiverCarver  [v2.1 NEW]
-- Carves river channels along terrain valleys using gradient
-- descent from noise saddle points. Rivers flow from high
-- terrain toward WaterLevel, creating realistic valley paths.
--
-- How it works:
--   1. Sample a grid of "candidate spring" points at mountain saddles
--   2. From each spring, walk downhill step-by-step (gradient descent)
--   3. For each step, carve a channel of radius RiverRadius into
--      the terrain using Terrain:FillBlock with Water material
--   4. Stop when reaching WaterLevel or world boundary
--
-- Usage:
--   RiverCarver.CarveRivers(seed)
--   Call from WorldGenerator AFTER initial chunk generation is done.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local WorldConfig = require(ReplicatedStorage:WaitForChild("WorldConfig"))

local Terrain = Workspace.Terrain

local RiverCarver = {}

-- ----------------------------------------------------------------
-- Internal: compute FBM terrain height at a point (must match ChunkHandler)
-- ----------------------------------------------------------------
local function noise2D(seed: number, x: number, z: number, scale: number): number
	return (math.noise(seed + x / scale, z / scale) + 1) * 0.5
end

local function getSurfaceHeight(seed: number, wx: number, wz: number): number
	local cfg    = WorldConfig.Settings
	local base   = noise2D(seed,        wx, wz, cfg.TerrainScale)
	local detail = noise2D(seed + 1000, wx, wz, cfg.TerrainScale / 2) * 0.4
	local fine   = noise2D(seed + 1500, wx, wz, cfg.TerrainScale / 4) * 0.15
	local mtn    = noise2D(seed + 2000, wx, wz, cfg.MountainScale)
	mtn = mtn * mtn
	return cfg.BaseY
		+ (base + detail + fine) * cfg.TerrainAmplitude
		+ mtn * cfg.MountainAmplitude
end

-- ----------------------------------------------------------------
-- Internal: gradient descent step — returns the lowest neighbour
-- ----------------------------------------------------------------
local DIRS = {
	{1, 0}, {-1, 0}, {0, 1}, {0, -1},
	{1, 1}, {-1, 1}, {1, -1}, {-1, -1},
}

local function lowestNeighbour(seed: number, x: number, z: number, step: number)
	local bestH = getSurfaceHeight(seed, x, z)
	local bestX, bestZ = x, z
	for _, d in DIRS do
		local nx = x + d[1] * step
		local nz = z + d[2] * step
		local nh = getSurfaceHeight(seed, nx, nz)
		if nh < bestH then
			bestH  = nh
			bestX  = nx
			bestZ  = nz
		end
	end
	return bestX, bestZ, bestH
end

-- ----------------------------------------------------------------
-- Internal: fill a cylindrical section of river at a position
-- ----------------------------------------------------------------
local function carveSection(x: number, surfY: number, z: number, radius: number, vSize: number)
	local halfV = vSize * 0.5
	local depth = math.max(vSize * 2, radius)
	for rx = -radius, radius, vSize do
		for rz = -radius, radius, vSize do
			if rx * rx + rz * rz <= radius * radius then
				for ry = 0, depth, vSize do
					local cy = surfY - ry + halfV
					local center = Vector3.new(x + rx + halfV, cy, z + rz + halfV)
					local ok, _ = pcall(
						Terrain.FillBlock, Terrain,
						CFrame.new(center),
						Vector3.new(vSize, vSize, vSize),
						Enum.Material.Water
					)
					if not ok then break end
				end
			end
		end
	end
end

-- ----------------------------------------------------------------
-- PUBLIC: CarveRivers
-- Finds spring candidates and traces them downhill.
-- ----------------------------------------------------------------
function RiverCarver.CarveRivers(seed: number)
	local cfg = WorldConfig.Settings
	local riverCfg = WorldConfig.RiverSettings

	local gridStep   = riverCfg.SpringGridStep
	local minHeight  = riverCfg.SpringMinHeight
	local maxSteps   = riverCfg.MaxSteps
	local stepSize   = riverCfg.StepSize
	local radius     = riverCfg.RiverRadius
	local vSize      = cfg.VoxelSize
	local halfX      = cfg.WorldSizeX / 2
	local halfZ      = cfg.WorldSizeZ / 2
	local waterLevel = cfg.WaterLevel
	local maxRivers  = riverCfg.MaxRivers

	local riverCount = 0

	for sx = -halfX, halfX - gridStep, gridStep do
		if riverCount >= maxRivers then break end
		for sz = -halfZ, halfZ - gridStep, gridStep do
			if riverCount >= maxRivers then break end

			local jx = sx + math.noise(seed + sx * 0.01, sz * 0.01) * gridStep * 0.4
			local jz = sz + math.noise(seed + sz * 0.01, sx * 0.01) * gridStep * 0.4

			local h = getSurfaceHeight(seed, jx, jz)
			if h < minHeight then continue end

			local isLocalPeak = true
			for _, d in DIRS do
				local nh = getSurfaceHeight(seed, jx + d[1] * gridStep, jz + d[2] * gridStep)
				if nh > h then
					isLocalPeak = false
					break
				end
			end
			if isLocalPeak then continue end

			local cx, cz = jx, jz
			local visited: { [string]: boolean } = {}

			riverCount += 1
			task.spawn(function()
				for _ = 1, maxSteps do
					local key = math.round(cx / stepSize) .. "," .. math.round(cz / stepSize)
					if visited[key] then break end
					visited[key] = true

					local curH = getSurfaceHeight(seed, cx, cz)
					if curH <= waterLevel then break end
					if math.abs(cx) > halfX or math.abs(cz) > halfZ then break end

					carveSection(cx, curH, cz, radius, vSize)

					local nx, nz, nh = lowestNeighbour(seed, cx, cz, stepSize)
					if nh >= curH then break end
					cx, cz = nx, nz
				end
			end)
		end
	end

	print(string.format("[RiverCarver] Started %d river traces.", riverCount))
end

return RiverCarver
