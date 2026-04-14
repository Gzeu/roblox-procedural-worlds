-- SeasonSystem.lua
-- 4 seasons: Spring, Summer, Autumn, Winter. Each lasts DurationMinutes real time.
-- Integrates with DayNightCycle, ParticleEffects, WaterFlow (frozen lakes)
-- v2.8 | roblox-procedural-worlds

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(script.Parent.WorldConfig)
local EventBus = require(script.Parent.EventBus)

local SeasonSystem = {}

local CONFIG = WorldConfig.Seasons or {
	Enabled          = true,
	DurationMinutes  = 30,
	StartSeason      = "Spring",
}

local SEASON_ORDER = { "Spring", "Summer", "Autumn", "Winter" }

local SEASON_DATA = {
	Spring = {
		Ambient         = Color3.fromRGB(180, 200, 180),
		OutdoorAmbient  = Color3.fromRGB(160, 200, 160),
		Brightness      = 2.5,
		FogEnd          = 1200,
		FogColor        = Color3.fromRGB(200, 230, 200),
		FrozenWater     = false,
		LeafParticles   = false,
		SnowOverlay     = false,
	},
	Summer = {
		Ambient         = Color3.fromRGB(220, 200, 160),
		OutdoorAmbient  = Color3.fromRGB(230, 210, 150),
		Brightness      = 3.0,
		FogEnd          = 1800,
		FogColor        = Color3.fromRGB(255, 240, 200),
		FrozenWater     = false,
		LeafParticles   = false,
		SnowOverlay     = false,
	},
	Autumn = {
		Ambient         = Color3.fromRGB(200, 150, 80),
		OutdoorAmbient  = Color3.fromRGB(190, 130, 60),
		Brightness      = 2.0,
		FogEnd          = 700,
		FogColor        = Color3.fromRGB(220, 170, 100),
		FrozenWater     = false,
		LeafParticles   = true,
		SnowOverlay     = false,
	},
	Winter = {
		Ambient         = Color3.fromRGB(180, 200, 230),
		OutdoorAmbient  = Color3.fromRGB(160, 190, 230),
		Brightness      = 1.5,
		FogEnd          = 400,
		FogColor        = Color3.fromRGB(220, 230, 255),
		FrozenWater     = true,
		LeafParticles   = false,
		SnowOverlay     = true,
	},
}

local currentSeason = CONFIG.StartSeason or "Spring"
local seasonIndex = 1

-- Remote for client overlay effects
local clientRemote
local function ensureRemote()
	if clientRemote then return end
	local folder = ReplicatedStorage:FindFirstChild("SeasonRemotes")
			or Instance.new("Folder")
	folder.Name = "SeasonRemotes"
	folder.Parent = ReplicatedStorage
	clientRemote = folder:FindFirstChild("SeasonChanged")
	if not clientRemote then
		clientRemote = Instance.new("RemoteEvent")
		clientRemote.Name = "SeasonChanged"
		clientRemote.Parent = folder
	end
end

local function applySeasonLighting(seasonName)
	local data = SEASON_DATA[seasonName]
	if not data then return end
	local tweenInfo = TweenInfo.new(10, Enum.EasingStyle.Sine)
	local tween = TweenService:Create(Lighting, tweenInfo, {
		Ambient        = data.Ambient,
		OutdoorAmbient = data.OutdoorAmbient,
		Brightness     = data.Brightness,
		FogEnd         = data.FogEnd,
		FogColor       = data.FogColor,
	})
	tween:Play()
end

local function transitionToSeason(newSeason)
	local prev = currentSeason
	currentSeason = newSeason
	applySeasonLighting(newSeason)
	local data = SEASON_DATA[newSeason]
	-- Notify client for overlay effects (snow, leaves)
	clientRemote:FireAllClients(newSeason, data)
	-- Notify other server modules
	EventBus:Fire("SeasonChanged", newSeason, prev)
	-- WaterFlow integration
	if data.FrozenWater then
		EventBus:Fire("FreezeWater", true)
	else
		EventBus:Fire("FreezeWater", false)
	end
	if WorldConfig.Debug then
		warn("[SeasonSystem]", prev, "→", newSeason)
	end
end

local function startSeasonLoop()
	-- Find starting index
	for i, name in ipairs(SEASON_ORDER) do
		if name == currentSeason then
			seasonIndex = i
			break
		end
	end
	-- Apply initial season immediately
	applySeasonLighting(currentSeason)
	local data = SEASON_DATA[currentSeason]
	clientRemote:FireAllClients(currentSeason, data)
	EventBus:Fire("SeasonChanged", currentSeason, nil)
	if data.FrozenWater then EventBus:Fire("FreezeWater", true) end

	local durationSeconds = CONFIG.DurationMinutes * 60

	local function scheduleNext()
		task.delay(durationSeconds, function()
			seasonIndex = (seasonIndex % #SEASON_ORDER) + 1
			local next = SEASON_ORDER[seasonIndex]
			transitionToSeason(next)
			scheduleNext()
		end)
	end
	scheduleNext()
end

-- Public API
function SeasonSystem.GetCurrentSeason()
	return currentSeason
end

function SeasonSystem.GetSeasonData(name)
	return SEASON_DATA[name or currentSeason]
end

function SeasonSystem.ForceSeason(name)
	if not SEASON_DATA[name] then return false end
	transitionToSeason(name)
	return true
end

function SeasonSystem.Init()
	if not CONFIG.Enabled then return end
	ensureRemote()
	startSeasonLoop()
	if WorldConfig.Debug then
		warn("[SeasonSystem] Initialized | Start:", currentSeason, "| Duration:", CONFIG.DurationMinutes, "min")
	end
end

return SeasonSystem
