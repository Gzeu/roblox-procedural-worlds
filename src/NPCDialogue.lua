-- NPCDialogue.lua
-- Proximity-based NPC dialogue with biome-aware lines and quest hints
-- Server creates dialogue; client receives via RemoteEvent
-- v2.5.0

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local WorldConfig   = require(script.Parent.WorldConfig)
local BiomeResolver = require(script.Parent.BiomeResolver)

local NPCDialogue = {}

local TRIGGER_DIST  = 15  -- studs
local COOLDOWN      = 10  -- seconds between repeats per player/NPC pair
local dialogueEvent       -- RemoteEvent, created on Start

local lastTriggered = {}  -- { [userId .. "_" .. npcId] = tick() }
local registeredNPCs = {} -- { { model, lines, id } }
local npcCounter     = 0

local BIOME_GREETINGS = {
	Forest    = { "The forest whispers secrets tonight.", "Watch for wolves after dusk.", "I've found strange ruins nearby..." },
	Desert    = { "Water is scarce here, traveler.",     "The scorpions grow bolder each season.",  "An ancient pyramid lies to the east." },
	Tundra    = { "The cold never truly leaves here.",   "The Yeti have been restless lately.",     "Wrap yourself warm, friend." },
	Swamp     = { "Beware the Witch's hut at midnight.", "The water here will swallow you whole.",  "Slimes breed in the fog." },
	Jungle    = { "The jungle has eyes.",                "Raptors hunt in packs. Stay alert.",      "Ancient temples hide deadly traps." },
	Mountains = { "The Troll Bridge demands a toll.",    "Eagles circle the peak at dawn.",         "Legends speak of a dragon's hoard." },
	Plains    = { "Good harvest season, thank the gods.","Travelers often pass through here.",      "The horizon holds many adventures." },
	Ocean     = { "The Kraken stirs in the deep.",       "Many ships never returned from the fog.", "The tides bring strange treasures." },
	Default   = { "Safe travels, adventurer.",           "The world is vast and dangerous.",        "May fortune guide your path." },
}

local function getLinesForBiome(biomeName)
	return BIOME_GREETINGS[biomeName] or BIOME_GREETINGS.Default
end

local function triggerDialogue(player, npc, seed)
	local userId = player.UserId
	local key    = tostring(userId) .. "_" .. tostring(npc.id)
	if lastTriggered[key] and tick() - lastTriggered[key] < COOLDOWN then return end
	lastTriggered[key] = tick()

	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Pick biome-aware line
	local worldSeed = seed or 0
	local biomeName = BiomeResolver.GetBiomeAt(
		root.Position.X, root.Position.Z, worldSeed
	)
	local lines   = getLinesForBiome(biomeName)
	local rng     = Random.new(tick() * 1000 + npc.id)
	local line    = lines[rng:NextInteger(1, #lines)]
	local npcName = npc.model.Name

	if dialogueEvent then
		dialogueEvent:FireClient(player, npcName, line)
	end
end

function NPCDialogue.Register(npcModel, customLines)
	npcCounter = npcCounter + 1
	table.insert(registeredNPCs, {
		model = npcModel,
		lines = customLines or nil,
		id    = npcCounter,
	})
end

function NPCDialogue.Start(worldSeed)
	-- Create RemoteEvent for client communication
	local remotes = game:GetService("ReplicatedStorage")
	dialogueEvent = Instance.new("RemoteEvent")
	dialogueEvent.Name   = "NPCDialogueEvent"
	dialogueEvent.Parent = remotes

	-- Proximity check loop
	RunService.Heartbeat:Connect(function()
		for _, npc in ipairs(registeredNPCs) do
			local npcRoot = npc.model:FindFirstChild("HumanoidRootPart")
			if not npcRoot then continue end

			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				if not char then continue end
				local root = char:FindFirstChild("HumanoidRootPart")
				if not root then continue end
				local dist = (root.Position - npcRoot.Position).Magnitude
				if dist <= TRIGGER_DIST then
					triggerDialogue(player, npc, worldSeed)
				end
			end
		end
	end)
end

return NPCDialogue
