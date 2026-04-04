-- InventoryRemote.lua  (ModuleScript → child of ProceduralWorldsServer)
-- Server-side RemoteFunction handler for client inventory queries.
-- Bridges InventoryUI.client.lua <-> Inventory.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local InventoryRemote = {}

local Inventory  -- lazily required to avoid circular deps

function InventoryRemote.Start()
	task.spawn(function()
		Inventory = require(script.Parent.Inventory)
	end)

	local remotes = ReplicatedStorage:WaitForChild("ProceduralWorldsRemotes", 15)
	if not remotes then
		warn("[InventoryRemote] ProceduralWorldsRemotes not found")
		return
	end

	local rf = Instance.new("RemoteFunction")
	rf.Name   = "InventoryRemote"
	rf.Parent = remotes

	rf.OnServerInvoke = function(player, action, arg)
		if not Inventory then
			return nil
		end

		if action == "getSlots" then
			-- Return slot data as array of {name, quantity, color (as RGB triplet)}
			local raw = Inventory.getSlots and Inventory.getSlots(player)
			if not raw then return {} end
			local result = {}
			for _, slot in ipairs(raw) do
				table.insert(result, {
					name     = slot.name     or "Unknown",
					quantity = slot.quantity  or 1,
					color    = slot.color
						or Color3.fromRGB(80, 120, 80),
				})
			end
			return result

		elseif action == "drop" then
			-- arg = slot index
			if Inventory.dropSlot then
				Inventory.dropSlot(player, arg)
			end
			return true

		elseif action == "use" then
			if Inventory.useSlot then
				Inventory.useSlot(player, arg)
			end
			return true

		elseif action == "equip" then
			if Inventory.equipSlot then
				Inventory.equipSlot(player, arg)
			end
			return true
		end

		return nil
	end
end

return InventoryRemote
