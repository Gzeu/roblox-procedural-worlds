--!strict
-- ============================================================
-- MODULE: ChunkHandler  [v2.1 — fixed]
-- Requires via script.Parent (ServerScriptService tree)
-- Generates a single chunk:
--   - Layered FBM height map (base + mountain)
--   - Biome-aware materials + smooth blending
--   - Water fill below WaterLevel
--   - 3D cave carving
--   - Ore vein injection (OreGenerator)
--   - Biome structure placement (StructurePlacer)
--   - Surface asset placement (AssetPlacer)
-- ============================================================

local Workspace = game:GetService("Workspace")

local WorldConfig     = require(script.Parent.WorldConfig)
local BiomeResolver   = require(script.Parent.BiomeResolver)
local AssetPlacer     = require(script.Parent.AssetPlacer)
local OreGenerator    = require(script.Parent.OreGenerator)
local StructurePlacer = require(script.Parent.StructurePlacer)

local Terrain = Workspace.Terrain

local function noise2D(seed: number, x: number, z: number, scale: number): number
	return (math.noise(seed + x / scale, z / scale) + 1) * 0.5
end

local function noise3D(seed: number, x: number, y: number, z: number, scale: number): number
	return (math.noise(seed + x / scale, y / scale, z / scale) + 1) * 0.5
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

local function isCave(seed: number, x: number, y: number, z: number): boolean
	local cfg = WorldConfig.Settings
	if y > cfg.CaveMaxY or y < cfg.CaveMinY then return false end
	return noise3D(seed + 9000, x, y, z, cfg.CaveScale) < cfg.CaveThreshold
end

local ChunkHandler = {}

-- GenerateChunk: called by WorldGenerator
function ChunkHandler.GenerateChunk(originX: number, originZ: number, seed: number)
	local cfg   = WorldConfig.Settings
	local vSize = cfg.VoxelSize
	local halfV = vSize * 0.5
	local deepY = cfg.CaveMinY - vSize * 4

	for lx = 0, cfg.ChunkSize - 1, vSize do
		for lz = 0, cfg.ChunkSize - 1, vSize do
			local wx = originX + lx
			local wz = originZ + lz

			local temp        = noise2D(seed + 3000, wx, wz, cfg.TempScale)
			local moisture    = noise2D(seed + 4000, wx, wz, cfg.MoistureScale)
			local biomeResult = BiomeResolver.Resolve(temp, moisture)
			local biome       = biomeResult.Biome

			local surfaceY = math.round(getSurfaceHeight(seed, wx, wz) / vSize) * vSize

			for y = deepY, surfaceY, vSize do
				local isSurface = (y == surfaceY)
				local isUnder   = (y < surfaceY)

				if isUnder and isCave(seed, wx, y, wz) then continue end

				local material: Enum.Material

				if isSurface then
					material = BiomeResolver.GetSurfaceMaterial(biomeResult)
				elseif y >= surfaceY - vSize * 2 then
					material = biome.FillMaterial
				else
					local oreMat = OreGenerator.CheckAndPlaceOre(wx, y, wz, seed)
					if oreMat then continue end
					material = Enum.Material.Rock
				end

				if y <= cfg.WaterLevel and isUnder then
					material = Enum.Material.Water
				end

				local center = Vector3.new(wx + halfV, y + halfV, wz + halfV)
				local ok, err = pcall(Terrain.FillBlock, Terrain,
					CFrame.new(center), Vector3.new(vSize, vSize, vSize), material)
				if not ok then warn("[ChunkHandler] FillBlock:", err) end
			end

			if surfaceY < cfg.WaterLevel then
				for wy = surfaceY + vSize, cfg.WaterLevel, vSize do
					local center = Vector3.new(wx + halfV, wy + halfV, wz + halfV)
					local ok, _ = pcall(Terrain.FillBlock, Terrain,
						CFrame.new(center), Vector3.new(vSize, vSize, vSize), Enum.Material.Water)
					if not ok then break end
				end
			end

			if surfaceY >= cfg.WaterLevel then
				local assetPos = Vector3.new(wx + halfV, surfaceY + vSize, wz + halfV)
				AssetPlacer.PlaceAsset(biome, assetPos, {
					Tree = math.random(),
					Rock = math.random(),
					Bush = math.random(),
				})
				StructurePlacer.TryPlace(biome, assetPos)
			end
		end
	end
end

-- Alias: WorldGenerator calls BuildChunk in some paths
ChunkHandler.BuildChunk = ChunkHandler.GenerateChunk

return ChunkHandler
