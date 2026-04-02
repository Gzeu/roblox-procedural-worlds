--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/ChunkHandler  [v2]
-- Generates a single chunk:
--   - Layered FBM height map (base + mountain)
--   - Biome-aware materials + smooth blending
--   - Water fill below WaterLevel
--   - 3D cave carving
--   - Ore vein injection (OreGenerator)
--   - Biome structure placement (StructurePlacer)
--   - Surface asset placement (AssetPlacer)
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local WorldConfig      = require(ReplicatedStorage:WaitForChild("WorldConfig"))
local BiomeResolver    = require(ReplicatedStorage:WaitForChild("BiomeResolver"))
local AssetPlacer      = require(ReplicatedStorage:WaitForChild("AssetPlacer"))
local OreGenerator     = require(ReplicatedStorage:WaitForChild("OreGenerator"))
local StructurePlacer  = require(ReplicatedStorage:WaitForChild("StructurePlacer"))

local Terrain = Workspace.Terrain

-- noise2D: remap [-1,1] → [0,1]
local function noise2D(seed: number, x: number, z: number, scale: number): number
	return (math.noise(seed + x / scale, z / scale) + 1) * 0.5
end

-- noise3D: for caves and ores
local function noise3D(seed: number, x: number, y: number, z: number, scale: number): number
	return (math.noise(seed + x / scale, y / scale, z / scale) + 1) * 0.5
end

-- FBM surface height — 3 octaves
local function getSurfaceHeight(seed: number, wx: number, wz: number): number
	local cfg    = WorldConfig.Settings
	local base   = noise2D(seed,        wx, wz, cfg.TerrainScale)
	local detail = noise2D(seed + 1000, wx, wz, cfg.TerrainScale / 2) * 0.4
	local fine   = noise2D(seed + 1500, wx, wz, cfg.TerrainScale / 4) * 0.15
	local mtn    = noise2D(seed + 2000, wx, wz, cfg.MountainScale)
	mtn = mtn * mtn  -- square → sharp peaks
	return cfg.BaseY
		+ (base + detail + fine) * cfg.TerrainAmplitude
		+ mtn * cfg.MountainAmplitude
end

-- Cave carving gate
local function isCave(seed: number, x: number, y: number, z: number): boolean
	local cfg = WorldConfig.Settings
	if y > cfg.CaveMaxY or y < cfg.CaveMinY then return false end
	return noise3D(seed + 9000, x, y, z, cfg.CaveScale) < cfg.CaveThreshold
end

-- ================================================================
-- PUBLIC: GenerateChunk
-- ================================================================
local ChunkHandler = {}

function ChunkHandler.GenerateChunk(originX: number, originZ: number, seed: number)
	local cfg   = WorldConfig.Settings
	local vSize = cfg.VoxelSize
	local halfV = vSize * 0.5
	local deepY = cfg.CaveMinY - vSize * 4

	for lx = 0, cfg.ChunkSize - 1, vSize do
		for lz = 0, cfg.ChunkSize - 1, vSize do
			local wx = originX + lx
			local wz = originZ + lz

			-- Biome sampling
			local temp        = noise2D(seed + 3000, wx, wz, cfg.TempScale)
			local moisture    = noise2D(seed + 4000, wx, wz, cfg.MoistureScale)
			local biomeResult = BiomeResolver.Resolve(temp, moisture)
			local biome       = biomeResult.Biome

			-- Snap surface to voxel grid
			local surfaceY = math.round(getSurfaceHeight(seed, wx, wz) / vSize) * vSize

			-- Fill column from bedrock → surface
			for y = deepY, surfaceY, vSize do
				local isSurface = (y == surfaceY)
				local isUnder   = (y < surfaceY)

				-- Cave carving
				if isUnder and isCave(seed, wx, y, wz) then continue end

				local material: Enum.Material

				if isSurface then
					material = BiomeResolver.GetSurfaceMaterial(biomeResult)
				elseif y >= surfaceY - vSize * 2 then
					material = biome.FillMaterial
				else
					-- Check for ore before defaulting to Rock
					local oreMat = OreGenerator.CheckAndPlaceOre(wx, y, wz, seed)
					if oreMat then continue end  -- ore already filled this voxel
					material = Enum.Material.Rock
				end

				-- Water override below water level (underground only)
				if y <= cfg.WaterLevel and isUnder then
					material = Enum.Material.Water
				end

				local center = Vector3.new(wx + halfV, y + halfV, wz + halfV)
				local ok, err = pcall(Terrain.FillBlock, Terrain,
					CFrame.new(center),
					Vector3.new(vSize, vSize, vSize),
					material
				)
				if not ok then warn("[ChunkHandler] FillBlock:", err) end
			end

			-- Water cap for submerged surfaces
			if surfaceY < cfg.WaterLevel then
				for wy = surfaceY + vSize, cfg.WaterLevel, vSize do
					local center = Vector3.new(wx + halfV, wy + halfV, wz + halfV)
					local ok, _ = pcall(Terrain.FillBlock, Terrain,
						CFrame.new(center), Vector3.new(vSize, vSize, vSize), Enum.Material.Water)
					if not ok then break end
				end
			end

			-- Surface props + structures (dry land only)
			if surfaceY >= cfg.WaterLevel then
				local assetPos = Vector3.new(wx + halfV, surfaceY + vSize, wz + halfV)
				-- Asset placement
				AssetPlacer.PlaceAsset(biome, assetPos, {
					Tree = math.random(),
					Rock = math.random(),
					Bush = math.random(),
				})
				-- Structure placement (lower probability check inside StructurePlacer)
				StructurePlacer.TryPlace(biome, assetPos)
			end

		end -- lz
	end -- lx
end

return ChunkHandler
