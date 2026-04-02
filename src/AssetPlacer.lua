--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/AssetPlacer  [v2]
-- Clones prop Models (trees, rocks, bushes) from
-- ReplicatedStorage/Assets/ and places them with random Y rotation.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local WorldConfig       = require(ReplicatedStorage:WaitForChild("WorldConfig"))

local function getTemplate(folder: string, name: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then return nil end
	local f = assets:FindFirstChild(folder)
	if not f then return nil end
	return f:FindFirstChild(name) :: Model?
end

local function placeModel(model: Model, position: Vector3)
	if not model.PrimaryPart then
		local part = model:FindFirstChildWhichIsA("BasePart")
		if part then model.PrimaryPart = part
		else model:Destroy(); warn("[AssetPlacer] No BasePart"); return end
	end
	local rot = CFrame.Angles(0, math.rad(math.random(0, 359)), 0)
	model:SetPrimaryPartCFrame(CFrame.new(position) * rot)
	model.Parent = Workspace:FindFirstChild("ProceduralAssets") or Workspace
end

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
			local t = getTemplate("Trees", names[math.random(1, #names)])
			if t then placeModel(t:Clone(), position) end
		end)
		if not ok then warn("[AssetPlacer] Tree:", err) end
	end

	if biome.Rocks and spawnRolls.Rock < cfg.RockSpawnChance then
		local names = { "Rock_Small", "Rock_Medium", "Rock_Large" }
		local ok, err = pcall(function()
			local t = getTemplate("Rocks", names[math.random(1, #names)])
			if t then placeModel(t:Clone(), position) end
		end)
		if not ok then warn("[AssetPlacer] Rock:", err) end
	end

	if biome.Bushes and spawnRolls.Bush < cfg.BushSpawnChance then
		local names = { "Bush_Round", "Bush_Shrub" }
		local ok, err = pcall(function()
			local t = getTemplate("Bushes", names[math.random(1, #names)])
			if t then placeModel(t:Clone(), position) end
		end)
		if not ok then warn("[AssetPlacer] Bush:", err) end
	end
end

function AssetPlacer.Init()
	if not Workspace:FindFirstChild("ProceduralAssets") then
		local f = Instance.new("Folder")
		f.Name = "ProceduralAssets"
		f.Parent = Workspace
	end
end

return AssetPlacer
