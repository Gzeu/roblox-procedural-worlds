-- AIGroupBehavior.lua
-- Mob pack coordination: leader election, flank, alert, retreat signals
-- v4.0 | roblox-procedural-worlds

local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local EventBus   = require(script.Parent.EventBus)
local AIMemory   = require(script.Parent.AIMemory)

local AIGroupBehavior = {}

-- ── Config ───────────────────────────────────────────────────────
local PACK_RADIUS        = 55    -- studs — mobs within this range form a pack
local ALERT_BROADCAST    = 60    -- studs — alert range when one mob spots player
local FLANK_ANGLE        = 110   -- degrees offset for flanker
local RETREAT_HP_PCT     = 0.18  -- pack retreats when leader drops below this
local REGROUP_INTERVAL   = 8     -- seconds between pack regrouping
local LEADER_ELECT_TIMER = 3     -- seconds after leader dies before re-electing

-- ── Pack registry ────────────────────────────────────────────────
-- { packId = { leader, members={}, role={[model]=role}, target=player|nil, lastRegroup } }
local _packs   = {}   -- keyed by packId (string)
local _mobPack = {}   -- { [model] = packId }
local _packCounter = 0

local function newPackId()
	_packCounter += 1
	return "pack_" .. _packCounter
end

-- ── Role constants ───────────────────────────────────────────────
local ROLE = {
	LEADER  = "Leader",
	FLANKER = "Flanker",
	SUPPORT = "Support",
	SCOUT   = "Scout",
}

-- ── Utility: nearest player ──────────────────────────────────────
local function getNearestPlayer(origin, range)
	local nearest, best = nil, range
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local d = (hrp.Position - origin).Magnitude
				if d < best then best = d; nearest = p end
			end
		end
	end
	return nearest, best
end

-- ── Pack formation ───────────────────────────────────────────────
function AIGroupBehavior.registerMob(mobModel)
	if _mobPack[mobModel] then return _mobPack[mobModel] end

	-- Try to join existing pack within radius
	local root = mobModel:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	for packId, pack in pairs(_packs) do
		local leaderRoot = pack.leader and
			pack.leader:FindFirstChild("HumanoidRootPart")
		if leaderRoot then
			local d = (root.Position - leaderRoot.Position).Magnitude
			if d <= PACK_RADIUS then
				table.insert(pack.members, mobModel)
				local role = #pack.members == 2 and ROLE.FLANKER
					or #pack.members == 3 and ROLE.SCOUT
					or ROLE.SUPPORT
				pack.role[mobModel] = role
				_mobPack[mobModel] = packId
				EventBus.emit("AIGroup:Joined", mobModel, packId, role)
				return packId
			end
		end
	end

	-- Create new pack, this mob is leader
	local packId = newPackId()
	_packs[packId] = {
		leader      = mobModel,
		members     = { mobModel },
		role        = { [mobModel] = ROLE.LEADER },
		target      = nil,
		lastRegroup = os.clock(),
		leaderElectTimer = 0,
	}
	_mobPack[mobModel] = packId
	EventBus.emit("AIGroup:PackCreated", packId, mobModel)
	return packId
end

-- ── Alert pack ───────────────────────────────────────────────────
function AIGroupBehavior.alertPack(mobModel, player)
	local packId = _mobPack[mobModel]
	if not packId then return end
	local pack = _packs[packId]
	if not pack then return end

	pack.target = player

	local attackerRoot = mobModel:FindFirstChild("HumanoidRootPart")
	if not attackerRoot then return end

	for _, member in ipairs(pack.members) do
		if member == mobModel then continue end
		if not member.Parent then continue end
		local mem = AIMemory.get(member)
		if mem and player and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				mem:recordSighting(hrp.Position, player)
				EventBus.emit("AIGroup:MemberAlerted", member, packId, player)
			end
		end
	end
end

-- ── Get flank position for a mob ─────────────────────────────────
function AIGroupBehavior.getFlankPosition(mobModel, targetPlayer)
	if not targetPlayer or not targetPlayer.Character then return nil end
	local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not targetHRP then return nil end
	local root = mobModel:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local toTarget = (targetHRP.Position - root.Position).Unit
	local angle    = math.rad(FLANK_ANGLE)
	-- rotate toTarget by angle around Y axis
	local flankDir = Vector3.new(
		toTarget.X * math.cos(angle) - toTarget.Z * math.sin(angle),
		0,
		toTarget.X * math.sin(angle) + toTarget.Z * math.cos(angle)
	)
	return targetHRP.Position + flankDir * 10
end

-- ── Retrieve pack info ───────────────────────────────────────────
function AIGroupBehavior.getRole(mobModel)
	local packId = _mobPack[mobModel]
	if not packId then return nil end
	local pack = _packs[packId]
	return pack and pack.role[mobModel]
end

function AIGroupBehavior.getPackTarget(mobModel)
	local packId = _mobPack[mobModel]
	if not packId then return nil end
	local pack = _packs[packId]
	return pack and pack.target
end

function AIGroupBehavior.isLeader(mobModel)
	local packId = _mobPack[mobModel]
	if not packId then return false end
	local pack = _packs[packId]
	return pack and pack.leader == mobModel
end

-- ── Retreat signal ───────────────────────────────────────────────
function AIGroupBehavior.checkRetreat(mobModel, currentHpPct)
	if not AIGroupBehavior.isLeader(mobModel) then return false end
	if currentHpPct <= RETREAT_HP_PCT then
		local packId = _mobPack[mobModel]
		if packId then
			EventBus.emit("AIGroup:RetreatSignal", packId, mobModel)
		end
		return true
	end
	return false
end

-- ── Cleanup on mob death ─────────────────────────────────────────
EventBus.on("MobAI:Died", function(mobModel, attacker)
	local packId = _mobPack[mobModel]
	if not packId then return end
	local pack = _packs[packId]
	if not pack then return end

	-- Remove from members list
	for i, m in ipairs(pack.members) do
		if m == mobModel then
			table.remove(pack.members, i)
			break
		end
	end
	pack.role[mobModel] = nil
	_mobPack[mobModel]  = nil

	-- Re-elect leader if needed
	if pack.leader == mobModel then
		pack.leader = pack.members[1]  -- next in list
		if pack.leader then
			pack.role[pack.leader] = ROLE.LEADER
			EventBus.emit("AIGroup:LeaderElected", packId, pack.leader)
		end
	end

	-- Disband empty pack
	if #pack.members == 0 then
		_packs[packId] = nil
		EventBus.emit("AIGroup:PackDisbanded", packId)
	end
end)

AIGroupBehavior.ROLE       = ROLE
AIGroupBehavior.PACK_RADIUS = PACK_RADIUS

return AIGroupBehavior
