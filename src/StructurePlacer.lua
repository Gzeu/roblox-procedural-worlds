--!strict
-- ============================================================
-- MODULE: StructurePlacer  [v1.1 - fixed]
-- Places pre-built structures (ruins, camps, temples) on land.
-- Low-probability check to keep structures rare and meaningful.
-- ============================================================

local WorldConfig = require(script.Parent.WorldConfig)

local Workspace = game:GetService("Workspace")

local StructurePlacer = {}

-- Structures available per biome
local BIOME_STRUCTURES: { [string]: { string } } = {
	Forest    = { "AbandonedCabin", "AncientRuins" },
	Desert    = { "SandTemple", "BuriedCache" },
	Snow      = { "IceFort", "FrozenSanctuary" },
	Grassland = { "Farmstead", "RoadShrine" },
	Jungle    = { "TempleRuins", "HiddenGrove" },
	Tundra    = { "StoneCircle" },
	Volcano   = { "FireShrine", "LavaCastle" },
	Swamp     = { "WitchHut", "SunkenRuins" },
}

local PLACEMENT_CHANCE = 0.003  -- 0.3% per voxel column on dry land

function StructurePlacer.TryPlace(biome, position: Vector3)
	if not biome then return end
	if math.random() > PLACEMENT_CHANCE then return end

	local structures = BIOME_STRUCTURES[biome.Name]
	if not structures or #structures == 0 then return end

	local pick = structures[math.random(#structures)]
	local template = game:GetService("ServerStorage"):FindFirstChild(pick, true)
	if not template then
		warn("[StructurePlacer] Structure model not found:", pick)
		return
	end

	local clone = template:Clone()
	clone:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.random(4) * math.pi * 0.5, 0))
	clone.Parent = Workspace
end

return StructurePlacer
