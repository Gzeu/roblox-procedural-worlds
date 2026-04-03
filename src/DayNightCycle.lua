-- DayNightCycle.lua
-- Smooth day/night cycle with Lighting control and time-of-day events
-- v2.4.0

local Lighting    = game:GetService("Lighting")
local RunService  = game:GetService("RunService")
local WorldConfig = require(script.Parent.WorldConfig)

local DayNightCycle = {}

local currentTime  = WorldConfig.DayNight.StartHour or 8  -- 0-24
local cyclePaused  = false
local lastTick     = 0
local callbacks    = { onDawn = {}, onDusk = {}, onNoon = {}, onMidnight = {} }

local DAWN_HOUR     = 6
local DUSK_HOUR     = 20
local NOON_HOUR     = 12
local MIDNIGHT_HOUR = 0
local TOLERANCE     = 0.05  -- trigger window

local firedThisCycle = {}

local function fireEvent(name)
	if firedThisCycle[name] then return end
	firedThisCycle[name] = true
	for _, cb in ipairs(callbacks[name] or {}) do
		task.spawn(cb)
	end
end

local function resetFiredFlags()
	for k in pairs(firedThisCycle) do
		firedThisCycle[k] = nil
	end
end

local function applyLighting(hour)
	Lighting.ClockTime   = hour
	Lighting.GeographicLatitude = WorldConfig.DayNight.Latitude or 41

	-- Ambient and brightness curve
	local t = (hour / 24)
	local dayFactor = math.clamp(math.sin(t * math.pi * 2 - math.pi * 0.5) * 0.5 + 0.5, 0, 1)

	Lighting.Ambient = Color3.fromRGB(
		math.floor(30 + dayFactor * 60),
		math.floor(30 + dayFactor * 60),
		math.floor(50 + dayFactor * 50)
	)
	Lighting.Brightness   = 0.5 + dayFactor * 2.5
	Lighting.OutdoorAmbient = Color3.fromRGB(
		math.floor(50 + dayFactor * 100),
		math.floor(50 + dayFactor * 100),
		math.floor(80 + dayFactor * 80)
	)

	-- Sky colours at dawn/dusk
	if hour >= 5 and hour <= 7 then
		Lighting.FogColor  = Color3.fromRGB(220, 150, 100)
		Lighting.FogEnd    = 500
		Lighting.FogStart  = 200
	elseif hour >= 19 and hour <= 21 then
		Lighting.FogColor  = Color3.fromRGB(180, 80, 60)
		Lighting.FogEnd    = 400
		Lighting.FogStart  = 150
	elseif hour >= 22 or hour <= 4 then
		Lighting.FogColor  = Color3.fromRGB(10, 10, 30)
		Lighting.FogEnd    = 800
		Lighting.FogStart  = 300
	else
		Lighting.FogColor  = Color3.fromRGB(180, 210, 230)
		Lighting.FogEnd    = 2000
		Lighting.FogStart  = 800
	end
end

function DayNightCycle.GetHour()
	return currentTime
end

function DayNightCycle.SetHour(hour)
	currentTime = hour % 24
	applyLighting(currentTime)
end

function DayNightCycle.IsDaytime()
	return currentTime >= DAWN_HOUR and currentTime < DUSK_HOUR
end

function DayNightCycle.OnDawn(callback)
	table.insert(callbacks.onDawn, callback)
end

function DayNightCycle.OnDusk(callback)
	table.insert(callbacks.onDusk, callback)
end

function DayNightCycle.OnNoon(callback)
	table.insert(callbacks.onNoon, callback)
end

function DayNightCycle.OnMidnight(callback)
	table.insert(callbacks.onMidnight, callback)
end

function DayNightCycle.Pause()
	cyclePaused = true
end

function DayNightCycle.Resume()
	cyclePaused = false
end

function DayNightCycle.Start()
	lastTick = tick()
	applyLighting(currentTime)

	RunService.Heartbeat:Connect(function()
		if cyclePaused then return end

		local now   = tick()
		local delta = now - lastTick
		lastTick    = now

		-- Advance time
		local speed = WorldConfig.DayNight.CycleMinutes or 20  -- real minutes per full day
		local hoursPerSecond = 24 / (speed * 60)
		currentTime = (currentTime + delta * hoursPerSecond) % 24

		applyLighting(currentTime)

		-- Reset fired flags at midnight
		if currentTime < 0.05 then resetFiredFlags() end

		-- Fire time events
		if math.abs(currentTime - DAWN_HOUR)     < TOLERANCE then fireEvent("onDawn")     end
		if math.abs(currentTime - NOON_HOUR)     < TOLERANCE then fireEvent("onNoon")     end
		if math.abs(currentTime - DUSK_HOUR)     < TOLERANCE then fireEvent("onDusk")     end
		if currentTime < TOLERANCE                            then fireEvent("onMidnight") end
	end)
end

return DayNightCycle
