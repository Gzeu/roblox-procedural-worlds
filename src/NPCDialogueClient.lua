-- NPCDialogueClient.lua (StarterPlayerScripts)
-- Receives dialogue events and renders billboard GUI above NPC
-- v2.5.0

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local function createBillboard(npcModel, text)
	-- Remove existing billboard
	local existing = npcModel:FindFirstChild("DialogueBillboard")
	if existing then existing:Destroy() end

	local bb = Instance.new("BillboardGui")
	bb.Name          = "DialogueBillboard"
	bb.Size          = UDim2.new(0, 200, 0, 60)
	bb.StudsOffset   = Vector3.new(0, 5, 0)
	bb.AlwaysOnTop   = false
	bb.MaxDistance   = 30
	bb.Parent        = npcModel

	local bg = Instance.new("Frame")
	bg.Size             = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	bg.BackgroundTransparency = 0.2
	bg.BorderSizePixel  = 0
	bg.Parent           = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent       = bg

	local label = Instance.new("TextLabel")
	label.Size            = UDim2.new(1, -12, 1, -8)
	label.Position        = UDim2.new(0, 6, 0, 4)
	label.BackgroundTransparency = 1
	label.TextColor3      = Color3.fromRGB(240, 240, 220)
	label.Text            = text
	label.TextSize        = 13
	label.Font            = Enum.Font.GothamMedium
	label.TextWrapped     = true
	label.TextXAlignment  = Enum.TextXAlignment.Left
	label.Parent          = bg

	-- Auto-remove after 6 seconds
	task.delay(6, function()
		if bb and bb.Parent then bb:Destroy() end
	end)
end

-- Wait for RemoteEvent
task.spawn(function()
	local event = ReplicatedStorage:WaitForChild("NPCDialogueEvent", 10)
	if not event then return end

	event.OnClientEvent:Connect(function(npcName, line)
		-- Find NPC model in workspace
		local npcModel = workspace:FindFirstChild(npcName)
		if not npcModel then
			-- Search villages
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj.Name == npcName and obj:IsA("Model") then
					npcModel = obj
					break
				end
			end
		end
		if npcModel then
			createDialogue(npcModel, line)
		end
	end)
end)
