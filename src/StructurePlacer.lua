--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/StructurePlacer  [v2 NEW]
-- Spawns biome-specific structures (campfires, igloos, ruins…)
-- at world positions. All clones from ReplicatedStorage/Structures/
-- All placements wrapped in pcall.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local WorldConfig = require(ReplicatedStorage:WaitForChild("WorldConfig"))

-- Safe template retrieval
local function getTemplate(name: string): Model?
	local folder = ReplicatedStorage:FindFirstChild("Structures")
	if not folder then return nil end
	return folder:FindFirstChild(name) :: Model?
end

-- Place model at position with random Y rotation
local function placeModel(model: Model, position: Vector3)
	if not model.PrimaryPart then
		local part = model:FindFirstChildWhichIsA("BasePart")
		if part then model.PrimaryPart = part
		else model:Destroy(); return end
	end
	local rot = CFrame.Angles(0, math.rad(math.random(0, 359)), 0)
	model:SetPrimaryPartCFrame(CFrame.new(position) * rot)
	local container = Workspace:FindFirstChild("ProceduralAssets") or Workspace
	model.Parent = container
end

local StructurePlacer = {}

-- ----------------------------------------------------------------
-- TryPlace: rolls against StructureSpawnChance, then picks a
-- random structure from the biome's Structures list.
-- ----------------------------------------------------------------
function StructurePlacer.TryPlace(
	biome: { Name: string, Structures: { string } },
	position: Vector3
)
	local cfg = WorldConfig.Settings
	-- Early exit if biome has no structures or roll fails
	if #biome.Structures == 0 then return end
	if math.random() >= cfg.StructureSpawnChance then return end

	local structName = biome.Structures[math.random(1, #biome.Structures)]
	local ok, err = pcall(function()
		local tmpl = getTemplate(structName)
		if tmpl then
			placeModel(tmpl:Clone(), position)
		end
	end)
	if not ok then
		warn("[StructurePlacer] Failed to place '" .. structName .. "':", err)
	end
end

return StructurePlacer
