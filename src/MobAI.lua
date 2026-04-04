--[[
  MobAI.lua  v5.0
  Vision cone (90°), hearing radius, memory decay system.
  Usage:
    local MobAI = require(game.ServerScriptService.MobAI)
    local mob   = MobAI.new(mobModel, { visionRange=40, hearingRadius=20 })
    -- in heartbeat:
    mob:update(dt)
--]]

local MobAI = {}
MobAI.__index = MobAI

local DEFAULT_OPTS = {
  visionRange    = 40,
  visionAngle    = 90,   -- degrees, total cone width
  hearingRadius  = 20,
  memoryDecay    = 8,    -- seconds until last-seen target is forgotten
  moveSpeed      = 16,
  attackRange    = 4,
  attackDamage   = 10,
}

function MobAI.new(model, opts)
  opts = opts or {}
  local self = setmetatable({}, MobAI)
  self._model   = model
  self._root    = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
  self._humanoid= model:FindFirstChildOfClass("Humanoid")
  self._opts    = setmetatable(opts, {__index = DEFAULT_OPTS})
  self._target  = nil      -- last known player target
  self._lastSeen = 0       -- time since last sighting
  self._state   = "idle"   -- idle | chase | attack | patrol
  self._memory  = {}       -- { position=Vector3, time=number }
  return self
end

--- Returns true if `target` falls inside the vision cone.
function MobAI:_canSee(target)
  if not self._root then return false end
  local diff  = target.Position - self._root.Position
  local dist  = diff.Magnitude
  if dist > self._opts.visionRange then return false end

  local forward = self._root.CFrame.LookVector
  local angle   = math.deg(math.acos(
    math.clamp(forward:Dot(diff.Unit), -1, 1)
  ))
  return angle <= self._opts.visionAngle / 2
end

--- Returns true if `target` is within hearing radius.
function MobAI:_canHear(target)
  if not self._root then return false end
  return (target.Position - self._root.Position).Magnitude <= self._opts.hearingRadius
end

--- Attempt to detect players in the workspace.
function MobAI:_detectPlayers()
  for _, player in ipairs(game.Players:GetPlayers()) do
    local char = player.Character
    if char then
      local root = char:FindFirstChild("HumanoidRootPart")
      if root and (self:_canSee(root) or self:_canHear(root)) then
        self._target   = root
        self._lastSeen = 0
        -- Store in memory
        table.insert(self._memory, { position = root.Position, time = 0 })
        if #self._memory > 10 then table.remove(self._memory, 1) end
        return true
      end
    end
  end
  return false
end

--- Move toward a world position using Humanoid:MoveTo.
function MobAI:_moveTo(pos)
  if self._humanoid then
    self._humanoid.WalkSpeed = self._opts.moveSpeed
    self._humanoid:MoveTo(pos)
  end
end

--- Per-frame update. Call with delta time from RunService.Heartbeat.
function MobAI:update(dt)
  -- Age memory entries
  for i = #self._memory, 1, -1 do
    self._memory[i].time = self._memory[i].time + dt
    if self._memory[i].time > self._opts.memoryDecay then
      table.remove(self._memory, i)
    end
  end

  self._lastSeen = self._lastSeen + dt

  local detected = self:_detectPlayers()

  if detected and self._target then
    local dist = (self._target.Position - self._root.Position).Magnitude
    if dist <= self._opts.attackRange then
      self._state = "attack"
      -- Trigger attack animation / deal damage (hook here)
    else
      self._state = "chase"
      self:_moveTo(self._target.Position)
    end
  elseif #self._memory > 0 then
    -- Investigate last known position from memory
    self._state = "patrol"
    local last = self._memory[#self._memory]
    self:_moveTo(last.position)
  else
    self._state = "idle"
    -- Wander: random offset every N seconds (stub)
  end
end

--- Returns current AI state string.
function MobAI:getState()
  return self._state
end

return MobAI
