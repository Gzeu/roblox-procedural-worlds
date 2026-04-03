-- VillageGenerator.lua
-- Procedural village placement with houses, market, well, torch posts
-- v2.5.0

local WorldConfig = require(script.Parent.WorldConfig)

local VillageGenerator = {}

local HOUSE_SIZE   = { w = 10, h = 8, d = 10 }
local WELL_RADIUS  = 2
local ROAD_WIDTH   = 4
local TORCH_HEIGHT = 5

local function buildHouse(origin, rng, parent)
	local w = HOUSE_SIZE.w
	local h = HOUSE_SIZE.h
	local d = HOUSE_SIZE.d

	-- Floor
	local floor = Instance.new("Part")
	floor.Size      = Vector3.new(w, 0.5, d)
	floor.CFrame    = CFrame.new(origin)
	floor.BrickColor = BrickColor.new("Sand yellow")
	floor.Anchored  = true
	floor.Name      = "Floor"
	floor.Parent    = parent

	-- Walls
	local wallDefs = {
		{ pos = Vector3.new(0, h/2, d/2),  size = Vector3.new(w, h, 0.5) },
		{ pos = Vector3.new(0, h/2, -d/2), size = Vector3.new(w, h, 0.5) },
		{ pos = Vector3.new(w/2, h/2, 0),  size = Vector3.new(0.5, h, d) },
		{ pos = Vector3.new(-w/2, h/2, 0), size = Vector3.new(0.5, h, d) },
	}
	local wallColor = BrickColor.new(rng:NextInteger(0,1) == 0 and "Brick yellow" or "Light stone grey")
	for i, wd in ipairs(wallDefs) do
		local wall = Instance.new("Part")
		wall.Size      = wd.size
		wall.CFrame    = CFrame.new(origin + wd.pos)
		wall.BrickColor = wallColor
		wall.Anchored  = true
		wall.Name      = "Wall_" .. i
		wall.Parent    = parent
	end

	-- Roof (slanted via wedge)
	local roof = Instance.new("WedgePart")
	roof.Size      = Vector3.new(w, h * 0.4, d / 2)
	roof.CFrame    = CFrame.new(origin + Vector3.new(0, h + roof.Size.Y/2 - 0.5, d/4))
	roof.BrickColor = BrickColor.new("Reddish brown")
	roof.Anchored  = true
	roof.Name      = "Roof_A"
	roof.Parent    = parent

	local roof2 = Instance.new("WedgePart")
	roof2.Size      = Vector3.new(w, h * 0.4, d / 2)
	roof2.CFrame    = CFrame.new(origin + Vector3.new(0, h + roof2.Size.Y/2 - 0.5, -d/4))
		* CFrame.Angles(0, math.pi, 0)
	roof2.BrickColor = BrickColor.new("Reddish brown")
	roof2.Anchored  = true
	roof2.Name      = "Roof_B"
	roof2.Parent    = parent

	-- Door (opening via removed block effect using SurfaceAppearance tag)
	local door = Instance.new("Part")
	door.Size      = Vector3.new(2, 4, 0.4)
	door.CFrame    = CFrame.new(origin + Vector3.new(0, 2, d/2 + 0.3))
	door.BrickColor = BrickColor.new("Brown")
	door.Anchored  = true
	door.Name      = "Door"
	door:SetAttribute("IsDecoration", true)
	door.Parent    = parent
end

local function buildWell(origin, parent)
	local base = Instance.new("Part")
	base.Size      = Vector3.new(WELL_RADIUS*2, 1, WELL_RADIUS*2)
	base.CFrame    = CFrame.new(origin)
	base.BrickColor = BrickColor.new("Medium stone grey")
	base.Anchored  = true
	base.Name      = "WellBase"
	base.Parent    = parent

	local water = Instance.new("Part")
	water.Size      = Vector3.new(WELL_RADIUS*2 - 0.8, 0.3, WELL_RADIUS*2 - 0.8)
	water.CFrame    = CFrame.new(origin + Vector3.new(0, 0.8, 0))
	water.BrickColor = BrickColor.new("Deep blue")
	water.Material  = Enum.Material.Water
	water.Anchored  = true
	water.Name      = "WellWater"
	water.Parent    = parent
end

local function buildTorch(origin, parent)
	local pole = Instance.new("Part")
	pole.Size      = Vector3.new(0.3, TORCH_HEIGHT, 0.3)
	pole.CFrame    = CFrame.new(origin + Vector3.new(0, TORCH_HEIGHT/2, 0))
	pole.BrickColor = BrickColor.new("Dark orange")
	pole.Anchored  = true
	pole.Name      = "TorchPole"
	pole.Parent    = parent

	local light = Instance.new("Part")
	light.Size      = Vector3.new(0.5, 0.5, 0.5)
	light.CFrame    = CFrame.new(origin + Vector3.new(0, TORCH_HEIGHT + 0.4, 0))
	light.BrickColor = BrickColor.new("Bright orange")
	light.Material  = Enum.Material.Neon
	light.Anchored  = true
	light.Name      = "TorchFlame"
	light:SetAttribute("IsDecoration", true)
	light.Parent    = parent
end

local function buildRoad(from, to, parent)
	local mid    = (from + to) / 2
	local length = (to - from).Magnitude
	local road   = Instance.new("Part")
	road.Size    = Vector3.new(ROAD_WIDTH, 0.3, length)
	road.CFrame  = CFrame.new(mid, to) * CFrame.new(0, -0.15, 0)
	road.BrickColor = BrickColor.new("Sand yellow")
	road.Material   = Enum.Material.Cobblestone
	road.Anchored   = true
	road.Name       = "Road"
	road.Parent     = parent
end

function VillageGenerator.Generate(originPos, seed)
	local rng  = Random.new(seed)
	local cfg  = WorldConfig.VillageConfig
	local houseCount = rng:NextInteger(cfg.minHouses, cfg.maxHouses)

	local villageModel = Instance.new("Model")
	villageModel.Name  = "Village_" .. seed

	-- Central well
	buildWell(originPos + Vector3.new(0, 0.5, 0), villageModel)

	-- Place houses in a ring around the center
	local positions = {}
	local radius    = cfg.radius
	for i = 1, houseCount do
		local angle = (i / houseCount) * math.pi * 2 + rng:NextNumber() * 0.5
		local r     = radius + rng:NextNumber() * radius * 0.3
		local pos   = originPos + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		positions[i] = pos

		local houseModel = Instance.new("Model")
		houseModel.Name  = "House_" .. i
		houseModel.Parent = villageModel
		buildHouse(pos + Vector3.new(0, HOUSE_SIZE.h / 2, 0), rng, houseModel)

		-- Road from house to center
		buildRoad(
			originPos + Vector3.new(0, 0.15, 0),
			pos       + Vector3.new(0, 0.15, 0),
			villageModel
		)

		-- Torch near house
		buildTorch(pos + Vector3.new(HOUSE_SIZE.w / 2 + 2, 0, 0), villageModel)
	end

	villageModel.Parent = workspace
	return villageModel
end

function VillageGenerator.TrySpawnAt(x, z, seed)
	local hash = (x * 374761393 + z * 1103515245 + seed) % 1000000
	local roll = hash / 1000000
	if roll < WorldConfig.VillageConfig.frequency then
		local origin = Vector3.new(x, WorldConfig.BaseHeight, z)
		VillageGenerator.Generate(origin, hash)
		return true
	end
	return false
end

return VillageGenerator
