-- FightingStyles.lua
-- Anime RPG / roguelite combat stances, combo chains and stance meter
-- v5.0 | roblox-procedural-worlds

local Players = game:GetService("Players")
local EventBus = require(script.Parent.EventBus)
local SkillSystem = require(script.Parent.SkillSystem)

local FightingStyles = {}

local COMBO_RESET_SECONDS = 3
local MAX_COMBO = 5
local MAX_STANCE = 100

FightingStyles.Styles = {
	Warrior = {
		rarity = "Common",
		damageMultiplier = 1.0,
		comboScaling = 0.08,
		critChance = 0.05,
		dodgeBonus = 0.00,
		magicWeight = 0.10,
		stanceGain = 12,
	},
	Rogue = {
		rarity = "Rare",
		damageMultiplier = 0.92,
		comboScaling = 0.11,
		critChance = 0.14,
		dodgeBonus = 0.08,
		magicWeight = 0.05,
		stanceGain = 14,
	},
	Mystic = {
		rarity = "Epic",
		damageMultiplier = 0.95,
		comboScaling = 0.07,
		critChance = 0.06,
		dodgeBonus = 0.03,
		magicWeight = 0.45,
		stanceGain = 16,
	},
	Berserker = {
		rarity = "Legendary",
		damageMultiplier = 1.18,
		comboScaling = 0.14,
		critChance = 0.10,
		dodgeBonus = -0.03,
		magicWeight = 0.00,
		stanceGain = 20,
	},
}

local playerData = {}

local function getData(player)
	local uid = player.UserId
	if not playerData[uid] then
		playerData[uid] = {
			style = "Warrior",
			unlocked = { Warrior = true },
			combo = 0,
			lastHitAt = 0,
			stance = 0,
		}
	end
	return playerData[uid]
end

function FightingStyles.initPlayer(player)
	local data = getData(player)
	player:SetAttribute("FightingStyle", data.style)
	player:SetAttribute("StanceMeter", data.stance)
	return data
end

function FightingStyles.getStyle(player)
	return getData(player).style
end

function FightingStyles.unlockStyle(player, styleName)
	if not FightingStyles.Styles[styleName] then return false, "Unknown style" end
	local data = getData(player)
	if data.unlocked[styleName] then return false, "Already unlocked" end
	data.unlocked[styleName] = true
	EventBus.emit("FightingStyles:Unlocked", player, styleName)
	return true
end

function FightingStyles.setStyle(player, styleName)
	if not FightingStyles.Styles[styleName] then return false, "Unknown style" end
	local data = getData(player)
	if not data.unlocked[styleName] then return false, "Style not unlocked" end
	data.style = styleName
	data.combo = 0
	player:SetAttribute("FightingStyle", styleName)
	EventBus.emit("FightingStyles:Changed", player, styleName)
	return true
end

function FightingStyles.buildAttackProfile(player, attackType)
	local data = getData(player)
	local style = FightingStyles.Styles[data.style] or FightingStyles.Styles.Warrior
	local now = tick()
	if now - data.lastHitAt > COMBO_RESET_SECONDS then data.combo = 0 end
	data.combo = math.clamp(data.combo + 1, 1, MAX_COMBO)
	data.lastHitAt = now
	data.stance = math.clamp(data.stance + style.stanceGain, 0, MAX_STANCE)
	player:SetAttribute("StanceMeter", data.stance)
	local meleeBonus = SkillSystem.getBonus(player, "meleeDamage") or 0
	local magicBonus = SkillSystem.getBonus(player, "magicDamage") or 0
	local dodgeBonus = SkillSystem.getBonus(player, "dodgeChance") or 0
	local comboMult  = 1 + ((data.combo - 1) * style.comboScaling)
	local dmgMult    = style.damageMultiplier * comboMult
	local flatBonus  = meleeBonus + math.floor(magicBonus * style.magicWeight)
	local profile = {
		style            = data.style,
		attackType       = attackType or "Light",
		combo            = data.combo,
		stance           = data.stance,
		damageMultiplier = dmgMult,
		flatDamageBonus  = flatBonus,
		critChance       = math.max(0, style.critChance + dodgeBonus * 0.25),
		dodgeBonus       = style.dodgeBonus + dodgeBonus,
	}
	EventBus.emit("FightingStyles:AttackProfile", player, profile)
	return profile
end

function FightingStyles.consumeStance(player, amount)
	local data = getData(player)
	if data.stance < amount then return false end
	data.stance = math.max(0, data.stance - amount)
	player:SetAttribute("StanceMeter", data.stance)
	return true
end

function FightingStyles.getSnapshot(player)
	local data = getData(player)
	return {
		style    = data.style,
		combo    = data.combo,
		stance   = data.stance,
		unlocked = (function()
			local out = {}
			for name, ok in pairs(data.unlocked) do if ok then table.insert(out, name) end end
			table.sort(out)
			return out
		end)(),
	}
end

Players.PlayerRemoving:Connect(function(player)
	playerData[player.UserId] = nil
end)

return FightingStyles
