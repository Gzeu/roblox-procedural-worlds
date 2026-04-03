--!strict
-- ============================================================
-- MODULE: ServerScriptService/SeedPersistence  [v2.1 NEW]
-- Stores and retrieves the world seed across server sessions
-- using DataStoreService. The seed is saved once per place,
-- so the same world topology is preserved when servers restart.
--
-- Key format: "WorldSeed_v1"
-- Returns the persisted seed, or generates + saves a new one.
--
-- Usage:
--   local seed = SeedPersistence.GetOrCreateSeed()
-- ============================================================

local DataStoreService = game:GetService("DataStoreService")

local SeedPersistence = {}

local STORE_NAME = "ProceduralWorldsV1"
local SEED_KEY   = "WorldSeed_v1"

function SeedPersistence.GetOrCreateSeed(): number
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)

	if not ok or not store then
		local fallback = math.random(1, 2^31 - 1)
		warn("[SeedPersistence] DataStore unavailable. Using ephemeral seed:", fallback)
		return fallback
	end

	local loadOk, value = pcall(function()
		return (store :: GlobalDataStore):GetAsync(SEED_KEY)
	end)

	if loadOk and type(value) == "number" then
		print("[SeedPersistence] Loaded persisted seed:", value)
		return value
	end

	local newSeed = math.random(1, 2^31 - 1)
	local saveOk, saveErr = pcall(function()
		(store :: GlobalDataStore):SetAsync(SEED_KEY, newSeed)
	end)

	if saveOk then
		print("[SeedPersistence] New world seed saved:", newSeed)
	else
		warn("[SeedPersistence] Failed to save seed:", saveErr)
	end

	return newSeed
end

function SeedPersistence.ResetSeed()
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if not ok then return end

	local removeOk, err = pcall(function()
		(store :: GlobalDataStore):RemoveAsync(SEED_KEY)
	end)
	if removeOk then
		print("[SeedPersistence] World seed cleared. Next restart will generate a new world.")
	else
		warn("[SeedPersistence] ResetSeed error:", err)
	end
end

return SeedPersistence
