--!strict
-- ============================================================
-- MODULE: GamepassManager
-- Handles Roblox Gamepass ownership checks + perks delivery.
-- Gamepasses:
--   VIP_BIOME_UNLOCK   → access to all biomes from spawn
--   EXTRA_QUEST_SLOTS  → 2 additional quest slots (3→5)
--   CHUNK_RADAR        → minimap shows upcoming biome types
--   DOUBLE_LOOT        → 2× loot drop chance
--   FACTION_DIPLOMAT   → start at Friendly (60 rep) with all factions
-- v1.0.0 | roblox-procedural-worlds
-- ============================================================

local Players          = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local GamepassManager = {}

-- ── Gamepass IDs ─────────────────────────────────────────────────
-- Replace with real Roblox Gamepass IDs before publishing.

local GAMEPASS_IDS = {
	VIP_BIOME_UNLOCK  = 000000001,
	EXTRA_QUEST_SLOTS = 000000002,
	CHUNK_RADAR       = 000000003,
	DOUBLE_LOOT       = 000000004,
	FACTION_DIPLOMAT  = 000000005,
}

export type GamepassName = "VIP_BIOME_UNLOCK" | "EXTRA_QUEST_SLOTS" | "CHUNK_RADAR" | "DOUBLE_LOOT" | "FACTION_DIPLOMAT"

-- Cache: { [userId] = { [passName] = bool } }
local ownershipCache: { [number]: { [string]: boolean } } = {}

-- ── Helpers ──────────────────────────────────────────────────────

local function safePCHeck(userId: number, passId: number): boolean
	local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync,
		MarketplaceService, userId, passId)
	if not ok then
		warn("[GamepassManager] Ownership check failed for passId:", passId, owns)
		return false
	end
	return owns :: boolean
end

local function loadOwnership(player: Player)
	local userId = player.UserId
	local cache: { [string]: boolean } = {}

	for name, id in pairs(GAMEPASS_IDS) do
		cache[name] = safePCHeck(userId, id)
		task.wait() -- avoid rate-limit burst
	end

	ownershipCache[userId] = cache
	return cache
end

-- ── Public API ───────────────────────────────────────────────────

--- Returns true if the player owns the named gamepass.
function GamepassManager.Has(player: Player, passName: GamepassName): boolean
	local cache = ownershipCache[player.UserId]
	if not cache then return false end
	return cache[passName] == true
end

--- Returns the player's full perk table (all gamepasses).
function GamepassManager.GetPerks(player: Player): { [string]: boolean }
	return ownershipCache[player.UserId] or {}
end

--- Manually grant a pass (for admin/testing).
function GamepassManager.GrantPass(player: Player, passName: string)
	local cache = ownershipCache[player.UserId]
	if not cache then return end
	cache[passName] = true
end

--- Quest slot count accounting for EXTRA_QUEST_SLOTS.
function GamepassManager.QuestSlots(player: Player): number
	return GamepassManager.Has(player, "EXTRA_QUEST_SLOTS") and 5 or 3
end

--- Loot multiplier (1× or 2×).
function GamepassManager.LootMultiplier(player: Player): number
	return GamepassManager.Has(player, "DOUBLE_LOOT") and 2 or 1
end

--- Prompt the player to purchase a gamepass.
function GamepassManager.Prompt(player: Player, passName: GamepassName)
	local id = GAMEPASS_IDS[passName]
	if not id then
		warn("[GamepassManager] Unknown pass:", passName)
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, id)
end

-- ── Lifecycle ────────────────────────────────────────────────────

function GamepassManager.Start()
	-- Load ownership async for joining players
	Players.PlayerAdded:Connect(function(player)
		task.spawn(loadOwnership, player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		ownershipCache[player.UserId] = nil
	end)

	-- Handle purchases mid-session
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then return end
		for name, id in pairs(GAMEPASS_IDS) do
			if id == passId then
				local cache = ownershipCache[player.UserId]
				if cache then cache[name] = true end
				print(string.format("[GamepassManager] %s purchased %s", player.Name, name))
				break
			end
		end
	end)

	-- Init existing players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(loadOwnership, player)
	end
end

return GamepassManager
