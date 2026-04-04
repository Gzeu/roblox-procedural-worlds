-- InventoryUI.client.lua  (LocalScript → StarterPlayerScripts)
-- 4x5 slot grid inventory. Toggle with B key. Right-click context menu.
-- Connects to InventoryRemote RemoteFunction on server for slot data.

local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("ProceduralWorldsRemotes", 10)
local invRemote = remotes and remotes:FindFirstChild("InventoryRemote")

local COLS, ROWS = 4, 5
local SLOT_SIZE  = 52
local SLOT_PAD   = 6
local PANEL_W    = COLS * (SLOT_SIZE + SLOT_PAD) + SLOT_PAD + 16
local PANEL_H    = ROWS * (SLOT_SIZE + SLOT_PAD) + SLOT_PAD + 54

-- ─ ScreenGui ─────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name           = "InventoryUI"
sg.ResetOnSpawn   = false
sg.DisplayOrder   = 20
sg.IgnoreGuiInset = false
sg.Parent         = player.PlayerGui

-- Main panel
local panel = Instance.new("Frame", sg)
panel.Name                    = "Panel"
panel.Size                    = UDim2.new(0, PANEL_W, 0, PANEL_H)
panel.AnchorPoint             = Vector2.new(0.5, 0.5)
panel.Position                = UDim2.new(0.5, 0, 0.5, 0)
panel.BackgroundColor3        = Color3.fromRGB(14, 14, 20)
panel.BackgroundTransparency  = 0.05
panel.BorderSizePixel         = 0
panel.Visible                 = false
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

-- Title bar
local title = Instance.new("TextLabel", panel)
title.Size          = UDim2.new(1, 0, 0, 36)
title.BackgroundColor3 = Color3.fromRGB(20,20,30)
title.BackgroundTransparency = 0
title.BorderSizePixel = 0
title.Text          = "🎒  INVENTORY"
title.TextColor3    = Color3.new(1,1,1)
title.Font          = Enum.Font.GothamBold
title.TextSize      = 15
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

-- Close btn
local closeBtn = Instance.new("TextButton", panel)
closeBtn.Size     = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 4)
closeBtn.Text     = "X"
closeBtn.Font     = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.TextColor3 = Color3.new(1,0.4,0.4)
closeBtn.BackgroundColor3 = Color3.fromRGB(40,10,10)
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Slot grid
local slots = {}
for row = 1, ROWS do
	for col = 1, COLS do
		local idx = (row-1)*COLS + col
		local slot = Instance.new("Frame", panel)
		slot.Name  = "Slot" .. idx
		slot.Size  = UDim2.new(0, SLOT_SIZE, 0, SLOT_SIZE)
		slot.Position = UDim2.new(0, 8 + (col-1)*(SLOT_SIZE+SLOT_PAD),
			                            0, 42 + (row-1)*(SLOT_SIZE+SLOT_PAD))
		slot.BackgroundColor3 = Color3.fromRGB(25,25,35)
		slot.BackgroundTransparency = 0.2
		slot.BorderSizePixel = 0
		Instance.new("UICorner", slot).CornerRadius = UDim.new(0,6)

		-- Icon placeholder
		local icon = Instance.new("Frame", slot)
		icon.Name = "Icon"
		icon.Size = UDim2.new(0,32,0,32)
		icon.AnchorPoint = Vector2.new(0.5,0.5)
		icon.Position = UDim2.new(0.5,0,0.45,0)
		icon.BackgroundColor3 = Color3.fromRGB(40,40,55)
		icon.BorderSizePixel = 0
		Instance.new("UICorner", icon).CornerRadius = UDim.new(0,4)

		-- Quantity label
		local qty = Instance.new("TextLabel", slot)
		qty.Name  = "Qty"
		qty.Size  = UDim2.new(1,-4,0,14)
		qty.Position = UDim2.new(0,2,1,-16)
		qty.BackgroundTransparency = 1
		qty.Text  = ""
		qty.TextSize = 11
		qty.Font  = Enum.Font.GothamBold
		qty.TextColor3 = Color3.fromRGB(200,255,200)
		qty.TextXAlignment = Enum.TextXAlignment.Right

		-- Item name tooltip label (small)
		local nameL = Instance.new("TextLabel", slot)
		nameL.Name = "ItemName"
		nameL.Size = UDim2.new(1,-2,0,13)
		nameL.Position = UDim2.new(0,1,0,2)
		nameL.BackgroundTransparency = 1
		nameL.Text = ""
		nameL.TextSize = 10
		nameL.Font = Enum.Font.Gotham
		nameL.TextColor3 = Color3.fromRGB(180,180,180)
		nameL.TextXAlignment = Enum.TextXAlignment.Left

		slots[idx] = {frame=slot, icon=icon, qty=qty, nameL=nameL, item=nil}
	end
end

-- ─ Context menu ──────────────────────────────────────────────────
local contextMenu = Instance.new("Frame", sg)
contextMenu.Name                    = "ContextMenu"
contextMenu.Size                    = UDim2.new(0, 120, 0, 96)
contextMenu.BackgroundColor3        = Color3.fromRGB(18,18,26)
contextMenu.BackgroundTransparency  = 0
contextMenu.BorderSizePixel         = 0
contextMenu.Visible                 = false
contextMenu.ZIndex                  = 50
Instance.new("UICorner", contextMenu).CornerRadius = UDim.new(0,8)

local ctxActions = {"Use", "Equip", "Drop"}
local ctxCallbacks = {}

for i, action in ipairs(ctxActions) do
	local btn = Instance.new("TextButton", contextMenu)
	btn.Size     = UDim2.new(1,-8,0,26)
	btn.Position = UDim2.new(0,4,0,(i-1)*30+4)
	btn.Text     = action
	btn.Font     = Enum.Font.Gotham
	btn.TextSize = 13
	btn.TextColor3 = Color3.new(1,1,1)
	btn.BackgroundColor3 = Color3.fromRGB(30,30,42)
	btn.BorderSizePixel = 0
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
	btn.MouseButton1Click:Connect(function()
		if ctxCallbacks[action] then ctxCallbacks[action]() end
		contextMenu.Visible = false
	end)
end

-- ─ Populate slots from server ────────────────────────────────────
local function populateSlots(inventoryData)
	-- inventoryData: array of {name, quantity, color}
	for i, s in ipairs(slots) do
		local item = inventoryData and inventoryData[i]
		if item then
			s.item = item
			s.icon.BackgroundColor3 = item.color or Color3.fromRGB(80,120,80)
			s.qty.Text   = item.quantity > 1 and ("x"..item.quantity) or ""
			s.nameL.Text = item.name
		else
			s.item = nil
			s.icon.BackgroundColor3 = Color3.fromRGB(40,40,55)
			s.qty.Text   = ""
			s.nameL.Text = ""
		end
	end
end

local function openInventory()
	if invRemote then
		local ok, data = pcall(function() return invRemote:InvokeServer("getSlots") end)
		if ok and data then populateSlots(data) end
	else
		-- Fallback demo data
		populateSlots({
			{name="Iron Sword", quantity=1,  color=Color3.fromRGB(140,140,160)},
			{name="Health Potion", quantity=5, color=Color3.fromRGB(200,60,60)},
			{name="Wood",         quantity=24, color=Color3.fromRGB(140,90,40)},
			{name="Gold Ore",     quantity=3,  color=Color3.fromRGB(220,180,50)},
		})
	end
end

-- Right-click on slot
for idx, s in ipairs(slots) do
	s.frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 and s.item then
			local mx = input.Position.X
			local my = input.Position.Y
			contextMenu.Position = UDim2.new(0, mx, 0, my)
			contextMenu.Visible  = true
			ctxCallbacks["Use"]   = function() print("Use", s.item.name) end
			ctxCallbacks["Equip"] = function() print("Equip", s.item.name) end
			ctxCallbacks["Drop"]  = function()
				if invRemote then invRemote:InvokeServer("drop", idx) end
				s.item = nil
				s.icon.BackgroundColor3 = Color3.fromRGB(40,40,55)
				s.qty.Text = ""
				s.nameL.Text = ""
			end
		end
	end)
end

-- ─ Toggle open/close ───────────────────────────────────────────────
local isOpen = false

local function toggleInv(open)
	isOpen = open
	panel.Visible = open
	contextMenu.Visible = false
	if open then openInventory() end
end

closeBtn.MouseButton1Click:Connect(function() toggleInv(false) end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.B then
		toggleInv(not isOpen)
	end
	if input.KeyCode == Enum.KeyCode.Escape then
		if contextMenu.Visible then
			contextMenu.Visible = false
		elseif isOpen then
			toggleInv(false)
		end
	end
end)
