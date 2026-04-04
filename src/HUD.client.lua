-- HUD.client.lua  (LocalScript → StarterPlayerScripts)
-- Complete heads-up display: HP, Stamina, XP, Level, Gold, Awaken energy, Clan badge, Fighting style
-- v7.0 | roblox-procedural-worlds

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player   = Players.LocalPlayer
local remotes  = ReplicatedStorage:WaitForChild("ProceduralWorldsRemotes", 10)

-- ─ helpers ─────────────────────────────────────────────────────
local function frame(parent, name, bg, size, pos)
	local f = Instance.new("Frame")
	f.Name            = name
	f.BackgroundColor3 = bg or Color3.new(0,0,0)
	f.BackgroundTransparency = bg and 0 or 0.5
	f.BorderSizePixel = 0
	f.Size            = size or UDim2.new(1, 0, 1, 0)
	f.Position        = pos or UDim2.new(0, 0, 0, 0)
	f.Parent          = parent
	return f
end

local function label(parent, text, size, color, pos, anchor)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text        = text
	l.TextColor3  = color or Color3.new(1,1,1)
	l.TextSize    = size or 14
	l.Font        = Enum.Font.GothamBold
	l.Size        = UDim2.new(1, 0, 0, size and size + 4 or 18)
	l.Position    = pos or UDim2.new(0, 0, 0, 0)
	l.AnchorPoint = anchor or Vector2.new(0, 0)
	l.Parent      = parent
	return l
end

local function bar(parent, name, fillColor)
	local bg = frame(parent, name .. "BG",
		Color3.fromRGB(20,20,20),
		UDim2.new(0, 180, 0, 14),
		UDim2.new(0, 0, 0, 0))
	bg.BackgroundTransparency = 0.4
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)

	local fill = frame(bg, name .. "Fill", fillColor,
		UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
	return bg, fill
end

local function tweenFill(fill, pct)
	TweenService:Create(fill,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)}
	):Play()
end

-- ─ ScreenGui ──────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name             = "HUD"
sg.ResetOnSpawn     = false
sg.IgnoreGuiInset   = false
sg.DisplayOrder     = 5
sg.Parent           = player.PlayerGui

-- ─ Bottom-left panel: HP / Stamina / XP ───────────────────────
local statsPanel = frame(sg, "StatsPanel",
	Color3.fromRGB(10,10,10),
	UDim2.new(0, 200, 0, 110),
	UDim2.new(0, 12, 1, -122))
statsPanel.BackgroundTransparency = 0.35
Instance.new("UICorner", statsPanel).CornerRadius = UDim.new(0, 8)

-- HP
local hpLabel = label(statsPanel, "♥ HP", 12, Color3.fromRGB(255,100,100), UDim2.new(0,8,0,6))
_, hpFill = bar(frame(statsPanel, "HP", nil, UDim2.new(0,184,0,14), UDim2.new(0,8,0,22)), "HP", Color3.fromRGB(220,50,50))

-- Stamina
label(statsPanel, "⚡ STAMINA", 12, Color3.fromRGB(255,230,80), UDim2.new(0,8,0,40))
_, staminaFill = bar(frame(statsPanel, "Stamina", nil, UDim2.new(0,184,0,14), UDim2.new(0,8,0,56)), "Stamina", Color3.fromRGB(230,210,40))

-- XP
label(statsPanel, "★ XP", 12, Color3.fromRGB(100,180,255), UDim2.new(0,8,0,74))
_, xpFill = bar(frame(statsPanel, "XP", nil, UDim2.new(0,184,0,14), UDim2.new(0,8,0,90)), "XP", Color3.fromRGB(50,150,255))

-- ─ Top-right: Level + Gold ─────────────────────────────────────
local infoPanel = frame(sg, "InfoPanel",
	Color3.fromRGB(10,10,10),
	UDim2.new(0, 150, 0, 52),
	UDim2.new(1, -162, 0, 10))
infoPanel.BackgroundTransparency = 0.35
Instance.new("UICorner", infoPanel).CornerRadius = UDim.new(0, 8)

local levelLabel = label(infoPanel, "Lv.1",  18, Color3.fromRGB(255,220,100), UDim2.new(0,10,0,4))
local goldLabel  = label(infoPanel, "💰 0",    14, Color3.fromRGB(255,200,50),  UDim2.new(0,10,0,26))

-- ─ Bottom-left (below stats): Clan badge + Fighting Style ─────────
local clanPanel = frame(sg, "ClanPanel",
	Color3.fromRGB(30,15,40),
	UDim2.new(0, 200, 0, 44),
	UDim2.new(0, 12, 1, -64))
clanPanel.BackgroundTransparency = 0.35
Instance.new("UICorner", clanPanel).CornerRadius = UDim.new(0, 8)
local clanLabel  = label(clanPanel, "🎯 Clan: --",      12, Color3.fromRGB(220,180,255), UDim2.new(0,8,0,4))
local styleLabel = label(clanPanel, "⚔️ Style: Warrior", 12, Color3.fromRGB(200,200,255), UDim2.new(0,8,0,22))

-- ─ Awaken energy bar (bottom-center, purple) ───────────────────
local awakenPanel = frame(sg, "AwakenPanel",
	Color3.fromRGB(15,5,30),
	UDim2.new(0, 220, 0, 34),
	UDim2.new(0.5, -110, 1, -42))
awakenPanel.BackgroundTransparency = 0.35
Instance.new("UICorner", awakenPanel).CornerRadius = UDim.new(0, 8)
label(awakenPanel, "⚡ AWAKEN", 11, Color3.fromRGB(200,150,255), UDim2.new(0,8,0,2))
local _, awakenFill = bar(frame(awakenPanel, "AW", nil, UDim2.new(0,200,0,12), UDim2.new(0,10,0,18)), "Awaken", Color3.fromRGB(160,80,255))

-- glow effect when awaken is full
local awakenGlow = Instance.new("UIStroke", awakenPanel)
awakenGlow.Color     = Color3.fromRGB(180,100,255)
awakenGlow.Thickness = 0

-- ─ Polling loop ───────────────────────────────────────────────────
local HP_MAX      = 100
local XP_MAX      = 100
local STAMINA_MAX = 100
local AWAKEN_MAX  = 200

RunService.Heartbeat:Connect(function()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	-- HP
	local maxHp = hum.MaxHealth
	if maxHp > 0 then
		local pct = hum.Health / maxHp
		tweenFill(hpFill, pct)
		hpLabel.Text = string.format("♥ HP  %d / %d", math.floor(hum.Health), math.floor(maxHp))
	end

	-- Stamina (attribute on character)
	local stamina = char:GetAttribute("Stamina") or STAMINA_MAX
	tweenFill(staminaFill, stamina / STAMINA_MAX)

	-- XP
	local xp    = player:GetAttribute("XP")       or 0
	local level = player:GetAttribute("Level")    or 1
	local xpMax = player:GetAttribute("XPToNext") or XP_MAX
	tweenFill(xpFill, xp / xpMax)
	levelLabel.Text = "Lv." .. level

	-- Gold
	local gold = player:GetAttribute("Gold") or 0
	goldLabel.Text = "💰 " .. gold

	-- Clan / style
	local clan  = player:GetAttribute("Clan")          or "--"
	local style = player:GetAttribute("FightingStyle")  or "Warrior"
	clanLabel.Text  = "🎯 Clan: " .. clan
	styleLabel.Text = "⚔️ " .. style

	-- Awaken energy
	local energy = player:GetAttribute("AwakenEnergy") or 0
	local pctA   = energy / AWAKEN_MAX
	tweenFill(awakenFill, pctA)
	if pctA >= 1 then
		TweenService:Create(awakenGlow,
			TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Thickness = 3}
		):Play()
	else
		awakenGlow.Thickness = 0
	end
end)

-- ─ RemoteEvent hooks (level-up, quest, boss) ──────────────────
if remotes then
	local lvlRemote = remotes:FindFirstChild("LevelUpRemote")
	if lvlRemote then
		lvlRemote.OnClientEvent:Connect(function(newLevel)
			levelLabel.Text = "Lv." .. newLevel
			-- Flash gold border
			local stroke = Instance.new("UIStroke", infoPanel)
			stroke.Color     = Color3.fromRGB(255,220,50)
			stroke.Thickness = 2
			task.delay(1.5, function() stroke:Destroy() end)
		end)
	end
end
