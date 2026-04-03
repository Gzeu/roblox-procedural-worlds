-- DungeonGenerator.lua
-- Procedural dungeon room generation with loot-filled chests
-- v2.2.0

local WorldConfig  = require(script.Parent.WorldConfig)
local LootTable    = require(script.Parent.LootTable)

local DungeonGenerator = {}

local ROOM_SIZE    = 20
local CORRIDOR_W   = 4
local WALL_HEIGHT  = 8
local CHEST_CHANCE = 0.4  -- 40% per room

local function selectTier(rng)
	local weights = WorldConfig.DungeonChestWeights
	local tiers   = WorldConfig.DungeonChestTiers
	local total   = 0
	for _, w in ipairs(weights) do total = total + w end
	local roll = rng:NextNumber() * total
	local cum  = 0
	for i, w in ipairs(weights) do
		cum = cum + w
		if roll <= cum then return tiers[i] end
	end
	return tiers[1]
end

local function buildRoom(origin, rng, dungeonSeed, roomIndex)
	local roomModel = Instance.new("Model")
	roomModel.Name  = "DungeonRoom_" .. roomIndex

	-- Floor
	local floor = Instance.new("Part")
	floor.Size      = Vector3.new(ROOM_SIZE, 1, ROOM_SIZE)
	floor.CFrame    = CFrame.new(origin + Vector3.new(0, -0.5, 0))
	floor.BrickColor = BrickColor.new("Dark stone grey")
	floor.Anchored  = true
	floor.Name      = "Floor"
	floor.Parent    = roomModel

	-- Walls (N, S, E, W)
	local wallDefs = {
		{ pos = Vector3.new(0,        WALL_HEIGHT/2,  ROOM_SIZE/2),  size = Vector3.new(ROOM_SIZE, WALL_HEIGHT, 1) },
		{ pos = Vector3.new(0,        WALL_HEIGHT/2, -ROOM_SIZE/2),  size = Vector3.new(ROOM_SIZE, WALL_HEIGHT, 1) },
		{ pos = Vector3.new( ROOM_SIZE/2, WALL_HEIGHT/2, 0),         size = Vector3.new(1, WALL_HEIGHT, ROOM_SIZE) },
		{ pos = Vector3.new(-ROOM_SIZE/2, WALL_HEIGHT/2, 0),         size = Vector3.new(1, WALL_HEIGHT, ROOM_SIZE) },
	}
	for i, wd in ipairs(wallDefs) do
		local wall = Instance.new("Part")
		wall.Size      = wd.size
		wall.CFrame    = CFrame.new(origin + wd.pos)
		wall.BrickColor = BrickColor.new("Medium stone grey")
		wall.Anchored  = true
		wall.Name      = "Wall_" .. i
		wall.Parent    = roomModel
	end

	-- Ceiling
	local ceil = Instance.new("Part")
	ceil.Size      = Vector3.new(ROOM_SIZE, 1, ROOM_SIZE)
	ceil.CFrame    = CFrame.new(origin + Vector3.new(0, WALL_HEIGHT + 0.5, 0))
	ceil.BrickColor = BrickColor.new("Dark stone grey")
	ceil.Anchored  = true
	ceil.Name      = "Ceiling"
	ceil.Parent    = roomModel

	-- Torch light (simple part as placeholder)
	local torchPart = Instance.new("Part")
	torchPart.Size      = Vector3.new(0.4, 0.4, 0.4)
	torchPart.CFrame    = CFrame.new(origin + Vector3.new(0, WALL_HEIGHT - 1, 0))
	torchPart.BrickColor = BrickColor.new("Bright orange")
	torchPart.Anchored  = true
	torchPart.Name      = "TorchLight"
	torchPart.Material  = Enum.Material.Neon
	torchPart.Parent    = roomModel

	-- Chest (random chance)
	if rng:NextNumber() < CHEST_CHANCE then
		local tier      = selectTier(rng)
		local chestSeed = dungeonSeed + roomIndex * 997

		local chest = Instance.new("Part")
		chest.Size      = Vector3.new(2, 1.5, 1)
		chest.CFrame    = CFrame.new(origin + Vector3.new(
			(rng:NextNumber() - 0.5) * (ROOM_SIZE - 4),
			0.75,
			(rng:NextNumber() - 0.5) * (ROOM_SIZE - 4)
		))
		chest.BrickColor = BrickColor.new("Bright orange")
		chest.Anchored  = true
		chest.Name      = "Chest_" .. tier
		chest.Parent    = roomModel

		LootTable.FillChest(chest, tier, chestSeed)
	end

	return roomModel
end

local function buildCorridor(from, to)
	local mid    = (from + to) / 2
	local length = (to - from).Magnitude
	local dir    = (to - from).Unit

	local corr = Instance.new("Part")
	corr.Size    = Vector3.new(CORRIDOR_W, 1, length)
	corr.CFrame  = CFrame.new(mid, mid + dir) * CFrame.new(0, -0.5, 0)
	corr.BrickColor = BrickColor.new("Dark stone grey")
	corr.Anchored = true
	corr.Name    = "Corridor"
	return corr
end

function DungeonGenerator.Generate(originPos, seed)
	local rng       = Random.new(seed)
	local cfg       = WorldConfig.DungeonRoomCount
	local roomCount = rng:NextInteger(cfg.min, cfg.max)

	local dungeonModel = Instance.new("Model")
	dungeonModel.Name  = "Dungeon_" .. seed

	local positions = {}
	local spread    = ROOM_SIZE * 2.5

	for i = 1, roomCount do
		local angle  = (i / roomCount) * math.pi * 2 + rng:NextNumber() * 0.8
		local radius = spread + rng:NextNumber() * spread * 0.5
		local pos    = originPos + Vector3.new(
			math.cos(angle) * radius,
			0,
			math.sin(angle) * radius
		)
		positions[i] = pos

		local room = buildRoom(pos, rng, seed, i)
		room.Parent = dungeonModel

		-- Connect to previous room with a corridor
		if i > 1 then
			local corr = buildCorridor(positions[i-1], pos)
			corr.Parent = dungeonModel
		end
	end

	dungeonModel.Parent = workspace
	return dungeonModel
end

function DungeonGenerator.TrySpawnAt(x, z, seed)
	local hash  = (x * 374761393 + z * 1103515245 + seed) % 1000000
	local roll  = (hash / 1000000)
	if roll < WorldConfig.DungeonFrequency then
		local origin = Vector3.new(x, -30, z)
		DungeonGenerator.Generate(origin, hash)
		return true
	end
	return false
end

return DungeonGenerator
