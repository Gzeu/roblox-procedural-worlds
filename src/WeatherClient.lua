--!strict
-- ============================================================
-- LOCAL SCRIPT: StarterPlayerScripts/WeatherClient  [v2.1 NEW]
-- Receives WeatherChanged events from the server and manages
-- particle effects (Rain, Snow, Ash) attached above the camera.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

local camera    = workspace.CurrentCamera

local WeatherEvent = ReplicatedStorage:WaitForChild("WeatherChanged", 30) :: RemoteEvent?
if not WeatherEvent then return end

type EmitterMap = { [string]: ParticleEmitter }
local emitters: EmitterMap = {}

local PARTICLE_CONFIGS: { [string]: {
	Color: ColorSequence,
	Size: NumberSequence,
	Speed: NumberRange,
	Rate: number,
	Lifetime: NumberRange,
	Rotation: NumberRange,
} } = {
	Rain = {
		Color    = ColorSequence.new(Color3.fromRGB(150, 180, 220)),
		Size     = NumberSequence.new(0.08),
		Speed    = NumberRange.new(40, 55),
		Rate     = 300,
		Lifetime = NumberRange.new(0.6, 1.0),
		Rotation = NumberRange.new(-10, 10),
	},
	Snow = {
		Color    = ColorSequence.new(Color3.fromRGB(230, 240, 255)),
		Size     = NumberSequence.new(0.18),
		Speed    = NumberRange.new(6, 14),
		Rate     = 120,
		Lifetime = NumberRange.new(2, 3.5),
		Rotation = NumberRange.new(0, 360),
	},
	Ash = {
		Color    = ColorSequence.new(Color3.fromRGB(80, 60, 55)),
		Size     = NumberSequence.new(0.25),
		Speed    = NumberRange.new(3, 8),
		Rate     = 80,
		Lifetime = NumberRange.new(3, 5),
		Rotation = NumberRange.new(0, 360),
	},
}

local weatherPart = Instance.new("Part")
weatherPart.Size         = Vector3.new(1, 1, 1)
weatherPart.Anchored     = true
weatherPart.CanCollide   = false
weatherPart.Transparency = 1
weatherPart.Name         = "WeatherAnchor"
weatherPart.Parent       = workspace

for weatherType, config in PARTICLE_CONFIGS do
	local emitter          = Instance.new("ParticleEmitter")
	emitter.Name           = weatherType
	emitter.Color          = config.Color
	emitter.Size           = config.Size
	emitter.Speed          = config.Speed
	emitter.Rate           = 0
	emitter.Lifetime       = config.Lifetime
	emitter.Rotation       = config.Rotation
	emitter.LockedToPart   = false
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent         = weatherPart
	emitters[weatherType]  = emitter
end

RunService.RenderStepped:Connect(function()
	if camera then
		weatherPart.CFrame = camera.CFrame * CFrame.new(0, 12, 0)
	end
end)

local function setWeather(weatherType: string)
	for name, emitter in emitters do
		if name == weatherType then
			local cfg = PARTICLE_CONFIGS[name]
			emitter.Rate = if cfg then cfg.Rate else 0
		else
			emitter.Rate = 0
		end
	end
end

WeatherEvent.OnClientEvent:Connect(function(weatherType: string)
	setWeather(weatherType)
end)

setWeather("Clear")
