--!strict
-- ============================================================
-- MODULE: OreGenerator  [v1.1 - fixed]
-- Injects ore veins into underground columns using 3D noise.
-- Called per-voxel from ChunkHandler during column fill.
-- ============================================================

local WorldConfig = require(script.Parent.WorldConfig)

local OreGenerator = {}

local ORE_DEFS = {
	{ material = Enum.Material.SmoothPlastic, threshold = 0.72, maxY = -10, name = "Coal"   },  -- SmoothPlastic as coal stand-in
	{ material = Enum.Material.Metal,         threshold = 0.78, maxY = -20, name = "Iron"   },
	{ material = Enum.Material.Neon,          threshold = 0.85, maxY = -40, name = "Diamond"},
	{ material = Enum.Material.ForceField,    threshold = 0.88, maxY = -60, name = "Mythril"},
}

local function ore3D(seed: number, x: number, y: number, z: number, scale: number): number
	return (math.noise(seed + x / scale, y / scale, z / scale) + 1) * 0.5
end

-- Returns the ore material if this voxel should contain ore, else nil
function OreGenerator.CheckAndPlaceOre(x: number, y: number, z: number, seed: number): Enum.Material?
	for _, ore in ipairs(ORE_DEFS) do
		if y > ore.maxY then continue end
		local v = ore3D(seed + 5000 + _ * 777, x, y, z, 8)
		if v > ore.threshold then
			return ore.material
		end
	end
	return nil
end

-- Bulk placement pass (called after chunk column fill)
function OreGenerator.PlaceOres(originX: number, originZ: number, seed: number)
	-- Bulk pass is a no-op here since CheckAndPlaceOre handles per-voxel
	-- This function exists for WorldGenerator.GenerateChunk to call after fill
end

return OreGenerator
