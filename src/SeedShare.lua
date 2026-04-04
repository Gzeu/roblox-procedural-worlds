--!strict
-- ============================================================
-- MODULE: SeedShare  [v1.1 - fixed]
-- Lets players share world seeds via a RemoteFunction.
-- Server: registers seed lookup; Client: calls to fetch seed.
-- ============================================================

local WorldConfig = require(script.Parent.WorldConfig)

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

local SeedShare = {}

local RF_NAME = "GetWorldSeed"

-- Server-side init: expose seed via RemoteFunction
function SeedShare.InitServer(getSeedFn: () -> number)
	local rf = Instance.new("RemoteFunction")
	rf.Name   = RF_NAME
	rf.Parent = ReplicatedStorage

	function rf.OnServerInvoke(_player: Player)
		return getSeedFn()
	end

	print("[SeedShare] Server ready — seed RF exposed")
end

-- Client-side: request seed from server
function SeedShare.GetSeedFromServer(): number?
	local rf = ReplicatedStorage:WaitForChild(RF_NAME, 10) :: RemoteFunction?
	if not rf then
		warn("[SeedShare] RemoteFunction not found")
		return nil
	end
	return rf:InvokeServer()
end

return SeedShare
