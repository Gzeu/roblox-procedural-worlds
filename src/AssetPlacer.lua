local WorldConfig       = require(script.Parent.WorldConfig)
local BiomeResolver     = require(script.Parent.BiomeResolver)

local Workspace = game:GetService("Workspace")

local AssetPlacer = {}

-- Tree/rock/bush density per biome defined in WorldConfig.Biomes[name]
local function shouldPlace(biome, assetType: string, roll: number): boolean
	local density = biome[assetType .. "Density"] or 0
	return roll < density
end

function AssetPlacer.PlaceAsset(biome, position: Vector3, rolls: { Tree: number, Rock: number, Bush: number })
	if not biome then return end

	if shouldPlace(biome, "Tree", rolls.Tree) then
		AssetPlacer._Spawn(biome.TreeModel, position)
	elseif shouldPlace(biome, "Rock", rolls.Rock) then
		AssetPlacer._Spawn(biome.RockModel, position)
	elseif shouldPlace(biome, "Bush", rolls.Bush) then
		AssetPlacer._Spawn(biome.BushModel, position)
	end
end

function AssetPlacer._Spawn(modelName: string?, pos: Vector3)
	if not modelName then return end
	local template = game:GetService("ServerStorage"):FindFirstChild(modelName, true)
	if not template then
		warn("[AssetPlacer] Model not found:", modelName)
		return
	end
	local clone = template:Clone()
	clone:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	clone.Parent = Workspace
end

return AssetPlacer
