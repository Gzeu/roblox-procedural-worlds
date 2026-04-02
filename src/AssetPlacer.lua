--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/AssetPlacer
-- Clones prop Models from ReplicatedStorage/Assets/ and places
-- them at world positions with random Y rotation.
-- All placements wrapped in pcall for resilience.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local WorldConfig = require(ReplicatedStorage:WaitForChild("WorldConfig"))

-- Safely retrieve a template Model from Assets sub-folder
local function getTemplate(folder: string, name: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then return nil end
	local f = assets:FindFirstChild(folder)
	if not f then return nil end
	return f:FindFirstChild(name) :: Model?
end

-- Anchor a cloned Model at position with random Y rotation
local function placeModel(model: Model, position: Vector3)
	if not model.PrimaryPart then
		local part = model:FindFirstChildWhichIsA("BasePart")
		if part then
			model.PrimaryPart = part
		else
			model:Destroy()
			warn("[AssetPlacer] Model has no BasePart — skipped")
			return
		end
	end
	local rotation = CFrame.Angles(0, math.rad(math.random(0, 359)), 0)
	model:SetPrimaryPartCFrame(CFrame.new(position) * rotation)
	model.Parent = Workspace:FindFirstChild("ProceduralAssets") or Workspace
end

-- ================================================================
-- PUBLIC API
-- ================================================================
local AssetPlacer = {}

function AssetPlacer.PlaceAsset(
	biome: { Name: string, Trees: boolean, Rocks: boolean, Bushes: boolean },
	position: Vector3,
	spawnRolls: { Tree: number, Rock: number, Bush: number }
)
	local cfg = WorldConfig.Settings

	if biome.Trees and spawnRolls.Tree < cfg.TreeSpawnChance then
		local names = { "Tree_Pine", "Tree_Oak", "Tree_Birch" }
		local ok, err = pcall(function()
			local tmpl = getTemplate("Trees", names[math.random(1, #names)])
			if tmpl then placeModel(tmpl:Clone(), position) end
		end)
		if not ok then warn("[AssetPlacer] Tree error:", err) end
	end

	if biome.Rocks and spawnRolls.Rock < cfg.RockSpawnChance then
		local names = { "Rock_Small", "Rock_Medium", "Rock_Large" }
		local ok, err = pcall(function()
			local tmpl = getTemplate("Rocks", names[math.random(1, #names)])
			if tmpl then placeModel(tmpl:Clone(), position) end
		end)
		if not ok then warn("[AssetPlacer] Rock error:", err) end
	end

	if biome.Bushes and spawnRolls.Bush < cfg.BushSpawnChance then
		local names = { "Bush_Round", "Bush_Shrub" }
		local ok, err = pcall(function()
			local tmpl = getTemplate("Bushes", names[math.random(1, #names)])
			if tmpl then placeModel(tmpl:Clone(), position) end
		end)
		if not ok then warn("[AssetPlacer] Bush error:", err) end
	end
end

-- Creates the Workspace container folder for all placed props
function AssetPlacer.Init()
	if not Workspace:FindFirstChild("ProceduralAssets") then
		local f = Instance.new("Folder")
		f.Name   = "ProceduralAssets"
		f.Parent = Workspace
	end
end

return AssetPlacer
