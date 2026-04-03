-- LootTable.lua
-- Procedural loot generation for dungeon chests
-- v2.2.0

local WorldConfig = require(script.Parent.WorldConfig)

local LootTable = {}

local function weightedRandom(pool, rng)
	local total = 0
	for _, entry in ipairs(pool) do
		total = total + (entry.weight or 1)
	end
	local roll = rng:NextNumber() * total
	local cumulative = 0
	for _, entry in ipairs(pool) do
		cumulative = cumulative + (entry.weight or 1)
		if roll <= cumulative then
			return entry
		end
	end
	return pool[#pool]
end

function LootTable.Generate(tier, seed)
	local rng = Random.new(seed or os.time())
	local config = WorldConfig.LootTables[tier] or WorldConfig.LootTables["Common"]
	local result = {}

	local itemCount = rng:NextInteger(config.minItems, config.maxItems)
	for _ = 1, itemCount do
		local entry = weightedRandom(config.pool, rng)
		local qty = rng:NextInteger(entry.minQty or 1, entry.maxQty or 1)
		table.insert(result, {
			name  = entry.name,
			qty   = qty,
			model = entry.model or nil,
		})
	end
	return result
end

function LootTable.FillChest(chestModel, tier, seed)
	if not chestModel then return end
	local items = LootTable.Generate(tier, seed)

	-- Store loot as attributes on the chest model for retrieval by client/server
	for i, item in ipairs(items) do
		chestModel:SetAttribute("Loot_" .. i .. "_Name",  item.name)
		chestModel:SetAttribute("Loot_" .. i .. "_Qty",   item.qty)
	end
	chestModel:SetAttribute("LootCount", #items)
	chestModel:SetAttribute("LootTier",  tier)
	chestModel:SetAttribute("LootSeed",  seed or 0)
end

return LootTable
