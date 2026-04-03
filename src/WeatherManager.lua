--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/WeatherManager  [v2.1 NEW]
-- Biome-zone weather: rain, snow, ash particle effects.
-- Polls each player's biome every WeatherCheckInterval seconds
-- and fires WeatherChanged RemoteEvent when the zone changes.
--
-- Zones:
--   Forest / Grassland / Jungle / Swamp → Rain
--   Snow / Tundra                       → Snowfall
--   Volcano                             → Ash
--   Desert / Ocean                      → Clear
--
-- Usage: WeatherManager.Start(seed)
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local WorldConfig   = require(ReplicatedStorage:WaitForChild("WorldConfig"))
local BiomeResolver = require(ReplicatedStorage:WaitForChild("BiomeResolver"))

local function getOrCreateRemote(name: string): RemoteEvent
	local existing = ReplicatedStorage:FindFirstChild(name) :: RemoteEvent?
	if existing then return existing end
	local re = Instance.new("RemoteEvent")
	re.Name   = name
	re.Parent = ReplicatedStorage
	return re
end

local WeatherEvent = getOrCreateRemote("WeatherChanged")

type WeatherType = "Rain" | "Snow" | "Ash" | "Clear"

local BIOME_WEATHER: { [string]: WeatherType } = {
	Forest    = "Rain",
	Grassland = "Rain",
	Jungle    = "Rain",
	Swamp     = "Rain",
	Snow      = "Snow",
	Tundra    = "Snow",
	Volcano   = "Ash",
	Desert    = "Clear",
	Ocean     = "Clear",
}

local playerWeather: { [number]: WeatherType } = {}

local function noise2D(seed: number, x: number, z: number, scale: number): number
	return (math.noise(seed + x / scale, z / scale) + 1) * 0.5
end

local function getPlayerBiome(seed: number, player: Player): string?
	local char = player.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return nil end
	local pos = root.Position
	local cfg = WorldConfig.Settings
	local temp     = noise2D(seed + 3000, pos.X, pos.Z, cfg.TempScale)
	local moisture = noise2D(seed + 4000, pos.X, pos.Z, cfg.MoistureScale)
	local result   = BiomeResolver.Resolve(temp, moisture)
	return result.Biome.Name
end

local WeatherManager = {}

function WeatherManager.Start(seed: number)
	local interval = WorldConfig.Settings.WeatherCheckInterval or 8

	task.spawn(function()
		while true do
			task.wait(interval)
			for _, player in Players:GetPlayers() do
				local biomeName = getPlayerBiome(seed, player)
				if not biomeName then continue end
				local weather: WeatherType = BIOME_WEATHER[biomeName] or "Clear"
				local prev = playerWeather[player.UserId]
				if weather ~= prev then
					playerWeather[player.UserId] = weather
					WeatherEvent:FireClient(player, weather)
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerWeather[player.UserId] = nil
	end)
end

return WeatherManager
