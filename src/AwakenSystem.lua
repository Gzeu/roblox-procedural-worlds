-- AwakenSystem.lua
-- Timed transformation states powered by combat energy and level thresholds
-- v5.0 | roblox-procedural-worlds

local Players     = game:GetService("Players")
local EventBus    = require(script.Parent.EventBus)
local SkillSystem = require(script.Parent.SkillSystem)

local AwakenSystem = {}

local dataByPlayer = {}

local STAGES = {
	Burst = {
		minLevel   = 10,
		energyCost = 100,
		duration   = 20,
		cooldown   = 45,
		buffs      = { damage = 0.18, speed = 2, maxHP = 20, crit = 0.05 },
	},
	Ascended = {
		minLevel   = 25,
		energyCost = 100,
		duration   = 25,
		cooldown   = 45,
		buffs      = { damage = 0.30, speed = 4, maxHP = 45, crit = 0.10 },
	},
	Mythic = {
		minLevel   = 50,
		energyCost = 100,
		duration   = 30,
		cooldown   = 45,
		buffs      = { damage = 0.45, speed = 6, maxHP = 80, crit = 0.16 },
	},
}

local function getData(player)
	local uid = player.UserId
	if not dataByPlayer[uid] then
		dataByPlayer[uid] = {
			energy        = 0,
			activeStage   = nil,
			activeUntil   = 0,
			cooldownUntil = 0,
		}
	end
	return dataByPlayer[uid]
end

local function chooseStage(player)
	local level = SkillSystem.getLevel(player)
	if     level >= STAGES.Mythic.minLevel   then return "Mythic",   STAGES.Mythic
	elseif level >= STAGES.Ascended.minLevel then return "Ascended", STAGES.Ascended
	elseif level >= STAGES.Burst.minLevel    then return "Burst",    STAGES.Burst
	end
	return nil, nil
end

function AwakenSystem.initPlayer(player)
	local data = getData(player)
	player:SetAttribute("AwakenEnergy", data.energy)
	player:SetAttribute("AwakenStage",  data.activeStage or "")
	return data
end

function AwakenSystem.grantEnergy(player, amount)
	local data = getData(player)
	if data.activeStage then return data.energy end
	data.energy = math.clamp(data.energy + amount, 0, 100)
	player:SetAttribute("AwakenEnergy", data.energy)
	EventBus.emit("AwakenSystem:EnergyChanged", player, data.energy)
	return data.energy
end

function AwakenSystem.canActivate(player)
	local data = getData(player)
	if tick() < data.cooldownUntil then return false, "Awaken cooldown active" end
	local stageName, stage = chooseStage(player)
	if not stage then return false, "Level too low" end
	if data.energy < stage.energyCost then return false, "Not enough energy" end
	return true, stageName
end

function AwakenSystem.activate(player)
	local ok, detail = AwakenSystem.canActivate(player)
	if not ok then return false, detail end
	local stageName = detail
	local stage = STAGES[stageName]
	local data  = getData(player)
	data.energy        = 0
	data.activeStage   = stageName
	data.activeUntil   = tick() + stage.duration
	data.cooldownUntil = data.activeUntil + stage.cooldown
	player:SetAttribute("AwakenEnergy", data.energy)
	player:SetAttribute("AwakenStage",  stageName)
	EventBus.emit("AwakenSystem:Activated", player, stageName, stage.buffs)
	task.delay(stage.duration, function()
		local current = getData(player)
		if current.activeStage == stageName then
			current.activeStage = nil
			current.activeUntil = 0
			player:SetAttribute("AwakenStage", "")
			EventBus.emit("AwakenSystem:Expired", player, stageName)
		end
	end)
	return true, stageName, stage.buffs
end

function AwakenSystem.getBuffs(player)
	local data = getData(player)
	if not data.activeStage then
		return { damage = 0, speed = 0, maxHP = 0, crit = 0 }
	end
	return STAGES[data.activeStage].buffs
end

function AwakenSystem.getState(player)
	local data = getData(player)
	return {
		energy            = data.energy,
		activeStage       = data.activeStage,
		remaining         = math.max(0, data.activeUntil   - tick()),
		cooldownRemaining = math.max(0, data.cooldownUntil - tick()),
	}
end

Players.PlayerRemoving:Connect(function(player)
	dataByPlayer[player.UserId] = nil
end)

return AwakenSystem
