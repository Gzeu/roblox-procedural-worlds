-- CraftingSystem.lua
-- Recipe-based crafting: validates ingredients, consumes from Inventory, outputs result
-- v2.5.0

local WorldConfig = require(script.Parent.WorldConfig)
local CraftingSystem = {}

local Players = game:GetService("Players")

-- ── Recipe catalogue ───────────────────────────────────────────────
local RECIPES = WorldConfig.CRAFTING_RECIPES or {
	{
		id      = "IronSword",
		inputs  = { { item="Iron", qty=3 }, { item="Coal", qty=1 } },
		output  = { item="IronSword", qty=1 },
		level   = 1,
	},
	{
		id      = "HealthPotion",
		inputs  = { { item="Herb", qty=2 }, { item="Water", qty=1 } },
		output  = { item="HealthPotion", qty=2 },
		level   = 1,
	},
	{
		id      = "DiamondArmor",
		inputs  = { { item="Diamond", qty=8 }, { item="IronSword", qty=2 } },
		output  = { item="DiamondArmor", qty=1 },
		level   = 10,
	},
	{
		id      = "MagicStaff",
		inputs  = { { item="MagicCrystal", qty=3 }, { item="Wood", qty=2 } },
		output  = { item="MagicStaff", qty=1 },
		level   = 8,
	},
}

-- Lazy require Inventory to avoid circular deps
local Inventory

local function getInventory()
	if not Inventory then
		Inventory = require(script.Parent.Inventory)
	end
	return Inventory
end

-- ── Helpers ────────────────────────────────────────────────────────
local function findRecipe(id)
	for _, r in RECIPES do if r.id == id then return r end end
	return nil
end

-- ── Public API ─────────────────────────────────────────────────────

---Attempts to craft recipeId for player.
---@param playerLevel number  current skill/craft level
---@return boolean, string
function CraftingSystem.Craft(player, recipeId, playerLevel)
	local recipe = findRecipe(recipeId)
	if not recipe then return false, "unknown_recipe" end
	if (playerLevel or 0) < (recipe.level or 1) then
		return false, "level_too_low"
	end
	local inv = getInventory()
	-- Check all inputs
	for _, req in recipe.inputs do
		if inv.CountItem(player, req.item) < req.qty then
			return false, "missing_" .. req.item
		end
	end
	-- Consume inputs
	for _, req in recipe.inputs do
		inv.RemoveItem(player, req.item, req.qty)
	end
	-- Grant output
	local leftover = inv.AddItem(player, recipe.output.item, recipe.output.qty)
	if leftover > 0 and WorldConfig.Debug then
		warn("[Crafting] Inventory full; dropped", leftover, recipe.output.item)
	end
	if WorldConfig.Debug then
		warn("[Crafting]", player.Name, "crafted", recipe.output.qty, recipe.output.item)
	end
	return true, "ok"
end

function CraftingSystem.GetRecipes()
	return RECIPES
end

function CraftingSystem.GetRecipesForLevel(level)
	local available = {}
	for _, r in RECIPES do
		if (r.level or 1) <= level then
			table.insert(available, r)
		end
	end
	return available
end

function CraftingSystem.Init() end
function CraftingSystem.Start() end

return CraftingSystem
