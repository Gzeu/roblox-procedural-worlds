--!strict
-- ============================================================
-- MODULE: ReplicatedStorage/DungeonGenerator  [v2.1 NEW]
-- Underground dungeon room + corridor generation.
-- Uses BSP (Binary Space Partitioning) to place non-overlapping
-- rooms, then connects them with L-shaped corridors.
-- Rooms are carved into existing terrain using FillBlock(Air),
-- then floors are filled with SmoothPlastic and decorated with
-- dungeon props (torches, chests) from ReplicatedStorage/DungeonProps.
--
-- Usage:
--   DungeonGenerator.GenerateDungeons(seed)
--   Call from WorldGenerator AFTER terrain is generated.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local WorldConfig = require(ReplicatedStorage:WaitForChild("WorldConfig"))

local Terrain = Workspace.Terrain

local DungeonGenerator = {}

type Rect = { x: number, z: number, w: number, h: number }
type Room = { rect: Rect, centerX: number, centerZ: number, y: number }

local MIN_ROOM = 8
local MAX_DEPTH = 4

local function splitRect(rect: Rect, depth: number, seed: number, rooms: { Room })
	if depth == 0 or (rect.w < MIN_ROOM * 2 and rect.h < MIN_ROOM * 2) then
		local margin = 2
		local rx = rect.x + margin
		local rz = rect.z + margin
		local rw = math.max(MIN_ROOM, rect.w - margin * 2)
		local rh = math.max(MIN_ROOM, rect.h - margin * 2)
		local room: Room = {
			rect    = { x = rx, z = rz, w = rw, h = rh },
			centerX = rx + rw / 2,
			centerZ = rz + rh / 2,
			y       = 0,
		}
		table.insert(rooms, room)
		return
	end

	local splitNoise = math.noise(seed * 0.001 + rect.x * 0.01, rect.z * 0.01)
	local splitHoriz = (splitNoise > 0 and rect.h >= rect.w) or (rect.h > rect.w * 1.25)

	if splitHoriz then
		local splitAt = rect.z + math.floor(rect.h * 0.35 + math.abs(splitNoise) * rect.h * 0.3)
		splitRect({ x = rect.x, z = rect.z, w = rect.w, h = splitAt - rect.z }, depth - 1, seed + 1, rooms)
		splitRect({ x = rect.x, z = splitAt, w = rect.w, h = (rect.z + rect.h) - splitAt }, depth - 1, seed + 2, rooms)
	else
		local splitAt = rect.x + math.floor(rect.w * 0.35 + math.abs(splitNoise) * rect.w * 0.3)
		splitRect({ x = rect.x, z = rect.z, w = splitAt - rect.x, h = rect.h }, depth - 1, seed + 3, rooms)
		splitRect({ x = splitAt, z = rect.z, w = (rect.x + rect.w) - splitAt, h = rect.h }, depth - 1, seed + 4, rooms)
	end
end

local function carveRoom(room: Room, vSize: number)
	local halfV = vSize * 0.5
	local roomHeight = vSize * 4

	for lx = 0, room.rect.w - 1, vSize do
		for lz = 0, room.rect.h - 1, vSize do
			for ly = 0, roomHeight, vSize do
				local wx = room.rect.x + lx
				local wz = room.rect.z + lz
				local wy = room.y + ly

				local isFloor = (ly == 0)
				local material = if isFloor then Enum.Material.SmoothPlastic else Enum.Material.Air

				local center = Vector3.new(wx + halfV, wy + halfV, wz + halfV)
				local ok, _ = pcall(
					Terrain.FillBlock, Terrain,
					CFrame.new(center),
					Vector3.new(vSize, vSize, vSize),
					material
				)
				if not ok then break end
			end
		end
	end
end

local function carveCorridor(r1: Room, r2: Room, vSize: number)
	local halfV = vSize * 0.5
	local corrW = vSize * 2
	local corrH = vSize * 3
	local y = r1.y

	local x1 = math.min(r1.centerX, r2.centerX)
	local x2 = math.max(r1.centerX, r2.centerX)
	for wx = x1, x2, vSize do
		for lz = 0, corrW - 1, vSize do
			for ly = vSize, corrH, vSize do
				local center = Vector3.new(wx + halfV, y + ly + halfV, r1.centerZ + lz + halfV)
				pcall(Terrain.FillBlock, Terrain, CFrame.new(center), Vector3.new(vSize, vSize, vSize), Enum.Material.Air)
			end
		end
	end

	local z1 = math.min(r1.centerZ, r2.centerZ)
	local z2 = math.max(r1.centerZ, r2.centerZ)
	for wz = z1, z2, vSize do
		for lx = 0, corrW - 1, vSize do
			for ly = vSize, corrH, vSize do
				local center = Vector3.new(r2.centerX + lx + halfV, y + ly + halfV, wz + halfV)
				pcall(Terrain.FillBlock, Terrain, CFrame.new(center), Vector3.new(vSize, vSize, vSize), Enum.Material.Air)
			end
		end
	end
end

local function placeDungeonProps(room: Room)
	local propsFolder = ReplicatedStorage:FindFirstChild("DungeonProps")
	if not propsFolder then return end

	local corners = {
		Vector3.new(room.rect.x + 2, room.y + 6, room.rect.z + 2),
		Vector3.new(room.rect.x + room.rect.w - 2, room.y + 6, room.rect.z + 2),
		Vector3.new(room.rect.x + 2, room.y + 6, room.rect.z + room.rect.h - 2),
		Vector3.new(room.rect.x + room.rect.w - 2, room.y + 6, room.rect.z + room.rect.h - 2),
	}
	for _, pos in corners do
		local torch = propsFolder:FindFirstChild("Torch") :: Model?
		if torch then
			local clone = torch:Clone()
			if clone.PrimaryPart then
				clone:SetPrimaryPartCFrame(CFrame.new(pos))
				clone.Parent = Workspace:FindFirstChild("ProceduralAssets") or Workspace
			else
				clone:Destroy()
			end
		end
	end

	if math.random() < 0.35 then
		local chest = propsFolder:FindFirstChild("Chest") :: Model?
		if chest then
			local clone = chest:Clone()
			local centerPos = Vector3.new(room.centerX, room.y + 2, room.centerZ)
			if clone.PrimaryPart then
				clone:SetPrimaryPartCFrame(CFrame.new(centerPos))
				clone.Parent = Workspace:FindFirstChild("ProceduralAssets") or Workspace
			else
				clone:Destroy()
			end
		end
	end
end

function DungeonGenerator.GenerateDungeons(seed: number)
	local cfg     = WorldConfig.Settings
	local dungCfg = WorldConfig.DungeonSettings
	local vSize   = cfg.VoxelSize
	local halfX   = cfg.WorldSizeX / 2
	local halfZ   = cfg.WorldSizeZ / 2

	local placed = 0

	for gx = -halfX, halfX - dungCfg.GridStep, dungCfg.GridStep do
		if placed >= dungCfg.MaxDungeons then break end
		for gz = -halfZ, halfZ - dungCfg.GridStep, dungCfg.GridStep do
			if placed >= dungCfg.MaxDungeons then break end

			local n = math.noise(seed * 0.0001 + gx * 0.003, gz * 0.003)
			if n < dungCfg.SpawnThreshold then continue end

			local jx = gx + math.floor(math.noise(seed + gx, gz) * dungCfg.GridStep * 0.3)
			local jz = gz + math.floor(math.noise(seed + gz, gx) * dungCfg.GridStep * 0.3)

			placed += 1
			task.spawn(function()
				local rooms: { Room } = {}
				splitRect({ x = jx, z = jz, w = dungCfg.DungeonWidth, h = dungCfg.DungeonHeight }, MAX_DEPTH, seed + gx + gz, rooms)
				for _, room in rooms do room.y = dungCfg.DungeonY end
				for _, room in rooms do
					carveRoom(room, vSize)
					placeDungeonProps(room)
				end
				for i = 1, #rooms - 1 do
					carveCorridor(rooms[i], rooms[i + 1], vSize)
				end
				print(string.format("[DungeonGenerator] Dungeon @ (%d,%d) with %d rooms.", jx, jz, #rooms))
			end)
		end
	end
end

return DungeonGenerator
