--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/BiomeResolver
-- Maps (temperature, moisture) noise values → biome + blend weights.
-- Uses inverse-square-distance weighting for smooth transitions.
-- To add a biome: add a pole in BIOME_POLES + entry in WorldConfig.Biomes
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldConfig = require(ReplicatedStorage:WaitForChild("WorldConfig"))

export type BiomeDef = {
	Name: string,
	SurfaceMaterial: Enum.Material,
	FillMaterial: Enum.Material,
	DebugColor: Color3,
	Trees: boolean,
	Rocks: boolean,
	Bushes: boolean,
}

export type BiomeResult = {
	Biome: BiomeDef,
	BlendFactors: { [string]: number },
}

local BiomeResolver = {}

-- ----------------------------------------------------------------
-- Each biome has a "pole" in (temperature, moisture) space.
-- temperature: 0 = cold → 1 = hot
-- moisture:    0 = dry  → 1 = wet
-- ----------------------------------------------------------------
local BIOME_POLES = {
	Forest    = { t = 0.4, m = 0.8 },
	Desert    = { t = 0.9, m = 0.1 },
	Snow      = { t = 0.1, m = 0.5 },
	Grassland = { t = 0.6, m = 0.4 },
}

-- ----------------------------------------------------------------
-- Resolve returns:
--   .Biome        → dominant BiomeDef
--   .BlendFactors → normalised weight per biome (sums to 1.0)
-- ----------------------------------------------------------------
function BiomeResolver.Resolve(temperature: number, moisture: number): BiomeResult
	local weights: { [string]: number } = {}
	local totalWeight = 0.0

	for name, pole in BIOME_POLES do
		local dt = temperature - pole.t
		local dm = moisture    - pole.m
		local w = 1.0 / (dt * dt + dm * dm + 0.0001)
		weights[name] = w
		totalWeight += w
	end

	local blendFactors: { [string]: number } = {}
	local dominantBiome = "Grassland"
	local dominantWeight = 0.0

	for name, w in weights do
		local norm = w / totalWeight
		blendFactors[name] = norm
		if norm > dominantWeight then
			dominantWeight = norm
			dominantBiome  = name
		end
	end

	return {
		Biome        = WorldConfig.Biomes[dominantBiome] :: BiomeDef,
		BlendFactors = blendFactors,
	}
end

-- ----------------------------------------------------------------
-- GetSurfaceMaterial: probabilistically blends materials at edges.
-- When a secondary biome has >20% influence, randomly borrow
-- its surface material to soften the hard border.
-- ----------------------------------------------------------------
function BiomeResolver.GetSurfaceMaterial(result: BiomeResult): Enum.Material
	local dominant = result.Biome
	for name, factor in result.BlendFactors do
		if name ~= dominant.Name and factor > 0.20 then
			if math.random() < factor then
				local secondary = WorldConfig.Biomes[name]
				if secondary then
					return secondary.SurfaceMaterial
				end
			end
		end
	end
	return dominant.SurfaceMaterial
end

return BiomeResolver
