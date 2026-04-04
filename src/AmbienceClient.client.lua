-- AmbienceClient.client.lua  (LocalScript → StarterPlayerScripts)
-- Polls player biome every 5s, crossfades ambient sound loop over 2s.
-- Uses SoundService for client-side audio.

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")

local player  = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("ProceduralWorldsRemotes", 10)
local seedRemote = remotes and remotes:FindFirstChild("SeedRemote")

-- Biome ambient SoundId map (rbxasset:// only)
local BIOME_SOUNDS = {
	Forest    = "rbxasset://sounds/ambient.wav",
	Jungle    = "rbxasset://sounds/ambient.wav",
	Grassland = "rbxasset://sounds/ambient.wav",
	Desert    = "rbxasset://sounds/electronicpingshort.wav",
	Tundra    = "rbxasset://sounds/electronicpingshort.wav",
	Snow      = "rbxasset://sounds/electronicpingshort.wav",
	Swamp     = "rbxasset://sounds/ambient.wav",
	Ocean     = "rbxasset://sounds/impact_water.mp3",
	Volcano   = "rbxasset://sounds/Explosion.wav",
}

local currentBiome   = nil
local currentSound   = nil
local crossfadeActive = false

local function crossfadeTo(biome)
	if biome == currentBiome then return end
	if crossfadeActive then return end
	crossfadeActive = true

	local newId = BIOME_SOUNDS[biome] or BIOME_SOUNDS.Forest

	local newSound = Instance.new("Sound")
	newSound.SoundId = newId
	newSound.Volume  = 0
	newSound.Looped  = true
	newSound.Parent  = SoundService
	newSound:Play()

	-- Crossfade: fade in new, fade out old over 2s
	TweenService:Create(newSound,
		TweenInfo.new(2, Enum.EasingStyle.Linear),
		{Volume = 0.18}
	):Play()

	if currentSound and currentSound.Parent then
		local fadeOut = TweenService:Create(currentSound,
			TweenInfo.new(2, Enum.EasingStyle.Linear),
			{Volume = 0}
		)
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			if currentSound and currentSound.Parent then
				currentSound:Stop()
				currentSound:Destroy()
			end
		end)
	end

	currentSound  = newSound
	currentBiome  = biome
	crossfadeActive = false
end

-- Start with Forest
crossfadeTo("Forest")

-- Poll biome from character attribute every 5 seconds
local lastPoll = 0
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastPoll < 5 then return end
	lastPoll = now

	local char = player.Character
	if not char then return end
	local biome = char:GetAttribute("CurrentBiome") or "Forest"
	crossfadeTo(biome)
end)
