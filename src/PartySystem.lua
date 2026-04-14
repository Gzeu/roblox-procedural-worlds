-- PartySystem.lua
-- Manages player parties: creation, XP split, loot visibility, chunk teleport
-- v2.8 | roblox-procedural-worlds

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(script.Parent.WorldConfig)
local EventBus = require(script.Parent.EventBus)

local PartySystem = {}
PartySystem.__index = PartySystem

-- Module state
local parties = {}       -- partyId -> { leaderId, members={userId}, xpPool=0 }
local playerParty = {}   -- userId -> partyId
local nextPartyId = 1

local CONFIG = WorldConfig.Party or {
	MaxSize        = 4,
	XPSplitMode    = "equal",   -- "equal" | "proportional"
	ShareRadius    = 200,        -- studs — loot visibility radius
	TeleportDelay  = 3,         -- seconds before chunk teleport
}

-- Remote events (created once)
local remotes

local function ensureRemotes()
	if remotes then return end
	local folder = ReplicatedStorage:FindFirstChild("PartyRemotes")
			or Instance.new("Folder")
	folder.Name = "PartyRemotes"
	folder.Parent = ReplicatedStorage

	local function makeRemote(name)
		local r = folder:FindFirstChild(name)
		if not r then
			r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = folder
		end
		return r
	end

	remotes = {
		Invite        = makeRemote("PartyInvite"),
		Accept        = makeRemote("PartyAccept"),
		Leave         = makeRemote("PartyLeave"),
		Kick          = makeRemote("PartyKick"),
		Update        = makeRemote("PartyUpdate"),   -- server -> client sync
		LootNotify   = makeRemote("PartyLootNotify"),
	}
end

-- Internal: broadcast party state to all members
local function syncParty(partyId)
	local party = parties[partyId]
	if not party then return end
	for _, uid in ipairs(party.members) do
		local plr = Players:GetPlayerByUserId(uid)
		if plr then
			remotes.Update:FireClient(plr, {
				partyId   = partyId,
				leaderId  = party.leaderId,
				members   = party.members,
			})
		end
	end
end

-- Internal: dissolve a party
local function dissolveParty(partyId)
	local party = parties[partyId]
	if not party then return end
	for _, uid in ipairs(party.members) do
		playerParty[uid] = nil
		local plr = Players:GetPlayerByUserId(uid)
		if plr then
			remotes.Update:FireClient(plr, nil)  -- nil = no party
		end
	end
	parties[partyId] = nil
	EventBus:Fire("PartyDissolved", partyId)
end

-- Public: Create a new party (leader only)
function PartySystem.Create(leader)
	if playerParty[leader.UserId] then
		return nil, "Already in a party"
	end
	local id = nextPartyId
	nextPartyId = nextPartyId + 1
	parties[id] = {
		leaderId = leader.UserId,
		members  = { leader.UserId },
		xpPool   = 0,
	}
	playerParty[leader.UserId] = id
	syncParty(id)
	EventBus:Fire("PartyCreated", id, leader)
	return id
end

-- Public: Invite a player to leader's party
function PartySystem.Invite(leader, target)
	local partyId = playerParty[leader.UserId]
	if not partyId then return false, "Not in a party" end
	local party = parties[partyId]
	if party.leaderId ~= leader.UserId then return false, "Not leader" end
	if #party.members >= CONFIG.MaxSize then return false, "Party full" end
	if playerParty[target.UserId] then return false, "Target already in party" end
	remotes.Invite:FireClient(target, {
		partyId  = partyId,
		leader   = leader.Name,
	})
	return true
end

-- Public: Accept invite
function PartySystem.Accept(player, partyId)
	if playerParty[player.UserId] then return false end
	local party = parties[partyId]
	if not party then return false end
	if #party.members >= CONFIG.MaxSize then return false end
	table.insert(party.members, player.UserId)
	playerParty[player.UserId] = partyId
	syncParty(partyId)
	EventBus:Fire("PartyMemberJoined", partyId, player)
	return true
end

-- Public: Leave party
function PartySystem.Leave(player)
	local partyId = playerParty[player.UserId]
	if not partyId then return end
	local party = parties[partyId]
	if party.leaderId == player.UserId then
		dissolveParty(partyId)
		return
	end
	for i, uid in ipairs(party.members) do
		if uid == player.UserId then
			table.remove(party.members, i)
			break
		end
	end
	playerParty[player.UserId] = nil
	remotes.Update:FireClient(player, nil)
	syncParty(partyId)
	EventBus:Fire("PartyMemberLeft", partyId, player)
end

-- Public: Distribute XP to all party members
function PartySystem.DistributeXP(sourcePlayer, totalXP)
	local partyId = playerParty[sourcePlayer.UserId]
	if not partyId then
		EventBus:Fire("XPGained", sourcePlayer, totalXP)
		return
	end
	local party = parties[partyId]
	local memberCount = #party.members
	if memberCount == 0 then return end

	local share = CONFIG.XPSplitMode == "equal"
		and math.floor(totalXP / memberCount)
		or totalXP   -- proportional: caller handles weights externally

	for _, uid in ipairs(party.members) do
		local plr = Players:GetPlayerByUserId(uid)
		if plr then
			EventBus:Fire("XPGained", plr, share)
		end
	end
end

-- Public: Notify all nearby party members about loot drop
function PartySystem.NotifyLoot(sourcePlayer, lootData)
	local partyId = playerParty[sourcePlayer.UserId]
	if not partyId then return end
	local party = parties[partyId]
	local srcChar = sourcePlayer.Character
	local srcPos = srcChar and srcChar:FindFirstChild("HumanoidRootPart")
			and srcChar.HumanoidRootPart.Position
	for _, uid in ipairs(party.members) do
		if uid ~= sourcePlayer.UserId then
			local plr = Players:GetPlayerByUserId(uid)
			if plr then
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp and srcPos then
					local dist = (hrp.Position - srcPos).Magnitude
					if dist <= CONFIG.ShareRadius then
						remotes.LootNotify:FireClient(plr, lootData)
					end
				end
			end
		end
	end
end

-- Public: Get party of a player
function PartySystem.GetParty(player)
	local partyId = playerParty[player.UserId]
	return partyId and parties[partyId] or nil
end

-- Init: wire up remotes + PlayerRemoving cleanup
function PartySystem.Init()
	ensureRemotes()

	remotes.Accept:OnServerEvent:Connect(function(player, partyId)
		PartySystem.Accept(player, partyId)
	end)

	remotes.Leave:OnServerEvent:Connect(function(player)
		PartySystem.Leave(player)
	end)

	remotes.Kick:OnServerEvent:Connect(function(leader, targetUserId)
		local partyId = playerParty[leader.UserId]
		if not partyId then return end
		local party = parties[partyId]
		if party.leaderId ~= leader.UserId then return end
		local target = Players:GetPlayerByUserId(targetUserId)
		if target then PartySystem.Leave(target) end
	end)

	Players.PlayerRemoving:Connect(function(player)
		PartySystem.Leave(player)
	end)

	if WorldConfig.Debug then
		warn("[PartySystem] Initialized | MaxSize:", CONFIG.MaxSize, "| XPSplit:", CONFIG.XPSplitMode)
	end
end

return PartySystem
