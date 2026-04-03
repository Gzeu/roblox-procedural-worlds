-- NPCDialogue.lua
-- Procedural NPC dialogue lines based on biome, weather, and quests
-- v2.4.0

local Players     = game:GetService("Players")
local WorldConfig = require(script.Parent.WorldConfig)

local NPCDialogue = {}

-- Dialogue pools per context
local DIALOGUE = {
	greeting = {
		"Traveller, you look weary. Rest a moment.",
		"Ah, a visitor! These lands are full of danger.",
		"Welcome, stranger. Watch your step out there.",
		"You have the eyes of an adventurer.",
		"I haven't seen another soul in days.",
	},
	biome = {
		Forest   = { "These woods whisper at night.", "Wolves roam here after dark.", "The trees remember everything.", "Goblins nest east of the river." },
		Desert   = { "The heat will kill you before the scorpions do.", "Water is worth more than gold here.", "Mummies rise when the sand shifts." },
		Tundra   = { "The cold seeps into your very soul.", "Ice Golems patrol the northern ridges.", "Blizzards come without warning." },
		Swamp    = { "Don't drink the water. Trust me.", "The witches brew something foul tonight.", "Slimes multiply in the mist." },
		Jungle   = { "The jungle is alive — and it watches you.", "Raptors hunt in packs here.", "The shamans speak to old gods." },
		Mountains= { "Trolls block the only pass north.", "Eagles will steal your food.", "The peak hides an ancient dungeon." },
		Plains   = { "Good hunting here if you know where to look.", "The grass hides more than you think.", "Peaceful — for now." },
		Ocean    = { "The Kraken sleeps beneath. Don't wake it.", "Sailors speak of lights below the surface." },
		Savanna  = { "The dry season brings out the beasts.", "Fire spreads fast in the Savanna." },
		Taiga    = { "Pine resin burns bright and long.", "Bears are the least of your worries." },
	},
	weather = {
		Clear       = { "Fine day for an adventure.", "Enjoy the sun while it lasts." },
		Cloudy      = { "Storm's coming. Can feel it in my bones.", "The sky is restless today." },
		Rain        = { "Mud makes it hard to track.", "The river will flood by morning." },
		Thunderstorm= { "Stay away from tall trees!", "Metal armour and lightning — bad idea." },
		Fog         = { "I can't see more than ten paces. Perfect for ambushes.", "Something moves in the fog." },
		Blizzard    = { "We'll freeze if we don't find shelter.", "Only the Ice Golems love this weather." },
	},
	quest = {
		kill    = { "There's a bounty on those creatures, you know.", "Every {mob} you slay keeps us safer." },
		explore = { "I've heard there are places no one has mapped.", "The world is larger than any map." },
		loot    = { "Dungeons hide more treasure than you'd expect.", "Chests don't open themselves." },
		survive = { "Survival is its own reward out here.", "Stay alive long enough and the land respects you." },
		boss    = { "There is a great evil in {biome}. Only a hero can end it.", "Legends are written in blood." },
	},
	goodbye = {
		"May your blade stay sharp.",
		"Don't die out there.",
		"The road is long. Travel safely.",
		"Come back when you have stories to tell.",
		"Fortune favours the bold.",
	},
}

local function pick(pool, seed)
	if not pool or #pool == 0 then return nil end
	local idx = (seed % #pool) + 1
	return pool[idx]
end

local function fillTemplate(line, vars)
	if not line then return "..." end
	for k, v in pairs(vars) do
		line = line:gsub("{" .. k .. "}", tostring(v))
	end
	return line
end

function NPCDialogue.Generate(npcModel, player, context)
	context = context or {}
	local seed    = npcModel:GetAttribute("NPCSeed") or math.random(1, 999999)
	local biome   = context.biome   or "Plains"
	local weather = context.weather or "Clear"
	local quest   = context.quest   -- optional quest table

	local lines = {}

	-- Greeting
	local greeting = pick(DIALOGUE.greeting, seed)
	if greeting then table.insert(lines, greeting) end

	-- Biome line
	local biomePool = DIALOGUE.biome[biome]
	local biomeLine = pick(biomePool, seed + 1)
	if biomeLine then table.insert(lines, biomeLine) end

	-- Weather line
	local weatherPool = DIALOGUE.weather[weather]
	local weatherLine = pick(weatherPool, seed + 2)
	if weatherLine then table.insert(lines, weatherLine) end

	-- Quest hint
	if quest then
		local questPool = DIALOGUE.quest[quest.type]
		local questLine = pick(questPool, seed + 3)
		if questLine then
			questLine = fillTemplate(questLine, { mob = quest.mob or "creature", biome = biome })
			table.insert(lines, questLine)
		end
	end

	-- Goodbye
	local goodbye = pick(DIALOGUE.goodbye, seed + 4)
	if goodbye then table.insert(lines, goodbye) end

	return lines
end

function NPCDialogue.ShowDialogue(player, npcModel, lines)
	if not player or not player.PlayerGui then return end

	-- Remove old dialogue if any
	local existing = player.PlayerGui:FindFirstChild("NPCDialogueGui")
	if existing then existing:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name        = "NPCDialogueGui"
	sg.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Size            = UDim2.new(0.5, 0, 0, 180)
	frame.Position        = UDim2.new(0.25, 0, 0.7, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	frame.BorderSizePixel = 0
	frame.Parent          = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent       = frame

	local npcName = Instance.new("TextLabel")
	npcName.Size            = UDim2.new(1, -16, 0, 28)
	npcName.Position        = UDim2.new(0, 8, 0, 6)
	npcName.BackgroundTransparency = 1
	npcName.TextColor3      = Color3.fromRGB(255, 200, 80)
	npcName.TextSize        = 14
	npcName.Font            = Enum.Font.GothamBold
	npcName.TextXAlignment  = Enum.TextXAlignment.Left
	npcName.Text            = npcModel.Name or "Villager"
	npcName.Parent          = frame

	local dialogueLabel = Instance.new("TextLabel")
	dialogueLabel.Name            = "DialogueText"
	dialogueLabel.Size            = UDim2.new(1, -16, 0, 100)
	dialogueLabel.Position        = UDim2.new(0, 8, 0, 36)
	dialogueLabel.BackgroundTransparency = 1
	dialogueLabel.TextColor3      = Color3.fromRGB(220, 220, 230)
	dialogueLabel.TextSize        = 13
	dialogueLabel.Font            = Enum.Font.Gotham
	dialogueLabel.TextXAlignment  = Enum.TextXAlignment.Left
	dialogueLabel.TextYAlignment  = Enum.TextYAlignment.Top
	dialogueLabel.TextWrapped     = true
	dialogueLabel.Text            = lines[1] or "..."
	dialogueLabel.Parent          = frame

	local nextBtn = Instance.new("TextButton")
	nextBtn.Size            = UDim2.new(0, 100, 0, 28)
	nextBtn.Position        = UDim2.new(1, -108, 1, -34)
	nextBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
	nextBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
	nextBtn.Text            = "Next ▶"
	nextBtn.TextSize        = 12
	nextBtn.Font            = Enum.Font.GothamBold
	nextBtn.Parent          = frame

	local nextCorner = Instance.new("UICorner")
	nextCorner.CornerRadius = UDim.new(0, 6)
	nextCorner.Parent       = nextBtn

	sg.Parent = player.PlayerGui

	local lineIdx = 1
	nextBtn.MouseButton1Click:Connect(function()
		lineIdx = lineIdx + 1
		if lineIdx > #lines then
			sg:Destroy()
		else
			dialogueLabel.Text = lines[lineIdx]
			if lineIdx == #lines then
				nextBtn.Text = "Close ✕"
			end
		end
	end)

	-- Auto-close after 30s
	task.delay(30, function() if sg and sg.Parent then sg:Destroy() end end)
end

function NPCDialogue.Interact(player, npcModel, context)
	local lines = NPCDialogue.Generate(npcModel, player, context)
	NPCDialogue.ShowDialogue(player, npcModel, lines)
end

return NPCDialogue
