-- CraftingSystem.lua
-- Recipe-based crafting with ingredient validation, output generation and EventBus integration
-- v2.5 | roblox-procedural-worlds

local EventBus = require(script.Parent.EventBus)
local Inventory = require(script.Parent.Inventory)

local CraftingSystem = {}
CraftingSystem.__index = CraftingSystem

-- Recipe registry: { [recipeName] = { ingredients = {...}, output = {...}, requiredLevel = number } }
local recipes = {
	WoodenSword = {
		ingredients = { Wood = 3, Stone = 1 },
		output = { WoodenSword = 1 },
		requiredLevel = 1,
		description = "A basic sword made of wood and stone.",
	},
	HealthPotion = {
		ingredients = { Herb = 2, Water = 1 },
		output = { HealthPotion = 1 },
		requiredLevel = 1,
		description = "Restores 50 HP when consumed.",
	},
	IronPickaxe = {
		ingredients = { IronIngot = 3, Wood = 2 },
		output = { IronPickaxe = 1 },
		requiredLevel = 5,
		description = "Mines ores twice as fast as a stone pickaxe.",
	},
	Torch = {
		ingredients = { Wood = 1, Coal = 1 },
		output = { Torch = 4 },
		requiredLevel = 1,
		description = "Illuminates dark dungeons. Lasts 5 in-game hours.",
	},
	StoneWall = {
		ingredients = { Stone = 6 },
		output = { StoneWall = 1 },
		requiredLevel = 2,
		description = "A solid stone wall segment for building.",
	},
	EnchantedArmor = {
		ingredients = { IronIngot = 5, MagicCrystal = 2, Leather = 3 },
		output = { EnchantedArmor = 1 },
		requiredLevel = 15,
		description = "Provides +25 defense and minor magic resistance.",
	},
}

-- Register a new recipe at runtime
function CraftingSystem.registerRecipe(name, data)
	assert(type(name) == "string", "Recipe name must be a string")
	assert(data.ingredients and data.output, "Recipe must have ingredients and output")
	recipes[name] = data
	EventBus.emit("CraftingSystem:RecipeRegistered", name, data)
end

-- Get all available recipes
function CraftingSystem.getRecipes()
	return recipes
end

-- Get a single recipe by name
function CraftingSystem.getRecipe(name)
	return recipes[name]
end

-- Check if a player can craft a recipe
-- @param player Player
-- @param recipeName string
-- @param playerLevel number
-- @returns boolean, string reason
function CraftingSystem.canCraft(player, recipeName, playerLevel)
	local recipe = recipes[recipeName]
	if not recipe then
		return false, "Unknown recipe: " .. tostring(recipeName)
	end

	if playerLevel and recipe.requiredLevel and playerLevel < recipe.requiredLevel then
		return false, "Requires level " .. recipe.requiredLevel
	end

	for item, qty in pairs(recipe.ingredients) do
		local has = Inventory.getItemCount(player, item)
		if has < qty then
			return false, "Not enough " .. item .. " (need " .. qty .. ", have " .. has .. ")"
		end
	end

	return true, "OK"
end

-- Attempt to craft a recipe for a player
-- @param player Player
-- @param recipeName string
-- @param playerLevel number
-- @returns boolean success, string message
function CraftingSystem.craft(player, recipeName, playerLevel)
	local ok, reason = CraftingSystem.canCraft(player, recipeName, playerLevel)
	if not ok then
		EventBus.emit("CraftingSystem:CraftFailed", player, recipeName, reason)
		return false, reason
	end

	local recipe = recipes[recipeName]

	-- Deduct ingredients
	for item, qty in pairs(recipe.ingredients) do
		Inventory.removeItem(player, item, qty)
	end

	-- Add output items
	for item, qty in pairs(recipe.output) do
		Inventory.addItem(player, item, qty)
	end

	EventBus.emit("CraftingSystem:CraftSuccess", player, recipeName, recipe.output)
	return true, "Crafted " .. recipeName .. " successfully!"
end

return CraftingSystem
