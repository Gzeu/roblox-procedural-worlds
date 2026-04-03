-- EconomyManager.lua
-- Player wallets, listing market and purchase flow
-- v5.0 | roblox-procedural-worlds

local Players  = game:GetService("Players")
local EventBus = require(script.Parent.EventBus)

local okInv, Inventory = pcall(function() return require(script.Parent.Inventory) end)
if not okInv then Inventory = nil end

local EconomyManager = {}

local DEFAULT_STARTING_GOLD = 250
local balances   = {}
local listings   = {}
local nextListId = 1

local function getBalance(player)
	if balances[player.UserId] == nil then
		balances[player.UserId] = player:GetAttribute("Gold") or DEFAULT_STARTING_GOLD
		player:SetAttribute("Gold", balances[player.UserId])
	end
	return balances[player.UserId]
end

local function setBalance(player, amount)
	balances[player.UserId] = math.max(0, math.floor(amount))
	player:SetAttribute("Gold", balances[player.UserId])
	EventBus.emit("Economy:BalanceChanged", player, balances[player.UserId])
end

function EconomyManager.initPlayer(player)
	return getBalance(player)
end

function EconomyManager.getBalance(player)
	return getBalance(player)
end

function EconomyManager.addGold(player, amount)
	setBalance(player, getBalance(player) + amount)
	return getBalance(player)
end

function EconomyManager.removeGold(player, amount)
	if getBalance(player) < amount then return false, "Insufficient gold" end
	setBalance(player, getBalance(player) - amount)
	return true, getBalance(player)
end

function EconomyManager.createListing(player, itemId, quantity, unitPrice)
	quantity  = math.max(1, math.floor(quantity  or 1))
	unitPrice = math.max(1, math.floor(unitPrice or 1))
	if Inventory and Inventory.hasItem and not Inventory.hasItem(player, itemId, quantity) then
		return false, "Missing inventory item"
	end
	if Inventory and Inventory.removeItem then
		Inventory.removeItem(player, itemId, quantity)
	end
	local listing = {
		id           = nextListId,
		sellerUserId = player.UserId,
		sellerName   = player.Name,
		itemId       = itemId,
		quantity     = quantity,
		unitPrice    = unitPrice,
		createdAt    = os.time(),
	}
	listings[listing.id] = listing
	nextListId += 1
	EventBus.emit("Economy:ListingCreated", player, listing)
	return true, listing
end

function EconomyManager.cancelListing(player, listingId)
	local listing = listings[listingId]
	if not listing then return false, "Listing not found" end
	if listing.sellerUserId ~= player.UserId then return false, "Not your listing" end
	if Inventory and Inventory.addItem then
		Inventory.addItem(player, listing.itemId, listing.quantity)
	end
	listings[listingId] = nil
	EventBus.emit("Economy:ListingCancelled", player, listingId)
	return true
end

function EconomyManager.purchaseListing(buyer, listingId, quantity)
	local listing = listings[listingId]
	if not listing then return false, "Listing not found" end
	quantity = math.max(1, math.floor(quantity or 1))
	if quantity > listing.quantity then return false, "Quantity exceeds stock" end
	local total = quantity * listing.unitPrice
	if getBalance(buyer) < total then return false, "Insufficient gold" end
	if buyer.UserId == listing.sellerUserId then return false, "Cannot buy your own listing" end
	setBalance(buyer, getBalance(buyer) - total)
	local seller = Players:GetPlayerByUserId(listing.sellerUserId)
	if seller then setBalance(seller, getBalance(seller) + total) end
	if Inventory and Inventory.addItem then Inventory.addItem(buyer, listing.itemId, quantity) end
	listing.quantity -= quantity
	if listing.quantity <= 0 then listings[listingId] = nil end
	EventBus.emit("Economy:Purchased", buyer, listingId, quantity, total)
	return true, total
end

function EconomyManager.getListings()
	local out = {}
	for _, listing in pairs(listings) do table.insert(out, listing) end
	table.sort(out, function(a, b) return a.id < b.id end)
	return out
end

Players.PlayerRemoving:Connect(function(player)
	balances[player.UserId] = nil
end)

return EconomyManager
