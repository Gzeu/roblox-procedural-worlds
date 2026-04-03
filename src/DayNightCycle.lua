-- DayNightCycle.lua
-- Smooth day/night cycle synced across all clients via Lighting
-- Day length configurable in WorldConfig
-- v2.5.0

local Lighting    = game:GetService("Lighting")
local RunService  = game:GetService("RunService")
local WorldConfig = require(script.Parent.WorldConfig)

local DayNightCycle = {}

local elapsed   = 0
local started   = false

-- Map 0..1 time of day to Lighting.ClockTime (0-24)
local function toDayClock(t)
	return t * 24
end

-- Ambient and sky color transitions
local PHASES = {
	-- { timeNorm, ambient R,G,B, outoor R,G,B }
	{ t = 0.0,  amb = Color3.fromRGB(10,10,30),   sky = Color3.fromRGB(5,5,20)   },  -- midnight
	{ t = 0.25, amb = Color3.fromRGB(80,50,30),   sky = Color3.fromRGB(180,80,20) }, -- dawn
	{ t = 0.35, amb = Color3.fromRGB(200,180,150),sky = Color3.fromRGB(255,200,120) },-- sunrise
	{ t = 0.5,  amb = Color3.fromRGB(180,200,220),sky = Color3.fromRGB(120,170,255) },-- noon
	{ t = 0.65, amb = Color3.fromRGB(220,170,100),sky = Color3.fromRGB(255,160,60) }, -- sunset
	{ t = 0.75, amb = Color3.fromRGB(60,30,20),   sky = Color3.fromRGB(30,10,5)  },  -- dusk
	{ t = 1.0,  amb = Color3.fromRGB(10,10,30),   sky = Color3.fromRGB(5,5,20)   },  -- midnight again
}

local function lerpColor(a, b, t)
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

local function getPhaseColors(norm)
	for i = 1, #PHASES - 1 do
		local a = PHASES[i]
		local b = PHASES[i + 1]
		if norm >= a.t and norm <= b.t then
			local t = (norm - a.t) / (b.t - a.t)
			return lerpColor(a.amb, b.amb, t), lerpColor(a.sky, b.sky, t)
		end
	end
	return PHASES[1].amb, PHASES[1].sky
end

function DayNightCycle.Start(startTimeNorm)
	if started then return end
	started = true

	local dayLength = WorldConfig.DayLengthSeconds or 600
	-- Start at given normalized time (0-1), default noon
	elapsed = (startTimeNorm or 0.5) * dayLength

	RunService.Heartbeat:Connect(function(dt)
		elapsed = elapsed + dt
		local norm = (elapsed % dayLength) / dayLength

		Lighting.ClockTime = toDayClock(norm)

		local ambColor, skyColor = getPhaseColors(norm)
		Lighting.Ambient           = ambColor
		Lighting.OutdoorAmbient    = skyColor

		-- Night: enable shadows and reduce brightness
		if norm < 0.3 or norm > 0.7 then
			Lighting.Brightness = 0.3
		else
			Lighting.Brightness = 2.0
		end
	end)
end

function DayNightCycle.GetNormalized()
	local dayLength = WorldConfig.DayLengthSeconds or 600
	return (elapsed % dayLength) / dayLength
end

function DayNightCycle.IsNight()
	local t = DayNightCycle.GetNormalized()
	return t < 0.25 or t > 0.75
end

return DayNightCycle
