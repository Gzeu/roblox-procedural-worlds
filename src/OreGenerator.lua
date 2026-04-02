--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/OreGenerator  [v2 NEW]
-- Replaces underground Rock voxels with ore materials when a
-- 3D noise value exceeds the ore's rarity threshold.
-- Called by ChunkHandler once per voxel column.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local WorldConfig = require(ReplicatedStorage:WaitForChild("WorldConfig"))
local Terrain     = Workspace.Terrain

type OreVein = {
	Name: string,
	Material: Enum.Material,
	MinY: number,
	MaxY: number,
	Scale: number,
	Threshold: number,
	SeedOffset: number,
}

local OreGenerator = {}

-- ----------------------------------------------------------------
-- CheckAndPlaceOre
-- Evaluates all ore types at position (x, y, z) and places the
-- first one whose noise exceeds its threshold.
-- Returns true if an ore was placed (so ChunkHandler skips Rock).
-- ----------------------------------------------------------------
function OreGenerator.CheckAndPlaceOre(
	x: number,
	y: number,
	z: number,
	seed: number
): Enum.Material?
	local cfg   = WorldConfig.Settings
	local vSize = cfg.VoxelSize

	for _, ore in WorldConfig.OreVeins :: { OreVein } do
		-- Depth gate: only check within this ore's valid Y range
		if y < ore.MinY or y > ore.MaxY then continue end

		-- 3D Perlin sample decorrelated by SeedOffset
		local n = (math.noise(
			(seed + ore.SeedOffset) + x / ore.Scale,
			y / ore.Scale,
			z / ore.Scale
		) + 1) * 0.5

		if n >= ore.Threshold then
			local halfV = vSize * 0.5
			local center = Vector3.new(x + halfV, y + halfV, z + halfV)
			local ok, err = pcall(Terrain.FillBlock, Terrain,
				CFrame.new(center),
				Vector3.new(vSize, vSize, vSize),
				ore.Material
			)
			if not ok then
				warn("[OreGenerator] FillBlock error:", err)
			end
			-- Return the placed material so ChunkHandler knows not to overwrite
			return ore.Material
		end
	end

	return nil
end

return OreGenerator
