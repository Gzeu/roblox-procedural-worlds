--[[
  ChunkHandler.lua  v4.0
  Async chunk loading/unloading with task.defer.
  Chunks are 32x32 stud regions loaded around the player.
--]]

local ChunkHandler = {}
ChunkHandler.__index = ChunkHandler

local CHUNK_SIZE   = 32
local LOAD_RADIUS  = 4   -- chunks
local UNLOAD_DIST  = 6   -- chunks

function ChunkHandler.new(worldData)
  local self = setmetatable({}, ChunkHandler)
  self._worldData    = worldData    -- heightmap / config
  self._loadedChunks = {}           -- key="cx,cz" -> Model
  self._pending      = {}
  self._active       = true
  return self
end

local function chunkKey(cx, cz)
  return cx .. "," .. cz
end

--- Convert world position to chunk coordinates.
function ChunkHandler:worldToChunk(x, z)
  return math.floor(x / CHUNK_SIZE), math.floor(z / CHUNK_SIZE)
end

--- Async-load a single chunk via task.defer.
function ChunkHandler:_loadChunk(cx, cz)
  local key = chunkKey(cx, cz)
  if self._loadedChunks[key] then return end
  self._loadedChunks[key] = true  -- mark loading

  task.defer(function()
    if not self._active then return end
    -- Build the chunk model
    local model = Instance.new("Model")
    model.Name  = "Chunk_" .. key
    -- TODO: populate from worldData heightmap
    -- (In production, voxel data drives part placement here)
    model.Parent = workspace.Terrain
    self._loadedChunks[key] = model
  end)
end

--- Unload chunks beyond UNLOAD_DIST from player.
function ChunkHandler:_unloadFarChunks(pcx, pcz)
  for key, model in pairs(self._loadedChunks) do
    local cx, cz = key:match("(-?%d+),(-?%d+)")
    cx, cz = tonumber(cx), tonumber(cz)
    if math.abs(cx - pcx) > UNLOAD_DIST or math.abs(cz - pcz) > UNLOAD_DIST then
      if typeof(model) == "Instance" then model:Destroy() end
      self._loadedChunks[key] = nil
    end
  end
end

--- Call every heartbeat with current player position.
function ChunkHandler:update(playerPosition)
  local pcx, pcz = self:worldToChunk(playerPosition.X, playerPosition.Z)
  -- Queue nearby chunk loads
  for dz = -LOAD_RADIUS, LOAD_RADIUS do
    for dx = -LOAD_RADIUS, LOAD_RADIUS do
      self:_loadChunk(pcx + dx, pcz + dz)
    end
  end
  self:_unloadFarChunks(pcx, pcz)
end

--- Clean up all chunks.
function ChunkHandler:destroy()
  self._active = false
  for key, model in pairs(self._loadedChunks) do
    if typeof(model) == "Instance" then model:Destroy() end
    self._loadedChunks[key] = nil
  end
end

return ChunkHandler
