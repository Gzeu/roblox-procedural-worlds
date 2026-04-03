-- EconomyManager.lua
-- In-game currency (Gold), trading, shop prices, inflation guard
-- v2.6.0

local WorldConfig = require(script.Parent.WorldConfig)
local EconomyManager = {}

local Players      = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local CurrencyStore = DataStoreService:GetDataStore("EconomyV1")

-- ── State ──────────────────────────────────────────────────────────
local balances   = {}  -- [userId] = number
local STARTING_GOLD = WorldConfig.STARTING_GOLD or 100

-- ── Shop catalogue (seed-independent, read from WorldConfig) ───────
local SHOP = WorldConfig.SHOP_ITEMS or {
	{ id="HealthPotion",  buy=30,  sell=12 },
	{ id="IronSword",     buy=150, sell=60 },
	{ id="MagicCrystal",  buy=500, sell=200 },
	{ id="Coal",          buy=5,   sell=2  },
	{ id="Gold",          buy=40,  sell=15 },
	{ id="Diamond",       buy=800, sell=350 },
}

-- ── Helpers ────────────────────────────────────────────────────────
local function loadBalance(uid)
	local ok, val = pcall(function()
		return CurrencyStore:GetAsync("bal_" .. uid)
	end)
	return (ok and val) or STARTING_GOLD
end

local function saveBalance(uid, amount)
	pcall(function()
		CurrencyStore:SetAsync("bal_" .. uid, amount)
	end)
end

local function findShopItem(id)
	for _, entry in SHOP do
		if entry.id == id then return entry end
	end
	return nil
end

-- ── Public API ─────────────────────────────────────────────────────
function EconomyManager.GetBalance(player)
	return balances[player.UserId] or 0
end

---Adds currency to player.
function EconomyManager.Credit(player, amount)
	if amount <= 0 then return end
	local uid = player.UserId
	balances[uid] = (balances[uid] or 0) + amount
	if WorldConfig.Debug then
		warn("[Economy] +" .. amount .. " -> " .. player.Name .. " (" .. balances[uid] .. ")")
	end
end

---Deducts currency. Returns false if insufficient.
function EconomyManager.Debit(player, amount)
	local uid = player.UserId
	if (balances[uid] or 0) < amount then return false end
	balances[uid] -= amount
	return true
end

---Player buys itemId from shop.
---@return boolean, string  success, reason
function EconomyManager.BuyItem(player, itemId)
	local entry = findShopItem(itemId)
	if not entry then return false, "unknown_item" end
	if not EconomyManager.Debit(player, entry.buy) then
		return false, "insufficient_funds"
	end
	return true, "ok"
end

---Player sells itemId to shop.
function EconomyManager.SellItem(player, itemId)
	local entry = findShopItem(itemId)
	if not entry then return false, "unknown_item" end
	EconomyManager.Credit(player, entry.sell)
	return true, "ok"
end

---Transfer currency between two players.
function EconomyManager.Transfer(from, to, amount)
	if not EconomyManager.Debit(from, amount) then
		return false, "insufficient_funds"
	end
	EconomyManager.Credit(to, amount)
	return true, "ok"
end

function EconomyManager.GetShopCatalogue()
	return SHOP
end

-- ── Lifecycle ──────────────────────────────────────────────────────
local function onPlayerAdded(player)
	balances[player.UserId] = loadBalance(player.UserId)
end

local function onPlayerRemoving(player)
	local uid = player.UserId
	if balances[uid] then
		saveBalance(uid, balances[uid])
		balances[uid] = nil
	end
end

function EconomyManager.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, p in Players:GetPlayers() do
		onPlayerAdded(p)
	end
end

function EconomyManager.Start() end

return EconomyManager
