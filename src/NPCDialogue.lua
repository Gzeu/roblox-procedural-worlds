-- NPCDialogue.lua
-- v4.0 | roblox-procedural-worlds
-- Dialogue tree with player choices, choice tracking, quest gating, biome-aware lines
-- Replaces v2.4 flat-line system; backwards-compatible (Register / Start APIs kept)

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local WorldConfig   = require(script.Parent.WorldConfig)
local BiomeResolver = require(script.Parent.BiomeResolver)
local QuestSystem   = require(script.Parent.QuestSystem)
local EventBus      = require(script.Parent.EventBus)

local NPCDialogue = {}

-- ── Config ───────────────────────────────────────────────────────
local TRIGGER_DIST       = 15   -- studs
local COOLDOWN           = 10   -- seconds per player/NPC pair
local CHOICE_TIMEOUT     = 20   -- seconds player has to pick a choice
local MAX_HISTORY        = 50   -- max dialogue choices remembered per player

-- ── Remote events ────────────────────────────────────────────────
local dialogueEvent  -- RemoteEvent: server → client (show dialogue line + choices)
local choiceEvent    -- RemoteEvent: client → server (player picked a choice)

-- ── State ────────────────────────────────────────────────────────
local lastTriggered   = {}   -- { ["uid_npcId"] = tick() }
local registeredNPCs  = {}   -- { { model, tree, id } }
local npcCounter      = 0
local activeDialogues = {}   -- { [userId] = { npcId, nodeId, expireAt } }
local playerHistory   = {}   -- { [userId] = { [npcId] = { choiceKey=true } } }

-- ── Biome-aware root lines ────────────────────────────────────────
local BIOME_GREETINGS = {
	Forest    = { "The forest whispers secrets tonight.",     "Watch for wolves after dusk.",       "I found strange ruins nearby..." },
	Desert    = { "Water is scarce here, traveler.",          "The scorpions grow bolder each season.","An ancient pyramid lies east."   },
	Tundra    = { "The cold never truly leaves here.",        "The Yeti have been restless lately.",  "Wrap yourself warm, friend."     },
	Swamp     = { "Beware the Witch's hut at midnight.",      "The water here will swallow you.",    "Slimes breed in the fog."        },
	Jungle    = { "The jungle has eyes.",                     "Raptors hunt in packs. Stay alert.",  "Ancient temples hide deadly traps."},
	Mountains = { "The Troll Bridge demands a toll.",         "Eagles circle the peak at dawn.",     "A dragon's hoard lies hidden above."},
	Plains    = { "Good harvest season, thank the gods.",     "Travelers pass through often.",       "The horizon holds many adventures."},
	Ocean     = { "The Kraken stirs in the deep.",            "Many ships never returned from the fog.","The tides bring strange treasures."},
	Default   = { "Safe travels, adventurer.",                "The world is vast and dangerous.",    "May fortune guide your path."    },
}

-- ── Dialogue tree node format ────────────────────────────────────
--[[
  A tree is a table of nodes keyed by node ID (string).
  Each node:
  {
    text     = "NPC says this",
    speaker  = "NPC Name" (optional, overrides model name)
    choices  = {        -- optional; if absent, dialogue ends
      { label = "Player text", next = "nodeId",
        questRequire = "questTitle" (optional),  -- only visible if quest active
        questComplete = "questTitle" (optional), -- completing this choice advances quest
        once = true   (optional)  -- hide after chosen once
      },
    }
  }
  Special nodeId "END" terminates the conversation.
]]

-- ── Default fallback tree ─────────────────────────────────────────
local function makeFallbackTree(lines)
	return {
		root = {
			text    = lines[1] or "Hello, traveler.",
			choices = {
				{ label = "Tell me more.", next = "more" },
				{ label = "Farewell.",     next = "END"  },
			},
		},
		more = {
			text    = lines[2] or "Stay safe out there.",
			choices = {
				{ label = "Any quests for me?", next = "quest" },
				{ label = "Goodbye.",           next = "END"   },
			},
		},
		quest = {
			text    = "I may have a task for a capable adventurer.",
			choices = {
				{ label = "I accept!",  next = "questAccept", questComplete = "__auto__" },
				{ label = "Not now.",   next = "END" },
			},
		},
		questAccept = {
			text    = "Good luck. Report back when it's done.",
		},
	}
end

-- ── Player history helpers ────────────────────────────────────────
local function getHistory(userId, npcId)
	playerHistory[userId] = playerHistory[userId] or {}
	playerHistory[userId][npcId] = playerHistory[userId][npcId] or {}
	return playerHistory[userId][npcId]
end

local function recordChoice(userId, npcId, choiceLabel)
	local h = getHistory(userId, npcId)
	h[choiceLabel] = true
	-- trim to MAX_HISTORY
	local keys, count = {}, 0
	for k in pairs(h) do count += 1; table.insert(keys, k) end
	if count > MAX_HISTORY then
		table.remove(keys, 1)
		h[keys[1]] = nil
	end
end

local function hasChosen(userId, npcId, choiceLabel)
	local h = getHistory(userId, npcId)
	return h[choiceLabel] == true
end

-- ── Choice filtering (quest gates, once flags) ────────────────────
local function filterChoices(player, npcId, choices)
	if not choices then return nil end
	local out = {}
	for _, c in ipairs(choices) do
		local show = true
		-- once: hide if already picked
		if c.once and hasChosen(player.UserId, npcId, c.label) then
			show = false
		end
		-- questRequire: only show if player has an active quest of that title
		if show and c.questRequire then
			local quests = QuestSystem.GetQuests(player)
			local found  = false
			for _, q in ipairs(quests) do
				if q.title == c.questRequire and not q.completed then
					found = true; break
				end
			end
			if not found then show = false end
		end
		if show then table.insert(out, c) end
	end
	return #out > 0 and out or nil
end

-- ── Send a dialogue node to client ───────────────────────────────
local function sendNode(player, npcName, npcId, nodeId, node)
	if not dialogueEvent then return end
	local filteredChoices = filterChoices(player, npcId, node.choices)
	dialogueEvent:FireClient(player, {
		npcName  = node.speaker or npcName,
		npcId    = npcId,
		nodeId   = nodeId,
		text     = node.text,
		choices  = filteredChoices,
	})
	-- Record active dialogue state
	activeDialogues[player.UserId] = {
		npcId    = npcId,
		nodeId   = nodeId,
		expireAt = os.clock() + CHOICE_TIMEOUT,
	}
end

-- ── Proximity trigger ────────────────────────────────────────────
local function tryTrigger(player, npc, worldSeed)
	local uid = player.UserId
	local key = tostring(uid) .. "_" .. tostring(npc.id)

	-- Don't interrupt an active dialogue
	if activeDialogues[uid] then
		if os.clock() < activeDialogues[uid].expireAt then return end
		activeDialogues[uid] = nil
	end

	if lastTriggered[key] and tick() - lastTriggered[key] < COOLDOWN then return end
	lastTriggered[key] = tick()

	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Build tree: use custom tree or generate fallback from biome lines
	local tree = npc.tree
	if not tree then
		local biomeName = BiomeResolver.GetBiomeAt(
			root.Position.X, root.Position.Z, worldSeed or 0)
		local biomeLines = BIOME_GREETINGS[biomeName] or BIOME_GREETINGS.Default
		tree = makeFallbackTree(biomeLines)
	end

	sendNode(player, npc.model.Name, npc.id, "root", tree["root"] or tree[1])
	EventBus.emit("NPCDialogue:Started", player, npc.model)
end

-- ── Choice handler (client → server) ─────────────────────────────
local function onChoiceReceived(player, payload)
	-- payload = { npcId, nodeId, choiceLabel, choiceNext }
	if type(payload) ~= "table" then return end

	local uid    = player.UserId
	local active = activeDialogues[uid]
	if not active then return end
	if active.npcId ~= payload.npcId then return end
	if os.clock() > active.expireAt then
		activeDialogues[uid] = nil; return
	end

	-- Find the NPC and tree
	local npc
	for _, n in ipairs(registeredNPCs) do
		if n.id == payload.npcId then npc = n; break end
	end
	if not npc then return end

	local tree = npc.tree or makeFallbackTree(BIOME_GREETINGS.Default)

	-- Validate choice exists in the current node
	local currentNode = tree[active.nodeId]
	if not currentNode or not currentNode.choices then
		activeDialogues[uid] = nil; return
	end

	local chosenChoice
	for _, c in ipairs(currentNode.choices) do
		if c.label == payload.choiceLabel then
			chosenChoice = c; break
		end
	end
	if not chosenChoice then return end

	-- Record history
	recordChoice(uid, npc.id, chosenChoice.label)

	-- Quest completion hook
	if chosenChoice.questComplete then
		if chosenChoice.questComplete == "__auto__" then
			QuestSystem.UpdateProgress(player, "npc", 1)
		else
			QuestSystem.UpdateProgress(player, chosenChoice.questComplete, 1)
		end
		EventBus.emit("NPCDialogue:QuestProgressed", player, npc.model, chosenChoice.questComplete)
	end

	EventBus.emit("NPCDialogue:ChoiceMade", player, npc.model, chosenChoice.label)

	-- Advance to next node
	local nextId = chosenChoice.next
	if not nextId or nextId == "END" then
		activeDialogues[uid] = nil
		if dialogueEvent then
			dialogueEvent:FireClient(player, { npcId = npc.id, end_ = true })
		end
		EventBus.emit("NPCDialogue:Ended", player, npc.model)
		return
	end

	local nextNode = tree[nextId]
	if not nextNode then
		activeDialogues[uid] = nil; return
	end

	sendNode(player, npc.model.Name, npc.id, nextId, nextNode)
end

-- ── Public API ────────────────────────────────────────────────────

-- Register an NPC with an optional dialogue tree
-- tree: nil → fallback biome tree; table → custom tree (see format above)
function NPCDialogue.Register(npcModel, treeOrLines)
	npcCounter = npcCounter + 1
	local tree = nil
	if type(treeOrLines) == "table" then
		-- detect if it's a tree (has "root" key) or legacy lines array
		if treeOrLines.root or treeOrLines[1] == nil then
			tree = treeOrLines
		else
			tree = makeFallbackTree(treeOrLines)
		end
	end
	table.insert(registeredNPCs, {
		model = npcModel,
		tree  = tree,
		id    = npcCounter,
	})
	return npcCounter
end

function NPCDialogue.Start(worldSeed)
	local remotes = game:GetService("ReplicatedStorage")

	dialogueEvent = Instance.new("RemoteEvent")
	dialogueEvent.Name   = "NPCDialogueEvent"
	dialogueEvent.Parent = remotes

	choiceEvent = Instance.new("RemoteEvent")
	choiceEvent.Name   = "NPCDialogueChoice"
	choiceEvent.Parent = remotes

	choiceEvent.OnServerEvent:Connect(onChoiceReceived)

	-- Proximity loop
	RunService.Heartbeat:Connect(function()
		for _, npc in ipairs(registeredNPCs) do
			local npcRoot = npc.model:FindFirstChild("HumanoidRootPart")
			if not npcRoot then continue end
			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				if not char then continue end
				local root = char:FindFirstChild("HumanoidRootPart")
				if not root then continue end
				if (root.Position - npcRoot.Position).Magnitude <= TRIGGER_DIST then
					tryTrigger(player, npc, worldSeed)
				end
			end
		end
	end)

	-- Expire stale active dialogues
	task.spawn(function()
		while true do
			task.wait(5)
			local now = os.clock()
			for uid, d in pairs(activeDialogues) do
				if now > d.expireAt then
					activeDialogues[uid] = nil
				end
			end
		end
	end)
end

function NPCDialogue.GetHistory(player, npcId)
	local h = playerHistory[player.UserId]
	if not h then return {} end
	return h[npcId] or {}
end

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
	playerHistory[player.UserId]   = nil
	activeDialogues[player.UserId] = nil
end)

return NPCDialogue
