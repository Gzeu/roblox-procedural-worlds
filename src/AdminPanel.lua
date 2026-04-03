-- AdminPanel.lua
-- Server-side admin panel: biome debug, seed info, mob count, chunk stats
-- Only accessible to players in WorldConfig.AdminUserIds
-- v2.3.0

local Players       = game:GetService("Players")
local WorldConfig   = require(script.Parent.WorldConfig)
local BiomeResolver = require(script.Parent.BiomeResolver)

local AdminPanel = {}

local worldGen   = nil  -- set via AdminPanel.Init(worldGeneratorRef)
local mobSpawner = nil

local function isAdmin(player)
	local admins = WorldConfig.AdminUserIds or {}
	for _, id in ipairs(admins) do
		if player.UserId == id then return true end
	end
	-- In Studio, treat all players as admin for convenience
	return game:GetService("RunService"):IsStudio()
end

local function buildAdminGui(player)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name        = "AdminPanel"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Toggle button
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size            = UDim2.new(0, 120, 0, 30)
	toggleBtn.Position        = UDim2.new(1, -130, 0, 10)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	toggleBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
	toggleBtn.Text            = "🛠 Admin Panel"
	toggleBtn.TextSize        = 13
	toggleBtn.Font            = Enum.Font.GothamBold
	toggleBtn.Parent          = screenGui

	-- Main frame
	local frame = Instance.new("Frame")
	frame.Size            = UDim2.new(0, 320, 0, 420)
	frame.Position        = UDim2.new(1, -340, 0, 50)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
	frame.BorderSizePixel = 0
	frame.Visible         = false
	frame.Name            = "MainFrame"
	frame.Parent          = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent       = frame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size            = UDim2.new(1, 0, 0, 36)
	title.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	title.TextColor3      = Color3.fromRGB(100, 200, 255)
	title.Text            = "🌍 Procedural Worlds — Admin"
	title.TextSize        = 14
	title.Font            = Enum.Font.GothamBold
	title.BorderSizePixel = 0
	title.Parent          = frame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent       = title

	-- Stats label
	local stats = Instance.new("TextLabel")
	stats.Name            = "Stats"
	stats.Size            = UDim2.new(1, -16, 0, 260)
	stats.Position        = UDim2.new(0, 8, 0, 44)
	stats.BackgroundTransparency = 1
	stats.TextColor3      = Color3.fromRGB(200, 200, 220)
	stats.TextSize        = 12
	stats.Font            = Enum.Font.Code
	stats.TextXAlignment  = Enum.TextXAlignment.Left
	stats.TextYAlignment  = Enum.TextYAlignment.Top
	stats.TextWrapped     = true
	stats.Text            = "Loading..."
	stats.Parent          = frame

	-- Regen seed button
	local regenBtn = Instance.new("TextButton")
	regenBtn.Size            = UDim2.new(1, -16, 0, 32)
	regenBtn.Position        = UDim2.new(0, 8, 0, 312)
	regenBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
	regenBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
	regenBtn.Text            = "🎲 New Random Seed"
	regenBtn.TextSize        = 13
	regenBtn.Font            = Enum.Font.GothamBold
	regenBtn.Name            = "RegenBtn"
	regenBtn.Parent          = frame

	local regenCorner = Instance.new("UICorner")
	regenCorner.CornerRadius = UDim.new(0, 6)
	regenCorner.Parent       = regenBtn

	-- Clear mobs button
	local clearBtn = Instance.new("TextButton")
	clearBtn.Size            = UDim2.new(1, -16, 0, 32)
	clearBtn.Position        = UDim2.new(0, 8, 0, 352)
	clearBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	clearBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
	clearBtn.Text            = "💀 Clear All Mobs"
	clearBtn.TextSize        = 13
	clearBtn.Font            = Enum.Font.GothamBold
	clearBtn.Name            = "ClearBtn"
	clearBtn.Parent          = frame

	local clearCorner = Instance.new("UICorner")
	clearCorner.CornerRadius = UDim.new(0, 6)
	clearCorner.Parent       = clearBtn

	-- Toggle visibility
	toggleBtn.MouseButton1Click:Connect(function()
		frame.Visible = not frame.Visible
	end)

	-- Update stats loop
	task.spawn(function()
		while screenGui.Parent do
			if frame.Visible then
				local seed    = worldGen and worldGen.GetSeed() or 0
				local char    = player.Character
				local pos     = char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.Position or Vector3.zero
				local biome   = BiomeResolver.GetBiomeAt(pos.X, pos.Z, seed)
				local mobCount = 0
				if mobSpawner then
					for _ in pairs(mobSpawner.GetActive()) do mobCount += 1 end
				end
				local chunkX  = math.floor(pos.X / WorldConfig.ChunkSize)
				local chunkZ  = math.floor(pos.Z / WorldConfig.ChunkSize)

				stats.Text = table.concat({
					"Seed:       " .. seed,
					"Position:   " .. string.format("(%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z),
					"Chunk:      [" .. chunkX .. ", " .. chunkZ .. "]",
					"Biome:      " .. biome,
					"Mobs Active:" .. mobCount,
					"Render Dist:" .. WorldConfig.RenderDistance .. " chunks",
					"Chunk Size: " .. WorldConfig.ChunkSize .. " studs",
					"Mob Cap:    " .. (WorldConfig.MobSpawnCap or 10) .. " per player",
					"Weather:    " .. tostring(WorldConfig.WeatherCycle) .. "s cycle",
					"",
					"Players:    " .. #Players:GetPlayers(),
				}, "\n")
			end
			task.wait(0.5)
		end
	end)

	-- Regen seed
	regenBtn.MouseButton1Click:Connect(function()
		if worldGen then
			local newSeed = math.random(1, 2^31 - 1)
			worldGen.SetSeed(newSeed)
			warn("[AdminPanel] Seed changed to:", newSeed, "by", player.Name)
		end
	end)

	-- Clear mobs
	clearBtn.MouseButton1Click:Connect(function()
		local cleared = 0
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:GetAttribute("MobType") then
				obj:Destroy()
				cleared += 1
			end
		end
		warn("[AdminPanel] Cleared", cleared, "mobs by", player.Name)
	end)

	screenGui.Parent = player.PlayerGui
end

function AdminPanel.Init(worldGeneratorRef, mobSpawnerRef)
	worldGen   = worldGeneratorRef
	mobSpawner = mobSpawnerRef

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.delay(1, function()
				if isAdmin(player) then
					buildAdminGui(player)
				end
			end)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if isAdmin(player) and player.Character then
			buildAdminGui(player)
		end
	end
end

return AdminPanel
