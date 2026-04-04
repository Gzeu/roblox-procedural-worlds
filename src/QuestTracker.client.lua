-- QuestTracker.client.lua  (LocalScript → StarterPlayerScripts)
-- Shows up to 3 active quests on the right side of screen with progress bars
-- Animates in/out. Listens to QuestCompleteRemote.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("ProceduralWorldsRemotes", 10)

-- ─ Gui ─────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name           = "QuestTracker"
sg.ResetOnSpawn   = false
sg.IgnoreGuiInset = false
sg.DisplayOrder   = 6
sg.Parent         = player.PlayerGui

local listFrame = Instance.new("Frame")
listFrame.Name                    = "QuestList"
listFrame.BackgroundTransparency  = 1
listFrame.Size                    = UDim2.new(0, 230, 0, 260)
listFrame.Position                = UDim2.new(1, -242, 0.5, -130)
listFrame.AnchorPoint             = Vector2.new(0, 0)
listFrame.Parent                  = sg

local layout = Instance.new("UIListLayout", listFrame)
layout.Padding         = UDim.new(0, 8)
layout.SortOrder       = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right

-- ─ Active quests table ───────────────────────────────────────────
local activeQuests = {}   -- {id, cardFrame, fillFrame}

local RARITY_COLORS = {
	Common   = Color3.fromRGB(200, 200, 200),
	Rare     = Color3.fromRGB(100, 160, 255),
	Epic     = Color3.fromRGB(180, 80,  255),
	Legendary= Color3.fromRGB(255, 200, 50),
}

local function makeQuestCard(questId, title, progress, target, rewardTier)
	local card = Instance.new("Frame")
	card.Name                    = "Quest_" .. questId
	card.Size                    = UDim2.new(0, 226, 0, 68)
	card.BackgroundColor3        = Color3.fromRGB(12, 12, 18)
	card.BackgroundTransparency  = 0.2
	card.BorderSizePixel         = 0
	card.AnchorPoint             = Vector2.new(1, 0)
	card.Position                = UDim2.new(1, 30, 0, 0)   -- starts off screen right
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	-- Rarity accent left strip
	local strip = Instance.new("Frame", card)
	strip.Size             = UDim2.new(0, 3, 1, 0)
	strip.BorderSizePixel  = 0
	strip.BackgroundColor3 = RARITY_COLORS[rewardTier] or RARITY_COLORS.Common
	Instance.new("UICorner", strip).CornerRadius = UDim.new(0, 4)

	-- Title
	local t = Instance.new("TextLabel", card)
	t.BackgroundTransparency = 1
	t.Text      = "📌 " .. title
	t.TextColor3 = Color3.new(1,1,1)
	t.TextSize  = 13
	t.Font      = Enum.Font.GothamBold
	t.Size      = UDim2.new(1, -12, 0, 18)
	t.Position  = UDim2.new(0, 10, 0, 6)
	t.TextXAlignment = Enum.TextXAlignment.Left

	-- Progress text
	local pText = Instance.new("TextLabel", card)
	pText.Name  = "ProgressText"
	pText.BackgroundTransparency = 1
	pText.Text  = progress .. " / " .. target
	pText.TextColor3 = Color3.fromRGB(180,180,180)
	pText.TextSize = 11
	pText.Font = Enum.Font.Gotham
	pText.Size = UDim2.new(1,-12,0,14)
	pText.Position = UDim2.new(0,10,0,24)
	pText.TextXAlignment = Enum.TextXAlignment.Left

	-- Progress bar bg
	local barBg = Instance.new("Frame", card)
	barBg.Size = UDim2.new(1,-20,0,8)
	barBg.Position = UDim2.new(0,10,0,44)
	barBg.BackgroundColor3 = Color3.fromRGB(30,30,30)
	barBg.BorderSizePixel = 0
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0,4)

	local fill = Instance.new("Frame", barBg)
	fill.Name = "Fill"
	fill.Size = UDim2.new(math.clamp(progress/math.max(target,1),0,1), 0, 1, 0)
	fill.BackgroundColor3 = RARITY_COLORS[rewardTier] or Color3.fromRGB(80,200,80)
	fill.BorderSizePixel = 0
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0,4)

	card.Parent = listFrame

	-- Slide in animation
	task.delay(0.05, function()
		TweenService:Create(card,
			TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Position = UDim2.new(1, 0, 0, 0)}
		):Play()
	end)

	return card, fill, pText
end

local function removeQuestCard(questId)
	for i, q in ipairs(activeQuests) do
		if q.id == questId then
			local card = q.card
			local tween = TweenService:Create(card,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(1, 30, 0, card.Position.Y.Offset)}
			)
			tween:Play()
			tween.Completed:Connect(function() card:Destroy() end)
			table.remove(activeQuests, i)
			break
		end
	end
end

-- ─ Demo quests (populated from server attributes or RemoteEvents) ────
-- Server should fire QuestCompleteRemote {action="add"|"update"|"remove", ...}

local function handleQuestUpdate(data)
	if data.action == "add" then
		local card, fill, pText = makeQuestCard(
			data.id, data.title, data.progress or 0, data.target or 1, data.rewardTier or "Common"
		)
		table.insert(activeQuests, {id=data.id, card=card, fill=fill, pText=pText})

	elseif data.action == "update" then
		for _, q in ipairs(activeQuests) do
			if q.id == data.id then
				local pct = (data.progress or 0) / math.max(data.target or 1, 1)
				TweenService:Create(q.fill,
					TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Size = UDim2.new(pct, 0, 1, 0)}
				):Play()
				q.pText.Text = (data.progress or 0) .. " / " .. (data.target or 1)
			end
		end

	elseif data.action == "remove" then
		removeQuestCard(data.id)
	end
end

-- Listen to server
if remotes then
	local qr = remotes:FindFirstChild("QuestCompleteRemote")
	if qr then
		qr.OnClientEvent:Connect(function(data) handleQuestUpdate(data) end)
	end
end

-- Seed a demo quest so the tracker isn\'t empty on first spawn
task.delay(2, function()
	handleQuestUpdate({action="add", id="demo_1", title="Slay 10 Goblins",
		progress=3, target=10, rewardTier="Common"})
	handleQuestUpdate({action="add", id="demo_2", title="Explore 5 Chunks",
		progress=1, target=5, rewardTier="Rare"})
end)
