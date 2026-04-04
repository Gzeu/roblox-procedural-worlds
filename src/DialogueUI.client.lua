-- DialogueUI.client.lua  (LocalScript → StarterPlayerScripts)
-- Full NPC dialogue box: typewriter effect, choice buttons, Escape to close.
-- Replaces / extends NPCDialogueClient. Listens to NPCDialogueRemote.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("ProceduralWorldsRemotes", 10)
local npcRemote = remotes and remotes:FindFirstChild("NPCDialogueRemote")

-- ─ GUI ───────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name           = "DialogueUI"
sg.ResetOnSpawn   = false
sg.IgnoreGuiInset = false
sg.DisplayOrder   = 30
sg.Parent         = player.PlayerGui

-- Backdrop
local box = Instance.new("Frame", sg)
box.Name                   = "DialogueBox"
box.Size                   = UDim2.new(0, 600, 0, 180)
box.AnchorPoint            = Vector2.new(0.5, 1)
box.Position               = UDim2.new(0.5, 0, 1, -20)
box.BackgroundColor3       = Color3.fromRGB(10, 10, 18)
box.BackgroundTransparency = 0.08
box.BorderSizePixel        = 0
box.Visible                = false
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", box).Color = Color3.fromRGB(80,80,120)

-- NPC portrait
local portrait = Instance.new("Frame", box)
portrait.Size              = UDim2.new(0, 60, 0, 60)
portrait.Position          = UDim2.new(0, 12, 0, 12)
portrait.BackgroundColor3  = Color3.fromRGB(40, 30, 60)
portrait.BorderSizePixel   = 0
Instance.new("UICorner", portrait).CornerRadius = UDim.new(0, 8)

local portraitLabel = Instance.new("TextLabel", portrait)
portraitLabel.Size   = UDim2.new(1,0,1,0)
portraitLabel.BackgroundTransparency = 1
portraitLabel.Text   = "🧙"
portraitLabel.TextSize = 28
portraitLabel.Font   = Enum.Font.GothamBold

-- NPC name
local npcName = Instance.new("TextLabel", box)
npcName.Size          = UDim2.new(0, 300, 0, 22)
npcName.Position      = UDim2.new(0, 82, 0, 12)
npcName.BackgroundTransparency = 1
npcName.Text          = "Elder NPC"
npcName.Font          = Enum.Font.GothamBold
npcName.TextSize      = 15
npcName.TextColor3    = Color3.fromRGB(255,220,100)
npcName.TextXAlignment = Enum.TextXAlignment.Left

-- Dialogue text
local dialogueText = Instance.new("TextLabel", box)
dialogueText.Name   = "DialogueText"
dialogueText.Size   = UDim2.new(0, 490, 0, 70)
dialogueText.Position = UDim2.new(0, 82, 0, 36)
dialogueText.BackgroundTransparency = 1
dialogueText.Text   = ""
dialogueText.Font   = Enum.Font.Gotham
dialogueText.TextSize = 14
dialogueText.TextColor3 = Color3.fromRGB(230,230,230)
dialogueText.TextXAlignment = Enum.TextXAlignment.Left
dialogueText.TextYAlignment = Enum.TextYAlignment.Top
dialogueText.TextWrapped = true

-- Choice list
local choiceList = Instance.new("Frame", box)
choiceList.Name  = "Choices"
choiceList.Size  = UDim2.new(1,-20,0,80)
choiceList.Position = UDim2.new(0,10,0,110)
choiceList.BackgroundTransparency = 1
Instance.new("UIListLayout", choiceList).Padding = UDim.new(0,4)

-- ─ Typewriter ───────────────────────────────────────────────────
local typewriterConn

local function typewrite(text, done)
	if typewriterConn then typewriterConn:Disconnect() end
	dialogueText.Text = ""
	local i = 0
	local chars = string.len(text)
	typewriterConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
		i = i + dt * 40   -- 40 chars/sec
		local shown = math.min(math.floor(i), chars)
		dialogueText.Text = string.sub(text, 1, shown)
		if shown >= chars then
			typewriterConn:Disconnect()
			if done then done() end
		end
	end)
end

-- ─ Show / Hide ─────────────────────────────────────────────────
local function clearChoices()
	for _, c in ipairs(choiceList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
end

local function showDialogue(data)
	-- data: {npcName, portrait?, text, choices=[ {label, questId?, close?} ]}
	clearChoices()
	npcName.Text = data.npcName or "???"
	portraitLabel.Text = data.portrait or "🧙"
	box.Visible = true

	-- Slide in
	box.Position = UDim2.new(0.5, 0, 1, 60)
	TweenService:Create(box,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 1, -20)}
	):Play()

	typewrite(data.text or "", function()
		-- Show choice buttons after typewriter finishes
		for i, choice in ipairs(data.choices or {}) do
			local btn = Instance.new("TextButton", choiceList)
			btn.Size              = UDim2.new(1, 0, 0, 26)
			btn.BackgroundColor3  = Color3.fromRGB(30, 30, 50)
			btn.BackgroundTransparency = 0.2
			btn.BorderSizePixel   = 0
			btn.Text              = (i .. ". ") .. choice.label
			btn.Font              = Enum.Font.Gotham
			btn.TextSize          = 13
			btn.TextColor3        = Color3.new(1,1,1)
			btn.TextXAlignment    = Enum.TextXAlignment.Left
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
			local pad = Instance.new("UIPadding", btn)
			pad.PaddingLeft = UDim.new(0,10)

			btn.MouseEnter:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.1),
					{BackgroundColor3=Color3.fromRGB(50,50,80)}):Play()
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.1),
					{BackgroundColor3=Color3.fromRGB(30,30,50)}):Play()
			end)

			local choiceData = choice
			btn.MouseButton1Click:Connect(function()
				if npcRemote then
					npcRemote:FireServer("choice", choiceData)
				end
				if choiceData.close then
					hideDialogue()
				end
			end)
		end
	end)
end

function hideDialogue()
	clearChoices()
	if typewriterConn then typewriterConn:Disconnect() end
	TweenService:Create(box,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, 0, 1, 60)}
	).Completed:Connect(function() box.Visible = false end)
	TweenService:Create(box,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, 0, 1, 60)}
	):Play()
end

-- Escape key
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Escape and box.Visible then
		hideDialogue()
	end
end)

-- Listen to server
if npcRemote then
	npcRemote.OnClientEvent:Connect(function(action, data)
		if action == "show" then showDialogue(data)
		elseif action == "hide" then hideDialogue()
		end
	end)
end
