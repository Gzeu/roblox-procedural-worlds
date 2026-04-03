--!strict
-- ============================================================
-- MODULE: NotificationBridge
-- Server → Client notification system via RemoteEvents.
-- Categories:
--   QUEST_COMPLETE   — quest finished, reward shown
--   FACTION_ATTACK   — enemy faction is attacking owned chunk
--   BOSS_SPAWN       — boss appeared in nearby chunk
--   LEVEL_UP         — player leveled up
--   DAILY_REWARD     — daily reward available reminder
--   SYSTEM           — generic server messages
-- v1.0.0 | roblox-procedural-worlds
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NotificationBridge = {}

-- ── RemoteEvent Setup ────────────────────────────────────────────

local function getOrCreate(name: string, parent: Instance): RemoteEvent
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing :: RemoteEvent
	end
	local re = Instance.new("RemoteEvent")
	re.Name   = name
	re.Parent = parent
	return re
end

local remoteFolder: Folder
local notifyEvent: RemoteEvent

export type NotifCategory =
	"QUEST_COMPLETE" | "FACTION_ATTACK" | "BOSS_SPAWN" |
	"LEVEL_UP" | "DAILY_REWARD" | "SYSTEM"

export type Notification = {
	category: NotifCategory,
	title:    string,
	body:     string,
	duration: number?,   -- seconds to show (default 5)
	icon:     string?,   -- rbxassetid or emoji
}

-- ── Public API ───────────────────────────────────────────────────

--- Send a notification to a single player.
function NotificationBridge.Notify(player: Player, notif: Notification)
	if notifyEvent then
		notifyEvent:FireClient(player, notif)
	end
end

--- Broadcast to all players.
function NotificationBridge.NotifyAll(notif: Notification)
	if notifyEvent then
		notifyEvent:FireAllClients(notif)
	end
end

--- Broadcast to all players in a radius around a world position.
function NotificationBridge.NotifyRadius(pos: Vector3, radius: number, notif: Notification)
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp  = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and (hrp.Position - pos).Magnitude <= radius then
			NotificationBridge.Notify(player, notif)
		end
	end
end

-- ── Convenience Wrappers ───────────────────────────────────────────

function NotificationBridge.QuestComplete(player: Player, questTitle: string, rewardTier: string)
	NotificationBridge.Notify(player, {
		category = "QUEST_COMPLETE",
		title    = "Quest Complete!",
		body     = questTitle .. " — " .. rewardTier .. " reward earned.",
		duration = 6,
		icon     = "🏆",
	})
end

function NotificationBridge.BossSpawn(pos: Vector3, bossName: string)
	NotificationBridge.NotifyRadius(pos, 800, {
		category = "BOSS_SPAWN",
		title    = "⚠️ Boss Appeared!",
		body     = bossName .. " has awakened nearby!",
		duration = 8,
		icon     = "🐲",
	})
end

function NotificationBridge.FactionAttack(player: Player, attackerName: string, chunkKey: string)
	NotificationBridge.Notify(player, {
		category = "FACTION_ATTACK",
		title    = "🗡️ Territory Under Attack!",
		body     = attackerName .. " is attacking chunk " .. chunkKey .. "!",
		duration = 7,
		icon     = "🚨",
	})
end

function NotificationBridge.LevelUp(player: Player, newLevel: number)
	NotificationBridge.Notify(player, {
		category = "LEVEL_UP",
		title    = "⭐ Level Up!",
		body     = "You reached level " .. newLevel .. "!",
		duration = 5,
		icon     = "⭐",
	})
end

function NotificationBridge.DailyReady(player: Player, day: number)
	NotificationBridge.Notify(player, {
		category = "DAILY_REWARD",
		title    = "🎁 Daily Reward Ready!",
		body     = "Day " .. day .. " reward is waiting. Claim it now!",
		duration = 8,
		icon     = "🎁",
	})
end

-- ── Lifecycle ────────────────────────────────────────────────────

function NotificationBridge.Start()
	-- Create folder + remote in ReplicatedStorage
	remoteFolder = ReplicatedStorage:FindFirstChild("ProceduralWorldsRemotes") :: Folder
	if not remoteFolder or not remoteFolder:IsA("Folder") then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name   = "ProceduralWorldsRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end
	notifyEvent = getOrCreate("NotifyClient", remoteFolder)
	print("[NotificationBridge] RemoteEvent ready.")
end

return NotificationBridge
