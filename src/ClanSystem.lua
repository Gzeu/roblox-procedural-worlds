-- ClanSystem.lua
-- Player-created clans: creation, membership, leadership, clan XP
-- v2.5.0

local WorldConfig = require(script.Parent.WorldConfig)
local ClanSystem = {}

local Players = game:GetService("Players")

-- ── Config ─────────────────────────────────────────────────────────
local MAX_CLAN_MEMBERS = WorldConfig.MAX_CLAN_MEMBERS or 20
local MAX_CLAN_NAME    = 24

-- ── State ──────────────────────────────────────────────────────────
local clans      = {}  -- [clanId] = { name, leaderId, members={userId}, xp, level }
local playerClan = {}  -- [userId] = clanId
local nextClanId = 1

-- ── Helpers ────────────────────────────────────────────────────────
local function genId()
	local id = "clan_" .. nextClanId
	nextClanId += 1
	return id
end

local function clanXpToLevel(xp)
	return math.floor(1 + math.sqrt(xp / 100))
end

-- ── Public API ─────────────────────────────────────────────────────

---Creates a new clan. Returns clanId or nil, reason.
function ClanSystem.CreateClan(founder, clanName)
	if playerClan[founder.UserId] then
		return nil, "already_in_clan"
	end
	if #clanName > MAX_CLAN_NAME or #clanName < 3 then
		return nil, "invalid_name"
	end
	-- Name uniqueness check
	for _, c in clans do
		if c.name:lower() == clanName:lower() then
			return nil, "name_taken"
		end
	end
	local id = genId()
	clans[id] = {
		name     = clanName,
		leaderId = founder.UserId,
		members  = { founder.UserId },
		xp       = 0,
		level    = 1,
	}
	playerClan[founder.UserId] = id
	if WorldConfig.Debug then
		warn("[Clan] Created:", clanName, "by", founder.Name)
	end
	return id, "ok"
end

---Invites a player to join a clan (called by clan leader).
function ClanSystem.Invite(leader, target)
	local clanId = playerClan[leader.UserId]
	if not clanId then return false, "not_in_clan" end
	local clan = clans[clanId]
	if clan.leaderId ~= leader.UserId then return false, "not_leader" end
	if playerClan[target.UserId] then return false, "target_in_clan" end
	if #clan.members >= MAX_CLAN_MEMBERS then return false, "clan_full" end
	table.insert(clan.members, target.UserId)
	playerClan[target.UserId] = clanId
	return true, "ok"
end

---Removes a player from their clan.
function ClanSystem.Leave(player)
	local clanId = playerClan[player.UserId]
	if not clanId then return false, "not_in_clan" end
	local clan = clans[clanId]
	-- Remove from members
	for i, uid in clan.members do
		if uid == player.UserId then
			table.remove(clan.members, i)
			break
		end
	end
	playerClan[player.UserId] = nil
	-- Dissolve if empty
	if #clan.members == 0 then
		clans[clanId] = nil
	end
	return true, "ok"
end

function ClanSystem.AwardClanXP(clanId, amount)
	local clan = clans[clanId]
	if not clan then return end
	clan.xp    += amount
	clan.level  = clanXpToLevel(clan.xp)
end

function ClanSystem.GetClan(clanId)
	return clans[clanId]
end

function ClanSystem.GetPlayerClan(player)
	local id = playerClan[player.UserId]
	return id and clans[id]
end

function ClanSystem.Init()
	Players.PlayerRemoving:Connect(function(player)
		-- Auto-leave on disconnect
		if playerClan[player.UserId] then
			ClanSystem.Leave(player)
		end
	end)
end

function ClanSystem.Start() end

return ClanSystem
