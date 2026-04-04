-- MinimapUI.client.lua  (LocalScript → StarterPlayerScripts)
-- Circular minimap bottom-right. Player (white), mobs (red), NPCs (yellow), dungeons (purple).
-- Updates every 0.5s.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")

local player   = Players.LocalPlayer
local MAP_SIZE = 140   -- pixels
local MAP_RANGE = 120  -- studs rendered radius

-- ─ GUI ───────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name           = "MinimapUI"
sg.ResetOnSpawn   = false
sg.IgnoreGuiInset = false
sg.DisplayOrder   = 4
sg.Parent         = player.PlayerGui

-- Circular clip frame
local container = Instance.new("Frame", sg)
container.Name                   = "MapContainer"
container.Size                   = UDim2.new(0, MAP_SIZE, 0, MAP_SIZE)
container.AnchorPoint            = Vector2.new(1, 1)
container.Position               = UDim2.new(1, -12, 1, -12)
container.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
container.BackgroundTransparency = 0.35
container.BorderSizePixel        = 0
Instance.new("UICorner", container).CornerRadius = UDim.new(0.5, 0)  -- full circle

-- Border ring
local stroke = Instance.new("UIStroke", container)
stroke.Color     = Color3.fromRGB(100,100,130)
stroke.Thickness = 2

-- "MAP" label
local mapLabel = Instance.new("TextLabel", container)
mapLabel.BackgroundTransparency = 1
mapLabel.Size     = UDim2.new(1,0,0,14)
mapLabel.Position = UDim2.new(0,0,0,4)
mapLabel.Text     = "MAP"
mapLabel.TextSize = 10
mapLabel.Font     = Enum.Font.GothamBold
mapLabel.TextColor3 = Color3.fromRGB(180,180,200)

-- Player dot
local playerDot = Instance.new("Frame", container)
playerDot.Name   = "PlayerDot"
playerDot.Size   = UDim2.new(0, 8, 0, 8)
playerDot.AnchorPoint = Vector2.new(0.5, 0.5)
playerDot.Position    = UDim2.new(0.5, 0, 0.5, 0)
playerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
playerDot.BorderSizePixel  = 0
Instance.new("UICorner", playerDot).CornerRadius = UDim.new(0.5, 0)

-- Pool of entity dots
local DOT_POOL_SIZE = 40
local dotPool = {}
for _ = 1, DOT_POOL_SIZE do
	local d = Instance.new("Frame", container)
	d.Size = UDim2.new(0,6,0,6)
	d.AnchorPoint = Vector2.new(0.5,0.5)
	d.Position    = UDim2.new(2, 0, 2, 0)  -- off-map
	d.BackgroundColor3 = Color3.new(1,0,0)
	d.BorderSizePixel  = 0
	d.Visible = false
	Instance.new("UICorner", d).CornerRadius = UDim.new(0.5,0)
	table.insert(dotPool, d)
end

local function getDot(idx)
	return dotPool[idx]
end

-- ─ Update loop ──────────────────────────────────────────────────
local lastUpdate = 0

RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastUpdate < 0.5 then return end
	lastUpdate = now

	local char    = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local pPos = hrp.Position
	local dotIdx = 0

	local function placeDot(worldPos, color)
		dotIdx = dotIdx + 1
		if dotIdx > DOT_POOL_SIZE then return end
		local d = getDot(dotIdx)
		local dx = worldPos.X - pPos.X
		local dz = worldPos.Z - pPos.Z
		local nx = math.clamp(dx / MAP_RANGE, -0.95, 0.95)
		local nz = math.clamp(dz / MAP_RANGE, -0.95, 0.95)
		if math.sqrt(nx*nx + nz*nz) > 0.95 then
			d.Visible = false
			return
		end
		d.Position = UDim2.new(0.5 + nx*0.45, 0, 0.5 + nz*0.45, 0)
		d.BackgroundColor3 = color
		d.Visible = true
	end

	-- Hide all dots first
	for _, d in ipairs(dotPool) do d.Visible = false end
	dotIdx = 0

	-- Scan workspace for tagged entities
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and obj ~= char then
			local root = obj:FindFirstChild("HumanoidRootPart")
			if root then
				local tag = obj:GetAttribute("MapTag")
				local color
				if tag == "Mob"  then color = Color3.fromRGB(255,80,80)
				elseif tag == "NPC" then color = Color3.fromRGB(255,230,80)
				elseif tag == "Dungeon" then color = Color3.fromRGB(180,80,255)
				else color = Color3.fromRGB(100,200,100) end
				placeDot(root.Position, color)
			end
		end
	end
end)
