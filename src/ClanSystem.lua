-- ClanSystem.lua
-- Weighted clan rolls, rarity tiers and passive stat bonuses
-- v5.0 | roblox-procedural-worlds

local Players  = game:GetService("Players")
local EventBus = require(script.Parent.EventBus)

local ClanSystem = {}

ClanSystem.Clans = {
	Ironfang   = { rarity = "Common",    weight = 50, bonuses = { meleeDamage = 4,  maxHP = 10 } },
	Moonveil   = { rarity = "Rare",      weight = 28, bonuses = { dodgeChance = 0.06, moveSpeed = 1 } },
	Stormcall  = { rarity = "Epic",      weight = 15, bonuses = { magicDamage = 8,  xpBonus = 0.08 } },
	Sunbreaker = { rarity = "Legendary", weight = 7,  bonuses = { meleeDamage = 8, critChance = 0.08, maxHP = 25 } },
}

local playerClans = {}

local function weightedRoll()
	local total = 0
	for _, clan in pairs(ClanSystem.Clans) do total += clan.weight end
	local roll   = Random.new():NextNumber(0, total)
	local cursor = 0
	for name, clan in pairs(ClanSystem.Clans) do
		cursor += clan.weight
		if roll <= cursor then return name end
	end
	return "Ironfang"
end

function ClanSystem.initPlayer(player)
	if not playerClans[player.UserId] then
		local clanName = player:GetAttribute("ClanName") or weightedRoll()
		playerClans[player.UserId] = clanName
		player:SetAttribute("ClanName", clanName)
		EventBus.emit("ClanSystem:Assigned", player, clanName)
	end
	return playerClans[player.UserId]
end

function ClanSystem.getClan(player)
	return playerClans[player.UserId] or ClanSystem.initPlayer(player)
end

function ClanSystem.setClan(player, clanName)
	if not ClanSystem.Clans[clanName] then return false, "Unknown clan" end
	playerClans[player.UserId] = clanName
	player:SetAttribute("ClanName", clanName)
	EventBus.emit("ClanSystem:Changed", player, clanName)
	return true
end

function ClanSystem.rerollClan(player)
	local clanName = weightedRoll()
	ClanSystem.setClan(player, clanName)
	return clanName
end

function ClanSystem.getPassiveBonuses(player)
	local clanName   = ClanSystem.getClan(player)
	local definition = ClanSystem.Clans[clanName]
	return definition and definition.bonuses or {}
end

function ClanSystem.getSummary(player)
	local clanName   = ClanSystem.getClan(player)
	local definition = ClanSystem.Clans[clanName]
	return {
		name    = clanName,
		rarity  = definition and definition.rarity  or "Common",
		bonuses = definition and definition.bonuses or {},
	}
end

Players.PlayerRemoving:Connect(function(player)
	playerClans[player.UserId] = nil
end)

return ClanSystem
