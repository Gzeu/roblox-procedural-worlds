--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/ChunkHandler
-- Generates a single 30x30 chunk:
--   - Layered Perlin height map (base + mountain octaves)
--   - Biome-aware surface & fill materials
--   - Water fill below WaterLevel
--   - 3D cave noise punches underground air pockets
--   - Triggers asset placement on exposed surfaces
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local WorldConfig   = require(ReplicatedStorage:WaitForChild("WorldConfig"))
local BiomeResolver = require(ReplicatedStorage:WaitForChild("BiomeResolver"))
local AssetPlacer   = require(ReplicatedStorage:WaitForChild("AssetPlacer"))

local Terrain = Workspace.Terrain

-- noise2D: remaps math.noise [-1,1] → [0,1]
local function noise2D(seed: number, x: number, z: number, scale: number): number
	return (math.noise(seed + x / scale, z / scale) + 1) * 0.5
end

-- noise3D: three-axis variant for cave generation
local function noise3D(seed: number, x: number, y: number, z: number, scale: number): number
	return (math.noise(seed + x / scale, y / scale, z / scale) + 1) * 0.5
end

-- getSurfaceHeight: FBM layered height sampler
local function getSurfaceHeight(seed: number, worldX: number, worldZ: number): number
	local cfg = WorldConfig.Settings
	local base   = noise2D(seed,        worldX, worldZ, cfg.TerrainScale)
	local detail = noise2D(seed + 1000, worldX, worldZ, cfg.TerrainScale / 2) * 0.4
	local mtn    = noise2D(seed + 2000, worldX, worldZ, cfg.MountainScale)
	mtn = mtn * mtn  -- squared = sharp peaks
	return cfg.BaseY
		+ (base + detail) * cfg.TerrainAmplitude
		+ mtn             * cfg.MountainAmplitude
end

-- isCave: true when voxel should be hollow Air
local function isCave(seed: number, x: number, y: number, z: number): boolean
	local cfg = WorldConfig.Settings
	if y > cfg.CaveMaxY or y < cfg.CaveMinY then return false end
	return noise3D(seed + 9000, x, y, z, cfg.CaveScale) < cfg.CaveThreshold
end

-- ================================================================
-- PUBLIC: GenerateChunk
-- chunkOriginX / chunkOriginZ = world-space bottom-left corner
-- seed = shared world seed
-- ================================================================
local ChunkHandler = {}

function ChunkHandler.GenerateChunk(chunkOriginX: number, chunkOriginZ: number, seed: number)
	local cfg   = WorldConfig.Settings
	local vSize = cfg.VoxelSize
	local halfV = vSize * 0.5
	local deepY = cfg.CaveMinY - vSize * 4

	for lx = 0, cfg.ChunkSize - 1, vSize do
		for lz = 0, cfg.ChunkSize - 1, vSize do
			local worldX = chunkOriginX + lx
			local worldZ = chunkOriginZ + lz

			-- Sample biome noise
			local temp        = noise2D(seed + 3000, worldX, worldZ, cfg.TempScale)
			local moisture    = noise2D(seed + 4000, worldX, worldZ, cfg.MoistureScale)
			local biomeResult = BiomeResolver.Resolve(temp, moisture)
			local biome       = biomeResult.Biome

			-- Snap surface Y to voxel grid
			local surfaceY = math.round(getSurfaceHeight(seed, worldX, worldZ) / vSize) * vSize

			-- Fill voxel column from bedrock to surface
			for y = deepY, surfaceY, vSize do
				local isSurface     = (y == surfaceY)
				local isUnderground = (y < surfaceY)

				-- Cave carving: skip FillBlock → leaves Air
				if isUnderground and isCave(seed, worldX, y, worldZ) then
					continue
				end

				local material: Enum.Material
				if isSurface then
					material = BiomeResolver.GetSurfaceMaterial(biomeResult)
				elseif y >= surfaceY - vSize * 2 then
					material = biome.FillMaterial
				else
					material = Enum.Material.Rock
				end

				-- Override: water underground below WaterLevel
				if y <= cfg.WaterLevel and isUnderground then
					material = Enum.Material.Water
				end

				local center = Vector3.new(worldX + halfV, y + halfV, worldZ + halfV)
				local ok, err = pcall(Terrain.FillBlock, Terrain,
					CFrame.new(center),
					Vector3.new(vSize, vSize, vSize),
					material
				)
				if not ok then
					warn("[ChunkHandler] FillBlock error:", err)
				end
			end

			-- Water cap when surface is below WaterLevel
			if surfaceY < cfg.WaterLevel then
				for wy = surfaceY + vSize, cfg.WaterLevel, vSize do
					local center = Vector3.new(worldX + halfV, wy + halfV, worldZ + halfV)
					local ok, _ = pcall(Terrain.FillBlock, Terrain,
						CFrame.new(center),
						Vector3.new(vSize, vSize, vSize),
						Enum.Material.Water
					)
					if not ok then break end
				end
			end

			-- Asset placement on dry land only
			if surfaceY >= cfg.WaterLevel then
				local assetPos = Vector3.new(worldX + halfV, surfaceY + vSize, worldZ + halfV)
				AssetPlacer.PlaceAsset(biome, assetPos, {
					Tree = math.random(),
					Rock = math.random(),
					Bush = math.random(),
				})
			end

		end
	end
end

return ChunkHandler
