--!strict
-- ============================================================
-- MODULE: FactionSystem
-- Territory-based faction system:
--   - Factions claim chunks → passive income via EconomyManager
--   - Player reputation per faction (ally/neutral/enemy)
--   - Chunk ownership tracked on a global map
--   - Attack/defend events trigger BossEncounter hooks
-- v1.0.0 | roblox-procedural-worlds
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldConfig       = require(ReplicatedStorage:WaitForChild("WorldConfig"))

local FactionSystem = {}

-- ── Faction Definitions ──────────────────────────────────────────

export type Faction = {
	id:          string,
	name:        string,
	color:       Color3,
	biomes:      { string },       -- preferred biomes
	passiveIncome: number,         -- gold/min per owned chunk
	startRep:    number,           -- default reputation (0–100)
	enemy:       { string },       -- faction ids that are hostile by default
}

local FACTIONS: { Faction } = {
	{
		id           = "iron_veil",
		name         = "Iron Veil",
		color        = Color3.fromRGB(120, 140, 160),
		biomes       = { "Tundra", "Taiga" },
		passiveIncome = 2,
		startRep     = 50,
		enemy        = { "ember_cult" },
	},
	{
		id           = "ember_cult",
		name         = "Ember Cult",
		color        = Color3.fromRGB(200, 80, 40),
		biomes       = { "Volcanic", "Desert" },
		passiveIncome = 3,
		startRep     = 30,
		enemy        = { "iron_veil", "verdant_circle" },
	},
	{
		id           = "verdant_circle",
		name         = "Verdant Circle",
		color        = Color3.fromRGB(60, 160, 80),
		biomes       = { "Forest", "Jungle", "Swamp" },
		passiveIncome = 2,
		startRep     = 50,
		enemy        = { "ember_cult" },
	},
	{
		id           = "tide_syndicate",
		name         = "Tide Syndicate",
		color        = Color3.fromRGB(40, 120, 200),
		biomes       = { "Ocean", "Swamp", "Grassland" },
		passiveIncome = 4,
		startRep     = 40,
		enemy        = {},
	},
}

-- ── State ────────────────────────────────────────────────────────

-- chunkOwnership["cx,cz"] = factionId
local chunkOwnership: { [string]: string } = {}

-- playerRep[userId][factionId] = 0–100
local playerRep: { [number]: { [string]: number } } = {}

-- factionTreasury[factionId] = accumulated gold
local factionTreasury: { [string]: number } = {}

local INCOME_TICK = 60  -- seconds between income ticks

-- ── Helpers ──────────────────────────────────────────────────────

local function chunkKey(cx: number, cz: number): string
	return cx .. "," .. cz
end

local function getFaction(id: string): Faction?
	for _, f in ipairs(FACTIONS) do
		if f.id == id then return f end
	end
	return nil
end

local function initPlayerRep(userId: number)
	if playerRep[userId] then return end
	playerRep[userId] = {}
	for _, f in ipairs(FACTIONS) do
		playerRep[userId][f.id] = f.startRep
	end
end

-- ── Territory ────────────────────────────────────────────────────

--- Assign a chunk to a faction (called by WorldGenerator on world gen).
function FactionSystem.ClaimChunk(cx: number, cz: number, factionId: string)
	chunkOwnership[chunkKey(cx, cz)] = factionId
end

--- Get the faction that owns a given chunk (nil = unclaimed).
function FactionSystem.GetChunkOwner(cx: number, cz: number): Faction?
	local id = chunkOwnership[chunkKey(cx, cz)]
	if not id then return nil end
	return getFaction(id)
end

--- Return how many chunks a faction owns.
function FactionSystem.GetTerritoryCount(factionId: string): number
	local count = 0
	for _, ownerId in pairs(chunkOwnership) do
		if ownerId == factionId then count += 1 end
	end
	return count
end

--- Transfer a chunk's ownership (player conquered territory).
function FactionSystem.ConquerChunk(cx: number, cz: number, newFactionId: string, conqueredBy: Player?)
	local key     = chunkKey(cx, cz)
	local oldId   = chunkOwnership[key]
	chunkOwnership[key] = newFactionId

	-- Rep consequences
	if conqueredBy then
		local userId = conqueredBy.UserId
		initPlayerRep(userId)
		-- Gain rep with new faction, lose with old
		if newFactionId then
			FactionSystem.AdjustRep(userId, newFactionId, 10)
		end
		if oldId then
			FactionSystem.AdjustRep(userId, oldId, -15)
		end
	end

end

-- ── Reputation ───────────────────────────────────────────────────

export type RepStatus = "Ally" | "Friendly" | "Neutral" | "Unfriendly" | "Enemy"

local function repToStatus(rep: number): RepStatus
	if rep >= 80 then return "Ally"
	elseif rep >= 60 then return "Friendly"
	elseif rep >= 35 then return "Neutral"
	elseif rep >= 15 then return "Unfriendly"
	else return "Enemy"
	end
end

--- Adjust a player's reputation with a faction.
function FactionSystem.AdjustRep(userId: number, factionId: string, delta: number)
	initPlayerRep(userId)
	local current = playerRep[userId][factionId] or 50
	playerRep[userId][factionId] = math.clamp(current + delta, 0, 100)
end

--- Get a player's numeric reputation with a faction.
function FactionSystem.GetRep(userId: number, factionId: string): number
	initPlayerRep(userId)
	return playerRep[userId][factionId] or 50
end

--- Get a player's status label with a faction.
function FactionSystem.GetStatus(userId: number, factionId: string): RepStatus
	return repToStatus(FactionSystem.GetRep(userId, factionId))
end

--- Get all faction reputations for a player.
function FactionSystem.GetAllReps(userId: number): { [string]: { rep: number, status: RepStatus } }
	initPlayerRep(userId)
	local result = {}
	for factionId, rep in pairs(playerRep[userId]) do
		result[factionId] = { rep = rep, status = repToStatus(rep) }
	end
	return result
end

-- ── Passive Income ───────────────────────────────────────────────

local function runIncomeTick()
	for _, faction in ipairs(FACTIONS) do
		local territory = FactionSystem.GetTerritoryCount(faction.id)
		local income    = territory * faction.passiveIncome
		factionTreasury[faction.id] = (factionTreasury[faction.id] or 0) + income
	end
end

--- Get a faction's current treasury balance.
function FactionSystem.GetTreasury(factionId: string): number
	return factionTreasury[factionId] or 0
end

-- ── World Init ───────────────────────────────────────────────────

--- Auto-assign chunks to factions based on biome during world gen.
--- Call this after ChunkHandler generates each chunk.
function FactionSystem.AutoClaimFromBiome(cx: number, cz: number, biomeName: string)
	for _, faction in ipairs(FACTIONS) do
		for _, b in ipairs(faction.biomes) do
			if b == biomeName then
				FactionSystem.ClaimChunk(cx, cz, faction.id)
				return
			end
		end
	end
end

--- Get all faction definitions.
function FactionSystem.GetAll(): { Faction }
	return FACTIONS
end

--- Get a single faction by id.
function FactionSystem.Get(id: string): Faction?
	return getFaction(id)
end

-- ── Lifecycle ────────────────────────────────────────────────────

function FactionSystem.Start()
	-- Init rep for players already in game
	for _, player in ipairs(Players:GetPlayers()) do
		initPlayerRep(player.UserId)
	end

	Players.PlayerAdded:Connect(function(player)
		initPlayerRep(player.UserId)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerRep[player.UserId] = nil
	end)

	-- Passive income loop
	task.spawn(function()
		while true do
			task.wait(INCOME_TICK)
			runIncomeTick()
		end
	end)
end

return FactionSystem
