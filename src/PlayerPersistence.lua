-- PlayerPersistence.lua
-- Saves and loads per-player data: position, inventory, quest progress, XP
-- Uses DataStoreService with auto-save every 60s
-- v2.5.0

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local WorldConfig      = require(script.Parent.WorldConfig)

local PlayerPersistence = {}

local STORE_NAME   = "ProceduralWorlds_v1"
local SAVE_INTERVAL = 60  -- seconds
local playerData   = {}   -- { [userId] = { xp, level, inventory, quests, lastPos } }
local saveTimers   = {}   -- { [userId] = lastSaveTick }
local dataStore

local DEFAULT_DATA = {
	xp        = 0,
	level     = 1,
	inventory = {},
	quests    = {},
	lastPos   = { x = 0, y = WorldConfig.BaseHeight + 5, z = 0 },
}

local function deepCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = type(v) == "table" and deepCopy(v) or v
	end
	return copy
end

local function getStore()
	if not dataStore then
		local ok, store = pcall(function()
			return DataStoreService:GetDataStore(STORE_NAME)
		end)
		if ok then dataStore = store end
	end
	return dataStore
end

local function loadData(userId)
	local store = getStore()
	if not store then return deepCopy(DEFAULT_DATA) end
	local ok, data = pcall(function()
		return store:GetAsync(tostring(userId))
	end)
	if ok and data then
		-- Fill missing keys from default
		for k, v in pairs(DEFAULT_DATA) do
			if data[k] == nil then
				data[k] = type(v) == "table" and deepCopy(v) or v
			end
		end
		return data
	else
		return deepCopy(DEFAULT_DATA)
	end
end

local function saveData(userId)
	local store = getStore()
	if not store then return end
	local data = playerData[userId]
	if not data then return end
	pcall(function()
		store:SetAsync(tostring(userId), data)
	end)
	saveTimers[userId] = tick()
end

-- Sync player's current position into data before save
local function capturePosition(player)
	local data = playerData[player.UserId]
	if not data then return end
	local char = player.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			local p = root.Position
			data.lastPos = { x = p.X, y = p.Y, z = p.Z }
		end
	end
end

function PlayerPersistence.Get(player)
	return playerData[player.UserId]
end

function PlayerPersistence.AddXP(player, amount)
	local data = playerData[player.UserId]
	if not data then return end
	data.xp = data.xp + amount
	-- Simple level threshold: level = floor(sqrt(xp / 100)) + 1
	local newLevel = math.floor(math.sqrt(data.xp / 100)) + 1
	if newLevel > data.level then
		data.level = newLevel
		player:SetAttribute("Level", newLevel)
		warn("[PlayerPersistence]", player.Name, "leveled up to", newLevel)
	end
	player:SetAttribute("XP", data.xp)
end

function PlayerPersistence.AddItem(player, itemName, qty)
	local data = playerData[player.UserId]
	if not data then return end
	data.inventory[itemName] = (data.inventory[itemName] or 0) + (qty or 1)
	player:SetAttribute("Inv_" .. itemName, data.inventory[itemName])
end

function PlayerPersistence.SaveNow(player)
	capturePosition(player)
	saveData(player.UserId)
end

function PlayerPersistence.Start()
	Players.PlayerAdded:Connect(function(player)
		local data = loadData(player.UserId)
		playerData[player.UserId] = data
		saveTimers[player.UserId] = tick()

		-- Restore attributes
		player:SetAttribute("XP",    data.xp)
		player:SetAttribute("Level", data.level)

		-- Teleport to last saved position on spawn
		player.CharacterAdded:Connect(function(char)
			task.delay(0.5, function()
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					local p = data.lastPos
					root.CFrame = CFrame.new(p.x, p.y + 2, p.z)
				end
			end)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		capturePosition(player)
		saveData(player.UserId)
		playerData[player.UserId] = nil
		saveTimers[player.UserId] = nil
	end)

	-- Auto-save loop
	RunService.Heartbeat:Connect(function()
		for userId, lastSave in pairs(saveTimers) do
			if tick() - lastSave >= SAVE_INTERVAL then
				local player = Players:GetPlayerByUserId(userId)
				if player then
					capturePosition(player)
					saveData(userId)
				end
			end
		end
	end)
end

return PlayerPersistence
