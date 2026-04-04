--!strict
-- ============================================================
-- MODULE: RiverCarver  [v1.1 - fixed]
-- Carves river channels into terrain using directional noise.
-- Called per-chunk from WorldGenerator after chunk fill.
-- ============================================================

local WorldConfig = require(script.Parent.WorldConfig)

local Workspace = game:GetService("Workspace")
local Terrain   = Workspace.Terrain

local RiverCarver = {}

local RIVER_THRESHOLD = 0.52  -- noise value above which a river channel exists
local RIVER_WIDTH     = 3     -- voxels either side of centerline
local RIVER_DEPTH     = 4     -- voxels carved below surface

local function riverNoise(seed: number, wx: number, wz: number): number
	return (math.noise(seed + 8000 + wx / 600, wz / 600) + 1) * 0.5
end

local function surfaceY(seed: number, wx: number, wz: number): number
	local cfg = WorldConfig.Settings
	local base   = (math.noise(seed + wx / cfg.TerrainScale, wz / cfg.TerrainScale) + 1) * 0.5
	local mtn    = (math.noise(seed + 2000 + wx / cfg.MountainScale, wz / cfg.MountainScale) + 1) * 0.5
	mtn = mtn * mtn
	return math.round(
		(cfg.BaseY + base * cfg.TerrainAmplitude + mtn * cfg.MountainAmplitude) / cfg.VoxelSize
	) * cfg.VoxelSize
end

function RiverCarver.CarveAt(originX: number, originZ: number, seed: number)
	local cfg   = WorldConfig.Settings
	local vSize = cfg.VoxelSize

	for lx = 0, cfg.ChunkSize - 1, vSize do
		for lz = 0, cfg.ChunkSize - 1, vSize do
			local wx = originX + lx
			local wz = originZ + lz

			local rv = riverNoise(seed, wx, wz)
			if math.abs(rv - RIVER_THRESHOLD) > (RIVER_WIDTH * vSize / 1000) then continue end

			local sy = surfaceY(seed, wx, wz)
			for dy = 0, RIVER_DEPTH do
				local cy = sy - dy * vSize
				local mat = (dy == 0) and Enum.Material.Water or Enum.Material.Air
				pcall(Terrain.FillBlock, Terrain,
					CFrame.new(wx + vSize*0.5, cy + vSize*0.5, wz + vSize*0.5),
					Vector3.new(vSize, vSize, vSize), mat)
			end
		end
	end
end

return RiverCarver
