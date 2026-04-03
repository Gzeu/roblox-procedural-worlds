-- MobSpawner.lua
-- Biome-aware NPC/mob spawning with per-player cap and despawn
-- v2.2.0

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local WorldConfig   = require(script.Parent.WorldConfig)
local BiomeResolver = require(script.Parent.BiomeResolver)

local MobSpawner = {}

local activeMobs   = {}  -- { [mob] = { owner = player, spawnTick = tick() } }
local DESPAWN_DIST = 200 -- studs
local SPAWN_INTERVAL = 5 -- seconds
local lastSpawn    = 0
local seed         = 0

local function getMobPoolForBiome(biomeName)
	local cfg = WorldConfig.MobSpawns[biomeName]
	if cfg then return cfg end
	return WorldConfig.MobSpawns["Default"] or {}
end

local function countMobsForPlayer(player)
	local count = 0
	for _, data in pairs(activeMobs) do
		if data.owner == player then count = count + 1 end
	end
	return count
end

local function spawnMobNear(player, mobDef)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local angle  = math.random() * math.pi * 2
	local radius = math.random(30, 80)
	local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	local pos    = root.Position + offset

	local mob = Instance.new("Model")
	mob.Name = mobDef.name

	local part = Instance.new("Part")
	part.Size     = mobDef.size or Vector3.new(2, 3, 2)
	part.BrickColor = BrickColor.new(mobDef.color or "Medium stone grey")
	part.Anchored = false
	part.CFrame   = CFrame.new(pos + Vector3.new(0, part.Size.Y / 2, 0))
	part.Name     = "HumanoidRootPart"
	part.Parent   = mob

	local hum = Instance.new("Humanoid")
	hum.MaxHealth = mobDef.hp or 100
	hum.Health    = hum.MaxHealth
	hum.Parent    = mob

	mob:SetAttribute("MobType",  mobDef.name)
	mob:SetAttribute("Biome",    mobDef.biome or "Unknown")
	mob:SetAttribute("SpawnTick", tick())
	mob.Parent = workspace

	activeMobs[mob] = { owner = player, spawnTick = tick() }
	return mob
end

local function despawnStale()
	for mob, data in pairs(activeMobs) do
		if not mob or not mob.Parent then
			activeMobs[mob] = nil
					continue
		end
		local root = mob:FindFirstChild("HumanoidRootPart")
		local owner = data.owner
		if owner and owner.Character then
			local pr = owner.Character:FindFirstChild("HumanoidRootPart")
			if pr and root then
				local dist = (pr.Position - root.Position).Magnitude
				if dist > DESPAWN_DIST then
					mob:Destroy()
					activeMobs[mob] = nil
				end
			end
		end
	end
end

function MobSpawner.Start(worldSeed)
	seed = worldSeed or 0
	RunService.Heartbeat:Connect(function()
		if tick() - lastSpawn < SPAWN_INTERVAL then return end
		lastSpawn = tick()
		despawnStale()

		for _, player in ipairs(Players:GetPlayers()) do
			local cap = WorldConfig.MobSpawnCap or 10
			if countMobsForPlayer(player) >= cap then continue end

			local char = player.Character
			if not char then continue end
			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then continue end

			local biomeName = BiomeResolver.GetBiomeAt(
				root.Position.X, root.Position.Z, seed
			)
			local pool = getMobPoolForBiome(biomeName)
			if #pool == 0 then continue end

			local mobDef = pool[math.random(1, #pool)]
			spawnMobNear(player, mobDef)
		end
	end)
end

function MobSpawner.GetActive()
	return activeMobs
end

return MobSpawner
