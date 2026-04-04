-- SoundManager.lua  (ModuleScript)
-- Plays sounds at world positions or for specific players.
-- Uses ONLY rbxasset:// built-in Roblox sounds — no uploading required.
-- v7.0 | roblox-procedural-worlds

local Workspace = game:GetService("Workspace")
local Players   = game:GetService("Players")

local SoundManager = {}

-- ─ Built-in sound library ──────────────────────────────────────────
local SOUNDS = {
	hit           = "rbxasset://sounds/hit.wav",
	explosion     = "rbxasset://sounds/Explosion.wav",
	levelup       = "rbxasset://sounds/electronicpingshort.wav",
	step          = "rbxasset://sounds/action_footsteps_plastic.mp3",
	ambient_forest= "rbxasset://sounds/ambient.wav",
	click         = "rbxasset://sounds/uiclick.wav",
	death         = "rbxasset://sounds/Uuhhh.wav",
	splash        = "rbxasset://sounds/impact_water.mp3",
	swing         = "rbxasset://sounds/action_get_up.mp3",
	build         = "rbxasset://sounds/snap.mp3",
}

local ambienceSound = nil  -- current looping ambience Sound instance

-- ─ playAtPosition ───────────────────────────────────────────────
-- Creates a temporary invisible Part at `position`, attaches a Sound, plays it, destroys after.
function SoundManager.playAtPosition(soundName, position, volume, pitch)
	local assetId = SOUNDS[soundName]
	if not assetId then return end

	local part = Instance.new("Part")
	part.Anchored     = true
	part.CanCollide   = false
	part.Transparency = 1
	part.Size         = Vector3.new(1, 1, 1)
	part.CFrame       = CFrame.new(position or Vector3.new(0, 0, 0))
	part.Parent       = Workspace

	local sound = Instance.new("Sound", part)
	sound.SoundId     = assetId
	sound.Volume      = math.clamp(volume or 0.8, 0, 10)
	sound.PlaybackSpeed = math.clamp(pitch or 1, 0.1, 4)
	sound.RollOffMaxDistance = 120
	sound.RollOffMinDistance = 1
	sound:Play()

	sound.Ended:Connect(function()
		part:Destroy()
	end)
	-- Safety destroy after 10s
	task.delay(10, function()
		if part and part.Parent then part:Destroy() end
	end)
end

-- ─ playForPlayer (server-side: fires a client event — fallback: play at player pos) ────
function SoundManager.playForPlayer(player, soundName, volume)
	-- Best used with a client-side handler on NotificationRemote.
	-- As a fallback we play at the player\'s character position from the server.
	if not player or not player.Character then return end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		SoundManager.playAtPosition(soundName, hrp.Position, volume or 0.8, 1)
	end
end

-- ─ setAmbience ────────────────────────────────────────────────────
-- Swaps the looping ambient Sound in Workspace. Called from AmbienceClient on the client.
function SoundManager.setAmbience(biomeName)
	local assetId = SOUNDS["ambient_" .. (biomeName or "forest")]
				or SOUNDS["ambient_forest"]

	if ambienceSound and ambienceSound.Parent then
		ambienceSound:Stop()
		ambienceSound:Destroy()
	end

	ambienceSound = Instance.new("Sound")
	ambienceSound.SoundId  = assetId
	ambienceSound.Volume   = 0.15
	ambienceSound.Looped   = true
	ambienceSound.Parent   = Workspace
	ambienceSound:Play()
end

return SoundManager
