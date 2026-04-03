-- Inventory.lua
-- Per-player item inventory with stacking, equip slot, and persistence hooks
-- v2.4.0

local WorldConfig = require(script.Parent.WorldConfig)
local Inventory = {}

local Players = game:GetService("Players")

-- ── State ──────────────────────────────────────────────────────────
local inventories  = {}  -- [userId] = { slots = {}, equipped = {} }
local MAX_STACK    = 99

-- ── Helpers ────────────────────────────────────────────────────────
local function newInventory()
	local slots = {}
	for i = 1, WorldConfig.INVENTORY_SLOTS do
		slots[i] = { item = nil, qty = 0 }
	end
	return { slots = slots, equipped = {} }
end

local function findSlot(inv, itemName)
	for _, slot in inv.slots do
		if slot.item == itemName and slot.qty < MAX_STACK then
			return slot
		end
	end
	return nil
end

local function findEmptySlot(inv)
	for _, slot in inv.slots do
		if slot.item == nil then return slot end
	end
	return nil
end

-- ── Public API ─────────────────────────────────────────────────────
function Inventory.RegisterPlayer(player)
	inventories[player.UserId] = newInventory()
end

function Inventory.UnregisterPlayer(player)
	inventories[player.UserId] = nil
end

---Adds qty of itemName to player's inventory.
---@return number  leftover quantity that didn't fit
function Inventory.AddItem(player, itemName, qty)
	local inv = inventories[player.UserId]
	if not inv then return qty end
	local remaining = qty
	while remaining > 0 do
		local slot = findSlot(inv, itemName) or findEmptySlot(inv)
		if not slot then break end
		if slot.item == nil then
			slot.item = itemName
			slot.qty  = 0
		end
		local canAdd = math.min(remaining, MAX_STACK - slot.qty)
		slot.qty   += canAdd
		remaining  -= canAdd
	end
	return remaining
end

---Removes qty of itemName from player's inventory.
---@return boolean  true if fully removed
function Inventory.RemoveItem(player, itemName, qty)
	local inv = inventories[player.UserId]
	if not inv then return false end
	-- count total
	local total = 0
	for _, slot in inv.slots do
		if slot.item == itemName then total += slot.qty end
	end
	if total < qty then return false end
	local remaining = qty
	for _, slot in inv.slots do
		if slot.item == itemName and remaining > 0 then
			local take = math.min(slot.qty, remaining)
			slot.qty   -= take
			remaining  -= take
			if slot.qty == 0 then slot.item = nil end
		end
	end
	return true
end

---Returns total count of itemName in inventory.
function Inventory.CountItem(player, itemName)
	local inv = inventories[player.UserId]
	if not inv then return 0 end
	local total = 0
	for _, slot in inv.slots do
		if slot.item == itemName then total += slot.qty end
	end
	return total
end

---Equips an item to a named slot (e.g. "Weapon", "Helmet").
function Inventory.Equip(player, slotName, itemName)
	local inv = inventories[player.UserId]
	if not inv then return end
	inv.equipped[slotName] = itemName
end

---Returns snapshot of inventory for persistence.
function Inventory.Serialize(player)
	return inventories[player.UserId]
end

---Restores inventory from persisted data.
function Inventory.Deserialize(player, data)
	if not data then return end
	inventories[player.UserId] = data
end

function Inventory.Init()
	Players.PlayerAdded:Connect(Inventory.RegisterPlayer)
	Players.PlayerRemoving:Connect(Inventory.UnregisterPlayer)
	for _, p in Players:GetPlayers() do
		Inventory.RegisterPlayer(p)
	end
end

function Inventory.Start() end

return Inventory
