--!strict
-- ============================================================
-- MODULE: DeveloperProductHandler
-- Processes Roblox Developer Product purchases.
-- Products:
--   SEED_REROLL     → generate a new random world seed
--   INSTANT_RESPAWN → revive immediately on death
--   FACTION_BOOST   → +20 rep to chosen faction
--   CHEST_KEY       → open 1 locked dungeon chest
--   QUEST_REFRESH   → reroll all current quests
-- v1.0.0 | roblox-procedural-worlds
-- ============================================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")

local DeveloperProductHandler = {}

-- ── Product IDs ─────────────────────────────────────────────────
-- Replace with real Roblox Developer Product IDs before publishing.

local PRODUCT_IDS: { [number]: string } = {
	[100000001] = "SEED_REROLL",
	[100000002] = "INSTANT_RESPAWN",
	[100000003] = "FACTION_BOOST",
	[100000004] = "CHEST_KEY",
	[100000005] = "QUEST_REFRESH",
}

-- Custom handlers registered by other systems
local handlers: { [string]: (player: Player) -> boolean } = {}

-- ── Built-in Handlers ───────────────────────────────────────────

local function handleSeedReroll(player: Player): boolean
	-- Hook: WorldGenerator.rerollSeed(player) if exposed
	player:SetAttribute("SeedRerollPending", true)
	print("[DevProduct] SEED_REROLL for", player.Name)
	return true
end

local function handleInstantRespawn(player: Player): boolean
	player:SetAttribute("InstantRespawn", true)
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health <= 0 then
			player:LoadCharacter()
		end
	end
	print("[DevProduct] INSTANT_RESPAWN for", player.Name)
	return true
end

local function handleFactionBoost(player: Player): boolean
	-- Boost rep with the faction the player has lowest rep with
	local ok, FactionSystem = pcall(require,
		game:GetService("ReplicatedStorage"):WaitForChild("FactionSystem"))
	if ok and FactionSystem then
		local allReps = FactionSystem.GetAllReps(player.UserId)
		local lowestId, lowestRep = nil, 101
		for fId, data in pairs(allReps) do
			if data.rep < lowestRep then
				lowestRep = data.rep
				lowestId  = fId
			end
		end
		if lowestId then
			FactionSystem.AdjustRep(player.UserId, lowestId, 20)
			print(string.format("[DevProduct] FACTION_BOOST: %s +20 rep to %s",
				player.Name, lowestId))
		end
	end
	return true
end

local function handleChestKey(player: Player): boolean
	local count = player:GetAttribute("ChestKeys") or 0
	player:SetAttribute("ChestKeys", count + 1)
	print("[DevProduct] CHEST_KEY for", player.Name)
	return true
end

local function handleQuestRefresh(player: Player): boolean
	player:SetAttribute("QuestRefreshPending", true)
	print("[DevProduct] QUEST_REFRESH for", player.Name)
	return true
end

local BUILT_IN: { [string]: (player: Player) -> boolean } = {
	SEED_REROLL     = handleSeedReroll,
	INSTANT_RESPAWN = handleInstantRespawn,
	FACTION_BOOST   = handleFactionBoost,
	CHEST_KEY       = handleChestKey,
	QUEST_REFRESH   = handleQuestRefresh,
}

-- ── Public API ───────────────────────────────────────────────────

--- Register a custom product handler.
function DeveloperProductHandler.Register(productName: string, fn: (player: Player) -> boolean)
	handlers[productName] = fn
end

--- Prompt a player to buy a product by name.
function DeveloperProductHandler.Prompt(player: Player, productName: string)
	for id, name in pairs(PRODUCT_IDS) do
		if name == productName then
			MarketplaceService:PromptProductPurchase(player, id)
			return
		end
	end
	warn("[DevProduct] Unknown product:", productName)
end

-- ── Lifecycle ────────────────────────────────────────────────────

function DeveloperProductHandler.Start()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			-- Player left; grant on rejoin via DataStore
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local productName = PRODUCT_IDS[receiptInfo.ProductId]
		if not productName then
			warn("[DevProduct] Unrecognised product ID:", receiptInfo.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local handler = handlers[productName] or BUILT_IN[productName]
		if not handler then
			warn("[DevProduct] No handler for:", productName)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local ok, result = pcall(handler, player)
		if ok and result then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		warn("[DevProduct] Handler failed for", productName, result)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return DeveloperProductHandler
