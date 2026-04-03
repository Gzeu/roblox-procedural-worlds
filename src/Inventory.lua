-- Inventory.lua
-- Per-player item inventory with equip, add, remove, and persistence via attributes
-- v2.4.0

local Players     = game:GetService("Players")
local WorldConfig = require(script.Parent.WorldConfig)

local Inventory = {}

-- { [userId] = { slots = { {name, qty, equipped} ... } } }
local playerInventories = {}

local MAX_SLOTS = WorldConfig.Inventory.MaxSlots or 20

local function getInv(player)
	local uid = player.UserId
	if not playerInventories[uid] then
		playerInventories[uid] = { slots = {} }
	end
	return playerInventories[uid]
end

-- Serialise inventory to a player attribute (simple string, max 200 chars)
local function syncAttributes(player)
	local inv = getInv(player)
	for i, slot in ipairs(inv.slots) do
		player:SetAttribute("Inv_" .. i .. "_Name",    slot.name)
		player:SetAttribute("Inv_" .. i .. "_Qty",     slot.qty)
		player:SetAttribute("Inv_" .. i .. "_Equipped",slot.equipped or false)
	end
	player:SetAttribute("InvSlots", #inv.slots)
end

function Inventory.AddItem(player, itemName, qty)
	local inv = getInv(player)
	qty = qty or 1

	-- Stack into existing slot
	for _, slot in ipairs(inv.slots) do
		if slot.name == itemName then
			slot.qty = slot.qty + qty
			syncAttributes(player)
			return true
		end
	end

	-- New slot
	if #inv.slots >= MAX_SLOTS then
		warn("[Inventory] Full for", player.Name)
		return false
	end

	table.insert(inv.slots, { name = itemName, qty = qty, equipped = false })
	syncAttributes(player)
	return true
end

function Inventory.RemoveItem(player, itemName, qty)
	local inv = getInv(player)
	qty = qty or 1

	for i, slot in ipairs(inv.slots) do
		if slot.name == itemName then
			slot.qty = slot.qty - qty
			if slot.qty <= 0 then
				table.remove(inv.slots, i)
			end
			syncAttributes(player)
			return true
		end
	end
	return false
end

function Inventory.EquipItem(player, itemName)
	local inv = getInv(player)
	local weaponCfg = WorldConfig.Inventory.Weapons[itemName]

	-- Unequip all first
	for _, slot in ipairs(inv.slots) do
		slot.equipped = false
	end

	for _, slot in ipairs(inv.slots) do
		if slot.name == itemName then
			slot.equipped = true
			-- Apply weapon stats to player attributes for CombatSystem
			if weaponCfg then
				player:SetAttribute("WeaponDamage", weaponCfg.damage)
				player:SetAttribute("WeaponRange",  weaponCfg.range)
				player:SetAttribute("EquippedItem", itemName)
			end
			syncAttributes(player)
			return true
		end
	end
	return false
end

function Inventory.GetSlots(player)
	return getInv(player).slots
end

function Inventory.Has(player, itemName)
	for _, slot in ipairs(getInv(player).slots) do
		if slot.name == itemName then return true, slot.qty end
	end
	return false, 0
end

-- Give loot table result directly to player
function Inventory.GiveLoot(player, lootList)
	for _, item in ipairs(lootList) do
		Inventory.AddItem(player, item.name, item.qty)
	end
end

function Inventory.Start()
	Players.PlayerRemoving:Connect(function(player)
		playerInventories[player.UserId] = nil
	end)

	if WorldConfig.Debug then
		warn("[Inventory] Started")
	end
end

return Inventory
