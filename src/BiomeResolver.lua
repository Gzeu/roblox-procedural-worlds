--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/BiomeResolver  [v2]
-- Maps (temperature, moisture) → biome using inverse-square-distance.
-- 9 biome poles — add more by inserting into BIOME_POLES.
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
	Structures: { string },
}

export type BiomeResult = {
	Biome: BiomeDef,
	BlendFactors: { [string]: number },
}

local BiomeResolver = {}

-- temperature: 0=cold → 1=hot   |   moisture: 0=dry → 1=wet
local BIOME_POLES: { [string]: { t: number, m: number } } = {
	Forest    = { t = 0.45, m = 0.75 },
	Desert    = { t = 0.90, m = 0.08 },
	Snow      = { t = 0.08, m = 0.45 },
	Grassland = { t = 0.60, m = 0.40 },
	Jungle    = { t = 0.85, m = 0.90 },
	Tundra    = { t = 0.10, m = 0.20 },
	Volcano   = { t = 0.95, m = 0.05 },
	Swamp     = { t = 0.35, m = 0.92 },
	Ocean     = { t = 0.50, m = 1.00 },
}

function BiomeResolver.Resolve(temperature: number, moisture: number): BiomeResult
	local weights: { [string]: number } = {}
	local totalWeight = 0.0

	for name, pole in BIOME_POLES do
		local dt = temperature - pole.t
		local dm = moisture    - pole.m
		local w  = 1.0 / (dt * dt + dm * dm + 0.0001)
		weights[name] = w
		totalWeight   += w
	end

	local blendFactors: { [string]: number } = {}
	local dominantBiome   = "Grassland"
	local dominantWeight  = 0.0

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

-- Probabilistic material blending at biome edges (>18% secondary influence)
function BiomeResolver.GetSurfaceMaterial(result: BiomeResult): Enum.Material
	local dominant = result.Biome
	for name, factor in result.BlendFactors do
		if name ~= dominant.Name and factor > 0.18 then
			if math.random() < factor then
				local secondary = WorldConfig.Biomes[name]
				if secondary then return secondary.SurfaceMaterial end
			end
		end
	end
	return dominant.SurfaceMaterial
end

return BiomeResolver
