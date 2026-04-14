-- CaveSystem.lua
-- 3D connected cave network: Drunkard's Walk tunnels + Cellular Automata widening
-- Underground biomes: Gloom, Crystal, Magma (below y=50)
-- Integrates with DungeonGenerator and AIDirector
-- v2.8 | roblox-procedural-worlds

local WorldConfig = require(script.Parent.WorldConfig)
local EventBus = require(script.Parent.EventBus)

local CaveSystem = {}

local CONFIG = WorldConfig.Caves or {
	Enabled          = true,
	TunnelRadius     = 5,        -- studs
	TunnelLength     = 60,       -- steps per tunnel segment
	MaxTunnels       = 8,        -- per chunk
	UndergroundY     = -50,      -- base Y for cave layer
	CrystalChance    = 0.15,     -- per tunnel cell
	LavaPoolChance   = 0.08,
	MobSpawnChance   = 0.25,     -- per cave room
}

local BIOMES = {
	["Gloom"]   = { light = Color3.fromRGB(10, 10, 20),   mobs = {"Shadow", "Bat"} },
	["Crystal"] = { light = Color3.fromRGB(80, 20, 160),  mobs = {"CrystalGolem"} },
	["Magma"]   = { light = Color3.fromRGB(200, 80, 0),   mobs = {"FireDemon", "LavaSlime"} },
}

local registeredCaves = {}  -- { tunnels, rooms, biome }

-- ─── Drunkard's Walk tunnel generator ────────────────────────────
local DIRS = {
	Vector3.new(1,0,0), Vector3.new(-1,0,0),
	Vector3.new(0,0,1), Vector3.new(0,0,-1),
	Vector3.new(0,1,0), Vector3.new(0,-1,0),
}

local function drunkardWalk(startPos, steps, seed)
	local rng = Random.new(seed)
	local cells = {}
	local pos = startPos
	for _ = 1, steps do
		local key = math.floor(pos.X) .. "," .. math.floor(pos.Y) .. "," .. math.floor(pos.Z)
		cells[key] = pos
		local dir = DIRS[rng:NextInteger(1, #DIRS)]
		pos = pos + dir
	end
	return cells
end

-- ─── Cellular Automata widening ──────────────────────────────────
local function widenCells(cells, radius)
	local widened = {}
	for _, pos in pairs(cells) do
		for dx = -radius, radius do
			for dy = -1, 1 do
				for dz = -radius, radius do
					if dx*dx + dz*dz <= radius*radius then
						local np = pos + Vector3.new(dx, dy, dz)
						local key = math.floor(np.X) .. "," .. math.floor(np.Y) .. "," .. math.floor(np.Z)
						widened[key] = np
					end
				end
			end
		end
	end
	return widened
end

-- ─── Place cave geometry in workspace ──────────────────────────────
local function placeCaveGeometry(cells, biome, rng)
	local folder = Instance.new("Folder")
	folder.Name = "Cave_" .. biome
	folder.Parent = workspace

	local biomeData = BIOMES[biome]

	for _, pos in pairs(cells) do
		-- Air wedge (removes terrain visually via negative part trick or TerrainAPI)
		-- For now: place a glowing crystal or lava pool stochastically
		local r = rng:NextNumber()
		if r < CONFIG.CrystalChance and biome == "Crystal" then
			local crystal = Instance.new("Part")
			crystal.Name = "Crystal"
			crystal.Anchored = true
			crystal.Material = Enum.Material.Neon
			crystal.Color = Color3.fromRGB(120, 40, 200)
			crystal.Size = Vector3.new(1, rng:NextInteger(2,6), 1)
			crystal.CFrame = CFrame.new(pos)
			crystal.Parent = folder
		elseif r < CONFIG.LavaPoolChance and biome == "Magma" then
			local lava = Instance.new("Part")
			lava.Name = "LavaPool"
			lava.Anchored = true
			lava.CanCollide = false
			lava.Material = Enum.Material.Neon
			lava.Color = Color3.fromRGB(255, 80, 0)
			lava.Transparency = 0.2
			lava.Size = Vector3.new(4, 1, 4)
			lava.CFrame = CFrame.new(pos)
			lava.Parent = folder
			-- Damage on touch
			lava.Touched:Connect(function(hit)
				local hum = hit.Parent and hit.Parent:FindFirstChild("Humanoid")
				if hum then hum:TakeDamage(5) end
			end)
		end
	end
	return folder
end

-- ─── Pick underground biome based on Y depth ───────────────────────
local function pickBiome(centerY, seed)
	local depth = math.abs(centerY - CONFIG.UndergroundY)
	if depth > 80 then return "Magma"
	elseif depth > 40 then return "Crystal"
	else return "Gloom"
	end
end

-- ─── Public: Generate a cave network at a position ────────────────────
function CaveSystem.GenerateCaves(chunkX, chunkZ, seed)
	if not CONFIG.Enabled then return end
	local rng = Random.new(seed + chunkX * 7919 + chunkZ * 6271)
	local centerY = CONFIG.UndergroundY - rng:NextInteger(0, 60)
	local biome = pickBiome(centerY, seed)
	local caveData = { tunnels = {}, biome = biome }

	for i = 1, CONFIG.MaxTunnels do
		local startPos = Vector3.new(
			chunkX + rng:NextInteger(-20, 20),
			centerY + rng:NextInteger(-10, 10),
			chunkZ + rng:NextInteger(-20, 20)
		)
		local tunnelSeed = seed + i * 1234 + chunkX + chunkZ
		local cells = drunkardWalk(startPos, CONFIG.TunnelLength, tunnelSeed)
		local widened = widenCells(cells, CONFIG.TunnelRadius)
		local folder = placeCaveGeometry(widened, biome, rng)
		table.insert(caveData.tunnels, { folder = folder, startPos = startPos })

		-- Notify AIDirector about new cave spawn zone
		if rng:NextNumber() < CONFIG.MobSpawnChance then
			EventBus:Fire("CaveRoomReady", {
				position = startPos,
				biome    = biome,
				mobs     = BIOMES[biome].mobs,
			})
		end
	end

	table.insert(registeredCaves, caveData)
	EventBus:Fire("CaveGenerated", { chunkX = chunkX, chunkZ = chunkZ, biome = biome })
	return caveData
end

-- ─── Connect to existing dungeons ─────────────────────────────────
function CaveSystem.ConnectToDungeon(dungeonPos, seed)
	if not CONFIG.Enabled then return end
	local rng = Random.new(seed + 9999)
	local startPos = dungeonPos + Vector3.new(0, -20, 0)
	local cells = drunkardWalk(startPos, 30, seed)
	local widened = widenCells(cells, math.floor(CONFIG.TunnelRadius * 0.7))
	placeCaveGeometry(widened, "Gloom", rng)
end

-- ─── Init ─────────────────────────────────────────────────────
function CaveSystem.Init()
	if not CONFIG.Enabled then return end
	-- Hook into DungeonGenerator: create connecting tunnel for each placed dungeon
	EventBus:On("DungeonPlaced", function(data)
		if data and data.position then
			CaveSystem.ConnectToDungeon(data.position, data.seed or 12345)
		end
	end)
	if WorldConfig.Debug then
		warn("[CaveSystem] Initialized | MaxTunnels:", CONFIG.MaxTunnels, "| BaseY:", CONFIG.UndergroundY)
	end
end

return CaveSystem
