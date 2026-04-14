-- WorldEventManager.lua
-- Global random world events: MeteorShower, BloodMoon, Invasion, FogWave
-- v2.8 | roblox-procedural-worlds

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(script.Parent.WorldConfig)
local EventBus = require(script.Parent.EventBus)
local MobSpawner = require(script.Parent.MobSpawner)
local ObjectPool = require(script.Parent.ObjectPool)

local WorldEventManager = {}

local CONFIG = WorldConfig.Events or {
	Enabled        = true,
	MinInterval    = 600,     -- seconds between events
	MaxInterval    = 1200,
	MeteorCount    = 8,
	InvasionWaves  = 3,
	BloodMoonMult  = 2.0,     -- mob HP + spawn rate multiplier
}

-- Event definitions
local EVENTS = {
	"BloodMoon",
	"MeteorShower",
	"Invasion",
	"FogWave",
}

local activeEvent = nil
local eventConnection = nil

-- Remote for client-side effects
local clientRemote
local function ensureRemote()
	if clientRemote then return end
	local folder = ReplicatedStorage:FindFirstChild("WorldEventRemotes")
			or Instance.new("Folder")
	folder.Name = "WorldEventRemotes"
	folder.Parent = ReplicatedStorage
	clientRemote = folder:FindFirstChild("EventNotify")
	if not clientRemote then
		clientRemote = Instance.new("RemoteEvent")
		clientRemote.Name = "EventNotify"
		clientRemote.Parent = folder
	end
end

local function notifyAll(eventName, data)
	clientRemote:FireAllClients(eventName, data)
	EventBus:Fire("WorldEvent", eventName, data)
end

-- ─── BloodMoon ───────────────────────────────────────────────
local function startBloodMoon()
	local origAmbient = Lighting.Ambient
	local origFog = Lighting.FogColor
	Lighting.Ambient = Color3.fromRGB(120, 0, 0)
	Lighting.FogColor = Color3.fromRGB(80, 0, 0)
	Lighting.FogEnd = 300
	MobSpawner.SetMultiplier(CONFIG.BloodMoonMult)
	notifyAll("BloodMoon", { active = true })

	task.delay(300, function()
		if activeEvent ~= "BloodMoon" then return end
		Lighting.Ambient = origAmbient
		Lighting.FogColor = origFog
		Lighting.FogEnd = 1000
		MobSpawner.SetMultiplier(1)
		notifyAll("BloodMoon", { active = false })
		activeEvent = nil
	end)
end

-- ─── MeteorShower ────────────────────────────────────────────
local function spawnMeteor(origin)
	local meteor = ObjectPool.Get("Meteor")
	if not meteor then
		meteor = Instance.new("Part")
		meteor.Name = "Meteor"
		meteor.Shape = Enum.PartType.Ball
		meteor.Size = Vector3.new(6, 6, 6)
		meteor.BrickColor = BrickColor.new("Bright orange")
		meteor.Material = Enum.Material.Neon
	end
	meteor.CFrame = CFrame.new(origin + Vector3.new(0, 300, 0))
	meteor.Velocity = Vector3.new(
		math.random(-20, 20),
		-80,
		math.random(-20, 20)
	)
	meteor.Parent = workspace

	-- Impact after ~4 seconds
	task.delay(4, function()
		local impactPos = meteor.Position
		ObjectPool.Return("Meteor", meteor)
		-- Spawn rare ore at impact point
		EventBus:Fire("MeteorImpact", impactPos)
	end)
end

local function startMeteorShower()
	notifyAll("MeteorShower", { active = true })
	local count = CONFIG.MeteorCount
	for i = 1, count do
		task.delay(i * 1.5, function()
			if activeEvent ~= "MeteorShower" then return end
			local allPlayers = Players:GetPlayers()
			if #allPlayers == 0 then return end
			local target = allPlayers[math.random(1, #allPlayers)]
			local char = target.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local offset = Vector3.new(
					math.random(-100, 100),
					0,
					math.random(-100, 100)
				)
				spawnMeteor(hrp.Position + offset)
			end
		end)
	end
	task.delay(count * 1.5 + 5, function()
		if activeEvent ~= "MeteorShower" then return end
		notifyAll("MeteorShower", { active = false })
		activeEvent = nil
	end)
end

-- ─── Invasion ────────────────────────────────────────────────
local function startInvasion()
	notifyAll("Invasion", { active = true, waves = CONFIG.InvasionWaves })
	-- Find most populated chunk center
	local allPlayers = Players:GetPlayers()
	local center = Vector3.new(0, 0, 0)
	if #allPlayers > 0 then
		for _, p in ipairs(allPlayers) do
			local char = p.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then center = center + hrp.Position end
		end
		center = center / #allPlayers
	end

	for wave = 1, CONFIG.InvasionWaves do
		task.delay((wave - 1) * 30, function()
			if activeEvent ~= "Invasion" then return end
			MobSpawner.SpawnWave(center, wave * 5, "Invasion")
			EventBus:Fire("InvasionWave", wave)
		end)
	end
	task.delay(CONFIG.InvasionWaves * 30 + 10, function()
		if activeEvent ~= "Invasion" then return end
		notifyAll("Invasion", { active = false })
		activeEvent = nil
	end)
end

-- ─── FogWave ─────────────────────────────────────────────────
local function startFogWave()
	local origEnd = Lighting.FogEnd
	local origStart = Lighting.FogStart
	Lighting.FogEnd = 80
	Lighting.FogStart = 10
	Lighting.FogColor = Color3.fromRGB(180, 180, 200)
	notifyAll("FogWave", { active = true })
	task.delay(180, function()
		if activeEvent ~= "FogWave" then return end
		Lighting.FogEnd = origEnd
		Lighting.FogStart = origStart
		notifyAll("FogWave", { active = false })
		activeEvent = nil
	end)
end

-- ─── Dispatcher ──────────────────────────────────────────────
local eventHandlers = {
	BloodMoon    = startBloodMoon,
	MeteorShower = startMeteorShower,
	Invasion     = startInvasion,
	FogWave      = startFogWave,
}

local function triggerRandomEvent()
	if activeEvent then return end
	local players = Players:GetPlayers()
	if #players == 0 then return end
	local eventName = EVENTS[math.random(1, #EVENTS)]
	activeEvent = eventName
	if WorldConfig.Debug then
		warn("[WorldEventManager] Triggering:", eventName)
	end
	eventHandlers[eventName]()
end

-- ─── Public API ──────────────────────────────────────────────
function WorldEventManager.ForceEvent(eventName)
	if not eventHandlers[eventName] then return false end
	activeEvent = eventName
	eventHandlers[eventName]()
	return true
end

function WorldEventManager.GetActiveEvent()
	return activeEvent
end

function WorldEventManager.Init()
	if not CONFIG.Enabled then return end
	ensureRemote()

	local function scheduleNext()
		local interval = math.random(CONFIG.MinInterval, CONFIG.MaxInterval)
		task.delay(interval, function()
			triggerRandomEvent()
			scheduleNext()
		end)
	end
	scheduleNext()

	if WorldConfig.Debug then
		warn("[WorldEventManager] Initialized | Events:", table.concat(EVENTS, ", "))
	end
end

return WorldEventManager
