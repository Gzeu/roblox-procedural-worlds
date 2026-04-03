-- FactionSystem.lua
-- Player faction membership, reputation, inter-faction relations & perks
-- v2.5.0

local WorldConfig = require(script.Parent.WorldConfig)
local FactionSystem = {}

local Players = game:GetService("Players")

-- ── Config ─────────────────────────────────────────────────────────
local FACTIONS = WorldConfig.FACTIONS or {
	{ id="Ironclad",    displayName="Ironclad Guard",  alignment="Lawful"  },
	{ id="WildHunters", displayName="Wild Hunters",     alignment="Neutral" },
	{ id="ShadowCult",  displayName="Shadow Cult",      alignment="Chaotic" },
	{ id="MerchantGuild",displayName="Merchant Guild",  alignment="Neutral" },
}

-- Relation matrix: factionId -> factionId -> "Allied"|"Hostile"|"Neutral"
local RELATIONS = WorldConfig.FACTION_RELATIONS or {
	Ironclad    = { WildHunters="Neutral", ShadowCult="Hostile",  MerchantGuild="Allied"  },
	WildHunters = { Ironclad="Neutral",    ShadowCult="Neutral",  MerchantGuild="Neutral" },
	ShadowCult  = { Ironclad="Hostile",    WildHunters="Neutral", MerchantGuild="Hostile" },
	MerchantGuild={ Ironclad="Allied",     WildHunters="Neutral", ShadowCult="Hostile"   },
}

local REP_THRESHOLDS = {
	{ min=-1000, max=-500, rank="Exiled"    },
	{ min=-499,  max=-1,   rank="Hostile"   },
	{ min=0,     max=499,  rank="Neutral"   },
	{ min=500,   max=1499, rank="Friendly"  },
	{ min=1500,  max=2999, rank="Honored"   },
	{ min=3000,  max=5000, rank="Exalted"   },
}

-- ── State ──────────────────────────────────────────────────────────
local playerData = {}  -- [userId] = { faction=id|nil, reputation={ [factionId]=number } }

-- ── Helpers ────────────────────────────────────────────────────────
local function newData()
	local rep = {}
	for _, f in FACTIONS do rep[f.id] = 0 end
	return { faction=nil, reputation=rep }
end

local function getRank(rep)
	for _, tier in REP_THRESHOLDS do
		if rep >= tier.min and rep <= tier.max then return tier.rank end
	end
	return "Neutral"
end

-- ── Public API ─────────────────────────────────────────────────────
function FactionSystem.RegisterPlayer(player)
	playerData[player.UserId] = newData()
end

function FactionSystem.UnregisterPlayer(player)
	playerData[player.UserId] = nil
end

---Assigns player to a faction.
function FactionSystem.JoinFaction(player, factionId)
	local d = playerData[player.UserId]
	if not d then return false, "no_data" end
	for _, f in FACTIONS do
		if f.id == factionId then
			d.faction = factionId
			return true, "ok"
		end
	end
	return false, "unknown_faction"
end

---Changes reputation with a faction.
function FactionSystem.ChangeReputation(player, factionId, delta)
	local d = playerData[player.UserId]
	if not d or not d.reputation[factionId] then return end
	d.reputation[factionId] = math.clamp(
		d.reputation[factionId] + delta, -1000, 5000
	)
end

function FactionSystem.GetReputation(player, factionId)
	local d = playerData[player.UserId]
	if not d then return 0 end
	return d.reputation[factionId] or 0
end

function FactionSystem.GetRank(player, factionId)
	return getRank(FactionSystem.GetReputation(player, factionId))
end

function FactionSystem.GetRelation(factionA, factionB)
	if factionA == factionB then return "Allied" end
	return (RELATIONS[factionA] and RELATIONS[factionA][factionB]) or "Neutral"
end

function FactionSystem.GetPlayerFaction(player)
	local d = playerData[player.UserId]
	return d and d.faction
end

function FactionSystem.GetAll()
	return FACTIONS
end

function FactionSystem.Init()
	Players.PlayerAdded:Connect(FactionSystem.RegisterPlayer)
	Players.PlayerRemoving:Connect(FactionSystem.UnregisterPlayer)
	for _, p in Players:GetPlayers() do
		FactionSystem.RegisterPlayer(p)
	end
end

function FactionSystem.Start() end

return FactionSystem
