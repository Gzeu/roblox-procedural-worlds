--!strict
-- ============================================================
-- MODULE: WeatherManager  [v1.1 - fixed]
-- Server-side weather state machine.
-- Broadcasts weather changes to clients via RemoteEvent.
-- ============================================================

local WorldConfig = require(script.Parent.WorldConfig)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local WeatherManager = {}

type WeatherState = "Clear" | "Rain" | "Storm" | "Snow" | "Fog"

local WEATHER_STATES: { WeatherState } = { "Clear", "Rain", "Storm", "Snow", "Fog" }
local TRANSITION_INTERVAL = 120  -- seconds between potential weather changes
local CHANGE_CHANCE       = 0.45  -- 45% chance to change each interval

local currentWeather: WeatherState = "Clear"
local elapsed = 0
local remoteEvent: RemoteEvent?

local function broadcast(weather: WeatherState)
	if remoteEvent then
		remoteEvent:FireAllClients(weather)
	end
end

local function pickNextWeather(seed: number): WeatherState
	local idx = (math.floor(os.clock()) + seed) % #WEATHER_STATES + 1
	return WEATHER_STATES[idx]
end

function WeatherManager.GetCurrent(): WeatherState
	return currentWeather
end

function WeatherManager.Start(seed: number)
	-- Create RemoteEvent for client broadcasts
	local existing = ReplicatedStorage:FindFirstChild("WeatherChanged")
	if existing then
		remoteEvent = existing :: RemoteEvent
	else
		local re = Instance.new("RemoteEvent")
		re.Name   = "WeatherChanged"
		re.Parent = ReplicatedStorage
		remoteEvent = re
	end

	broadcast(currentWeather)

	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < TRANSITION_INTERVAL then return end
		elapsed = 0

		if math.random() < CHANGE_CHANCE then
			local next = pickNextWeather(seed)
			if next ~= currentWeather then
				currentWeather = next
				broadcast(currentWeather)
				print("[WeatherManager] Weather →", currentWeather)
			end
		end
	end)
end

return WeatherManager
