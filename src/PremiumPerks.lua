--!strict
-- ============================================================
-- MODULE: PremiumPerks
-- Detects Roblox Premium membership and grants automatic perks:
--   - +50% XP gain
--   - +1 quest slot (3→4)
--   - Exclusive "Prestige" chat tag
--   - Daily 50-coin bonus (stacked with DailyRewards)
-- v1.0.0 | roblox-procedural-worlds
-- ============================================================

local Players = game:GetService("Players")

local PremiumPerks = {}

local premiumUsers: { [number]: boolean } = {}

-- XP bonus multiplier for Premium players
local XP_MULTIPLIER    = 1.5
local DAILY_COIN_BONUS = 50
local EXTRA_QUEST_SLOT = 1

-- ── Detection ─────────────────────────────────────────────────────

local function applyPerks(player: Player)
	local hasPremium = player.MembershipType == Enum.MembershipType.Premium
	premiumUsers[player.UserId] = hasPremium

	player:SetAttribute("IsPremium",        hasPremium)
	player:SetAttribute("XPMultiplier",     hasPremium and XP_MULTIPLIER or 1.0)
	player:SetAttribute("PremiumQuestSlot", hasPremium and EXTRA_QUEST_SLOT or 0)
	player:SetAttribute("PremiumCoinBonus", hasPremium and DAILY_COIN_BONUS or 0)

	if hasPremium then
		print(string.format("[PremiumPerks] %s is Premium — perks applied.", player.Name))
	end
end

-- ── Public API ───────────────────────────────────────────────────

function PremiumPerks.IsPremium(player: Player): boolean
	return premiumUsers[player.UserId] == true
end

--- Apply XP multiplier — call from SkillSystem.awardXP.
function PremiumPerks.ScaleXP(player: Player, baseXP: number): number
	if premiumUsers[player.UserId] then
		return math.round(baseXP * XP_MULTIPLIER)
	end
	return baseXP
end

--- Total quest slots accounting for Premium.
function PremiumPerks.QuestSlots(player: Player, base: number): number
	return base + (premiumUsers[player.UserId] and EXTRA_QUEST_SLOT or 0)
end

-- ── Lifecycle ────────────────────────────────────────────────────

function PremiumPerks.Start()
	Players.PlayerAdded:Connect(applyPerks)

	Players.PlayerRemoving:Connect(function(player)
		premiumUsers[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		applyPerks(player)
	end
end

return PremiumPerks
